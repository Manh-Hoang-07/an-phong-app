extends Control
## Nút tròn hành động của HUD cảm ứng (kỹ năng, Đánh, Nhảy, bình...).

const T := preload("res://src/ui/UITheme.gd")

signal pressed()
var radius := 30.0
var fill := Color(0.06, 0.09, 0.16, 0.78)
var ring := Color(0.55, 0.68, 0.92, 0.85)
var usable := true
var big := false
var glow := false
var _glow_t := 0.0
var glyph: Label
var icon: TextureRect
var _down := false
var _touch := -1
var _cd_total := 0.0
var _cd_end := 0
var _cd: Control
var _redraw_acc := 0.0

func setup(r: float, ring_color: Color) -> void:
	radius = r
	ring = ring_color
	custom_minimum_size = Vector2(r * 2.0, r * 2.0)
	size = custom_minimum_size
	mouse_filter = Control.MOUSE_FILTER_STOP
	pivot_offset = Vector2(r, r)
	glyph = Label.new()
	glyph.set_anchors_preset(Control.PRESET_FULL_RECT)
	glyph.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	glyph.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glyph.autowrap_mode = TextServer.AUTOWRAP_OFF
	glyph.add_theme_font_size_override("font_size", int(r * 0.9))
	add_child(glyph)
	icon = TextureRect.new()
	icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var pad := r * 0.5
	icon.offset_left = pad; icon.offset_top = pad; icon.offset_right = -pad; icon.offset_bottom = -pad
	add_child(icon)
	_cd = Control.new()
	_cd.set_anchors_preset(Control.PRESET_FULL_RECT)
	_cd.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cd.draw.connect(_draw_cd)
	add_child(_cd)

var _badge: Label = null

func set_badge(text: String) -> void:
	if _badge == null:
		_badge = Label.new()
		_badge.add_theme_font_size_override("font_size", 13)
		_badge.add_theme_color_override("font_color", Color.WHITE)
		_badge.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
		_badge.add_theme_constant_override("outline_size", 4)
		_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_badge.autowrap_mode = TextServer.AUTOWRAP_OFF
		_badge.size = Vector2(radius * 2.0, 16.0)
		_badge.position = Vector2(0.0, radius * 2.0 - 17.0)   # căn giữa, sát đáy nút
		_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_badge)
	_badge.text = text

var _art: Control = null

func set_glyph(text: String) -> void:
	if _art != null:
		_art.queue_free(); _art = null
	if text.begins_with("@"):
		glyph.visible = false
		_art = T.GlyphArt.make(text, radius * 1.15)
		_art.set_anchors_preset(Control.PRESET_FULL_RECT)
		var pd := radius * 0.42
		_art.offset_left = pd; _art.offset_top = pd; _art.offset_right = -pd; _art.offset_bottom = -pd
		add_child(_art)
		return
	glyph.text = T.GlyphArt.clean(text)
	glyph.visible = not text.is_empty()

func start_cooldown(seconds: float) -> void:
	if seconds <= 0.0: return
	_cd_total = seconds
	_cd_end = Time.get_ticks_msec() + int(seconds * 1000.0)
	set_process(true)

func _ready() -> void:
	set_process(false)

var _ready_until := 0

func set_glow(on: bool) -> void:
	glow = on
	if on: set_process(true)
	queue_redraw()

func _process(_d: float) -> void:
	var now := Time.get_ticks_msec()
	if _cd_total > 0.0 and now >= _cd_end:
		_cd_total = 0.0
		_ready_until = now + 450
	if glow:
		_glow_t += _d
	elif _cd_total <= 0.0 and now >= _ready_until:
		set_process(false)
	# 30 lần/giây là đủ cho vòng quét cooldown; thời gian vẫn đếm bằng msec nên số hiển thị đúng.
	_redraw_acc += _d
	if _redraw_acc >= 1.0 / 30.0:
		_redraw_acc = 0.0
		queue_redraw()
		_cd.queue_redraw()

func set_usable(v: bool) -> void:
	if usable == v: return
	usable = v
	modulate = Color(1, 1, 1, 1) if v else Color(0.55, 0.55, 0.62, 0.85)

func _draw() -> void:
	var c := Vector2(radius, radius)
	var r := radius
	if glow:
		var pulse := 0.5 + 0.5 * sin(_glow_t * 6.0)
		draw_arc(c, r + 3.0 + pulse * 3.0, 0.0, TAU, 64, Color(ring, 0.35 + 0.35 * pulse), 3.0, true)
		draw_circle(c, r + 2.0, Color(ring, 0.12 + 0.1 * pulse))
	draw_circle(c + Vector2(0, 2.0), r, Color(0, 0, 0, 0.5))                           # bóng đổ
	draw_circle(c, r - 0.5, Color(0.01, 0.01, 0.03, 1.0))                              # viền ngoài tối
	# vành kim loại: nền tối, nửa trên sáng, nửa dưới tối hơn
	draw_arc(c, r - 2.6, 0.0, TAU, 72, ring.darkened(0.5), 3.8, true)
	draw_arc(c, r - 2.6, PI * 1.02, PI * 1.98, 40, ring.lightened(0.3), 3.8, true)
	draw_arc(c, r - 2.6, PI * 0.12, PI * 0.88, 28, ring.darkened(0.65), 3.2, true)
	if big: draw_arc(c, r - 6.6, 0.0, TAU, 64, Color(ring, 0.55), 1.4, true)           # vành phụ (nút Đánh)
	draw_arc(c, r - 5.2, 0.0, TAU, 64, Color(0, 0, 0, 0.65), 1.2, true)                # khe tối trong
	# thân: các vòng tròn đồng tâm tối -> sáng, tâm lệch lên trên cho cảm giác nổi khối
	var inner := r - 5.8
	var lit := fill.lightened(0.18 if _down else 0.0)
	for i in range(9):
		var t := float(i) / 8.0
		var rad := inner * (1.0 - t * 0.74)
		var col := lit.darkened(0.45).lerp(lit.lightened(0.28), t)
		draw_circle(c + Vector2(0, -t * inner * 0.2), rad, Color(col, 0.97))
	draw_arc(c, inner - 1.5, PI * 1.14, PI * 1.86, 24, Color(1, 1, 1, 0.26), 2.0, true) # vệt sáng

func _draw_cd() -> void:
	var now_ms := Time.get_ticks_msec()
	if _cd_total <= 0.0 and now_ms < _ready_until:
		var k := float(_ready_until - now_ms) / 450.0
		_cd.draw_arc(Vector2(radius, radius), radius - 1.0 + (1.0 - k) * 6.0, 0.0, TAU, 40, Color(1, 0.95, 0.6, k), 3.0, true)
		return
	if _cd_total <= 0.0: return
	var left := float(_cd_end - Time.get_ticks_msec()) / 1000.0
	if left <= 0.0: return
	var frac := clampf(left / _cd_total, 0.0, 1.0)
	var c := Vector2(radius, radius)
	var pts := PackedVector2Array([c])
	var a0 := -PI * 0.5
	var a1 := a0 + TAU * frac
	var steps := maxi(4, int(40.0 * frac))
	for i in range(steps + 1):
		var a := a0 + (a1 - a0) * float(i) / float(steps)
		pts.append(c + Vector2(cos(a), sin(a)) * (radius - 2.0))
	_cd.draw_colored_polygon(pts, Color(0, 0, 0, 0.62))
	_cd.draw_string(UITheme_font(), Vector2(0, radius + radius * 0.22), "%.1f" % left if left < 10.0 else str(int(ceil(left))),
		HORIZONTAL_ALIGNMENT_CENTER, radius * 2.0, int(radius * 0.62) + 2, Color(1, 1, 1, 0.95))

static func UITheme_font() -> Font:
	return preload("res://src/ui/UITheme.gd").font(true)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var lp: Vector2 = event.position
		var inside: bool = (lp - Vector2(radius, radius)).length() <= radius + 6.0
		if event.pressed and _touch == -1 and inside:
			_touch = event.index
			_set_down(true)
			pressed.emit()
			accept_event()
		elif not event.pressed and event.index == _touch:
			_touch = -1
			_set_down(false)
			accept_event()
	elif event is InputEventScreenDrag and event.index == _touch:
		accept_event()

func _set_down(v: bool) -> void:
	_down = v
	scale = Vector2(0.92, 0.92) if v else Vector2.ONE
	queue_redraw()
