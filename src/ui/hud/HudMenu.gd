extends "res://src/ui/hud/HudPart.gd"
## Nút menu phải-trên + bảng menu dưới đáy (lưới tab chính và dịch vụ).
## Thành phần của MobileHUD (hud = MobileHUD): tự dựng node, tự giữ trạng thái; API công khai được MobileHUD chuyển tiếp.

# menu + panel
var _menu_layer: Control = null

var _menu_scroll: TouchScroll = null

func _build_top_right() -> void:
	var box := HBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 8)
	box.alignment = BoxContainer.ALIGNMENT_END
	_anchor_rect(box, Control.PRESET_TOP_RIGHT, _inset.z, _inset.y, 300, 46)
	_root.add_child(box)
	var chat_btn := T.icon_button("chat", 46)
	chat_btn.pressed.connect(hud._toggle_chat)
	box.add_child(chat_btn)
	var menu_btn := T.icon_button("menu", 46, T.C_GOLD, true)
	menu_btn.pressed.connect(_toggle_menu)
	box.add_child(menu_btn)

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
	b.pressed.connect(func(): _close_menu(); hud.open_panel(tab))
	return b

func _toggle_menu() -> void:
	if _menu_layer.visible: _close_menu()
	else:
		hud.close_panel()
		_menu_layer.visible = true

func _close_menu() -> void:
	_menu_layer.visible = false
