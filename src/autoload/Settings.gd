extends Node
## Cấu hình app: URL server, token, giao thức, FPS, chất lượng đồ hoạ.
## Lưu bằng user:// (ConfigFile) để không mất khi cài lại app.

signal changed(key: String, value: Variant)

const CFG_PATH := "user://settings.cfg"
## Token/phien luu RIENG, khong nam trong settings.cfg (file config de doc/sua).
const SECURE_PATH := "user://.ap_secure.cfg"
const DEFAULT_SERVER := "https://monmon.io.vn"
## Pin URL server vao binary: thay doi tu UI/gia ma config khong co tac dung.
## Muon doi server hop le phai cap nhat const nay va phat lai app.
const SERVER_PIN := "monmon.io.vn"
const DEFAULT_PROTO := 1

var server_url: String = DEFAULT_SERVER
var proto: int = DEFAULT_PROTO
var token: String = ""
var session: String = ""  ## ap_session cookie lấy từ Set-Cookie của /api/login
var fps_cap: int = 60          # 60 hoặc 30
const DEFAULT_UI_SCALE := 0.85
var ui_scale: float = DEFAULT_UI_SCALE   # cỡ HUD (0.75..1.15): nhỏ hơn = chữ/nút nhỏ lại, KHÔNG đổi tầm nhìn thế giới
## Độ phóng thế giới (camera). Nhỏ hơn = thấy nhiều map hơn. Tách riêng ui_scale để không bị content_scale_factor triệt tiêu.
const DEFAULT_WORLD_ZOOM := 0.95
var world_zoom: float = DEFAULT_WORLD_ZOOM
var quality_low: bool = false  # giảm hạt / hiệu ứng khi máy yếu
var debug_stats: bool = false
var hints_seen: Dictionary = {}     ## gợi ý lần đầu đã hiện (id -> true)
var show_damage: bool = true    ## hiện số sát thương nổi
var haptics: bool = true       ## rung khi bị đánh
var volume: float = 0.7        ## âm lượng chung (alias tương thích; dùng sfx_volume/music_volume)
var sfx_enabled: bool = true   ## bật hiệu ứng âm thanh
var music_enabled: bool = true ## bật nhạc nền
var sfx_volume: float = 1.0    ## âm lượng hiệu ứng 0..1
var music_volume: float = 0.6  ## âm lượng nhạc nền 0..1
var last_user: String = ""     ## tên đăng nhập gần nhất (điền sẵn ở màn Login)

var _cfg := ConfigFile.new()
var _save_timer: Timer = null      # debounce ghi đĩa khi kéo slider/đổi zoom

func _ready() -> void:
	var err := _cfg.load(CFG_PATH)
	if err == OK:
		server_url = str(_cfg.get_value("net", "server_url", DEFAULT_SERVER))
		proto = int(_cfg.get_value("net", "proto", DEFAULT_PROTO))
		token = str(_cfg.get_value("net", "token", ""))
		session = str(_cfg.get_value("net", "session", ""))
		fps_cap = int(_cfg.get_value("game", "fps_cap", 60))
		ui_scale = clampf(float(_cfg.get_value("game", "ui_scale", DEFAULT_UI_SCALE)), 0.6, 1.5)
		world_zoom = clampf(float(_cfg.get_value("game", "world_zoom", DEFAULT_WORLD_ZOOM)), 0.6, 2.0)
		# Lần đầu (chưa có khoá): mobile ít nhân CPU thì mặc định chất lượng thấp
		quality_low = bool(_cfg.get_value("game", "quality_low", _weak_device()))
		debug_stats = bool(_cfg.get_value("game", "debug_stats", false))
		last_user = str(_cfg.get_value("net", "last_user", ""))
		haptics = bool(_cfg.get_value("game", "haptics", true))
		show_damage = bool(_cfg.get_value("game", "show_damage", true))
		hints_seen = _cfg.get_value("ux", "hints_seen", {})
		volume = float(_cfg.get_value("game", "volume", 0.7))
		sfx_enabled = bool(_cfg.get_value("game", "sfx_enabled", true))
		music_enabled = bool(_cfg.get_value("game", "music_enabled", true))
		sfx_volume = clampf(float(_cfg.get_value("game", "sfx_volume", 1.0)), 0.0, 1.0)
		music_volume = clampf(float(_cfg.get_value("game", "music_volume", 0.6)), 0.0, 1.0)
	_load_secure()
	_enforce_server_pin()
	_apply_fps()
	_apply_display()

func _weak_device() -> bool:
	return (OS.has_feature("mobile") or OS.has_feature("android") or OS.has_feature("ios")) and OS.get_processor_count() <= 4

## Cỡ HUD. Thay đổi content_scale_factor; KHÔNG đụng vào camera (thế giới có world_zoom riêng).
func _apply_display() -> void:
	var w := get_window()
	if w != null: w.content_scale_factor = ui_scale

func set_ui_scale(value: float) -> void:
	ui_scale = clampf(value, 0.6, 1.5)
	_apply_display(); _save(); changed.emit("ui_scale", ui_scale)

## Độ phóng thế giới: nhỏ hơn = nhìn rộng hơn (xem nhiều map hơn). Ảnh hưởng trực tiếp camera.
func set_world_zoom(value: float) -> void:
	world_zoom = clampf(value, 0.6, 2.0)
	_save(); changed.emit("world_zoom", world_zoom)

## Tự hạ chất lượng khi máy yếu: FPS < 40 liên tục ~6s (chỉ khi đang ở chế độ 60 và chưa bật low) thì bật quality_low.
## Người chơi vẫn tắt lại được trong cài đặt; chỉ tự hạ một lần mỗi phiên để không giằng co.
var _perf_low_s := 0
var _perf_acc := 0.0
var _perf_done := false

func _process(delta: float) -> void:
	if quality_low or _perf_done or fps_cap == 30: return
	_perf_acc += delta
	if _perf_acc < 1.0: return
	_perf_acc = 0.0
	if not get_window().has_focus(): _perf_low_s = 0; return
	var fps := Engine.get_frames_per_second()
	if fps > 0 and fps < 40: _perf_low_s += 1
	else: _perf_low_s = maxi(0, _perf_low_s - 1)
	if _perf_low_s >= 6:
		_perf_done = true
		set_quality_low(true)

func _apply_fps() -> void:
	# 30 FPS: cố định 30. Còn lại: để màn hình quyết định nhịp (vsync) — đặt trần 60 trên màn 90/120Hz làm
	# khung hình đến không đều (giật), nên không giới hạn tay.
	Engine.max_fps = 30 if fps_cap == 30 else 0
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	# Di chuyển nhân vật chạy trong _process theo delta thật, không còn phụ thuộc nhịp vật lý
	Engine.physics_ticks_per_second = 60

func set_server_url(url: String) -> void:
	var u := url.trim_suffix("/")
	if not _url_matches_pin(u): return   ## khong cho tro app sang server khac
	server_url = u
	_save(); changed.emit("server_url", server_url)

func set_token(value: String) -> void:
	token = value
	_save_secure(); changed.emit("token", "<ẩn>")

func set_session(value: String) -> void:
	session = value
	_save_secure(); changed.emit("session", "<ẩn>")

## Header Cookie gửi kèm mọi request HTTP.
func cookie_header() -> String:
	return "ap_session=" + session if not session.is_empty() else ""

func set_proto(value: int) -> void:
	proto = value
	_save(); changed.emit("proto", proto)

func set_fps_cap(value: int) -> void:
	fps_cap = 30 if value == 30 else 60
	_apply_fps(); _save(); changed.emit("fps_cap", fps_cap)

func set_quality_low(value: bool) -> void:
	quality_low = value
	_save(); changed.emit("quality_low", quality_low)

func set_debug_stats(value: bool) -> void:
	debug_stats = value
	_save(); changed.emit("debug_stats", debug_stats)

func _save() -> void:
	# Gộp các setter liên tiếp (kéo slider) thành 1 lần ghi sau 250ms.
	if _save_timer == null:
		_save_timer = Timer.new()
		_save_timer.one_shot = true
		_save_timer.wait_time = 0.25
		_save_timer.timeout.connect(_save_now)
		add_child(_save_timer)
	_save_timer.start(0.25)

func _notification(what: int) -> void:
	# Đảm bảo ghi phần đang chờ debounce khi thoát app (Android/iOS gửi NOTIFICATION_WM_CLOSE_REQUEST / PAUSE).
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED:
		if _save_timer != null and not _save_timer.is_stopped(): _save_now()

func _save_now() -> void:
	if _save_timer != null and not _save_timer.is_stopped(): _save_timer.stop()
	_cfg.set_value("net", "server_url", server_url)
	_cfg.set_value("net", "proto", proto)
	_cfg.set_value("net", "last_user", last_user)
	_cfg.set_value("game", "haptics", haptics)
	_cfg.set_value("game", "show_damage", show_damage)
	_cfg.set_value("ux", "hints_seen", hints_seen)
	_cfg.set_value("game", "volume", volume)
	_cfg.set_value("game", "sfx_enabled", sfx_enabled)
	_cfg.set_value("game", "music_enabled", music_enabled)
	_cfg.set_value("game", "sfx_volume", sfx_volume)
	_cfg.set_value("game", "music_volume", music_volume)
	_cfg.set_value("game", "fps_cap", fps_cap)
	_cfg.set_value("game", "ui_scale", ui_scale)
	_cfg.set_value("game", "world_zoom", world_zoom)
	_cfg.set_value("game", "quality_low", quality_low)
	_cfg.set_value("game", "debug_stats", debug_stats)
	_cfg.save(CFG_PATH)

## --- Lưu phiên riêng (không lẫn vào settings.cfg) ---
func _load_secure() -> void:
	var f := ConfigFile.new()
	if f.load(SECURE_PATH) == OK:
		token = str(f.get_value("net", "token", ""))
		session = str(f.get_value("net", "session", ""))
	# Migrate 1 lần: bản cũ lưu token/session ngay trong settings.cfg.
	var old_token := str(_cfg.get_value("net", "token", ""))
	var old_session := str(_cfg.get_value("net", "session", ""))
	if token.is_empty() and not old_token.is_empty(): token = old_token
	if session.is_empty() and not old_session.is_empty(): session = old_session
	if not old_token.is_empty() or not old_session.is_empty():
		# Godot 4.3 không có erase_section_field: ghi đè thành rỗng (giá trị thật đã ở file riêng).
		_cfg.set_value("net", "token", "")
		_cfg.set_value("net", "session", "")
		_cfg.save(CFG_PATH)
		_save_secure()

func _save_secure() -> void:
	var f := ConfigFile.new()
	f.set_value("net", "token", token)
	f.set_value("net", "session", session)
	f.save(SECURE_PATH)

func _url_matches_pin(u: String) -> bool:
	var host := u
	if host.begins_with("https://"): host = host.substr(8)
	elif host.begins_with("http://"): host = host.substr(7)
	host = host.split("/")[0].split(":")[0].to_lower()
	return host == SERVER_PIN

func _enforce_server_pin() -> void:
	if not _url_matches_pin(server_url):
		server_url = DEFAULT_SERVER
		_save()

## Chuyển URL server thành URL WebSocket /ws (wss khi https)
func ws_url() -> String:
	var u := server_url
	if u.begins_with("https://"): return "wss://" + u.substr(8) + "/ws"
	if u.begins_with("http://"): return "ws://" + u.substr(7) + "/ws"
	return "wss://" + u + "/ws"

func set_last_user(value: String) -> void:
	last_user = value
	_save()

func set_haptics(value: bool) -> void:
	haptics = value
	_save(); changed.emit("haptics", haptics)

func set_volume(value: float) -> void:
	volume = clampf(value, 0.0, 1.0)
	sfx_volume = volume
	Audio.set_sfx_volume(volume)
	_save(); changed.emit("volume", volume)

func set_sfx_enabled(value: bool) -> void:
	sfx_enabled = value
	Audio.set_sfx_enabled(value)
	_save(); changed.emit("sfx_enabled", value)

func set_music_enabled(value: bool) -> void:
	music_enabled = value
	Audio.set_music_enabled(value)
	_save(); changed.emit("music_enabled", value)

func set_sfx_volume(value: float) -> void:
	sfx_volume = clampf(value, 0.0, 1.0)
	volume = sfx_volume
	Audio.set_sfx_volume(sfx_volume)
	_save(); changed.emit("sfx_volume", sfx_volume)

func set_music_volume(value: float) -> void:
	music_volume = clampf(value, 0.0, 1.0)
	Audio.set_music_volume(music_volume)
	_save(); changed.emit("music_volume", music_volume)

func mark_hint(id: String) -> void:
	hints_seen[id] = true
	_save()

func set_show_damage(value: bool) -> void:
	show_damage = value
	_save(); changed.emit("show_damage", show_damage)

func reset_hints() -> void:
	hints_seen = {}
	_save()
