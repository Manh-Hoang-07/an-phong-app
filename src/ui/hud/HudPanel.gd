extends "res://src/ui/hud/HudPart.gd"
## Ngăn kéo panel bên phải (rail tab + nội dung do GamePanels dựng), debounce dựng lại panel.
## Thành phần của MobileHUD (hud = MobileHUD): tự dựng node, tự giữ trạng thái; API công khai được MobileHUD chuyển tiếp.

var _busy_bar: ProgressBar = null

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

var _panel_rebuild_pending := false

var _panel_rebuild_at := 0

var _panel_rebuild_extra: Dictionary = {}

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
	Net.busy_changed.connect(func(b): hud._tween_busy(1.0 if b else 0.0))
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

func open_panel(tab: String, extra: Dictionary = {}) -> void:
	if tab == "npc":
		hud.open_dialog(str(extra.get("id", "")))
		return
	hud._close_menu()
	var tab_changed := tab != _open_tab
	if tab_changed: W.left_scroll_pos = 0
	_open_tab = tab
	_open_extra = extra
	_update_rail()
	# Đổi tab thì dựng ngay (bỏ qua throttle); cùng tab mới dồn các gói liên tiếp.
	if tab_changed:
		_panel_rebuild_pending = false
		_panel_rebuild_at = Time.get_ticks_msec()
		_do_refresh_panel(extra)
	else:
		refresh_panel(extra)
	if not _panel_layer.visible:
		_panel_layer.visible = true
		hud._layout()
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
	hud.menu_pressed.emit(tab)

func refresh_panel(extra: Dictionary = {}) -> void:
	# Dồn các gói liên tiếp: rebuild ngay nếu chưa từng rebuild, nếu không đợi tới khung _process.
	if not _panel_body or _open_tab.is_empty(): return
	_panel_rebuild_extra = extra if not extra.is_empty() else _open_extra
	if _panel_rebuild_at <= 0 or Time.get_ticks_msec() - _panel_rebuild_at >= 150:
		_panel_rebuild_pending = false
		_panel_rebuild_at = Time.get_ticks_msec()
		_do_refresh_panel(_panel_rebuild_extra)
	else:
		_panel_rebuild_pending = true

func _do_refresh_panel(extra: Dictionary) -> void:
	if not _panel_body or _open_tab.is_empty(): return
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

func _on_social_changed(kind: String) -> void:
	if kind == "channels":
		var cur := int(Social.channels.get("cur", -1))
		if cur != hud.stats._last_zone:
			hud.stats._last_zone = cur
			# Đổi khu: hiện lại khung với tên map hiện tại + khu mới.
			hud.show_zone(hud.stats._last_map_name, cur)
	if kind == "trade" and Social.in_trade() and _open_tab != "trade":
		open_panel("trade")
	elif kind in ["trade", "party", "channels", "market"] and _panel_layer.visible and _open_tab in ["trade", "social"]:
		refresh_panel()

func _on_trade_ended(reason: String, done: bool) -> void:
	hud.toast("Giao dịch thành công" if done else ("Giao dịch đã kết thúc" if reason.is_empty() else reason))
	if _open_tab == "trade": close_panel()

func create_panels() -> void:
	_panels = GP.new(hud)

## Dựng lại panel bị dồn lại tối đa ~6.7 lần/giây (mỗi action_done gọi refresh_panel); gọi mỗi khung từ MobileHUD._process.
func tick() -> void:
	if _panel_rebuild_pending and Time.get_ticks_msec() - _panel_rebuild_at >= 150:
		_panel_rebuild_pending = false
		_panel_rebuild_at = Time.get_ticks_msec()
		_do_refresh_panel(_panel_rebuild_extra)

## Đặt lại ngăn kéo theo kích thước màn hình (gọi từ MobileHUD._layout).
func layout() -> void:
	var vp := get_viewport().get_visible_rect().size
	_panel_w = clampf(vp.x * 0.80, 480.0, 780.0)
	if _panel:
		_panel.set_anchors_preset(Control.PRESET_RIGHT_WIDE)
		_panel.offset_left = -_panel_w - _inset.z - 10.0
		_panel.offset_right = -_inset.z - 10.0
		_panel.offset_top = _inset.y + 12.0
		_panel.offset_bottom = -_inset.w
