extends Node2D
## Mũi tên tam giác đánh dấu mục tiêu (đỏ) / điểm tương tác (vàng).
var col := Color(1.0, 0.32, 0.32)
func _draw() -> void:
	var pts := PackedVector2Array([Vector2(-9, 0), Vector2(9, 0), Vector2(0, 14)])
	draw_colored_polygon(pts, col)
	draw_polyline(PackedVector2Array([pts[0], pts[1], pts[2], pts[0]]), Color(0, 0, 0, 0.8), 2.0)
