extends "res://src/ui/panels/PanelBase.gd"
## Biến hình (Ấn thức tỉnh) + Kỳ Nguyên (build_form, build_kynguyen). Dùng chung trạng thái/hàm trợ giúp qua PanelBase; hub = GamePanels.gd.

func build_form() -> Control:
	var vb := _vb()
	var pl := p()
	var unlocked := int(pl.get("awakenTier", 0))
	var cur_tier := maxi(1, Data.awaken_tier_of(pl.get("formChoice", "")))
	var active := Game.form_active
	var aw: Dictionary = Data.awaken(cur_tier)
	var st: Dictionary = Game.stats
	# --- Thẻ trạng thái + nút chính
	var inner := _vb(8)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 8)
	var tl := T.label(("Ấn %s" % str(Data.ROMAN[cur_tier - 1])) if unlocked >= 1 else "Chưa mở khóa Ấn nào", T.FS_L, T.C_GOLD, true)
	tl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(tl)
	head.add_child(W.chip("Đang biến hình" if active else "Dạng thường", T.C_GOLD if active else T.C_MUTED))
	inner.add_child(head)
	if unlocked >= 1:
		inner.add_child(T.label(str(aw.get("desc", "")), T.FS_S, T.C_TEXT))
		var need := int(aw.get("drain", 3)) * 3
		inner.add_child(W.chip_row([["Năng lượng  %d / %d" % [Game.mp, int(st.get("maxMp", 0))], T.C_BLUE], ["Thể lực  %d / %d" % [Game.sta, int(st.get("maxSta", 100))], T.C_GREEN], ["Tốn %d / giây" % int(aw.get("drain", 3)), T.C_MUTED]]))
		var tb: Button
		if active:
			tb = W.action_button("Trở lại dạng thường", func(): host.form_pressed.emit())
		else:
			tb = T.button_primary("Biến hình", Vector2(0, 48))
			tb.pressed.connect(func(): host.form_pressed.emit())
			var enough := Game.mp >= need and Game.sta >= need and not Game.sta_locked
			tb.disabled = not enough
			if not enough: inner.add_child(T.label("Cần ít nhất %d năng lượng và %d thể lực để biến hình." % [need, need], 12, Color(1.0, 0.7, 0.3)))
		inner.add_child(tb)
		if unlocked >= 2 and active: inner.add_child(T.label("Hãy trở lại dạng thường trước khi đổi ấn.", 12, T.C_MUTED))
	else:
		inner.add_child(T.label("Biến hình là hình thái thức tỉnh tăng mạnh máu, năng lượng, tấn công và phòng thủ, đổi lại tốn năng lượng và thể lực mỗi giây.", T.FS_S, T.C_MUTED))
	var card := W.card_row(inner)
	if active: card.add_theme_stylebox_override("panel", T.UISkin.tab(true))
	vb.add_child(card)
	# --- Danh sách 5 Ấn
	vb.add_child(W.section_label("Các Ấn thức tỉnh"))
	for t in range(1, Data.AWAKENS.size() + 1):
		var a: Dictionary = Data.awaken(t)
		var open := t <= unlocked
		var is_cur := t == cur_tier and unlocked >= 1
		var row := _vb(4)
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 8)
		var col := _vb(0)
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		col.add_child(T.label("Ấn %s" % str(Data.ROMAN[t - 1]), T.FS_M, T.C_GOLD if open else T.C_MUTED, true))
		var sub := "Đã mở khóa" if open else ("Cần cấp %d · thử thách NPC ẩn + Sách Biến Hình" % int(a.get("level", 0)) if t == unlocked + 1 else "Mở khóa lần lượt sau Ấn %s" % str(Data.ROMAN[maxi(0, t - 2)]))
		col.add_child(T.label(sub, 12, T.C_GREEN if open else T.C_MUTED))
		h.add_child(col)
		if open:
			if is_cur: h.add_child(W.chip("Đang chọn", T.C_GOLD))
			else:
				var sb := W.action_button("Chọn ấn này", func(): act("form_select", {"choice": "awaken%d" % t}), active)
				sb.custom_minimum_size = Vector2(110, 40)
				h.add_child(sb)
		row.add_child(h)
		var m: Dictionary = a.get("mul", {})
		var chips: Array = []
		for k in [["hp", "Máu", T.C_RED], ["mp", "Năng lượng", T.C_BLUE], ["atk", "Tấn công", T.C_GOLD], ["def", "Phòng thủ", T.C_GREEN]]:
			if m.has(k[0]): chips.append(["%s +%d%%" % [k[1], int(roundf((float(m[k[0]]) - 1.0) * 100.0))], k[2]])
		var fl := HFlowContainer.new()
		fl.add_theme_constant_override("h_separation", 6)
		fl.add_theme_constant_override("v_separation", 4)
		for c in chips: fl.add_child(W.chip(str(c[0]), c[1] as Color))
		row.add_child(fl)
		var c2 := W.card_row(row)
		if is_cur: c2.add_theme_stylebox_override("panel", T.UISkin.tab(true))
		vb.add_child(c2)
	# --- Cách mở khóa
	var guide := _vb(3)
	guide.add_child(T.label("Cách mở khóa", T.FS_S, T.C_MUTED, true))
	guide.add_child(T.label("1. Ở Tân Đô, mở chat gõ \"npc an\" để gọi Người Gác Màn.\n2. Đạt đủ cấp, nhận thử thách (hạ quái) rồi quay lại trả.\n3. Dùng Sách Biến Hình trong Túi để mở khóa Ấn.", 12, T.C_TEXT))
	vb.add_child(W.card_row(guide))
	return vb

func build_kynguyen() -> Control:
	var vb := _vb()
	var pl := p()
	var kn: Dictionary = pl.get("kyNguyen", {})
	var owned: Array = kn.get("owned", [])
	var active: Array = kn.get("active", [])
	var lvp := int(pl.get("level", 1))
	vb.add_child(T.label("Kỳ Nguyên là ấn ký đặc biệt: không chiếm ô trang bị, không cường hóa, mua bằng Linh Ngọc tại Lầu Trân Bảo rồi bật/tắt tại đây.", T.FS_S, T.C_MUTED))
	vb.add_child(_gold_row(pl))
	var list: Array = []
	for iid in Data.ITEMS.keys():
		if bool((Data.ITEMS[iid] as Dictionary).get("kyNguyen", false)): list.append(str(iid))
	list.sort_custom(func(a, b): return int(Data.item(a).get("level", 0)) < int(Data.item(b).get("level", 0)))
	for iid2 in list:
		var sid := str(iid2)
		var d: Dictionary = Data.item(sid)
		var have: bool = sid in owned
		var on: bool = sid in active
		var req := int(d.get("level", 1))
		var inner := _vb(6)
		var head := HBoxContainer.new()
		head.add_theme_constant_override("separation", 10)
		var frame := PanelContainer.new()
		frame.add_theme_stylebox_override("panel", T.UISkin.slot(5 if on else (4 if have else 0), on))
		frame.add_child(W.item_icon(sid, 40))
		head.add_child(frame)
		var tc := _vb(2)
		tc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tc.custom_minimum_size = Vector2(240, 0)
		tc.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		tc.add_child(T.label(str(d.get("name", sid)).replace("Kỳ Nguyên · ", ""), T.FS_L, T.C_GOLD if have else T.C_TEXT, true))
		var state_txt := "ĐANG BẬT" if on else ("Đã sở hữu · đang tắt" if have else ("Mở khóa ở cấp %d" % req if lvp < req else "Chưa sở hữu"))
		tc.add_child(T.label(state_txt, T.FS_S, T.C_GREEN if on else (T.C_MUTED if have or lvp >= req else T.C_RED), true))
		head.add_child(tc)
		if have:
			var tb: Button
			if on: tb = W.action_button("Tháo", func(): act("toggle_ky_nguyen", {"id": sid}))
			else:
				tb = T.button_primary("Bật", Vector2(86, 42))
				tb.pressed.connect(func(): act("toggle_ky_nguyen", {"id": sid}))
			tb.custom_minimum_size = Vector2(86, 42)
			head.add_child(tb)
		else:
			var buy := W.action_button("%s Linh Ngọc" % W.fmt_num(int(d.get("priceNgoc", 0))), func(): host.toast("Mua tại Lầu Trân Bảo (NPC bán Linh Ngọc).", "info"), lvp < req)
			buy.custom_minimum_size = Vector2(120, 42)
			buy.add_theme_color_override("font_color", T.C_PURPLE)
			head.add_child(buy)
		inner.add_child(head)
		inner.add_child(T.label(str(d.get("fxText", "")), T.FS_S, T.C_TEXT))
		var sl := W.item_stat_lines(d)
		if not sl.is_empty(): inner.add_child(T.label("Cộng: " + " · ".join(sl), T.FS_S, T.C_GREEN))
		var card := W.card_row(inner)
		if on: card.add_theme_stylebox_override("panel", T.UISkin.tab(true))
		vb.add_child(card)
	return vb
