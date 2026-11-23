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
	hash_local = str(raw.get("dataHash", ""))
	_load_quests()
	_load_looks()
	loaded.emit(true, "")
	return true

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

## Map có phải Tân Đô (village là object {cap,n} hoặc true).
func is_village(m: Dictionary) -> bool:
	var v: Variant = m.get("village", false)
	return typeof(v) == TYPE_DICTIONARY or (typeof(v) == TYPE_BOOL and v)

func _load_looks() -> void:
	looks = {}
	art_meta = {}
	for pair in [["res://data/map_looks.json", "looks"], ["res://assets/art/meta.json", "art_meta"]]:
		if not FileAccess.file_exists(pair[0]): continue
		var f := FileAccess.open(pair[0], FileAccess.READ)
		if f == null: continue
		var parsed: Variant = JSON.parse_string(f.get_as_text())
		f.close()
		if typeof(parsed) == TYPE_DICTIONARY:
			if pair[1] == "looks": looks = parsed
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
