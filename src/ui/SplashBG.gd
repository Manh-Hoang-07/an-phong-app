extends Control
## Nền dùng chung cho Boot / Login: ảnh parallax của một pack nền (phủ kín, cắt giữa),
## lớp tối dần ở dưới, logo "THỨC TỈNH". Chỉ trang trí, không nhận chạm.

const T := preload("res://src/ui/UITheme.gd")
const PACK := "bch1"

func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _ready() -> void:
	var base := ColorRect.new()
	base.color = Color(0.03, 0.04, 0.08)
	base.set_anchors_preset(Control.PRESET_FULL_RECT)
	base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(base)
	for layer in ["sky", "far", "mid"]:
		var path := "res://assets/bg/%s/%s.png" % [PACK, layer]
		if not ResourceLoader.exists(path): continue
		var tr := TextureRect.new()
		tr.texture = load(path)
		tr.set_anchors_preset(Control.PRESET_FULL_RECT)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tr.modulate = Color(0.78, 0.82, 0.95, 1.0)
		add_child(tr)
	# Lớp phủ tối dần xuống dưới để chữ đọc rõ.
	var grad := Gradient.new()
	grad.set_color(0, Color(0.02, 0.03, 0.07, 0.35))
	grad.set_color(1, Color(0.02, 0.03, 0.07, 0.92))
	var gt := GradientTexture2D.new()
	gt.gradient = grad
	gt.fill_from = Vector2(0.5, 0.0)
	gt.fill_to = Vector2(0.5, 1.0)
	var ov := TextureRect.new()
	ov.texture = gt
	ov.set_anchors_preset(Control.PRESET_FULL_RECT)
	ov.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ov.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ov)

## Logo chữ; thêm vào container do màn hình chọn.
static func make_logo(size: int = T.FS_XXL) -> Control:
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 0)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var l := T.hud_label("THỨC TỈNH", size, T.C_GOLD, true)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_constant_override("outline_size", 6)
	box.add_child(l)
	var sub := T.hud_label("Thợ săn thức tỉnh", T.FS_S, T.C_MUTED, false)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(sub)
	return box
