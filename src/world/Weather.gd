extends CanvasLayer
## Lớp phủ màn hình theo diện mạo map: ánh sáng chung (nhân màu), hạt sáng bay, thời tiết (mưa / tuyết / than hồng / sương).
## Dữ liệu từ data/map_looks.json (grade, mote, moteN, weather, fog). Giảm một nửa hạt khi "Đồ họa thấp".

var _grade: ColorRect
var _holder: Control
var _view := Vector2(960, 432)

func _ready() -> void:
	layer = 1
	_view = get_viewport().get_visible_rect().size
	_grade = ColorRect.new()
	_grade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_grade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_MUL
	_grade.material = mat
	add_child(_grade)
	_holder = Control.new()
	_holder.set_anchors_preset(Control.PRESET_FULL_RECT)
	_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_holder)

func _col(v: int, a: float = 1.0) -> Color:
	return Color(float((v >> 16) & 255) / 255.0, float((v >> 8) & 255) / 255.0, float(v & 255) / 255.0, a)

func _soft_dot(size: int = 16) -> Texture2D:
	var grad := Gradient.new()
	grad.set_color(0, Color(1, 1, 1, 1))
	grad.set_color(1, Color(1, 1, 1, 0))
	var gt := GradientTexture2D.new()
	gt.gradient = grad
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.5)
	gt.fill_to = Vector2(1.0, 0.5)
	gt.width = size
	gt.height = size
	return gt

func _streak() -> Texture2D:
	var im := Image.create(2, 14, false, Image.FORMAT_RGBA8)
	for y in range(14):
		im.set_pixel(0, y, Color(1, 1, 1, float(y) / 14.0))
		im.set_pixel(1, y, Color(1, 1, 1, float(y) / 14.0))
	return ImageTexture.create_from_image(im)

func _emitter(count: int, tex: Texture2D, color: Color, life: float, vel: Vector2, dir: Vector2, spread: float, size: Vector2, additive: bool, rect: Vector2) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.amount = maxi(2, int(float(count) * (0.5 if Settings.quality_low else 1.0)))
	p.lifetime = life
	p.preprocess = life
	p.texture = tex
	p.color = color
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = rect
	p.direction = dir
	p.spread = spread
	p.initial_velocity_min = vel.x
	p.initial_velocity_max = vel.y
	p.scale_amount_min = size.x
	p.scale_amount_max = size.y
	if additive:
		var m := CanvasItemMaterial.new()
		m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		p.material = m
	p.emitting = true
	return p

func apply(look: Dictionary) -> void:
	for c in _holder.get_children(): c.queue_free()
	_view = get_viewport().get_visible_rect().size
	_grade.color = _col(int(look.get("grade", 0xffffff)))
	var weather := str(look.get("weather", "none"))
	if Settings.quality_low and weather in ["rain", "snow"]: weather = "none"
	var mote_n := int(look.get("moteN", 14))
	if not Settings.quality_low and look.has("mote"):
		var mc := _col(int(look["mote"]), 0.55)
		var p := _emitter(mote_n, _soft_dot(14), mc, 7.0, Vector2(6, 18), Vector2.UP, 40.0, Vector2(0.4, 1.0), true, Vector2(_view.x * 0.5, _view.y * 0.5))
		p.position = _view * 0.5
		_holder.add_child(p)
	match weather:
		"rain":
			var r := _emitter(110, _streak(), Color(0.8, 0.85, 1.0, 0.45), 0.9, Vector2(520, 640), Vector2(-0.12, 1.0), 4.0, Vector2(1.0, 1.0), false, Vector2(_view.x * 0.6, 4))
			r.position = Vector2(_view.x * 0.5, -10)
			_holder.add_child(r)
		"snow":
			var s := _emitter(90, _soft_dot(8), Color(1, 1, 1, 0.8), 6.0, Vector2(20, 50), Vector2(-0.2, 1.0), 25.0, Vector2(0.5, 1.2), false, Vector2(_view.x * 0.6, 4))
			s.position = Vector2(_view.x * 0.5, -10)
			_holder.add_child(s)
		"ember":
			var e := _emitter(40, _soft_dot(8), Color(1.0, 0.55, 0.2, 0.8), 3.5, Vector2(30, 90), Vector2.UP, 30.0, Vector2(0.5, 1.2), true, Vector2(_view.x * 0.5, 4))
			e.position = Vector2(_view.x * 0.5, _view.y + 6)
			_holder.add_child(e)
		"fog":
			var fc := _col(int(look.get("fog", 0xcfe0e0)), 0.0)
			var fr := ColorRect.new()
			fr.set_anchors_preset(Control.PRESET_FULL_RECT)
			fr.mouse_filter = Control.MOUSE_FILTER_IGNORE
			fr.color = fc
			_holder.add_child(fr)
			var tw := fr.create_tween().set_loops()
			tw.tween_property(fr, "color:a", 0.13, 4.0).set_trans(Tween.TRANS_SINE)
			tw.tween_property(fr, "color:a", 0.05, 4.0).set_trans(Tween.TRANS_SINE)
