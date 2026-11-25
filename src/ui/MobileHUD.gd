extends CanvasLayer
## HUD cảm ứng (điện thoại, ngang). Không chứa luật chơi — chỉ phát tín hiệu cho World và dựng panel qua GamePanels.
##
## Bố cục (viewport ~960x432, có safe area):
##   trái-trên: avatar + tên + HP/MP/STA     giữa-trên: nhiệm vụ     phải-trên: tên map, chat, menu
##   trái-dưới: log chat + joystick động     phải-dưới: nút Đánh lớn + vòng 5 kỹ năng + nút Nhảy
##   đáy: thanh EXP mảnh toàn chiều rộng
## Mọi điều khiển game dùng InputEventScreenTouch/Drag (đa điểm); nút panel dùng chuột giả lập từ cảm ứng.

signal move_vector(dir: Vector2)
signal skill_pressed(index: int)
signal attack_pressed()
signal jump_pressed()
signal menu_pressed(tab: String)
signal chat_sent(text: String)
signal interact_pressed()
signal potion_pressed(kind: String)
signal form_pressed()
signal seal_pressed()
signal death_choice(where: String)

const T := preload("res://src/ui/UITheme.gd")
const TouchScroll := preload("res://src/ui/TouchScroll.gd")
const GP := preload("res://src/ui/GamePanels.gd")
const W := preload("res://src/ui/PanelWidgets.gd")
const NpcDialog := preload("res://src/ui/NpcDialog.gd")

# Panel chính (hiện trong ngăn kéo bên phải)
const TABS := ["bag", "equip", "char", "skills", "quest", "mount", "companion", "shadows",
	"map", "shop", "smith", "storage", "teleport", "daily", "npc", "code", "school", "gate", "config", "social", "trade", "kynguyen", "form"]
const TAB_LABELS := {
	"bag": "Túi", "equip": "Trang bị", "char": "Nhân vật", "skills": "Kỹ năng", "quest": "Nhiệm vụ",
	"mount": "Linh thú", "companion": "Thú cưng", "shadows": "Bóng ma", "map": "Bản đồ",
	"shop": "Cửa hàng", "smith": "Lò rèn", "storage": "Kho", "teleport": "Dịch chuyển",
	"daily": "Nhiệm vụ ngày", "npc": "NPC", "code": "Mật mã", "school": "Class", "gate": "Cổng", "config": "Cài đặt",
	"social": "Xã hội", "trade": "Giao dịch", "kynguyen": "Kỳ Nguyên", "form": "Biến hình"
}
const TAB_ICONS := {
	"bag": "bag", "equip": "equip", "char": "char", "skills": "skills", "quest": "quest",
	"mount": "pet", "companion": "pet", "shadows": "social", "map": "map",
	"shop": "shop", "smith": "anvil", "storage": "storage", "teleport": "portal",
	"daily": "quest", "npc": "chat", "code": "quest", "school": "char", "gate": "portal", "config": "gear",
	"social": "social", "trade": "bag", "kynguyen": "star", "form": "flame"
}
# Lưới menu chính (8 mục) + hàng dịch vụ (tạm thời cho tới khi chạm NPC trên bản đồ).
const RAIL_SHORT := {"bag": "Túi", "equip": "Trang bị", "char": "Nhân vật", "skills": "Kỹ năng", "quest": "Nhiệm vụ", "map": "Bản đồ", "social": "Xã hội", "kynguyen": "Kỳ Nguyên", "companion": "Thú cưng", "config": "Cài đặt"}
const RAIL_TABS := ["bag", "equip", "char", "skills", "quest", "map", "social", "companion", "config"]
const MENU_MAIN := ["bag", "equip", "char", "skills", "quest", "map", "social", "companion", "config"]
const MENU_MORE := []
const MENU_SERVICES := ["shop", "smith", "storage", "teleport", "npc", "code", "gate"]

const MENU_TILE_H := 76.0   # chiều cao ô menu dưới đáy
const MENU_TILE_W := 100.0
const JOY_R := 54.0
const SKILL_R := 25.0      # 4 kỹ năng thường (hàng ngang dưới màn)
const ULT_R := 29.0        # kỹ năng đặc biệt (cạnh nút Đánh)
const ATTACK_R := 40.0
const JUMP_R := 23.0

# ---------------------------------------------------------------- Nút tròn hành động
class ActionButton extends Control:
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
			queue_redraw()
		elif _cd_total <= 0.0 and now >= _ready_until:
			set_process(false)
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

# ---------------------------------------------------------------- Trạng thái
var _root: Control = null
var _inset := Vector4(14, 8, 14, 8)

# HUD trái-trên
var _avatar_holder: Control = null
var _portrait: TextureRect = null
var _portrait_school := ""
var _lv_badge: Label = null
var _name_label: Label = null
var _hp_bar: ProgressBar = null
var _hp_text: Label = null
var _mp_text: Label = null
var _sta_text: Label = null
var _mp_bar: ProgressBar = null
var _sta_bar: ProgressBar = null
var _exp_bar: ProgressBar = null
# giữa/phải-trên
var _quest_btn: Button = null
var _map_label: Label = null
# joystick
var _joy_zone: Control = null
var _joy_ring: Panel = null
var _joy_knob: Panel = null
var _joy_touch := -1
var _joy_center := Vector2.ZERO
var _joy_idle := Vector2.ZERO
# nút hành động
var _skill_buttons: Array = []
var _attack_btn: ActionButton = null
var _jump_btn: ActionButton = null
var _form_btn: ActionButton = null
var _seal_btn: ActionButton = null
# log / chat / toast
var _log: RichTextLabel = null
var _log_lines: Array = []   # [{text, color, at}]
var _chat_bar: Control = null
var _chat: LineEdit = null
var _toast_panel: PanelContainer = null
var _toast: Label = null
var _toast_tween: Tween = null
var _interact_btn: Button = null
var _death_layer: Control = null
var _banner: Label = null
var _banner_tween: Tween = null
var _flash: ColorRect = null
var _busy_bar: ProgressBar = null
var _potion_hp: ActionButton = null
var _potion_mp: ActionButton = null
var _dialog: Control = null
var _vignette: TextureRect = null
var _low_hp_tween: Tween = null
# menu + panel
var _menu_layer: Control = null
var _menu_scroll: TouchScroll = null
var _panel_layer: Control = null
var _panel: PanelContainer = null
var _panel_scroll: ScrollContainer = null
var _panel_body: VBoxContainer = null
var _panel_fixed: VBoxContainer = null
var _rail_buttons: Dictionary = {}
var _rail_scroll: ScrollContainer = null
var _panel_w := 560.0
var _open_tab := ""
var _open_extra: Dictionary = {}
var _panels: GP = null

func _ready() -> void:
	layer = 10   # CanvasLayer lồng trong node layer 10 vẫn có chỉ số riêng; phải nằm trên lớp thời tiết
	_panels = GP.new(self)
	_build()
	get_viewport().size_changed.connect(_layout)
	set_process(true)

func _process(_delta: float) -> void:
	# Dòng log tự mờ/biến mất sau 9 giây.
	if _log_lines.is_empty(): return
	var now := Time.get_ticks_msec()
	var changed := false
	while not _log_lines.is_empty() and now - int(_log_lines[0]["at"]) > 14000:
		_log_lines.pop_front()
		changed = true
	if changed: _render_log()

# ---------------------------------------------------------------- Dựng giao diện
func _build() -> void:
	_inset = _calc_inset()
	_root = Control.new()
	_root.name = "Root"
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.theme = T.make_theme()
	_root.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(_root)

	_build_joystick()
	_build_top_left()
	_build_buffs()
	_build_top_right()
	_build_actions()
	_build_log_and_chat()
	_build_toast()
	_build_screen_fx()
	_build_interact()
	_build_banner()
	_build_menu()
	_build_panel()
	_build_death()
	_build_invite()
	_build_dialog()
	_build_confirm()
	_build_net_status()
	_layout()
	Social.changed.connect(_on_social_changed)
	Social.invited.connect(_on_invited)
	Social.trade_ended.connect(_on_trade_ended)

## Khoảng cách tới mép màn hình: sát góc, chỉ chừa một phần nhỏ vùng an toàn (tai thỏ / bo góc).
func _calc_inset() -> Vector4:
	var s := T.safe_insets(get_viewport(), 0.0)
	return Vector4(maxf(3.0, s.x * 0.35), maxf(3.0, s.y * 0.5), maxf(3.0, s.z * 0.35), maxf(3.0, s.w * 0.4))

func _anchor_rect(c: Control, preset: int, x: float, y: float, w: float, h: float) -> void:
	## Đặt control theo góc (preset) với vị trí x,y tính từ góc đó (x,y dương = vào trong).
	c.set_anchors_preset(preset)
	match preset:
		Control.PRESET_TOP_LEFT:
			c.offset_left = x; c.offset_top = y; c.offset_right = x + w; c.offset_bottom = y + h
		Control.PRESET_TOP_RIGHT:
			c.offset_right = -x; c.offset_top = y; c.offset_left = -x - w; c.offset_bottom = y + h
		Control.PRESET_BOTTOM_LEFT:
			c.offset_left = x; c.offset_bottom = -y; c.offset_right = x + w; c.offset_top = -y - h
		Control.PRESET_BOTTOM_RIGHT:
			c.offset_right = -x; c.offset_bottom = -y; c.offset_left = -x - w; c.offset_top = -y - h
		Control.PRESET_CENTER_TOP:
			c.offset_left = -w * 0.5; c.offset_right = w * 0.5; c.offset_top = y; c.offset_bottom = y + h

func _build_top_left() -> void:
	var box := HBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 6)
	_anchor_rect(box, Control.PRESET_TOP_LEFT, _inset.x, _inset.y, 232, 70)
	_root.add_child(box)
	# Chân dung + cấp độ
	_avatar_holder = Control.new()
	_avatar_holder.custom_minimum_size = Vector2(46, 46)
	_avatar_holder.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_avatar_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(_avatar_holder)
	var frame := Panel.new()
	frame.set_anchors_preset(Control.PRESET_FULL_RECT)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_theme_stylebox_override("panel", T.UISkin.slot(5))
	_avatar_holder.add_child(frame)
	_portrait = TextureRect.new()
	_portrait.set_anchors_preset(Control.PRESET_FULL_RECT)
	_portrait.offset_left = 3; _portrait.offset_top = 3; _portrait.offset_right = -3; _portrait.offset_bottom = -3
	_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_avatar_holder.add_child(_portrait)
	var badge := PanelContainer.new()
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.add_theme_stylebox_override("panel", T.sb(T.C_GOLD, T.C_GOLD_DK, 1, 9, 0))
	badge.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	badge.offset_left = -20; badge.offset_top = -13; badge.offset_right = 4; badge.offset_bottom = 3
	_avatar_holder.add_child(badge)
	_lv_badge = T.label("1", 10, Color(0.14, 0.09, 0.02), true)
	_lv_badge.autowrap_mode = TextServer.AUTOWRAP_OFF
	_lv_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.add_child(_lv_badge)

	# Cột phải: khung chỉ số + dòng nhiệm vụ nhỏ
	var col := VBoxContainer.new()
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_theme_constant_override("separation", 3)
	box.add_child(col)
	var plate := PanelContainer.new()
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plate.add_theme_stylebox_override("panel", T.UISkin.plate(6))
	col.add_child(plate)
	var rows := VBoxContainer.new()
	rows.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rows.add_theme_constant_override("separation", 4)
	plate.add_child(rows)
	# Thanh kinh nghiệm mảnh, nằm ngay trên HP (thay cho thanh vàng dưới màn hình).
	_exp_bar = ProgressBar.new()
	_exp_bar.show_percentage = false
	_exp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_exp_bar.max_value = 100
	_exp_bar.custom_minimum_size = Vector2(150, 3)
	_exp_bar.add_theme_stylebox_override("fill", T.sb(T.C_GOLD, Color(0, 0, 0, 0), 0, 2, 0))
	_exp_bar.add_theme_stylebox_override("background", T.sb(Color(0, 0, 0, 0.45), Color(0, 0, 0, 0), 0, 2, 0))
	rows.add_child(_exp_bar)
	var hp_row := _stat_row("heart", T.C_RED, 15.0)
	_hp_bar = hp_row[0]; _hp_text = hp_row[1]
	rows.add_child(hp_row[2])
	var mp_row := _stat_row("drop", T.C_BLUE, 14.0)
	_mp_bar = mp_row[0]; _mp_text = mp_row[1]
	rows.add_child(mp_row[2])
	var sta_row := _stat_row("skills", Color(0.30, 0.92, 0.50), 14.0)
	_sta_bar = sta_row[0]; _sta_text = sta_row[1]
	rows.add_child(sta_row[2])
	# dòng nhiệm vụ: một dòng nhỏ dưới khung chỉ số
	_quest_btn = Button.new()
	_quest_btn.focus_mode = Control.FOCUS_NONE
	_quest_btn.flat = true
	_quest_btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	_quest_btn.clip_text = true
	_quest_btn.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_quest_btn.custom_minimum_size = Vector2(200, 26)
	_quest_btn.icon = T.icon("flag")
	_quest_btn.expand_icon = true
	_quest_btn.add_theme_constant_override("icon_max_width", 16)
	_quest_btn.add_theme_constant_override("h_separation", 5)
	_quest_btn.add_theme_font_size_override("font_size", 14)
	_quest_btn.add_theme_font_override("font", T.font(false))
	_quest_btn.add_theme_color_override("font_color", Color(1.0, 0.9, 0.6))
	_quest_btn.add_theme_color_override("font_hover_color", Color.WHITE)
	_quest_btn.add_theme_color_override("font_pressed_color", T.C_GOLD)
	_quest_btn.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	_quest_btn.add_theme_constant_override("outline_size", 4)
	_quest_btn.add_theme_color_override("icon_normal_color", T.C_GOLD)
	var qsb := T.sb(Color(0.03, 0.05, 0.1, 0.62), Color(T.C_GOLD, 0.45), 1, 10, 8)
	for st in ["normal", "hover", "pressed"]:
		_quest_btn.add_theme_stylebox_override(st, qsb)
	_quest_btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	_quest_btn.text = "Nhiệm vụ: chưa nhận"
	_quest_btn.pressed.connect(func(): open_panel("quest"))
	col.add_child(_quest_btn)

## Một hàng chỉ số: icon nhỏ + thanh (có số trong thanh nếu đủ cao). Trả [bar, text_label, row].
func _stat_row(icon_name: String, color: Color, h: float) -> Array:
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 5)
	var ic := T.icon_rect(icon_name, 13.0, color)
	ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(ic)
	var bar := _make_bar(color, h)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(bar)
	var txt: Label = null
	if h >= 12.0:
		txt = T.hud_label("0 / 0", 10 if h < 13.0 else (11 if h < 16.0 else 12), Color.WHITE, true)
		txt.set_anchors_preset(Control.PRESET_FULL_RECT)
		txt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		txt.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		txt.add_theme_constant_override("outline_size", 3)
		bar.add_child(txt)
	return [bar, txt, row]

func _make_bar(color: Color, h: float) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.min_value = 0; bar.max_value = 100; bar.value = 100
	bar.custom_minimum_size = Vector2(176, h)
	bar.show_percentage = false
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_theme_stylebox_override("fill", T.UISkin.bar_fill(color))
	bar.add_theme_stylebox_override("background", T.UISkin.bar_frame())
	return bar

func _build_top_right() -> void:
	var box := HBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 8)
	box.alignment = BoxContainer.ALIGNMENT_END
	_anchor_rect(box, Control.PRESET_TOP_RIGHT, _inset.z, _inset.y, 300, 46)
	_root.add_child(box)
	var chat_btn := T.icon_button("chat", 46)
	chat_btn.pressed.connect(_toggle_chat)
	box.add_child(chat_btn)
	var menu_btn := T.icon_button("menu", 46, T.C_GOLD, true)
	menu_btn.pressed.connect(_toggle_menu)
	box.add_child(menu_btn)

func _build_joystick() -> void:
	_joy_zone = Control.new()
	_joy_zone.name = "JoyZone"
	_joy_zone.set_anchors_preset(Control.PRESET_FULL_RECT)
	_joy_zone.anchor_right = 0.46
	_joy_zone.anchor_top = 0.22
	_joy_zone.offset_left = 0; _joy_zone.offset_top = 0; _joy_zone.offset_right = 0; _joy_zone.offset_bottom = 0
	_joy_zone.mouse_filter = Control.MOUSE_FILTER_STOP
	_joy_zone.gui_input.connect(_on_joy_input)
	_joy_zone.resized.connect(_layout_joy)
	_root.add_child(_joy_zone)
	_joy_ring = Panel.new()
	_joy_ring.size = Vector2(JOY_R * 2.0, JOY_R * 2.0)
	_joy_ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_joy_ring.add_theme_stylebox_override("panel", T.sb(Color(0.08, 0.10, 0.17, 0.35), Color(0.62, 0.74, 0.96, 0.7), 2, int(JOY_R), 0))
	_joy_zone.add_child(_joy_ring)
	_joy_knob = Panel.new()
	_joy_knob.size = Vector2(46, 46)
	_joy_knob.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_joy_knob.add_theme_stylebox_override("panel", T.sb(Color(0.62, 0.76, 0.98, 0.9), T.C_GOLD, 2, 23, 0))
	_joy_zone.add_child(_joy_knob)

func _layout_joy() -> void:
	if _joy_zone == null or _joy_knob == null or _joy_touch != -1: return
	var zs := _joy_zone.size
	_joy_idle = Vector2(_inset.x + 18.0 + JOY_R, zs.y - _inset.w - 18.0 - JOY_R)
	_set_joy_visual(_joy_idle, Vector2.ZERO, 0.45)

func _set_joy_visual(center: Vector2, d: Vector2, alpha: float) -> void:
	_joy_ring.position = center - Vector2(JOY_R, JOY_R)
	_joy_knob.position = center + d - _joy_knob.size * 0.5
	_joy_ring.modulate.a = alpha
	_joy_knob.modulate.a = clampf(alpha + 0.2, 0.0, 1.0)

func _on_joy_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and _joy_touch == -1:
			_joy_touch = event.index
			_joy_center = event.position
			_set_joy_visual(_joy_center, Vector2.ZERO, 1.0)
			accept_event_safe()
		elif not event.pressed and event.index == _joy_touch:
			_joy_touch = -1
			_set_joy_visual(_joy_idle, Vector2.ZERO, 0.45)
			move_vector.emit(Vector2.ZERO)
	elif event is InputEventScreenDrag and event.index == _joy_touch:
		var d: Vector2 = event.position - _joy_center
		if d.length() > JOY_R: d = d.normalized() * JOY_R
		_set_joy_visual(_joy_center, d, 1.0)
		var v := d / JOY_R
		if v.length() < 0.18: v = Vector2.ZERO   # vùng chết nhỏ, tránh trôi
		move_vector.emit(v)

func accept_event_safe() -> void:
	if _joy_zone: _joy_zone.accept_event()

func _build_actions() -> void:
	# Bố cục góc phải-dưới, tâm nút Đánh (A) sát góc; các nút còn lại xếp cung tròn quanh A, không chồng nhau.
	var cx := -(_inset.z + ATTACK_R + 2.0)
	var cy := -(_inset.w + ATTACK_R + 2.0)
	_attack_btn = ActionButton.new()
	_attack_btn.setup(ATTACK_R, Color(1.0, 0.82, 0.36))
	_attack_btn.big = true
	_attack_btn.fill = Color(0.62, 0.15, 0.10, 1.0)
	_attack_btn.icon.texture = T.icon("sword")
	_attack_btn.icon.modulate = Color(1.0, 0.95, 0.8)
	_attack_btn.icon.offset_left = ATTACK_R * 0.4; _attack_btn.icon.offset_top = ATTACK_R * 0.4
	_attack_btn.icon.offset_right = -ATTACK_R * 0.4; _attack_btn.icon.offset_bottom = -ATTACK_R * 0.4
	_attack_btn.pressed.connect(func(): attack_pressed.emit())
	_place_br(_attack_btn, cx, cy, ATTACK_R)
	_root.add_child(_attack_btn)

	# Nhảy: dùng cần di chuyển (kéo lên), không còn nút riêng. Giữ biến để tương thích.
	_jump_btn = null

	# 5 kỹ năng thường (ô 0-4 của server): hàng ngang giữa-dưới, sát đáy màn hình
	var row_y := -(_inset.w + SKILL_R + 1.0)
	for i in range(5):
		var b := _make_skill_button(i, SKILL_R, false)
		_place_bc(b, (float(i) - 2.0) * (SKILL_R * 2.0 + 10.0), row_y, SKILL_R)
		_root.add_child(b)
		_skill_buttons.append(b)
	# 3 ô tuyệt kỹ / tuyệt phẩm (ô 5, 6, 7 của server) xếp cung quanh nút Đánh
	var ult_pos := [Vector2(-80.0, 8.0), Vector2(-58.0, -52.0), Vector2(0.0, -80.0)]
	for k in range(3):
		var u := _make_skill_button(5 + k, ULT_R, true)
		_place_br(u, cx + (ult_pos[k] as Vector2).x, cy + (ult_pos[k] as Vector2).y, ULT_R)
		_root.add_child(u)
		_skill_buttons.append(u)
	# Kỹ năng do trang bị cấp (ô 8): nối tiếp hàng kỹ năng thường, chỉ hiện khi đang mặc món có kỹ năng
	var gear := _make_skill_button(8, SKILL_R, false)
	gear.ring = Color(0.45, 0.92, 0.7)
	_place_bc(gear, 3.0 * (SKILL_R * 2.0 + 10.0), row_y, SKILL_R)
	gear.visible = false
	_root.add_child(gear)
	_skill_buttons.append(gear)
	# Biến hình (chỉ hiện khi đã mở khóa Ấn) và nút đổi ấn nhỏ phía trên
	_form_btn = ActionButton.new()
	_form_btn.setup(26.0, Color(1.0, 0.62, 0.25))
	_form_btn.fill = Color(0.30, 0.12, 0.06, 1.0)
	_form_btn.icon.texture = T.icon("flame")
	_form_btn.icon.modulate = Color(1.0, 0.85, 0.5)
	_form_btn.visible = false
	_form_btn.pressed.connect(func(): form_pressed.emit())
	_place_br(_form_btn, cx - 112.0, cy - 72.0, 26.0)
	_root.add_child(_form_btn)
	_seal_btn = ActionButton.new()
	_seal_btn.setup(14.0, Color(0.8, 0.7, 1.0))
	_seal_btn.fill = Color(0.16, 0.10, 0.26, 1.0)
	_seal_btn.icon.visible = false
	_seal_btn.set_glyph("I")
	_seal_btn.glyph.add_theme_font_size_override("font_size", 12)
	_seal_btn.visible = false
	_seal_btn.pressed.connect(func(): seal_pressed.emit())
	_place_br(_seal_btn, cx - 118.0, cy - 116.0, 14.0)
	_root.add_child(_seal_btn)
	# Bình máu / MP nhanh: hàng dưới, bên trái các nút tuyệt kỹ
	_potion_hp = _make_potion_button("hp", Color(0.94, 0.34, 0.38), cx - 140.0, cy + 22.0)
	_potion_mp = _make_potion_button("mp", Color(0.38, 0.66, 1.0), cx - 186.0, cy + 22.0)

func _make_skill_button(i: int, r: float, special: bool) -> ActionButton:
	var b := ActionButton.new()
	b.setup(r, Color(1.0, 0.82, 0.36) if special else Color(0.55, 0.68, 0.92))
	b.big = special
	b.fill = Color(0.18, 0.12, 0.26, 1.0) if special else Color(0.09, 0.14, 0.26, 1.0)
	b.icon.visible = false
	b.set_glyph("·")
	var idx := i
	b.pressed.connect(func(): skill_pressed.emit(idx))
	return b

## Đặt tâm control tại (dx, cy): dx tính từ giữa màn hình, cy tính từ đáy (âm = vào trong).
func _place_bc(c: Control, dx: float, cy: float, r: float) -> void:
	c.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	c.offset_left = dx - r; c.offset_right = dx + r
	c.offset_top = cy - r; c.offset_bottom = cy + r

func _place_br(c: Control, cx: float, cy: float, r: float) -> void:
	## Đặt tâm control tại (cx, cy) tính từ góc phải-dưới (giá trị âm = vào trong màn hình).
	c.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	c.offset_left = cx - r; c.offset_right = cx + r
	c.offset_top = cy - r; c.offset_bottom = cy + r

func _build_log_and_chat() -> void:
	_log = RichTextLabel.new()
	_log.bbcode_enabled = true
	_log.scroll_active = false
	_log.fit_content = true
	_log.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_log.add_theme_font_size_override("normal_font_size", T.FS_S)
	_log.add_theme_font_override("normal_font", T.font(false))
	_log.add_theme_font_override("bold_font", T.font(true))
	_log.add_theme_constant_override("outline_size", 4)
	_log.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.75))
	# Nằm DƯỚI thẻ HP/MP (trước đây y=82 bị thẻ che nên tin chat mới không thấy).
	_anchor_rect(_log, Control.PRESET_TOP_LEFT, _inset.x + 4, _inset.y + 156, 300, 120)
	_root.add_child(_log)

	# Thanh chat: bật bằng nút chat, hiện ở giữa-trên.
	var bar := PanelContainer.new()
	bar.visible = false
	bar.add_theme_stylebox_override("panel", T.UISkin.panel(8))
	_anchor_rect(bar, Control.PRESET_CENTER_TOP, 0, _inset.y + 44, 420, 58)
	_root.add_child(bar)
	_chat_bar = bar
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 8)
	bar.add_child(hb)
	_chat = LineEdit.new()
	_chat.placeholder_text = "Chat… (/map, /shop, /npc)"
	_chat.custom_minimum_size = Vector2(0, 42)
	_chat.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_chat.text_submitted.connect(func(_t): _send_chat())
	hb.add_child(_chat)
	var send := T.button_primary("Gửi", Vector2(72, 42))
	send.add_theme_font_size_override("font_size", T.FS_M)
	send.pressed.connect(_send_chat)
	hb.add_child(send)

func _toggle_chat() -> void:
	_chat_bar.visible = not _chat_bar.visible
	if _chat_bar.visible: _chat.grab_focus()
	else: _chat.release_focus()

func _send_chat() -> void:
	var t := _chat.text.strip_edges()
	if not t.is_empty(): chat_sent.emit(t)
	_chat.clear()
	_chat_bar.visible = false
	_chat.release_focus()

func _build_toast() -> void:
	_toast_panel = PanelContainer.new()
	_toast_panel.visible = false
	_toast_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast_panel.add_theme_stylebox_override("panel", T.UISkin.pill())
	_anchor_rect(_toast_panel, Control.PRESET_CENTER_TOP, 0, _inset.y + 50, 40, 36)
	_toast_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_root.add_child(_toast_panel)
	_toast = T.label("", T.FS_M, T.C_GOLD, true)
	_toast.autowrap_mode = TextServer.AUTOWRAP_OFF
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast_panel.add_child(_toast)


# ---------------------------------------------------------------- Menu (bảng điều khiển)
func _build_menu() -> void:
	_menu_layer = Control.new()
	_menu_layer.visible = false
	_menu_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_menu_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	_menu_layer.gui_input.connect(func(e):
		if e is InputEventMouseButton and e.pressed: _close_menu())
	_root.add_child(_menu_layer)
	var scrim := ColorRect.new()
	scrim.color = T.C_SCRIM
	scrim.set_anchors_preset(Control.PRESET_FULL_RECT)
	scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_menu_layer.add_child(scrim)

	# Thanh menu nằm sát đáy màn hình; vuốt ngang khi không đủ chỗ (không hiện thanh cuộn).
	_menu_scroll = TouchScroll.new()
	_menu_scroll.horizontal = true
	_menu_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	_menu_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_menu_scroll.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_menu_scroll.offset_left = _inset.x + 4.0; _menu_scroll.offset_right = -(_inset.z + 4.0)
	_menu_scroll.offset_bottom = -(_inset.w + 4.0); _menu_scroll.offset_top = -(_inset.w + 4.0 + MENU_TILE_H)
	_menu_scroll.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_menu_layer.add_child(_menu_scroll)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_menu_scroll.add_child(row)
	for tab in _menu_tabs():
		row.add_child(_menu_tile(tab))

## Tab trong menu: Linh thú chỉ cho Triệu Hồi Sư, Bóng ma chỉ cho Tử Linh Thuật Sư.
func _menu_tabs() -> Array:
	var school := str(Game.player.get("school", ""))
	var base := str(Data.school(school).get("base", school))
	var out: Array = MENU_MAIN.duplicate()
	out.append_array(MENU_MORE)
	if base == "trieu_hoi_su": out.append("mount")
	if base == "tu_linh_thuat_su": out.append("shadows")
	return out

func _menu_tile(tab: String) -> Button:
	var b := T.button(str(RAIL_SHORT.get(tab, TAB_LABELS.get(tab, tab))), Vector2(MENU_TILE_W, MENU_TILE_H))
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.size_flags_vertical = Control.SIZE_EXPAND_FILL
	b.add_theme_stylebox_override("normal", T.UISkin.tab(false))
	b.add_theme_stylebox_override("hover", T.UISkin.tab(true))
	b.add_theme_stylebox_override("pressed", T.UISkin.tab(true))
	b.add_theme_color_override("font_color", T.C_TEXT)
	b.add_theme_color_override("font_hover_color", T.C_GOLD)
	b.add_theme_color_override("font_pressed_color", T.C_GOLD)
	b.add_theme_font_size_override("font_size", 15)
	b.icon = T.icon(str(TAB_ICONS.get(tab, "menu")))
	b.expand_icon = true
	b.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.add_theme_constant_override("icon_max_width", 32)
	b.add_theme_constant_override("h_separation", 3)
	b.add_theme_color_override("icon_normal_color", T.C_TEXT)
	b.add_theme_color_override("icon_hover_color", T.C_GOLD)
	b.add_theme_color_override("icon_pressed_color", T.C_GOLD)
	b.autowrap_mode = TextServer.AUTOWRAP_OFF
	b.pressed.connect(func(): _close_menu(); open_panel(tab))
	return b

func _toggle_menu() -> void:
	if _menu_layer.visible: _close_menu()
	else:
		close_panel()
		_menu_layer.visible = true

func _close_menu() -> void:
	_menu_layer.visible = false

# ---------------------------------------------------------------- Panel (ngăn kéo bên phải)
func _build_panel() -> void:
	_panel_layer = Control.new()
	_panel_layer.visible = false
	_panel_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_panel_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	_panel_layer.gui_input.connect(func(e):
		if e is InputEventMouseButton and e.pressed: close_panel())
	_root.add_child(_panel_layer)
	var scrim := ColorRect.new()
	scrim.color = T.C_SCRIM
	scrim.set_anchors_preset(Control.PRESET_FULL_RECT)
	scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel_layer.add_child(scrim)

	_panel = PanelContainer.new()
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_panel.add_theme_stylebox_override("panel", T.UISkin.panel(12))
	_panel_layer.add_child(_panel)
	var outer := HBoxContainer.new()
	outer.add_theme_constant_override("separation", 0)
	_panel.add_child(outer)

	# ---- Thanh tab dọc bên trái (chuyển nhanh giữa các panel chính) ----
	var rail_bg := PanelContainer.new()
	rail_bg.add_theme_stylebox_override("panel", T.UISkin.inset(6))
	outer.add_child(rail_bg)
	_rail_scroll = TouchScroll.new()
	_rail_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_rail_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_rail_scroll.custom_minimum_size = Vector2(70, 0)
	rail_bg.add_child(_rail_scroll)
	var rail := VBoxContainer.new()
	rail.add_theme_constant_override("separation", 4)
	rail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_rail_scroll.add_child(rail)
	for tab in RAIL_TABS:
		var b := Button.new()
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(60, 46)
		b.text = str(RAIL_SHORT.get(tab, TAB_LABELS.get(tab, tab)))
		b.icon = T.icon(str(TAB_ICONS.get(tab, "menu")))
		b.expand_icon = true
		b.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		b.add_theme_constant_override("icon_max_width", 20)
		b.add_theme_constant_override("h_separation", 1)
		b.add_theme_font_size_override("font_size", 12)
		b.add_theme_font_override("font", T.font(true))
		b.add_theme_color_override("font_color", T.C_MUTED)
		b.add_theme_color_override("font_hover_color", T.C_GOLD)
		b.add_theme_color_override("font_pressed_color", T.C_GOLD)
		b.add_theme_color_override("icon_normal_color", T.C_MUTED)
		b.add_theme_color_override("icon_hover_color", T.C_GOLD)
		b.add_theme_color_override("icon_pressed_color", T.C_GOLD)
		b.tooltip_text = str(TAB_LABELS.get(tab, tab))
		var t: String = tab
		b.pressed.connect(func(): open_panel(t))
		_rail_buttons[tab] = b
		rail.add_child(b)

	# ---- Nội dung ----
	var content := MarginContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("margin_left", 12)
	content.add_theme_constant_override("margin_right", 12)
	content.add_theme_constant_override("margin_top", 6)
	content.add_theme_constant_override("margin_bottom", 10)
	outer.add_child(content)
	var pv := VBoxContainer.new()
	pv.add_theme_constant_override("separation", 6)
	content.add_child(pv)
	_busy_bar = ProgressBar.new()
	_busy_bar.custom_minimum_size = Vector2(0, 3)
	_busy_bar.show_percentage = false
	_busy_bar.max_value = 1.0
	_busy_bar.indeterminate = true
	_busy_bar.modulate.a = 0.0
	_busy_bar.add_theme_stylebox_override("background", StyleBoxEmpty.new())
	_busy_bar.add_theme_stylebox_override("fill", T.sb(T.C_GOLD, Color(0, 0, 0, 0), 0, 2, 0))
	pv.add_child(_busy_bar)
	Net.busy_changed.connect(func(b): if _busy_bar: create_tween().tween_property(_busy_bar, "modulate:a", 1.0 if b else 0.0, 0.15))
	# Nút X nằm đè lên góc viền phải-trên của khung, không chiếm chỗ của nội dung.
	var corner := Control.new()
	corner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(corner)
	var close := T.icon_button("close", 18)
	close.custom_minimum_size = Vector2(32, 32)
	close.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	close.offset_left = -18; close.offset_right = 14; close.offset_top = -14; close.offset_bottom = 18
	close.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	close.pressed.connect(close_panel)
	corner.add_child(close)
	_panel_scroll = TouchScroll.new()
	_panel_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_panel_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	pv.add_child(_panel_scroll)
	_panel_body = VBoxContainer.new()
	_panel_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_panel_body.add_theme_constant_override("separation", 8)
	_panel_scroll.add_child(_panel_body)
	# Chế độ "fill": panel tự quản cuộn (hai cột)
	_panel_fixed = VBoxContainer.new()
	_panel_fixed.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_panel_fixed.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_panel_fixed.visible = false
	pv.add_child(_panel_fixed)

func _update_rail() -> void:
	for tab in _rail_buttons.keys():
		var b: Button = _rail_buttons[tab]
		var active: bool = tab == _open_tab
		var n: StyleBox = T.UISkin.tab(active) if active else StyleBoxEmpty.new()
		b.add_theme_stylebox_override("normal", n)
		b.add_theme_stylebox_override("hover", n)
		b.add_theme_stylebox_override("pressed", n)
		b.add_theme_color_override("icon_normal_color", T.C_GOLD if active else T.C_MUTED)
		b.add_theme_color_override("font_color", T.C_GOLD if active else T.C_MUTED)
		if active and _rail_scroll: _rail_scroll.call_deferred("ensure_control_visible", b)
		b.add_theme_color_override("icon_hover_color", T.C_GOLD)
		b.add_theme_color_override("icon_pressed_color", T.C_GOLD)

func _layout() -> void:
	_inset = _calc_inset()
	var vp := get_viewport().get_visible_rect().size
	_panel_w = clampf(vp.x * 0.80, 480.0, 780.0)
	if _panel:
		_panel.set_anchors_preset(Control.PRESET_RIGHT_WIDE)
		_panel.offset_left = -_panel_w - _inset.z - 10.0
		_panel.offset_right = -_inset.z - 10.0
		_panel.offset_top = _inset.y + 12.0
		_panel.offset_bottom = -_inset.w
	_layout_joy()

# ---------------------------------------------------------------- API cho World
func set_stats(hp: int, max_hp: int, mp: int, max_mp: int, sta: int = -1, max_sta: int = 0, exp: int = 0, exp_next: int = 0) -> void:
	if _hp_bar:
		_hp_bar.max_value = maxi(1, max_hp); _hp_bar.value = clampi(hp, 0, maxi(1, max_hp))
		if _hp_text: _hp_text.text = "%d / %d" % [hp, max_hp]
		_update_low_hp(float(hp) / float(maxi(1, max_hp)))
	if _mp_bar:
		_mp_bar.max_value = maxi(1, max_mp); _mp_bar.value = clampi(mp, 0, maxi(1, max_mp))
		if _mp_text: _mp_text.text = "%d / %d" % [mp, max_mp]
	if _sta_bar:
		_sta_bar.max_value = maxi(1, max_sta); _sta_bar.value = clampi(sta, 0, maxi(1, max_sta))
		if _sta_text: _sta_text.text = "%d / %d" % [sta, max_sta]
	if _exp_bar:
		_exp_bar.max_value = maxi(1, exp_next); _exp_bar.value = clampi(exp, 0, maxi(1, exp_next))

func set_hero(_name: String, level: int, _rank: String, school: String) -> void:
	if not _lv_badge: return
	_lv_badge.text = str(level)
	if school != _portrait_school:
		_portrait_school = school
		var p := W.char_avatar(school, 42)
		if p and p.texture: _portrait.texture = p.texture
		if p: p.queue_free()

func set_map(_name: String) -> void:
	pass   # không hiện tên map trên màn hình

func set_quest(text: String) -> void:
	if _quest_btn: _quest_btn.text = text

## Màu viền + trạng thái dùng được của từng ô kỹ năng (đủ MP hay chưa).
func set_skill_styles(colors: Array, usable: Array) -> void:
	for i in range(_skill_buttons.size()):
		var b := _skill_buttons[i] as ActionButton
		if i < colors.size() and colors[i] is Color and b.ring != colors[i]:
			b.ring = colors[i]
			b.queue_redraw()
		if i < usable.size(): b.set_usable(bool(usable[i]))

## labels[i] = "glyph|tên kỹ năng" (glyph thường là emoji từ data).
func set_skill_labels(labels: Array) -> void:
	for i in range(_skill_buttons.size()):
		if i < labels.size():
			var parts := str(labels[i]).split("|", true, 1)
			var b := _skill_buttons[i] as ActionButton
			b.set_glyph(parts[0])
			b.tooltip_text = parts[1] if parts.size() > 1 else ""

## Ẩn/hiện ô kỹ năng (ô trang bị chỉ hiện khi có kỹ năng mượn).
func set_skill_visible(index: int, v: bool) -> void:
	if index >= 0 and index < _skill_buttons.size(): (_skill_buttons[index] as ActionButton).visible = v

## Bắt đầu vòng hồi chiêu cho ô kỹ năng `index` (0..4) trong `seconds` giây.
func start_cooldown(index: int, seconds: float) -> void:
	if index >= 0 and index < _skill_buttons.size():
		(_skill_buttons[index] as ActionButton).start_cooldown(seconds)

func log(text: String, color: Color = T.C_TEXT) -> void:
	_log_lines.append({"text": text.replace("[", "(").replace("]", ")"), "color": color, "at": Time.get_ticks_msec()})
	while _log_lines.size() > 6: _log_lines.pop_front()
	_render_log()

func _render_log() -> void:
	var parts: PackedStringArray = []
	for l in _log_lines:
		parts.append("[color=#%s]%s[/color]" % [(l["color"] as Color).to_html(false), l["text"]])
	_log.text = "\n".join(parts)

## kind: "info" (vàng) | "success" (xanh) | "error" (đỏ) | "warn" (cam). Thông báo mới thay thế cái cũ, tự mờ dần.
func toast(text: String, kind: String = "info") -> void:
	if not _toast: return
	var col := T.C_GOLD
	var pre := ""
	match kind:
		"success": col = T.C_GREEN; pre = "✓  "
		"error": col = Color(1.0, 0.45, 0.45); pre = "✕  "
		"warn": col = Color(1.0, 0.7, 0.3); pre = "!  "
	_toast.text = pre + text
	_toast.add_theme_color_override("font_color", col)
	if kind == "error": Audio.play("error")
	_toast_panel.visible = true
	_toast_panel.modulate.a = 0.0
	_toast_panel.reset_size()
	_toast_panel.offset_left = -_toast_panel.size.x * 0.5
	_toast_panel.offset_right = _toast_panel.size.x * 0.5
	if _toast_tween: _toast_tween.kill()
	_toast_tween = create_tween()
	_toast_tween.tween_property(_toast_panel, "modulate:a", 1.0, 0.12)
	_toast_tween.tween_interval(1.8 if kind != "error" else 2.6)
	_toast_tween.tween_property(_toast_panel, "modulate:a", 0.0, 0.3)
	_toast_tween.tween_callback(func(): _toast_panel.visible = false)

# ---------------------------------------------------------------- Panel API
func open_panel(tab: String, extra: Dictionary = {}) -> void:
	if tab == "npc":
		open_dialog(str(extra.get("id", "")))
		return
	_close_menu()
	var tab_changed := tab != _open_tab
	if tab_changed: W.left_scroll_pos = 0
	_open_tab = tab
	_open_extra = extra
	_update_rail()
	refresh_panel(extra)
	if not _panel_layer.visible:
		_panel_layer.visible = true
		_layout()
		var end_l := _panel.offset_left
		var end_r := _panel.offset_right
		_panel.offset_left = end_l + _panel_w
		_panel.offset_right = end_r + _panel_w
		var tw := create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw.tween_property(_panel, "offset_left", end_l, 0.2)
		tw.tween_property(_panel, "offset_right", end_r, 0.2)
	if tab_changed and _panel_layer.visible:
		_panel_fixed.modulate.a = 0.0
		_panel_scroll.modulate.a = 0.0
		var tw2 := create_tween().set_parallel(true)
		tw2.tween_property(_panel_fixed, "modulate:a", 1.0, 0.18)
		tw2.tween_property(_panel_scroll, "modulate:a", 1.0, 0.18)
	menu_pressed.emit(tab)

func refresh_panel(extra: Dictionary = {}) -> void:
	if not _panel_body or _open_tab.is_empty(): return
	if extra.is_empty(): extra = _open_extra
	var keep: int = _panel_scroll.scroll_vertical
	for c in _panel_body.get_children(): c.queue_free()
	for c2 in _panel_fixed.get_children(): c2.queue_free()
	if _panels == null: return
	var node: Control = _panels.build(_open_tab, extra)
	if node.has_meta("fill"):
		_panel_scroll.visible = false
		_panel_fixed.visible = true
		_panel_fixed.add_child(node)
	else:
		_panel_fixed.visible = false
		_panel_scroll.visible = true
		_panel_body.add_child(node)
		# Giữ vị trí cuộn sau khi dựng lại (tránh nhảy về đầu mỗi lần server trả patch).
		await get_tree().process_frame
		if is_instance_valid(_panel_scroll): _panel_scroll.scroll_vertical = keep

func _toggle_panel(tab: String) -> void:
	if _open_tab == tab and _panel_layer.visible:
		close_panel(); return
	open_panel(tab)

func close_panel() -> void:
	if _panel_layer: _panel_layer.visible = false
	_open_tab = ""

# ---------------------------------------------------------------- Nút ngữ cảnh / chết / banner
func _build_interact() -> void:
	pass   # tương tác NPC / nhặt đồ / qua cổng dùng nút Đánh (mũi tên vàng chỉ đối tượng), không còn nút riêng

## label rỗng = ẩn nút.
func set_interact(label: String) -> void:
	if _interact_btn == null: return
	_interact_btn.visible = not label.is_empty()
	_interact_btn.text = label

func _build_death() -> void:
	_death_layer = Control.new()
	_death_layer.visible = false
	_death_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_death_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.add_child(_death_layer)
	var scrim := ColorRect.new()
	scrim.color = Color(0.25, 0.0, 0.02, 0.62)
	scrim.set_anchors_preset(Control.PRESET_FULL_RECT)
	scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_death_layer.add_child(scrim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_death_layer.add_child(center)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 14)
	vb.custom_minimum_size = Vector2(320, 0)
	center.add_child(vb)
	var t := T.hud_label("Bạn đã bị đánh bại", T.FS_XL, Color(1.0, 0.5, 0.5), true)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(t)
	var b1 := T.button_primary("Đứng dậy tại chỗ", Vector2(0, 52))
	b1.pressed.connect(func(): _answer_death("stay"))
	vb.add_child(b1)
	var b2 := T.button("Về làng gần nhất", Vector2(0, 52))
	b2.add_theme_font_size_override("font_size", T.FS_L)
	b2.pressed.connect(func(): _answer_death("home"))
	vb.add_child(b2)
	var hint := T.label("Hồi sinh sẽ mất một phần kinh nghiệm.", T.FS_S, T.C_MUTED)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(hint)

func show_death() -> void:
	close_panel(); _close_menu()
	_death_layer.visible = true

func hide_death() -> void:
	_death_layer.visible = false

func _answer_death(where: String) -> void:
	_death_layer.visible = false
	death_choice.emit(where)

func _build_banner() -> void:
	_banner = T.hud_label("", T.FS_XXL, T.C_GOLD, true)
	_banner.visible = false
	_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_banner.set_anchors_preset(Control.PRESET_CENTER)
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.add_theme_constant_override("outline_size", 8)
	_banner.offset_left = -300; _banner.offset_right = 300
	_banner.offset_top = -90; _banner.offset_bottom = -30
	_root.add_child(_banner)

## Chữ lớn giữa màn hình (lên cấp, hạng...), tự mờ dần.
func banner(text: String, color: Color = T.C_GOLD) -> void:
	if _banner == null: return
	_banner.text = text
	_banner.add_theme_color_override("font_color", color)
	_banner.visible = true
	_banner.modulate.a = 0.0
	_banner.pivot_offset = Vector2(300, 30)
	_banner.scale = Vector2(0.7, 0.7)
	if _banner_tween: _banner_tween.kill()
	_banner_tween = create_tween()
	_banner_tween.set_parallel(true)
	_banner_tween.tween_property(_banner, "modulate:a", 1.0, 0.2)
	_banner_tween.tween_property(_banner, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_banner_tween.chain().tween_interval(1.4)
	_banner_tween.chain().tween_property(_banner, "modulate:a", 0.0, 0.4)
	_banner_tween.chain().tween_callback(func(): _banner.visible = false)


# ---------------------------------------------------------------- Lời mời đội / giao dịch
var _invite: PanelContainer = null
var _invite_label: Label = null
var _invite_kind := ""
var _invite_token := 0

func _build_invite() -> void:
	_invite = PanelContainer.new()
	_invite.visible = false
	_invite.add_theme_stylebox_override("panel", T.UISkin.panel(12))
	_anchor_rect(_invite, Control.PRESET_CENTER_TOP, 0, _inset.y + 44, 400, 80)
	_root.add_child(_invite)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	_invite.add_child(vb)
	_invite_label = T.label("", T.FS_M, T.C_TEXT, true)
	_invite_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(_invite_label)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 8)
	vb.add_child(hb)
	var yes := T.button_primary("Đồng ý", Vector2(0, 44))
	yes.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	yes.pressed.connect(func(): _answer_invite(true))
	hb.add_child(yes)
	var no := T.button("Từ chối", Vector2(0, 44))
	no.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	no.pressed.connect(func(): _answer_invite(false))
	hb.add_child(no)

func _on_invited(kind: String, from: Dictionary) -> void:
	_invite_kind = kind
	_invite_token += 1
	var token := _invite_token
	_invite_label.text = "%s mời bạn %s" % [str(from.get("name", "?")), "vào đội" if kind == "party" else "giao dịch"]
	_invite.visible = true
	Audio.play("ui")
	await get_tree().create_timer(20.0).timeout
	if token == _invite_token and _invite.visible: _invite.visible = false

func _answer_invite(ok: bool) -> void:
	_invite.visible = false
	if _invite_kind == "party": Socket.send_party("resp", {"ok": ok})
	else: Socket.send_trade("resp", {"ok": ok})

func _on_social_changed(kind: String) -> void:
	if kind == "trade" and Social.in_trade() and _open_tab != "trade":
		open_panel("trade")
	elif kind in ["trade", "party", "channels", "market"] and _panel_layer.visible and _open_tab in ["trade", "social"]:
		refresh_panel()

func _on_trade_ended(reason: String, done: bool) -> void:
	toast("Giao dịch thành công" if done else ("Giao dịch đã kết thúc" if reason.is_empty() else reason))
	if _open_tab == "trade": close_panel()


# ---------------------------------------------------------------- Nháy màn hình / cảnh báo máu thấp
func _build_screen_fx() -> void:
	_flash = ColorRect.new()
	_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash.color = Color(1, 1, 1, 0)
	_root.add_child(_flash)
	var grad := Gradient.new()
	grad.set_color(0, Color(0.8, 0.0, 0.05, 0.0))
	grad.set_color(1, Color(0.8, 0.0, 0.05, 0.75))
	grad.set_offset(0, 0.55)
	var gt := GradientTexture2D.new()
	gt.gradient = grad
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.5)
	gt.fill_to = Vector2(1.05, 1.05)
	gt.width = 256
	gt.height = 128
	_vignette = TextureRect.new()
	_vignette.texture = gt
	_vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	_vignette.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_vignette.stretch_mode = TextureRect.STRETCH_SCALE
	_vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vignette.modulate.a = 0.0
	_root.add_child(_vignette)

## Nháy toàn màn hình một màu (bị đánh, thăng cấp).
func flash(color: Color, strength: float = 0.3) -> void:
	if _flash == null: return
	_flash.color = Color(color, strength)
	create_tween().tween_property(_flash, "color:a", 0.0, 0.25)

func _update_low_hp(ratio: float) -> void:
	if _vignette == null: return
	var low := ratio < 0.28 and ratio > 0.0
	if low and _low_hp_tween == null:
		_low_hp_tween = create_tween().set_loops()
		_low_hp_tween.tween_property(_vignette, "modulate:a", 0.9, 0.5)
		_low_hp_tween.tween_property(_vignette, "modulate:a", 0.3, 0.5)
	elif not low and _low_hp_tween != null:
		_low_hp_tween.kill()
		_low_hp_tween = null
		create_tween().tween_property(_vignette, "modulate:a", 0.0, 0.3)


# ---------------------------------------------------------------- Hội thoại NPC
func _build_dialog() -> void:
	_dialog = NpcDialog.new()
	_root.add_child(_dialog)
	_dialog.open_panel_requested.connect(func(tab, extra): open_panel(tab, extra))
	_dialog.confirm_requested.connect(func(t, b, ok, cb): confirm(t, b, ok, cb, true))

## Mở hội thoại NPC (thay cho panel NPC cũ).
func open_dialog(npc_id: String) -> void:
	close_panel(); _close_menu()
	_dialog.open_for(npc_id)

func dialog_open() -> bool:
	return _dialog != null and _dialog.visible

func refresh_dialog() -> void:
	if _dialog: _dialog.refresh()


# ---------------------------------------------------------------- Hộp xác nhận
var _confirm_layer: Control = null
var _confirm_title: Label = null
var _confirm_body: Label = null
var _confirm_ok: Button = null
var _confirm_cb := Callable()

func _build_confirm() -> void:
	_confirm_layer = Control.new()
	_confirm_layer.visible = false
	_confirm_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_confirm_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.add_child(_confirm_layer)
	var scrim := ColorRect.new()
	scrim.color = Color(0, 0, 0.02, 0.6)
	scrim.set_anchors_preset(Control.PRESET_FULL_RECT)
	scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_confirm_layer.add_child(scrim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_confirm_layer.add_child(center)
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", T.UISkin.panel(16))
	card.custom_minimum_size = Vector2(340, 0)
	center.add_child(card)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	card.add_child(vb)
	_confirm_title = T.label("", T.FS_L, T.C_GOLD, true)
	_confirm_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(_confirm_title)
	_confirm_body = T.label("", T.FS_M, T.C_TEXT)
	_confirm_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(_confirm_body)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 10)
	vb.add_child(hb)
	var no := T.button("Huỷ", Vector2(0, 44))
	no.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	no.pressed.connect(func(): _confirm_layer.visible = false)
	hb.add_child(no)
	_confirm_ok = T.button_danger("Đồng ý", Vector2(0, 44))
	_confirm_ok.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_confirm_ok.pressed.connect(func():
		_confirm_layer.visible = false
		if _confirm_cb.is_valid(): _confirm_cb.call())
	hb.add_child(_confirm_ok)

## Hộp xác nhận cho hành động không hoàn tác được.
func confirm(title: String, body: String, ok_text: String, cb: Callable, danger: bool = false) -> void:
	_confirm_title.text = title
	_confirm_body.text = body
	_confirm_ok.text = ok_text
	_confirm_cb = cb
	_confirm_layer.visible = true
	Audio.play("ui")

# ---------------------------------------------------------------- Mất kết nối + gợi ý lần đầu
var _offline_bar: PanelContainer = null
var _hint_panel: PanelContainer = null
var _hint_label: Label = null
var _hint_tween: Tween = null

func _build_net_status() -> void:
	_offline_bar = PanelContainer.new()
	_offline_bar.visible = false
	_offline_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb: StyleBoxTexture = T.UISkin.button("danger", "normal", 8)
	_offline_bar.add_theme_stylebox_override("panel", sb)
	_anchor_rect(_offline_bar, Control.PRESET_CENTER_TOP, 0, _inset.y + 44, 300, 34)
	_root.add_child(_offline_bar)
	var l := T.label("Mất kết nối máy chủ — đang thử lại…", T.FS_S, Color.WHITE, true)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_offline_bar.add_child(l)
	Net.offline_changed.connect(func(off): _offline_bar.visible = off)
	Socket.disconnected_from_server.connect(func(_c): _offline_bar.visible = true)
	Socket.connected_to_server.connect(func(): _offline_bar.visible = false)
	# Gợi ý
	_hint_panel = PanelContainer.new()
	_hint_panel.visible = false
	_hint_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hint_panel.add_theme_stylebox_override("panel", T.UISkin.panel(10))
	_hint_panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_hint_panel.offset_left = -190; _hint_panel.offset_right = 190
	_hint_panel.offset_top = -(_inset.w + 190.0); _hint_panel.offset_bottom = -(_inset.w + 136.0)
	_hint_label = T.label("", T.FS_S, T.C_TEXT)
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint_panel.add_child(_hint_label)
	_root.add_child(_hint_panel)

## Gợi ý hiện đúng một lần cho mỗi id (lưu trong Settings).
func hint_once(id: String, text: String) -> void:
	if Settings.hints_seen.has(id): return
	Settings.mark_hint(id)
	_hint_label.text = "💡 " + text
	_hint_panel.visible = true
	_hint_panel.modulate.a = 0.0
	if _hint_tween: _hint_tween.kill()
	_hint_tween = create_tween()
	_hint_tween.tween_property(_hint_panel, "modulate:a", 1.0, 0.25)
	_hint_tween.tween_interval(4.5)
	_hint_tween.tween_property(_hint_panel, "modulate:a", 0.0, 0.4)
	_hint_tween.tween_callback(func(): _hint_panel.visible = false)


# ---------------------------------------------------------------- Bình nhanh
func _make_potion_button(kind: String, color: Color, cx: float, cy: float) -> ActionButton:
	var b := ActionButton.new()
	b.setup(21.0, color)
	b.icon.visible = true
	b.icon.modulate = Color.WHITE
	b.visible = false
	b.pressed.connect(func(): potion_pressed.emit(kind))
	_place_br(b, cx, cy, 21.0)
	_root.add_child(b)
	return b

## Cập nhật nút bình nhanh: item id + số lượng (0 = ẩn).
func set_potions(hp_id: String, hp_n: int, mp_id: String, mp_n: int) -> void:
	_set_potion(_potion_hp, hp_id, hp_n)
	_set_potion(_potion_mp, mp_id, mp_n)

func _set_potion(b: ActionButton, iid: String, n: int) -> void:
	if b == null: return
	b.visible = n > 0
	if n > 0:
		b.icon.texture = T.icon("bag") if not ResourceLoader.exists("res://assets/items/%s.svg" % iid) else load("res://assets/items/%s.svg" % iid)
		b.set_badge(str(n))
		b.tooltip_text = str(Data.item(iid).get("name", iid))

func potion_cooldown(kind: String, seconds: float) -> void:
	var b := _potion_hp if kind == "hp" else _potion_mp
	if b: b.start_cooldown(seconds)


## Cập nhật nút biến hình: số Ấn đã mở, Ấn đang chọn (1..5), đang biến hình hay không.
func set_form_state(unlocked: int, tier: int, active: bool) -> void:
	if _form_btn == null: return
	_form_btn.visible = unlocked >= 1
	_seal_btn.visible = unlocked >= 2
	if unlocked < 1: return
	var aw: Dictionary = Data.awaken(tier)
	var aura := Color.from_rgba8((int(aw.get("aura", 0xff9a40)) >> 16) & 255, (int(aw.get("aura", 0xff9a40)) >> 8) & 255, int(aw.get("aura", 0xff9a40)) & 255)
	_form_btn.ring = aura if active else Color(1.0, 0.62, 0.25)
	_form_btn.fill = Color(0.42, 0.16, 0.06, 1.0) if active else Color(0.30, 0.12, 0.06, 1.0)
	_form_btn.set_glow(active)
	_form_btn.tooltip_text = ("Trở lại dạng thường" if active else "Biến hình · Ấn %s" % str(Data.ROMAN[clampi(tier - 1, 0, 4)]))
	_form_btn.queue_redraw()
	_seal_btn.set_glyph(str(Data.ROMAN[clampi(tier - 1, 0, 4)]))
	_seal_btn.set_usable(not active)
# ---------------------------------------------------------------- Hiệu ứng đang dùng (buff kỹ năng)
var _buff_row: HBoxContainer = null
var _buff_sig := ""
var _buff_cells: Dictionary = {}   # id -> {t: Label, bar: ColorRect}

func _build_buffs() -> void:
	_buff_row = HBoxContainer.new()
	_buff_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_buff_row.add_theme_constant_override("separation", 4)
	_anchor_rect(_buff_row, Control.PRESET_TOP_LEFT, _inset.x + 2, _inset.y + 108, 320, 46)
	_buff_row.visible = false
	_root.add_child(_buff_row)

## list: [{id, icon, label, left (ms), dur (ms)}]. Mỗi hiệu ứng một ô: biểu tượng, số giây còn lại, vạch thời gian chạy dần.
func set_buffs(list: Array) -> void:
	if _buff_row == null: return
	var sig := ""
	for b in list: sig += str((b as Dictionary)["id"]) + ","
	if sig != _buff_sig:
		_buff_sig = sig
		_buff_cells.clear()
		for c in _buff_row.get_children(): c.queue_free()
		for b in list:
			var d: Dictionary = b
			var cell := Control.new()
			cell.custom_minimum_size = Vector2(38, 46)
			cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var bg := Panel.new()
			bg.set_anchors_preset(Control.PRESET_FULL_RECT)
			bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
			bg.add_theme_stylebox_override("panel", T.sb(Color(0.03, 0.05, 0.1, 0.72), Color(T.C_GOLD, 0.6), 1, 6, 0))
			cell.add_child(bg)
			var ic := T.GlyphArt.make(str(d["icon"]), 26.0)
			ic.position = Vector2(6, 2)
			ic.size = Vector2(26, 26)
			ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
			cell.add_child(ic)
			var tl := T.hud_label("", 12, Color.WHITE, true)
			tl.position = Vector2(0, 27)
			tl.custom_minimum_size = Vector2(38, 0)
			tl.size = Vector2(38, 14)
			tl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			tl.add_theme_constant_override("outline_size", 3)
			cell.add_child(tl)
			var bar := ColorRect.new()
			bar.color = T.C_GOLD
			bar.position = Vector2(3, 41)
			bar.size = Vector2(32, 3)
			bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
			cell.add_child(bar)
			cell.tooltip_text = str(d["label"])
			_buff_row.add_child(cell)
			_buff_cells[str(d["id"])] = {"t": tl, "bar": bar}
	_buff_row.visible = not list.is_empty()
	for b in list:
		var d2: Dictionary = b
		var c: Dictionary = _buff_cells.get(str(d2["id"]), {})
		if c.is_empty(): continue
		var left := int(d2["left"])
		var secs := int(ceil(float(left) / 1000.0))
		(c["t"] as Label).text = str(secs)
		(c["t"] as Label).add_theme_color_override("font_color", Color(1.0, 0.55, 0.5) if left <= 3000 else Color.WHITE)
		(c["bar"] as ColorRect).size.x = 32.0 * clampf(float(left) / float(maxi(1, int(d2["dur"]))), 0.0, 1.0)
