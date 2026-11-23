extends Node
## Cấu hình app: URL server, token, giao thức, FPS, chất lượng đồ hoạ.
## Lưu bằng user:// (ConfigFile) để không mất khi cài lại app.

signal changed(key: String, value: Variant)

const CFG_PATH := "user://settings.cfg"
const DEFAULT_SERVER := "https://monmon.io.vn"
const DEFAULT_PROTO := 1

var server_url: String = DEFAULT_SERVER
var proto: int = DEFAULT_PROTO
var token: String = ""
var session: String = ""  ## ap_session cookie lấy từ Set-Cookie của /api/login
var fps_cap: int = 60          # 60 hoặc 30
var quality_low: bool = false  # giảm hạt / hiệu ứng khi máy yếu
var debug_stats: bool = false
var hints_seen: Dictionary = {}     ## gợi ý lần đầu đã hiện (id -> true)
var show_damage: bool = true    ## hiện số sát thương nổi
var haptics: bool = true       ## rung khi bị đánh
var volume: float = 0.7        ## âm lượng 0..1
var last_user: String = ""     ## tên đăng nhập gần nhất (điền sẵn ở màn Login)

var _cfg := ConfigFile.new()

func _ready() -> void:
	var err := _cfg.load(CFG_PATH)
	if err == OK:
		server_url = str(_cfg.get_value("net", "server_url", DEFAULT_SERVER))
		proto = int(_cfg.get_value("net", "proto", DEFAULT_PROTO))
		token = str(_cfg.get_value("net", "token", ""))
		session = str(_cfg.get_value("net", "session", ""))
		fps_cap = int(_cfg.get_value("game", "fps_cap", 60))
		quality_low = bool(_cfg.get_value("game", "quality_low", false))
		debug_stats = bool(_cfg.get_value("game", "debug_stats", false))
		last_user = str(_cfg.get_value("net", "last_user", ""))
		haptics = bool(_cfg.get_value("game", "haptics", true))
		show_damage = bool(_cfg.get_value("game", "show_damage", true))
		hints_seen = _cfg.get_value("ux", "hints_seen", {})
		volume = float(_cfg.get_value("game", "volume", 0.7))
	_apply_fps()

func _apply_fps() -> void:
	# 0 = không giới hạn; Engine.max_fps = 60/30 theo cấu hình
	Engine.max_fps = fps_cap if fps_cap in [30, 60] else 60
	# Đồng bộ tần số vật lý với FPS để cảm giác di chuyển giống web
	Engine.physics_ticks_per_second = Engine.max_fps

func set_server_url(url: String) -> void:
	server_url = url.trim_suffix("/")
	_save(); changed.emit("server_url", server_url)

func set_token(value: String) -> void:
	token = value
	_save(); changed.emit("token", "<ẩn>")

func set_session(value: String) -> void:
	session = value
	_save(); changed.emit("session", "<ẩn>")

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
	_cfg.set_value("net", "server_url", server_url)
	_cfg.set_value("net", "proto", proto)
	_cfg.set_value("net", "token", token)
	_cfg.set_value("net", "session", session)
	_cfg.set_value("net", "last_user", last_user)
	_cfg.set_value("game", "haptics", haptics)
	_cfg.set_value("game", "show_damage", show_damage)
	_cfg.set_value("ux", "hints_seen", hints_seen)
	_cfg.set_value("game", "volume", volume)
	_cfg.set_value("game", "fps_cap", fps_cap)
	_cfg.set_value("game", "quality_low", quality_low)
	_cfg.set_value("game", "debug_stats", debug_stats)
	_cfg.save(CFG_PATH)

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
	Audio.set_volume(volume)
	_save(); changed.emit("volume", volume)

func mark_hint(id: String) -> void:
	hints_seen[id] = true
	_save()

func set_show_damage(value: bool) -> void:
	show_damage = value
	_save(); changed.emit("show_damage", show_damage)

func reset_hints() -> void:
	hints_seen = {}
	_save()
