extends "res://src/ui/hud/HudPart.gd"
## Hộp thoại/nút tình huống: tương tác, màn chết, lời mời đội/giao dịch, hội thoại NPC, hộp xác nhận.
## Thành phần của MobileHUD (hud = MobileHUD): tự dựng node, tự giữ trạng thái; API công khai được MobileHUD chuyển tiếp.

var _interact_btn: Button = null

var _death_layer: Control = null

var _dialog: Control = null

var _invite: PanelContainer = null

var _invite_label: Label = null

var _invite_kind := ""

var _invite_token := 0

var _confirm_layer: Control = null

var _confirm_title: Label = null

var _confirm_body: Label = null

var _confirm_ok: Button = null

var _confirm_cb := Callable()

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
	hud.close_panel(); hud._close_menu()
	_death_layer.visible = true

func hide_death() -> void:
	_death_layer.visible = false

func _answer_death(where: String) -> void:
	_death_layer.visible = false
	hud.death_choice.emit(where)

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

func _build_dialog() -> void:
	_dialog = NpcDialog.new()
	_root.add_child(_dialog)
	_dialog.open_panel_requested.connect(func(tab, extra): hud.open_panel(tab, extra))
	_dialog.confirm_requested.connect(func(t, b, ok, cb): confirm(t, b, ok, cb, true))

## Mở hội thoại NPC (thay cho panel NPC cũ).
func open_dialog(npc_id: String) -> void:
	hud.close_panel(); hud._close_menu()
	_dialog.open_for(npc_id)

func dialog_open() -> bool:
	return _dialog != null and _dialog.visible

func refresh_dialog() -> void:
	if _dialog: _dialog.refresh()

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
