extends "res://src/scenes/world/WorldPart.gd"
## Thú đồng hành / linh thú / bóng: chỉ số, chia sát thương, đồng bộ lên server.
## Hệ thống của World (w = World). Trạng thái riêng khai báo ngay dưới; trạng thái dùng chung đọc qua thuộc tính chuyển tiếp.

# Trạng thái riêng
var _pet_dead_until: Dictionary = {}

# Trạng thái dùng chung (lưu ở World)
var _fx: Node2D:
	get: return w._fx if is_instance_valid(w._fx) else null
	set(x): w._fx = x
var _player: Node2D:
	get: return w._player if is_instance_valid(w._player) else null
	set(x): w._player = x
var _hud_node: Node:
	get: return w._hud_node if is_instance_valid(w._hud_node) else null
	set(x): w._hud_node = x
var _assist: Node:
	get: return w._assist if is_instance_valid(w._assist) else null
	set(x): w._assist = x
var _last_hurt: int:
	get: return w._last_hurt
	set(x): w._last_hurt = x
var _hud_dirty: bool:
	get: return w._hud_dirty
	set(x): w._hud_dirty = x

## Đồng bộ thú đồng hành / linh thú / bóng ma với dữ liệu server (xem src/world/Assist.gd).
func _sync_pet() -> void:
	if _assist != null: _assist.sync()

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
