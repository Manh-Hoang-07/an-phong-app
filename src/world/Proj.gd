extends Node2D
## Đạn bay (mũi tên, quả cầu phép, đạn lửa). Chỉ vẽ; World.gd tự di chuyển và tính trúng.

var color := Color(1.0, 0.7, 0.3)
var big := 1.0
var arrow := false
var _t := 0.0

func setup(c: Color, angle: float, facing: int, size: float = 1.0, is_arrow: bool = false) -> void:
	color = c
	big = size
	arrow = is_arrow
	rotation = angle * float(facing)
	scale = Vector2(float(facing), 1.0)
	z_index = 7

func _process(delta: float) -> void:
	_t += delta
	queue_redraw()

func _draw() -> void:
	if arrow:
		draw_line(Vector2(-16, 0) * big, Vector2(10, 0) * big, Color(0.85, 0.72, 0.5), 2.0 * big)
		draw_colored_polygon(PackedVector2Array([Vector2(14, 0) * big, Vector2(8, -4) * big, Vector2(8, 4) * big]), Color(0.9, 0.9, 0.95))
		draw_line(Vector2(-16, 0) * big, Vector2(-20, -4) * big, color, 2.0)
		draw_line(Vector2(-16, 0) * big, Vector2(-20, 4) * big, color, 2.0)
		return
	var pulse := 1.0 + 0.12 * sin(_t * 30.0)
	draw_circle(Vector2.ZERO, 11.0 * big * pulse, Color(color.r, color.g, color.b, 0.22))
	draw_circle(Vector2.ZERO, 7.0 * big * pulse, Color(color.r, color.g, color.b, 0.55))
	draw_circle(Vector2.ZERO, 3.5 * big, Color(1, 1, 1, 0.95))
	draw_line(Vector2(-4, 0), Vector2(-26, 0) * big, Color(color.r, color.g, color.b, 0.4), 5.0 * big)
