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
