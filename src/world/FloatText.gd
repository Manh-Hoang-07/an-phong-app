extends RefCounted
## Chữ nổi trong thế giới (sát thương, +đồ, "Né"...). Tự bay lên, mờ dần rồi tự xoá.

const T := preload("res://src/ui/UITheme.gd")

static func spawn(parent: Node, pos: Vector2, text: String, color: Color = Color.WHITE, size: int = 16, rise: float = 46.0) -> void:
	if parent == null or not is_instance_valid(parent): return
	var l := Label.new()
	l.text = text
	l.z_index = 50
	l.add_theme_font_override("font", T.font(true))
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	l.add_theme_constant_override("outline_size", 4)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.pivot_offset = Vector2(30, 10)
	parent.add_child(l)
	l.reset_size()
	l.position = pos - Vector2(l.size.x * 0.5, l.size.y * 0.5)
	l.scale = Vector2(0.6, 0.6)
	var tw := l.create_tween()
	tw.set_parallel(true)
	tw.tween_property(l, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(l, "position:y", l.position.y - rise, 0.8).set_ease(Tween.EASE_OUT)
	tw.chain().tween_property(l, "modulate:a", 0.0, 0.25)
	tw.chain().tween_callback(l.queue_free)
