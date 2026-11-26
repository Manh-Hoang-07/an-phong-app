extends Node2D
## Màn chơi: nền parallax, bản đồ, nhân vật, quái (server quản lý), người chơi khác, đồ rơi, NPC/cổng, HUD cảm ứng.
## Luật chơi vẫn ở server. File này: vật lý nhân vật, gửi đòn, nhận sát thương từ đòn lao của quái,
## chết/hồi sinh, đổi bản đồ, đổi phiếu thưởng (`kills`), nhặt đồ, lưu trạng thái.

const T := preload("res://src/ui/UITheme.gd")
const GlyphArt := preload("res://src/ui/GlyphArt.gd")
const FloatText := preload("res://src/world/FloatText.gd")
const LootNode := preload("res://src/world/LootNode.gd")
const RemotePlayer := preload("res://src/world/RemotePlayer.gd")
const MapEntities := preload("res://src/world/MapEntities.gd")
const Fx := preload("res://src/world/Fx.gd")
const Weather := preload("res://src/world/Weather.gd")

const TILE := 32.0
const STRETCH := 1.5
const SPEED := 190.0
const GRAVITY := 1300.0
const JUMP_V := 560.0
const SAVE_EVERY := 5.0
const ATTACK_GAP_MS := 340

@onready var _bg: Node2D = $Background
@onready var _map_layer: Node2D = $MapLayer
@onready var _remote: Node2D = $RemoteLayer
@onready var _mob_layer: Node2D = $MobLayer
@onready var _fx: Node2D = $FxLayer
@onready var _player: Node2D = $Player
@onready var _hud: CanvasLayer = $MobileHUD
@onready var _cam: Camera2D = $Camera2D

var _char_script: Script = null
var _hud_node: Node = null
var _skill_fx: Node = null
var _bg_node: Node = null
var _map_view: Node2D = null
var _entities: Node2D = null
var _loot_layer: Node2D = null
var _fade: ColorRect = null
var _fxs: Node2D = null
var _weather: CanvasLayer = null
var _mob_script: Script = null
const AssistScript := preload("res://src/world/Assist.gd")
var _assist: Node = null         # thú đồng hành / linh thú / bóng ma tự đánh quái
var _last_hit_uid := 0           # quái người chơi vừa đánh (bạn đồng hành nhắm theo)
var _last_hit_at := 0
var _shadow_power_until := 0

var _players: Dictionary = {}   # id -> RemotePlayer
var _mobs: Dictionary = {}      # uid -> MobSprite
var _loots: Dictionary = {}     # lid -> LootNode
var _map_id := ""
var _meta: Dictionary = {}
var _grid: Array = []
var _cols := 0
var _rows := 0
# Bake va chạm/mặt đất theo cột khi load map: _move_step gọi _ground_y 4 lần + _walkable 2 lần mỗi khung.
var _stand_rows: Array = []          # _stand_rows[c] = mảng các hàng đứng (#/=) đã sort tăng dần
var _walk_cache: Array[bool] = []    # index = row * _cols + col

# nhân vật
var _facing := 1
var _anim := "idle"
var _move_dir := Vector2.ZERO
var _vy := 0.0
var _knock_vx := 0.0
var _knock_until := 0
var _jump_req := false
var _attack_until := 0
var _next_attack := 0
var _hurt_until := 0
var _invuln_until := 0
var _last_hurt := 0
var _buffs: Dictionary = {}          # id kỹ năng -> {name, until, reduce, reflect, absorb, atk, crit, speed, regen}
var _phase_cd := 0                   # bộ Vĩnh Hằng: lướt qua đòn
var _stone_cd := 0                   # bộ Thạch Vương: khiên đá
var _slow_until := 0                 # trùm Nước / Băng làm chậm người chơi
var _last_ground_at := 0             # coyote time: còn nhảy được 110ms sau khi rời mép
var _jump_buffered_at := -1000       # bộ đệm nhảy: bấm sớm 140ms vẫn nhảy khi chạm đất
var _jumped_air := false
var _laststand_cd := 0               # Bùa Hộ Mệnh (Kỳ Nguyên Bất Tử)
var _laststand_until := 0
var _nth_count: Dictionary = {}           # Ấn Sát: số đòn đã trúng theo uid quái
var _free_cast_used := false         # bộ Lưu Trữ: kỹ năng đầu tiên mỗi trận miễn MP
var _heal_tick := 0                  # Kiếm Tâm: chống hồi dồn trong 120ms
var _dead := false
var _changing := false
var _reload_queued := false
var _skill_ids: Array = ["pa1", "pa2", "pa3", "pa4", "pa5"]
var _cd_until: Array = [0, 0, 0, 0, 0, 0, 0, 0, 0]   # 0-4 thường, 5-7 tuyệt kỹ/tuyệt phẩm (ô 5,6,7 của server), 8 kỹ năng trang bị

## Ô nút HUD -> id kỹ năng (đúng mô hình ô của web/server). Ô trang bị là ô ảo lấy từ món đang mặc.
func _btn_skill(i: int) -> String:
	var slots: Array = Game.player.get("skillSlots", [])
	if i == 8: return _gear_skill_id()
	if i < 0 or i > 7: return ""
	var s0 := str(slots[i]) if i < slots.size() and slots[i] != null else ""
	if s0 == "" and i < 4: s0 = str(_skill_ids[i])
	return s0

func _gear_skill_id() -> String:
	var eq: Variant = Game.player.get("equip", {})
	if typeof(eq) != TYPE_DICTIONARY: return ""
	for slot in (eq as Dictionary).keys():
		var it: Variant = (eq as Dictionary)[slot]
		if typeof(it) != TYPE_DICTIONARY: continue
		var g := str(Data.item(str((it as Dictionary).get("id", ""))).get("grantsSkill", ""))
		if g != "" and not Data.skill(g).is_empty() and not bool(Data.skill(g).get("ult", false)): return g
	return ""

# mạng / lưu
var _pending_kills: Array = []
var _kill_timer: SceneTreeTimer = null
var _save_acc := 0.0
var _last_saved := Vector2(-1, -1)
var _last_saved_sig := 0
var _save_idle := 0.0
const SAVE_IDLE_MAX := 30.0
var _regen_acc := 0.0
var _hud_dirty := true
var _hud_acc := 0.0
var _interact_acc := 0.0
var _pickup_pending: Dictionary = {}
var _pickup_lid := ""
var _interact: Dictionary = {}
var _other_fx_at := 0
var _other_fx_n := 0

# ------------------------------------------------------------------ Khởi tạo
func _ready() -> void:
	_char_script = load("res://src/world/CharSprite.gd")
	_mob_script = load("res://src/world/MobSprite.gd")
	get_viewport().size_changed.connect(_apply_zoom)
	Settings.changed.connect(func(k, _v): if k == "world_zoom": _apply_zoom.call_deferred())
	_assist = AssistScript.new()
	add_child(_assist)
	_assist.setup(self)
	var mv_script: Script = load("res://src/world/MapView.gd")
	if mv_script:
		_map_view = mv_script.new()
		_map_view.name = "MapView"
		_map_layer.add_child(_map_view)
	_entities = MapEntities.new()
	_entities.name = "Entities"
	_map_layer.add_child(_entities)
	_loot_layer = Node2D.new()
	_loot_layer.name = "Loot"
	_mob_layer.get_parent().add_child(_loot_layer)
	_mob_layer.get_parent().move_child(_loot_layer, _mob_layer.get_index())
	_fxs = Fx.new()
	_fxs.name = "Fx"
	_fx.add_child(_fxs)
	var fx_script: Script = load("res://src/world/SkillFx.gd")
	if fx_script:
		_skill_fx = fx_script.new()
		_skill_fx.name = "SkillFx"
		_fx.add_child(_skill_fx)
	var bg_script: Script = load("res://src/world/Background.gd")
	if bg_script:
		_bg_node = bg_script.new()
		_bg.name = "BackgroundFx"
		_bg.add_child(_bg_node)
	_weather = Weather.new()
	add_child(_weather)
	var hud_script: Script = load("res://src/ui/MobileHUD.gd")
	if hud_script:
		_hud_node = hud_script.new()
		_hud.add_child(_hud_node)
		_hud_node.move_vector.connect(func(d): _move_dir = d)
		_hud_node.skill_pressed.connect(_cast)
		_hud_node.attack_pressed.connect(_on_attack)
		_hud_node.jump_pressed.connect(func(): _jump_req = true)
		_hud_node.menu_pressed.connect(func(_t): _hud_dirty = true)
		_hud_node.chat_sent.connect(_on_chat)
		_hud_node.interact_pressed.connect(_do_interact)
		_hud_node.death_choice.connect(_on_death_choice)
		_hud_node.potion_pressed.connect(_use_quick_potion)
		_hud_node.form_pressed.connect(_toggle_form)
		_hud_node.seal_pressed.connect(_switch_seal)

	# Lớp phủ đen dùng khi chuyển cảnh
	var fl := CanvasLayer.new()
	fl.layer = 30
	add_child(fl)
	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 1)
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fl.add_child(_fade)

	Socket.connected_to_server.connect(_on_socket_connected)
	Socket.players.connect(_on_players)
	Socket.mobs.connect(_on_mobs)
	Socket.chat.connect(_on_chat_recv)
	Game.player_changed.connect(func(_q): _hud_dirty = true)
	Game.event_received.connect(_on_event)
	Net.action_done.connect(_on_action_done)

	if not Game.has_player():
		get_tree().call_deferred("change_scene_to_file", "res://src/scenes/Login.tscn")
		return
	if Game.hp <= 0:
		Game.hp = int(Game.player.get("hp", 0))
		if Game.hp <= 0: Game.hp = int(Game.stats.get("maxHp", 100))
	if Game.mp <= 0 and int(Game.player.get("mp", 0)) > 0: Game.mp = int(Game.player.get("mp", 0))
	_setup_player_sprite()
	_load_player_map("")
	_refresh_hud()
	Socket.start()
	_fade_in()

func _exit_tree() -> void:
	if Game.has_player() and not _dead and not _changing:
		_save_state()
	_flush_kills()
	Socket.stop()

func _fade_in() -> void:
	_fade.modulate.a = 1.0
	create_tween().tween_property(_fade, "modulate:a", 0.0, 0.3)

var _player_sprite: Node2D = null   # reference trực tiếp, tránh get_children() mỗi khung trong _set_facing/_play_anim
func _setup_player_sprite() -> void:
	var school := str(Game.player.get("school", "kiem_si"))
	for c in _player.get_children(): c.queue_free()
	_player_sprite = null
	if _char_script:
		var sprite: Node2D = _char_script.new()
		_player.add_child(sprite)
		sprite.setup(school)
		_player_sprite = sprite
	_aura = null
	_player.modulate = Color.WHITE
	if Game.form_active: _apply_form_visual(true, true)

# ------------------------------------------------------------------ Bản đồ
func _find_char(ch: String) -> Vector2i:
	for r in range(_grid.size()):
		var row: Array = _grid[r]
		for c in range(row.size()):
			if str(row[c]) == ch: return Vector2i(c, r)
	return Vector2i(-1, -1)

func _load_player_map(arrive: String) -> void:
	_clear_world()
	_free_cast_used = false
	_nth_count.clear()
	_map_id = str(Game.player.get("map", "cong_do"))
	if _map_id.is_empty() or not Data.has_map_text(_map_id):
		_map_id = "cong_do"
	_meta = Data.map_def(_map_id)
	Audio.music(_map_id, str(_meta.get("theme", "city")))
	var lines: Array = Data.map_text(_map_id).replace("\r", "").split("\n", false)
	var source_cols := 0
	for line in lines: source_cols = maxi(source_cols, (line as String).length())
	# Khớp WorldMap.parseMap của web: giãn cột 1.5x, TILE vẫn 32 => ô va chạm 48px.
	_cols = int(ceil(float(source_cols) * STRETCH))
	_rows = lines.size()
	var markers := ["S"]
	for k in (_meta.get("spawns", {}) as Dictionary).keys(): markers.append(str(k))
	for k in (_meta.get("npcs", {}) as Dictionary).keys(): markers.append(str(k))
	for k in (_meta.get("portals", {}) as Dictionary).keys(): markers.append(str(k))
	markers.append(str(_meta.get("gate", "")))
	_grid = []
	for line in lines:
		var s := line as String
		var row: Array = []
		for col in range(_cols):
			var old := mini(source_cols - 1, int(floor(float(col) / STRETCH)))
			var ch := s.substr(old, 1) if old < s.length() else "."
			if ch in markers and col != int(ceil(float(old) * STRETCH)): ch = "."
			row.append(ch)
		_grid.append(row)
	for i in range(maxi(0, 17 - _rows)):
		_grid.append(Array(_grid[0]).map(func(_x): return "#"))
	_rows = _grid.size()
	for r in range(_rows - 1):
		for c in range(_cols):
			if str((_grid[r] as Array)[c]) == "=" and str((_grid[r + 1] as Array)[c]) == "#":
				(_grid[r] as Array)[c] = "."
	_bake_collision_cache()

	# Vị trí xuất hiện: toạ độ đã lưu (nếu hợp lệ) hoặc điểm tới (arrive / S).
	var px = Game.player.get("x", null)
	var py = Game.player.get("y", null)
	var pos := Vector2.ZERO
	var saved_ok := px != null and py != null and arrive.is_empty() and float(px) > 20.0 and float(px) < float(_cols) * TILE - 20.0 \
		and float(py) > 0.0 and float(py) < float(_rows) * TILE
	if saved_ok:
		pos = Vector2(float(px), float(py))
	else:
		var a := arrive
		var portals: Dictionary = _meta.get("portals", {})
		if not _meta.get("gate", "").is_empty() and not a.is_empty() and a != "<" and portals.has(a):
			a = str(_meta["gate"])
		var c := _find_char(a) if not a.is_empty() else Vector2i(-1, -1)
		if c.x < 0: c = _find_char("S")
		if c.x < 0: c = _find_char("<")
		if c.x < 0: c = Vector2i(2, 2)
		var x := float(c.x) * TILE + TILE * 0.5
		if portals.has(arrive): x += 50.0 if x < float(_cols) * TILE * 0.5 else -50.0
		pos = Vector2(x, float(_ground_y(x, float(c.y) * TILE)) - 30.0)
	_player.position = pos
	Game.player["arrive"] = null
	_vy = 0.0
	_snap_to_ground()

	var theme_id := _theme_of(_map_id)
	var t_bake := Time.get_ticks_msec()
	if _map_view and _map_view.has_method("build_grid"):
		_map_view.build_grid(_grid, theme_id, TILE, _map_id)
	_entities.build(_grid, TILE, _meta, func(r: int, c: int) -> float:
		return float(_ground_y(float(c) * TILE + TILE * 0.5, float(r) * TILE)))
	_entities.refresh_visibility(Game.player, _map_id)
	if _bg_node and _bg_node.has_method("set_map"):
		_bg_node.set_map(_map_id, theme_id, Settings.quality_low)
	var look: Dictionary = Data.look(_map_id)
	if _weather: _weather.apply(look)
	RenderingServer.set_default_clear_color(Color.from_rgba8((int(look.get("bg", 0x101820)) >> 16) & 255, (int(look.get("bg", 0x101820)) >> 8) & 255, int(look.get("bg", 0x101820)) & 255))
	if _cam:
		_apply_zoom()
		_cam.limit_left = 0
		_cam.limit_right = int(float(_cols) * TILE)
		_cam.limit_top = 0
		_cam.limit_bottom = _cam_limit_bottom()
		_cam.global_position = _player.position + Vector2(0, -24.0)
		_cam.position = _cam.global_position
		_cam.make_current()
		_cam.reset_smoothing()
	_changing = false
	_dead = false
	_invuln_until = Time.get_ticks_msec() + 1200
	_last_saved = Vector2(-1, -1)
	Socket.send_pos(_map_id, _player.position.x, _player.position.y, _facing, "idle", true, _hp_pct())
	# Đồ rơi còn lại trên map (từ dữ liệu nhân vật)
	for l in Game.player.get("loot", []):
		if typeof(l) == TYPE_DICTIONARY and str((l as Dictionary).get("map", "")) == _map_id: _add_loot(l, false)
	_hud_dirty = true

func _clear_world() -> void:
	if _assist != null: _assist.clear()
	for u in _mobs.keys():
		var n: Node = _mobs[u]
		if is_instance_valid(n): n.queue_free()
	_mobs.clear()
	for id in _players.keys():
		var n2: Node = _players[id]
		if is_instance_valid(n2): n2.queue_free()
	_players.clear()
	for lid in _loots.keys():
		var n3: Node = _loots[lid]
		if is_instance_valid(n3): n3.queue_free()
	_loots.clear()
	_pickup_pending.clear()
	_interact = {}
	Social.nearby.clear()

func _theme_of(map_id: String) -> String:
	var th := str(Data.map_def(map_id).get("theme", "city"))
	return th if th in ["city", "forest", "cave", "redgate"] else "city"

func _cell(x: float, y: float) -> String:
	var c := int(floor(x / TILE))
	var r := int(floor(y / TILE))
	if r < 0 or c < 0 or c >= _cols or r >= _grid.size(): return "."
	return str((_grid[r] as Array)[c])

## Bake cache sau khi _grid/_cols/_rows sẵn sàng (gọi ở cuối _load_player_map).
func _bake_collision_cache() -> void:
	_stand_rows = []
	_stand_rows.resize(_cols)
	_walk_cache = []
	_walk_cache.resize(_rows * _cols)
	for c in range(_cols):
		_stand_rows[c] = []
		for r in range(_rows):
			var ch := str((_grid[r] as Array)[c])
			_walk_cache[r * _cols + c] = (ch != "#" and ch != "" and ch != " ")
			if ch == "#" or ch == "=": (_stand_rows[c] as Array).append(r)

func _walkable(x: float, y: float) -> bool:
	var c := int(floor(x / TILE))
	var r := int(floor(y / TILE))
	if r < 0 or c < 0 or c >= _cols or r >= _rows: return true
	return _walk_cache[r * _cols + c]

func _is_stand(r: int, c: int) -> bool:
	if r < 0 or r >= _rows or c < 0 or c >= _cols: return r >= _rows
	var ch := str((_grid[r] as Array)[c])
	return ch == "#" or ch == "="

## y mặt đất gần nhất bên dưới chân (theo ô của grid đã giãn).
func _ground_y(x: float, foot_y: float) -> float:
	var c := int(floor(x / TILE))
	var r := int(floor(foot_y / TILE))
	if c >= 0 and c < _stand_rows.size():
		# Tìm nhị phân hàng đứng đầu tiên >= r (cache đã sort). O(log rows) thay vì O(rows).
		var rows: Array = _stand_rows[c]
		var lo := 0
		var hi := rows.size()
		while lo < hi:
			var mid := (lo + hi) / 2
			if int(rows[mid]) < r: lo = mid + 1
			else: hi = mid
		if lo < rows.size(): return float(rows[lo]) * TILE
		return float(_rows) * TILE
	# Fallback (cache chưa bake): quét như cũ.
	for rr in range(maxi(0, r), _rows):
		if _is_stand(rr, c): return float(rr) * TILE
	return float(_rows) * TILE

## Đáy camera: chỉ chừa ~1.5 ô dưới mặt đất thấp nhất có thể đứng, để lớp đất sâu không chiếm cả màn hình.
const CAM_BELOW_GROUND := 64.0
func _cam_limit_bottom() -> int:
	var full := int(float(_rows) * TILE)
	var low := -1
	for c in range(_cols):
		for r in range(_rows - 1, -1, -1):
			if _is_stand(r, c) and (r == 0 or not _is_stand(r - 1, c)):
				low = maxi(low, r)
				break
	if low < 0: return full
	return mini(full, int(float(low) * TILE + CAM_BELOW_GROUND))

func _snap_to_ground() -> void:
	if _grid.is_empty(): return
	var gy := _ground_y(_player.position.x, _player.position.y + 30.0)
	_player.position.y = gy - 30.0
	_vy = 0.0

# ------------------------------------------------------------------ Vòng lặp
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("skill1"): _cast(0)
	elif event.is_action_pressed("skill2"): _cast(1)
	elif event.is_action_pressed("skill3"): _cast(2)
	elif event.is_action_pressed("skill4"): _cast(3)
	elif event.is_action_pressed("skill5"): _cast(4)
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_X: _cast(5)
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_V: _cast(8)
	elif event.is_action_pressed("attack"): _on_attack()

## Đồng bộ thú đồng hành / linh thú / bóng ma với dữ liệu server (xem src/world/Assist.gd).
func _sync_pet() -> void:
	if _assist != null: _assist.sync()

func _process(delta: float) -> void:
	if not Game.has_player(): return
	_move_step(minf(delta, 1.0 / 30.0))
	if _assist != null: _assist.tick(delta)
	# Nền bám đúng tâm màn hình THẬT của camera (đã bị chặn ở biên map), không phải vị trí nhân vật
	if _cam and _bg_node:
		_bg_node.set_camera(_cam.get_screen_center_position())
	_hud_acc += delta
	if _hud_dirty and _hud_acc > 0.1:
		_hud_acc = 0.0
		_hud_dirty = false
		_refresh_hud()
	# Chưa nhận được danh sách quái sau 3s: xin server gửi lại (vào phòng bằng pos r=1)
	if Socket.online and not Socket.mobs_received and Time.get_ticks_msec() - _enter_try > 3000:
		_on_socket_connected()
	_interact_acc += delta
	if _interact_acc >= 0.1:
		_interact_acc = 0.0
		_update_interact()
	elif _interact_mark != null and is_instance_valid(_interact_mark):
		# vẫn nhấp nhô mũi tên giữa các lần quét
		var it := str(_interact.get("type", ""))
		if it != "" and _interact.has("pos"):
			_interact_mark.position = (_interact["pos"] as Vector2) + Vector2(0, sin(_target_t * 7.7) * 4.0)
	_update_target(delta)
	_buff_hud_tick(delta)
	_regen(delta)
	_update_projectiles(delta)
	_stamina_tick(delta)
	_form_tick(delta)

## Độ phóng camera = Settings.world_zoom (nhỏ hơn = thấy rộng hơn). CHỈ phụ thuộc world_zoom,
## KHÔNG chia cho content_scale_factor như cũ — chính phép chia đó triệt tiêu hoàn tác dụng của
## tỉ lệ hiển thị (đổi 75/85/115% nhưng tầm nhìn thế giới y hệt). HUD nằm ở lớp canvas riêng nên
## content_scale_factor vẫn chỉnh cỡ chữ/nút bình thường, không ảnh hưởng tầm nhìn map.
## ---- Mục tiêu quái (mũi tên tam giác như web): quái gần nhất trong tầm được chỉ định, chỉ quái đó hiện tên.
## Chọn lại 5 lần/giây (không phải mỗi khung) với cùng tầm + cách tính điểm như web (target.js).
const TARGET_RX := 520.0
const TARGET_RY := 260.0
var _target_mob: Node2D = null
var _target_mark: Node2D = null
var _target_acc := 0.0
var _target_t := 0.0

func _update_target(delta: float) -> void:
	_target_t += delta
	_target_acc += delta
	if _target_acc >= 0.2:
		_target_acc = 0.0
		_pick_target()
	var ok: bool = _target_mob != null and is_instance_valid(_target_mob) and _target_mob.alive
	if not ok:
		if _target_mark != null: _target_mark.visible = false
		return
	if _target_mark == null or not is_instance_valid(_target_mark):
		_target_mark = _TargetMark.new()
		_target_mark.z_index = 50
		_mob_layer.add_child(_target_mark)
	# Đặt trên đầu quái (cùng mốc với dòng tên), nhấp nhô nhẹ
	_target_mark.visible = true
	_target_mark.position = _target_mob.position + Vector2(0, -_target_mob._height - 44.0 + sin(_target_t * 7.7) * 4.0)

func _pick_target() -> void:
	var best: Node2D = null
	var best_score := 1e9
	for u in _mobs.keys():
		var m: Node2D = _mobs[u]
		if not is_instance_valid(m) or not m.alive: continue
		var dx := absf(m.position.x - _player.position.x)
		var dy := absf(m.position.y - _player.position.y)
		if dx >= TARGET_RX or dy >= TARGET_RY: continue
		var score := dx + dy * 0.5
		if score < best_score:
			best_score = score
			best = m
	if best == _target_mob: return
	if _target_mob != null and is_instance_valid(_target_mob): _target_mob.show_name(false)
	_target_mob = best
	if best != null: best.show_name(true)

class _TargetMark extends Node2D:
	var col := Color(1.0, 0.32, 0.32)
	func _draw() -> void:
		var pts := PackedVector2Array([Vector2(-9, 0), Vector2(9, 0), Vector2(0, 14)])
		draw_colored_polygon(pts, col)
		draw_polyline(PackedVector2Array([pts[0], pts[1], pts[2], pts[0]]), Color(0, 0, 0, 0.8), 2.0)

func _apply_zoom() -> void:
	if _cam == null: return
	_cam.zoom = Vector2.ONE * Settings.world_zoom
	# Nền tính _view theo zoom của camera -> báo nó tính lại sau khi zoom đổi.
	if _bg_node != null and _bg_node.has_method("refresh_view"):
		_bg_node.refresh_view.call_deferred()

## Di chuyển + va chạm + camera: chạy trong _process với delta thật (giới hạn 1/30s). Trước đây ở _physics_process
## (60Hz cố định) trong khi hình vẽ theo nhịp màn hình, nên nhịp lệch nhau gây giật.
func _move_step(delta: float) -> void:
	if not Game.has_player() or _grid.is_empty(): return
	var now := Time.get_ticks_msec()
	var dir := _move_dir
	if Input.is_action_pressed("move_left") or Input.is_action_pressed("ui_left"): dir.x -= 1
	if Input.is_action_pressed("move_right") or Input.is_action_pressed("ui_right"): dir.x += 1
	var jump_pressed := Input.is_action_just_pressed("move_up") or Input.is_action_just_pressed("ui_up") or dir.y < -0.6 or _jump_req
	_jump_req = false
	var drop_pressed := Input.is_action_pressed("move_down") or dir.y > 0.6
	dir.y = 0.0
	if _dead or _changing: dir = Vector2.ZERO; jump_pressed = false
	if dir.length() > 1.0: dir = dir.normalized()

	var foot := _player.position.y + 30.0
	var gy := _ground_y(_player.position.x, foot)
	var on_ground := foot >= gy - 1.0 and _vy >= 0.0

	var tnow := Time.get_ticks_msec()
	if on_ground:
		_last_ground_at = tnow
		_jumped_air = false
	if jump_pressed: _jump_buffered_at = tnow
	var can_jump := on_ground or (tnow - _last_ground_at < 110 and not _jumped_air)
	if tnow - _jump_buffered_at < 140 and can_jump and not drop_pressed and not _dead and not _changing:
		_jump_buffered_at = -1000
		_vy = -JUMP_V
		_jumped_air = true
		on_ground = false

	if not on_ground:
		# Tích phân chính xác theo dt: độ cao nhảy không phụ thuộc FPS
		_player.position.y += _vy * delta + 0.5 * GRAVITY * delta * delta
		_vy += GRAVITY * delta
		foot = _player.position.y + 30.0
		gy = _ground_y(_player.position.x, foot)
		if _vy >= 0.0 and foot >= gy:
			_player.position.y = gy - 30.0
			_vy = 0.0
			on_ground = true
	else:
		_player.position.y = gy - 30.0
		_vy = 0.0

	# Tốc độ theo chỉ số (nhanh nhẹn, đồ, class) x buff tốc độ; trùm làm chậm thì còn 60% (updatePlayer của web)
	var spd := float(Game.stats.get("speed", SPEED)) * (1.0 + _buff_sum("speed") * 0.3)
	if now < _slow_until: spd *= 0.6
	var vx := dir.x * spd
	if now < _knock_until: vx = _knock_vx
	if absf(vx) > 1.0:
		if now >= _knock_until and dir.x != 0.0:
			_facing = 1 if dir.x > 0 else -1
			_set_facing(_facing)
		var nx := _player.position.x + vx * delta
		nx = clampf(nx, 20.0, float(_cols) * TILE - 20.0)
		var foot_x := _player.position.y + 30.0
		var blocked := not _walkable(nx, foot_x - 2.0)
		if blocked and on_ground:
			var step_gy := _ground_y(nx, foot_x - TILE)
			if step_gy >= 0.0 and foot_x - step_gy <= TILE * 0.75 and _walkable(nx, step_gy - 4.0):
				_player.position.y = step_gy - 30.0
				blocked = false
		if not blocked:
			_player.position.x = nx
			var ngy := _ground_y(nx, _player.position.y + 30.0)
			if _player.position.y + 30.0 < ngy and _vy >= 0.0 and on_ground:
				# Nội suy lên bậc thang thay vì gán cứng -> không bị giật từng ô.
				var want_y := ngy - 30.0
				_player.position.y = lerpf(_player.position.y, want_y, clampf(delta * 14.0, 0.0, 1.0))
				if absf(_player.position.y - want_y) < 0.5: _player.position.y = want_y

	# Hoạt ảnh (ưu tiên: chết > bị đánh > tấn công > trên không > chạy > đứng)
	var moving := absf(vx) > 1.0 and now >= _knock_until
	if _dead: _anim = "death"
	elif now < _hurt_until: _anim = "hit"
	elif now < _attack_until: _anim = "attack1"
	elif not on_ground: _anim = "jump" if _vy < 0.0 else "fall"
	elif moving: _anim = "run"
	else: _anim = "idle"
	_play_anim(_anim)
	Socket.send_pos(_map_id, _player.position.x, _player.position.y, _facing, _server_anim(_anim), false, _hp_pct())

	# Quái: nhắm tên theo khoảng cách + kiểm đòn lao trúng mình
	var prect := Rect2(_player.position.x - 12.0, _player.position.y - 28.0, 24.0, 58.0)
	for u in _mobs.keys():
		var m: Node2D = _mobs[u]
		if not is_instance_valid(m) or not m.alive: continue
		if m.state != 2 or m.lunge_hit or m.atk <= 0 or _dead: continue
		# Lọc tầm bằng số trước khi tạo Rect2: chỉ quái thật sự gần mới cần hộp va chạm.
		if absf(m.position.x - _player.position.x) > 90.0: continue
		if absf(m.position.y - _player.position.y) > 90.0: continue
		var br: Rect2 = m.body_rect().grow(-4.0)
		if br.intersects(prect):
			m.lunge_hit = true
			_hurt_player(m)

	if _cam:
		# Lệch camera lên trên một chút: nhân vật nằm thấp hơn giữa màn hình, thấy nhiều trời/map phía trên hơn.
		# Smooth follow frame-rate-independent (exp): mượt mà không bị giật từng khung, vẫn bám sát khi chạy.
		var cam_target := _player.position + Vector2(0, -24.0)
		var cam_k := 1.0 - exp(-14.0 * delta)
		_cam.position = _cam.position.lerp(cam_target, cam_k)
		# Bám ngay nếu lệch quá xa (đổi map/teleport/dịch chuyển không qua _reload_after_move).
		if _cam.position.distance_squared_to(cam_target) > 40000.0: _cam.position = cam_target

	# Lưu định kỳ
	_save_acc += delta
	if _save_acc >= SAVE_EVERY and not _dead and not _changing:
		_save_acc = 0.0
		# Chỉ lưu khi vị trí / máu / mana / thú đổi so với lần lưu trước; đứng yên không đổi gì thì cứ 30 giây
		# mới lưu một lần (giữ nhịp sống). Rời map / mua bán / thoát đã có đường lưu riêng nên không phụ thuộc chỗ này.
		var p := Vector2(roundf(_player.position.x), roundf(_player.position.y))
		var sig := hash([p, Game.hp, Game.mp, _pets_payload()])
		_save_idle += SAVE_EVERY
		if p != _last_saved or sig != _last_saved_sig or _save_idle >= SAVE_IDLE_MAX:
			_last_saved = p
			_last_saved_sig = sig
			_save_idle = 0.0
			_save_state()

func _server_anim(a: String) -> String:
	match a:
		"attack1", "attack2", "attack3": return "atk"
		"death": return "dead"
		"jump", "fall", "run", "hit", "idle": return a
	return "idle"

func _set_facing(f: int) -> void:
	if _player_sprite != null and is_instance_valid(_player_sprite) and _player_sprite.has_method("set_facing"):
		_player_sprite.set_facing(f)

func _play_anim(a: String) -> void:
	if _player_sprite != null and is_instance_valid(_player_sprite) and _player_sprite.has_method("play"):
		_player_sprite.play(a)

func _hp_pct() -> int:
	var mx := maxi(1, int(Game.stats.get("maxHp", 100)))
	return clampi(int(roundf(float(Game.hp) / float(mx) * 100.0)), 0, 100)

# ------------------------------------------------------------------ Chiến đấu
func _atk_stat() -> int:
	var st: Dictionary = Game.stats
	if st.is_empty(): st = Game.player.get("stats", {})
	return int(st.get("atk", Game.player.get("atk", 30)))

## Quét hình chữ nhật trước mặt, gửi đòn cho MỌI quái trúng (khớp hitBox của web).
## Tổng một chỉ số buff (atk / crit / speed) của mọi hiệu ứng còn hạn — cộng dồn như web (buffTotals).
func _buff_sum(key: String) -> float:
	var now := Time.get_ticks_msec()
	var t := 0.0
	for id in _buffs.keys():
		var b: Dictionary = _buffs[id]
		if now < int(b.get("until", 0)): t += float(b.get(key, 0.0))
	return t

## Như trên nhưng chỉ tính buff cùng loại (guard: reduce/reflect, manashield: absorb).
func _buff_sum_of(name: String, key: String) -> float:
	var now := Time.get_ticks_msec()
	var t := 0.0
	for id in _buffs.keys():
		var b: Dictionary = _buffs[id]
		if now < int(b.get("until", 0)) and str(b.get("name", "")) == name: t += float(b.get(key, 0.0))
	return t

## Buff đang bật mang tên này ({} nếu không có) — buffOn của web.
func _buff_on(name: String) -> Dictionary:
	var now := Time.get_ticks_msec()
	for id in _buffs.keys():
		var b: Dictionary = _buffs[id]
		if now < int(b.get("until", 0)) and str(b.get("name", "")) == name: return b
	return {}

func _add_buff(id: String, sk: Dictionary, stype: String) -> void:
	var dur := float(sk.get("duration", 0.0))
	if dur <= 0.0: return
	_buffs[id] = {
		"name": str(sk.get("buff", id)) if stype == "buff" else stype, "until": Time.get_ticks_msec() + int(dur * 1000.0),
		"reduce": float(sk.get("reduce", 0.0)), "reflect": float(sk.get("reflect", 0.0)), "absorb": float(sk.get("absorb", 0.0)),
		"atk": float(sk.get("atkBuff", 0.0)), "crit": float(sk.get("critBuff", 0.0)), "speed": float(sk.get("speedBuff", 0.0)),
		"regen": float(sk.get("regen", 0.0)), "exec": sk.get("exec", null), "dur": int(dur * 1000.0), "skill": id,
	}

## Hồi máu theo % máu tối đa; Trị Liệu Sư hồi thêm 20% (skillHeal của web).
func _skill_heal(ratio: float) -> void:
	var boost := 1.2 if Game.has_passive("tri_lieu_su") else 1.0
	var mx := int(Game.stats.get("maxHp", 1))
	var amount := int(roundf(float(mx) * ratio * boost))
	Game.hp = mini(mx, Game.hp + amount)
	FloatText.spawn(_fx, _player.position + Vector2(0, -30), "+%d" % amount, Color(0.41, 0.94, 0.68), 16)
	_hud_dirty = true

## Sát thương một đòn lên một con quái — cùng công thức calcDamage của web:
## ATK x hệ số x (1+buff) x trùm x (1-giáp quái) x [0.9,1.1], chí mạng x1.6 (Cung Thủ x1.8), trần chí mạng 90%.
func _calc_hit(mob: Node2D, mult: float, boss_bonus: float, pierce: Dictionary, basic: bool = false) -> Dictionary:
	var pierced := false
	if not pierce.is_empty():
		pierced = mob.mob_level >= int(pierce.get("minLevel", 1)) and mob.mob_level <= int(pierce.get("maxLevel", 999))
	# Chỉ boss / thủ lĩnh mới chịu "sát thương lên trùm" (web: def.boss || def.leader; trùm cuối không có cờ này thì không tính)
	var md: Dictionary = Data.monster(mob.mob_id)
	var boss_mul := 1.0 + boss_bonus / 100.0 if (bool(md.get("boss", false)) or bool(md.get("leader", false))) else 1.0
	var armor := 1.0 if pierced else 1.0 - Formulas.def_reduce(float(mob.def_stat), mob.mob_level)
	# Buff "exec": nhân thêm khi quái dưới ngưỡng máu
	var now_ms := Time.get_ticks_msec()
	for bid in _buffs.keys():
		var bb: Dictionary = _buffs[bid]
		var ex: Dictionary = Game._as_dict(bb.get("exec", {}))
		if not ex.is_empty() and now_ms < int(bb.get("until", 0)) and float(mob.hp) <= float(mob.max_hp) * float(ex.get("below", 0.0)): mult *= float(ex.get("mult", 1.0))
	var dmg := float(_atk_stat()) * mult * (1.0 + _buff_sum("atk")) * boss_mul * armor
	dmg = maxf(1.0, dmg) * randf_range(0.9, 1.1)
	var crit_p := minf(90.0, float(Game.stats.get("crit", 3.0)) + _buff_sum("crit"))
	var crit := randf() * 100.0 < crit_p
	if crit:
		if _shadow_crit and Game.has_passive("sat_thu"):
			dmg *= 2.5
			_shadow_crit = false
		else:
			dmg *= 1.8 if Game.has_passive("cung_thu") else 1.6
	var out := maxi(1, int(roundf(dmg)))
	# Kháng đòn thường áp sau chí mạng + làm tròn (web: combat.js damageMonster)
	if basic and mob.resist > 0.0: out = maxi(1, int(roundf(float(out) * (1.0 - mob.resist))))
	return {"dmg": out, "crit": crit}

var _shadow_crit := false

# ------------------------------------------------------------------ Chiến đấu: vùng trúng đòn (hitBox / hitCircle / shoot của web)
const HIT_GAP := 0.13
const ProjScript := preload("res://src/world/Proj.gd")

func _weapon() -> Dictionary:
	var wt: Dictionary = Game._as_dict(Data.calc.get("WEAPON_TYPES", {}))
	var w: Variant = wt.get(str(Game.stats.get("wtype", "tay")), null)
	if typeof(w) == TYPE_DICTIONARY: return w
	return {"range": 74.0, "cooldown": 360.0, "mult": 1.0, "style": "melee"}

## Bối cảnh một lượt đòn: hiệu ứng trang bị tính 1 lần cho mọi quái trúng.
func _hit_ctx() -> Dictionary:
	var fx: Dictionary = Game.special_fx()
	return {"boss": float(Game.stats.get("boss", 0.0)), "lifesteal": float(Game.stats.get("lifesteal", 0.0)),
		"pierce": Game._as_dict(fx.get("pierce", {})), "nth": Game._as_dict(fx.get("everyNth", {})),
		"freeze": Game._as_dict(fx.get("setFreeze", {})), "aura": Game._as_dict(fx.get("slowAura", {}))}

## Vùng trúng: {"kind":"rect","cx","cy","w","h"} hoặc {"kind":"circle","cx","cy","r"}.
func _shape_hits(shape: Dictionary, r: Rect2) -> bool:
	var cx := float(shape["cx"])
	var cy := float(shape["cy"])
	if str(shape.get("kind", "rect")) == "circle":
		var rad := float(shape["r"])
		var nx := clampf(cx, r.position.x, r.position.x + r.size.x)
		var ny := clampf(cy, r.position.y, r.position.y + r.size.y)
		return (nx - cx) * (nx - cx) + (ny - cy) * (ny - cy) <= rad * rad
	var w := float(shape["w"])
	var h := float(shape["h"])
	return Rect2(cx - w * 0.5, cy - h * 0.5, w, h).intersects(r)

## Một lượt đòn lên mọi quái nằm trong vùng. `power` chưa nhân skillMul (kỹ năng) — hàm tự nhân.
func _strike_shape(shape: Dictionary, skill_id: String, power: float, kind: int, extra: Dictionary = {}) -> int:
	var skill_mul := float(Game.stats.get("skillMul", 1.0)) if kind > 0 else 1.0
	var mult := maxf(0.05, power) * skill_mul
	var ctx := _hit_ctx()
	var n := 0
	if extra.has("chain") and not extra.has("chainBudget"): extra["chainBudget"] = {"n": 6}   # tối đa 6 mục tiêu lan cho CẢ lần tung (như web), không phải mỗi quái
	# Có quái đang chỉ định nằm trong vùng chém -> chỉ trúng đúng con đó (web: hitBox `only`)
	var only: Node2D = null
	if bool(extra.get("only_target", false)) and _target_mob != null and is_instance_valid(_target_mob) and _target_mob.alive and _shape_hits(shape, _target_mob.body_rect()): only = _target_mob
	for u in _mobs.keys():
		var mob: Node2D = _mobs[u]
		if not is_instance_valid(mob) or not mob.alive or (only != null and mob != only): continue
		if _shape_hits(shape, mob.body_rect()):
			_hit_mob(int(u), mob, mult, kind, skill_id, extra, ctx)
			n += 1
	return n

## Nhiều nhát liên tiếp (cận chiến): nhát cuối dùng `finisher` nếu có. Hộp trước mặt rộng `range_px`.
func _strike(range_px: float, skill_id: String, power: float, kind: int, hits: int = 1, gap: float = HIT_GAP, extra: Dictionary = {}, height: float = 70.0) -> void:
	for i in range(hits):
		if i > 0: await get_tree().create_timer(gap).timeout
		if _dead or not is_inside_tree(): return
		var pw := power
		var is_last := i == hits - 1
		if extra.has("finisher") and is_last: pw = float(extra["finisher"])
		# Hất văng / choáng dồn vào nhát CUỐI; làm chậm / đóng băng / phá giáp thì nhát nào cũng ăn (như web)
		var hx := extra.duplicate()
		hx["only_target"] = true
		if not is_last:
			hx["knock"] = 0.0
			hx["stun"] = 0.0
		var shape := {"kind": "rect", "cx": _player.position.x + float(_facing) * range_px * 0.5, "cy": _player.position.y, "w": range_px, "h": height}
		_strike_shape(shape, skill_id, pw, kind, hx)

func _after(sec: float, cb: Callable) -> void:
	await get_tree().create_timer(sec).timeout
	if not is_inside_tree(): return
	cb.call()

## Lõi một đòn lên một con quái: tính sát thương, hiệu ứng trang bị, gửi server, hút máu, dây chuyền.
func _hit_mob(u: int, mob: Node2D, mult: float, kind: int, skill_id: String, extra: Dictionary, ctx: Dictionary) -> void:
	var m2 := mult
	# Kỹ năng gấp bội lên quái đang bị làm chậm / đóng băng
	if extra.has("vsSlowed") and (int(mob.flags) & 3) != 0: m2 *= float(extra["vsSlowed"])
	var r := _calc_hit(mob, m2, float(ctx["boss"]), ctx["pierce"], kind == 0)
	var dmg := int(r["dmg"])
	# Ấn Sát (Kỳ Nguyên Sát Kiếp): cứ n đòn trúng một mục tiêu thì đòn thứ n nặng hơn, đếm riêng từng quái
	var nth: Dictionary = ctx["nth"]
	if not nth.is_empty():
		var cnt := int(_nth_count.get(u, 0)) + 1
		if cnt >= int(nth.get("n", 5)):
			cnt = 0
			dmg = maxi(1, int(roundf(float(dmg) * float(nth.get("mult", 1.0)))))
			FloatText.spawn(_fx, mob.position + Vector2(0, -70), "Ấn Sát", Color(1.0, 0.84, 0.33), 15)
		_nth_count[u] = cnt
	# Tên Phá Giáp: quái đang bị phá giáp chịu thêm sát thương; đòn mang `shred` (đặt lại 6 giây) — như web
	var now_sh := Time.get_ticks_msec()
	if mob.shred_until > now_sh: dmg = maxi(1, int(roundf(float(dmg) * (1.0 + mob.shred))))
	if float(extra.get("shred", 0.0)) > 0.0:
		mob.shred = float(extra["shred"])
		mob.shred_until = now_sh + 6000
	var hit_x: Dictionary = {"slow": float(extra.get("slow", 0.0)), "freeze": float(extra.get("freeze", 0.0)), "stun": float(extra.get("stun", 0.0))}
	if extra.has("knock"): hit_x["knock"] = float(extra["knock"])
	# Bộ Băng Long 10 món: đòn có cơ hội đóng băng quái
	var freeze_fx: Dictionary = ctx["freeze"]
	if not freeze_fx.is_empty() and not bool(mob.passive) and hit_x["freeze"] <= 0.0 and randf() < float(freeze_fx.get("chance", 0.0)):
		hit_x["freeze"] = float(freeze_fx.get("dur", 2.0))
		FloatText.spawn(_fx, mob.position + Vector2(0, -84), "Đóng Băng", Color(0.5, 0.85, 1.0), 14)
	# Kiếm Thượng Băng Sương: quái trong tầm bị làm chậm
	var aura: Dictionary = ctx["aura"]
	if not aura.is_empty() and absf(mob.position.x - _player.position.x) < float(aura.get("range", 170.0)):
		hit_x["slow"] = maxf(float(hit_x["slow"]), 0.5)
	var dir := 1 if mob.position.x >= _player.position.x else -1
	_last_hit_uid = u
	_last_hit_at = Time.get_ticks_msec()
	if skill_id != "" and _skill_fx != null and _skill_fx.has_method("play_hit"):
		_skill_fx.play_hit(skill_id, (mob.body_rect() as Rect2).get_center(), 1 if mob.position.x >= _player.position.x else -1)   # hiệu ứng riêng của kỹ năng trên đúng quái bị trúng
	Socket.send_hit(u, dmg, skill_id, kind, dir, bool(r["crit"]), hit_x)
	if not bool(mob.passive) and not _dead:
		var mxh := int(Game.stats.get("maxHp", 1))
		var ls := float(ctx["lifesteal"])
		if ls > 0.0: Game.hp = mini(mxh, Game.hp + _carry("lifesteal", float(dmg) * ls / 100.0))   # cộng dồn phần lẻ, hút máu nhỏ không bị làm tròn về 0
		# Nội tại Kiếm Tâm: đánh thường trúng quái hồi 0,5% máu tối đa
		if kind == 0 and Game.has_passive("kiem_si") and Time.get_ticks_msec() > _heal_tick:
			_heal_tick = Time.get_ticks_msec() + 120
			Game.hp = mini(mxh, Game.hp + _carry("kiem_tam", float(mxh) * 0.005))
	# Dây chuyền: lan sang quái gần mục tiêu (tối đa 6 con)
	if extra.has("chain"):
		var cbud: Dictionary = extra.get("chainBudget", {"n": 6})
		var budget := int(cbud.get("n", 6))
		var rad := float(extra.get("chainRadius", 150.0))
		for u2 in _mobs.keys():
			if budget <= 0: break
			var o: Node2D = _mobs[u2]
			if int(u2) == u or not is_instance_valid(o) or not o.alive or bool(o.passive): continue
			if o.position.distance_to(mob.position) <= rad:
				budget -= 1
				cbud["n"] = budget
				var rc := _calc_hit(o, m2 * float(extra["chain"]), float(ctx["boss"]), ctx["pierce"], false)
				Socket.send_hit(int(u2), int(rc["dmg"]), skill_id, kind, dir, bool(rc["crit"]))

# ---- Đạn bay
var _projs: Array = []

## o: speed, range, mult (đã nhân skillMul), angle, dy, pierce, skill_id, kind, extra, color, basic, arrow
func _shoot(o: Dictionary) -> void:
	var node: Node2D = ProjScript.new()
	node.position = _player.position + Vector2(float(_facing) * 16.0, -2.0 + float(o.get("dy", 0.0)))
	var ang := float(o.get("angle", 0.0))
	node.setup(o.get("color", Color(1.0, 0.6, 0.3)), ang, _facing, float(o.get("size", 1.0)), bool(o.get("arrow", false)))
	var pinfo: Dictionary = _skill_fx.proj_info(str(o.get("skill_id", ""))) if (_skill_fx != null and _skill_fx.has_method("proj_info")) else {}
	if not pinfo.is_empty(): node.setup_skill(str(o["skill_id"]), pinfo["col"], pinfo["core"], bool(pinfo["dark"]))   # đạn mang hình riêng của kỹ năng
	_fx.add_child(node)
	var spd := float(o.get("speed", 700.0))
	# Đạn đơn mục tiêu bay vào đúng quái đang chỉ định, bỏ qua quái khác chắn đường (đạn xuyên thì trúng hết)
	var focus: Node2D = _target_mob if (not bool(o.get("pierce", false)) and _target_mob != null and is_instance_valid(_target_mob) and _target_mob.alive) else null
	_projs.append({"node": node, "v": Vector2(cos(ang) * spd * float(_facing), sin(ang) * spd), "dist": 0.0, "hit": {}, "o": o, "focus": focus})

func _free_proj(p: Dictionary) -> void:
	var n: Variant = p.get("node", null)
	if n != null and is_instance_valid(n): (n as Node).queue_free()
	_projs.erase(p)

func _update_projectiles(delta: float) -> void:
	if _projs.is_empty(): return
	var ctx := {}   # tính lười: chỉ khi có đạn trúng (special_fx khá tốn)
	# Chạy ngược bằng chỉ số: không cấp phát mảng mới mỗi khung, vẫn xoá an toàn khi trúng/đạn hết tầm.
	var pi := _projs.size() - 1
	while pi >= 0:
		var p: Dictionary = _projs[pi]
		pi -= 1
		var node: Node2D = p["node"]
		if not is_instance_valid(node): _projs.erase(p); continue
		var o: Dictionary = p["o"]
		var step: Vector2 = (p["v"] as Vector2) * delta
		node.position += step
		p["dist"] = float(p["dist"]) + step.length()
		if float(p["dist"]) > float(o.get("range", 400.0)) or _cell(node.position.x, node.position.y) == "#":
			_free_proj(p); continue
		var box := Rect2(node.position - Vector2(12, 9), Vector2(24, 18))
		for u in _mobs.keys():
			var mob: Node2D = _mobs[u]
			if not is_instance_valid(mob) or not mob.alive or (p["hit"] as Dictionary).has(u): continue
			if absf(mob.position.x - node.position.x) > 350.0: continue
			var fo: Variant = p.get("focus", null)
			if fo != null and is_instance_valid(fo) and (fo as Node2D).alive and mob != fo: continue
			# Lọc tầm dọc trước khi tạo hộp va chạm (đạn bay ngang tầm ngực).
			if absf(mob.position.y - node.position.y) > 90.0: continue
			var mr: Rect2 = mob.body_rect()
			# Quái thấp vẫn bị đạn tầm ngực trúng (web dùng khung sprite cao hơn): nới khung lên tối thiểu 70px
			if mr.size.y < 70.0: mr = Rect2(mr.position.x, mr.end.y - 70.0, mr.size.x, 70.0)
			if box.intersects(mr):
				(p["hit"] as Dictionary)[u] = true
				if ctx.is_empty(): ctx = _hit_ctx()
				_hit_mob(int(u), mob, float(o.get("mult", 1.0)), int(o.get("kind", 0)), str(o.get("skill_id", "")), o.get("extra", {}), ctx)
				if not bool(o.get("pierce", false)):
					_free_proj(p)
					break

func _skill_extra(sk: Dictionary) -> Dictionary:
	var sx := {}
	for key in ["slow", "freeze", "stun", "knock", "vsSlowed", "chain", "finisher", "shred"]:
		if sk.has(key): sx[key] = sk[key]
	return sx

func _proj_color(sk: Dictionary) -> Color:
	if str(sk.get("school", "")) == "phap_su": return Color(0.45, 0.78, 1.0)
	return Color(1.0, 0.62, 0.28)

## Gây sát thương của một kỹ năng theo đúng dạng của web (xem WorldSkills.castSkill).
func _skill_damage(id: String, sk: Dictionary, stype: String, kind: int) -> void:
	if stype in ["melee", "projectile", "spread", "sword_fall", "meteor", "arrow_rain"]: _aim_at_target()   # quay mặt về quái đang chỉ định (web: aimAtTarget)
	var power := float(sk.get("power", 0.0))
	var sx := _skill_extra(sk)
	var fa := float(_facing)
	var px := _player.position.x
	var py := _player.position.y
	var smul := float(Game.stats.get("skillMul", 1.0))
	# Mục tiêu đang nhắm: các chiêu rơi (kiếm/đá/mưa tên) phải trúng đúng quái trong tầm,
	# không phải điểm cố định trước mặt người chơi (quái có thể đứng lệch trên/dưới hoặc sau lưng).
	var aim: Node2D = _target_mob if (_target_mob != null and is_instance_valid(_target_mob) and _target_mob.alive) else null
	var aim_x := px + fa * 140.0
	var aim_y := py
	if aim != null:
		aim_x = aim.position.x
		aim_y = aim.position.y - float(aim.get("_height")) * 0.5
	match stype:
		"melee":
			_strike(float(sk.get("range", 90.0)), id, power, kind, maxi(1, int(sk.get("hits", 1))), HIT_GAP, sx)
		"aoe":
			_strike_shape({"kind": "circle", "cx": px, "cy": py, "r": float(sk.get("radius", 160.0))}, id, power, kind, sx)
		"sword_fall":
			var cnt_s := mini(int(sk.get("count", 1)), 3)
			for k in range(cnt_s):
				# Có mục tiêu: tất cả kiếm rơi quanh mục tiêu. Không có: rơi trước mặt như cũ.
				var x := clampf(aim_x + fa * (float(k) - float(cnt_s - 1) * 0.5) * 70.0, 30.0, float(_cols) * TILE - 30.0)
				var kx := sx.duplicate(); kx["knock"] = float(sk.get("knock", 300.0))
				_after(float(k) * 0.22 + 0.3, func(): _strike_shape({"kind": "circle", "cx": x, "cy": aim_y, "r": float(sk.get("radius", 120.0))}, id, power, kind, kx))
		"meteor":
			var cnt_m := maxi(1, int(sk.get("count", 1)))
			for k in range(cnt_m):
				var x2 := clampf(aim_x + fa * (float(k) - float(cnt_m - 1) * 0.5) * 90.0, 30.0, float(_cols) * TILE - 30.0)
				var km := sx.duplicate(); km["knock"] = float(sk.get("knock", 260.0)); km["chainRadius"] = 170.0
				_after(float(k) * 0.42 + 0.6, func(): _strike_shape({"kind": "circle", "cx": x2, "cy": aim_y, "r": float(sk.get("radius", 120.0))}, id, power, kind, km))
			if float(sk.get("heal", 0.0)) > 0.0: _skill_heal(float(sk["heal"]))
		"arrow_rain":
			var width := float(sk.get("width", 300.0))
			var cx := clampf(aim_x, 30.0, float(_cols) * TILE - 30.0)
			var n := maxi(1, int(sk.get("arrows", 1)))
			for i in range(n):
				var ax := cx + randf_range(-width * 0.5, width * 0.5)
				_after(0.15 + float(i) * (1.2 / float(n)) + 0.26, func(): _strike_shape({"kind": "rect", "cx": ax, "cy": aim_y, "w": 46.0, "h": 90.0}, id, power, kind, sx))
		"projectile":
			var water := str(sk.get("school", "")) == "phap_su"
			var cnt := maxi(1, int(sk.get("count", 1)))
			for k in range(cnt):
				var ex := sx.duplicate()
				if not ex.has("knock"): ex["knock"] = 140.0 if water else 60.0
				_shoot({"speed": 520.0 if water else 820.0, "range": float(sk.get("range", 400.0)), "mult": power * smul, "kind": kind, "skill_id": id,
					"pierce": bool(sk.get("pierce", false)), "extra": ex, "dy": (float(k) - float(cnt - 1) * 0.5) * 16.0, "angle": _target_angle(), "color": _proj_color(sk)})
		"spread":
			var cs := maxi(1, int(sk.get("count", 1)))
			for k in range(cs):
				_shoot({"speed": 760.0, "range": float(sk.get("range", 400.0)), "mult": power * smul, "kind": kind, "skill_id": id,
					"pierce": bool(sk.get("pierce", false)), "extra": sx, "angle": (float(k) - float(cs - 1) * 0.5) * 0.16 + _target_angle(), "color": _proj_color(sk)})
		"backstep":
			var now := Time.get_ticks_msec()
			_invuln_until = maxi(_invuln_until, now + 450)
			_knock_vx = -fa * 650.0
			_knock_until = now + 260
			_vy = -320.0
			var cb := maxi(1, int(sk.get("count", 1)))
			_after(0.12, func():
				for k in range(cb):
					_shoot({"speed": 780.0, "range": 420.0, "mult": power * smul, "kind": kind, "skill_id": id, "extra": sx,
						"angle": (float(k) - float(cb - 1) * 0.5) * 0.12, "color": _proj_color(sk)}))
		"shadow_command":
			var target := _nearest_mob(500.0, 200.0)
			var cx2 := px + fa * 100.0
			var cy2 := py
			if target != null:
				cx2 = target.position.x; cy2 = target.position.y - 20.0
				_shadow_focus = int(target.uid); _shadow_focus_until = Time.get_ticks_msec() + 6000
			_strike_shape({"kind": "circle", "cx": cx2, "cy": cy2, "r": float(sk.get("radius", 200.0))}, id, power, kind, sx)

var _shadow_focus := 0
var _shadow_focus_until := 0

func _nearest_mob(range_x: float, reach_y: float) -> Node2D:
	var best: Node2D = null
	var bd := 1e9
	for u in _mobs.keys():
		var m: Node2D = _mobs[u]
		if not is_instance_valid(m) or not m.alive or bool(m.passive): continue
		var dx := absf(m.position.x - _player.position.x)
		if dx < range_x and absf(m.position.y - _player.position.y) < reach_y and dx < bd:
			bd = dx; best = m
	return best

func _on_attack() -> void:
	if _dead or _changing: return
	# Có NPC / đồ rơi / cổng ngay cạnh và không có quái sát bên: nút Đánh dùng để tương tác (như Ninja School).
	if not _interact.is_empty() and _nearest_mob(110.0, 90.0) == null:
		_do_interact()
		return
	var now := Time.get_ticks_msec()
	if now < _next_attack: return
	var w := _weapon()
	if not _spend_sta(_attack_sta_cost()): return
	_next_attack = now + int(float(w.get("cooldown", 360.0)) / (1.0 + _buff_sum("speed")))
	_attack_until = now + 280
	var style := str(w.get("style", "melee"))
	var wmult := float(w.get("mult", 1.0))
	var wrange := float(w.get("range", 74.0))
	if style == "melee":
		Audio.play("hit", 1.2)
		_fxs.slash(_player.position + Vector2(0, 6), _facing, Color(1.0, 0.95, 0.8), 1.0, int(now / 340) % 2 == 0)
		_strike_shape({"kind": "rect", "cx": _player.position.x + float(_facing) * wrange * 0.5, "cy": _player.position.y, "w": wrange, "h": 60.0}, "", wmult, 0, {"only_target": true})
	elif style == "projectile":
		Audio.play("cast", 1.3)
		var orb := str(w.get("proj", "")) == "proj_orb"
		_shoot({"speed": float(w.get("speed", 720.0)), "range": wrange, "mult": wmult, "kind": 0, "skill_id": "", "extra": {"knock": 90.0}, "angle": _target_angle(),
			"color": Color(0.75, 0.6, 1.0) if orb else Color(0.9, 0.85, 0.7), "arrow": not orb})
	else:
		Audio.play("cast", 1.1)
		_shoot({"speed": 460.0, "range": wrange, "mult": wmult, "kind": 0, "skill_id": "", "pierce": true, "extra": {"knock": 160.0}, "angle": _target_angle(),
			"color": Color(0.6, 0.85, 1.0), "size": 1.3})

func _cast(index: int) -> void:
	if _dead or _changing or index >= 9: return
	var id := _btn_skill(index)
	var sk: Dictionary = Data.skill_eff(Game.player, id)
	if sk.is_empty():
		if _hud_node: _hud_node.toast("Ô kỹ năng trống — mở Kỹ năng để gán", "warn")
		return
	var now := Time.get_ticks_msec()
	if now < int(_cd_until[index]):
		return
	var cost := int(roundf(float(sk.get("mp", 0)) * float(Game.stats.get("costMul", 1.0))))
	# Bộ Lưu Trữ 10 món (Cổ Ngữ): kỹ năng đầu tiên mỗi trận không tốn năng lượng
	var free_cast: bool = Game.special_fx().has("setFreeCast") and not _free_cast_used
	if free_cast: cost = 0
	if Game.mp < cost:
		if _hud_node: _hud_node.toast("Không đủ MP", "warn")
		return
	var sta_cost: float = float(Data.STAMINA.get("ult", 50.0)) if bool(sk.get("ult", false)) else float(Data.STAMINA.get("skill", 14.0))
	if not _spend_sta(sta_cost): return
	Game.mp -= cost
	if free_cast:
		_free_cast_used = true
		FloatText.spawn(_fx, _player.position + Vector2(0, -60), "Cổ Ngữ", Color(0.31, 0.76, 0.97), 14)
	var cd := float(sk.get("cd", 1.0)) * (1.0 - float(Game.stats.get("cdr", 0.0)) / 100.0)
	_cd_until[index] = now + int(cd * 1000.0)
	if _hud_node: _hud_node.start_cooldown(index, cd)
	var stype0 := str(sk.get("type", ""))
	var exec_target: Node2D = null
	if stype0 == "execute":
		exec_target = _exec_target(float(sk.get("range", 520.0)), float(sk.get("reach", 320.0)))
		if exec_target == null:
			if _hud_node: _hud_node.toast("Không có mục tiêu trong tầm", "warn")
			_cd_until[index] = 0
			Game.mp += cost
			return
	if stype0 != "fusion" and stype0 != "execute":
		Socket.send_cast(id, _player.position.x, _player.position.y)
	Audio.play("cast")
	_attack_until = now + 320
	# Chiêu rơi (kiếm/đá/mưa tên): căn hiệu ứng vào mục tiêu đang nhắm để kiếm đâm đúng quái.
	var fx_origin := _player.position
	if stype0 in ["sword_fall", "meteor", "arrow_rain"] and _target_mob != null and is_instance_valid(_target_mob) and _target_mob.alive:
		fx_origin = _target_mob.position
	if _skill_fx and _skill_fx.has_method("play"):
		_skill_fx.play("cast", id, fx_origin, _facing)
	var custom_fx: bool = _skill_fx != null and _skill_fx.has_method("has_custom") and _skill_fx.has_custom(id)   # có hình riêng -> bỏ hiệu ứng chung theo loại
	var kind := 3 if bool(sk.get("superUlt", false)) else (2 if bool(sk.get("ult", false)) else 1)
	var stype := str(sk.get("type", ""))
	match stype:
		"manaburst": Socket.send_manaburst()
		"allin": Socket.send_allin()
		"fusion": Socket.send_fusion()
		"execute":
			if exec_target != null:
				Socket.send({"t": "exec", "u": int(exec_target.get("uid")), "bua": 0})
				_fxs.ring(exec_target.position, Color(1, 1, 1), 90.0, 0.5, 5.0)
				shake(5.0, 0.25)
				Game.hp = 0
				_die()
		"dash":
			var x0 := _player.position.x
			_dash(float(sk.get("distance", 170.0)))
			_invuln_until = maxi(_invuln_until, now + 400)
			_shadow_crit = true   # Sát Thủ: chí mạng đầu tiên sau lướt gây 250%
			# Đòn đánh xuyên suốt quãng đã lướt (và đòn nối `after` sau 180ms)
			var da := minf(x0, _player.position.x)
			var db := maxf(x0, _player.position.x)
			var dshape := {"kind": "rect", "cx": (da + db) * 0.5, "cy": _player.position.y, "w": db - da + 50.0, "h": 64.0}
			var dx := _skill_extra(sk)
			if float(sk.get("power", 0.0)) > 0.0: _strike_shape(dshape, id, float(sk["power"]), kind, dx)
			if float(sk.get("after", 0.0)) > 0.0: _after(0.18, func(): _strike_shape(dshape, id, float(sk["after"]), kind, dx))
		"melee", "backstep":
			if not custom_fx: _fxs.slash(_player.position + Vector2(0, 6), _facing, Color(1.0, 0.85, 0.5), 1.5)
		"guard", "manashield", "buff":
			_add_buff(id, sk, stype)
			if not custom_fx: _fxs.shield(_player.position + Vector2(0, 26), Color(0.45, 0.72, 1.0) if stype != "buff" else Color(1.0, 0.85, 0.4))
		"heal":
			_skill_heal(float(sk.get("heal", 0.0)))
			if float(sk.get("mpHeal", 0.0)) > 0.0:
				var mxm := int(Game.stats.get("maxMp", 1))
				var gm := int(roundf(float(mxm) * float(sk["mpHeal"])))
				Game.mp = mini(mxm, Game.mp + gm)
				FloatText.spawn(_fx, _player.position + Vector2(0, -46), "+%d" % gm, Color(0.39, 0.71, 0.96), 14)
			if not custom_fx: _fxs.heal(_player.position)
			Audio.play("coin", 0.8)
		"aoe", "meteor", "sword_fall", "arrow_rain":
			if stype == "aoe" and float(sk.get("heal", 0.0)) > 0.0: _skill_heal(float(sk["heal"]))
			if not custom_fx: _fxs.ring(_player.position + Vector2(float(_facing) * 70.0, 28), Color(1.0, 0.6, 0.3), 120.0, 0.5, 5.0)
		"summon", "shadow_toggle", "shadow_command":
			if stype == "summon": Net.action("summon_toggle", {}, {"silent": true})
			elif stype == "shadow_toggle": Net.action("shadow_toggle", {}, {"silent": true})
			if not custom_fx: _fxs.ring(_player.position + Vector2(0, 28), Color(0.7, 0.5, 1.0), 80.0, 0.6, 4.0)
	if stype != "dash" and float(sk.get("power", 0.0)) > 0.0:
		_skill_damage(id, sk, stype, kind)
	_hud_dirty = true

## Mục tiêu gần nhất cho Tuyệt Phẩm "execute" (quái sống, trong tầm ngang/dọc).
func _exec_target(range_x: float, reach_y: float) -> Node2D:
	var best: Node2D = null
	var bd := 1e9
	for u in _mobs.keys():
		var m: Node2D = _mobs[u]
		if not is_instance_valid(m) or int(m.get("hp")) <= 0: continue
		var dx := absf(m.position.x - _player.position.x)
		if dx < range_x and absf(m.position.y - _player.position.y) < reach_y and dx < bd:
			bd = dx; best = m
	return best

func _dash(distance: float) -> void:
	var from := _player.position
	var steps := int(distance / 16.0)
	for i in range(steps):
		var nx := _player.position.x + float(_facing) * 16.0
		if not _walkable(nx, _player.position.y + 28.0) or nx < 20.0 or nx > float(_cols) * TILE - 20.0: break
		_player.position.x = nx
	_fxs.dash_trail(from + Vector2(0, 8), _player.position + Vector2(0, 8))
	_invuln_until = Time.get_ticks_msec() + 250

## Hệ số sát thương đòn đặc biệt của trùm theo web (boss.js): giậm đất x1.5, các chiêu theo kiểu `style`.
const BOSS_STYLE_MUL := {"water": 0.8, "ice": 1.3, "void": 1.1, "moon": 0.9}

## `mult`: hệ số của đòn (giậm đất 1.5, chiêu trùm theo style); `enrage_scale`: đòn lao thường nhân thêm 1.25 khi quái phẫn nộ.
func _hurt_player(m: Node2D, mult: float = 1.0, enrage_scale: bool = true) -> void:
	var now := Time.get_ticks_msec()
	if now < _invuln_until or _dead: return
	var fx: Dictionary = Game.special_fx()
	# Cánh Phiêu Diêu: né hoàn toàn một đòn
	var dodge: Dictionary = Game._as_dict(fx.get("dodge", {}))
	if not dodge.is_empty() and randf() < float(dodge.get("chance", 0.0)):
		FloatText.spawn(_fx, _player.position + Vector2(0, -34), "Né", Color(0.56, 0.94, 1.0), 17)
		Audio.play("cast", 1.4)
		_invuln_until = now + 300
		return
	# Bộ Vĩnh Hằng 10 món: lướt qua đòn mỗi `cd` giây
	var phase: Dictionary = Game._as_dict(fx.get("setPhase", {}))
	if not phase.is_empty() and now >= _phase_cd:
		_phase_cd = now + int(float(phase.get("cd", 8.0)) * 1000.0)
		FloatText.spawn(_fx, _player.position + Vector2(0, -34), "Xuyên Không", Color(0.70, 0.53, 1.0), 16)
		_invuln_until = now + 300
		return
	# Bộ Thạch Vương 10 món: khiên đá đỡ trọn một đòn mỗi `cd` giây
	var stone: Dictionary = Game._as_dict(fx.get("setStone", {}))
	if not stone.is_empty() and now >= _stone_cd:
		_stone_cd = now + int(float(stone.get("cd", 12.0)) * 1000.0)
		FloatText.spawn(_fx, _player.position + Vector2(0, -46), "Khiên Đá", Color(0.63, 0.53, 0.50), 15)
		_invuln_until = now + 400
		return
	var def_v := float(Game.stats.get("def", 0))
	var lv := int(Game.player.get("level", 1))
	var atk_v := float(m.atk) * mult
	if enrage_scale and m.enraged: atk_v *= 1.25
	var dmg := Formulas.mitigate(atk_v * randf_range(0.9, 1.1), def_v, lv)
	var mx_hp := int(Game.stats.get("maxHp", 100))
	# Nội tại Tanker "Thành Đồng": máu dưới 50% giảm thêm 10%
	if float(Game.hp) < float(mx_hp) * 0.5 and Game.has_passive("tanker"): dmg = maxi(1, int(roundf(float(dmg) * 0.9)))
	# Thủ thế: giảm cộng dồn (đòn vẫn tối thiểu 1) + phản sát thương
	var reduce := _buff_sum_of("guard", "reduce")
	if reduce > 0.0:
		dmg = maxi(1, int(roundf(float(dmg) * (1.0 - reduce))))
		var refl := _buff_sum_of("guard", "reflect")
		if refl > 0.0 and m.alive and m.uid != 900001:
			var rdir := 1 if m.position.x >= _player.position.x else -1
			Socket.send_hit(int(m.uid), maxi(1, int(roundf(float(m.atk) * refl))), "", 0, rdir, false)
	# Khiên năng lượng: hấp thụ bằng MP, cộng dồn
	var absorb := _buff_sum_of("manashield", "absorb")
	if absorb > 0.0 and Game.mp > 0:
		var take := mini(Game.mp, int(roundf(float(dmg) * absorb)))
		Game.mp -= take
		dmg -= take
		if take > 0: FloatText.spawn(_fx, _player.position + Vector2(0, -46), "%d" % take, Color(0.56, 0.71, 1.0), 13)
		if dmg <= 0:
			_invuln_until = now + 500
			_hud_dirty = true
			return
	# Hộ Mệnh đang chạy: mọi đòn không trừ máu
	if _laststand_until > 0 and now < _laststand_until:
		_invuln_until = now + 400
		return
	Game.hp = maxi(0, Game.hp - dmg)
	_share_to_companions(dmg)
	_last_hurt = now
	_hurt_until = now + 260
	_invuln_until = now + 700
	var dirx := signf(_player.position.x - m.position.x)
	if dirx == 0.0: dirx = 1.0
	_knock_vx = dirx * 260.0
	_knock_until = now + 220
	_vy = -220.0
	FloatText.spawn(_fx, _player.position + Vector2(0, -34), "-%d" % dmg, Color(1.0, 0.32, 0.32), 20)
	Audio.play("hurt")
	shake(3.0, 0.15)
	if _hud_node: _hud_node.flash(Color(1.0, 0.1, 0.1), 0.28)
	if Settings.haptics: Input.vibrate_handheld(40)
	_hud_dirty = true
	# Bùa Hộ Mệnh (Kỳ Nguyên Bất Tử): máu cạn thì giữ 1 máu trong `dur` giây, hồi lại sau `cd` giây
	var undying: Dictionary = Game._as_dict(fx.get("undying", {}))
	if Game.hp <= 0 and not undying.is_empty() and now >= _laststand_cd:
		_laststand_cd = now + int(float(undying.get("cd", 60.0)) * 1000.0)
		_laststand_until = now + int(float(undying.get("dur", 5.0)) * 1000.0)
		Game.hp = 1
		FloatText.spawn(_fx, _player.position + Vector2(0, -52), "Hộ Mệnh %ds" % int(undying.get("dur", 5)), Color(1.0, 0.88, 0.51), 16)
	if Game.hp > 0 and float(Game.hp) / float(maxi(1, mx_hp)) < 0.3: _hud_node.hint_once("lowhp", "Máu thấp! Mở Túi và dùng bình máu.")
	if Game.hp <= 0: _die()

## Hết 5 giây Hộ Mệnh mà máu vẫn <= 0 thì gục (gọi mỗi giây từ _regen).
func _laststand_tick(now: int) -> void:
	if _laststand_until > 0 and now >= _laststand_until:
		_laststand_until = 0
		if Game.hp <= 0 and not _dead: _die()

func _regen(delta: float) -> void:
	if _dead or _changing: return
	_regen_acc += delta
	if _regen_acc < 1.0: return
	_regen_acc = 0.0
	var now := Time.get_ticks_msec()
	_laststand_tick(now)
	_pets_tick(now)
	_fusion_expire_tick()
	var mx_hp := int(Game.stats.get("maxHp", 0))
	var mx_mp := int(Game.stats.get("maxMp", 0))
	var changed := false
	# Buff hồi máu liên tục: `regen` là % máu tối đa mỗi 2 giây (cộng dồn)
	var regen_pct := _buff_sum("regen")
	if regen_pct > 0.0 and Game.hp < mx_hp:
		Game.hp = mini(mx_hp, Game.hp + _carry("hp_buff", float(mx_hp) * regen_pct / 2.0))
		changed = true
	# Cấm Chú Giải Phóng: đang phong ấn năng lượng thì không hồi MP bằng đường nào
	var mp_locked := float(Game.player.get("mpLock", 0)) > Time.get_unix_time_from_system() * 1000.0
	# Nội tại Dòng Chảy (Pháp Sư): hồi 0,5% MP mỗi giây kể cả khi đang đánh
	if Game.has_passive("phap_su") and not mp_locked and Game.mp < mx_mp:
		Game.mp = mini(mx_mp, Game.mp + _carry("mp_flow", float(mx_mp) * 0.005))
		changed = true
	# Chỉ hồi khi KHÔNG giao chiến (không đánh / không bị đánh trong calmMs gần nhất), như web
	var calm_ms := int(Game._as_dict(Data.calc.get("REGEN", {})).get("calmMs", 2000))
	var fighting := now - _sta_used_at < calm_ms or now - _last_hurt < calm_ms
	if not fighting:
		# Đồ nhiễm đỏ: không hồi máu ngoài giao chiến
		if Game.hp < mx_hp and int(Game.stats.get("nhiem", 0)) == 0:
			Game.hp = mini(mx_hp, Game.hp + _carry("hp_calm", maxf(float(Game._as_dict(Data.calc.get("REGEN", {})).get("hp", 1)), float(mx_hp) * 0.005)))
			changed = true
		if Game.mp < mx_mp and not mp_locked:
			Game.mp = mini(mx_mp, Game.mp + _carry("mp_calm", maxf(float(Game._as_dict(Data.calc.get("REGEN", {})).get("mp", 1)), float(mx_mp) * 0.005)))
			changed = true
	if changed: _hud_dirty = true

# ------------------------------------------------------------------ Chết / hồi sinh
# ------------------------------------------------------------------ Thú đồng hành (chia sát thương, hồi sinh)
var _pet_dead_until: Dictionary = {}

func _companion_ids() -> Array:
	var m: Dictionary = Game._as_dict(Game.player.get("mounts", {}))
	var owned: Variant = m.get("owned", [])
	var sm: Variant = m.get("summoned", null)
	var ids: Array = []
	if typeof(sm) == TYPE_ARRAY: ids = sm
	elif m.get("active", null) != null: ids = [m["active"]]
	var out: Array = []
	for id in ids:
		var s := str(id)
		if typeof(owned) == TYPE_ARRAY and (owned as Array).has(s) and not Data.mount(s).is_empty() and not out.has(s): out.append(s)
	return out

## Chỉ số thú = chỉ số cố định theo loài + trang bị thú (port companionStats).
func _companion_stats(id: String) -> Dictionary:
	var mt: Dictionary = Data.mount(id)
	var st := {"maxHp": float(mt.get("hp", 1000)), "maxMp": float(mt.get("mp", 60)), "maxSta": float(mt.get("sta", 100)), "atk": float(mt.get("atk", 100)), "def": float(mt.get("def", 100))}
	var gear: Dictionary = Game._as_dict(Game._as_dict(Game.player.get("petGear", {})).get(id, {}))
	var table: Dictionary = Game._as_dict(Data.calc.get("PET_GEAR", {}))
	for slot in gear.keys():
		var b: Dictionary = Game._as_dict(table.get(str(gear[slot]), {}))
		if b.has("maxHp"): st["maxHp"] = roundf(float(st["maxHp"]) + float(b["maxHp"]))
		if b.has("atk"): st["atk"] = float(st["atk"]) + float(b["atk"])
		if b.has("def"): st["def"] = roundf(float(st["def"]) + float(b["def"]))
	return st

func _pet_state(id: String, ps: Dictionary) -> Dictionary:
	if typeof(Game.player.get("pets", null)) != TYPE_DICTIONARY: Game.player["pets"] = {}
	var pets: Dictionary = Game.player["pets"]
	if typeof(pets.get(id, null)) != TYPE_DICTIONARY:
		pets[id] = {"hp": ps["maxHp"], "mp": ps["maxMp"], "sta": ps["maxSta"]}
	return pets[id]

## Thú đồng hành gánh 18% sát thương người chơi nhận (chia đều), giảm theo giáp thú; gục thì 15 giây sau hồi 50%.
func _share_to_companions(dmg: int) -> void:
	var ids := _companion_ids()
	if ids.is_empty(): return
	var now := Time.get_ticks_msec()
	var share := float(dmg) * 0.18 / float(ids.size())
	var lv := int(Game.player.get("level", 1))
	for id in ids:
		var ps := _companion_stats(id)
		var state := _pet_state(id, ps)
		if float(state.get("hp", 0)) <= 0.0: continue
		var pd := maxi(1, int(roundf(share * (1.0 - Formulas.def_reduce(float(ps["def"]), lv)))))
		state["hp"] = maxf(0.0, float(state.get("hp", 0)) - float(pd))
		FloatText.spawn(_fx, _player.position + Vector2(-35, -36), "-%d" % pd, Color(1.0, 0.61, 0.61), 12)
		if float(state["hp"]) <= 0.0:
			_pet_dead_until[id] = now + 15000
			if _hud_node: _hud_node.log("%s đã gục, sẽ hồi sinh sau 15 giây." % Data.mount_name(id), Color(1.0, 0.72, 0.30))

func _pets_tick(now: int) -> void:
	for id in _companion_ids():
		var ps := _companion_stats(id)
		var state := _pet_state(id, ps)
		if float(state.get("hp", 0)) <= 0.0:
			if now >= int(_pet_dead_until.get(id, 0)):
				_pet_dead_until.erase(id)
				state["hp"] = maxf(1.0, roundf(float(ps["maxHp"]) * 0.5)); state["mp"] = ps["maxMp"]; state["sta"] = ps["maxSta"]
			continue
		if now - _last_hurt >= 3000:
			state["hp"] = minf(float(ps["maxHp"]), float(state.get("hp", 0)) + float(ps["maxHp"]) * 0.018)
			state["mp"] = minf(float(ps["maxMp"]), float(state.get("mp", 0)) + 5.0)
			state["sta"] = minf(float(ps["maxSta"]), float(state.get("sta", 0)) + 14.0)

## Trạng thái thú gửi kèm lúc lưu (server kẹp theo chỉ số tối đa).
func _pets_payload() -> Dictionary:
	var out := {}
	for id in _companion_ids():
		var st: Dictionary = _pet_state(id, _companion_stats(id))
		out[id] = {"hp": roundi(float(st.get("hp", 0))), "mp": roundi(float(st.get("mp", 0))), "sta": roundi(float(st.get("sta", 0)))}
	return out

## Tử Linh Dung Hợp hết hạn: bỏ cộng thêm, tính lại chỉ số, báo server dọn `player.fusion`.
func _fusion_expire_tick() -> void:
	var fu: Dictionary = Game._as_dict(Game.player.get("fusion", null))
	if fu.is_empty() or Game.fusion_active(): return
	Game.player["fusion"] = null
	Game.recalc_stats()
	_hud_dirty = true
	if _hud_node: _hud_node.log("Dung hợp tan: bóng ma đã tiêu biến, chỉ số trở lại bình thường.", Color(0.61, 0.55, 0.75))
	Socket.send_fusion_end()

## Hồi chút khi hạ quái (Chuông Trấn Hồn): % máu / năng lượng tối đa.
func _on_my_kill() -> void:
	var fx: Dictionary = Game._as_dict(Game.special_fx().get("onKill", {}))
	if fx.is_empty() or _dead: return
	var mxh := int(Game.stats.get("maxHp", 1))
	var mxm := int(Game.stats.get("maxMp", 1))
	var hp_gain := int(roundf(float(mxh) * float(fx.get("hp", 0.0))))
	var mp_gain := int(roundf(float(mxm) * float(fx.get("mp", 0.0))))
	if hp_gain > 0 and Game.hp < mxh:
		Game.hp = mini(mxh, Game.hp + hp_gain)
		FloatText.spawn(_fx, _player.position + Vector2(0, -34), "+%d" % hp_gain, Color(0.41, 0.94, 0.68), 13)
	if mp_gain > 0 and Game.mp < mxm: Game.mp = mini(mxm, Game.mp + mp_gain)
	_hud_dirty = true

func _die() -> void:
	if _dead: return
	_end_form("")
	_dead = true
	Game.hp = 0
	_free_cast_used = false
	_laststand_until = 0
	_buffs.clear()   # chết thì mọi buff tan (web: resetCombatFlags)
	_slow_until = 0
	_move_dir = Vector2.ZERO
	_flush_kills()
	Audio.play("death")
	Socket.send_pos(_map_id, _player.position.x, _player.position.y, _facing, "dead", false, 0)
	if _hud_node:
		_hud_node.show_death()
	_hud_dirty = true

func _on_death_choice(where: String) -> void:
	_changing = true
	Net.action("die", {"where": where})

# ------------------------------------------------------------------ Lưu / phiếu thưởng
func _save_state() -> void:
	if _map_id.is_empty() or _changing: return
	Net.action("save", {"map": _map_id, "x": roundi(_player.position.x), "y": roundi(_player.position.y),
		"hp": Game.hp, "mp": Game.mp, "pets": _pets_payload()}, {"silent": true})

func _queue_kill(kid: String) -> void:
	_pending_kills.append({"kid": kid})
	if _kill_timer == null:
		_kill_timer = get_tree().create_timer(0.12)
		_kill_timer.timeout.connect(_flush_kills)

func _flush_kills() -> void:
	_kill_timer = null
	if _pending_kills.is_empty(): return
	var list := _pending_kills.duplicate()
	_pending_kills.clear()
	var i := 0
	while i < list.size():
		Net.action("kills", {"list": list.slice(i, i + 15)}, {"silent": true})
		i += 15

# ------------------------------------------------------------------ Tương tác (NPC / cổng / đồ rơi)
func _update_interact() -> void:
	if _hud_node == null or _dead or _changing or _hud_node.dialog_open():
		_interact = {}
		if _interact_mark != null and is_instance_valid(_interact_mark): _interact_mark.visible = false
		return
	var foot := _player.position + Vector2(0, 30)
	var best: Dictionary = _entities.nearest(foot) if _entities else {}
	# Đồ rơi gần nhất (ưu tiên sau cổng, trước NPC)
	var lbest: LootNode = null
	var ld := 1e9
	for lid in _loots.keys():
		var l: LootNode = _loots[lid]
		if not is_instance_valid(l) or _pickup_pending.has(lid): continue
		var dx := absf(l.position.x - _player.position.x)
		var dy := absf((l.position.y + 14.0) - foot.y)
		if dx < 120.0 and dy < 90.0 and dx < ld:
			ld = dx; lbest = l
	if not best.is_empty() and best.get("type") == "portal":
		_interact = best
	elif lbest != null:
		_interact = {"type": "loot", "lid": lbest.lid, "name": lbest.item_name, "pos": lbest.position + Vector2(0, -34)}
	else:
		_interact = best
	var t := str(_interact.get("type", ""))
	# Không còn nút ngữ cảnh: nút Đánh sẽ nhặt / nói chuyện / vào cổng, mũi tên vàng chỉ vào đối tượng.
	if t == "" or not _interact.has("pos"):
		if _interact_mark != null and is_instance_valid(_interact_mark): _interact_mark.visible = false
	else:
		if _interact_mark == null or not is_instance_valid(_interact_mark):
			var im := _TargetMark.new()
			im.col = Color(1.0, 0.86, 0.25)
			im.z_index = 51
			_mob_layer.add_child(im)
			_interact_mark = im
		_interact_mark.visible = true
		_interact_mark.position = (_interact["pos"] as Vector2) + Vector2(0, sin(_target_t * 7.7) * 4.0)
	if t == "npc": _hud_node.hint_once("npc", "Chạm nút Đánh để nói chuyện với NPC (mũi tên vàng).")
	elif t == "loot": _hud_node.hint_once("loot", "Đứng gần đồ rơi và chạm nút Đánh để nhặt.")
	elif t == "portal": _hud_node.hint_once("portal", "Chạm nút Đánh để qua cổng. Một số cổng cần hoàn thành nhiệm vụ.")

var _interact_mark: Node2D = null

func _do_interact() -> void:
	if _interact.is_empty() or _dead or _changing: return
	match str(_interact.get("type", "")):
		"npc":
			var id := str(_interact.get("id", ""))
			_hud_node.open_dialog(id)
			Net.action("talk", {"npc": id}, {"silent": true})
		"portal": _use_portal(str(_interact.get("key", "")))
		"loot": _pickup(str(_interact.get("lid", "")))

func _pickup(lid: String) -> void:
	if lid.is_empty() or _pickup_pending.has(lid): return
	_pickup_lid = lid
	_pickup_pending[lid] = true
	Net.action("pickup", {"lid": lid}, {"silent": true})

func _use_portal(key: String) -> void:
	if _changing: return
	# Cổng gom nhiều điểm đến: mở bảng chọn (có trạng thái mở/khoá) thay vì đi thẳng
	var portals: Dictionary = _meta.get("portals", {})
	if str(_meta.get("gate", "")) == key and portals.size() > 2:
		_hud_node.open_panel("gate")
		return
	_changing = true
	_flush_kills()
	_move_dir = Vector2.ZERO
	Audio.play("portal")
	_fxs.ring(_player.position + Vector2(0, 28), Color(0.7, 0.6, 1.0), 90.0, 0.5, 5.0)
	create_tween().tween_property(_fade, "modulate:a", 1.0, 0.25)
	Net.action("change_map", {"portal": key, "hp": Game.hp, "mp": Game.mp, "pets": _pets_payload()})

func use_teleport(to: String) -> void:
	if _changing: return
	_changing = true
	_flush_kills()
	create_tween().tween_property(_fade, "modulate:a", 1.0, 0.25)
	Net.action("teleport", {"to": to, "hp": Game.hp, "mp": Game.mp, "pets": _pets_payload()})

# ------------------------------------------------------------------ Kết quả action / sự kiện
func _on_action_done(data: Dictionary, type: String) -> void:
	if type == "save" or type == "kills" or type == "talk":
		if data.has("error") and type == "kills": pass
		return
	if type == "pickup":
		# Đồ được dọn khi nhận event 'picked'; lỗi thì cho nhặt lại.
		var plid := _pickup_lid
		_pickup_pending.erase(plid)
		if data.has("error"):
			if str(data["error"]) == "Món đồ đã biến mất." and _loots.has(plid):
				(_loots[plid] as Node).queue_free()
				_loots.erase(plid)
			if _hud_node: _hud_node.log(str(data["error"]), Color(1, 0.55, 0.5))
		return
	if data.has("error"):
		if _hud_node:
			_hud_node.log("Lỗi: " + str(data["error"]), Color(1, 0.4, 0.4))
			_hud_node.toast(str(data["error"]), "error")
		if type in ["change_map", "teleport"]:
			_changing = false
			create_tween().tween_property(_fade, "modulate:a", 0.0, 0.2)
		elif type == "die":
			_changing = false
			_dead = false
			Game.hp = maxi(1, int(Game.stats.get("maxHp", 100) * 0.5))
			_hud_dirty = true
		return
	if type in ["change_map", "teleport", "die", "respawn_choice"]:
		_reload_after_move(type == "die")
		return
	if type == "mount_set": _sync_pet()
	if _hud_node:
		_hud_node.refresh_panel()
		_hud_node.refresh_dialog()
	_hud_dirty = true

func _reload_after_move(from_death: bool) -> void:
	if _reload_queued: return
	_reload_queued = true
	_changing = true
	var tw := create_tween()
	tw.tween_property(_fade, "modulate:a", 1.0, 0.18)
	await tw.finished
	_reload_queued = false
	if not is_inside_tree(): return
	if from_death:
		if Game.hp <= 0: Game.hp = maxi(1, int(Game.player.get("hp", int(Game.stats.get("maxHp", 100) * 0.5))))
		if Game.mp < 0: Game.mp = 0
	var arrive := str(Game.player.get("arrive", "")) if Game.player.get("arrive", null) != null else ""
	_setup_player_sprite()
	_load_player_map(arrive)
	_hud_node.hide_death()
	_hud_node.close_panel()
	_refresh_hud()
	_fade_in()

func _on_event(ev: Dictionary) -> void:
	var t := str(ev.get("t", ""))
	if t in ["exec", "fusion", "manaburst", "allin"] and ev.has("sk"):
		if _skill_fx and _skill_fx.has_method("play"):
			_skill_fx.play(t, str(ev["sk"]), _player.position, _facing)
	if _hud_node == null: return
	match t:
		"msg": _hud_node.log(str(ev.get("text", "")), _hex(str(ev.get("color", "")), Color(0.95, 0.88, 0.60)))
		"float":
			var txt := str(ev.get("text", ""))
			if txt.ends_with("xu"): Audio.play("coin")
			FloatText.spawn(_fx, _player.position + Vector2(0, -40), txt, _hex(str(ev.get("color", "")), Color(0.6, 0.95, 0.7)), 15)
			_hud_node.log(txt, Color(0.60, 0.95, 0.70))
		"levelup":
			Audio.play("levelup")
			_fxs.levelup(_player.position)
			_hud_node.flash(Color(1.0, 0.9, 0.5), 0.35)
			_hud_node.banner("THĂNG CẤP · Lv %s" % str(ev.get("level", "?")))
			_hud_node.log("★ Thăng cấp lên Lv %s" % str(ev.get("level", "?")), T.C_GOLD)
			Game.hp = int(Game.stats.get("maxHp", Game.hp)); Game.mp = int(Game.stats.get("maxMp", Game.mp))
		"rank": _hud_node.banner("THỢ SĂN HẠNG %s" % str(ev.get("rank", "?")))
		"queststep":
			Game.quest_hint = "%s: %s %s/%s" % [str(ev.get("name", "Nhiệm vụ")), str(ev.get("label", "")), str(ev.get("have", 0)), str(ev.get("need", 0))]
			_hud_node.toast(Game.quest_hint, "info")
			_hud_dirty = true
		"loot": _add_loot(ev.get("loot", {}), true)
		"picked":
			var lid := str(ev.get("lid", ""))
			Audio.play("pickup")
			_pickup_pending.erase(lid)
			_loot_store.erase(lid)
			if _loots.has(lid):
				var ln: LootNode = _loots[lid]
				_loots.erase(lid)
				FloatText.spawn(_fx, _player.position + Vector2(0, -52), "+" + ln.item_name, Color(1.0, 0.88, 0.5), 14)
				_fxs.pickup(ln.position)
				ln.fly_to(_player.global_position + Vector2(0, -10))
		"map":
			if not _changing or true: _reload_after_move(false)
		"form": _apply_form_visual(bool(ev.get("active", false)))
		"awaken":
			_hud_node.banner("THỨC TỈNH · MỞ KHÓA ẤN MỚI", Color(1.0, 0.7, 0.3))
			_fxs.levelup(_player.position)
		"market": Social.on_market(ev)
		"upgrade": _hud_node.toast("Cường hóa thành công!" if ev.get("ok", true) else "Cường hóa thất bại", "success" if ev.get("ok", true) else "error")
		"side": _hud_node.banner("PHỤ TUYẾN: %s" % str(ev.get("name", "")).to_upper(), T.C_BLUE)
		"mount_new", "perk", "unlock": _hud_node.banner(t.to_upper().replace("_", " "))
	_hud_dirty = true

func _hex(s: String, fallback: Color) -> Color:
	if s.is_empty(): return fallback
	return Color.from_string(s, fallback)

var _loot_store: Dictionary = {}   # lid -> {data, ch}: đồ rơi nhớ theo khu (kênh), chỉ hiện ở khu nó rơi

func _add_loot(data: Dictionary, animate: bool) -> void:
	var lid := str(data.get("lid", ""))
	if lid.is_empty() or _loots.has(lid) or str(data.get("map", _map_id)) != _map_id: return
	var lch: int = int((_loot_store[lid] as Dictionary)["ch"]) if _loot_store.has(lid) else Socket.channel
	_loot_store[lid] = {"data": data, "ch": lch}
	if lch != Socket.channel: return
	# Đồ rơi phải nằm trên mặt đất / bậc gỗ ngay dưới điểm rơi (server gửi toạ độ quái, có thể đang lơ lửng)
	var gd := data.duplicate()
	var gx := float(gd.get("x", 0))
	var gy := _ground_y(gx, float(gd.get("y", 0)) - 12.0)
	if gy < float(_rows) * TILE: gd["y"] = gy
	var n: LootNode = LootNode.new()
	_loot_layer.add_child(n)
	n.setup(gd)
	if not n.init_expiry(animate):   # đồ đã hết hạn từ trước thì bỏ
		n.queue_free()
		return
	if not animate:
		n.scale = Vector2.ONE
	_loots[lid] = n
	n.expired.connect(func(l: String) -> void:
		_loots.erase(l)
		_loot_store.erase(l)
		_pickup_pending.erase(l))

# ------------------------------------------------------------------ Chat
func _on_chat(text: String) -> void:
	var t := text.strip_edges()
	if t.is_empty(): return
	if t.to_lower() in ["npc an", "ncp an"]:
		Net.action("hidden_chat", {"text": t})
		return
	if t.begins_with("/map"): _hud_node.open_panel("map"); return
	if t.begins_with("/shop"): _hud_node.open_panel("shop", {"npc": _nearest_shop_npc()}); return
	if t.begins_with("/npc"): _hud_node.open_panel("npc", {"id": _nearest_npc()}); return
	if t.begins_with("/w "): Socket.send_chat(t.substr(3), "world"); return
	if t.begins_with("/t ") or t.begins_with("/ds "):
		Socket.send_chat(t.substr(t.find(" ") + 1), "party"); return
	if not Socket.send_chat(t, "map"):
		_hud_node.log("Chưa kết nối máy chủ, tin nhắn sẽ gửi khi có mạng.", Color(1.0, 0.7, 0.5))

func _on_chat_recv(msg: Dictionary) -> void:
	var who := str(msg.get("name", "?"))
	var text := str(msg.get("text", ""))
	if text.is_empty(): return
	var ch := str(msg.get("ch", "map"))
	var tag := "" if ch == "map" else ("[Thế giới] " if ch == "world" else "[Đội] ")
	var col := Color(0.88, 0.92, 1.0) if ch == "map" else (Color(1.0, 0.85, 0.5) if ch == "world" else Color(0.6, 0.95, 0.7))
	if int(msg.get("id", 0)) == Socket.my_id: col = Color(0.75, 0.9, 1.0)
	_hud_node.log("%s%s: %s" % [tag, who, text], col)
	var pid := int(msg.get("id", 0))
	if _players.has(pid): (_players[pid] as RemotePlayer).say(text)

func _nearest_shop_npc() -> String:
	var npcs: Dictionary = _meta.get("npcs", {})
	for k in npcs.keys():
		var nd: Dictionary = Data.npc(str(npcs[k]))
		if not str(nd.get("shop", "")).is_empty() or bool(nd.get("ngocShop", false)):
			return str(npcs[k])
	return ""

func _nearest_npc() -> String:
	var n: Dictionary = _entities.nearest(_player.position + Vector2(0, 30)) if _entities else {}
	if n.get("type") == "npc": return str(n.get("id", ""))
	var npcs: Dictionary = _meta.get("npcs", {})
	return str(npcs[npcs.keys()[0]]) if not npcs.is_empty() else ""

# ------------------------------------------------------------------ Mạng (đúng giao thức server/realtime)
var _enter_try := 0

func _on_socket_connected() -> void:
	_enter_try = Time.get_ticks_msec()
	Socket.send_pos(_map_id, _player.position.x, _player.position.y, _facing, _server_anim(_anim), true, _hp_pct())

func _on_players(msg: Dictionary) -> void:
	var t := str(msg.get("t", ""))
	if t in ["msnap", "mspawn", "mhit", "mhp", "mdie", "mdel", "mresp", "mact"]:
		_on_mob_packet(msg); return
	if t in ["party", "party_inv", "trade", "trade_inv", "trade_end", "chlist"]:
		Social.on_message(msg); return
	match t:
		"room":
			for id in _players.keys(): (_players[id] as Node).queue_free()
			_players.clear()
			Social.nearby.clear()
			_apply_loot_channel(int(msg.get("ch", 1)))
			# Đổi khu xong: cập nhật "đang ở Khu n" ngay và xin danh sách mới (trước đây bảng vẫn hiện khu cũ nên phải bấm nhiều lần)
			if not Social.channels.is_empty():
				Social.channels["cur"] = int(msg.get("ch", Social.channels.get("cur", 1)))
				Social.changed.emit("channels")
				Socket.send_chlist()
			for p in msg.get("list", []):
				if typeof(p) == TYPE_DICTIONARY: _add_remote(p)
		"join":
			if typeof(msg.get("p", null)) == TYPE_DICTIONARY: _add_remote(msg["p"])
		"leave":
			var id2 := int(msg.get("id", 0))
			if _players.has(id2):
				(_players[id2] as Node).queue_free()
				_players.erase(id2)
				Social.nearby.erase(id2)
		"snap":
			for e in msg.get("p", []):
				# Mục ngắn [id,x,y] = hướng và hoạt ảnh không đổi; mục đủ [id,x,y,f,a] khi có đổi
				if typeof(e) != TYPE_ARRAY or (e as Array).size() < 3: continue
				var rp: RemotePlayer = _players.get(int(e[0]), null)
				if rp:
					var st := {"x": e[1], "y": e[2]}
					if (e as Array).size() >= 5:
						st["f"] = e[3]
						st["a"] = e[4]
					rp.apply_state(st)
		"look":
			var p2: Dictionary = msg.get("p", {})
			var rp2: RemotePlayer = _players.get(int(p2.get("id", 0)), null)
			if rp2: rp2.apply_look(p2)
		"sys":
			if _hud_node: _hud_node.log(str(msg.get("text", "")), Color(0.75, 0.85, 1.0))

func _add_remote(info: Dictionary) -> void:
	var id := int(info.get("id", 0))
	if id == 0 or id == Socket.my_id or _players.has(id): return
	var rp: RemotePlayer = RemotePlayer.new()
	_remote.add_child(rp)
	rp.setup(info)
	_players[id] = rp
	Social.nearby[id] = {"name": str(info.get("name", "?")), "lv": int(info.get("lv", 1)), "sc": str(info.get("sc", ""))}

func _on_mobs(msg: Dictionary) -> void:
	# Gói đầy đủ khi vào map: dựng lại toàn bộ quái.
	for u in _mobs.keys():
		var n: Node = _mobs[u]
		if is_instance_valid(n): n.queue_free()
	_mobs.clear()
	for info in msg.get("list", []):
		if typeof(info) == TYPE_DICTIONARY: _spawn_mob(info, false)

func _spawn_mob(info: Dictionary, fx: bool) -> void:
	var u := int(info.get("u", 0))
	if u == 0 or _mob_script == null: return
	if _mobs.has(u):
		_apply_mob_full(_mobs[u], info); return
	var node: Node2D = _mob_script.new()
	var mid := str(info.get("id", ""))
	var def: Dictionary = Data.monster(mid)
	node.setup(u, mid, str(def.get("look", "")), str(def.get("sprite", "")))
	_mob_layer.add_child(node)
	_mobs[u] = node
	_apply_mob_full(node, info)
	if fx: node.modulate.a = 0.0; create_tween().tween_property(node, "modulate:a", 1.0, 0.4)

func _apply_mob_full(node: Node2D, info: Dictionary) -> void:
	node.set_target(Vector2(float(info.get("x", 0)), float(info.get("y", 0))), true)
	node.set_facing(int(info.get("f", 1)))
	node.set_hp(int(info.get("hp", 0)), int(info.get("mh", 1)))
	node.set_state(int(info.get("st", 0)))
	node.flags = int(info.get("fl", 0))
	node.enraged = (node.flags & 4) != 0
	if int(info.get("al", 1)) == 1:
		if not node.alive: node.revive()
		node.visible = true
	else:
		node.alive = false
		node.set_process(false)   # mob chết/ẩn khỏi snapshot: khỏi chạy _process mỗi khung
		node.visible = false

func _on_mob_packet(msg: Dictionary) -> void:
	var t := str(msg.get("t", ""))
	match t:
		"msnap":
			for e in msg.get("p", []):
				if typeof(e) != TYPE_ARRAY or (e as Array).size() < 5: continue
				var n: Node2D = _mobs.get(int(e[0]), null)
				if n == null or not n.alive: continue
				n.set_target(Vector2(float(e[1]), float(e[2])))
				n.set_facing(int(e[3]))
				n.set_state(int(e[4]))
				if (e as Array).size() > 5:
					n.flags = int(e[5])
					n.enraged = (int(e[5]) & 4) != 0
		"mspawn":
			if typeof(msg.get("m", null)) == TYPE_DICTIONARY: _spawn_mob(msg["m"], true)
		"mresp":
			var info: Dictionary = msg.get("m", {})
			var n2: Node2D = _mobs.get(int(info.get("u", 0)), null)
			if n2 == null: _spawn_mob(info, true)
			else:
				_apply_mob_full(n2, info)
				n2.revive()
				n2.modulate.a = 0.0
				create_tween().tween_property(n2, "modulate:a", 1.0, 0.4)
		"mhp":
			var n3: Node2D = _mobs.get(int(msg.get("u", 0)), null)
			if n3: n3.set_hp(int(msg.get("hp", 0)), int(msg.get("mh", n3.max_hp)))
		"mhit":
			var n4: Node2D = _mobs.get(int(msg.get("u", 0)), null)
			if n4 == null or not n4.alive: return
			n4.set_hp(int(msg.get("hp", 0)), n4.max_hp)
			var mine := int(msg.get("by", -1)) == Socket.my_id
			if not mine:
				var now := Time.get_ticks_msec()
				if now - _other_fx_at > 1000: _other_fx_at = now; _other_fx_n = 0
				_other_fx_n += 1
				if _other_fx_n > 8: return
			n4.hit_flash()
			_fxs.hit_spark(n4.position + Vector2(0, -n4._height * 0.5), int(msg.get("c", 0)) == 1, int(msg.get("dir", 1)))
			if mine: Audio.play("crit" if int(msg.get("c", 0)) == 1 else "hit")
			var crit := int(msg.get("c", 0)) == 1
			var col := Color(1.0, 0.84, 0.25) if crit else (Color.WHITE if mine else Color(0.69, 0.75, 0.78))
			if Settings.show_damage: FloatText.spawn(_fx, n4.position + Vector2(randf_range(-8, 8), -n4._height - 6.0), ("%d!" if crit else "%d") % int(msg.get("d", 0)), col, 22 if crit else 16)
		"mdie":
			var n5: Node2D = _mobs.get(int(msg.get("u", 0)), null)
			if n5 and n5.alive:
				_fxs.death_poof(n5.position, n5.is_boss)
				n5.die()
				if int(msg.get("fled", 0)) == 1:
					FloatText.spawn(_fx, n5.position + Vector2(0, -60), "Bỏ chạy!", T.C_GOLD, 16)
			var kid := str(msg.get("kid", ""))
			var me := Socket.my_id
			if not kid.is_empty() and me != 0 and (int(msg.get("by", -1)) == me or (msg.get("as", []) as Array).has(me)):
				_queue_kill(kid)
			if int(msg.get("by", -1)) == me and me != 0: _on_my_kill()
		"mact":
			var bm: Node2D = _mobs.get(int(msg.get("u", 0)), null)
			if bm == null or not bm.alive: return
			var dxm := absf(bm.position.x - _player.position.x)
			match str(msg.get("a", "")):
				"slam":
					shake(8.0, 0.35)
					FloatText.spawn(_fx, bm.position + Vector2(0, -90), "Giậm đất!", Color(1.0, 0.6, 0.3), 18)
					if dxm < 230.0 and absf(bm.position.y - _player.position.y) < 120.0: _hurt_player(bm, 1.5, false)
				"special":
					shake(5.0, 0.4)
					FloatText.spawn(_fx, bm.position + Vector2(0, -90), "Tuyệt chiêu!", Color(1.0, 0.4, 0.8), 18)
					if dxm < 300.0 and absf(bm.position.y - _player.position.y) < 160.0:
						_hurt_player(bm, float(BOSS_STYLE_MUL.get(bm.mob_style, 1.0)), false)
						# Trùm Nước / Băng: đòn trúng thì làm chậm người chơi (60% tốc độ)
						if bm.mob_style == "water": _slow_until = Time.get_ticks_msec() + 2600
						elif bm.mob_style == "ice": _slow_until = Time.get_ticks_msec() + 3000
				"enrage":
					FloatText.spawn(_fx, bm.position + Vector2(0, -90), "Phẫn nộ!", Color(1.0, 0.3, 0.3), 20)
					shake(4.0, 0.3)
		"mdel":
			var u := int(msg.get("u", 0))
			if _mobs.has(u):
				(_mobs[u] as Node).queue_free()
				_mobs.erase(u)

var _shake_tween: Tween = null
func shake(strength: float, duration: float) -> void:
	if _cam == null: return
	# Chỉ một Tween rung tại một thời điểm: trúng đòn dồn dập không chồng offset.
	if _shake_tween != null and _shake_tween.is_valid(): _shake_tween.kill()
	var tw := create_tween()
	_shake_tween = tw
	var steps := maxi(1, int(duration / 0.04))
	for i in range(steps):
		var k := 1.0 - float(i) / float(steps)
		tw.tween_property(_cam, "offset", Vector2(randf_range(-1, 1), randf_range(-1, 1)) * strength * k, 0.04)
	tw.tween_property(_cam, "offset", Vector2.ZERO, 0.04)

# ------------------------------------------------------------------ HUD
func _refresh_hud() -> void:
	if _hud_node == null: return
	var p: Dictionary = Game.player
	var lv := int(p.get("level", 1))
	var st: Dictionary = Game.stats
	if st.is_empty(): st = p.get("stats", {})
	if st.is_empty(): st = p
	_hud_node.set_stats(
		Game.hp, int(st.get("maxHp", p.get("maxHp", 100))),
		Game.mp, int(st.get("maxMp", p.get("maxMp", 100))),
		maxi(0, Game.sta) if Game.sta >= 0 else int(p.get("sta", 0)), int(st.get("maxSta", 100)),
		int(p.get("exp", 0)), Formulas.exp_to_next(lv))
	_hud_node.set_map(str(Data.map_def(_map_id).get("name", _map_id)))
	_hud_node.set_hero(str(p.get("name", "Thức Tỉnh")), lv, str(p.get("rank", "E")), str(p.get("school", "")))
	var q: Dictionary = p.get("quest", {}) if typeof(p.get("quest", {})) == TYPE_DICTIONARY else {}
	var qtext := "Nhiệm vụ: hoàn tất cốt truyện"
	if not q.is_empty():
		var qstate := str(q.get("state", "none"))
		if qstate == "active" and not Game.quest_hint.is_empty():
			qtext = Game.quest_hint
		else:
			var ready := Data.quest_ready(p)
			var cqq: Dictionary = Data.quest_current(p)
			if qstate == "active" and ready:
				qtext = "Trả nhiệm vụ: %s" % str(cqq.get("name", ""))
			elif qstate == "active":
				var nl := ""
				for l in Data.quest_obj_lines(p, cqq.get("obj", {}), q.get("progress", {}) if typeof(q.get("progress", {})) == TYPE_DICTIONARY else {}):
					if not bool(l[1]): nl = str(l[0]); break
				qtext = nl if nl != "" else str(cqq.get("name", "Nhiệm vụ"))
			elif cqq.is_empty():
				qtext = "Nhiệm vụ: hoàn tất cốt truyện"
			else:
				qtext = "Gặp NPC để nhận: %s" % str(cqq.get("name", ""))
	if not Data.quest_ready(p):
		for sid in (Data.side_state(p).get("active", {}) as Dictionary).keys():
			if Data.side_ready(p, str(sid)):
				qtext = "Trả phụ tuyến: %s" % str(Data.quest_by_id(str(sid)).get("name", sid))
				break
	_hud_node.set_quest(qtext)
	if _entities:
		var cq: Dictionary = Data.quest_current(p)
		_entities.set_quest_marks(str(cq.get("npc", "")), ("done" if Data.quest_ready(p) else str(q.get("state", ""))) if not q.is_empty() else "")
		_entities.refresh_visibility(p, _map_id)
	var labels: Array = []
	for i in range(9):
		var sid := _btn_skill(i)
		var sk: Dictionary = Data.skill(sid)
		labels.append("%s|%s" % [(GlyphArt.skill_token(sid, str(sk.get("icon", "@star"))) if not sk.is_empty() else ("@star" if i >= 5 and i < 8 else "")), str(sk.get("name", sid))])
	_hud_node.set_skill_visible(8, _gear_skill_id() != "")
	var toan_nang := str(Data.school(str(p.get("school", ""))).get("base", str(p.get("school", "")))) == "toan_nang"   # Toàn Năng có thêm ô thường 5 và ô tuyệt kỹ 3 (như web)
	_hud_node.set_skill_visible(4, toan_nang)
	_hud_node.set_skill_visible(7, toan_nang)
	_hud_node.set_skill_labels(labels)
	var colors: Array = []
	var usable: Array = []
	for i in range(9):
		var sk2: Dictionary = Data.skill_eff(Game.player, _btn_skill(i))
		colors.append(_skill_color(sk2) if not sk2.is_empty() else Color(0.5, 0.5, 0.58))
		usable.append(not sk2.is_empty() and Game.mp >= int(sk2.get("mp", 0)))
	_hud_node.set_skill_styles(colors, usable)
	_hud_node.set_form_state(int(p.get("awakenTier", 0)), maxi(1, Data.awaken_tier_of(p.get("formChoice", ""))), Game.form_active)
	_sync_hidden_npc()
	_update_potions()

# ------------------------------------------------------------------ Bình nhanh
var _potion_ids := {"hp": "", "mp": ""}
var _potion_cd_until := 0

## Số lượng một vật phẩm trong túi (cộng mọi ô).
func _bag_count(iid: String) -> int:
	var n := 0
	for e in Game.player.get("bag", []):
		if typeof(e) == TYPE_DICTIONARY and str(e.get("id", "")) == iid: n += int(e.get("n", e.get("qty", 1)))
	return n

func _potion_heal(iid: String, kind: String) -> int:
	var d: Dictionary = Data.item(iid)
	if kind == "hp": return int(d.get("hp", 0)) + (int(roundf(float(Game.stats.get("maxHp", 0)) * float(d["hpPct"]))) if d.has("hpPct") else 0)
	return int(d.get("mp", 0))

## Chọn bình để uống như web (usePotion): mọi bình cùng hệ xếp theo lượng hồi tăng dần; lấy bình nhỏ nhất đủ lấp phần đang thiếu
## (đỡ phí bình xịn), không đủ thì dùng bình mạnh nhất đang có. Bình phải đủ cấp; thuốc chữa nhiễm đỏ chỉ là phương án cuối.
## Cache theo túi/cấp/máu: hàm này quét toàn bộ Data.ITEMS (~434 mục) và từng ô túi, mà _refresh_hud gọi 2 lần mỗi lần dirty.
var _potion_pick_cache: Dictionary = {}

func _potion_pick(kind: String) -> String:
	# Chữ ký gồm mọi đầu vào của phép chọn: túi, cấp, maxHp/maxMp và máu/mana hiện tại.
	var sig := "%s|%s|%s|%s|%s|%s|%s" % [kind, str(Game.player.get("bag", [])), str(Game.player.get("level", 1)),
		str(Game.stats.get("maxHp", 0)), str(Game.stats.get("maxMp", 0)), str(Game.hp), str(Game.mp)]
	if _potion_pick_cache.has(sig): return str(_potion_pick_cache[sig])
	var picked := _potion_pick_calc(kind)
	# Giới hạn bộ nhớ cache: mỗi lần máu đổi là một chữ ký mới.
	if _potion_pick_cache.size() > 64: _potion_pick_cache.clear()
	_potion_pick_cache[sig] = picked
	return picked

func _potion_pick_calc(kind: String) -> String:
	var ids: Array = []
	for iid in Data.ITEMS.keys():
		var d: Dictionary = Data.item(str(iid))
		if str(d.get("kind", "")) != "potion" or _potion_heal(str(iid), kind) <= 0: continue
		if (kind == "hp") == d.has("mp"): continue   # hp: bình không có mp; mp: bình có mp
		if int(d.get("level", 1)) > int(Game.player.get("level", 1)) or _bag_count(str(iid)) <= 0: continue
		ids.append(str(iid))
	ids.sort_custom(func(a, b): return _potion_heal(a, kind) < _potion_heal(b, kind))
	if ids.is_empty(): return ""
	var missing := (int(Game.stats.get("maxHp", 0)) - Game.hp) if kind == "hp" else (int(Game.stats.get("maxMp", 0)) - Game.mp)
	var normal: Array = ids.filter(func(i): return i != "thuoc_nhiem_do")
	for i in normal:
		if _potion_heal(i, kind) >= missing: return i
	if not normal.is_empty(): return normal[normal.size() - 1]
	return ids[0]

func _update_potions() -> void:
	# Số hiển thị = tổng mọi bình cùng hệ trong túi (như web), biểu tượng = bình sẽ được uống
	var total := {"hp": 0, "mp": 0}
	var seen := {}
	for e in Game.player.get("bag", []):
		if typeof(e) != TYPE_DICTIONARY: continue
		var iid := str(e.get("id", ""))
		var d: Dictionary = Data.item(iid)
		if str(d.get("kind", "")) != "potion": continue
		var n := int(e.get("n", e.get("qty", 1)))
		if d.has("hp") or d.has("hpPct"): total["hp"] = int(total["hp"]) + n
		if d.has("mp"): total["mp"] = int(total["mp"]) + n
		seen[iid] = true
	_potion_ids["hp"] = _potion_pick("hp")
	_potion_ids["mp"] = _potion_pick("mp")
	var hid := str(_potion_ids["hp"])
	var mid := str(_potion_ids["mp"])
	_hud_node.set_potions(hid if hid != "" else _any_potion("hp"), int(total["hp"]), mid if mid != "" else _any_potion("mp"), int(total["mp"]))

## Khi không có bình nào dùng được (thiếu cấp) vẫn cần id để vẽ biểu tượng nút.
func _any_potion(kind: String) -> String:
	for e in Game.player.get("bag", []):
		if typeof(e) != TYPE_DICTIONARY: continue
		var d: Dictionary = Data.item(str(e.get("id", "")))
		if str(d.get("kind", "")) == "potion" and ((kind == "hp" and (d.has("hp") or d.has("hpPct"))) or (kind == "mp" and d.has("mp"))): return str(e.get("id", ""))
	return ""

func _use_quick_potion(kind: String) -> void:
	var now := Time.get_ticks_msec()
	if _dead or _changing or now < _potion_cd_until: return
	var iid := _potion_pick(kind)   # chọn lại theo lượng máu đang thiếu lúc bấm (như web)
	if iid.is_empty():
		_hud_node.toast("Hết bình máu hoặc chưa đủ cấp dùng bình" if kind == "hp" else "Hết bình năng lượng hoặc chưa đủ cấp dùng bình", "warn")
		return
	var full := (Game.hp >= int(Game.stats.get("maxHp", 1))) if kind == "hp" else (Game.mp >= int(Game.stats.get("maxMp", 1)))
	if full:
		_hud_node.toast("%s đã đầy" % ("Máu" if kind == "hp" else "MP"), "warn")
		return
	_potion_cd_until = now + 450
	_hud_node.potion_cooldown(kind, 0.45)
	_fxs.heal(_player.position)
	Audio.play("pickup", 0.9)
	# Gửi máu/MP tức thời như web: server cộng bình vào giá trị này, không phải giá trị lưu cũ
	Net.action("use", {"item": iid, "hp": Game.hp, "mp": Game.mp}, {"silent": true})

## Màu viền nút kỹ năng theo loại: tuyệt kỹ vàng, tấn công cam, phòng thủ xanh dương, hồi phục xanh lá, triệu hồi tím.
func _skill_color(sk: Dictionary) -> Color:
	if sk.is_empty(): return Color(0.45, 0.5, 0.6)
	if bool(sk.get("ult", false)): return Color(1.0, 0.82, 0.36)
	match str(sk.get("type", "")):
		"guard", "manashield", "buff": return Color(0.45, 0.72, 1.0)
		"heal": return Color(0.45, 0.9, 0.6)
		"summon", "shadow_toggle", "shadow_command": return Color(0.75, 0.55, 1.0)
	return Color(1.0, 0.6, 0.35)

# ------------------------------------------------------------------ Thể lực
var _sta_used_at := 0
var _sta_warn_at := 0

func _attack_sta_cost() -> float:
	return maxf(1.0, roundf(float(Data.STAMINA.get("attack", 4.8)) * float(_weapon().get("cooldown", 360.0)) / 400.0))

## Trừ thể lực cho một đòn. Không đủ hoặc đang kiệt sức -> false (không đánh được).
func _spend_sta(cost: float) -> bool:
	if Game.sta_locked or float(Game.sta) < cost:
		Game.sta_locked = true
		var now := Time.get_ticks_msec()
		if now > _sta_warn_at:
			_sta_warn_at = now + 1500
			FloatText.spawn(_fx, _player.position + Vector2(0, -52), "Kiệt sức", Color(1.0, 0.79, 0.16), 14)
			if _hud_node: _hud_node.toast("Hết thể lực! Chờ hồi lại rồi đánh tiếp.", "warn")
		return false
	Game.sta = maxi(0, int(roundf(float(Game.sta) - cost)))
	_sta_used_at = Time.get_ticks_msec()
	_sta_frac = float(Game.sta)
	_hud_dirty = true
	return true

var _sta_frac := -1.0

func _stamina_tick(delta: float) -> void:
	if _dead: return
	var max_sta := int(Game.stats.get("maxSta", 100))
	if _sta_frac < 0.0 or absf(_sta_frac - float(Game.sta)) > 1.5: _sta_frac = float(Game.sta)
	if _sta_frac < float(max_sta):
		var rate := 1.0 if Time.get_ticks_msec() - _sta_used_at > int(Data.STAMINA.get("delay", 800)) else float(Data.STAMINA.get("activeMul", 0.3))
		_sta_frac = minf(float(max_sta), _sta_frac + float(Data.STAMINA.get("regen", 12.0)) * rate * (1.0 + float(Game.stats.get("staRegen", 0.0)) / 100.0) * delta)
		var new_sta := int(_sta_frac)
		if new_sta != Game.sta:
			Game.sta = new_sta
			_hud_dirty = true
	if Game.sta_locked and float(Game.sta) >= float(max_sta) * float(Data.STAMINA.get("unlock", 0.3)):
		Game.sta_locked = false

# ------------------------------------------------------------------ Biến hình (Ấn thức tỉnh)
var _aura: Node2D = null
var _form_ready_at := 0
var _form_acc := 0.0

func _active_awaken() -> Dictionary:
	return Data.awaken(maxi(1, Data.awaken_tier_of(Game.player.get("formChoice", ""))))

func _toggle_form() -> void:
	if _dead or _changing: return
	var tier := maxi(1, Data.awaken_tier_of(Game.player.get("formChoice", "")))
	if tier > int(Game.player.get("awakenTier", 0)):
		_hud_node.toast("Ấn chưa mở khóa. Hoàn thành thử thách NPC ẩn rồi dùng Sách Biến Hình.", "warn")
		return
	if Game.form_active:
		_end_form("")
		return
	var now := Time.get_ticks_msec()
	if now < _form_ready_at: return
	var aw := _active_awaken()
	var drain := float(aw.get("drain", 3))
	var need := drain * 3.0
	if float(Game.mp) < need or float(Game.sta) < need or Game.sta_locked:
		_hud_node.toast("Không đủ năng lượng / thể lực để biến hình (cần %d)." % int(need), "warn")
		return
	var hr := float(Game.hp) / float(maxi(1, int(Game.stats.get("maxHp", 1))))
	var mr := float(Game.mp) / float(maxi(1, int(Game.stats.get("maxMp", 1))))
	var sr := float(Game.sta) / float(maxi(1, int(Game.stats.get("maxSta", 1))))
	Game.form_active = true
	Game.recalc_stats()
	Game.hp = int(roundf(float(Game.stats.get("maxHp", 1)) * hr))
	Game.mp = int(roundf(float(Game.stats.get("maxMp", 1)) * mr))
	Game.sta = int(roundf(float(Game.stats.get("maxSta", 1)) * sr))
	_sta_frac = float(Game.sta)
	_form_acc = 0.0
	_form_ready_at = now + 1500
	_apply_form_visual(true, false)
	Net.action("form_toggle", {}, {"silent": true})
	_hud_node.banner("BIẾN HÌNH · ẤN THỨ %s" % ["NHẤT", "HAI", "BA", "TƯ", "NĂM"][clampi(int(aw.get("tier", 1)) - 1, 0, 4)], _col_int(int(aw.get("aura", 0xffcc66))))
	_hud_dirty = true

func _end_form(reason: String) -> void:
	if not Game.form_active: return
	var hr := float(Game.hp) / float(maxi(1, int(Game.stats.get("maxHp", 1))))
	var mr := float(Game.mp) / float(maxi(1, int(Game.stats.get("maxMp", 1))))
	var sr := float(Game.sta) / float(maxi(1, int(Game.stats.get("maxSta", 1))))
	Game.form_active = false
	Game.recalc_stats()
	Game.hp = maxi(1, int(roundf(float(Game.stats.get("maxHp", 1)) * hr)))
	Game.mp = maxi(0, int(roundf(float(Game.stats.get("maxMp", 1)) * mr)))
	Game.sta = maxi(0, int(roundf(float(Game.stats.get("maxSta", 1)) * sr)))
	_sta_frac = float(Game.sta)
	_form_ready_at = Time.get_ticks_msec() + 1500
	_apply_form_visual(false, false)
	Net.action("form_toggle", {}, {"silent": true})
	if not reason.is_empty() and _hud_node: _hud_node.toast(reason, "warn")
	FloatText.spawn(_fx, _player.position + Vector2(0, -52), "Trở lại dạng thường", Color(0.88, 0.88, 0.88), 12)
	_hud_dirty = true

func _col_int(v: int) -> Color:
	return Color.from_rgba8((v >> 16) & 255, (v >> 8) & 255, v & 255)

## Hào quang + nhuộm màu khi biến hình (idempotent). quiet: không phát hiệu ứng bùng nổ.
func _apply_form_visual(on: bool, quiet: bool = true) -> void:
	var aw := _active_awaken()
	if on and not aw.is_empty():
		_player.modulate = Color.WHITE.lerp(_col_int(int(aw.get("tint", 0xffffff))), 0.42)
		if _aura == null or not is_instance_valid(_aura):
			_aura = _make_aura(aw)
			_player.add_child(_aura)
		if not quiet:
			var col := _col_int(int(aw.get("aura", 0xffcc66)))
			_fxs.ring(_player.position + Vector2(0, 28), col, 120.0, 0.7, 6.0)
			_fxs.ring(_player.position + Vector2(0, 28), Color(1, 1, 1, 0.8), 70.0, 0.5, 3.0)
			_fxs.burst(_player.position, col, 24, 220.0)
			shake(7.0, 0.4)
			Audio.play("levelup", 0.8)
			if _hud_node: _hud_node.flash(col, 0.3)
	else:
		_player.modulate = Color.WHITE
		if _aura != null and is_instance_valid(_aura):
			_aura.queue_free()
		_aura = null

## Hào quang riêng từng Ấn: 1 vàng bốc lên · 2 hồng tím có tia điện · 3 băng lam rơi tuyết · 4 huyết hỏa dữ dội · 5 tím trắng quầng sáng + vệt sao xoay.
func _make_aura(aw: Dictionary) -> Node2D:
	var tier := int(aw.get("tier", 1))
	var c1 := _col_int(int(aw.get("aura", 0xffcc66)))
	var c2 := _col_int(int(aw.get("aura2", 0xffffff)))
	var root := Node2D.new()
	root.z_index = -1
	root.position = Vector2(0, 14)
	var halo := _AuraHalo.new()
	halo.col = c1
	halo.tier = tier
	root.add_child(halo)
	var low := Settings.quality_low
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	var p := CPUParticles2D.new()
	p.material = mat
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(11, 6)
	p.direction = Vector2.UP
	var g := Gradient.new()
	g.set_color(0, Color(c2, 0.9))
	g.add_point(0.5, Color(c1, 0.7))
	g.set_color(g.get_point_count() - 1, Color(c1, 0.0))
	p.color_ramp = g
	match tier:
		1:   # vàng: đốm sáng nhẹ bay lên
			p.amount = 14 if low else 26; p.lifetime = 0.9; p.spread = 22.0
			p.initial_velocity_min = 28.0; p.initial_velocity_max = 70.0
			p.gravity = Vector2(0, -30); p.scale_amount_min = 2.0; p.scale_amount_max = 5.0
		2:   # hồng tím: tia điện giật quanh người
			p.amount = 16 if low else 34; p.lifetime = 0.35; p.spread = 180.0
			p.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
			p.emission_sphere_radius = 16.0
			p.initial_velocity_min = 60.0; p.initial_velocity_max = 150.0
			p.gravity = Vector2.ZERO; p.scale_amount_min = 1.5; p.scale_amount_max = 3.5
			p.position = Vector2(0, -14)
			var bolt := _AuraBolts.new()
			bolt.col = c2
			root.add_child(bolt)
		3:   # băng lam: bông băng rơi chậm toả ra ngoài
			p.amount = 14 if low else 30; p.lifetime = 1.6; p.direction = Vector2.DOWN; p.spread = 70.0
			p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
			p.emission_rect_extents = Vector2(20, 26); p.position = Vector2(0, -34)
			p.initial_velocity_min = 8.0; p.initial_velocity_max = 28.0
			p.gravity = Vector2(0, 14); p.scale_amount_min = 2.0; p.scale_amount_max = 4.5
			p.angular_velocity_min = -90.0; p.angular_velocity_max = 90.0
		4:   # huyết hỏa: lửa cao, dữ dội
			p.amount = 22 if low else 48; p.lifetime = 0.8; p.spread = 16.0
			p.emission_rect_extents = Vector2(14, 5)
			p.initial_velocity_min = 70.0; p.initial_velocity_max = 150.0
			p.gravity = Vector2(0, -90); p.scale_amount_min = 3.0; p.scale_amount_max = 8.0
			g.set_color(0, Color(c2, 0.95))
		_:   # tím trắng: vệt sao xoay quanh người
			p.amount = 20 if low else 40; p.lifetime = 1.1; p.spread = 180.0
			p.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
			p.emission_sphere_radius = 24.0; p.position = Vector2(0, -16)
			p.initial_velocity_min = 4.0; p.initial_velocity_max = 20.0
			p.orbit_velocity_min = 0.6; p.orbit_velocity_max = 1.1
			p.gravity = Vector2(0, -22); p.scale_amount_min = 2.0; p.scale_amount_max = 5.0
	root.add_child(p)
	p.emitting = true
	return root

class _AuraHalo extends Node2D:
	var col := Color.WHITE
	var tier := 1
	var _t := 0.0
	var _redraw_acc := 0.0
	func _process(d: float) -> void:
		_t += d
		_redraw_acc += d
		if _redraw_acc >= 1.0 / 30.0:
			_redraw_acc = 0.0
			queue_redraw()
	func _draw() -> void:
		var pulse := 0.5 + 0.5 * sin(_t * (2.5 + float(tier) * 0.7))
		var r := 30.0 + float(tier) * 3.0 + pulse * 4.0
		draw_set_transform(Vector2(0, -18), 0.0, Vector2(0.8, 1.15))
		draw_circle(Vector2.ZERO, r, Color(col, 0.10 + 0.06 * pulse))
		draw_circle(Vector2.ZERO, r * 0.7, Color(col, 0.12))
		if tier >= 5:
			draw_arc(Vector2.ZERO, r + 6.0, _t * 1.4, _t * 1.4 + PI * 1.2, 24, Color(1, 1, 1, 0.55), 2.0)
			draw_arc(Vector2.ZERO, r + 12.0, -_t * 1.0, -_t * 1.0 + PI * 0.9, 24, Color(col, 0.6), 2.0)
		elif tier == 3:
			for i in range(6):
				var a := float(i) * TAU / 6.0 + _t * 0.4
				draw_line(Vector2(cos(a), sin(a)) * (r - 4.0), Vector2(cos(a), sin(a)) * (r + 6.0), Color(1, 1, 1, 0.45), 1.5)
		elif tier == 4:
			draw_arc(Vector2.ZERO, r + 3.0, 0.0, TAU, 32, Color(col, 0.35 + 0.25 * pulse), 3.0)

class _AuraBolts extends Node2D:
	var col := Color.WHITE
	var _t := 0.0
	var _seed := 0
	var _rng := RandomNumberGenerator.new()
	func _process(d: float) -> void:
		_t += d
		if _t > 0.09:
			_t = 0.0
			_seed = randi()
			queue_redraw()
	func _draw() -> void:
		_rng.seed = _seed
		for k in range(2):
			var p := Vector2(0, -18)
			var a := _rng.randf() * TAU
			for i in range(4):
				a += _rng.randf_range(-0.9, 0.9)
				var n := p + Vector2(cos(a), sin(a)) * _rng.randf_range(7.0, 13.0)
				draw_line(p, n, Color(col, 0.95), 1.6)
				p = n

## Mỗi giây trừ năng lượng + thể lực theo ấn; cạn mà hồi không đủ bù thì tự trở lại dạng thường (như web).
func _form_tick(delta: float) -> void:
	if not Game.form_active or _dead: return
	var aw := _active_awaken()
	if aw.is_empty():
		_end_form("")
		return
	_form_acc += delta
	var drain := int(aw.get("drain", 3))
	while _form_acc >= 1.0:
		_form_acc -= 1.0
		Game.mp = maxi(0, Game.mp - drain)
		Game.sta = maxi(0, Game.sta - drain)
		_sta_frac = float(Game.sta)
		_hud_dirty = true
	# Tốc độ hồi thực tế mỗi giây — khớp formRegenRates() của web (hồi MP chỉ khi không giao chiến; Dòng Chảy luôn hồi)
	var max_mp_f := float(int(Game.stats.get("maxMp", 100)))
	var now_f := Time.get_ticks_msec()
	var calm_f := int(Game._as_dict(Data.calc.get("REGEN", {})).get("calmMs", 2000))
	var fighting_f := now_f - _sta_used_at < calm_f or now_f - _last_hurt < calm_f
	var mp_regen := max_mp_f * 0.005 if Game.has_passive("phap_su") else 0.0
	if not fighting_f: mp_regen += maxf(float(Game._as_dict(Data.calc.get("REGEN", {})).get("mp", 1)), max_mp_f * 0.005)
	var sta_regen := float(Data.STAMINA.get("regen", 12.0)) * (1.0 if now_f - _sta_used_at > int(Data.STAMINA.get("delay", 800)) else float(Data.STAMINA.get("activeMul", 0.3))) * (1.0 + float(Game.stats.get("staRegen", 0.0)) / 100.0)
	if Game.mp <= 0 and mp_regen < float(drain): _end_form("Hết năng lượng, biến hình kết thúc.")
	elif Game.sta <= 0 and sta_regen < float(drain):
		Game.sta_locked = true
		_end_form("Hết thể lực, biến hình kết thúc.")

## Đổi vòng qua các Ấn đã mở (Ấn I -> II -> ... -> I). Chỉ đổi được ở dạng thường.
func _switch_seal() -> void:
	var unlocked := int(Game.player.get("awakenTier", 0))
	if unlocked < 2 or _dead or _changing: return
	if Game.form_active:
		_hud_node.toast("Hãy trở lại dạng thường trước khi đổi ấn.", "warn")
		return
	var cur := maxi(1, Data.awaken_tier_of(Game.player.get("formChoice", "")))
	var nxt := cur % unlocked + 1
	Net.action("form_select", {"choice": "awaken%d" % nxt}, {"silent": true})
	_hud_node.toast("Đã chọn Biến hình · Ấn %s" % str(Data.ROMAN[nxt - 1]), "success")
	Audio.play("ui")

# ------------------------------------------------------------------ NPC ẩn (Người Gác Màn)
func _sync_hidden_npc() -> void:
	if _entities == null: return
	var want: bool = str(Game.player.get("map", "")) == "lang" and bool(Game.player.get("hiddenNpcActive", false))
	var has: bool = _entities.has_npc("npc_an")
	if want and not has:
		var x := clampf(_player.position.x + 100.0, 60.0, float(_cols) * TILE - 60.0)
		var gy := _ground_y(x, _player.position.y)
		_entities.spawn_npc("npc_an", Vector2(x, gy))
	elif not want and has:
		_entities.remove_npc("npc_an")

# ------------------------------------------------------------------ Hiệu ứng đang dùng (buff) trên HUD — như thanh buff của web
var _buff_hud_acc := 0.0

func _buff_hud_tick(delta: float) -> void:
	_buff_hud_acc += delta
	if _buff_hud_acc < 0.12: return
	_buff_hud_acc = 0.0
	if _skill_fx != null and _skill_fx.has_method("sync_auras"): _skill_fx.sync_auras(_buffs, _player, _facing)   # hào quang buff theo người suốt thời gian hiệu lực
	if _hud_node == null: return
	var now := Time.get_ticks_msec()
	var list: Array = []
	for id in _buffs.keys():
		var b: Dictionary = _buffs[id]
		var left := int(b.get("until", 0)) - now
		if left <= 0: continue
		var sk: Dictionary = Data.skill(str(b.get("skill", id)))
		var icon := GlyphArt.skill_token(str(id), str(sk.get("icon", "@star"))) if not sk.is_empty() else "@star"
		list.append({"id": str(id), "icon": icon, "label": str(sk.get("name", b.get("name", id))), "left": left, "dur": maxi(1, int(b.get("dur", left)))})
	_hud_node.set_buffs(list)

## Đổi khu: gỡ đồ rơi của khu cũ khỏi màn hình, dựng lại đồ đã rơi ở khu mới (mỗi khu một thế giới riêng).
func _apply_loot_channel(ch: int) -> void:
	for lid in _loots.keys():
		var st: Dictionary = _loot_store.get(lid, {})
		if st.is_empty() or int(st["ch"]) == ch: continue
		var n: Node = _loots[lid]
		if is_instance_valid(n): n.queue_free()
		_loots.erase(lid)
		_pickup_pending.erase(lid)
	for lid in _loot_store.keys():
		var st2: Dictionary = _loot_store[lid]
		if int(st2["ch"]) == ch and not _loots.has(lid): _add_loot(st2["data"], false)

## Hồi phục theo số lẻ như web (App.hp là số thực): cộng dồn phần lẻ, trả về phần nguyên mỗi lần.
var _carry_acc: Dictionary = {}
func _carry(key: String, amount: float) -> int:
	var v := float(_carry_acc.get(key, 0.0)) + amount
	var whole := int(floor(v))
	_carry_acc[key] = v - float(whole)
	return whole

# ------------------------------------------------------------------ Nhắm mục tiêu (như target.js của web)
## Quay mặt về quái đang chỉ định trước khi tung kỹ năng đánh thẳng.
func _aim_at_target() -> void:
	var m := _target_mob
	if m == null or not is_instance_valid(m) or not m.alive: return
	var dx: float = m.position.x - _player.position.x
	if absf(dx) > 8.0: _facing = -1 if dx < 0.0 else 1

## Góc bắn (rad, theo hướng đã quay mặt) để đạn bay vào đúng quái đang chỉ định, kẹp ±0,6.
func _target_angle() -> float:
	var m := _target_mob
	if m == null or not is_instance_valid(m) or not m.alive: return 0.0
	var dx: float = absf(m.position.x - _player.position.x)
	if dx < 30.0: return 0.0
	var cy: float = m.position.y - float(m._height) * 0.5 if not bool(m.fly) else m.position.y
	return clampf(atan2(cy - _player.position.y, dx), -0.6, 0.6)
