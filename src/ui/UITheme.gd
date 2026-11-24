extends RefCounted
## Design system của app (mobile, landscape). Mọi màu / cỡ chữ / khoảng cách đi qua file này.
## Không gian thiết kế: viewport 960x432 (xem project.godot) ~ 1 đơn vị = 1 css px trên điện thoại ngang.
## Quy tắc: chữ >= 13px, vùng chạm >= 44px, bo góc lớn, tương phản cao trên nền tối.

const UISkin := preload("res://src/ui/UISkin.gd")
const GlyphArt := preload("res://src/ui/GlyphArt.gd")
const FONT_DIR := "res://assets/fonts/"
const ICON_DIR := "res://assets/ui/icons/"

# ---- Màu: xanh đêm + vàng đồng ----
const C_BG        := Color(0.043, 0.055, 0.094, 0.975)
const C_BG2       := Color(0.070, 0.086, 0.137, 0.97)
const C_PANEL     := Color(0.055, 0.070, 0.118, 0.985)
const C_CARD      := Color(0.098, 0.121, 0.184, 0.96)
const C_CARD_HI   := Color(0.145, 0.184, 0.270, 0.98)
const C_BORDER    := Color(0.36, 0.48, 0.70, 0.85)
const C_GOLD      := Color(1.00, 0.84, 0.42)
const C_GOLD_DK   := Color(0.80, 0.58, 0.16)
const C_BRASS     := Color(0.82, 0.64, 0.30)   # đồng ấm dùng cho viền/điểm nhấn phụ
const C_TEXT      := Color(0.94, 0.96, 1.00)
const C_MUTED     := Color(0.62, 0.68, 0.81)
const C_FAINT     := Color(0.44, 0.50, 0.63)   # chữ phụ cấp ba (hint, đơn vị)
const C_RED       := Color(0.95, 0.36, 0.40)
const C_GREEN     := Color(0.36, 0.88, 0.58)
const C_BLUE      := Color(0.38, 0.68, 1.00)
const C_PURPLE    := Color(0.74, 0.50, 0.99)
const C_SCRIM     := Color(0.0, 0.0, 0.02, 0.62)
const C_HUD_BG    := Color(0.04, 0.06, 0.12, 0.72)

# ---- Cỡ chữ ----
const FS_S  := 13
const FS_M  := 15
const FS_L  := 18
const FS_XL := 24
const FS_XXL := 40

# ---- Khoảng cách / kích thước ----
const SP_XS := 4
const SP_S  := 8
const SP_M  := 12
const SP_L  := 16
const TOUCH := 48          # vùng chạm tối thiểu
const R_S := 8
const R_M := 12
const R_L := 18

static var _font: Font = null
static var _font_bold: Font = null
static var _theme: Theme = null
static var _icons: Dictionary = {}

# ------------------------------------------------------------------ Font
static func _build_font(weight: String) -> Font:
	var main := FontFile.new()
	var sets := ["latin", "vietnamese", "latin-ext"]
	var loaded: Array[FontFile] = []
	for s in sets:
		var path := "%sbvp-%s-%s.woff2" % [FONT_DIR, s, weight]
		if not ResourceLoader.exists(path): continue
		# Dùng resource đã import (bản export không còn file .woff2 gốc).
		var f := load(path) as FontFile
		if f == null: continue
		f.allow_system_fallback = false   # không nạp font emoji/hệ thống (crash iOS)
		f.antialiasing = TextServer.FONT_ANTIALIASING_GRAY
		f.hinting = TextServer.HINTING_NONE
		f.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_AUTO
		loaded.append(f)
	if loaded.is_empty():
		return ThemeDB.fallback_font
	main = loaded[0]
	var fb: Array[Font] = []
	for i in range(1, loaded.size()): fb.append(loaded[i])
	main.fallbacks = fb
	return main

static func font(bold: bool = false) -> Font:
	if bold:
		if _font_bold == null: _font_bold = _build_font("700")
		return _font_bold
	if _font == null: _font = _build_font("400")
	return _font

# ------------------------------------------------------------------ Icon
static func icon(name: String) -> Texture2D:
	if _icons.has(name): return _icons[name]
	var path := ICON_DIR + name + ".svg"
	var tex: Texture2D = null
	if ResourceLoader.exists(path):
		tex = load(path) as Texture2D
	_icons[name] = tex
	return tex

static func icon_rect(name: String, size: float = 24.0, tint: Color = C_TEXT) -> TextureRect:
	var tr := TextureRect.new()
	tr.texture = icon(name)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.custom_minimum_size = Vector2(size, size)
	tr.modulate = tint
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return tr

# ------------------------------------------------------------------ Safe area
## Lề an toàn (tai thỏ / thanh điều hướng) theo đơn vị viewport: x=trái, y=trên, z=phải, w=dưới.
## Luôn tối thiểu `min_pad` để HUD không dính mép.
static func safe_insets(vp: Viewport, min_pad: float = 14.0) -> Vector4:
	var res := Vector4(min_pad, min_pad * 0.6, min_pad, min_pad * 0.6)
	if vp == null: return res
	var win := Vector2(DisplayServer.window_get_size())
	if win.x <= 0.0 or win.y <= 0.0: return res
	var safe := Rect2(DisplayServer.get_display_safe_area())
	if safe.size.x <= 0.0: return res
	var vis := vp.get_visible_rect().size
	var sx := vis.x / win.x
	var sy := vis.y / win.y
	var l := maxf(0.0, safe.position.x) * sx
	var t := maxf(0.0, safe.position.y) * sy
	var r := maxf(0.0, win.x - safe.end.x) * sx
	var b := maxf(0.0, win.y - safe.end.y) * sy
	return Vector4(maxf(res.x, l), maxf(res.y, t), maxf(res.z, r), maxf(res.w, b))

# ------------------------------------------------------------------ StyleBox
static func _sb(bg: Color, border: Color, width: int, radius: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(width)
	s.set_corner_radius_all(radius)
	s.set_content_margin_all(10)
	s.anti_aliasing = true
	return s

static func sb(bg: Color, border: Color = Color(0, 0, 0, 0), width: int = 0, radius: int = R_M, margin: int = 10) -> StyleBoxFlat:
	var s := _sb(bg, border, width, radius)
	s.set_content_margin_all(margin)
	return s

## Khung có bóng đổ nhẹ — dùng cho panel/thẻ nổi.
static func sb_shadow(bg: Color, border: Color, width: int, radius: int, margin: int = 12) -> StyleBoxFlat:
	var s := sb(bg, border, width, radius, margin)
	s.shadow_color = Color(0, 0, 0, 0.45)
	s.shadow_size = 10
	s.shadow_offset = Vector2(0, 3)
	return s

static func make_theme() -> Theme:
	if _theme != null: return _theme
	var t := Theme.new()
	var f := font()
	t.default_font = f
	t.default_font_size = FS_M
	# Button
	t.set_stylebox("normal", "Button", UISkin.button("default", "normal", 10))
	t.set_stylebox("hover", "Button", UISkin.button("default", "hover", 10))
	t.set_stylebox("pressed", "Button", UISkin.button("default", "pressed", 10))
	t.set_stylebox("disabled", "Button", UISkin.button("default", "disabled", 10))
	t.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	t.set_color("font_color", "Button", C_TEXT)
	t.set_color("font_hover_color", "Button", Color.WHITE)
	t.set_color("font_pressed_color", "Button", C_GOLD)
	t.set_color("font_disabled_color", "Button", C_MUTED)
	t.set_font("font", "Button", f)
	t.set_font_size("font_size", "Button", FS_M)
	# Panel
	t.set_stylebox("panel", "PanelContainer", UISkin.panel(12))
	t.set_stylebox("panel", "Panel", UISkin.card(0))
	# LineEdit
	t.set_stylebox("normal", "LineEdit", UISkin.inset(11))
	t.set_stylebox("focus", "LineEdit", UISkin.tab(true))
	t.set_stylebox("read_only", "LineEdit", UISkin.inset(11))
	t.set_color("font_color", "LineEdit", C_TEXT)
	t.set_color("font_placeholder_color", "LineEdit", C_MUTED)
	t.set_color("caret_color", "LineEdit", C_GOLD)
	t.set_color("selection_color", "LineEdit", Color(C_GOLD, 0.35))
	t.set_font("font", "LineEdit", f)
	t.set_font_size("font_size", "LineEdit", FS_M)
	# Label
	t.set_color("font_color", "Label", C_TEXT)
	t.set_font("font", "Label", f)
	t.set_font_size("font_size", "Label", FS_M)
	# CheckButton / CheckBox: chữ to hơn, không viền focus
	for cls in ["CheckButton", "CheckBox"]:
		t.set_color("font_color", cls, C_TEXT)
		t.set_font_size("font_size", cls, FS_M)
		t.set_stylebox("focus", cls, StyleBoxEmpty.new())
		# CheckButton ke thua stylebox cua Button -> vien vang + nen xanh quanh o bat/tat.
		# Bo het: chi con thanh truot va nut tron.
		for st in ["normal", "hover", "pressed", "disabled", "hover_pressed"]:
			t.set_stylebox(st, cls, StyleBoxEmpty.new())
	# ProgressBar
	t.set_stylebox("background", "ProgressBar", UISkin.bar_frame())
	t.set_stylebox("fill", "ProgressBar", UISkin.bar_fill(C_GREEN))
	# Scrollbar mảnh, bo tròn (trên điện thoại cuộn bằng vuốt nên chỉ cần gợi ý)
	var grab := sb(Color(1, 1, 1, 0.28), Color(0, 0, 0, 0), 0, 4, 0)
	var track := sb(Color(1, 1, 1, 0.05), Color(0, 0, 0, 0), 0, 4, 0)
	for cls in ["VScrollBar", "HScrollBar"]:
		t.set_stylebox("scroll", cls, track)
		t.set_stylebox("grabber", cls, grab)
		t.set_stylebox("grabber_highlight", cls, grab)
		t.set_stylebox("grabber_pressed", cls, grab)
	t.set_constant("separation", "VBoxContainer", SP_S)
	t.set_constant("separation", "HBoxContainer", SP_S)
	t.set_stylebox("panel", "ScrollContainer", StyleBoxEmpty.new())
	_theme = t
	return t

# ------------------------------------------------------------------ Factory
static func label(text: String, size: int = FS_M, color: Color = C_TEXT, bold: bool = false) -> Label:
	var l := Label.new()
	l.text = GlyphArt.clean(text)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_font_override("font", font(bold))
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

## Chữ có bóng đen — dùng trên nền thế giới (HUD).
static func hud_label(text: String, size: int = FS_M, color: Color = C_TEXT, bold: bool = true) -> Label:
	var l := label(text, size, color, bold)
	l.autowrap_mode = TextServer.AUTOWRAP_OFF
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	l.add_theme_constant_override("shadow_offset_x", 1)
	l.add_theme_constant_override("shadow_offset_y", 1)
	l.add_theme_constant_override("outline_size", 3)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.6))
	return l

static func button(text: String, min_size: Vector2 = Vector2(0, 40)) -> Button:
	var b := Button.new()
	b.text = GlyphArt.clean(text)
	b.custom_minimum_size = min_size
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_override("font", font(true))
	b.add_theme_font_size_override("font_size", FS_M)
	b.add_theme_color_override("font_color", C_TEXT)
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	b.add_theme_color_override("font_pressed_color", C_GOLD)
	b.add_theme_color_override("font_disabled_color", Color(C_MUTED, 0.6))
	b.add_theme_stylebox_override("normal", UISkin.button("default", "normal", 10))
	b.add_theme_stylebox_override("hover", UISkin.button("default", "hover", 10))
	b.add_theme_stylebox_override("pressed", UISkin.button("default", "pressed", 10))
	b.add_theme_stylebox_override("disabled", UISkin.button("default", "disabled", 10))
	b.pressed.connect(func(): Audio.play("ui"))
	return b

## Nút chính (vàng đồng) — hành động quan trọng nhất trên màn hình.
static func button_primary(text: String, min_size: Vector2 = Vector2(0, 48)) -> Button:
	var b := button(text, min_size)
	b.add_theme_font_size_override("font_size", FS_L)
	var dark := Color(0.16, 0.09, 0.01)
	b.add_theme_color_override("font_color", dark)
	b.add_theme_color_override("font_hover_color", dark)
	b.add_theme_color_override("font_pressed_color", Color(0.3, 0.17, 0.02))
	b.add_theme_color_override("font_disabled_color", Color(0.45, 0.40, 0.30))
	b.add_theme_stylebox_override("normal", UISkin.button("primary", "normal", 12))
	b.add_theme_stylebox_override("hover", UISkin.button("primary", "hover", 12))
	b.add_theme_stylebox_override("pressed", UISkin.button("primary", "pressed", 12))
	b.add_theme_stylebox_override("disabled", UISkin.button("primary", "disabled", 12))
	return b

## Nút nguy hiểm (đỏ).
static func button_danger(text: String, min_size: Vector2 = Vector2(0, 40)) -> Button:
	var b := button(text, min_size)
	b.add_theme_stylebox_override("normal", UISkin.button("danger", "normal", 10))
	b.add_theme_stylebox_override("hover", UISkin.button("danger", "hover", 10))
	b.add_theme_stylebox_override("pressed", UISkin.button("danger", "pressed", 10))
	return b

## Nút phụ dạng chữ, không khung (liên kết).
static func button_link(text: String) -> Button:
	var b := button(text, Vector2(0, 36))
	var e := StyleBoxEmpty.new()
	for st in ["normal", "hover", "pressed", "disabled"]:
		b.add_theme_stylebox_override(st, e)
	b.add_theme_color_override("font_color", C_MUTED)
	b.add_theme_color_override("font_hover_color", C_GOLD)
	b.add_theme_color_override("font_pressed_color", C_GOLD)
	b.add_theme_font_size_override("font_size", FS_S)
	return b

## Nút tròn có icon (menu, chat, đóng...). gold = viền vàng.
static func icon_button(icon_name: String, size: float = 44.0, tint: Color = C_TEXT, gold: bool = false) -> Button:
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(size, size)
	var sz := int(size)
	b.add_theme_stylebox_override("normal", UISkin.round_button(sz, "normal", gold))
	b.add_theme_stylebox_override("hover", UISkin.round_button(sz, "hover", gold))
	b.add_theme_stylebox_override("pressed", UISkin.round_button(sz, "pressed", gold))
	b.icon = icon(icon_name)
	b.expand_icon = true
	b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
	b.add_theme_color_override("icon_normal_color", C_GOLD if gold else tint)
	b.add_theme_color_override("icon_hover_color", Color.WHITE)
	b.add_theme_color_override("icon_pressed_color", C_GOLD)
	b.add_theme_constant_override("icon_max_width", int(size * 0.5))
	return b

static func section(title: String) -> Label:
	var l := label(title, FS_L, C_GOLD, true)
	return l

static func row(text: String, color: Color = C_TEXT, size: int = FS_M) -> Label:
	return label(text, size, color)

static func hsep(color: Color = C_BORDER) -> HSeparator:
	var s := HSeparator.new()
	s.add_theme_stylebox_override("separator", sb(Color(color, 0.45), Color(0, 0, 0, 0), 0, 0, 0))
	s.add_theme_constant_override("separation", 2)
	s.custom_minimum_size = Vector2(0, 2)
	return s

static func quality_color(q: int) -> Color:
	if q >= 5: return Color(1.00, 0.66, 0.20)
	if q >= 4: return C_PURPLE
	if q >= 3: return C_BLUE
	if q >= 2: return C_GREEN
	return C_MUTED

# ------------------------------------------------------------------ Phân cấp chữ / tiêu đề
## Nhãn nhỏ kiểu "overline" (ví dụ: "THANH KỸ NĂNG", "MỤC TIÊU") — chữ hoa, giãn khoảng, mờ.
static func overline(text: String, color: Color = C_BRASS) -> Label:
	var l := label(text.to_upper(), FS_S, color, true)
	l.autowrap_mode = TextServer.AUTOWRAP_OFF
	l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

## Tiêu đề mục có vạch đồng ngắn bên trái — dùng thay cho section() ở panel cần nhịp rõ.
static func heading(text: String, color: Color = C_GOLD) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	h.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.custom_minimum_size = Vector2(0, 20)
	var bar := ColorRect.new()
	bar.color = color
	bar.custom_minimum_size = Vector2(3, 16)
	bar.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(bar)
	var l := label(text, FS_L, color, true)
	l.autowrap_mode = TextServer.AUTOWRAP_OFF
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(l)
	return h

## Giá trị số lớn (stats, tiền) — căn phải tuỳ chọn.
static func stat_value(text: String, color: Color = C_TEXT, align: int = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l := label(text, FS_XL, color, true)
	l.horizontal_alignment = align
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l