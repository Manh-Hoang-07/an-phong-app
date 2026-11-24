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

## Sức chứa túi: khớp G.bagSize của web (40 + 10 mỗi lần mở rộng, tối đa 3 lần).
func bag_size() -> int:
	return Data.const_int("BAG_SIZE", 40) + 10 * clampi(int(player.get("bagPlus", 0)), 0, 3)

func has_player() -> bool:
	return not player.is_empty()

## `reset_vitals`: true khi vào game (lấy hp/mp server); false khi đồng bộ lại giữa chừng — như web, máu tức thời do client giữ.
func set_player(p: Variant, reset_vitals: bool = true) -> void:
	if typeof(p) == TYPE_DICTIONARY and OS.is_debug_build():
		print("[PLAYER] school=", p.get("school"), " skills=", JSON.stringify(p.get("skills")).left(200), " slots=", JSON.stringify(p.get("skillSlots")), " supers=", JSON.stringify(p.get("superUlts")), " mounts=", JSON.stringify(p.get("mounts")).left(200))
	# Chặn payload sai kiểu tu /api/me: gan Dictionary khong dung kieu vao bien
	# typed Dictionary gay EXC_BAD_ACCESS ngay khi goi .is_empty() tren iOS/arm64.
	if typeof(p) != TYPE_DICTIONARY:
		push_warning("set_player: payload khong phai Dictionary, bo qua")
		return
	var d: Dictionary = p
	player = d.duplicate(true)
	form_active = bool(d.get("formActive", false))
	# Server gửi hp/mp trong player; client tự giữ giá trị tức thời giữa các lần lưu
	if reset_vitals:
		hp = int(d.get("hp", 0))
		mp = int(d.get("mp", 0))
	recalc_stats()
	player_changed.emit(false)

## Ép an toàn sang Dictionary. Gán Variant sai kiểu vào biến typed Dictionary
## rồi gọi .is_empty() la nguon EXC_BAD_ACCESS tren iOS release build.
static func _as_dict(v: Variant) -> Dictionary:
	return v if typeof(v) == TYPE_DICTIONARY else {}

## Port đầy đủ GameData.calcStats của web (shared/logic/player.js): trang bị (phẩm chất, cường hóa, dòng phụ, nhiễm),
## Kỳ Nguyên, đường cong class, nội tại, thưởng bộ, ấn thức tỉnh khi biến hình. Không gồm dung hợp bóng ma.
func _inst_stats(it: Dictionary) -> Dictionary:
	var item_def: Dictionary = Data.item(str(it.get("id", "")))
	var st: Dictionary = _as_dict(item_def.get("stats", {}))
	var all := {}
	if st.is_empty(): return all
	var qm: Dictionary = _as_dict(Data.calc.get("QUALITY_MUL", {}))
	var qv: Variant = it.get("q", null)
	var q := int(qv) if qv != null else int(item_def.get("minQ", 1))
	var rv: Variant = it.get("roll", null)
	var roll := float(rv) if rv != null else 1.0
	var nh := float(Data.calc.get("NHIEM_STAT_MUL", 1.18)) if float(it.get("nhiem", 0)) > 0.0 else 1.0
	var mul := roll * float(qm.get(str(q), 1.0)) * (1.0 + 0.08 * float(it.get("plus", 0))) * nh
	for k in st.keys():
		if str(k) == "crit": all[k] = Formulas.r1(float(st[k]))
		else: all[k] = float(roundi(float(st[k]) * mul))
	var aff: Variant = it.get("aff", [])
	if typeof(aff) == TYPE_ARRAY:
		for a in aff:
			if typeof(a) == TYPE_ARRAY and (a as Array).size() >= 2:
				all[a[0]] = Formulas.r1(float(all.get(a[0], 0.0)) + float(a[1]))
	return all

## Thưởng bộ trang bị đang mặc ({mul, add} hoặc {}).
func _set_bonus() -> Dictionary:
	var counts := {}
	var sets: Array = Data.calc.get("SETS", [])
	if sets.is_empty(): return {}
	var lvl_per := maxi(1, int(Data.calc.get("SET_LEVELS", 10)))
	var equip: Dictionary = _as_dict(player.get("equip", {}))
	for slot in Data.calc.get("SLOTS", []):
		var it: Variant = equip.get(slot, null)
		if typeof(it) != TYPE_DICTIONARY: continue
		var d: Dictionary = Data.item(str((it as Dictionary).get("id", "")))
		if str(d.get("slot", "")).is_empty(): continue
		var lv := maxi(1, int(d.get("level", 1)))
		var idx := mini(sets.size() - 1, (lv - 1) / lvl_per)
		var sid := int((sets[idx] as Dictionary).get("id", 0))
		counts[sid] = int(counts.get(sid, 0)) + 1
	var best_id := -1
	var best_n := 0
	for sid in counts.keys():
		if int(counts[sid]) > best_n:
			best_n = int(counts[sid]); best_id = int(sid)
	if best_id < 0 or best_n < int(Data.calc.get("SET_TIER_LOW", 6)): return {}
	var bonus: Dictionary = _as_dict(_as_dict(Data.calc.get("SET_BONUS", {})).get(str(best_id), {}))
	var tier_key := "at10" if best_n >= int(Data.calc.get("SET_TIER_HIGH", 10)) else "at6"
	return _as_dict(bonus.get(tier_key, {}))

## Gom hiệu ứng (fx) của đồ đang mặc + Kỳ Nguyên đang bật + bộ 10 món, theo loại (port G.specialFx của web).
## Kỳ Nguyên rồi đến bộ đè lên trang bị nếu trùng loại, giống thứ tự bên web.
func special_fx() -> Dictionary:
	var out := {}
	var equip: Dictionary = _as_dict(player.get("equip", {}))
	for slot in Data.calc.get("SLOTS", []):
		var it: Variant = equip.get(slot, null)
		if typeof(it) != TYPE_DICTIONARY: continue
		var fx: Dictionary = _as_dict(Data.item(str((it as Dictionary).get("id", ""))).get("fx", {}))
		if fx.has("kind"): out[str(fx["kind"])] = fx
	var kn: Dictionary = _as_dict(player.get("kyNguyen", {}))
	var kact: Variant = kn.get("active", [])
	if typeof(kact) == TYPE_ARRAY:
		var kfx: Dictionary = _as_dict(Data.calc.get("KY_FX", {}))
		for kid in kact:
			var fx2: Dictionary = _as_dict(kfx.get(str(kid), {}))
			if fx2.has("kind"): out[str(fx2["kind"])] = fx2
	var fx3: Dictionary = _as_dict(_set_bonus().get("fx", {}))
	if fx3.has("kind"): out[str(fx3["kind"])] = fx3
	return out

## Nội tại class (Kiếm Tâm, Yếu Điểm, Thành Đồng...): chức nghiệp 2 giữ nội tại class nền, Toàn Năng có tất cả.
func has_passive(id: String) -> bool:
	var school := str(player.get("school", ""))
	if school.is_empty(): return false
	var sc: Dictionary = _as_dict(_as_dict(Data.raw.get("SCHOOLS", {})).get(school, {}))
	var base := str(sc.get("base", school))
	if base.is_empty(): base = school
	return base == id or base == "toan_nang"

## Tử Linh Dung Hợp: cộng thẳng chỉ số của cả bộ sưu tập bóng ma khi `player.fusion.until` còn hạn (port G.shadowFusion).
func fusion_active() -> bool:
	var fu: Dictionary = _as_dict(player.get("fusion", null))
	return not fu.is_empty() and float(fu.get("until", 0)) > Time.get_unix_time_from_system() * 1000.0

func _fusion_bonus() -> Dictionary:
	var out := {"hp": 0.0, "mp": 0.0, "sta": 0.0, "def": 0.0}
	if not fusion_active(): return out
	var souls: Variant = _as_dict(player.get("fusion", {})).get("souls", [])
	if typeof(souls) != TYPE_ARRAY: return out
	var mons: Dictionary = _as_dict(Data.calc.get("FUSION_MON", {}))
	var curve: Array = Data.calc.get("MON_CURVE", [])
	var fk: Dictionary = _as_dict(Data.calc.get("FUSION", {}))
	if curve.is_empty(): return out
	var owner_lv := maxi(1, int(player.get("level", 1)))
	for soul in souls:
		if typeof(soul) != TYPE_DICTIONARY: continue
		var sd: Dictionary = soul
		var mon: Dictionary = _as_dict(mons.get(str(sd.get("monster", "")), {}))
		if mon.is_empty(): continue
		var sstats: Dictionary = _as_dict(sd.get("stats", {}))
		var slv := 1
		if sd.get("lv", null) != null: slv = maxi(1, int(floorf(float(sd["lv"]))))
		else: slv = maxi(1, int(sstats.get("level", 1)))
		var base: Array = curve[clampi(int(mon.get("level", 1)) - 1, 0, curve.size() - 1)]
		var now_c: Array = curve[clampi(slv - 1, 0, curve.size() - 1)]
		var s_hp := maxf(1.0, roundf(float(mon.get("hp", 1)) * (float(now_c[0]) / float(base[0]))))
		var s_def := roundf(float(mon.get("def", 0)) * (float(now_c[2]) / float(base[2])))
		var c: Array = curve[clampi(mini(owner_lv, slv) - 1, 0, curve.size() - 1)]
		out["hp"] += s_hp * float(fk.get("hp", 1))
		out["mp"] += float(c[1]) * float(fk.get("mp", 1))
		out["sta"] += float(c[2]) * float(fk.get("sta", 1))
		out["def"] += s_def * float(fk.get("def", 1))
	for k in out.keys(): out[k] = roundf(float(out[k]))
	return out

func recalc_stats() -> void:
	if player.is_empty(): return
	var lv := maxi(1, int(player.get("level", 1)))
	var pts: Dictionary = _as_dict(player.get("points", {}))
	var school := str(player.get("school", ""))
	var schools: Dictionary = _as_dict(Data.raw.get("SCHOOLS", {}))
	var sc: Dictionary = _as_dict(schools.get(school, {}))
	var base_sc: Dictionary = _as_dict(schools.get(str(sc.get("base", "")), {}))
	var extra: Dictionary = _as_dict(_as_dict(Data.calc.get("SCHOOL_EXTRA", {})).get(school, {}))
	var curve: Dictionary = _as_dict(sc.get("curve", {}))
	if curve.is_empty(): curve = _as_dict(base_sc.get("curve", {}))
	if curve.is_empty(): curve = _as_dict(Data.calc.get("NOVICE_CURVE", {"hp": [100, 50], "mp": [40, 6], "atk": [8, 5], "def": [2, 2.5]}))
	var evo_mul := float(Data.calc.get("EVOLUTION_MUL", 1.3)) if bool(sc.get("evolved", false)) else 1.0
	var lvl := func(key: String) -> float:
		var a: Array = curve.get(key, [0, 0])
		return (float(a[0]) + float(a[1]) * float(lv - 1)) * evo_mul
	# Cộng chỉ số 10 ô trang bị + Kỳ Nguyên đang bật
	var eq := {"hp": 0.0, "mp": 0.0, "atk": 0.0, "def": 0.0, "crit": 0.0, "lifesteal": 0.0, "cdr": 0.0, "speed": 0.0, "boss": 0.0, "goldfind": 0.0, "expfind": 0.0, "sta": 0.0, "staRegen": 0.0, "skill": 0.0}
	var equip: Dictionary = _as_dict(player.get("equip", {}))
	var nhiem := 0
	for slot in Data.calc.get("SLOTS", []):
		var it: Variant = equip.get(slot, null)
		if typeof(it) != TYPE_DICTIONARY: continue
		nhiem += int((it as Dictionary).get("nhiem", 0))
		var s := _inst_stats(it)
		for k in s.keys(): eq[k] = float(eq.get(k, 0.0)) + float(s[k])
	var kn: Dictionary = _as_dict(player.get("kyNguyen", {}))
	var kdef: Dictionary = _as_dict(Data.calc.get("KY_NGUYEN", {}))
	var kact: Variant = kn.get("active", [])
	if typeof(kact) == TYPE_ARRAY:
		for kid in kact:
			var ks: Dictionary = _as_dict(kdef.get(str(kid), {}))
			for k in ks.keys(): eq[k] = float(eq.get(k, 0.0)) + float(ks[k])
	var vit := int(pts.get("vit", 0))
	var spi := int(pts.get("spi", 0))
	var str_ := int(pts.get("str", 0))
	var agi := int(pts.get("agi", 0))
	var hp_v: float = float(lvl.call("hp")) + float(vit) * 10.0 + float(eq["hp"])
	var mp_v: float = float(lvl.call("mp")) + float(spi) * 6.0 + float(eq["mp"])
	var atk_v: float = float(lvl.call("atk")) + float(str_) * 2.0 + float(eq["atk"])
	var def_v: float = float(lvl.call("def")) + floorf(float(vit) * 0.8) + float(eq["def"])
	var crit: float = 3.0 + float(agi) * 0.4 + float(eq["crit"])
	# Nội tại cốt truyện
	var perk_mul := {"hp": 1.0, "mp": 1.0, "atk": 1.0, "def": 1.0}
	var perk_add := {"crit": 0.0, "boss": 0.0, "cdr": 0.0, "goldfind": 0.0, "expfind": 0.0, "skill": 0.0, "speed": 0.0, "lifestealAdd": 0.0}
	var perks_def: Dictionary = _as_dict(Data.calc.get("PERKS", {}))
	var plist: Variant = player.get("perks", [])
	if typeof(plist) == TYPE_ARRAY:
		for pid in plist:
			var pk: Dictionary = _as_dict(perks_def.get(str(pid), {}))
			var pm: Dictionary = _as_dict(pk.get("mul", {}))
			var pa: Dictionary = _as_dict(pk.get("add", {}))
			for k in pm.keys(): perk_mul[k] = float(perk_mul.get(k, 1.0)) * float(pm[k])
			for k in pa.keys(): perk_add[k] = float(perk_add.get(k, 0.0)) + float(pa[k])
	var skill_mul := 1.0 + float(spi) / (float(spi) + 150.0)
	if float(eq["skill"]) != 0.0: skill_mul *= 1.0 + float(eq["skill"]) / 100.0
	if float(perk_add["skill"]) != 0.0: skill_mul *= 1.0 + float(perk_add["skill"]) / 100.0
	var cost_mul := 1.0
	var bonus: Dictionary = _as_dict(sc.get("bonus", {}))
	if not sc.is_empty():
		if bonus.has("critAdd"): crit += float(bonus["critAdd"])
		var sp := 0.0
		if bonus.get("skillPower", null) != null: sp = float(bonus["skillPower"])
		elif extra.get("skillPower", null) != null: sp = float(extra["skillPower"])
		if sp > 0.0: skill_mul *= sp
		if extra.get("skillCost", null) != null: cost_mul = float(extra["skillCost"])
	var sc_speed := float(bonus.get("speed", 1.0))
	hp_v *= float(perk_mul["hp"]); mp_v *= float(perk_mul["mp"]); atk_v *= float(perk_mul["atk"]); def_v *= float(perk_mul["def"])
	# Thưởng mặc đủ bộ
	var sb := _set_bonus()
	var set_add: Dictionary = _as_dict(sb.get("add", {}))
	var sm: Dictionary = _as_dict(sb.get("mul", {}))
	if sm.has("hp"): hp_v *= float(sm["hp"])
	if sm.has("mp"): mp_v *= float(sm["mp"])
	if sm.has("atk"): atk_v *= float(sm["atk"])
	if sm.has("def"): def_v *= float(sm["def"])
	# Ấn thức tỉnh đang bật
	var S: Dictionary = Data.STAMINA
	var sta_mul := float(S.get("maxMul", 1.3))
	if form_active:
		var aw: Dictionary = _as_dict(Data.awaken(maxi(1, Data.awaken_tier_of(player.get("formChoice", "")))))
		var m: Dictionary = _as_dict(aw.get("mul", {}))
		if not m.is_empty():
			hp_v *= float(m.get("hp", 1.0)); mp_v *= float(m.get("mp", 1.0)); atk_v *= float(m.get("atk", 1.0)); def_v *= float(m.get("def", 1.0))
			sta_mul = maxf(float(m.get("mp", 1.0)), sta_mul)
	crit += float(perk_add["crit"])
	for k in set_add.keys(): perk_add[k] = float(perk_add.get(k, 0.0)) + float(set_add[k])
	var speed_final := roundi(minf(290.0, minf(260.0, 190.0 + float(agi) * 2.0) * sc_speed + float(eq["speed"]) + float(perk_add["speed"])))
	if nhiem > 0: hp_v *= maxf(0.7, 1.0 - float(Data.calc.get("NHIEM_HP_PENALTY", 0.06)) * float(nhiem))
	var fu := _fusion_bonus()
	hp_v += float(fu["hp"]); mp_v += float(fu["mp"]); def_v += float(fu["def"])
	var max_hp := roundi(hp_v)
	var max_mp := roundi(mp_v)
	var atk := roundi(atk_v)
	var def := roundi(def_v)
	var max_sta := roundi((float(S.get("base", 100)) + float(S.get("perLevel", 2)) * float(lv - 1) + float(S.get("perAgi", 1)) * float(agi)) * sta_mul * float(bonus.get("sta", 1.0))) + int(eq["sta"]) + int(fu["sta"])
	var wtype := "tay"
	var wpn: Variant = equip.get("weapon", null)
	if typeof(wpn) == TYPE_DICTIONARY: wtype = str(Data.item(str((wpn as Dictionary).get("id", ""))).get("wtype", "tay"))
	stats = {
		"maxSta": max_sta, "maxHp": max_hp, "maxMp": max_mp, "atk": atk, "def": def,
		"crit": minf(60.0, Formulas.r1(crit)), "speed": float(speed_final), "skillMul": skill_mul, "costMul": cost_mul, "wtype": wtype, "nhiem": nhiem,
		"staRegen": maxf(0.0, Formulas.r1(float(eq["staRegen"]))),
		"lifesteal": minf(15.0, Formulas.r1(float(eq["lifesteal"]) + float(bonus.get("lifestealAdd", 0.0)) + float(perk_add["lifestealAdd"]))),
		"cdr": minf(30.0, Formulas.r1(float(eq["cdr"]) + float(perk_add["cdr"]) + float(bonus.get("cdrAdd", 0.0)))),
		"boss": minf(80.0, Formulas.r1(float(eq["boss"]) + float(perk_add["boss"]))),
		"goldfind": minf(100.0, Formulas.r1(float(eq["goldfind"]) + float(perk_add["goldfind"]))),
		"expfind": minf(60.0, Formulas.r1(float(eq["expfind"]) + float(perk_add["expfind"]))),
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
	# KHÔNG chép hp/mp từ bản vá: server chỉ biết giá trị lưu lần cuối (cũ hơn máu tức thời của client).
	# Web cũng vậy; hp/mp chỉ lấy từ server qua các sự kiện levelup / school / awaken / heal.
	# Điểm/đồ/cấp đổi thì tính lại chỉ số (panel Nhân vật không còn hiện toàn 0).
	var stat_keys := ["points", "equip", "level", "school", "formChoice", "formActive", "fusion", "perks", "kyNguyen"]
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
			hp = int(player.get("hp", hp))
			mp = int(player.get("mp", mp))
		_: pass

func on_events(events: Array) -> void:
	for ev in events:
		if typeof(ev) == TYPE_DICTIONARY: handle_event(ev)
