extends Node2D
## Hiệu ứng chiến đấu dùng chung: vệt chém, tia lửa trúng đòn, vòng sóng, nổ hạt, khói chết, thăng cấp, hồi máu, vệt lướt.
## Mọi hiệu ứng tự xoá; số hạt giảm một nửa khi bật "Đồ họa thấp".

const T := preload("res://src/ui/UITheme.gd")

var _live_particles := 0

func _q() -> float:
	return 0.5 if Settings.quality_low else 1.0

func _particles(pos: Vector2, count: int, color: Color, speed: Vector2, life: float, size: float, gravity: float = 0.0, spread: float = 180.0, dir: Vector2 = Vector2.UP) -> CPUParticles2D:
	# Trần số cụm hạt đang sống: đánh dồn dập không tạo thêm khi đã quá nhiều (tránh spike + tụt FPS)
	if _live_particles >= (14 if Settings.quality_low else 28):
		return null
	_live_particles += 1
	var p := CPUParticles2D.new()
	p.tree_exited.connect(func() -> void: _live_particles = maxi(0, _live_particles - 1))
	p.position = pos
	p.z_index = 20
	p.amount = maxi(2, int(float(count) * _q()))
	p.lifetime = life
	p.one_shot = true
	p.explosiveness = 0.95
	p.direction = dir
	p.spread = spread
	p.initial_velocity_min = speed.x
	p.initial_velocity_max = speed.y
	p.gravity = Vector2(0, gravity)
	p.scale_amount_min = size * 0.6
	p.scale_amount_max = size
	var g := Gradient.new()
	g.set_color(0, Color(color.lightened(0.4), 1.0))
	g.add_point(0.5, color)
	g.set_color(g.get_point_count() - 1, Color(color, 0.0))
	p.color_ramp = g
	add_child(p)
	p.emitting = true
	get_tree().create_timer(life + 0.3).timeout.connect(p.queue_free)
	return p

## Vệt chém hình lưỡi liềm trước mặt.
func slash(pos: Vector2, facing: int, color: Color = Color(1.0, 0.95, 0.8), scale_f: float = 1.0, flip_y: bool = false) -> void:
	var n := _Slash.new()
	n.position = pos + Vector2(float(facing) * 34.0 * scale_f, -4.0)
	n.facing = facing
	n.color = color
	n.scale = Vector2(scale_f, scale_f * (-1.0 if flip_y else 1.0))
	n.z_index = 18
	add_child(n)
	var tw := n.create_tween().set_parallel(true)
	tw.tween_property(n, "progress", 1.0, 0.18)
	tw.tween_property(n, "modulate:a", 0.0, 0.18).set_delay(0.06)
	tw.chain().tween_callback(n.queue_free)

## Tia lửa khi trúng quái; crit thì to và vàng.
func hit_spark(pos: Vector2, crit: bool, dir: int = 1) -> void:
	var col := Color(1.0, 0.82, 0.3) if crit else Color(1.0, 0.95, 0.85)
	_particles(pos, 14 if crit else 7, col, Vector2(90, 230 if crit else 170), 0.35, 3.2 if crit else 2.2, 260.0, 70.0, Vector2(float(dir), -0.35))
	var star := _Star.new()
	star.position = pos
	star.color = col
	star.big = crit
	star.z_index = 22
	add_child(star)
	var tw := star.create_tween().set_parallel(true)
	tw.tween_property(star, "scale", Vector2(1.6, 1.6) if crit else Vector2(1.2, 1.2), 0.14).from(Vector2(0.4, 0.4))
	tw.tween_property(star, "modulate:a", 0.0, 0.16)
	tw.chain().tween_callback(star.queue_free)

## Vòng sóng lan ra.
func ring(pos: Vector2, color: Color, radius: float = 60.0, dur: float = 0.45, width: float = 4.0) -> void:
	var r := _Ring.new()
	r.position = pos
	r.color = color
	r.width = width
	r.z_index = 17
	add_child(r)
	var tw := r.create_tween().set_parallel(true)
	tw.tween_property(r, "radius", radius, dur).from(8.0).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(r, "modulate:a", 0.0, dur).set_delay(dur * 0.3)
	tw.chain().tween_callback(r.queue_free)

func burst(pos: Vector2, color: Color, count: int = 12, speed: float = 160.0) -> void:
	_particles(pos, count, color, Vector2(speed * 0.4, speed), 0.5, 3.0, 120.0, 180.0)

## Khói + tia khi quái chết.
func death_poof(pos: Vector2, boss: bool = false) -> void:
	_particles(pos + Vector2(0, -14), 16 if not boss else 40, Color(0.75, 0.75, 0.8), Vector2(30, 120), 0.7, 5.0 if not boss else 9.0, -30.0, 180.0)
	_particles(pos + Vector2(0, -14), 8 if not boss else 24, Color(1.0, 0.85, 0.4), Vector2(80, 200), 0.5, 2.4, 200.0, 180.0)
	ring(pos + Vector2(0, -14), Color(1, 1, 1, 0.6), 46.0 if not boss else 120.0, 0.35, 3.0)

## Thăng cấp: cột sáng + vòng + sao bay lên.
func levelup(pos: Vector2) -> void:
	var beam := _Beam.new()
	beam.position = pos + Vector2(0, 32)
	beam.z_index = 16
	add_child(beam)
	var tw := beam.create_tween().set_parallel(true)
	tw.tween_property(beam, "h", 240.0, 0.35).from(10.0).set_ease(Tween.EASE_OUT)
	tw.tween_property(beam, "modulate:a", 0.0, 0.9).set_delay(0.25)
	tw.chain().tween_callback(beam.queue_free)
	ring(pos + Vector2(0, 28), Color(1.0, 0.85, 0.35), 110.0, 0.7, 5.0)
	ring(pos + Vector2(0, 28), Color(1.0, 1.0, 0.8), 70.0, 0.5, 3.0)
	_particles(pos + Vector2(0, 10), 28, Color(1.0, 0.88, 0.4), Vector2(60, 220), 1.0, 3.4, -80.0, 50.0, Vector2.UP)

func heal(pos: Vector2) -> void:
	_particles(pos + Vector2(0, 20), 12, Color(0.4, 1.0, 0.6), Vector2(30, 90), 0.9, 3.0, -40.0, 40.0, Vector2.UP)
	ring(pos + Vector2(0, 28), Color(0.4, 1.0, 0.6, 0.8), 40.0, 0.5, 3.0)

func shield(pos: Vector2, color: Color = Color(0.45, 0.7, 1.0)) -> void:
	ring(pos, color, 44.0, 0.5, 4.0)
	_particles(pos, 10, color, Vector2(40, 120), 0.5, 2.6, 0.0, 180.0)

func pickup(pos: Vector2) -> void:
	_particles(pos, 8, Color(1.0, 0.9, 0.5), Vector2(50, 130), 0.4, 2.4, 80.0, 90.0, Vector2.UP)

## Vệt lướt: dải mờ từ a tới b.
func dash_trail(a: Vector2, b: Vector2, color: Color = Color(0.7, 0.85, 1.0)) -> void:
	var l := Line2D.new()
	l.z_index = 15
	l.width = 26.0
	l.default_color = Color(color, 0.5)
	l.points = PackedVector2Array([a, b])
	var grad := Gradient.new()
	grad.set_color(0, Color(color, 0.0))
	grad.set_color(1, Color(color, 0.7))
	l.gradient = grad
	add_child(l)
	var tw := l.create_tween()
	tw.tween_property(l, "modulate:a", 0.0, 0.3)
	tw.tween_callback(l.queue_free)

# ---------------------------------------------------------------- Hình vẽ
class _Slash extends Node2D:
	var facing := 1
	var color := Color.WHITE
	var progress := 0.0:
		set(v):
			progress = v
			queue_redraw()
	func _draw() -> void:
		# Lưỡi liềm: hai cung lệch tâm tạo hình trăng khuyết, quét theo progress
		var sweep := lerpf(0.25, 1.0, progress)
		var r_out := 46.0
		var a0 := -1.2 * float(facing) - (0.0 if facing > 0 else PI)
		var pts_o := PackedVector2Array()
		var pts_i := PackedVector2Array()
		var steps := 14
		for i in range(steps + 1):
			var t := float(i) / float(steps)
			var ang := lerpf(-1.15, 1.15 * sweep, t)
			var dir := Vector2(cos(ang) * float(facing), sin(ang))
			pts_o.append(dir * r_out)
			pts_i.append(dir * (r_out - 14.0 * sin(t * PI) - 2.0) + Vector2(-5.0 * float(facing), 0))
		var poly := PackedVector2Array()
		poly.append_array(pts_o)
		pts_i.reverse()
		poly.append_array(pts_i)
		if poly.size() >= 3:
			draw_colored_polygon(poly, Color(color, 0.85))
		draw_polyline(pts_o, Color(1, 1, 1, 0.9), 2.0, true)

class _Star extends Node2D:
	var color := Color.WHITE
	var big := false
	func _draw() -> void:
		var r := 16.0 if big else 10.0
		for i in range(4):
			var a := PI * 0.5 * float(i) + PI * 0.25
			draw_line(Vector2.ZERO, Vector2(cos(a), sin(a)) * r, color, 2.4, true)
		draw_line(Vector2(-r * 1.3, 0), Vector2(r * 1.3, 0), Color(1, 1, 1, 0.9), 2.0, true)
		draw_line(Vector2(0, -r * 1.3), Vector2(0, r * 1.3), Color(1, 1, 1, 0.9), 2.0, true)
		draw_circle(Vector2.ZERO, r * 0.3, Color(1, 1, 1, 0.95))

class _Ring extends Node2D:
	var color := Color.WHITE
	var width := 4.0
	var radius := 8.0:
		set(v):
			radius = v
			queue_redraw()
	func _draw() -> void:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.45))   # nhìn nghiêng như đứng trên mặt đất
		draw_arc(Vector2.ZERO, radius, 0.0, TAU, 40, color, width, true)
		draw_arc(Vector2.ZERO, radius * 0.82, 0.0, TAU, 40, Color(color, color.a * 0.4), width * 0.6, true)

class _Beam extends Node2D:
	var h := 10.0:
		set(v):
			h = v
			queue_redraw()
	func _draw() -> void:
		for i in range(5):
			var w := 34.0 - float(i) * 6.0
			draw_rect(Rect2(-w * 0.5, -h, w, h), Color(1.0, 0.9, 0.5, 0.10 + float(i) * 0.06), true)
		draw_rect(Rect2(-3, -h, 6, h), Color(1, 1, 0.9, 0.7), true)
