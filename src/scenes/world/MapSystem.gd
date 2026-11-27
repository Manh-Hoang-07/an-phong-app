extends "res://src/scenes/world/WorldPart.gd"
## Bản đồ: tải map, lưới/va chạm, mặt đất, giới hạn camera.
## Hệ thống của World (w = World). Trạng thái riêng khai báo ngay dưới; trạng thái dùng chung đọc qua thuộc tính chuyển tiếp.

const STRETCH := 1.5
const MapGrid := preload("res://src/world/MapGrid.gd")
## Đáy camera: chỉ chừa ~1.5 ô dưới mặt đất thấp nhất có thể đứng, để lớp đất sâu không chiếm cả màn hình.
const CAM_BELOW_GROUND := 64.0

# Trạng thái riêng
# Bake va chạm/mặt đất theo cột khi load map: _move_step gọi _ground_y 4 lần + _walkable 2 lần mỗi khung.
var _stand_rows: Array = []          # _stand_rows[c] = mảng các hàng đứng (#/=) đã sort tăng dần
var _walk_cache: Array[bool] = []    # index = row * _cols + col

# Trạng thái dùng chung (lưu ở World)
var _player: Node2D:
	get: return w._player if is_instance_valid(w._player) else null
	set(x): w._player = x
var _cam: Camera2D:
	get: return w._cam if is_instance_valid(w._cam) else null
	set(x): w._cam = x
var _bg_node: Node:
	get: return w._bg_node if is_instance_valid(w._bg_node) else null
	set(x): w._bg_node = x
var _map_view: Node2D:
	get: return w._map_view if is_instance_valid(w._map_view) else null
	set(x): w._map_view = x
var _entities: Node2D:
	get: return w._entities if is_instance_valid(w._entities) else null
	set(x): w._entities = x
var _weather: CanvasLayer:
	get: return w._weather if is_instance_valid(w._weather) else null
	set(x): w._weather = x
var _assist: Node:
	get: return w._assist if is_instance_valid(w._assist) else null
	set(x): w._assist = x
var _players: Dictionary:
	get: return w._players
	set(x): w._players = x
var _mobs: Dictionary:
	get: return w._mobs
	set(x): w._mobs = x
var _loots: Dictionary:
	get: return w._loots
	set(x): w._loots = x
var _map_id: String:
	get: return w._map_id
	set(x): w._map_id = x
var _meta: Dictionary:
	get: return w._meta
	set(x): w._meta = x
var _grid: Array:
	get: return w._grid
	set(x): w._grid = x
var _cols: int:
	get: return w._cols
	set(x): w._cols = x
var _rows: int:
	get: return w._rows
	set(x): w._rows = x
var _facing: int:
	get: return w._facing
	set(x): w._facing = x
var _vy: float:
	get: return w._vy
	set(x): w._vy = x
var _invuln_until: int:
	get: return w._invuln_until
	set(x): w._invuln_until = x
var _nth_count: Dictionary:
	get: return w._nth_count
	set(x): w._nth_count = x
var _free_cast_used: bool:
	get: return w._free_cast_used
	set(x): w._free_cast_used = x
var _dead: bool:
	get: return w._dead
	set(x): w._dead = x
var _changing: bool:
	get: return w._changing
	set(x): w._changing = x
var _last_saved: Vector2:
	get: return w._last_saved
	set(x): w._last_saved = x
var _hud_dirty: bool:
	get: return w._hud_dirty
	set(x): w._hud_dirty = x
var _pickup_pending: Dictionary:
	get: return w._pickup_pending
	set(x): w._pickup_pending = x
var _interact: Dictionary:
	get: return w._interact
	set(x): w._interact = x

# Hàm của hệ thống khác
func _find_char(ch: String) -> Vector2i:
	return w._find_char(ch)

func _apply_zoom() -> void:
	w._apply_zoom()

func _move_step(delta: float) -> void:
	w.motor._move_step(delta)

func _hp_pct() -> int:
	return w.motor._hp_pct()

func _add_loot(data: Dictionary, animate: bool) -> void:
	w.loot._add_loot(data, animate)

func _load_player_map(arrive: String) -> void:
	_clear_world()
	_free_cast_used = false
	_nth_count.clear()
	_map_id = str(Game.player.get("map", "cong_do"))
	if _map_id.is_empty() or not Data.has_map_text(_map_id):
		# Thiếu data/maps/<id>.txt (thường do bản build không đóng gói file .txt: xem include_filter trong export_presets.cfg)
		push_error("Thiếu dữ liệu map '%s', tạm dùng cong_do" % _map_id)
		_map_id = "cong_do"
	_meta = Data.map_def(_map_id)
	Audio.music(_map_id, str(_meta.get("theme", "city")))
	_grid = MapGrid.build(Data.map_text(_map_id), _meta)
	_rows = _grid.size()
	_cols = (_grid[0] as Array).size() if _rows > 0 else 0
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
