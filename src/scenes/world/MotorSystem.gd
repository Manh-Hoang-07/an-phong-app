extends "res://src/scenes/world/WorldPart.gd"
## Di chuyển nhân vật: vật lý, nhảy, coyote time, hoạt ảnh/hướng.
## Hệ thống của World (w = World). Trạng thái riêng khai báo ngay dưới; trạng thái dùng chung đọc qua thuộc tính chuyển tiếp.

const SPEED := 190.0
const GRAVITY := 1300.0
const JUMP_V := 560.0
const SAVE_EVERY := 5.0
const SAVE_IDLE_MAX := 30.0

# Trạng thái riêng
var _last_ground_at := 0             # coyote time: còn nhảy được 110ms sau khi rời mép
var _jump_buffered_at := -1000       # bộ đệm nhảy: bấm sớm 140ms vẫn nhảy khi chạm đất
var _jumped_air := false
var _save_acc := 0.0
var _last_saved_sig := 0
var _save_idle := 0.0

# Trạng thái dùng chung (lưu ở World)
var _player: Node2D:
	get: return w._player if is_instance_valid(w._player) else null
	set(x): w._player = x
var _cam: Camera2D:
	get: return w._cam if is_instance_valid(w._cam) else null
	set(x): w._cam = x
var _mobs: Dictionary:
	get: return w._mobs
	set(x): w._mobs = x
var _map_id: String:
	get: return w._map_id
	set(x): w._map_id = x
var _grid: Array:
	get: return w._grid
	set(x): w._grid = x
var _cols: int:
	get: return w._cols
	set(x): w._cols = x
var _facing: int:
	get: return w._facing
	set(x): w._facing = x
var _anim: String:
	get: return w._anim
	set(x): w._anim = x
var _move_dir: Vector2:
	get: return w._move_dir
	set(x): w._move_dir = x
var _vy: float:
	get: return w._vy
	set(x): w._vy = x
var _knock_vx: float:
	get: return w._knock_vx
	set(x): w._knock_vx = x
var _knock_until: int:
	get: return w._knock_until
	set(x): w._knock_until = x
var _jump_req: bool:
	get: return w._jump_req
	set(x): w._jump_req = x
var _attack_until: int:
	get: return w._attack_until
	set(x): w._attack_until = x
var _hurt_until: int:
	get: return w._hurt_until
	set(x): w._hurt_until = x
var _slow_until: int:
	get: return w._slow_until
	set(x): w._slow_until = x
var _dead: bool:
	get: return w._dead
	set(x): w._dead = x
var _changing: bool:
	get: return w._changing
	set(x): w._changing = x
var _last_saved: Vector2:
	get: return w._last_saved
	set(x): w._last_saved = x
var _player_sprite: Node2D:
	get: return w._player_sprite if is_instance_valid(w._player_sprite) else null
	set(x): w._player_sprite = x

# Hàm của hệ thống khác
func _walkable(x: float, y: float) -> bool:
	return w.map._walkable(x, y)

func _ground_y(x: float, foot_y: float) -> float:
	return w.map._ground_y(x, foot_y)

func _process(delta: float) -> void:
	w._process(delta)

func _buff_sum(key: String) -> float:
	return w.buffs._buff_sum(key)

func _hurt_player(m: Node2D, mult: float = 1.0, enrage_scale: bool = true) -> void:
	w.life._hurt_player(m, mult, enrage_scale)

func _pets_payload() -> Dictionary:
	return w.pets._pets_payload()

func _save_state() -> void:
	w.life._save_state()

func _reload_after_move(from_death: bool) -> void:
	w.net._reload_after_move(from_death)

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
