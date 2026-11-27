extends "res://src/scenes/world/WorldPart.gd"
## Bình nhanh: chọn bình, hồi chiêu, dùng bình.
## Hệ thống của World (w = World). Trạng thái riêng khai báo ngay dưới; trạng thái dùng chung đọc qua thuộc tính chuyển tiếp.

# Trạng thái riêng
var _potion_ids := {"hp": "", "mp": ""}
var _potion_cd_until := 0
## Chọn bình để uống như web (usePotion): mọi bình cùng hệ xếp theo lượng hồi tăng dần; lấy bình nhỏ nhất đủ lấp phần đang thiếu
## (đỡ phí bình xịn), không đủ thì dùng bình mạnh nhất đang có. Bình phải đủ cấp; thuốc chữa nhiễm đỏ chỉ là phương án cuối.
## Cache theo túi/cấp/máu: hàm này quét toàn bộ Data.ITEMS (~434 mục) và từng ô túi, mà _refresh_hud gọi 2 lần mỗi lần dirty.
var _potion_pick_cache: Dictionary = {}

# Trạng thái dùng chung (lưu ở World)
var _player: Node2D:
	get: return w._player if is_instance_valid(w._player) else null
	set(x): w._player = x
var _hud_node: Node:
	get: return w._hud_node if is_instance_valid(w._hud_node) else null
	set(x): w._hud_node = x
var _fxs: Node2D:
	get: return w._fxs if is_instance_valid(w._fxs) else null
	set(x): w._fxs = x
var _dead: bool:
	get: return w._dead
	set(x): w._dead = x
var _changing: bool:
	get: return w._changing
	set(x): w._changing = x

# Hàm của hệ thống khác
func _refresh_hud() -> void:
	w._refresh_hud()

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
