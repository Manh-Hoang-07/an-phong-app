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
var _pet: Node2D = null          # thú đồng hành đi theo player
var _pet_id: String = ""

var _players: Dictionary = {}   # id -> RemotePlayer
var _mobs: Dictionary = {}      # uid -> MobSprite
var _loots: Dictionary = {}     # lid -> LootNode
var _map_id := ""
var _meta: Dictionary = {}
var _grid: Array = []
var _cols := 0
var _rows := 0

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
var _dead := false
var _changing := false
var _reload_queued := false
var _skill_ids: Array = ["pa1", "pa2", "pa3", "pa4", "pa5"]
var _cd_until: Array = [0, 0, 0, 0, 0, 0, 0]   # 0-3 thường, 4-5 tuyệt kỹ/tuyệt phẩm (ô 5,6), 6 kỹ năng trang bị

## Ô nút HUD -> id kỹ năng (đúng mô hình ô của web/server). Ô trang bị là ô ảo lấy từ món đang mặc.
func _btn_skill(i: int) -> String:
	var slots: Array = Game.player.get("skillSlots", [])
	match i:
		0, 1, 2, 3:
			var s0 := str(slots[i]) if i < slots.size() and slots[i] != null else ""
			return s0 if s0 != "" else str(_skill_ids[i])
		4, 5:
			var k := i + 1
			return str(slots[k]) if k < slots.size() and slots[k] != null else ""
		6:
			return _gear_skill_id()
	return ""

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
var _regen_acc := 0.0
var _hud_dirty := true
var _hud_acc := 0.0
var _pickup_pending: Dictionary = {}
var _pickup_lid := ""
var _interact: Dictionary = {}
var _other_fx_at := 0
var _other_fx_n := 0

# ------------------------------------------------------------------ Khởi tạo
func _ready() -> void:
	_char_script = load("res://src/world/CharSprite.gd")
	_mob_script = load("res://src/world/MobSprite.gd")
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

func _setup_player_sprite() -> void:
	var school := str(Game.player.get("school", "kiem_si"))
	for c in _player.get_children(): c.queue_free()
	if _char_script:
		var sprite: Node2D = _char_script.new()
		_player.add_child(sprite)
		sprite.setup(school)
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
	_map_id = str(Game.player.get("map", "cong_do"))
	if _map_id.is_empty() or not Data.has_map_text(_map_id):
		_map_id = "cong_do"
	_meta = Data.map_def(_map_id)
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
	if Settings.debug_stats: print("Dựng map ", _map_id, " mất ", Time.get_ticks_msec() - t_bake, "ms")
	_entities.build(_grid, TILE, _meta, func(r: int, c: int) -> float:
		return float(_ground_y(float(c) * TILE + TILE * 0.5, float(r) * TILE)))
	_entities.refresh_visibility(Game.player, _map_id)
	if _bg_node and _bg_node.has_method("set_map"):
		_bg_node.set_map(_map_id, theme_id, Settings.quality_low)
	var look: Dictionary = Data.look(_map_id)
	if _weather: _weather.apply(look)
	RenderingServer.set_default_clear_color(Color.from_rgba8((int(look.get("bg", 0x101820)) >> 16) & 255, (int(look.get("bg", 0x101820)) >> 8) & 255, int(look.get("bg", 0x101820)) & 255))
	if _cam:
		_cam.zoom = Vector2(1.3, 1.3)
		_cam.limit_left = 0
		_cam.limit_right = int(float(_cols) * TILE)
		_cam.limit_top = 0
		_cam.limit_bottom = int(float(_rows) * TILE)
		_cam.global_position = _player.position
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

func _walkable(x: float, y: float) -> bool:
	var ch := _cell(x, y)
	return ch != "#" and ch != "" and ch != " "

func _is_stand(r: int, c: int) -> bool:
	if r < 0 or r >= _rows or c < 0 or c >= _cols: return r >= _rows
	var ch := str((_grid[r] as Array)[c])
	return ch == "#" or ch == "="

## y mặt đất gần nhất bên dưới chân (theo ô của grid đã giãn).
func _ground_y(x: float, foot_y: float) -> float:
	var c := int(floor(x / TILE))
	var r := int(floor(foot_y / TILE))
	for rr in range(maxi(0, r), _rows):
		if _is_stand(rr, c): return float(rr) * TILE
	return float(_rows) * TILE

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
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_V: _cast(6)
	elif event.is_action_pressed("attack"): _on_attack()

## Đồng bộ thú đồng hành với dữ liệu server (mounts.summoned). Gọi mỗi khung + sau action.
func _sync_pet() -> void:
	var mounts: Variant = Game.player.get("mounts", {})
	var summoned: Array = []
	if typeof(mounts) == TYPE_DICTIONARY:
		var sv: Variant = (mounts as Dictionary).get("summoned", [])
		if typeof(sv) == TYPE_ARRAY: summoned = sv
		elif typeof(sv) == TYPE_STRING and str(sv) != "": summoned = [sv]
	var want := str(summoned[0]) if not summoned.is_empty() else ""
	if want == _pet_id: return
	if is_instance_valid(_pet): _pet.queue_free(); _pet = null
	_pet_id = want
	if want != "" and _mob_script != null:
		# Dùng MobSprite (đã render quái ổn) làm thú đi theo.
		var pet: Node2D = _mob_script.new()
		var def: Dictionary = Data.monster(want)
		pet.setup(900001, want, str(def.get("look", "")), str(def.get("sprite", "")))
		pet.set_process(true)
		pet.set_physics_process(false)
		pet.z_index = 3
		var pn: Variant = pet.get("_name")
		if pn is Node: (pn as Node).visible = false
		var pb: Variant = pet.get("_bar")
		if pb is Node: (pb as Node).visible = false
		# Đặt ngoài _mob_layer để vòng lặp quái của World không gọi show_name(true) lại.
		var host_node: Node = _mob_layer.get_parent()
		host_node.add_child(pet)
		host_node.move_child(pet, _mob_layer.get_index())
		pet.set_target(_player.position, true)
		_pet = pet

func _process(delta: float) -> void:
	if not Game.has_player(): return
	_sync_pet()
	if is_instance_valid(_pet) and _pet.has_method("set_target"):
		_pet.set_target(_player.position + Vector2(-float(_facing) * 42.0, 6.0))
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
	_update_interact()
	_regen(delta)
	_stamina_tick(delta)
	_form_tick(delta)

func _physics_process(delta: float) -> void:
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

	if jump_pressed and on_ground and not drop_pressed:
		_vy = -JUMP_V
		on_ground = false

	if not on_ground:
		_vy += GRAVITY * delta
		_player.position.y += _vy * delta
		foot = _player.position.y + 30.0
		gy = _ground_y(_player.position.x, foot)
		if _vy >= 0.0 and foot >= gy:
			_player.position.y = gy - 30.0
			_vy = 0.0
			on_ground = true
	else:
		_player.position.y = gy - 30.0
		_vy = 0.0

	var vx := dir.x * SPEED
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
		m.show_name(absf(m.position.x - _player.position.x) < 380.0 and absf(m.position.y - _player.position.y) < 240.0)
		if m.state == 2 and not m.lunge_hit and m.atk > 0 and not _dead:
			var br: Rect2 = m.body_rect().grow(-4.0)
			if br.intersects(prect):
				m.lunge_hit = true
				_hurt_player(m)

	if _cam:
		_cam.position = _player.position

	# Lưu định kỳ
	_save_acc += delta
	if _save_acc >= SAVE_EVERY and not _dead and not _changing:
		_save_acc = 0.0
		var p := Vector2(roundf(_player.position.x), roundf(_player.position.y))
		if p != _last_saved or true:
			_last_saved = p
			_save_state()

func _server_anim(a: String) -> String:
	match a:
		"attack1", "attack2", "attack3": return "atk"
		"death": return "dead"
		"jump", "fall", "run", "hit", "idle": return a
	return "idle"

func _set_facing(f: int) -> void:
	for c in _player.get_children():
		if c.has_method("set_facing"): c.set_facing(f)

func _play_anim(a: String) -> void:
	for c in _player.get_children():
		if c.has_method("play"): c.play(a)

func _hp_pct() -> int:
	var mx := maxi(1, int(Game.stats.get("maxHp", 100)))
	return clampi(int(roundf(float(Game.hp) / float(mx) * 100.0)), 0, 100)

# ------------------------------------------------------------------ Chiến đấu
func _atk_stat() -> int:
	var st: Dictionary = Game.stats
	if st.is_empty(): st = Game.player.get("stats", {})
	return int(st.get("atk", Game.player.get("atk", 30)))

## Quét hình chữ nhật trước mặt, gửi đòn cho MỌI quái trúng (khớp hitBox của web).
func _strike(range_px: float, skill_id: String, power: float, kind: int, hits: int = 1, gap: float = 0.12) -> void:
	for i in range(hits):
		if i > 0: await get_tree().create_timer(gap).timeout
		if _dead or not is_inside_tree(): return
		_strike_once(range_px, skill_id, power, kind)

func _strike_once(range_px: float, skill_id: String, power: float, kind: int) -> void:
	var skill_mul := float(Game.stats.get("skillMul", 1.0)) if kind > 0 else 1.0
	var dmg := maxi(1, int(roundf(float(_atk_stat()) * maxf(0.05, power) * skill_mul * randf_range(0.95, 1.05))))
	var crit_p := float(Game.stats.get("crit", 3.0)) / 100.0
	var crit := randf() < crit_p
	if crit: dmg = int(roundf(float(dmg) * 1.5))
	var cx := _player.position.x + float(_facing) * range_px * 0.5
	var cy := _player.position.y
	var half_w := range_px * 0.5 + 20.0
	var hits := 0
	for u in _mobs.keys():
		var mob: Node2D = _mobs[u]
		if not is_instance_valid(mob) or not mob.alive: continue
		if absf(mob.position.x - cx) <= half_w and absf((mob.position.y - 20.0) - cy) <= 70.0:
			Socket.send_hit(int(u), dmg, skill_id, kind, _facing, crit)
			hits += 1
	if hits == 0 and kind == 0 and _hud_node:
		pass

func _on_attack() -> void:
	if _dead or _changing: return
	var now := Time.get_ticks_msec()
	if now < _next_attack: return
	if not _spend_sta(_attack_sta_cost()): return
	_next_attack = now + ATTACK_GAP_MS
	_attack_until = now + 280
	Audio.play("hit", 1.2)
	_fxs.slash(_player.position + Vector2(0, 6), _facing, Color(1.0, 0.95, 0.8), 1.0, int(now / 340) % 2 == 0)
	_strike(110.0, "", 1.0, 0)

func _cast(index: int) -> void:
	if _dead or _changing or index >= 7: return
	var id := _btn_skill(index)
	var sk: Dictionary = Data.skill_eff(Game.player, id)
	if sk.is_empty():
		if _hud_node: _hud_node.toast("Ô kỹ năng trống — mở Kỹ năng để gán", "warn")
		return
	var now := Time.get_ticks_msec()
	if now < int(_cd_until[index]):
		return
	var cost := int(sk.get("mp", 0))
	if Game.mp < cost:
		if _hud_node: _hud_node.toast("Không đủ MP", "warn")
		return
	var sta_cost: float = float(Data.STAMINA.get("ult", 50.0)) if bool(sk.get("ult", false)) else float(Data.STAMINA.get("skill", 14.0))
	if not _spend_sta(sta_cost): return
	Game.mp -= cost
	var cd := float(sk.get("cd", 1.0))
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
	if _skill_fx and _skill_fx.has_method("play"):
		_skill_fx.play("cast", id, _player.position, _facing)
	var kind := 1
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
		"dash": _dash(float(sk.get("distance", 170.0)))
		"melee", "backstep": _fxs.slash(_player.position + Vector2(0, 6), _facing, Color(1.0, 0.85, 0.5), 1.5)
		"guard", "manashield", "buff": _fxs.shield(_player.position + Vector2(0, 26), Color(0.45, 0.72, 1.0) if stype != "buff" else Color(1.0, 0.85, 0.4))
		"heal":
			_fxs.heal(_player.position)
			Audio.play("coin", 0.8)
		"aoe", "meteor", "sword_fall", "arrow_rain": _fxs.ring(_player.position + Vector2(float(_facing) * 70.0, 28), Color(1.0, 0.6, 0.3), 120.0, 0.5, 5.0)
		"summon", "shadow_toggle", "shadow_command": _fxs.ring(_player.position + Vector2(0, 28), Color(0.7, 0.5, 1.0), 80.0, 0.6, 4.0)
	if sk.has("power") and float(sk.get("power", 0.0)) > 0.0:
		var reach := float(sk.get("range", sk.get("distance", 130.0)))
		_strike(maxf(90.0, reach), id, float(sk.get("power", 1.0)), kind, maxi(1, int(sk.get("hits", 1))))
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

func _hurt_player(m: Node2D) -> void:
	var now := Time.get_ticks_msec()
	if now < _invuln_until or _dead: return
	var def_v := float(Game.stats.get("def", 0))
	var lv := int(Game.player.get("level", 1))
	var raw := float(m.atk) * randf_range(0.9, 1.1)
	var dmg := Formulas.mitigate(raw, def_v, lv)
	Game.hp = maxi(0, Game.hp - dmg)
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
	if Game.hp > 0 and float(Game.hp) / float(maxi(1, int(Game.stats.get("maxHp", 100)))) < 0.3: _hud_node.hint_once("lowhp", "Máu thấp! Mở Túi và dùng bình máu.")
	if Game.hp <= 0: _die()

func _regen(delta: float) -> void:
	if _dead or _changing: return
	_regen_acc += delta
	if _regen_acc < 1.0: return
	_regen_acc = 0.0
	var mx_hp := int(Game.stats.get("maxHp", 0))
	var mx_mp := int(Game.stats.get("maxMp", 0))
	var changed := false
	if Game.mp < mx_mp:
		Game.mp = mini(mx_mp, Game.mp + maxi(1, int(roundf(float(mx_mp) * 0.015))))
		changed = true
	if Game.hp < mx_hp and Time.get_ticks_msec() - _last_hurt > 5000:
		Game.hp = mini(mx_hp, Game.hp + maxi(1, int(roundf(float(mx_hp) * 0.005))))
		changed = true
	if changed: _hud_dirty = true

# ------------------------------------------------------------------ Chết / hồi sinh
func _die() -> void:
	if _dead: return
	_end_form("")
	_dead = true
	Game.hp = 0
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
		"hp": Game.hp, "mp": Game.mp}, {"silent": true})

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
		if _hud_node: _hud_node.set_interact("")
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
		_interact = {"type": "loot", "lid": lbest.lid, "name": lbest.item_name}
	else:
		_interact = best
	var label := ""
	match str(_interact.get("type", "")):
		"portal": label = "Vào · %s" % str(_interact.get("name", "cổng"))
		"loot": label = "Nhặt · %s" % str(_interact.get("name", ""))
		"npc": label = "Nói chuyện · %s" % str(_interact.get("name", ""))
	_hud_node.set_interact(label)
	if _interact.get("type") == "npc": _hud_node.hint_once("npc", "Chạm nút ở giữa-dưới để nói chuyện với NPC.")
	elif _interact.get("type") == "loot": _hud_node.hint_once("loot", "Đứng gần đồ rơi và chạm \"Nhặt\" để lấy.")
	elif _interact.get("type") == "portal": _hud_node.hint_once("portal", "Chạm \"Vào\" để qua cổng. Một số cổng cần hoàn thành nhiệm vụ.")

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
	Net.action("change_map", {"portal": key, "hp": Game.hp, "mp": Game.mp})

func use_teleport(to: String) -> void:
	if _changing: return
	_changing = true
	_flush_kills()
	create_tween().tween_property(_fade, "modulate:a", 1.0, 0.25)
	Net.action("teleport", {"to": to, "hp": Game.hp, "mp": Game.mp})

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

func _add_loot(data: Dictionary, animate: bool) -> void:
	var lid := str(data.get("lid", ""))
	if lid.is_empty() or _loots.has(lid) or str(data.get("map", _map_id)) != _map_id: return
	var n: LootNode = LootNode.new()
	_loot_layer.add_child(n)
	n.setup(data)
	if not animate:
		n.scale = Vector2.ONE
	_loots[lid] = n

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
	Socket.send_chat(t, "map")

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
		if not str(nd.get("shop", "")).is_empty() or not str(nd.get("ngocShop", "")).is_empty():
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
				if typeof(e) != TYPE_ARRAY or (e as Array).size() < 5: continue
				var rp: RemotePlayer = _players.get(int(e[0]), null)
				if rp: rp.apply_state({"x": e[1], "y": e[2], "f": e[3], "a": e[4]})
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
	print("[MOB] nhan danh sach: ", (msg.get("list", []) as Array).size(), " map=", msg.get("map", "?"))
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
	if int(info.get("al", 1)) == 1:
		if not node.alive: node.revive()
		node.visible = true
	else:
		node.alive = false
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
		"mact":
			var bm: Node2D = _mobs.get(int(msg.get("u", 0)), null)
			if bm == null or not bm.alive: return
			var dxm := absf(bm.position.x - _player.position.x)
			match str(msg.get("a", "")):
				"slam":
					shake(8.0, 0.35)
					FloatText.spawn(_fx, bm.position + Vector2(0, -90), "Giậm đất!", Color(1.0, 0.6, 0.3), 18)
					if dxm < 230.0 and absf(bm.position.y - _player.position.y) < 120.0: _hurt_player(bm)
				"special":
					shake(5.0, 0.4)
					FloatText.spawn(_fx, bm.position + Vector2(0, -90), "Tuyệt chiêu!", Color(1.0, 0.4, 0.8), 18)
					if dxm < 300.0 and absf(bm.position.y - _player.position.y) < 160.0: _hurt_player(bm)
				"enrage":
					FloatText.spawn(_fx, bm.position + Vector2(0, -90), "Phẫn nộ!", Color(1.0, 0.3, 0.3), 20)
					shake(4.0, 0.3)
		"mdel":
			var u := int(msg.get("u", 0))
			if _mobs.has(u):
				(_mobs[u] as Node).queue_free()
				_mobs.erase(u)

func shake(strength: float, duration: float) -> void:
	if _cam == null: return
	var tw := create_tween()
	var steps := int(duration / 0.04)
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
	_hud_node.set_quest(qtext)
	if _entities:
		var cq: Dictionary = Data.quest_current(p)
		_entities.set_quest_marks(str(cq.get("npc", "")), ("done" if Data.quest_ready(p) else str(q.get("state", ""))) if not q.is_empty() else "")
		_entities.refresh_visibility(p, _map_id)
	var labels: Array = []
	for i in range(7):
		var sid := _btn_skill(i)
		var sk: Dictionary = Data.skill(sid)
		labels.append("%s|%s" % [(GlyphArt.skill_token(sid, str(sk.get("icon", "@star"))) if not sk.is_empty() else ("@star" if i >= 4 and i < 6 else "")), str(sk.get("name", sid))])
	_hud_node.set_skill_visible(6, _gear_skill_id() != "")
	_hud_node.set_skill_labels(labels)
	var colors: Array = []
	var usable: Array = []
	for i in range(7):
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

func _update_potions() -> void:
	var best := {"hp": ["", 0, 1 << 30], "mp": ["", 0, 1 << 30]}   # [id, tổng số lượng, mức hồi]
	var totals := {}
	for e in Game.player.get("bag", []):
		if typeof(e) != TYPE_DICTIONARY: continue
		var iid := str(e.get("id", ""))
		var d: Dictionary = Data.item(iid)
		if str(d.get("kind", "")) != "potion": continue
		totals[iid] = int(totals.get(iid, 0)) + int(e.get("n", e.get("qty", 1)))
	for iid in totals.keys():
		var d2: Dictionary = Data.item(str(iid))
		for k in ["hp", "mp"]:
			var amt := int(d2.get(k, 0))
			if amt > 0 and amt < int((best[k] as Array)[2]): best[k] = [str(iid), int(totals[iid]), amt]
	_potion_ids["hp"] = (best["hp"] as Array)[0]
	_potion_ids["mp"] = (best["mp"] as Array)[0]
	_hud_node.set_potions(str(_potion_ids["hp"]), int((best["hp"] as Array)[1]), str(_potion_ids["mp"]), int((best["mp"] as Array)[1]))

func _use_quick_potion(kind: String) -> void:
	var now := Time.get_ticks_msec()
	if _dead or _changing or now < _potion_cd_until: return
	var iid := str(_potion_ids.get(kind, ""))
	if iid.is_empty(): return
	var full := (Game.hp >= int(Game.stats.get("maxHp", 1))) if kind == "hp" else (Game.mp >= int(Game.stats.get("maxMp", 1)))
	if full:
		_hud_node.toast("%s đã đầy" % ("Máu" if kind == "hp" else "MP"), "warn")
		return
	_potion_cd_until = now + 1000
	_hud_node.potion_cooldown(kind, 1.0)
	_fxs.heal(_player.position)
	Audio.play("pickup", 0.9)
	Net.action("use", {"item": iid}, {"silent": true})

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
	return maxf(1.0, roundf(float(Data.STAMINA.get("attack", 4.8)) * float(ATTACK_GAP_MS) / 400.0))

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
		_sta_frac = minf(float(max_sta), _sta_frac + float(Data.STAMINA.get("regen", 12.0)) * rate * delta)
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
	func _process(d: float) -> void:
		_t += d
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
	func _process(d: float) -> void:
		_t += d
		if _t > 0.09:
			_t = 0.0
			_seed = randi()
			queue_redraw()
	func _draw() -> void:
		var rng := RandomNumberGenerator.new()
		rng.seed = _seed
		for k in range(2):
			var p := Vector2(0, -18)
			var a := rng.randf() * TAU
			for i in range(4):
				a += rng.randf_range(-0.9, 0.9)
				var n := p + Vector2(cos(a), sin(a)) * rng.randf_range(7.0, 13.0)
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
	var mp_regen := maxf(float(int(Game.stats.get("maxMp", 100))) * 0.015, 1.0)
	var sta_regen := float(Data.STAMINA.get("regen", 12.0)) * (1.0 if Time.get_ticks_msec() - _sta_used_at > 800 else float(Data.STAMINA.get("activeMul", 0.3)))
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
