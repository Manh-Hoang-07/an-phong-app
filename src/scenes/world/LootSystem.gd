extends "res://src/scenes/world/WorldPart.gd"
## Tương tác trên bản đồ: NPC, cổng, đồ rơi, dịch chuyển, nhặt đồ.
## Hệ thống của World (w = World). Trạng thái riêng khai báo ngay dưới; trạng thái dùng chung đọc qua thuộc tính chuyển tiếp.

# Trạng thái dùng chung (lưu ở World)
var _mob_layer: Node2D:
	get: return w._mob_layer if is_instance_valid(w._mob_layer) else null
	set(x): w._mob_layer = x
var _player: Node2D:
	get: return w._player if is_instance_valid(w._player) else null
	set(x): w._player = x
var _hud_node: Node:
	get: return w._hud_node if is_instance_valid(w._hud_node) else null
	set(x): w._hud_node = x
var _entities: Node2D:
	get: return w._entities if is_instance_valid(w._entities) else null
	set(x): w._entities = x
var _loot_layer: Node2D:
	get: return w._loot_layer if is_instance_valid(w._loot_layer) else null
	set(x): w._loot_layer = x
var _fade: ColorRect:
	get: return w._fade if is_instance_valid(w._fade) else null
	set(x): w._fade = x
var _fxs: Node2D:
	get: return w._fxs if is_instance_valid(w._fxs) else null
	set(x): w._fxs = x
var _loots: Dictionary:
	get: return w._loots
	set(x): w._loots = x
var _map_id: String:
	get: return w._map_id
	set(x): w._map_id = x
var _meta: Dictionary:
	get: return w._meta
	set(x): w._meta = x
var _cols: int:
	get: return w._cols
	set(x): w._cols = x
var _rows: int:
	get: return w._rows
	set(x): w._rows = x
var _move_dir: Vector2:
	get: return w._move_dir
	set(x): w._move_dir = x
var _dead: bool:
	get: return w._dead
	set(x): w._dead = x
var _changing: bool:
	get: return w._changing
	set(x): w._changing = x
var _pickup_pending: Dictionary:
	get: return w._pickup_pending
	set(x): w._pickup_pending = x
var _pickup_lid: String:
	get: return w._pickup_lid
	set(x): w._pickup_lid = x
var _interact: Dictionary:
	get: return w._interact
	set(x): w._interact = x
var _target_t: float:
	get: return w._target_t
	set(x): w._target_t = x
var _interact_mark: Node2D:
	get: return w._interact_mark if is_instance_valid(w._interact_mark) else null
	set(x): w._interact_mark = x
var _loot_store: Dictionary:
	get: return w._loot_store
	set(x): w._loot_store = x

# Hàm của hệ thống khác
func _ground_y(x: float, foot_y: float) -> float:
	return w.map._ground_y(x, foot_y)

func _pets_payload() -> Dictionary:
	return w.pets._pets_payload()

func _flush_kills() -> void:
	w.life._flush_kills()

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

func _hex(s: String, fallback: Color) -> Color:
	if s.is_empty(): return fallback
	return Color.from_string(s, fallback)

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
