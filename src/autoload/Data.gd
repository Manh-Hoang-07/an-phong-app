extends Node
## Nạp data/gamedata.json đóng sẵn trong app; so hash với /api/version (dataHash).
## Expose SKILLS / ITEMS / MAPS (và SCHOOLS / MONSTERS / NPCS) cho phần còn lại.

signal loaded(ok: bool, message: String)

const DATA_PATH := "res://data/gamedata.json"

var raw: Dictionary = {}
var SKILLS: Dictionary = {}
var ITEMS: Dictionary = {}
var MAPS: Dictionary = {}
var SCHOOLS: Dictionary = {}
var MONSTERS: Dictionary = {}
var NPCS: Dictionary = {}
var looks: Dictionary = {}       ## data/map_looks.json: diện mạo từng map + bộ nền + biến thể ô đất
var art_meta: Dictionary = {}    ## assets/art/meta.json: kích thước / hệ số HD của hình web xuất ra
var AWAKENS: Array = []          ## Ấn thức tỉnh 1-5 (biến hình)
var EVOLUTION_SCHOOLS: Array = []
var STAMINA: Dictionary = {}
var QUESTS: Array = []
var SIDE_QUESTS: Array = []
var _quest_idx: Dictionary = {}
var hash_local: String = ""
var hash_server: String = ""
var version_info: Dictionary = {}

func _ready() -> void:
	load_local()

func load_local() -> bool:
	if not FileAccess.file_exists(DATA_PATH):
		loaded.emit(false, "Thiếu data/gamedata.json — chạy node server/tools/export-gamedata.js")
		return false
	var f := FileAccess.open(DATA_PATH, FileAccess.READ)
	if f == null:
		loaded.emit(false, "Không mở được gamedata.json")
		return false
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		loaded.emit(false, "gamedata.json không đúng định dạng")
		return false
	raw = parsed
	SKILLS = _section("SKILLS")
	ITEMS = _section("ITEMS")
	MAPS = _section("MAPS")
	SCHOOLS = _section("SCHOOLS")
	MONSTERS = _section("MONSTERS")
	NPCS = _section("NPCS")
	_fix_icons()
	hash_local = str(raw.get("dataHash", ""))
	_load_quests()
	_load_looks()
	loaded.emit(true, "")
	return true

## Emoji trong dữ liệu -> token "@họ" (vẽ bằng GlyphArt) để không phải nạp font emoji hệ thống (crash iOS).
func _fix_icons() -> void:
	var ga = load("res://src/ui/GlyphArt.gd")
	for dict in [SKILLS, SCHOOLS]:
		for k in dict.keys():
			var d: Variant = dict[k]
			if typeof(d) == TYPE_DICTIONARY and (d as Dictionary).has("icon"):
				(d as Dictionary)["icon"] = ga.token_of(str((d as Dictionary)["icon"]))

func _section(key: String) -> Dictionary:
	var v: Variant = raw.get(key, {})
	return v if typeof(v) == TYPE_DICTIONARY else {}

## So sánh hash dữ liệu đóng sẵn với server. Trả true nếu khớp (hoặc server chưa có /api/version).
func check_version() -> bool:
	version_info = await Net.version()
	if version_info.is_empty() or version_info.get("error") != null:
		# Server cũ chưa có /api/version: vẫn cho chơi, ghi nhận là không kiểm được
		return true
	hash_server = str(version_info.get("dataHash", ""))
	if hash_server.is_empty(): return true
	return hash_server == hash_local

func skill(id: String) -> Dictionary:
	var v: Variant = SKILLS.get(id, {})
	return v if typeof(v) == TYPE_DICTIONARY else {}

## Thông số thực tế của kỹ năng ở một cấp — bản sao shared/logic/skills.js skillAt() của server
## (mốc m5/m10, +5% sát thương mỗi cấp, MP +4% mỗi cấp, hồi chiêu ×0.85 ở cấp 10). Tuyệt phẩm: chỉ số cố định.
func skill_at(id: String, lv: int) -> Dictionary:
	var base := skill(id)
	if base.is_empty(): return {}
	lv = clampi(lv, 1, 10)
	var s: Dictionary = base.duplicate()
	if bool(base.get("superUlt", false)):
		s["lv"] = lv
		return s
	if lv >= 5 and typeof(base.get("m5", null)) == TYPE_DICTIONARY: s.merge(base["m5"], true)
	if lv >= 10 and typeof(base.get("m10", null)) == TYPE_DICTIONARY: s.merge(base["m10"], true)
	var mul := 1.0 + 0.05 * float(lv - 1)
	for k in ["power", "after", "finisher"]:
		if s.has(k) and float(s[k]) != 0.0: s[k] = float(s[k]) * mul
	if s.has("heal") and float(s["heal"]) != 0.0: s["heal"] = minf(0.9, float(s["heal"]) * (1.0 + 0.03 * float(lv - 1)))
	if s.has("atkBuff") and float(s["atkBuff"]) != 0.0:
		s["atkBuff"] = maxf(-1.0, float(s["atkBuff"]) * (1.0 + 0.05 * float(lv - 1)))
	s["mp"] = roundi(float(base.get("mp", 0)) * (1.0 + 0.04 * float(lv - 1)))
	if lv >= 10 and s.has("cd"): s["cd"] = float(s["cd"]) * 0.85
	s["lv"] = lv
	return s

## Cấp đã học của một kỹ năng (0 nếu chưa học). Kỹ năng không có trong danh sách học (trang bị, tuyệt phẩm) trả 1.
func skill_lv(pl: Dictionary, id: String) -> int:
	var learned: Variant = pl.get("skills", {})
	if typeof(learned) == TYPE_DICTIONARY and (learned as Dictionary).has(id):
		var v: Variant = (learned as Dictionary)[id]
		return int((v as Dictionary).get("lv", 1)) if typeof(v) == TYPE_DICTIONARY else int(v)
	# Kỹ năng do trang bị cấp: cấp mượn = cấp nhân vật / 8 (cấp 12 → 1, 40 → 5, 80 → 10) — như G.gearSkillLevel của web
	var eq: Variant = pl.get("equip", {})
	if typeof(eq) == TYPE_DICTIONARY:
		for slot in (eq as Dictionary).keys():
			var it: Variant = (eq as Dictionary)[slot]
			if typeof(it) != TYPE_DICTIONARY: continue
			if str(item(str((it as Dictionary).get("id", ""))).get("grantsSkill", "")) == id:
				return clampi(int(floor(float(int(pl.get("level", 1))) / 8.0)), 1, 10)
	return 1

## Thông số dùng khi bấm kỹ năng: theo cấp đã học, MP nhân hệ số tiêu hao (giống web). Hồi chiêu giữ nguyên số thực.
func skill_eff(pl: Dictionary, id: String) -> Dictionary:
	var d := skill_at(id, skill_lv(pl, id))
	if d.is_empty(): return d
	var st: Dictionary = Game.stats if not Game.stats.is_empty() else {}
	d["mp"] = roundi(float(d.get("mp", 0)) * float(st.get("costMul", 1.0)))
	return d

## Số giây hồi chiêu hiển thị: làm tròn 0,1 và bỏ ".0" thừa.
func fmt_cd(cd: float) -> String:
	var r := snappedf(cd, 0.1)
	return str(int(r)) if is_equal_approx(r, roundf(r)) else "%.1f" % r

## Thời gian hồi THỰC TẾ sau khi trừ giảm hồi chiêu (CDR) — cùng công thức World._cast_skill.
func cd_actual(cd: float) -> float:
	var cdr := float(Game.stats.get("cdr", 0.0)) if not Game.stats.is_empty() else 0.0
	return maxf(0.0, cd * (1.0 - cdr / 100.0))

## Chuỗi hiển thị: số thực tế làm chính, số gốc trong ngoặc khi CDR làm đổi số.
func cd_text(cd: float) -> String:
	var real := cd_actual(cd)
	var s := fmt_cd(real)
	if not is_equal_approx(real, cd): s += "s (gốc %ss)" % fmt_cd(cd)
	return s

func item(id: String) -> Dictionary:
	var v: Variant = ITEMS.get(id, {})
	return v if typeof(v) == TYPE_DICTIONARY else {}

func map_def(id: String) -> Dictionary:
	var v: Variant = MAPS.get(id, {})
	return v if typeof(v) == TYPE_DICTIONARY else {}

func school(id: String) -> Dictionary:
	var v: Variant = SCHOOLS.get(id, {})
	return v if typeof(v) == TYPE_DICTIONARY else {}

func npc(id: String) -> Dictionary:
	var v: Variant = raw.get("NPCS", {}).get(id, {})
	return v if typeof(v) == TYPE_DICTIONARY else {}

# ---------------------------------------------------------------- Cửa hàng
# Bản sao các hàm trong shared/logic/shop.js của web/server để app bày đúng hàng.
const SHOP_SLOT_ORDER := ["weapon", "mu", "ao", "gang_tay", "dai_lung", "quan", "giay", "nhan", "day_chuyen", "ngoc_boi"]
const SHOP_TIER_OF := {"nho": 1, "vua": 2, "lon": 3, "dac": 4, "than_thoai": 5, "trung": 2, "cao": 3}
const SHOP_TIER_CAP := {1: 1, 2: 2, 3: 3, 4: 4, 5: 4, 6: 5, 7: 5}

var _shop_gear_cache: Array = []
var _shop_book_cache: Array = []

func base_school(id: String) -> String:
	var sd := school(id)
	var b := str(sd.get("base", ""))
	return b if not b.is_empty() else id

func set_of_item(d: Dictionary) -> int:
	if str(d.get("slot", "")).is_empty(): return 0
	var lv := maxi(1, int(d.get("level", 1)))
	return mini(9, (lv - 1) / 10)

func _shop_gear() -> Array:
	if _shop_gear_cache.is_empty():
		var ids: Array = []
		for id in ITEMS.keys():
			var d: Dictionary = ITEMS[id]
			if not str(d.get("slot", "")).is_empty() and int(d.get("price", 0)) > 0 and not d.has("desc"):
				ids.append(str(id))
		ids.sort_custom(func(a, b):
			var sa := set_of_item(ITEMS[a]); var sb := set_of_item(ITEMS[b])
			if sa != sb: return sa < sb
			var oa := SHOP_SLOT_ORDER.find(str(ITEMS[a].get("slot", ""))); var ob := SHOP_SLOT_ORDER.find(str(ITEMS[b].get("slot", "")))
			if oa != ob: return oa < ob
			return int(ITEMS[a].get("level", 1)) < int(ITEMS[b].get("level", 1)))
		_shop_gear_cache = ids
	return _shop_gear_cache.duplicate()

func _book_line(id: String) -> String:
	var sk := skill(str(ITEMS[id].get("skill", "")))
	if sk.is_empty(): return ""
	return base_school(str(sk.get("evolutionKey", sk.get("school", ""))))

func _shop_book_ids() -> Array:
	if _shop_book_cache.is_empty():
		var ids: Array = []
		for id in ITEMS.keys():
			if str(ITEMS[id].get("kind", "")) == "skill_book": ids.append(str(id))
		ids.sort_custom(func(a, b):
			var la := _book_line(a); var lb := _book_line(b)
			if la != lb: return la < lb
			return int(ITEMS[a].get("level", 0)) < int(ITEMS[b].get("level", 0)))
		_shop_book_cache = ids
	return _shop_book_cache.duplicate()

func available_skills(pl: Dictionary) -> Array:
	var sch := str(pl.get("school", ""))
	if sch.is_empty(): return []
	var ids: Array = []
	var tn := base_school(sch) == "toan_nang"
	for id in SKILLS.keys():
		var s: Dictionary = SKILLS[id]
		if bool(s.get("ult", false)):
			if not tn and not bool(s.get("ultAny", false)):
				var list: Array = s.get("ultSchools", [s.get("school", "")]) if s.has("ultSchools") else [str(s.get("school", ""))]
				var schools: Array = [base_school(sch), sch]
				var ok := false
				for x in schools:
					if list.has(x): ok = true; break
				if not ok: continue
		elif tn:
			pass
		elif str(s.get("type", "")) == "shadow_toggle" and sch != "trieu_hoi_su" and sch != "tu_linh_thuat_su":
			continue
		elif s.has("evolutionKey"):
			if str(s.get("evolutionKey", "")) != sch: continue
		elif str(s.get("school", "")) != sch:
			continue
		ids.append(str(id))
	return ids

func _shop_item_tier(id: String) -> int:
	if id == "da_cuong_hoa": return 1
	var parts := id.split("_")
	if parts.size() > 0:
		var t := str(parts[parts.size() - 1])
		return int(SHOP_TIER_OF.get(t, 0))
	return 0

func _shop_cap_by_village(pl: Dictionary, list: Array) -> Array:
	var md := map_def(str(pl.get("map", "")))
	var v: Variant = md.get("village", null)
	if typeof(v) != TYPE_DICTIONARY: return list
	var cap := int((v as Dictionary).get("cap", 0))
	var n := int((v as Dictionary).get("n", 0))
	var out: Array = []
	for id in list:
		var d := item(str(id))
		if not str(d.get("slot", "")).is_empty():
			if int(d.get("level", 1)) <= cap: out.append(id)
		else:
			var t := _shop_item_tier(str(id))
			if t == 0 or t <= int(SHOP_TIER_CAP.get(n, 0)): out.append(id)
	return out

## Danh sách hàng xu của một NPC — khớp G.shopItems(player, npcId) của web.
func shop_items(pl: Dictionary, npc_id: String) -> Array:
	var nd := npc(npc_id)
	if nd.is_empty() or not nd.has("shop"): return []
	var base: Array = nd.get("shop", [])
	var list: Array = []
	if bool(nd.get("gearShop", false)):
		list = _shop_gear()
		for id in base:
			if not list.has(str(id)): list.append(str(id))
	else:
		list = base.duplicate()
	var add := func(ids: Array) -> void:
		for id in ids:
			if not item(str(id)).is_empty() and not list.has(str(id)): list.append(str(id))
	var kind := str(nd.get("shopKind", ""))
	if kind == "herb" and side_done(pl, "p5-2"): add.call(["thuoc_nhiem_do"])
	if kind == "gear" and side_done(pl, "p2-1"): add.call(["binh_mau_vua", "binh_nl_vua"])
	if kind == "gear" and side_done(pl, "p2-2"): add.call(["da_cuong_hoa_cao"])
	if kind == "gear":
		var pet_ids: Array = []
		for id in ITEMS.keys():
			if str(ITEMS[id].get("kind", "")) == "pet_gear": pet_ids.append(str(id))
		add.call(pet_ids)
		if not str(pl.get("school", "")).is_empty():
			var mine := available_skills(pl)
			var own: Array = []
			var rest: Array = []
			for id in _shop_book_ids():
				var skid := str(item(str(id)).get("skill", ""))
				if mine.has(skid): own.append(str(id))
				else: rest.append(str(id))
			add.call(own + rest)
	var out: Array = []
	for id in _shop_cap_by_village(pl, list):
		if int(item(str(id)).get("priceNgoc", 0)) <= 0: out.append(id)
	return out

## Giá mua xu sau giảm giá khách quen — khớp G.shopPrice.
func shop_price(pl: Dictionary, d: Dictionary, qty: int = 1) -> int:
	return maxi(1, roundi(float(d.get("price", 0)) * float(qty) * (1.0 - float(pl.get("shopDiscount", 0)))))

func monster(id: String) -> Dictionary:
	var v: Variant = MONSTERS.get(id, {})
	return v if typeof(v) == TYPE_DICTIONARY else {}

const MAP_DIR := "res://data/maps/"
var _map_cache: Dictionary = {}

## Bản đồ ký tự của một map: đọc data/maps/<id>.txt (mỗi map một file, giống shared/maps của web).
## Thiếu file thì rơi về MAP_TEXTS trong gamedata.json. Trả "" nếu không có.
func map_text(id: String) -> String:
	if _map_cache.has(id): return _map_cache[id]
	var text := ""
	var path := MAP_DIR + id + ".txt"
	if FileAccess.file_exists(path):
		var f := FileAccess.open(path, FileAccess.READ)
		if f: text = f.get_as_text(); f.close()
	if text.is_empty():
		text = str(raw.get("MAP_TEXTS", {}).get(id, ""))
	_map_cache[id] = text
	return text

func has_map_text(id: String) -> bool:
	return not map_text(id).is_empty()

func const_int(key: String, fallback: int = 0) -> int:
	var v: Variant = raw.get("CONSTANTS", {}).get(key, fallback)
	return int(v) if typeof(v) == TYPE_INT or typeof(v) == TYPE_FLOAT else fallback

func const_arr(key: String) -> Array:
	var v: Variant = raw.get("CONSTANTS", {}).get(key, [])
	return v if typeof(v) == TYPE_ARRAY else []

## Nhiệm vụ chính + phụ tuyến (data/quests.json, xuất bằng tools/export_quests.js).
func _load_quests() -> void:
	QUESTS = []; SIDE_QUESTS = []; _quest_idx = {}
	var path := "res://data/quests.json"
	if not FileAccess.file_exists(path): return
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null: return
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parsed) != TYPE_DICTIONARY: return
	QUESTS = (parsed as Dictionary).get("QUESTS", [])
	SIDE_QUESTS = (parsed as Dictionary).get("SIDE", [])
	AWAKENS = (parsed as Dictionary).get("AWAKENS", [])
	EVOLUTION_SCHOOLS = (parsed as Dictionary).get("EVOLUTION_SCHOOLS", [])
	STAMINA = (parsed as Dictionary).get("STAMINA", {})
	for i in range(QUESTS.size()): _quest_idx[str((QUESTS[i] as Dictionary).get("id", ""))] = i

func quest_by_id(id: String) -> Dictionary:
	if _quest_idx.has(id): return QUESTS[int(_quest_idx[id])]
	for q in SIDE_QUESTS:
		if str((q as Dictionary).get("id", "")) == id: return q
	return {}

## Nhiệm vụ chính đã hoàn thành chưa (player.quest.step là chỉ số nhiệm vụ đang làm) — giống G.questDone của server.
func quest_done(player: Dictionary, id: String) -> bool:
	if not _quest_idx.has(id): return false
	var q: Dictionary = player.get("quest", {}) if typeof(player.get("quest", {})) == TYPE_DICTIONARY else {}
	return int(q.get("step", 0)) > int(_quest_idx[id])

func quest_current(player: Dictionary) -> Dictionary:
	var q: Dictionary = player.get("quest", {}) if typeof(player.get("quest", {})) == TYPE_DICTIONARY else {}
	var i := int(q.get("step", 0))
	return QUESTS[i] if i >= 0 and i < QUESTS.size() else {}

## Dòng mục tiêu [[mô tả, đã xong]] của một nhiệm vụ (chính hoặc phụ) — giống questLines / sideLines của web.
func quest_obj_lines(player: Dictionary, obj: Dictionary, pr: Dictionary) -> Array:
	var out: Array = []
	var kills: Variant = pr.get("kill", {})
	for m in (obj.get("kill", {}) as Dictionary).keys():
		var need := int(obj["kill"][m])
		var c: int = int((kills as Dictionary).get(m, 0)) if typeof(kills) == TYPE_DICTIONARY else 0
		out.append(["%s: %d/%d" % [str(monster(str(m)).get("name", m)), mini(c, need), need], c >= need])
	for it in (obj.get("collect", {}) as Dictionary).keys():
		var need2 := int(obj["collect"][it])
		var have := 0
		for e in player.get("bag", []):
			if typeof(e) == TYPE_DICTIONARY and str(e.get("id", "")) == str(it): have += int(e.get("n", e.get("qty", 1)))
		out.append(["%s: %d/%d" % [str(item(str(it)).get("name", it)), mini(have, need2), need2], have >= need2])
	var visit: Variant = pr.get("visit", {})
	for n in obj.get("visit", []):
		var done: bool = typeof(visit) == TYPE_DICTIONARY and bool((visit as Dictionary).get(n, false))
		out.append(["Gặp %s" % str(npc(str(n)).get("name", n)), done])
	if obj.has("level"):
		var lv := int(player.get("level", 1))
		out.append(["Đạt cấp %d (%d/%d)" % [int(obj["level"]), mini(lv, int(obj["level"])), int(obj["level"])], lv >= int(obj["level"])])
	if obj.has("school"):
		out.append(["Thức tỉnh class", not str(player.get("school", "")).is_empty()])
	return out

func quest_ready(player: Dictionary) -> bool:
	var q: Dictionary = player.get("quest", {}) if typeof(player.get("quest", {})) == TYPE_DICTIONARY else {}
	if str(q.get("state", "")) != "active": return false
	var cur := quest_current(player)
	if cur.is_empty(): return false
	for l in quest_obj_lines(player, cur.get("obj", {}), q.get("progress", {}) if typeof(q.get("progress", {})) == TYPE_DICTIONARY else {}):
		if not bool(l[1]): return false
	return true

func side_state(player: Dictionary) -> Dictionary:
	var s: Variant = player.get("side", {})
	return s if typeof(s) == TYPE_DICTIONARY else {}

func side_done(player: Dictionary, id: String) -> bool:
	return id in (side_state(player).get("done", []) as Array)

func side_active(player: Dictionary, id: String) -> bool:
	var a: Variant = side_state(player).get("active", {})
	return typeof(a) == TYPE_DICTIONARY and (a as Dictionary).has(id)

func side_ready(player: Dictionary, id: String) -> bool:
	if not side_active(player, id): return false
	var q := quest_by_id(id)
	var pr: Variant = (side_state(player)["active"][id] as Dictionary).get("progress", {})
	for l in quest_obj_lines(player, q.get("obj", {}), pr if typeof(pr) == TYPE_DICTIONARY else {}):
		if not bool(l[1]): return false
	return true

func side_available(player: Dictionary, q: Dictionary) -> bool:
	var id := str(q.get("id", ""))
	if id.is_empty() or side_done(player, id) or side_active(player, id): return false
	for r in (q.get("req", []) if typeof(q.get("req", [])) == TYPE_ARRAY else []):
		var rs := str(r)
		var ok: bool = quest_done(player, rs) if _quest_idx.has(rs) else side_done(player, rs)
		if not ok: return false
	return true

## NPC có đang xuất hiện ở map này với tiến độ cốt truyện hiện tại không (giống G.npcHere của web).
func npc_here(player: Dictionary, map_id: String, npc_id: String) -> bool:
	var nd := npc(npc_id)
	if nd.is_empty(): return false
	var ap: Variant = nd.get("appear", null)
	if typeof(ap) != TYPE_DICTIONARY: return true
	var ranges: Variant = (ap as Dictionary).get(map_id, null)
	if typeof(ranges) != TYPE_ARRAY: return false
	var q: Dictionary = player.get("quest", {}) if typeof(player.get("quest", {})) == TYPE_DICTIONARY else {}
	var step := int(q.get("step", 0))
	for r in ranges:
		if typeof(r) != TYPE_ARRAY or (r as Array).size() < 2: continue
		var a: int = _quest_edge(r[0], false)
		var b: int = _quest_edge(r[1], true)
		if step >= a and step <= b: return true
	return false

## Có NPC với role/shop cụ thể đang hiện ở map này không (khớp G.npcByRole / shopHere của web).
func npc_role_here(player: Dictionary, map_id: String, role: String, require_shop: bool = false) -> bool:
	var npcs: Variant = map_def(map_id).get("npcs", {})
	if typeof(npcs) != TYPE_DICTIONARY: return false
	for key in (npcs as Dictionary).keys():
		var nid := str((npcs as Dictionary)[key])
		if not npc_here(player, map_id, nid): continue
		var nd := npc(nid)
		if str(nd.get("role", "")) != role: continue
		if require_shop and not nd.has("shop"): continue
		return true
	return false

func shop_here(player: Dictionary, map_id: String) -> bool:
	return npc_role_here(player, map_id, "shop", true)

## Có Dược sư (NPC role=shop, shopKind=herb) đang hiện ở map này không.
func herb_shop_here(player: Dictionary, map_id: String) -> bool:
	var npcs: Variant = map_def(map_id).get("npcs", {})
	if typeof(npcs) != TYPE_DICTIONARY: return false
	for key in (npcs as Dictionary).keys():
		var nid := str((npcs as Dictionary)[key])
		if not npc_here(player, map_id, nid): continue
		var nd := npc(nid)
		if str(nd.get("role", "")) == "shop" and str(nd.get("shopKind", "")) == "herb": return true
	return false

# Nội tại class (khớp shared/data/classes/passives.js của web).
const PASSIVES := {
	"kiem_si": {"icon": "@heart", "name": "Kiếm Tâm", "desc": "Mỗi lần đánh thường trúng quái hồi 0,5% máu tối đa."},
	"cung_thu": {"icon": "@target", "name": "Yếu Điểm", "desc": "Đòn chí mạng gây 180% sát thương thay vì 160%."},
	"phap_su": {"icon": "@mana", "name": "Dòng Chảy", "desc": "Hồi 0,5% năng lượng tối đa mỗi giây ngay cả khi đang chiến đấu; ngoài chiến đấu hồi gấp đôi."},
	"sat_thu": {"icon": "@shadow", "name": "Bóng Tối", "desc": "Chí mạng đầu tiên sau kỹ năng lướt gây 250% sát thương."},
	"tanker": {"icon": "@shield", "name": "Thành Đồng", "desc": "Giảm thêm 10% sát thương nhận vào khi máu dưới 50%."},
	"tri_lieu_su": {"icon": "@heal", "name": "Sinh Lực", "desc": "Kỹ năng hồi máu hồi thêm 20% lượng hồi."},
	"trieu_hoi_su": {"icon": "@pet", "name": "Liên Kết Linh Thể", "desc": "Thực thể được triệu hồi gây thêm 10% sát thương."},
	"tu_linh_thuat_su": {"icon": "@skull", "name": "Thu Hồn", "desc": "Quái thường và tinh anh do bạn kết liễu được lưu thành bóng ma. Bộ sưu tập tối đa 20 bóng."},
}

func passives_of(pl: Dictionary) -> Array:
	var school := str(pl.get("school", ""))
	if school.is_empty(): return []
	var base := base_school(school)
	if base == "toan_nang": return PASSIVES.keys()
	if PASSIVES.has(school): return [school]
	if PASSIVES.has(base): return [base]
	return []

# ---------------------------------------------------------------- Thợ rèn (khớp shared/logic/items.js + inventory.js của web)
const SMITH_UPGRADE_MAX := 12
const SMITH_PERFECT_MIN := 95
const SMITH_UPGRADE_RATES := [1.0, 1.0, 1.0, 1.0, 0.85, 0.78, 0.7, 0.62, 0.55, 0.48, 0.4, 0.3]

static func smith_upgrade_cost(plus: int) -> Dictionary:
	return {"gold": 15 * (plus + 1) * (plus + 1), "stones": ceili(float(plus + 1) / 3.0)}

func smith_reforge_cost(inst: Dictionary) -> Dictionary:
	var q := maxi(1, int(inst.get("q", 1)))
	var lv := maxi(2, int(item(str(inst.get("id", ""))).get("level", 1)))
	return {"gold": 60 * q * lv, "stones": q}

func smith_seal_cost(inst: Dictionary) -> Dictionary:
	var q := maxi(1, int(inst.get("q", 1)))
	var lv := maxi(2, int(item(str(inst.get("id", ""))).get("level", 1)))
	return {"gold": 120 * q * lv, "stones": q * 2}

static func smith_q(inst: Dictionary) -> int:
	return maxi(1, int(inst.get("q", 1)))

static func smith_salvage_stones(inst: Dictionary) -> int:
	var base: Array = [0, 1, 3, 6]
	var q := smith_q(inst)
	var n := 0 if q <= 0 else int(base[mini(q, 4) - 1])
	if q == 1: n = 0  # Thường: 0-1 ngẫu nhiên, hiện mức thấp nhất để không hứa sai
	return n + int(inst.get("plus", 0)) / 2

func _quest_edge(v: Variant, hi: bool) -> int:
	if typeof(v) == TYPE_STRING:
		return int(_quest_idx[v]) if _quest_idx.has(v) else (1 << 30 if hi else -1)
	return int(v)

## Map có phải Tân Đô (village là object {cap,n} hoặc true).
func is_village(m: Dictionary) -> bool:
	var v: Variant = m.get("village", false)
	return typeof(v) == TYPE_DICTIONARY or (typeof(v) == TYPE_BOOL and v)

## Bảng hình quái của web (MOBS / LOOK / LOOK_TINT / MON_GRADE), xuất bằng tools/export_mobs.js.
var mob_art: Dictionary = {}
## Hằng số tính chỉ số (phẩm chất, bộ trang bị, nội tại, Kỳ Nguyên...), tools/export_calc.js.
var calc: Dictionary = {}

func _load_looks() -> void:
	looks = {}
	art_meta = {}
	# File dữ liệu tính chỉ số BẮT BUỘC: thiếu thì mất toàn bộ chỉ số trang bị/nội tại/Kỳ Nguyên
	# và app hiển thị máu thấp hơn server rất nhiều (lỗi 3k vs 15k). Báo rõ thay vì bỏ qua im lặng.
	for req in ["res://data/calc.json", "res://data/mob_art.json"]:
		if not FileAccess.file_exists(req):
			push_error("THIEU FILE DU LIEU: %s — chay: node tools/export_calc.js va node tools/export_mobs.js" % req)
			printerr("THIEU FILE DU LIEU: ", req)
	for pair in [["res://data/map_looks.json", "looks"], ["res://assets/art/meta.json", "art_meta"], ["res://data/mob_art.json", "mob_art"], ["res://data/calc.json", "calc"]]:
		if not FileAccess.file_exists(pair[0]): continue
		var f := FileAccess.open(pair[0], FileAccess.READ)
		if f == null: continue
		var parsed: Variant = JSON.parse_string(f.get_as_text())
		f.close()
		if typeof(parsed) == TYPE_DICTIONARY:
			if pair[1] == "looks": looks = parsed
			elif pair[1] == "mob_art": mob_art = parsed
			elif pair[1] == "calc": calc = parsed
			else: art_meta = parsed

## Diện mạo của một map (nền, sương, ánh sáng, thời tiết, cảnh trí). Trả {} nếu không có.
func look(map_id: String) -> Dictionary:
	var m: Variant = (looks.get("maps", {}) as Dictionary).get(map_id, {})
	return m if typeof(m) == TYPE_DICTIONARY else {}

## "awaken3" -> 3 (0 nếu không hợp lệ).
func awaken_tier_of(choice: Variant) -> int:
	var t := str(choice) if choice != null else ""
	if not t.begins_with("awaken"): return 0
	return int(t.substr(6))

func awaken(tier: int) -> Dictionary:
	return AWAKENS[tier - 1] if tier >= 1 and tier <= AWAKENS.size() else {}

const ROMAN := ["I", "II", "III", "IV", "V"]
## Thú đồng hành: bảng y hệt shared/data/pets/mounts.js của web.
## Thú KHÔNG lên cấp — chỉ số cố định theo loài, tăng nhờ trang bị thú.
const MOUNTS := {
	"soi_xam": {"name": "Sói Xám", "look": "wolf", "tint": 0xb8c1cc, "hp": 2400, "mp": 60, "sta": 100, "atk": 180, "def": 150,
		"desc": "Sói đồng hành nhanh nhẹn, lao vào cắn mục tiêu."},
	"than_lan": {"name": "Thằn Lằn Đầm", "look": "lizard", "tint": 0xffffff, "hp": 2800, "mp": 60, "sta": 100, "atk": 170, "def": 190,
		"desc": "Thằn lằn đồng hành, dùng vuốt cào mục tiêu."},
	"soi_tuyet": {"name": "Sói Tuyết Bạc", "look": "wolf", "tint": 0xe5f3ff, "hp": 3000, "mp": 60, "sta": 100, "atk": 210, "def": 170,
		"desc": "Sói núi tuyết khỏe hơn, chuyên tấn công áp sát."},
	"hac_may": {"name": "Hắc Long", "look": "dragon", "tint": 0xffffff, "hp": 2200, "mp": 70, "sta": 110, "atk": 200, "def": 130,
		"desc": "Hắc long đồng hành, dùng vuốt và đuôi tấn công quái."},
	"ky_lan": {"name": "Dơi Huyết", "look": "bat", "tint": 0xffffff, "hp": 3400, "mp": 80, "sta": 110, "atk": 240, "def": 200,
		"desc": "Dơi huyết đồng hành, bay lượn và cắn mục tiêu."},
}

## Một con thú đồng hành ({} nếu không có).
func mount(id: String) -> Dictionary:
	var v: Variant = MOUNTS.get(id, {})
	return v if typeof(v) == TYPE_DICTIONARY else {}

## Tên hiển thị của thú; rơi về tên quái rồi mới tới mã.
func mount_name(id: String) -> String:
	var m := mount(id)
	if not m.is_empty(): return str(m.get("name", id))
	var mon := monster(id)
	if not mon.is_empty(): return str(mon.get("name", id))
	return id
