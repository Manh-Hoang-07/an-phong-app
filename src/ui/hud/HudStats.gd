extends "res://src/ui/hud/HudPart.gd"
## Khối trái-trên: avatar, tên, cấp, thanh HP/MP/STA/EXP, nút nhiệm vụ.
## Thành phần của MobileHUD (hud = MobileHUD): tự dựng node, tự giữ trạng thái; API công khai được MobileHUD chuyển tiếp.

# HUD trái-trên
var _avatar_holder: Control = null

var _portrait: TextureRect = null

var _portrait_school := ""

var _lv_badge: Label = null

var _hp_bar: ProgressBar = null

var _hp_text: Label = null

var _mp_text: Label = null

var _sta_text: Label = null

var _mp_bar: ProgressBar = null

var _sta_bar: ProgressBar = null

var _exp_bar: ProgressBar = null

# giữa/phải-trên
var _quest_btn: Button = null

var _last_map_name := ""

var _last_zone := -1

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
	_quest_btn.pressed.connect(func(): hud.open_panel("quest"))
	col.add_child(_quest_btn)

func set_stats(hp: int, max_hp: int, mp: int, max_mp: int, sta: int = -1, max_sta: int = 0, exp: int = 0, exp_next: int = 0) -> void:
	if _hp_bar:
		_hp_bar.max_value = maxi(1, max_hp); _hp_bar.value = clampi(hp, 0, maxi(1, max_hp))
		if _hp_text: _hp_text.text = "%d / %d" % [hp, max_hp]
		hud._update_low_hp(float(hp) / float(maxi(1, max_hp)))
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
	# Gọi mỗi lần refresh HUD; chỉ hiện khung khi tên map thực sự đổi.
	if _name.is_empty() or _name == _last_map_name: return
	_last_map_name = _name
	hud.show_zone(_name, _last_zone)

func set_quest(text: String) -> void:
	if _quest_btn: _quest_btn.text = text
