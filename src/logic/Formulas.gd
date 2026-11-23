extends Node
## Công thức dùng chung, port từ shared/core.js. Server vẫn là nơi tính thật;
## app chỉ dùng để HIỂN THỊ chỉ số cho đúng. Có tools/compare_formulas.js để so hai bên.

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
