extends "res://src/ui/panels/PanelBase.gd"
## Mật mã + cài đặt (build_code, build_config). Dùng chung trạng thái/hàm trợ giúp qua PanelBase; hub = GamePanels.gd.

# Trạng thái riêng của panel này
var code_draft := ""

var code_msg := ""

func build_code() -> Control:
	var vb := _vb()
	vb.add_child(T.label("Lữ khách bí ẩn sẽ đổi mật mã lấy phần thưởng hoặc mở khoá class đặc biệt.", T.FS_S, T.C_MUTED))
	if not code_msg.is_empty(): vb.add_child(T.label(code_msg, T.FS_S, T.C_RED))
	var ed := LineEdit.new()
	ed.placeholder_text = "Nhập mật mã…"
	ed.max_length = 40
	ed.custom_minimum_size = Vector2(0, 46)
	ed.text = code_draft
	ed.text_changed.connect(func(t): code_draft = t)
	vb.add_child(ed)
	vb.add_child(T.button_primary("Xác nhận", Vector2(0, 48)))
	(vb.get_child(vb.get_child_count() - 1) as Button).pressed.connect(func():
		var code := code_draft.strip_edges()
		if code.is_empty(): return
		var data := await Net.send_action("redeem", {"code": code})
		if bool(data.get("ok", false)):
			code_draft = ""; code_msg = ""
			if data.has("player"): Game.set_player(data["player"], false)
			if data.has("rev"): Game.rev = int(data["rev"])
			if data.has("events"): Game.on_events(data["events"])
			host.open_panel("npc", {"id": "lu_khach"})
		else:
			code_msg = str(data.get("error", "Mật mã không đúng."))
			refresh())
	var confirm := str(ctx_extra.get("confirm", ""))
	if not confirm.is_empty():
		vb.add_child(T.hsep())
		vb.add_child(W.section_label("Thức tỉnh · %s" % W.school_name(confirm)))
		vb.add_child(T.label("Cảnh báo: đã chọn thì không đổi lại được.", T.FS_S, T.C_RED))
		vb.add_child(W.action_button("Thức tỉnh", func(): act("awaken_special", {"school": confirm})))
	return vb

func _toggle(text: String, hint: String, value: bool, cb: Callable) -> Control:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	var col := _vb(0)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	col.add_child(T.label(text, T.FS_M, T.C_TEXT, true))
	if not hint.is_empty(): col.add_child(T.label(hint, 12, T.C_MUTED))
	h.add_child(col)
	var cb_btn := CheckButton.new()
	cb_btn.button_pressed = value
	cb_btn.focus_mode = Control.FOCUS_NONE
	cb_btn.toggled.connect(func(v): cb.call(v); Audio.play("ui"))
	cb_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(cb_btn)
	# Hang phang: khong vien vang, khong nen xanh cho o bat/tat.
	return h

## Một hàng âm lượng: nhãn + giá trị % + thanh kéo. `disabled` làm mờ khi kênh đang tắt.
func _vol_row(text: String, value: float, disabled: bool, cb: Callable) -> Control:
	var box := _vb(2)
	var head := HBoxContainer.new()
	var lbl := T.label(text, T.FS_M, T.C_TEXT, true)
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(lbl)
	var val := T.label("%d%%" % int(value * 100.0), T.FS_S, T.C_GOLD, true)
	val.autowrap_mode = TextServer.AUTOWRAP_OFF
	val.custom_minimum_size = Vector2(48, 0)
	val.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	head.add_child(val)
	box.add_child(head)
	var s := HSlider.new()
	s.min_value = 0.0; s.max_value = 1.0; s.step = 0.05
	s.value = value
	s.custom_minimum_size = Vector2(0, 28)
	s.editable = not disabled
	s.modulate = Color(1, 1, 1, 1.0 if not disabled else 0.45)
	s.value_changed.connect(func(v): cb.call(v); val.text = "%d%%" % int(v * 100.0))
	box.add_child(s)
	return W.card_row(box)

func build_config() -> Control:
	var vb := _vb()
	vb.add_child(W.section_label("Hiển thị"))
	var scale_opts := [["0.75", "75%"], ["0.85", "85%"], ["1.0", "100%"], ["1.15", "115%"]]
	var scale_cur := "0.85"
	for o in scale_opts:
		if absf(float(o[0]) - Settings.ui_scale) < 0.01: scale_cur = str(o[0])
	vb.add_child(T.label("Cỡ chữ & nút HUD (không đổi tầm nhìn map)", T.FS_S, T.C_MUTED))
	vb.add_child(W.segmented(scale_opts, scale_cur, func(v): Settings.set_ui_scale(float(v)); refresh()))
	# Tầm nhìn thế giới: đổi zoom camera thật, khác với content_scale_factor ở trên.
	var zoom_opts := [["0.75", "Rất rộng"], ["0.85", "Rộng"], ["0.95", "Vừa"], ["1.15", "Gần"], ["1.3", "Rất gần"]]
	var zoom_cur := "0.95"
	for o in zoom_opts:
		if absf(float(o[0]) - Settings.world_zoom) < 0.01: zoom_cur = str(o[0])
	vb.add_child(T.label("Tầm nhìn thế giới (nhỏ hơn = thấy nhiều map hơn)", T.FS_S, T.C_MUTED))
	vb.add_child(W.segmented(zoom_opts, zoom_cur, func(v): Settings.set_world_zoom(float(v)); refresh()))
	vb.add_child(_toggle("Đồ họa thấp", "Bớt hạt, tắt lớp nền giữa và thời tiết — nhẹ máy hơn", Settings.quality_low, func(v): Settings.set_quality_low(v)))
	vb.add_child(_toggle("Giới hạn 30 FPS", "Tiết kiệm pin, máy ít nóng", Settings.fps_cap == 30, func(v): Settings.set_fps_cap(30 if v else 60)))
	vb.add_child(_toggle("Hiện số sát thương", "Chữ nổi trên đầu quái khi đánh", Settings.show_damage, func(v): Settings.set_show_damage(v)))
	vb.add_child(W.section_label("Âm thanh & rung"))
	# Hai kênh riêng biệt như web: SFX (tiếng đánh/nhặt đồ) và nhạc nền theo bản đồ.
	vb.add_child(_toggle("Hiệu ứng âm thanh", "Tiếng đánh, nhặt đồ, mở bảng…", Settings.sfx_enabled, func(v): Settings.set_sfx_enabled(v)))
	vb.add_child(_vol_row("Âm lượng hiệu ứng", Settings.sfx_volume, not Settings.sfx_enabled, func(v): Settings.set_sfx_volume(v)))
	vb.add_child(_toggle("Nhạc nền", "Nhạc riêng cho từng vùng", Settings.music_enabled, func(v): Settings.set_music_enabled(v)))
	vb.add_child(_vol_row("Âm lượng nhạc", Settings.music_volume, not Settings.music_enabled, func(v): Settings.set_music_volume(v)))
	vb.add_child(_toggle("Rung khi bị đánh", "Chỉ có tác dụng trên điện thoại", Settings.haptics, func(v): Settings.set_haptics(v)))
	var do_out := func():
		Net.logout()
		Settings.set_session("")
		host.get_tree().change_scene_to_file("res://src/scenes/Login.tscn")
	var out := W.action_button("Đăng xuất", func():
		host.confirm("Đăng xuất?", "Tiến trình đã được lưu trên máy chủ. Bạn sẽ quay lại màn đăng nhập.", "Đăng xuất", do_out, true))
	out.add_theme_color_override("font_color", T.C_RED)
	vb.add_child(out)
	vb.add_child(T.label("Thức Tỉnh · phiên bản 0.1.0", 11, Color(T.C_MUTED, 0.6)))
	return vb
