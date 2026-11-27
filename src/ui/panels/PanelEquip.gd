extends "res://src/ui/panels/PanelBase.gd"
## Trang bị + nhân vật (build_equip, build_char). Dùng chung trạng thái/hàm trợ giúp qua PanelBase; hub = GamePanels.gd.

const EQUIP_SLOTS := ["weapon", "mu", "ao", "gang_tay", "dai_lung", "quan", "giay", "nhan", "day_chuyen", "ngoc_boi"]

const EQUIP_NAMES := {"weapon": "Vũ khí", "mu": "Mũ", "ao": "Áo", "gang_tay": "Găng tay", "dai_lung": "Đai lưng", "quan": "Quần",
	"giay": "Giày", "nhan": "Nhẫn", "day_chuyen": "Dây chuyền", "ngoc_boi": "Ngọc bội"}

const PERK_GLYPH := {"y_chi_thay": "@flame", "nhan_thuc_ky_sinh": "@orb", "lien_minh": "@shield", "binh_minh": "@blade",
	"tu_do": "@wind", "ket_cuc_pha_chuoi": "@bolt", "ket_cuc_giu_loi": "@heal", "ket_cuc_viet_lai": "@star"}

func _equip_col(slots: Array, eq: Dictionary) -> VBoxContainer:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	col.size_flags_vertical = Control.SIZE_EXPAND_FILL
	for sl in slots:
		var it: Variant = eq.get(sl, null)
		var pair := _equip_id_plus(it)
		var slot := str(sl)
		var filled := not str(pair[0]).is_empty()
		var is_sel: bool = selected_where == "equip" and selected_key == slot
		var on_tap := func():
			if not filled or is_sel: _deselect()
			else: _select("equip", slot)
		var cell := W.equip_cell(str(EQUIP_NAMES.get(sl, sl)), str(pair[0]), int(pair[1]), is_sel, on_tap, Formulas.is_broken(it))
		var cc := CenterContainer.new()
		cc.size_flags_vertical = Control.SIZE_EXPAND_FILL
		cc.add_child(cell)
		col.add_child(cc)
	return col

## Chuẩn hoá giá trị ô trang bị: Dictionary {id, plus} hoặc chuỗi id thuần.
static func _equip_id_plus(it: Variant) -> Array:
	if typeof(it) == TYPE_DICTIONARY:
		return [str((it as Dictionary).get("id", "")), int((it as Dictionary).get("plus", 0))]
	if typeof(it) == TYPE_STRING and str(it) != "":
		return [str(it), 0]
	return ["", 0]

func build_equip() -> Control:
	var vb := _vb()
	var pl := p()
	var eq: Dictionary = pl.get("equip", {})
	var school := str(pl.get("school", "kiem_si"))
	# Giữa: khung nhân vật (có menu nhỏ nổi lên khi chạm một ô) + 5 ô Kỳ Nguyên ngay dưới chân.
	var mid := _vb(6)
	mid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var frame := PanelContainer.new()
	frame.add_theme_stylebox_override("panel", T.UISkin.inset(6))
	frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	frame.clip_contents = true
	frame.add_child(_equip_stage_bg())
	var body := W.char_body(school, Vector2(140, 190))
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var bm := MarginContainer.new()
	bm.add_theme_constant_override("margin_bottom", 44)
	bm.add_theme_constant_override("margin_top", 6)
	bm.add_child(body)
	frame.add_child(bm)
	frame.add_child(_equip_stat_strip())
	if selected_where == "equip" and not str(_equip_id_plus(eq.get(selected_key, null))[0]).is_empty():
		frame.add_child(_equip_popup(selected_key, eq))
	mid.add_child(frame)
	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 10)
	cols.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cols.alignment = BoxContainer.ALIGNMENT_CENTER
	cols.add_child(_equip_col(["weapon", "mu", "ao", "gang_tay", "dai_lung"], eq))
	cols.add_child(mid)
	cols.add_child(_equip_col(["quan", "giay", "nhan", "day_chuyen", "ngoc_boi"], eq))
	mid.custom_minimum_size = Vector2(290, 0)
	mid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vb.add_child(W.fill(cols))
	return W.fill(vb)

## Nền sân khấu cho khung nhân vật: quầng sáng xanh phía sau, bóng đổ và vòng sáng dưới chân.
func _equip_stage_bg() -> Control:
	var g := Control.new()
	g.mouse_filter = Control.MOUSE_FILTER_IGNORE
	g.draw.connect(func():
		var sz := g.size
		var c := Vector2(sz.x * 0.5, sz.y * 0.42)
		for i in range(16):
			var t := float(i) / 15.0
			g.draw_circle(c, lerpf(sz.y * 0.66, sz.y * 0.07, t), Color(0.30, 0.46, 0.92, 0.03 + 0.012 * t))
		var foot := Vector2(sz.x * 0.5, sz.y - 52.0)
		g.draw_set_transform(foot, 0.0, Vector2(1.0, 0.24))
		for i in range(6):
			g.draw_circle(Vector2.ZERO, sz.x * 0.30 * (1.0 - float(i) * 0.12), Color(0.0, 0.0, 0.0, 0.16))
		g.draw_arc(Vector2.ZERO, sz.x * 0.30, 0.0, TAU, 40, Color(T.C_GOLD, 0.35), 1.6, true)
		g.draw_arc(Vector2.ZERO, sz.x * 0.22, 0.0, TAU, 32, Color(T.C_GOLD, 0.18), 1.2, true)
		g.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE))
	return g

## Dải chỉ số tóm tắt dưới chân nhân vật: Tấn công / Phòng thủ / Máu.
func _equip_stat_strip() -> Control:
	var st: Dictionary = Game.stats
	if st.is_empty(): st = p().get("stats", {})
	var v := VBoxContainer.new()
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sp := Control.new()
	sp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(sp)
	var h := HBoxContainer.new()
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_theme_constant_override("separation", 4)
	h.add_child(_stat_cell("@blade", "", W.fmt_num(int(st.get("atk", 0))), T.C_GOLD))
	h.add_child(_stat_cell("@shield", "", W.fmt_num(int(st.get("def", 0))), T.C_BLUE))
	h.add_child(_stat_cell("@heal", "", W.fmt_num(int(st.get("maxHp", 0))), T.C_RED))
	for c in h.get_children(): c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(h)
	return v

## Chạm một ô đã có đồ: hiện menu nhỏ giữa khung nhân vật với "Xem chi tiết" / "Tháo ra".
func _equip_popup(slot: String, eq: Dictionary) -> Control:
	var pair := _equip_id_plus(eq.get(slot, null))
	var iid := str(pair[0])
	var plus := int(pair[1])
	var d: Dictionary = Data.item(iid)
	var q := int(d.get("q", 0))
	var do_unequip := func():
		act("unequip", {"slot": slot})
		_deselect()
	if equip_detail:
		var box := PanelContainer.new()
		box.add_theme_stylebox_override("panel", T.UISkin.inset(8))
		var v := _vb(6)
		box.add_child(v)
		var sc := TouchScroll.new()
		sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
		sc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		var det := W.item_detail(iid, plus, false, (eq.get(slot, {}) as Dictionary) if typeof(eq.get(slot, null)) == TYPE_DICTIONARY else {})
		det.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		sc.add_child(det)
		v.add_child(sc)
		var eq_entry: Variant = eq.get(slot, null)
		if typeof(eq_entry) == TYPE_DICTIONARY: _nhiem_block(v, eq_entry, {"slot": slot})
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		var back := W.action_button("Quay lại", func(): equip_detail = false; refresh())
		back.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var off := W.action_button("Tháo ra", do_unequip)
		off.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(back); row.add_child(off)
		v.add_child(row)
		return box
	var ov := VBoxContainer.new()
	ov.add_theme_constant_override("separation", 0)
	# Vùng trống phía trên: chạm vào để đóng menu.
	var catcher := Button.new()
	catcher.flat = true
	catcher.focus_mode = Control.FOCUS_NONE
	catcher.size_flags_vertical = Control.SIZE_EXPAND_FILL
	for st in ["normal", "hover", "pressed", "focus"]: catcher.add_theme_stylebox_override(st, StyleBoxEmpty.new())
	catcher.pressed.connect(func(): _deselect())
	ov.add_child(catcher)
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", T.UISkin.card(8))
	card.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var v2 := _vb(6)
	card.add_child(v2)
	var nm := T.label(str(d.get("name", iid)) + ((" +%d" % plus) if plus > 0 else ""), T.FS_M, T.quality_color(q) if q > 1 else T.C_GOLD, true)
	nm.autowrap_mode = TextServer.AUTOWRAP_OFF
	v2.add_child(nm)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 6)
	var b_det := W.action_button("Chi tiết", func(): equip_detail = true; refresh())
	b_det.custom_minimum_size = Vector2(96, 34)
	var b_off := W.action_button("Tháo ra", do_unequip)
	b_off.custom_minimum_size = Vector2(96, 34)
	b_off.add_theme_color_override("font_color", T.C_RED)
	hb.add_child(b_det); hb.add_child(b_off)
	v2.add_child(hb)
	ov.add_child(card)
	return ov

## Nhóm có tiêu đề nhỏ viết hoa + khung nền.
func _group(title: String, inner: Control, right_text: String = "") -> Control:
	var box := _vb(8)
	var hr := HBoxContainer.new()
	var t := T.overline(title)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hr.add_child(t)
	if not right_text.is_empty():
		var rt := T.label(right_text, T.FS_S, T.C_GOLD, true)
		rt.autowrap_mode = TextServer.AUTOWRAP_OFF
		hr.add_child(rt)
	box.add_child(hr)
	box.add_child(inner)
	return W.card_row(box)

func _grid2(cells: Array) -> GridContainer:
	var g := GridContainer.new()
	g.columns = 2
	g.add_theme_constant_override("h_separation", 6)
	g.add_theme_constant_override("v_separation", 6)
	for c in cells: g.add_child(c)
	return g

func _row_text(a: String, b: String, b_color: Color) -> Control:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	var l := T.label(a, T.FS_M, T.C_TEXT, true)
	l.autowrap_mode = TextServer.AUTOWRAP_OFF
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(l)
	var r := T.label(b, T.FS_S, b_color)
	r.autowrap_mode = TextServer.AUTOWRAP_OFF
	h.add_child(r)
	return h

func _char_set_rows(pl: Dictionary) -> Control:
	var counts := {}
	var sets: Array = Data.calc.get("SETS", [])
	var per := maxi(1, int(Data.calc.get("SET_LEVELS", 10)))
	var eq: Dictionary = pl.get("equip", {}) if typeof(pl.get("equip", {})) == TYPE_DICTIONARY else {}
	for slot in Data.calc.get("SLOTS", []):
		var it: Variant = eq.get(slot, null)
		if typeof(it) != TYPE_DICTIONARY: continue
		if Formulas.is_broken(it): continue
		var d: Dictionary = Data.item(str((it as Dictionary).get("id", "")))
		if str(d.get("slot", "")).is_empty() or sets.is_empty(): continue
		var idx := mini(sets.size() - 1, (maxi(1, int(d.get("level", 1))) - 1) / per)
		counts[idx] = int(counts.get(idx, 0)) + 1
	var lo := int(Data.calc.get("SET_TIER_LOW", 6))
	var hi := int(Data.calc.get("SET_TIER_HIGH", 10))
	var box := _vb(6)
	var idxs: Array = counts.keys()
	idxs.sort()
	for idx in idxs:
		var n := int(counts[idx])
		var nm := str((sets[int(idx)] as Dictionary).get("name", "Bộ"))
		var note := "đủ bộ, hiệu ứng đang chạy" if n >= hi else ("còn %d món để đủ bộ" % (hi - n) if n >= lo else "cần %d món mới có thưởng" % lo)
		var col: Color = T.C_GOLD if n >= hi else (T.C_GREEN if n >= lo else T.C_MUTED)
		box.add_child(_row_text(nm, "%d/%d · %s" % [n, hi, note], col))
	if idxs.is_empty(): return null
	return _group("Bộ trang bị", box)

func _char_ky_nguyen(pl: Dictionary) -> Control:
	var kn: Dictionary = pl.get("kyNguyen", {}) if typeof(pl.get("kyNguyen", {})) == TYPE_DICTIONARY else {}
	var owned: Array = kn.get("owned", [])
	var active: Array = kn.get("active", [])
	var ids: Array = []
	for iid in Data.ITEMS.keys():
		if bool((Data.ITEMS[iid] as Dictionary).get("kyNguyen", false)): ids.append(str(iid))
	ids.sort_custom(func(a, b): return int(Data.item(a).get("level", 0)) < int(Data.item(b).get("level", 0)))
	var lvp := int(pl.get("level", 1))
	var box := _vb(6)
	for sid in ids:
		var d: Dictionary = Data.item(sid)
		var have: bool = sid in owned
		var on: bool = sid in active
		var req := int(d.get("level", 1))
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 8)
		var fr := PanelContainer.new()
		fr.add_theme_stylebox_override("panel", T.UISkin.slot(5 if on else (4 if have else 0), on))
		fr.add_child(W.item_icon(sid, 30))
		fr.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(fr)
		var col := _vb(0)
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		col.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var nl := T.label(str(d.get("name", sid)).replace("Kỳ Nguyên · ", ""), T.FS_M, T.C_GOLD if have else T.C_TEXT, true)
		nl.autowrap_mode = TextServer.AUTOWRAP_OFF
		col.add_child(nl)
		var state := "đang bật" if on else ("đang tháo" if have else ("cần cấp %d" % req if lvp < req else "mua ở Lầu Trân Bảo"))
		var sl := T.label(state, 11, T.C_GREEN if on else T.C_MUTED)
		sl.autowrap_mode = TextServer.AUTOWRAP_OFF
		col.add_child(sl)
		var sl2 := T.label(", ".join(W.item_stat_lines(d)), 11, T.C_TEXT)
		sl2.custom_minimum_size = Vector2(150, 0)
		col.add_child(sl2)
		h.add_child(col)
		var tb := W.action_button("Tháo" if on else ("Trang bị" if have else "Chưa có"), func(): act("toggle_ky_nguyen", {"id": sid}), not have)
		tb.custom_minimum_size = Vector2(72, 34)
		tb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(tb)
		box.add_child(h)
	return _group("Kỳ Nguyên", box, "%d/%d" % [owned.size(), ids.size()])

func build_char() -> Control:
	var pl := p()
	var school := str(pl.get("school", "kiem_si"))
	var st: Dictionary = Game.stats
	if st.is_empty(): st = pl.get("stats", {})
	var lvl := int(pl.get("level", 1))
	var sd: Dictionary = Data.school(school)
	# ---------------- Cột trái
	var left := _vb(8)
	# Thẻ đầu: avatar | tên + lớp + EXP | cấp
	var hh := HBoxContainer.new()
	hh.add_theme_constant_override("separation", 10)
	var av := PanelContainer.new()
	av.add_theme_stylebox_override("panel", T.UISkin.slot(4, false))
	av.custom_minimum_size = Vector2(52, 52)
	av.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var ag := T.GlyphArt.make(T.GlyphArt.token_of(str(sd.get("icon", ""))), 34.0)
	ag.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	ag.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	av.add_child(ag)
	hh.add_child(av)
	var idc := _vb(2)
	idc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var nm0 := T.label(str(pl.get("name", "?")), T.FS_XL, T.C_GOLD, true)
	nm0.autowrap_mode = TextServer.AUTOWRAP_OFF
	idc.add_child(nm0)
	var sub := T.label("%s · Hạng %s" % [W.school_name(school), str(pl.get("rank", "E"))], T.FS_S, T.C_MUTED)
	sub.autowrap_mode = TextServer.AUTOWRAP_OFF
	idc.add_child(sub)
	var need := Formulas.exp_to_next(lvl)
	var xp := W._flat_bar(int(pl.get("exp", 0)), need, T.C_GOLD.darkened(0.1), 14)
	var xt := T.hud_label("%s / %s" % [W.fmt_num(int(pl.get("exp", 0))), W.fmt_num(need)], 10, Color.WHITE, true)
	xt.set_anchors_preset(Control.PRESET_FULL_RECT)
	xt.autowrap_mode = TextServer.AUTOWRAP_OFF
	xt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	xt.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	xt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	xp.add_child(xt)
	idc.add_child(xp)
	hh.add_child(idc)
	var lc := _vb(0)
	lc.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var lcap := T.label("Cấp", T.FS_S, T.C_MUTED)
	lcap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lc.add_child(lcap)
	var lnum := T.label(str(lvl), 30, T.C_GOLD, true)
	lnum.autowrap_mode = TextServer.AUTOWRAP_OFF
	lnum.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lc.add_child(lnum)
	hh.add_child(lc)
	left.add_child(W.card_row(hh))
	# Chiến đấu / chi tiết
	left.add_child(_group("Chiến đấu", _grid2([
		_stat_cell("@heal", "Máu", W.fmt_num(int(st.get("maxHp", 0))), T.C_RED),
		_stat_cell("@drop", "Năng lượng", W.fmt_num(int(st.get("maxMp", 0))), T.C_BLUE),
		_stat_cell("@blade", "Tấn công", W.fmt_num(int(st.get("atk", 0))), T.C_GOLD),
		_stat_cell("@shield", "Phòng thủ", W.fmt_num(int(st.get("def", 0))), T.C_BLUE)])))
	left.add_child(_group("Chi tiết", _grid2([
		_stat_cell("@bolt", "Chí mạng", "%s%%" % str(snappedf(float(st.get("crit", 0)), 0.1)), T.C_GOLD),
		_stat_cell("@star", "Kỹ năng", "%d%%" % roundi(float(st.get("skillMul", 1.0)) * 100.0), T.C_PURPLE),
		_stat_cell("@wind", "Tốc chạy", str(int(st.get("speed", 0))), T.C_GREEN)])))
	var sets_box := _char_set_rows(pl)
	if sets_box: left.add_child(sets_box)
	left.add_child(_char_ky_nguyen(pl))
	var info := _vb(6)
	info.add_child(_row_text("Giảm giá cửa hàng", "%d%%" % roundi(float(pl.get("shopDiscount", 0)) * 100.0), T.C_MUTED))
	var titles: Array = pl.get("titles", []) if typeof(pl.get("titles", [])) == TYPE_ARRAY else []
	info.add_child(_row_text("Danh hiệu", "Chưa có" if titles.is_empty() else str(titles.size()), T.C_MUTED))
	for t in titles:
		var tl := T.label("· " + str(t), T.FS_S, T.C_GOLD)
		tl.autowrap_mode = TextServer.AUTOWRAP_OFF
		info.add_child(tl)
	if str(sd.get("desc", "")) != "":
		var ds := T.label(str(sd.get("desc", "")), 12, T.C_MUTED)
		ds.custom_minimum_size = Vector2(220, 0)
		info.add_child(ds)
	left.add_child(_group("Thông tin", info))
	# ---------------- Cột phải
	var right := _vb(8)
	var free_pts := int(pl.get("freePoints", 0))
	var pts: Dictionary = pl.get("points", {}) if typeof(pl.get("points", {})) == TYPE_DICTIONARY else {}
	var pbox := _vb(6)
	for e in [["str", "Sức mạnh", "@blade", "+2 tấn công"], ["vit", "Thể lực", "@heal", "+10 máu, +0.8 phòng thủ"],
			["agi", "Nhanh nhẹn", "@wind", "+0.4% chí mạng, tốc chạy"], ["spi", "Tinh thần", "@drop", "+6 NL, +1.5% sức mạnh KN"]]:
		var key := str(e[0])
		var pr := PanelContainer.new()
		pr.add_theme_stylebox_override("panel", T.UISkin.inset(7))
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 8)
		var g := T.GlyphArt.make(str(e[2]), 20.0, T.C_TEXT)
		g.custom_minimum_size = Vector2(22, 22)
		g.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(g)
		var col := _vb(0)
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		col.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var nr := HBoxContainer.new()
		nr.add_theme_constant_override("separation", 6)
		var nl := T.label(str(e[1]), T.FS_M, T.C_TEXT, true)
		nl.autowrap_mode = TextServer.AUTOWRAP_OFF
		nr.add_child(nl)
		var vl := T.label(str(int(pts.get(key, 0))), T.FS_M, T.C_GOLD, true)
		vl.autowrap_mode = TextServer.AUTOWRAP_OFF
		nr.add_child(vl)
		col.add_child(nr)
		var hl := T.label(str(e[3]), 11, T.C_MUTED)
		hl.autowrap_mode = TextServer.AUTOWRAP_OFF
		hl.clip_text = true
		col.add_child(hl)
		h.add_child(col)
		var b1 := W.action_button("+1", func(): act("add_stat", {"stat": key, "n": 1}), free_pts < 1)
		var b5 := W.action_button("+5", func(): act("add_stat", {"stat": key, "n": 5}), free_pts < 5)
		b1.custom_minimum_size = Vector2(44, 34); b5.custom_minimum_size = Vector2(44, 34)
		b1.size_flags_vertical = Control.SIZE_SHRINK_CENTER; b5.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(b1); h.add_child(b5)
		pr.add_child(h)
		pbox.add_child(pr)
	right.add_child(_group("Điểm tiềm năng", pbox, str(free_pts)))
	# Hình thái
	var unlocked := int(pl.get("awakenTier", 0))
	if unlocked >= 1:
		var cur := maxi(1, Data.awaken_tier_of(pl.get("formChoice", "")))
		var fb := _vb(6)
		var fh := HBoxContainer.new()
		var ft := T.label("Biến Hình %s" % str(Data.ROMAN[cur - 1]), T.FS_M, T.C_TEXT, true)
		ft.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fh.add_child(ft)
		var fs_l := T.label("Đang biến hình" if Game.form_active else "Dạng thường", T.FS_S, T.C_GOLD if Game.form_active else T.C_MUTED)
		fs_l.autowrap_mode = TextServer.AUTOWRAP_OFF
		fh.add_child(fs_l)
		fb.add_child(fh)
		var fr := HBoxContainer.new()
		fr.add_theme_constant_override("separation", 6)
		for t in range(1, unlocked + 1):
			var tt := t
			var fbn := W.action_button("Biến Hình %s" % str(Data.ROMAN[t - 1]), func(): act("form_select", {"choice": "awaken%d" % tt}))
			fbn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			if tt == cur: fbn.add_theme_color_override("font_color", T.C_GOLD)
			fr.add_child(fbn)
		fb.add_child(fr)
		right.add_child(_group("Hình thái", fb))
	# Nội tại cốt truyện
	var perks: Array = pl.get("perks", []) if typeof(pl.get("perks", [])) == TYPE_ARRAY else []
	var pdefs: Dictionary = Data.calc.get("PERKS", {})
	var kb := _vb(6)
	var shown := 0
	for pid in perks:
		var pk: Dictionary = pdefs.get(str(pid), {}) if typeof(pdefs.get(str(pid), {})) == TYPE_DICTIONARY else {}
		if pk.is_empty(): continue
		shown += 1
		var pr2 := PanelContainer.new()
		pr2.add_theme_stylebox_override("panel", T.UISkin.inset(8))
		var h2 := HBoxContainer.new()
		h2.add_theme_constant_override("separation", 10)
		var g2 := T.GlyphArt.make(str(PERK_GLYPH.get(str(pid), "@star")), 24.0, T.C_GOLD)
		g2.custom_minimum_size = Vector2(26, 26)
		g2.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h2.add_child(g2)
		var c2 := _vb(1)
		c2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var pn := T.label(str(pk.get("name", pid)), T.FS_M, T.C_TEXT, true)
		pn.autowrap_mode = TextServer.AUTOWRAP_OFF
		c2.add_child(pn)
		var pd := T.label(str(pk.get("desc", "")), 12, T.C_MUTED)
		pd.custom_minimum_size = Vector2(180, 0)
		c2.add_child(pd)
		h2.add_child(c2)
		pr2.add_child(h2)
		kb.add_child(pr2)
	if shown == 0:
		kb.add_child(T.label("Chưa có nội tại. Nội tại mở khi bạn đưa ra lựa chọn trong cốt truyện.", 12, T.C_MUTED))
	right.add_child(_group("Nội tại cốt truyện", kb))
	var vb := _vb()
	vb.add_child(W.split(left, right, 300.0))
	return W.fill(vb)
