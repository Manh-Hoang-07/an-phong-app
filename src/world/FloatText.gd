extends RefCounted
## Chữ nổi trong thế giới (sát thương, +đồ, "Né"...). Tự bay lên, mờ dần rồi tự ẩn.
## Label được TÁI SỬ DỤNG (pool) thay vì tạo mới + queue_free mỗi lần trúng đòn, và có trần số chữ đang bay
## để đánh dồn dập không sinh hàng chục Label/Tween cùng lúc.

const T := preload("res://src/ui/UITheme.gd")
const MAX_ACTIVE := 28

static var _pool: Array = []     # Label đã bay xong, đang ẩn, chờ dùng lại
static var _active: Array = []   # Label đang bay

static func _new_label() -> Label:
	var l := Label.new()
	l.z_index = 50
	l.add_theme_font_override("font", T.font(true))
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	l.add_theme_constant_override("outline_size", 4)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.pivot_offset = Vector2(30, 10)
	return l

static func _recycle(l: Label) -> void:
	if not is_instance_valid(l): return
	l.visible = false
	_active.erase(l)
	_pool.append(l)

static func spawn(parent: Node, pos: Vector2, text: String, color: Color = Color.WHITE, size: int = 16, rise: float = 46.0) -> void:
	if parent == null or not is_instance_valid(parent): return
	# Dọn nhãn đã bị giải phóng (đổi map) khỏi danh sách đang bay
	var i := _active.size() - 1
	while i >= 0:
		if not is_instance_valid(_active[i]): _active.remove_at(i)
		i -= 1
	if _active.size() >= MAX_ACTIVE: return
	var l: Label = null
	while l == null and not _pool.is_empty():
		var c: Variant = _pool.pop_back()
		if is_instance_valid(c): l = c as Label
	if l == null:
		l = _new_label()
	var old := l.get_parent()
	if old != parent:
		if old != null: old.remove_child(l)
		parent.add_child(l)
	l.visible = true
	l.modulate = Color.WHITE
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.reset_size()
	l.position = pos - Vector2(l.size.x * 0.5, l.size.y * 0.5)
	l.scale = Vector2(0.6, 0.6)
	_active.append(l)
	var tw := l.create_tween()
	tw.set_parallel(true)
	tw.tween_property(l, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(l, "position:y", l.position.y - rise, 0.8).set_ease(Tween.EASE_OUT)
	tw.chain().tween_property(l, "modulate:a", 0.0, 0.25)
	tw.chain().tween_callback(_recycle.bind(l))
