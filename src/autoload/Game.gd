extends Node
## Trạng thái nhân vật: chỉ đổi qua /api/action. Giữ rev, áp patch {set, del} đúng ngữ nghĩa web.
## Lệch rev thì tải lại cả nhân vật (/api/me) — Net.action đã lo, ở đây chỉ báo hiệu.

signal player_changed(quiet: bool)
signal rev_mismatch()
signal event_received(ev: Dictionary)

var player: Dictionary = {}
var rev: int = 0
var hp: int = 0
var mp: int = 0
var sta: int = -1
var stats: Dictionary = {}
var form_active := false     ## đang biến hình (Ấn thức tỉnh)
var sta_locked := false      ## kiệt sức: không đánh được tới khi hồi qua ngưỡng
var quest_hint := ""      ## tiến độ nhiệm vụ gần nhất từ sự kiện queststep (hiện ở HUD)

func has_player() -> bool:
	return not player.is_empty()

func set_player(p: Dictionary) -> void:
	player = p.duplicate(true)
	form_active = bool(p.get("formActive", false))
	# Server gửi hp/mp trong player; client tự giữ giá trị tức thời giữa các lần lưu
	if not p.has("hp"): hp = int(p.get("hp", 0))
	else: hp = int(p["hp"])
	if not p.has("mp"): mp = int(p.get("mp", 0))
	else: mp = int(p["mp"])
	recalc_stats()
	player_changed.emit(false)

## Web: App.stats = GameData.calcStats(player, {form}). Server KHÔNG gửi stats trong payload,
## nên client phải tự tính. Bản rút gọn: level curve của class + điểm潜力 + stats trang bị + crit.
## Đủ để các panel hiện số thật thay vì toàn 0 (các hệ số perks/set/awaken chỉ ảnh hưởng tinh chỉnh).
func recalc_stats() -> void:
	if player.is_empty(): return
	var lv := maxi(1, int(player.get("level", 1)))
	var pts: Dictionary = player.get("points", {})
	var school := str(player.get("school", ""))
	var schools: Dictionary = Data.raw.get("SCHOOLS", {})
	var sc: Dictionary = schools.get(school, {})
	if sc.is_empty():
		var base := str(sc.get("base", ""))
		sc = schools.get(base, {})
	var curve: Dictionary = sc.get("curve", {})
	if curve.is_empty():
		curve = {"hp": [100, 40], "mp": [30, 8], "atk": [8, 4], "def": [3, 2]}
	var evo_mul := 1.0
	if bool(sc.get("evolved", false)): evo_mul = 1.3
	var lvl := func(key: String) -> float:
		var a: Array = curve.get(key, [0, 0])
		return (float(a[0]) + float(a[1]) * float(lv - 1)) * evo_mul
	# Cộng stats từ 10 ô trang bị (mỗi món có thể có stats và quality mul; dùng stats đã lưu).
	var eq_add := {"hp": 0.0, "mp": 0.0, "atk": 0.0, "def": 0.0, "crit": 0.0, "speed": 0.0, "sta": 0.0}
	var equip: Dictionary = player.get("equip", {})
	for slot in equip.keys():
		var it: Dictionary = equip.get(slot, {})
		var st: Dictionary = it.get("stats", {})
		for k in st.keys():
			if eq_add.has(k): eq_add[k] += float(st[k])
	var vit := int(pts.get("vit", 0))
	var spi := int(pts.get("spi", 0))
	var str_ := int(pts.get("str", 0))
	var agi := int(pts.get("agi", 0))
	var max_hp := int(roundf(float(lvl.call("hp")) + float(vit) * 10.0 + float(eq_add["hp"])))
	var max_mp := int(roundf(float(lvl.call("mp")) + float(spi) * 6.0 + float(eq_add["mp"])))
	var atk := int(roundf(float(lvl.call("atk")) + float(str_) * 2.0 + float(eq_add["atk"])))
	var def := int(roundf(float(lvl.call("def")) + floorf(float(vit) * 0.8) + float(eq_add["def"])))
	var crit: float = 3.0 + float(agi) * 0.4 + float(eq_add["crit"])
	# Ấn thức tỉnh đang bật: nhân hệ số (máu, năng lượng, tấn công, phòng thủ; thể lực theo hệ số năng lượng)
	var sta_mul := 1.0
	if form_active:
		var aw: Dictionary = Data.awaken(maxi(1, Data.awaken_tier_of(player.get("formChoice", ""))))
		var m: Dictionary = aw.get("mul", {})
		if not m.is_empty():
			max_hp = int(roundf(float(max_hp) * float(m.get("hp", 1.0))))
			max_mp = int(roundf(float(max_mp) * float(m.get("mp", 1.0))))
			atk = int(roundf(float(atk) * float(m.get("atk", 1.0))))
			def = int(roundf(float(def) * float(m.get("def", 1.0))))
			sta_mul = float(m.get("mp", 1.0))
	var S: Dictionary = Data.STAMINA
	var max_sta := int(roundf((float(S.get("base", 100)) + float(S.get("perLevel", 2)) * float(lv - 1) + float(S.get("perAgi", 1)) * float(agi)) * sta_mul * float((sc.get("bonus", {}) as Dictionary).get("sta", 1.0)))) + int(eq_add["sta"])
	stats = {
		"maxSta": max_sta,
		"maxHp": max_hp, "maxMp": max_mp, "atk": atk, "def": def,
		"crit": crit, "speed": 100.0 + eq_add["speed"],
		"skillMul": 1.0 + float(spi) / float(spi + 150),
	}
	# Giữ hp/mp trong khoảng mới (web cũng clamp khi recalc).
	hp = clampi(hp, 0, max_hp)
	mp = clampi(mp, 0, max_mp)
	if sta < 0: sta = max_sta
	sta = clampi(sta, 0, max_sta)

func patch_is_quiet(patch: Dictionary) -> bool:
	# Giống App.patchIsQuiet: chỉ x/y/hp/mp/arrive đổi thì không cần vẽ lại giao diện
	if player.is_empty(): return false
	var del: Array = patch.get("del", [])
	if not del.is_empty(): return false
	var own := ["x", "y", "hp", "mp", "arrive"]
	var set_map: Dictionary = patch.get("set", {})
	for k in set_map.keys():
		if k in own: continue
		var a: Variant = player.get(k, null)
		var b: Variant = set_map[k]
		if typeof(a) == TYPE_DICTIONARY or typeof(a) == TYPE_ARRAY:
			if JSON.stringify(a) == JSON.stringify(b): continue
		elif a == b: continue
		return false
	return true

func apply_patch(patch: Dictionary, quiet: bool = false) -> void:
	if player.is_empty(): return
	var p := player.duplicate(true)
	for k in patch.get("del", []):
		p.erase(k)
	var set_map: Dictionary = patch.get("set", {})
	for k in set_map.keys():
		p[k] = set_map[k]
	var was_quiet: bool = quiet or patch_is_quiet(patch)
	player = p
	if p.has("hp"): hp = int(p["hp"])
	if p.has("mp"): mp = int(p["mp"])
	# Điểm/đồ/cấp đổi thì tính lại chỉ số (panel Nhân vật không còn hiện toàn 0).
	var stat_keys := ["points", "equip", "level", "school", "formChoice", "formActive"]
	for k in set_map.keys():
		if k in stat_keys:
			recalc_stats()
			break
	player_changed.emit(was_quiet)

## Bản vá đẩy qua WebSocket: cùng luật base/rev với HTTP (xem public/js/core/net.js pushPatch)
func apply_push_patch(m: Dictionary) -> void:
	if player.is_empty(): return
	if int(m.get("base", -1)) == rev and m.has("patch"):
		rev = int(m.get("rev", rev))
		apply_patch(m["patch"])
	elif int(m.get("base", -2)) != rev:
		rev_mismatch.emit()
	for ev in m.get("ev", []):
		if typeof(ev) == TYPE_DICTIONARY: handle_event(ev)

func handle_event(ev: Dictionary) -> void:
	event_received.emit(ev)
	var t := str(ev.get("t", ""))
	match t:
		"msg": pass
		"float": pass
		"levelup": pass
		"heal":
			hp = mini(hp + int(ev.get("hp", 0)), int(stats.get("maxHp", hp)))
			mp = mini(mp + int(ev.get("mp", 0)), int(stats.get("maxMp", mp)))
		"form":
			form_active = bool(ev.get("active", false))
			recalc_stats()
		"school", "awaken":
			if ev.has("hp"): hp = int(ev["hp"])
			if ev.has("mp"): mp = int(ev["mp"])
		_: pass

func on_events(events: Array) -> void:
	for ev in events:
		if typeof(ev) == TYPE_DICTIONARY: handle_event(ev)
