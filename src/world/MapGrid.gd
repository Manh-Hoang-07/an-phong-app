extends RefCounted
## Dựng lưới ô (Array các hàng, mỗi hàng là Array ký tự) từ file map: giãn cột 1.5x như WorldMap.parseMap của web,
## xoá ký tự điểm đánh dấu, đệm đủ 17 hàng, bỏ bục gỗ nằm ngay trên đất.
## Dùng chung cho World (MapSystem) và tool bake ảnh nền (tools/export/bake_maps.gd) để hai bên luôn ra cùng một lưới.

const STRETCH := 1.5

static func build(text: String, meta: Dictionary) -> Array:
	var lines: Array = text.replace("\r", "").split("\n", false)
	var source_cols := 0
	for line in lines: source_cols = maxi(source_cols, (line as String).length())
	var cols := int(ceil(float(source_cols) * STRETCH))
	var rows := lines.size()
	var markers := ["S"]
	for k in (meta.get("spawns", {}) as Dictionary).keys(): markers.append(str(k))
	for k in (meta.get("npcs", {}) as Dictionary).keys(): markers.append(str(k))
	for k in (meta.get("portals", {}) as Dictionary).keys(): markers.append(str(k))
	markers.append(str(meta.get("gate", "")))
	var grid: Array = []
	for line in lines:
		var s := line as String
		var row: Array = []
		for col in range(cols):
			var old := mini(source_cols - 1, int(floor(float(col) / STRETCH)))
			var ch := s.substr(old, 1) if old < s.length() else "."
			if ch in markers and col != int(ceil(float(old) * STRETCH)): ch = "."
			row.append(ch)
		grid.append(row)
	for i in range(maxi(0, 17 - rows)):
		grid.append(Array(grid[0]).map(func(_x): return "#"))
	rows = grid.size()
	for r in range(rows - 1):
		for c in range(cols):
			if str((grid[r] as Array)[c]) == "=" and str((grid[r + 1] as Array)[c]) == "#":
				(grid[r] as Array)[c] = "."
	return grid
