extends Node
## Công thức dùng chung, port từ shared/core.js. Server vẫn là nơi tính thật;
## app chỉ dùng để HIỂN THỊ chỉ số cho đúng. Có tools/tests/compare_formulas.js để so hai bên.

const DEF_REDUCE_MAX := 0.75

## Kinh nghiệm cần để lên cấp tiếp theo.
static func exp_to_next(level: int) -> int:
	return int(floor(40.0 * pow(float(level), 1.7)))

## Làm tròn 1 chữ số thập phân (khớp Math.round(v*10)/10 của JS).
static func r1(v: float) -> float:
	return float(roundi(v * 10.0)) / 10.0

## Nội suy tuyến tính theo bảng mốc [[cap, gia_tri], ...].
static func interp(points: Array, x: float) -> float:
	if points.is_empty():
		return 0.0
	var first: Array = points[0]
	if x <= float(first[0]):
		return float(first[1])
	for i in range(1, points.size()):
		var prev: Array = points[i - 1]
		var cur: Array = points[i]
		if x <= float(cur[0]):
			var x0 := float(prev[0])
			var y0 := float(prev[1])
			var x1 := float(cur[0])
			var y1 := float(cur[1])
			if x1 == x0:
				return y1
			return y0 + (y1 - y0) * (x - x0) / (x1 - x0)
	var last: Array = points[points.size() - 1]
	return float(last[1])

## Tỉ lệ sát thương bị giáp chặn = DEF/(DEF+60+12*cấp), tối đa 75%.
static func def_reduce(def: float, level: int) -> float:
	var d := maxf(0.0, def)
	var lv := maxi(1, level)
	return minf(DEF_REDUCE_MAX, d / (d + 60.0 + 12.0 * float(lv)))

## Sát thương sau giáp, tối thiểu 1.
static func mitigate(raw: float, def: float, level: int) -> int:
	return maxi(1, int(roundf(raw * (1.0 - def_reduce(def, level)))))

# ---------------------------------------------------------------- Độ bền trang bị
# Port shared/logic/items.js (khối "Độ bền") + shared/data/equipment.js (DURABILITY). Server là nơi ghi `dur`;
# app CHỈ ĐỌC để hiển thị và loại món hỏng khỏi chỉ số. Đổi cân bằng thì sửa bên web rồi cập nhật hằng số này.
# Doc: docs/DO_BEN_TRANG_BI.md
const DURABILITY := {
	"HITS_WEAPON": 25000, "HITS_ARMOR": 400, "MOB_LEVEL_DIV": 20.0,
	"WARN_PCT": 20, "BROKEN_SELL": 0.25, "HURT_GAP_MS": 300,
}
const QUALITY_PRICE := {1: 1.0, 2: 1.5, 3: 2.0, 4: 3.0}

## Đồ vô hạn: không phải trang bị thường, đồ đặc biệt (special) hoặc Linh Ngọc (priceNgoc).
static func dur_infinite(def: Dictionary) -> bool:
	return def.is_empty() or str(def.get("slot", "")).is_empty() or bool(def.get("special", false)) or int(def.get("priceNgoc", 0)) > 0

static func _dur_mob_factor(lv: float) -> float:
	return 1.0 + maxf(1.0, lv) / float(DURABILITY["MOB_LEVEL_DIV"])

## Độ bền tối đa theo cấp giữa của bộ; -1 nếu vô hạn.
static func dur_max(def: Dictionary) -> int:
	if dur_infinite(def): return -1
	var sets: Array = Data.calc.get("SETS", [])
	var per := maxi(1, int(Data.calc.get("SET_LEVELS", 10)))
	var lv := maxi(1, int(def.get("level", 1)))
	var mid := float(lv)
	if not sets.is_empty():
		var s: Dictionary = sets[mini(sets.size() - 1, (lv - 1) / per)]
		mid = (float(s.get("min", lv)) + float(s.get("max", lv))) / 2.0
	var hits: int = DURABILITY["HITS_WEAPON"] if str(def.get("slot", "")) == "weapon" else DURABILITY["HITS_ARMOR"]
	return roundi(float(hits) * _dur_mob_factor(mid))

## Điểm hiện tại; thiếu `dur` = đầy; -1 nếu vô hạn.
static func dur_cur(inst: Dictionary) -> int:
	var mx := dur_max(Data.item(str(inst.get("id", ""))))
	if mx < 0: return -1
	var d: Variant = inst.get("dur", null)
	return mx if d == null else clampi(int(d), 0, mx)

static func is_broken(inst: Variant) -> bool:
	if typeof(inst) != TYPE_DICTIONARY: return false
	var it: Dictionary = inst
	var mx := dur_max(Data.item(str(it.get("id", ""))))
	return mx >= 0 and dur_cur(it) <= 0

## % hiển thị 0–100 (còn chút ít hiện tối thiểu 1); -1 nếu vô hạn.
static func dur_pct(inst: Dictionary) -> int:
	var mx := dur_max(Data.item(str(inst.get("id", ""))))
	if mx < 0: return -1
	var cur := dur_cur(inst)
	if cur <= 0: return 0
	return clampi(roundi(float(cur) / float(mx) * 100.0), 1, 100)

## {gold, stones, pct} hoặc {} nếu không cần sửa / vô hạn.
static func repair_cost(inst: Dictionary) -> Dictionary:
	var def: Dictionary = Data.item(str(inst.get("id", "")))
	var mx := dur_max(def)
	if mx < 0: return {}
	var missing := mx - dur_cur(inst)
	if missing <= 0: return {}
	var frac := float(missing) / float(mx)
	var lv := maxi(1, int(def.get("level", 1)))
	var sets: Array = Data.calc.get("SETS", [])
	var per := maxi(1, int(Data.calc.get("SET_LEVELS", 10)))
	var set_id := 1
	if not sets.is_empty(): set_id = int((sets[mini(sets.size() - 1, (lv - 1) / per)] as Dictionary).get("id", 1))
	var base := maxf(float(def.get("price", 0)), 40.0 * float(lv))
	var q := clampi(int(inst.get("q", 1)), 1, 4)
	return {
		"gold": maxi(1, ceili(frac * base * 0.4 * float(QUALITY_PRICE[q]))),
		"stones": maxi(1, ceili(frac * (2.0 + float(set_id) * 1.5))),
		"pct": roundi(frac * 100.0),
	}
