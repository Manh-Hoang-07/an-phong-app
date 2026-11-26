extends RefCounted
## 19 panel game, port từ web public/js/ui/panels/*.js. Bố cục hai cột (danh sách + chi tiết) cho điện thoại ngang.
## Mọi thao tác gọi Net.action(type, params); luật chơi ở server. host = MobileHUD.

const T := preload("res://src/ui/UITheme.gd")
const TouchScroll := preload("res://src/ui/TouchScroll.gd")
const MobSpriteCls := preload("res://src/world/MobSprite.gd")
const W := preload("res://src/ui/PanelWidgets.gd")

# Trạng thái UI cục bộ (tương đương S của web)
var selected_where := ""
var selected_key := ""
var confirm_drop := ""
var confirm_release := -1
var confirm_buy := ""
var equip_detail := false
var pet_sel := ""
var shop_tab := "buy"
var shop_qty := 1
var smith_tab := "upgrade"
var storage_tab := "store"
var bag_filter := "all"
var npc_id := ""
var code_draft := ""
var code_msg := ""
var ctx_extra: Dictionary = {}

var host: Object = null

func _init(_host: Object) -> void:
	host = _host

func p() -> Dictionary:
	return Game.player

func act(type: String, params: Dictionary = {}, silent: bool = true) -> void:
	if type == "use":
		# Bình thuốc: server cộng vào máu/MP tức thời của client (như web), không phải giá trị lưu cũ
		params = params.duplicate()
		params["hp"] = Game.hp
		params["mp"] = Game.mp
	Net.action(type, params)
	if not silent and host: host.toast("Đang xử lý…")

func refresh() -> void:
	if host and host.has_method("refresh_panel"): host.refresh_panel()

func _vb(sep: int = 10) -> VBoxContainer:
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", sep)
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return vb

func _select(where: String, key: String) -> void:
	selected_where = where; selected_key = key
	confirm_drop = ""; confirm_buy = ""; equip_detail = false; refresh()

func _deselect() -> void:
	selected_where = ""; selected_key = ""; confirm_drop = ""; confirm_buy = ""; equip_detail = false; refresh()

func _gold_row(pl: Dictionary, ngoc: bool = true) -> Control:
	var items: Array = [["Vàng  %s" % W.full_num(int(pl.get("gold", 0))), T.C_GOLD]]
	if ngoc: items.append(["Linh Ngọc  %s" % W.full_num(int(pl.get("linhNgoc", 0))), T.C_PURPLE])
	return W.chip_row(items)

func _bag_entry(uid: String) -> Dictionary:
	for x in p().get("bag", []):
		if typeof(x) == TYPE_DICTIONARY and str(x.get("uid", "")) == uid: return x
	return {}

## Trạng thái rỗng: icon mờ + lời hướng dẫn, căn giữa.
func _empty(text: String, icon_name: String = "bag") -> Control:
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.custom_minimum_size = Vector2(0, 130)
	box.add_theme_constant_override("separation", 8)
	var ic := T.icon_rect(icon_name, 40.0, Color(T.C_MUTED, 0.45))
	ic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(ic)
	var l := T.label(text, T.FS_S, Color(T.C_MUTED, 0.9))
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(l)
	return box

func _grid(cols: int) -> GridContainer:
	return W.grid(cols)

# ============================================================ BAG
func build_bag() -> Control:
	var vb := _vb()
	var pl := p()
	var bag: Array = pl.get("bag", [])
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 8)
	top.add_child(_gold_row(pl))
	var cap := T.label("Túi %d/%d" % [bag.size(), Game.bag_size()], T.FS_S, T.C_MUTED)
	cap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	top.add_child(cap)
	vb.add_child(top)
	var g := _grid(6)
	var shown := 0
	for i in range(bag.size()):
		var e: Dictionary = bag[i] if typeof(bag[i]) == TYPE_DICTIONARY else {}
		shown += 1
		var uid := str(e.get("uid", i))
		g.add_child(W.item_cell(str(e.get("id", "")), int(e.get("n", e.get("qty", 1))), selected_where == "bag" and selected_key == uid, func(): _select("bag", uid)))
	var cap_n := Game.bag_size()
	for _i in range(shown, cap_n): g.add_child(W.empty_cell())
	var left_box := _vb(8)
	left_box.add_child(g)
	var left: Control = left_box
	var right: Control = W.empty_detail()
	if selected_where == "bag":
		var e2 := _bag_entry(selected_key)
		if not e2.is_empty(): right = _bag_detail(e2)
	vb.add_child(W.split(left, right))
	return W.fill(vb)

func _bag_match(iid: String) -> bool:
	if bag_filter == "all": return true
	var d: Dictionary = Data.item(iid)
	var is_gear := not str(d.get("slot", "")).is_empty()
	var kind := str(d.get("kind", ""))
	var is_use := kind in ["potion", "boost", "book", "potential_book", "skill_book", "ult_book", "transform_book", "slot_book", "erase_book"]
	match bag_filter:
		"gear": return is_gear
		"use": return is_use and not is_gear
		_: return not is_gear and not is_use

## Vết Nhiễm đỏ: cảnh báo (trừ máu, chặn hồi máu ngoài giao chiến) + nút gột bằng Thuốc chữa nhiễm đỏ (cleanse_nhiem).
func _nhiem_block(parent: Control, entry: Dictionary, params: Dictionary) -> void:
	var n := int(entry.get("nhiem", 0))
	if n <= 0: return
	var meds := 0
	var bag: Variant = p().get("bag", [])
	if typeof(bag) == TYPE_ARRAY:
		for b in bag:
			if typeof(b) == TYPE_DICTIONARY and str((b as Dictionary).get("id", "")) == "thuoc_nhiem_do": meds += int((b as Dictionary).get("qty", (b as Dictionary).get("n", 1)))
	var warn := T.label("Nhiễm đỏ bậc %d: chỉ số chính +18%%, máu tối đa -%d%%, không hồi máu ngoài giao chiến." % [n, 6 * n], T.FS_S, T.C_RED)
	warn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(warn)
	var pl := p()
	var at_herb := Data.herb_shop_here(pl, str(pl.get("map", "")))
	var btn := W.action_button("Gột bằng Thuốc chữa nhiễm đỏ (%d)" % meds, func(): act("cleanse_nhiem", params), meds <= 0 or not at_herb)
	if not at_herb: btn.tooltip_text = "Hãy đến gặp Dược sư để gột vết nhiễm."
	parent.add_child(btn)

func _bag_detail(e: Dictionary) -> Control:
	var iid := str(e.get("id", ""))
	var d: Dictionary = Data.item(iid)
	var box := W.item_detail(iid, int(e.get("plus", 0)), true, e)
	var body := W.box_body(box)
	var uidn := int(e.get("uid", 0))
	var qty := int(e.get("n", e.get("qty", 1)))
	if qty > 1: body.add_child(T.label("Số lượng: %d" % qty, T.FS_S, T.C_TEXT))
	if not str(d.get("slot", "")).is_empty():
		body.add_child(W.action_button("Trang bị", func(): act("equip", {"uid": uidn}); _deselect()))
		_nhiem_block(body, e, {"uid": uidn})
	var dkind := str(d.get("kind", ""))
	if dkind in ["book", "potential_book", "skill_book", "ult_book", "slot_book", "erase_book", "transform_book"]:
		body.add_child(W.action_button("Đọc sách", func(): act("use", {"item": iid})))
	elif dkind == "boost":
		body.add_child(W.action_button("Sử dụng", func(): act("use_boost", {"item": iid})))
	elif dkind in ["potion", "buff", "box", "food", "consumable"]:
		body.add_child(W.action_button("Sử dụng", func(): act("use", {"item": iid})))
	elif d.has("hp") or d.has("mp"):
		body.add_child(W.action_button("Sử dụng", func(): act("use", {"item": iid})))
	if int(d.get("price", 0)) > 0 and str(d.get("kind", "")) != "quest" and Data.shop_here(p(), str(p().get("map", ""))):
		body.add_child(W.action_button("Bán 1", func(): act("sell", {"uid": uidn, "qty": 1}); _deselect()))
		if qty > 1: body.add_child(W.action_button("Bán %d" % qty, func(): act("sell", {"uid": uidn, "qty": qty}); _deselect()))
	if str(d.get("kind", "")) != "quest":
		var do_drop := func(n: int):
			act("drop", {"uid": uidn, "qty": n})
			_deselect()
		var drop1 := W.action_button("Vứt 1" if qty > 1 else "Vứt đi", func():
			host.confirm("Vứt vật phẩm?", "Bạn sắp vứt 1 %s. Không thể lấy lại." % str(d.get("name", iid)), "Vứt", func(): do_drop.call(1), true))
		drop1.add_theme_color_override("font_color", T.C_RED)
		body.add_child(drop1)
		if qty > 1:
			var dropall := W.action_button("Vứt hết %d" % qty, func():
				host.confirm("Vứt vật phẩm?", "Bạn sắp vứt %s ×%d. Không thể lấy lại." % [str(d.get("name", iid)), qty], "Vứt", func(): do_drop.call(qty), true))
			dropall.add_theme_color_override("font_color", T.C_RED)
			body.add_child(dropall)
	return box

# ============================================================ EQUIP
const EQUIP_SLOTS := ["weapon", "mu", "ao", "gang_tay", "dai_lung", "quan", "giay", "nhan", "day_chuyen", "ngoc_boi"]
const EQUIP_NAMES := {"weapon": "Vũ khí", "mu": "Mũ", "ao": "Áo", "gang_tay": "Găng tay", "dai_lung": "Đai lưng", "quan": "Quần",
	"giay": "Giày", "nhan": "Nhẫn", "day_chuyen": "Dây chuyền", "ngoc_boi": "Ngọc bội"}

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
		var cell := W.equip_cell(str(EQUIP_NAMES.get(sl, sl)), str(pair[0]), int(pair[1]), is_sel, func():
			if not filled or is_sel: _deselect()
			else: _select("equip", slot))
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

# ============================================================ CHAR
## Ô chỉ số: icon | nhãn | giá trị (giống web: nền thẻ tối, số đậm bên phải).
func _stat_cell(glyph: String, label_text: String, value: String, color: Color) -> Control:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", T.UISkin.inset(7))
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 6)
	var g := T.GlyphArt.make(glyph, 18.0, color)
	g.custom_minimum_size = Vector2(20, 20)
	g.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(g)
	if label_text.is_empty():
		h.alignment = BoxContainer.ALIGNMENT_CENTER
	else:
		var l := T.label(label_text, 11, T.C_MUTED)
		l.autowrap_mode = TextServer.AUTOWRAP_OFF
		l.clip_text = true
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(l)
	var v := T.label(value, T.FS_M, T.C_TEXT, true)
	v.autowrap_mode = TextServer.AUTOWRAP_OFF
	v.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(v)
	p.add_child(h)
	return p

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

const PERK_GLYPH := {"y_chi_thay": "@flame", "nhan_thuc_ky_sinh": "@orb", "lien_minh": "@shield", "binh_minh": "@blade",
	"tu_do": "@wind", "ket_cuc_pha_chuoi": "@bolt", "ket_cuc_giu_loi": "@heal", "ket_cuc_viet_lai": "@star"}

func _char_set_rows(pl: Dictionary) -> Control:
	var counts := {}
	var sets: Array = Data.calc.get("SETS", [])
	var per := maxi(1, int(Data.calc.get("SET_LEVELS", 10)))
	var eq: Dictionary = pl.get("equip", {}) if typeof(pl.get("equip", {})) == TYPE_DICTIONARY else {}
	for slot in Data.calc.get("SLOTS", []):
		var it: Variant = eq.get(slot, null)
		if typeof(it) != TYPE_DICTIONARY: continue
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

# ============================================================ SKILLS
const SKILL_TYPES := {"dash": "Lướt", "melee": "Cận chiến", "guard": "Thủ thế", "buff": "Cường hóa", "sword_fall": "Kiếm giáng", "aoe": "Diện rộng",
	"projectile": "Phóng", "spread": "Tỏa", "backstep": "Lùi chém", "arrow_rain": "Mưa tên", "heal": "Hồi phục", "manashield": "Khiên năng lượng",
	"meteor": "Thiên thạch", "summon": "Triệu hồi", "shadow_toggle": "Bóng ma", "shadow_command": "Lệnh bóng", "execute": "Hành quyết",
	"fusion": "Hợp thể", "manaburst": "Bùng nổ", "allin": "Tất tay"}

## Thông số kỹ năng ở một cấp, đúng công thức server (shared/logic/skills.js): MP × hệ số tiêu hao như web.
## Cấp kỹ năng mượn từ trang bị: theo cấp nhân vật (12→1, 40→5, 80→10), khớp gearSkillLevel của web.
func _gear_skill_level(pl: Dictionary) -> int:
	return mini(10, maxi(1, int(pl.get("level", 1)) / 8))

func _sk_at(sid: String, lv: int) -> Dictionary:
	var d: Dictionary = Data.skill_at(sid, maxi(1, lv))
	if d.is_empty(): return d
	d["mp"] = roundi(float(d.get("mp", 0)) * float(Game.stats.get("costMul", 1.0)))
	return d

func _sk_line(sid: String, lv: int) -> String:
	var d := _sk_at(sid, lv)
	return "MP %d · Hồi %s" % [int(d.get("mp", 0)), Data.cd_text(float(d.get("cd", 0)))]

func _skill_detail(sid: String, learned: Dictionary, pl: Dictionary) -> Control:
	var d0: Dictionary = Data.skill(sid)
	var is_super := bool(d0.get("superUlt", false)) and _supers_of(pl).has(sid)
	var is_learned := learned.has(sid) or is_super
	var lv := 0
	if is_learned: lv = int((learned[sid] as Dictionary).get("lv", 1)) if typeof(learned.get(sid, null)) == TYPE_DICTIONARY else int(learned.get(sid, 1))
	elif sid == _gear_skill_of(pl): lv = _gear_skill_level(pl)
	var d: Dictionary = _sk_at(sid, maxi(1, lv))
	var box := W.detail_box()
	var body := W.box_body(box)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 8)
	var gl := T.GlyphArt.make(W.skill_icon(sid), 48.0, T.C_TEXT, false, true)
	gl.custom_minimum_size = Vector2(48, 48)
	head.add_child(gl)
	var col := _vb(0)
	col.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	col.add_child(T.label(str(d.get("name", sid)), T.FS_M, T.C_GOLD, true))
	if is_super: col.add_child(T.label("Sở hữu · chỉ số cố định", T.FS_S, T.C_MUTED))
	elif not is_learned: col.add_child(T.label("Do trang bị cấp", T.FS_S, T.C_MUTED))
	head.add_child(col)
	body.add_child(head)
	var chips: Array = [[str(SKILL_TYPES.get(str(d.get("type", "")), "Kỹ năng")), T.C_PURPLE], ["MP %d" % int(d.get("mp", 0)), T.C_BLUE], ["Hồi %s" % Data.cd_text(float(d.get("cd", 0))), T.C_MUTED]]
	if bool(d.get("superUlt", false)): chips.push_front(["Tuyệt phẩm", Color("ff8a4a")])
	elif bool(d.get("ult", false)): chips.push_front(["Tuyệt kỹ", T.C_GOLD])
	var chip_flow := HFlowContainer.new()
	chip_flow.add_theme_constant_override("h_separation", 6)
	chip_flow.add_theme_constant_override("v_separation", 4)
	for c in chips: chip_flow.add_child(W.chip(str(c[0]), c[1] as Color))
	body.add_child(chip_flow)
	if is_learned and not is_super: body.add_child(W.bar("Cấp kỹ năng", lv, 10, T.C_GOLD))
	if not str(d.get("desc", "")).is_empty(): body.add_child(T.label(str(d["desc"]), T.FS_S, T.C_TEXT))
	var stat_bits: Array = []
	if d.has("power"): stat_bits.append("Sức mạnh ×%s" % str(snappedf(float(d["power"]), 0.01)))
	if d.has("hits"): stat_bits.append("%d nhát" % int(d["hits"]))
	if d.has("range"): stat_bits.append("Tầm %d" % int(d["range"]))
	if d.has("distance"): stat_bits.append("Xa %d" % int(d["distance"]))
	if d.has("duration"): stat_bits.append("Kéo dài %ss" % str(d["duration"]))
	# Hiệu ứng thật (khớp skillNumbers của web) — những cái này mới là thứ người chơi cần thấy.
	if d.has("heal"): stat_bits.append("Hồi %d%% máu" % roundi(float(d["heal"]) * 100.0))
	if d.has("mpHeal"): stat_bits.append("+%d%% năng lượng" % roundi(float(d["mpHeal"]) * 100.0))
	if d.has("reduce"): stat_bits.append("Giảm %d%% sát thương" % roundi(float(d["reduce"]) * 100.0))
	if d.has("reflect"): stat_bits.append("Phản %d%%" % roundi(float(d["reflect"]) * 100.0))
	if d.has("absorb"): stat_bits.append("Đỡ %d%% sát thương" % roundi(float(d["absorb"]) * 100.0))
	if d.has("atkBuff"): stat_bits.append("Tấn công %+d%%" % roundi(float(d["atkBuff"]) * 100.0))
	if d.has("critBuff"): stat_bits.append("Chí mạng +%d%%" % int(d["critBuff"]))
	if d.has("speedBuff"): stat_bits.append("Tốc đánh %+d%%" % roundi(float(d["speedBuff"]) * 100.0))
	if d.has("slow"): stat_bits.append("Làm chậm %ss" % str(d["slow"]))
	if d.has("freeze"): stat_bits.append("Đóng băng %ss" % str(d["freeze"]))
	if d.has("stun"): stat_bits.append("Choáng %ss" % str(d["stun"]))
	if d.has("knock") and bool(d["knock"]): stat_bits.append("Hất văng")
	if d.has("pierce") and bool(d["pierce"]): stat_bits.append("Xuyên")
	if d.has("chain"): stat_bits.append("Nổ lan %d%%" % roundi(float(d["chain"]) * 100.0))
	if d.has("radius"): stat_bits.append("Bán kính %d" % int(d["radius"]))
	if bool(d.get("selfZero", false)): stat_bits.append("Giết ngay · mình về 0 máu" + (" (Bùa giữ 1 máu)" if bool(d.get("buaSaves", false)) else ""))
	if str(d.get("type", "")) == "manaburst": stat_bits.append("Đốt sạch MP · phong ấn hồi năng lượng %ds" % int(d.get("lockSec", 10)))
	if str(d.get("type", "")) == "allin": stat_bits.append("Phong ấn mọi kỹ năng %ds" % int(d.get("lockSec", 60)))
	if str(d.get("type", "")) == "fusion": stat_bits.append("Dung hợp bóng ma %ds · bộ sưu tập mất trắng" % int(d.get("fusionSec", 60)))
	if not stat_bits.is_empty(): body.add_child(T.label(" · ".join(stat_bits), T.FS_S, T.C_GREEN))
	# Mốc nâng cấp
	for ms in [[5, "t5", "m5"], [10, "t10", "m10"]]:
		var txt := str(d.get(str(ms[1]), ""))
		if txt.is_empty(): continue
		var reached := is_learned and lv >= int(ms[0])
		body.add_child(T.label("%s Cấp %d: %s" % ["+" if reached else "·", int(ms[0]), txt], T.FS_S, T.C_GREEN if reached else Color(T.C_MUTED, 0.8)))
	var pts := int(pl.get("skillPoints", 0))
	if is_learned:
		if not is_super:
			var up := W.action_button("Nâng cấp (1 điểm)", func(): act("learn_skill", {"skill": sid}), pts < 1 or lv >= 10)
			body.add_child(up)
			if pts < 1: body.add_child(T.label("Cần ít nhất 1 điểm kỹ năng.", 12, Color(T.C_MUTED, 0.85)))
		body.add_child(T.label("Gán vào ô:", T.FS_S, T.C_MUTED))
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 4)
		var slots: Array = pl.get("skillSlots", [])
		var is_ult := bool(d.get("ult", false)) or bool(d.get("superUlt", false))
		var tn := str(Data.school(str(pl.get("school", ""))).get("base", str(pl.get("school", "")))) == "toan_nang"
		var targets: Array = ([5, 6, 7] if tn else [5, 6]) if is_ult else ([0, 1, 2, 3, 4] if tn else [0, 1, 2, 3])
		for i in targets:
			var idx: int = i
			var here := idx < slots.size() and str(slots[idx]) == sid
			var cap := ("Tuyệt %d" % (idx - 4)) if is_ult else str(idx + 1)
			var bt := W.action_button(cap, func(): act("set_skill", {"slot": idx, "skill": sid}); host.toast("Đã gán vào ô %s" % cap, "success"))
			bt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			bt.custom_minimum_size = Vector2(0, 38)
			if here: bt.add_theme_color_override("font_color", T.C_GOLD)
			row.add_child(bt)
		body.add_child(row)
		# Gỡ chiêu đang gắn khỏi ô (khớp nút ✕ của web, server nhận skill:null).
		for i in targets:
			var oi: int = i
			if oi < slots.size() and str(slots[oi]) == sid:
				var cap2 := ("Tuyệt %d" % (oi - 4)) if is_ult else str(oi + 1)
				body.add_child(W.action_button("Gỡ khỏi ô %s" % cap2, func(): act("set_skill", {"slot": oi, "skill": null})))
				break
	return box

func _gear_skill_of(pl: Dictionary) -> String:
	var eq: Variant = pl.get("equip", {})
	if typeof(eq) != TYPE_DICTIONARY: return ""
	for slot in (eq as Dictionary).keys():
		var it: Variant = (eq as Dictionary)[slot]
		if typeof(it) != TYPE_DICTIONARY: continue
		var g := str(Data.item(str((it as Dictionary).get("id", ""))).get("grantsSkill", ""))
		if g != "" and not Data.skill(g).is_empty() and not bool(Data.skill(g).get("ult", false)): return g
	return ""

## Tuyệt phẩm đã sở hữu: server lưu dạng {id: cấp} (cũ có thể là mảng id).
func _supers_of(pl: Dictionary) -> Array:
	var v: Variant = pl.get("superUlts", {})
	if typeof(v) == TYPE_DICTIONARY: return (v as Dictionary).keys()
	if typeof(v) == TYPE_ARRAY: return v
	return []

func build_skills() -> Control:
	var vb := _vb()
	var pl := p()
	var learned: Dictionary = pl.get("skills", {})
	var slots: Array = pl.get("skillSlots", [])
	var left := _vb(8)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 8)
	var lbl := T.label("Thanh kỹ năng", T.FS_S, T.C_MUTED, true)
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(lbl)
	top.add_child(W.chip_row([["Điểm  %d" % int(pl.get("skillPoints", 0)), T.C_GOLD]]))
	left.add_child(top)
	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 8)
	var tn_bar := str(Data.school(str(pl.get("school", ""))).get("base", str(pl.get("school", "")))) == "toan_nang"
	var slot_ids: Array = [0, 1, 2, 3, 4, 5, 6, 7] if tn_bar else [0, 1, 2, 3, 5, 6]
	for i in slot_ids:
		var raw: Variant = slots[i] if i < slots.size() else null
		var sid := "" if raw == null or str(raw) == "<null>" else str(raw)
		var idx: int = i
		var cap := ("Tuyệt %d" % (i - 4)) if i >= 5 else str(i + 1)
		bar.add_child(W.skill_cell(W.skill_icon(sid) if not sid.is_empty() else "", cap, selected_where == "skill" and not sid.is_empty() and selected_key == sid, func():
			if not sid.is_empty(): _select("skill", sid)))
	left.add_child(bar)
	left.add_child(T.label("Ô 1–4: kỹ năng thường · Ô 5–6: tuyệt kỹ hoặc tuyệt phẩm (R, X)", 12, Color(T.C_MUTED, 0.85)))
	# Nội tại class (khớp mục Nội tại của web).
	var passives: Array = Data.passives_of(pl)
	if not passives.is_empty():
		left.add_child(T.heading("Nội tại", T.C_GREEN))
		for pk in passives:
			var pd: Dictionary = Data.PASSIVES[str(pk)]
			left.add_child(W.glyph_row(str(pd.get("icon", "@star")), str(pd.get("name", pk)), str(pd.get("desc", "")), "", false, func() -> void: pass, T.C_GREEN))
	# Chỉ liệt kê kỹ năng ĐÃ HỌC, chia 3 nhóm riêng: thường / tuyệt kỹ / tuyệt phẩm.
	var supers: Array = _supers_of(pl)
	var group_normal: Array = []   # [sid, lv]
	var group_ult: Array = []
	for sk in learned.keys():
		var sid2 := str(sk)
		var d2: Dictionary = Data.skill(sid2)
		if d2.is_empty(): continue
		var lv2 := int((learned[sk] as Dictionary).get("lv", 1)) if typeof(learned[sk]) == TYPE_DICTIONARY else int(learned[sk])
		if bool(d2.get("ult", false)) or bool(d2.get("superUlt", false)): group_ult.append([sid2, lv2])
		else: group_normal.append([sid2, lv2])

	var gsid := _gear_skill_of(pl)
	if gsid != "":
		var gd: Dictionary = Data.skill(gsid)
		left.add_child(T.heading("Kỹ năng trang bị", Color(0.45, 0.92, 0.7)))
		var glv := _gear_skill_level(pl)
		left.add_child(W.glyph_row(W.skill_icon(gsid), str(gd.get("name", gsid)), "Do trang bị cấp · cấp %d · MP %d" % [glv, int(_sk_at(gsid, glv).get("mp", 0))], "Trang bị", selected_where == "skill" and selected_key == gsid, func(): _select("skill", gsid), Color(0.45, 0.92, 0.7)))

	left.add_child(T.hsep())
	left.add_child(T.heading("Kỹ năng thường", T.C_GOLD))
	if group_normal.is_empty(): left.add_child(_empty("Chưa học kỹ năng thường nào."))
	for it2 in group_normal:
		var s2 := str(it2[0]); var lv2 := int(it2[1])
		var d2: Dictionary = Data.skill(s2)
		left.add_child(W.glyph_row(W.skill_icon(s2), str(d2.get("name", s2)), _sk_line(s2, lv2), "Lv %d" % lv2, selected_where == "skill" and selected_key == s2, func(): _select("skill", s2)))

	left.add_child(T.hsep())
	left.add_child(T.heading("Tuyệt kỹ", T.C_PURPLE))
	if group_ult.is_empty(): left.add_child(_empty("Chưa học tuyệt kỹ nào."))
	for it3 in group_ult:
		var s3 := str(it3[0]); var lv3 := int(it3[1])
		var d3: Dictionary = Data.skill(s3)
		left.add_child(W.glyph_row(W.skill_icon(s3), str(d3.get("name", s3)), _sk_line(s3, lv3), "Lv %d" % lv3, selected_where == "skill" and selected_key == s3, func(): _select("skill", s3), T.C_PURPLE))

	left.add_child(T.hsep())
	left.add_child(T.heading("Tuyệt phẩm", Color("ff8a4a")))
	if supers.is_empty(): left.add_child(_empty("Chưa sở hữu tuyệt phẩm nào."))
	for su in supers:
		var ss := str(su)
		var sd: Dictionary = Data.skill(ss)
		if sd.is_empty(): continue
		left.add_child(W.glyph_row(W.skill_icon(ss), str(sd.get("name", ss)), _sk_line(ss, 1), "Sở hữu", selected_where == "skill" and selected_key == ss, func(): _select("skill", ss), Color("ff8a4a")))
	var right: Control = W.empty_detail("Chạm một kỹ năng để xem chi tiết, nâng cấp hoặc gán vào ô.")
	if selected_where == "skill" and not Data.skill(selected_key).is_empty():
		right = _skill_detail(selected_key, learned, pl)
	vb.add_child(W.split(left, right))
	return W.fill(vb)

# ============================================================ QUEST
func _npc_places(npc_id: String) -> String:
	# Ưu tiên map NPC đang thật sự xuất hiện ở tiến độ hiện tại (appear); không có thì liệt kê mọi map chứa NPC.
	var now: Array = []
	var any: Array = []
	for mid in Data.MAPS.keys():
		var npcs: Dictionary = (Data.MAPS[mid] as Dictionary).get("npcs", {})
		for k in npcs.keys():
			if str(npcs[k]) == npc_id:
				any.append(W.map_name(str(mid)))
				if Data.npc_here(p(), str(mid), npc_id): now.append(W.map_name(str(mid)))
				break
	var out: Array = now if not now.is_empty() else any
	return " · ".join(out.slice(0, 2))

## Dòng mục tiêu có tiến độ. prog: tiến độ lưu trong player.quest.progress (hình dạng linh hoạt).
## Map có quái này (tối đa 3 tên map).
func _monster_places(mid: String) -> String:
	var out: Array = []
	for map_id in Data.MAPS.keys():
		var sp: Variant = (Data.MAPS[map_id] as Dictionary).get("spawns", {})
		if typeof(sp) == TYPE_DICTIONARY and mid in (sp as Dictionary).values():
			out.append(W.map_name(str(map_id)))
			if out.size() >= 3: break
	return ", ".join(out)

## Quái rơi vật phẩm này (tối đa 2 quái, kèm map đầu tiên của mỗi quái).
func _item_sources(iid: String) -> String:
	var out: Array = []
	for mid in Data.MONSTERS.keys():
		var drops: Variant = (Data.MONSTERS[mid] as Dictionary).get("drops", [])
		if typeof(drops) != TYPE_ARRAY: continue
		for dr in drops:
			if typeof(dr) == TYPE_ARRAY and (dr as Array).size() > 0 and str(dr[0]) == iid:
				var pl := _monster_places(str(mid)).split(", ")[0]
				out.append("%s%s" % [W.monster_name(str(mid)), (" (" + pl + ")") if pl != "" else ""])
				break
		if out.size() >= 2: break
	return " · ".join(out)

## Các bước của một nhiệm vụ: mỗi mục tiêu một hàng có đánh dấu, tiến độ và gợi ý nơi làm.
func _objective_rows(obj: Dictionary, prog: Dictionary, vb: VBoxContainer) -> void:
	var pl := p()
	var lines := Data.quest_obj_lines(pl, obj, prog)
	var li := 0
	for kind in ["kill", "collect", "visit", "level", "school"]:
		if not obj.has(kind): continue
		var spec: Variant = obj[kind]
		match kind:
			"kill":
				var pk: Dictionary = prog.get("kill", {}) if typeof(prog.get("kill", {})) == TYPE_DICTIONARY else {}
				for mid in (spec as Dictionary).keys():
					var where := _monster_places(str(mid))
					vb.add_child(_obj_row("Hạ %s" % W.monster_name(str(mid)), int(pk.get(mid, 0)), int(spec[mid]), ("Tìm ở: " + where) if where != "" else ""))
			"collect":
				for iid in (spec as Dictionary).keys():
					var have := 0
					for e in pl.get("bag", []):
						if typeof(e) == TYPE_DICTIONARY and str(e.get("id", "")) == str(iid): have += int(e.get("n", e.get("qty", 1)))
					var src := _item_sources(str(iid))
					vb.add_child(_obj_row("Thu thập %s" % W.item_name(str(iid)), have, int(spec[iid]), ("Rơi từ: " + src) if src != "" else ""))
			"visit":
				var pv: Variant = prog.get("visit", {})
				for nid in (spec as Array):
					var seen: bool = typeof(pv) == TYPE_DICTIONARY and bool((pv as Dictionary).get(nid, false))
					var wh := _npc_places(str(nid))
					vb.add_child(_obj_row("Gặp %s" % W.npc_name(str(nid)), 1 if seen else 0, 1, ("Ở: " + wh) if wh != "" else ""))
			"level": vb.add_child(_obj_row("Đạt cấp %d" % int(spec), int(pl.get("level", 1)), int(spec)))
			"school": vb.add_child(_obj_row("Thức tỉnh class ở Hội trưởng Khải", 1 if not str(pl.get("school", "")).is_empty() else 0, 1))
	li += lines.size()

func _obj_row(text: String, have: int, need: int, hint: String = "") -> Control:
	var done := have >= need
	var vb := _vb(3)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	var mark := PanelContainer.new()
	mark.custom_minimum_size = Vector2(22, 22)
	mark.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var msb := T.sb(T.C_GREEN if done else Color(0.1, 0.13, 0.2), T.C_GREEN if done else T.C_MUTED, 1, 11, 0)
	mark.add_theme_stylebox_override("panel", msb)
	if done:
		var ck := T.label("+", T.FS_S, Color(0.05, 0.12, 0.06), true)
		ck.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ck.autowrap_mode = TextServer.AUTOWRAP_OFF
		mark.add_child(ck)
	h.add_child(mark)
	var t := T.label(text, T.FS_M, T.C_MUTED if done else T.C_TEXT, true)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(t)
	var n := T.label("%d/%d" % [mini(have, need), need], T.FS_M, T.C_GREEN if done else T.C_GOLD, true)
	n.autowrap_mode = TextServer.AUTOWRAP_OFF
	h.add_child(n)
	vb.add_child(h)
	if need > 1:
		var pb := ProgressBar.new()
		pb.min_value = 0; pb.max_value = need; pb.value = mini(have, need)
		pb.show_percentage = false
		pb.custom_minimum_size = Vector2(0, 14)
		pb.add_theme_stylebox_override("background", T.UISkin.bar_frame())
		pb.add_theme_stylebox_override("fill", T.UISkin.bar_fill(T.C_GREEN if done else T.C_GOLD))
		vb.add_child(pb)
	if hint != "" and not done:
		var hl := T.label(hint, 12, Color(T.C_MUTED, 0.95))
		hl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vb.add_child(hl)
	return vb

func _reward_chips(rw: Dictionary) -> Control:
	var chips: Array = []
	if int(rw.get("exp", 0)) > 0: chips.append(["%s EXP" % W.fmt_num(int(rw["exp"])), T.C_BLUE])
	if int(rw.get("gold", 0)) > 0: chips.append(["%s xu" % W.fmt_num(int(rw["gold"])), T.C_GOLD])
	for it in rw.get("items", []):
		if typeof(it) == TYPE_ARRAY and (it as Array).size() >= 2: chips.append(["%s ×%d" % [W.item_name(str(it[0])), int(it[1])], T.C_PURPLE])
		elif typeof(it) == TYPE_STRING:
			var parts := str(it).split(" ")
			if parts.size() >= 2: chips.append(["%s ×%d" % [W.item_name(str(parts[0])), int(parts[1])], T.C_PURPLE])
			elif parts.size() == 1: chips.append([W.item_name(str(parts[0])), T.C_PURPLE])
	if bool(rw.get("schoolWeapon", false)): chips.append(["Vũ khí class", T.C_GOLD])
	var perk := str(rw.get("perk", ""))
	if not perk.is_empty(): chips.append(["Nội tại: %s" % perk, T.C_GREEN])
	var fl := HFlowContainer.new()
	fl.add_theme_constant_override("h_separation", 6)
	fl.add_theme_constant_override("v_separation", 4)
	for c in chips: fl.add_child(W.chip(str(c[0]), c[1] as Color))
	return fl

func build_quest() -> Control:
	var vb := _vb()
	var pl := p()
	var q: Variant = pl.get("quest", null)
	var qd: Dictionary = q if typeof(q) == TYPE_DICTIONARY else {}
	var cur: Dictionary = Data.quest_current(pl)
	if qd.is_empty() or cur.is_empty():
		vb.add_child(_empty("Cốt truyện đã hoàn tất.\nHãy làm phụ tuyến.", "quest"))
	else:
		var state := str(qd.get("state", "none"))
		if state == "active" and Data.quest_ready(pl): state = "done"
		var inner := _vb(8)
		var head := HBoxContainer.new()
		head.add_theme_constant_override("separation", 8)
		var tl := T.label(str(cur.get("name", "Nhiệm vụ")), T.FS_L, T.C_GOLD, true)
		tl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		head.add_child(tl)
		var smap := {"none": ["Chưa nhận", T.C_MUTED], "active": ["Đang làm", T.C_GOLD], "done": ["Có thể trả", T.C_GREEN]}
		var sv: Array = smap.get(state, [state, T.C_MUTED])
		head.add_child(W.chip(str(sv[0]), sv[1] as Color))
		inner.add_child(head)
		var npc_id := str(cur.get("npc", ""))
		if not npc_id.is_empty():
			var where := _npc_places(npc_id)
			inner.add_child(T.label("Gặp %s%s" % [W.npc_name(npc_id), (" — " + where) if not where.is_empty() else ""], T.FS_S, T.C_MUTED))
		var min_lv := int(cur.get("minLevel", 1))
		if state == "none" and min_lv > 1:
			var ok_lv := int(pl.get("level", 1)) >= min_lv
			inner.add_child(T.label(("%s Cần đạt cấp %d để nhận nhiệm vụ%s" % ["✓" if ok_lv else "🔒", min_lv, "" if ok_lv else " (bạn đang cấp %d)" % int(pl.get("level", 1))]), T.FS_S, T.C_GREEN if ok_lv else T.C_RED))
		if state != "none":
			inner.add_child(T.hsep())
			inner.add_child(T.label("Mục tiêu", T.FS_S, T.C_MUTED, true))
			var prog: Dictionary = qd.get("progress", {}) if typeof(qd.get("progress", {})) == TYPE_DICTIONARY else {}
			_objective_rows(cur.get("obj", {}), prog, inner)
		var rw: Dictionary = cur.get("reward", {})
		if not rw.is_empty():
			inner.add_child(T.label("Phần thưởng", T.FS_S, T.C_MUTED, true))
			inner.add_child(_reward_chips(rw))
		var lines: Array = cur.get("end", []) if state == "done" else cur.get("start", [])
		if not lines.is_empty():
			inner.add_child(T.hsep())
			var story := T.label("“" + "\n".join(lines.slice(0, 3)) + "”", 12, Color(T.C_MUTED, 0.9))
			inner.add_child(story)
		vb.add_child(W.card_row(inner))
	var side: Dictionary = pl.get("side", {}) if typeof(pl.get("side", {})) == TYPE_DICTIONARY else {}
	var active: Dictionary = side.get("active", {}) if typeof(side.get("active", {})) == TYPE_DICTIONARY else {}
	if not active.is_empty():
		vb.add_child(W.section_label("Phụ tuyến"))
		for sid in active.keys():
			var sq: Dictionary = Data.quest_by_id(str(sid))
			var inner2 := _vb(4)
			var s_ready := Data.side_ready(pl, str(sid))
			inner2.add_child(T.label(("✔ " if s_ready else "") + str(sq.get("name", _prettify(str(sid)))), T.FS_M, T.C_GREEN if s_ready else T.C_TEXT, true))
			if sq.has("npc"): inner2.add_child(T.label("Gặp %s" % W.npc_name(str(sq["npc"])), T.FS_S, T.C_MUTED))
			var sp: Dictionary = active[sid] if typeof(active[sid]) == TYPE_DICTIONARY else {}
			_objective_rows(sq.get("obj", {}), sp, inner2)
			if s_ready and sq.has("npc"):
				var swhere := _npc_places(str(sq["npc"]))
				inner2.add_child(T.label("Về gặp %s%s để trả" % [W.npc_name(str(sq["npc"])), (" · " + swhere) if swhere != "" else ""], T.FS_S, T.C_GREEN))
			vb.add_child(W.card_row(inner2))
	# Phụ tuyến có thể nhận (web liệt kê kèm NPC nhận ở cuối danh sách).
	var avail: Array = []
	for sq in Data.SIDE_QUESTS:
		if typeof(sq) == TYPE_DICTIONARY and Data.side_available(pl, sq as Dictionary): avail.append(sq as Dictionary)
	if not avail.is_empty():
		if active.is_empty(): vb.add_child(W.section_label("Phụ tuyến"))
		for aq in avail:
			var anpc := str(aq.get("npc", ""))
			vb.add_child(T.label("• %s — nhận ở %s" % [str(aq.get("name", "")), W.npc_name(anpc)], T.FS_S, T.C_MUTED))
	# Nhiệm vụ ngày chỉ hiển thị ở NPC/bảng nhiệm vụ, không đưa vào tab Nhiệm vụ.
	return vb

func _prettify(id: String) -> String:
	return id.replace("_", " ").capitalize()

# ============================================================ MAP (sơ đồ khu nối đường, giống web)
const WorldMapView := preload("res://src/ui/WorldMapView.gd")

func _map_info(box: VBoxContainer, id: String) -> void:
	for c in box.get_children(): c.queue_free()
	var m: Dictionary = Data.MAPS.get(id, {})
	var st: Dictionary = WorldMapView.status_of(id)
	var theme_names := {"city": "Thành thị", "forest": "Rừng", "cave": "Hang động", "redgate": "Cổng đỏ"}
	box.add_child(T.label(str(m.get("name", id)), T.FS_M, T.C_GOLD, true))
	var sub: Array = []
	if Data.is_village(m): sub.append(["Tân Đô", T.C_BLUE])
	if theme_names.has(str(m.get("theme", ""))): sub.append([str(theme_names[str(m.get("theme", ""))]), T.C_MUTED])
	if not sub.is_empty():
		var fl := HFlowContainer.new()
		fl.add_theme_constant_override("h_separation", 6)
		for c in sub: fl.add_child(W.chip(str(c[0]), c[1] as Color))
		box.add_child(fl)
	var ok := bool(st.get("ok", false))
	var here := bool(st.get("here", false))
	box.add_child(T.label(("📍 " if here else ("✓ " if ok else "🔒 ")) + str(st.get("reason", "")), T.FS_S, T.C_GOLD if here else (T.C_GREEN if ok else T.C_RED), true))
	var mobs: Array = []
	for k in (m.get("spawns", {}) as Dictionary).keys():
		var nm := W.monster_name(str(m["spawns"][k]))
		if not nm in mobs: mobs.append(nm)
	var npcs: Array = []
	for k in (m.get("npcs", {}) as Dictionary).keys():
		var nn := W.npc_name(str(m["npcs"][k]))
		if not nn in npcs: npcs.append(nn)
	var near: Array = []
	for k in (m.get("portals", {}) as Dictionary).keys():
		var tn := W.map_name(str(m["portals"][k].get("to", "")))
		if not tn in near: near.append(tn)
	box.add_child(T.hsep())
	box.add_child(_info_row("Quái", ", ".join(mobs) if not mobs.is_empty() else "Không có"))
	box.add_child(_info_row("NPC", ", ".join(npcs) if not npcs.is_empty() else "Không có"))
	box.add_child(_info_row("Nối tới", " · ".join(near) if not near.is_empty() else "—"))

func _info_row(k: String, v: String) -> Control:
	var vb := _vb(0)
	vb.add_child(T.label(k, 12, T.C_MUTED, true))
	vb.add_child(T.label(v, T.FS_S, T.C_TEXT))
	return vb

func build_map() -> Control:
	var vb := _vb(6)
	var view: Control = WorldMapView.new()
	view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var mapbox := PanelContainer.new()
	mapbox.add_theme_stylebox_override("panel", T.UISkin.inset(3))
	mapbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mapbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	mapbox.add_child(view)
	# Chỉ hiện bản đồ: bỏ cột chi tiết bên phải để bản đồ lấp đầy khung.
	vb.add_child(mapbox)
	return W.fill(vb)

func _dict_values(d: Dictionary) -> Array:
	var a: Array = []
	for k in d.keys(): a.append(str(d[k]))
	return a

# ============================================================ SHOP
const NGOC_GROUP_NAMES := {"ky_nguyen": "Kỳ Nguyên", "util": "Tiện ích", "book": "Sách", "ult": "Tuyệt kỹ", "superult": "Tuyệt Phẩm"}
const NGOC_GROUP_ORDER := ["ky_nguyen", "util", "book", "ult", "superult"]

## Lầu Trân Bảo: như web (ngocShopItems) - mọi món có priceNgoc (món trong shop + Kỳ Nguyên + sách tuyệt kỹ), xếp theo nhóm/cấp/tên.
func _ngoc_shop_items(base: Array) -> Array:
	var list: Array = []
	for id in base:
		if int(Data.item(str(id)).get("priceNgoc", 0)) > 0 and not list.has(str(id)): list.append(str(id))
	for id in Data.ITEMS.keys():
		if int((Data.ITEMS[id] as Dictionary).get("priceNgoc", 0)) > 0 and not list.has(str(id)): list.append(str(id))
	var rank := func(id: String) -> int: return maxi(0, NGOC_GROUP_ORDER.find(str(Data.item(id).get("ngocGroup", "util"))))
	list.sort_custom(func(a, b):
		var ra: int = rank.call(a)
		var rb: int = rank.call(b)
		if ra != rb: return ra < rb
		var la := int(Data.item(a).get("level", 0))
		var lb := int(Data.item(b).get("level", 0))
		if la != lb: return la < lb
		return str(Data.item(a).get("name", "")) < str(Data.item(b).get("name", "")))
	return list

func build_shop() -> Control:
	var vb := _vb()
	var pl := p()
	var npc := str(ctx_extra.get("npc", npc_id))
	var nd: Dictionary = Data.npc(npc)
	var sh_head := HBoxContainer.new()
	sh_head.add_theme_constant_override("separation", 10)
	var sh_name := T.label(str(nd.get("name", "Cửa hàng")), T.FS_M, T.C_TEXT, true)
	sh_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sh_head.add_child(sh_name)
	sh_head.add_child(_gold_row(pl))
	vb.add_child(sh_head)
	var is_ngoc: bool = bool(nd.get("ngocShop", false))
	if not is_ngoc:
		var discount := roundi(float(pl.get("shopDiscount", 0)) * 100.0)
		vb.add_child(W.segmented([["buy", "Mua"], ["sell", "Bán"]], shop_tab, func(t): shop_tab = t; _deselect()))
		if discount > 0: vb.add_child(T.label("Khách quen: giảm %d%%" % discount, T.FS_S, T.C_GREEN))
	var left: Control
	var right: Control = W.empty_detail()
	if shop_tab == "buy" or is_ngoc:
		var items: Array = Data.shop_items(pl, npc) if not is_ngoc else _ngoc_shop_items(nd.get("shop", []))
		var last_grp := ""
		var lv := _vb(6)
		for iid in items:
			var sid := str(iid)
			var d0: Dictionary = Data.item(sid)
			if is_ngoc:
				var grp := str(d0.get("ngocGroup", "util"))
				if grp != last_grp:
					last_grp = grp
					lv.add_child(W.section_label(str(NGOC_GROUP_NAMES.get(grp, "Tiện ích"))))
			var price_txt := ("%s ngọc" % W.fmt_num(int(d0.get("priceNgoc", 0)))) if is_ngoc else ("%s xu" % W.fmt_num(Data.shop_price(pl, d0)))
			var sub_parts: Array = W.item_stat_lines(d0)
			var sub := ", ".join(sub_parts.slice(0, 2)) if not sub_parts.is_empty() else str(d0.get("desc", ""))
			lv.add_child(W.shop_row(sid, sub, price_txt, selected_where == "shop" and selected_key == sid, func(): _select("shop", sid)))
		left = lv if not items.is_empty() else _empty("Cửa hàng chưa mở. Hãy lại gần NPC bán hàng.")
		if selected_where == "shop":
			var box := W.item_detail(selected_key)
			var body := W.box_body(box)
			var dsel: Dictionary = Data.item(selected_key)
			var stackable := bool(dsel.get("stack", false))
			if not stackable: shop_qty = 1
			var qty_row := HBoxContainer.new()
			qty_row.add_theme_constant_override("separation", 8)
			var minus := W.action_button("−", func(): shop_qty = maxi(1, shop_qty - 1); refresh())
			minus.custom_minimum_size = Vector2(48, 44)
			minus.disabled = not stackable
			qty_row.add_child(minus)
			var ql := T.label(str(shop_qty), T.FS_L, T.C_GOLD, true)
			ql.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			ql.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			qty_row.add_child(ql)
			var plus := W.action_button("+", func(): shop_qty = mini(99, shop_qty + 1); refresh())
			plus.custom_minimum_size = Vector2(48, 44)
			plus.disabled = not stackable
			qty_row.add_child(plus)
			if stackable: body.add_child(qty_row)
			var key := npc + ":" + selected_key
			var total: int = (int(dsel.get("priceNgoc", 0)) if is_ngoc else Data.shop_price(pl, dsel)) * shop_qty
			var cur_unit := "ngọc" if is_ngoc else "xu"
			var buy := W.action_button(("Chạm lần nữa: mua %d (%s %s)" if confirm_buy == key else "Mua %d · %s %s") % [shop_qty, W.fmt_num(total), cur_unit], func():
				if confirm_buy == key:
					act("buy_ngoc" if is_ngoc else "buy", {"npc": npc, "item": selected_key, "qty": shop_qty})
					confirm_buy = ""; refresh()
				else:
					confirm_buy = key; refresh())
			if confirm_buy == key: buy.add_theme_color_override("font_color", T.C_GOLD)
			body.add_child(buy)
			right = box
	else:
		var bag: Array = pl.get("bag", [])
		var g2 := _grid(6)
		var any := false
		for e in bag:
			if typeof(e) != TYPE_DICTIONARY: continue
			var iid2 := str(e.get("id", ""))
			var d2: Dictionary = Data.item(iid2)
			if int(d2.get("price", 0)) <= 0 or str(d2.get("kind", "")) == "quest": continue
			any = true
			var uid := str(e.get("uid", 0))
			g2.add_child(W.item_cell(iid2, int(e.get("n", 1)), selected_where == "sell" and selected_key == uid, func(): _select("sell", uid)))
		left = g2 if any else _empty("Không có đồ bán được.")
		if selected_where == "sell":
			var e3 := _bag_entry(selected_key)
			if not e3.is_empty():
				var box2 := W.item_detail(str(e3.get("id", "")), int(e3.get("plus", 0)), true, e3)
				var uidn := int(e3.get("uid", 0))
				var n := int(e3.get("n", 1))
				W.box_body(box2).add_child(W.action_button("Bán 1", func(): act("sell", {"uid": uidn, "qty": 1})))
				if n > 1: W.box_body(box2).add_child(W.action_button("Bán hết (%d)" % n, func(): act("sell", {"uid": uidn, "qty": n}); _deselect()))
				right = box2
	vb.add_child(W.split(left, right))
	return W.fill(vb)

# ============================================================ SMITH
const SMITH_TABS := [["upgrade", "Cường hóa"], ["reforge", "Tẩy luyện"], ["salvage", "Phân rã"], ["seal", "Khắc ấn"]]
const SMITH_DESC := {"upgrade": "Nâng cấp +1 cho trang bị. Càng cao càng dễ thất bại.", "reforge": "Đổi lại chỉ số ngẫu nhiên của trang bị.",
	"salvage": "Phân rã trang bị thành đá cường hóa.", "seal": "Khắc ấn tăng sức mạnh đặc biệt."}

func build_smith() -> Control:
	var vb := _vb()
	var pl := p()
	vb.add_child(_gold_row(pl, false))
	vb.add_child(W.segmented(SMITH_TABS, smith_tab, func(t): smith_tab = t; _deselect()))
	vb.add_child(T.label(str(SMITH_DESC.get(smith_tab, "")), T.FS_S, T.C_MUTED))
	# Ứng viên: tab Phân rã chỉ nhận đồ trong túi (server phân rã theo uid trong túi)
	var g := _grid(6)
	var cands := 0
	for e in pl.get("bag", []):
		if typeof(e) != TYPE_DICTIONARY: continue
		var iid := str(e.get("id", ""))
		if str(Data.item(iid).get("slot", "")).is_empty(): continue
		var key := "u" + str(e.get("uid", 0))
		cands += 1
		g.add_child(W.item_cell(iid, 1, selected_where == "smith" and selected_key == key, func(): _select("smith", key), ("+%d" % int(e.get("plus", 0))) if int(e.get("plus", 0)) > 0 else ""))
	var eq: Dictionary = pl.get("equip", {})
	if smith_tab != "salvage":
		for s in eq.keys():
			if typeof(eq[s]) != TYPE_DICTIONARY: continue
			var key2 := "s" + str(s)
			var iid2 := str((eq[s] as Dictionary).get("id", ""))
			cands += 1
			g.add_child(W.item_cell(iid2, 1, selected_where == "smith" and selected_key == key2, func(): _select("smith", key2), "Mặc"))
	var left: Control = g if cands > 0 else _empty("Không có trang bị.")
	var tips := {
		"upgrade": "Chọn trang bị bên trái để nâng cấp. Mỗi cấp +8% chỉ số chính.",
		"reforge": "Tẩy luyện gieo lại toàn bộ dòng phụ của đồ Tốt, Hiếm, Huyền thoại (giữ nguyên số dòng).",
		"seal": "Khắc ấn: đồ đạt độ hoàn hảo %d%% trở lên được thêm 1 dòng phụ thứ tư, vĩnh viễn." % Data.SMITH_PERFECT_MIN,
		"salvage": "Phân rã đồ trong túi để lấy Đá cường hóa: Tốt 1, Hiếm 3, Huyền thoại 6 viên, cộng thêm theo cấp nâng.",
	}
	var right: Control = W.empty_detail(str(tips.get(smith_tab, "")))
	if selected_where == "smith":
		var params: Dictionary = {}
		var iid3 := ""
		var plus := 0
		var sm_entry: Dictionary = {}
		if selected_key.begins_with("u"):
			var e2 := _bag_entry(selected_key.substr(1))
			iid3 = str(e2.get("id", "")); plus = int(e2.get("plus", 0)); sm_entry = e2
			params = {"uid": int(e2.get("uid", 0))}
		else:
			var slot := selected_key.substr(1)
			var it: Dictionary = eq.get(slot, {}) if typeof(eq.get(slot, null)) == TYPE_DICTIONARY else {}
			iid3 = str(it.get("id", "")); plus = int(it.get("plus", 0)); sm_entry = it
			params = {"slot": slot}
		if not iid3.is_empty():
			var box := W.item_detail(iid3, plus, true, sm_entry)
			var body := W.box_body(box)
			var gold := int(pl.get("gold", 0))
			var stones := 0
			for b in pl.get("bag", []):
				if typeof(b) == TYPE_DICTIONARY and str((b as Dictionary).get("id", "")) == "da_cuong_hoa":
					stones += int((b as Dictionary).get("qty", (b as Dictionary).get("n", 1)))
			var q := Data.smith_q(sm_entry)
			var tab := smith_tab
			var can := false
			var label := ""
			if tab == "upgrade":
				if plus >= Data.SMITH_UPGRADE_MAX:
					body.add_child(T.label("Đã đạt tối đa +%d." % Data.SMITH_UPGRADE_MAX, T.FS_S, T.C_GOLD))
				else:
					var c := Data.smith_upgrade_cost(plus)
					var rate := roundi(float(Data.SMITH_UPGRADE_RATES[mini(plus, Data.SMITH_UPGRADE_RATES.size() - 1)]) * 100.0)
					body.add_child(T.label("Tỉ lệ %d%%%s" % [rate, " · thất bại giảm 1 cấp" if plus + 1 >= 12 else ""], T.FS_S, T.C_GREEN if rate >= 70 else (T.C_GOLD if rate >= 40 else T.C_RED)))
					body.add_child(T.label("Chi phí: %s xu, %d đá cường hóa" % [W.fmt_num(int(c["gold"])), int(c["stones"])], T.FS_S, T.C_MUTED))
					can = gold >= int(c["gold"]) and stones >= int(c["stones"])
					label = "Cường hóa lên +%d" % (plus + 1)
			elif tab == "reforge":
				if q < 2:
					body.add_child(T.label("Đồ Thường không có dòng phụ. Chỉ đồ Tốt trở lên mới tẩy luyện được.", T.FS_S, T.C_MUTED))
				else:
					var c := Data.smith_reforge_cost(sm_entry)
					body.add_child(T.label("Chi phí: %s xu, %d đá cường hóa" % [W.fmt_num(int(c["gold"])), int(c["stones"])], T.FS_S, T.C_MUTED))
					can = gold >= int(c["gold"]) and stones >= int(c["stones"])
					label = "Tẩy luyện"
			elif tab == "seal":
				var pf := W.inst_perfection(sm_entry)
				if bool(sm_entry.get("seal", false)):
					body.add_child(T.label("Món này đã được khắc ấn rồi.", T.FS_S, T.C_MUTED))
				elif q < 2:
					body.add_child(T.label("Đồ Thường không có dòng phụ. Chỉ đồ Tốt trở lên mới khắc ấn được.", T.FS_S, T.C_MUTED))
				elif pf < Data.SMITH_PERFECT_MIN:
					body.add_child(T.label("Cần độ hoàn hảo %d%% trở lên. Món này đang %d%%." % [Data.SMITH_PERFECT_MIN, pf], T.FS_S, T.C_RED))
				else:
					var c := Data.smith_seal_cost(sm_entry)
					body.add_child(T.label("Chi phí: %s xu, %d đá cường hóa" % [W.fmt_num(int(c["gold"])), int(c["stones"])], T.FS_S, T.C_MUTED))
					can = gold >= int(c["gold"]) and stones >= int(c["stones"])
					label = "Khắc ấn"
			else:
				var st := Data.smith_salvage_stones(sm_entry)
				body.add_child(T.label("Nhận về: %d Đá cường hóa. Món đồ sẽ mất vĩnh viễn." % st, T.FS_S, T.C_MUTED))
				can = true
				label = "Phân rã lấy đá"
			if not label.is_empty():
				body.add_child(W.action_button(label, func(): act(tab, params); _deselect(), not can))
			right = box
	vb.add_child(W.split(left, right))
	return W.fill(vb)

# ============================================================ STORAGE
func build_storage() -> Control:
	var vb := _vb()
	var pl := p()
	var here := str(pl.get("map", "lang"))
	var store: Array = pl.get("storageByMap", {}).get(here, [])
	var cap_max := Data.const_int("STORAGE_SIZE", 30)
	vb.add_child(W.chip_row([["Kho %s" % W.map_name(here), T.C_GOLD], ["%d/%d" % [store.size(), cap_max], T.C_MUTED]]))
	if store.size() > cap_max: vb.add_child(T.label("Kho đang vượt giới hạn. Hãy lấy bớt đồ ra để gửi thêm.", T.FS_S, T.C_RED))
	elif store.size() >= cap_max: vb.add_child(T.label("Kho đã đầy.", T.FS_S, T.C_RED))
	vb.add_child(W.segmented([["store", "Gửi vào kho"], ["take", "Lấy ra"]], storage_tab, func(t): storage_tab = t; _deselect()))
	var src: Array = pl.get("bag", []) if storage_tab == "store" else store
	var g := _grid(6)
	for e in src:
		if typeof(e) != TYPE_DICTIONARY: continue
		var uid := str(e.get("uid", 0))
		g.add_child(W.item_cell(str(e.get("id", "")), int(e.get("qty", e.get("n", 1))), selected_where == "store" and selected_key == uid, func(): _select("store", uid)))
	var left: Control = g if not src.is_empty() else _empty("Không có đồ.")
	var right: Control = W.empty_detail()
	if selected_where == "store":
		var sel: Dictionary = {}
		for e2 in src:
			if typeof(e2) == TYPE_DICTIONARY and str(e2.get("uid", 0)) == selected_key: sel = e2; break
		if not sel.is_empty():
			var box := W.item_detail(str(sel.get("id", "")), int(sel.get("plus", 0)), true, sel)
			var uidn := int(sel.get("uid", 0))
			var act_type := "store" if storage_tab == "store" else "retrieve"
			W.box_body(box).add_child(W.action_button("Gửi vào kho" if storage_tab == "store" else "Lấy ra", func(): act(act_type, {"uid": uidn}); _deselect()))
			right = box
	vb.add_child(W.split(left, right))
	return W.fill(vb)

# ============================================================ TELEPORT
func build_teleport() -> Control:
	var vb := _vb()
	var pl := p()
	vb.add_child(T.label("Chọn Tân Đô đã từng tới. Phí 300 xu/lượt, về Hiệp Hội miễn phí. Bạn có %s xu." % W.fmt_num(int(pl.get("gold", 0))), T.FS_S, T.C_MUTED))
	var any := false
	for mid in pl.get("villages", []):
		var sid := str(mid)
		if sid == str(pl.get("map", "")): continue
		if not (Data.MAPS.get(sid, {}) as Dictionary).get("village", false): continue
		any = true
		var fee := 0 if sid == str(Data.raw.get("CONSTANTS", {}).get("START_MAP", "lang")) else 300
		var enough := int(pl.get("gold", 0)) >= fee
		var h := W.list_row(null, W.map_name(sid), "Tân Đô · " + ("miễn phí" if fee == 0 else "%s xu" % W.fmt_num(fee)))
		var go := W.action_button("Đi", func(): act("teleport", {"to": sid, "hp": Game.hp, "mp": Game.mp}), not enough)
		go.custom_minimum_size = Vector2(90, 44)
		h.add_child(go)
		vb.add_child(W.card_row(h))
	if not any: vb.add_child(_empty("Chưa có Tân Đô nào khác để tới.\nĐi bộ tới một Tân Đô để mở trạm dịch chuyển.", "portal"))
	vb.add_child(T.hsep())
	vb.add_child(W.action_button("Đặt điểm hồi sinh ở đây", func(): act("set_respawn", {"x": roundi(float(pl.get("x", 0))), "y": roundi(float(pl.get("y", 0)))})))
	return vb

# ============================================================ GATE
func build_gate() -> Control:
	var vb := _vb()
	var here := str(p().get("map", "lang"))
	var portals: Dictionary = Data.map_def(here).get("portals", {})
	vb.add_child(T.label("Chọn điểm đến. Cần đứng gần cổng và hoàn thành nhiệm vụ yêu cầu.", T.FS_S, T.C_MUTED))
	var shown := 0
	for pk in portals.keys():
		var pv: Dictionary = portals[pk] if typeof(portals[pk]) == TYPE_DICTIONARY else {}
		var key := str(pk)
		if key == "<": continue
		var to := str(pv.get("to", ""))
		var reason := ""
		for req in [str(pv.get("require", "")), str(Data.map_def(to).get("require", ""))]:
			if not req.is_empty() and not Data.quest_done(p(), req):
				reason = "Cần hoàn thành nhiệm vụ \"%s\"" % str(Data.quest_by_id(req).get("name", req))
				break
		var ok := reason.is_empty()
		var h := W.list_row(null, ("" if ok else "🔒 ") + W.map_name(to), "Sẵn sàng" if ok else reason, T.C_TEXT if ok else T.C_MUTED)
		var go := W.action_button("Đi" if ok else "Khoá", func(): act("change_map", {"portal": key, "hp": Game.hp, "mp": Game.mp, "pets": p().get("pets", {})}), not ok)
		go.custom_minimum_size = Vector2(90, 44)
		h.add_child(go)
		vb.add_child(W.card_row(h))
		shown += 1
	if shown == 0: vb.add_child(_empty("Không có cổng ở bản đồ này.", "portal"))
	return vb

# ============================================================ DAILY
const WEEKLY_KILLS := 200
const WEEKLY_BOSSES := 5
const WEEKLY_BOOKS := 1
const DAILY_BONUS_STONES := 6

## Hệ số thưởng theo làng: Tân Đô I ×0.4 … VII ×1.0 (G.villageRewardMult của web).
func _village_reward_mult(map_id: String) -> float:
	var v: Variant = Data.map_def(map_id).get("village", null)
	if typeof(v) != TYPE_DICTIONARY: return 1.0
	return 0.4 + 0.1 * float((v as Dictionary).get("n", 1) - 1)

func _daily_reward(level: int, map_id: String) -> Dictionary:
	var k := _village_reward_mult(map_id)
	return {"exp": roundi(float(Formulas.exp_to_next(level)) * 0.22 * k), "gold": roundi(40.0 * float(level) * k), "stones": 1}

func _weekly_reward(level: int, map_id: String) -> Dictionary:
	var k := _village_reward_mult(map_id)
	var st := func(n: int) -> int: return maxi(1, roundi(float(n) * k))
	return {
		"kills": {"exp": roundi(float(Formulas.exp_to_next(level)) * 0.5 * k), "gold": roundi(100.0 * float(level) * k), "stones": st.call(8)},
		"bosses": {"exp": roundi(float(Formulas.exp_to_next(level)) * 0.6 * k), "gold": roundi(150.0 * float(level) * k), "stones": st.call(3)},
	}

func _daily_line_text(x: Dictionary) -> String:
	var target := str(x.get("target", ""))
	var need := int(x.get("need", 0))
	var typ := str(x.get("type", ""))
	var name := str(Data.monster(target).get("name", Data.item(target).get("name", target)))
	if typ == "kill": return "Hạ %d %s" % [need, name]
	if typ == "boss": return "Hạ trùm %s" % name
	return "Thu thập %d %s" % [need, name]

func _daily_line_have(pl: Dictionary, x: Dictionary) -> int:
	var need := int(x.get("need", 0))
	if str(x.get("type", "")) == "collect":
		var target := str(x.get("target", ""))
		var total := 0
		for e in pl.get("bag", []):
			if typeof(e) == TYPE_DICTIONARY and str((e as Dictionary).get("id", "")) == target:
				total += int((e as Dictionary).get("n", (e as Dictionary).get("qty", 1)))
		return mini(need, total)
	return mini(need, int(x.get("have", 0)))

func _reward_text(exp: int, gold: int, stones: int, stone_name: String = "đá cường hóa") -> String:
	return "%s kinh nghiệm, %s xu, %d %s" % [W.fmt_num(exp), W.fmt_num(gold), stones, stone_name]

func build_daily() -> Control:
	var vb := _vb()
	var pl := p()
	var here := str(pl.get("map", "lang"))
	var lvl := int(pl.get("level", 1))
	var by_map: Variant = pl.get("dailyByMap", {})
	var d: Dictionary = (by_map as Dictionary).get(here, {}) if typeof(by_map) == TYPE_DICTIONARY else {}
	if typeof(d) != TYPE_DICTIONARY: d = {}
	vb.add_child(W.section_label("Bảng nhiệm vụ · %s" % W.map_name(here)))
	var list: Array = d.get("list", []) if typeof(d.get("list", [])) == TYPE_ARRAY else []
	if list.is_empty():
		vb.add_child(_empty("Chưa có nhiệm vụ ngày ở đây.\nHoàn thành nhiệm vụ Cổng đỏ của Hội trưởng Khải để mở khu săn của làng này.", "quest"))
		return vb
	var r := _daily_reward(lvl, here)
	vb.add_child(T.label("Mỗi ngày 3 nhiệm vụ theo quái của vùng này. Thưởng của làng này ×%.1f." % _village_reward_mult(here), T.FS_S, T.C_MUTED))
	for i in range(list.size()):
		var x: Dictionary = list[i] if typeof(list[i]) == TYPE_DICTIONARY else {}
		var need := int(x.get("need", 0))
		var have := _daily_line_have(pl, x)
		var done := have >= need
		var claimed := bool(x.get("claimed", false))
		var mul := 2 if str(x.get("type", "")) == "boss" else 1
		var icon := "👑" if str(x.get("type", "")) == "boss" else ("🔶" if str(x.get("type", "")) == "collect" else "⚔️")
		var h := W.list_row(null, icon + " " + _daily_line_text(x), "Tiến độ: %d/%d%s" % [have, need, " · rơi từ quái trong cổng" if str(x.get("type", "")) == "collect" else ""], T.C_MUTED if claimed else T.C_TEXT)
		var inner := VBoxContainer.new()
		inner.add_theme_constant_override("separation", 2)
		inner.add_child(T.label(_reward_text(int(r["exp"]) * mul, int(r["gold"]) * mul, int(r["stones"]) * mul), T.FS_S, T.C_GOLD))
		h.add_child(inner)
		var idx := i
		if claimed:
			h.add_child(T.label("✓ Đã nhận", T.FS_S, T.C_GREEN))
		else:
			var b := W.action_button("Nhận thưởng", func(): act("daily_claim", {"i": idx}), not done)
			b.custom_minimum_size = Vector2(110, 44)
			h.add_child(b)
		vb.add_child(W.card_row(h))
	# Thưởng hoàn thành cả 3
	var all := true
	for x in list:
		if not bool((x as Dictionary).get("claimed", false)): all = false; break
	var bonus_v: Variant = d.get("bonus", null)
	var bonus_claimed := bool(bonus_v) if typeof(bonus_v) != TYPE_DICTIONARY else bool((bonus_v as Dictionary).get("claimed", false))
	var bonus_box := _vb(4)
	bonus_box.add_child(T.label("🎁 Thưởng hoàn thành cả 3: %d đá cường hóa" % DAILY_BONUS_STONES, T.FS_S, T.C_GOLD))
	bonus_box.add_child(T.label("Sách kỹ năng không còn ở nhiệm vụ ngày — mỗi tuần nhận %d cuốn ở mốc hạ trùm bên dưới." % WEEKLY_BOOKS, T.FS_S, T.C_MUTED))
	if bonus_claimed:
		bonus_box.add_child(T.label("✓ Đã nhận hôm nay", T.FS_S, T.C_GREEN))
	else:
		bonus_box.add_child(W.action_button("Nhận thưởng thêm", func(): act("daily_bonus", {}), not all))
	vb.add_child(W.card_row(bonus_box))
	# Nhiệm vụ tuần
	var weekly_v: Variant = pl.get("weeklyByMap", {})
	var w: Dictionary = (weekly_v as Dictionary).get(here, {}) if typeof(weekly_v) == TYPE_DICTIONARY else {}
	if typeof(w) != TYPE_DICTIONARY: w = {}
	if not w.is_empty():
		vb.add_child(T.hsep())
		vb.add_child(W.section_label("Nhiệm vụ tuần · %s" % str(w.get("week", ""))))
		vb.add_child(T.label("Làm mới vào thứ Hai · chỉ tính quái hạ ở vùng của làng này.", T.FS_S, T.C_MUTED))
		var wr := _weekly_reward(lvl, here)
		var rows: Array = [
			{"kind": "kills", "icon": "⚔️", "label": "Hạ %d quái" % WEEKLY_KILLS, "have": int(w.get("kills", 0)), "need": WEEKLY_KILLS,
				"claimed": bool(w.get("claimedKills", false)), "reward": _reward_text(int(wr["kills"]["exp"]), int(wr["kills"]["gold"]), int(wr["kills"]["stones"]))},
			{"kind": "bosses", "icon": "👑", "label": "Hạ %d trùm" % WEEKLY_BOSSES, "have": int(w.get("bosses", 0)), "need": WEEKLY_BOSSES,
				"claimed": bool(w.get("claimedBosses", false)), "reward": _reward_text(int(wr["bosses"]["exp"]), int(wr["bosses"]["gold"]), int(wr["bosses"]["stones"]), "đá cường hóa cao") + ", %d sách kỹ năng" % WEEKLY_BOOKS},
		]
		for row in rows:
			var have := mini(int(row["have"]), int(row["need"]))
			var done := have >= int(row["need"])
			var rh := W.list_row(null, str(row["icon"]) + " " + str(row["label"]), "Tiến độ: %d/%d" % [have, int(row["need"])], T.C_MUTED if bool(row["claimed"]) else T.C_TEXT)
			rh.add_child(T.label("Thưởng: " + str(row["reward"]), T.FS_S, T.C_GOLD))
			if bool(row["claimed"]):
				rh.add_child(T.label("✓ Đã nhận", T.FS_S, T.C_GREEN))
			else:
				var kind := str(row["kind"])
				var rb := W.action_button("Nhận", func(): act("weekly_claim", {"kind": kind}), not done)
				rb.custom_minimum_size = Vector2(90, 44)
				rh.add_child(rb)
			vb.add_child(W.card_row(rh))
	return vb

# ============================================================ NPC
func build_npc() -> Control:
	var vb := _vb()
	var nid := str(ctx_extra.get("id", npc_id))
	var nd: Dictionary = Data.npc(nid)
	var pl := p()
	var head := _vb(2)
	head.add_child(T.label(str(nd.get("name", "NPC")), T.FS_XL, T.C_GOLD, true))
	var say := str(ctx_extra.get("say", str(nd.get("greet", nd.get("say", "")))))
	if not say.is_empty(): head.add_child(T.label(say, T.FS_M, T.C_TEXT))
	vb.add_child(W.card_row(head))
	var q: Dictionary = pl.get("quest", {}) if typeof(pl.get("quest", {})) == TYPE_DICTIONARY else {}
	var role := str(nd.get("role", ""))
	var g := _grid(2)
	if not q.is_empty():
		var state := str(q.get("state", "none"))
		if state == "none": g.add_child(W.action_button("Nhận nhiệm vụ", func(): act("quest_accept", {})))
		elif state == "active" or state == "done": g.add_child(W.action_button("Trả nhiệm vụ", func(): act("quest_complete", {})))
	var side: Dictionary = pl.get("side", {})
	for sid in (side.get("active", {}) as Dictionary).keys():
		g.add_child(W.action_button("Trả phụ tuyến · %s" % _prettify(str(sid)), func(): act("side_complete", {"id": str(sid)})))
	match role:
		"daily": g.add_child(W.action_button("Bảng nhiệm vụ", func(): host.open_panel("daily")))
		"storage": g.add_child(W.action_button("Mở kho", func(): host.open_panel("storage")))
		"smith": g.add_child(W.action_button("Lò rèn", func(): host.open_panel("smith")))
		"teleport": g.add_child(W.action_button("Dịch chuyển", func(): host.open_panel("teleport")))
		"shop":
			g.add_child(W.action_button("Cửa hàng", func(): host.open_panel("shop", {"npc": nid})))
		"lao_su":
			g.add_child(W.action_button("Đánh giá hạng", func(): act("rank_eval", {})))
			g.add_child(W.action_button("Tẩy điểm kỹ năng", func(): act("reset_skills", {})))
		"lu_khach": g.add_child(W.action_button("Nhập mật mã", func(): host.open_panel("code")))
	var adv: Dictionary = pl.get("advancement", {}) if typeof(pl.get("advancement", {})) == TYPE_DICTIONARY else {}
	if adv.get("quest", null) != null:
		g.add_child(W.action_button("Trả thử thách", func(): act("advancement_complete", {})))
	g.add_child(W.action_button("Trò chuyện", func(): act("talk", {"npc": nid})))
	g.add_child(W.action_button("Đặt điểm hồi sinh", func(): act("set_respawn", {"x": roundi(float(pl.get("x", 0))), "y": roundi(float(pl.get("y", 0)))})))
	for c in g.get_children(): c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_child(g)
	return vb

# ============================================================ CODE
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

# ============================================================ SCHOOL
func build_school() -> Control:
	var vb := _vb()
	var confirm := str(ctx_extra.get("confirm", ""))
	if not confirm.is_empty():
		var inner := _vb(6)
		inner.add_child(T.label("Gia nhập %s?" % W.school_name(confirm), T.FS_L, T.C_GOLD, true))
		inner.add_child(T.label(str(Data.school(confirm).get("desc", "")), T.FS_S, T.C_MUTED))
		inner.add_child(T.label("Đã chọn thì không đổi lại được.", T.FS_S, T.C_RED))
		vb.add_child(W.card_row(inner))
		vb.add_child(T.button_primary("Gia nhập", Vector2(0, 48)))
		(vb.get_child(vb.get_child_count() - 1) as Button).pressed.connect(func(): act("choose_school", {"school": confirm}))
		vb.add_child(W.action_button("Xem lại", func(): host.open_panel("school", {})))
		return vb
	var g := _grid(2)
	for sid in Data.SCHOOLS.keys():
		var s: Dictionary = Data.SCHOOLS[sid] if typeof(Data.SCHOOLS[sid]) == TYPE_DICTIONARY else {}
		if bool(s.get("special", false)) or bool(s.get("evolved", false)): continue
		var inner2 := _vb(4)
		inner2.add_child(T.label(str(s.get("name", sid)), T.FS_M, T.C_GOLD, true))
		inner2.add_child(T.label(str(s.get("desc", "")), T.FS_S, T.C_MUTED))
		var cid := str(sid)
		inner2.add_child(W.action_button("Chọn", func(): host.open_panel("school", {"confirm": cid})))
		var card := W.card_row(inner2)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.custom_minimum_size = Vector2(520, 0)
		g.add_child(card)
	vb.add_child(g)
	return vb

# ============================================================ MOUNT (Linh thú Triệu Hồi Sư)
## Chỉ số linh thú theo cấp (khớp Assist.summon_stats / G.summonUnitStats của web).
func _summon_stats(pl: Dictionary, mid: String) -> Dictionary:
	var sm: Dictionary = pl.get("summons", {}) if typeof(pl.get("summons", {})) == TYPE_DICTIONARY else {}
	var units: Dictionary = sm.get("units", {}) if typeof(sm.get("units", {})) == TYPE_DICTIONARY else {}
	var un: Dictionary = units.get(mid, {}) if typeof(units.get(mid, null)) == TYPE_DICTIONARY else {}
	var lv := mini(maxi(1, int(pl.get("level", 1))), maxi(1, int(un.get("lv", 1))))
	var skills: Dictionary = pl.get("skills", {}) if typeof(pl.get("skills", {})) == TYPE_DICTIONARY else {}
	var th5: Variant = skills.get("th5", 1)
	var skl := maxi(1, int((th5 as Dictionary).get("lv", 1)) if typeof(th5) == TYPE_DICTIONARY else int(th5))
	var mul := 1.0 + 0.12 * float(skl - 1)
	var sp: Dictionary = Data.calc.get("SUMMONS", {}).get(mid, {})
	var pc: Dictionary = Data.calc.get("PET_CURVE", {})
	var st := {
		"maxHp": roundi(Formulas.interp(pc.get("hp", []), float(lv)) * float(sp.get("hp", 1.0)) * mul),
		"maxMp": roundi((24.0 + 4.0 * float(lv - 1)) * mul),
		"maxSta": roundi((70.0 + 2.0 * float(lv - 1)) * mul),
		"atk": Formulas.interp(pc.get("atk", []), float(lv)) * mul,
		"def": roundi(Formulas.interp(pc.get("def", []), float(lv)) * float(sp.get("def", 1.0))),
		"lv": lv,
	}
	var gear: Dictionary = pl.get("petGear", {}) if typeof(pl.get("petGear", {})) == TYPE_DICTIONARY else {}
	var gmid: Dictionary = gear.get(mid, {}) if typeof(gear.get(mid, null)) == TYPE_DICTIONARY else {}
	var table: Dictionary = Data.calc.get("PET_GEAR", {})
	for slot in gmid.keys():
		var b: Dictionary = table.get(str(gmid[slot]), {}) if typeof(table.get(str(gmid[slot]), null)) == TYPE_DICTIONARY else {}
		if b.has("maxHp"): st["maxHp"] = int(st["maxHp"]) + int(b["maxHp"])
		if b.has("atk"): st["atk"] = float(st["atk"]) + float(b["atk"])
		if b.has("def"): st["def"] = int(st["def"]) + int(b["def"])
	return st

func build_mount() -> Control:
	var vb := _vb()
	var pl := p()
	var summons: Dictionary = pl.get("summons", {}) if typeof(pl.get("summons", {})) == TYPE_DICTIONARY else {}
	if str(pl.get("school", "")) != "trieu_hoi_su":
		vb.add_child(_empty("Chỉ Triệu Hồi Sư mới có linh thú.\nĐổi class để mở tính năng này.", "pet"))
		return vb
	var skills: Dictionary = pl.get("skills", {}) if typeof(pl.get("skills", {})) == TYPE_DICTIONARY else {}
	var th5v: Variant = skills.get("th5", 0)
	var th5lv := int((th5v as Dictionary).get("lv", 0)) if typeof(th5v) == TYPE_DICTIONARY else int(th5v)
	var can_summon := th5lv > 0
	var enabled := bool(summons.get("enabled", false))
	var toggle := W.action_button("Tắt linh thú" if enabled else "Bật linh thú", func(): act("summon_toggle", {}), not can_summon)
	if not can_summon: toggle.tooltip_text = "Cần học kỹ năng Triệu Hồi Linh Thú (th5) từ sách kỹ năng."
	vb.add_child(toggle)
	var choice := str(summons.get("choice", ""))
	var states: Dictionary = summons.get("states", {}) if typeof(summons.get("states", {})) == TYPE_DICTIONARY else {}
	var defs: Dictionary = Data.calc.get("SUMMONS", {})
	if defs.is_empty(): vb.add_child(_empty("Chưa có dữ liệu linh thú."))
	for mid in defs.keys():
		var m: Dictionary = defs[mid] if typeof(defs[mid]) == TYPE_DICTIONARY else {}
		var sid := str(mid)
		var picked := sid == choice
		var on := enabled and picked
		var st := _summon_stats(pl, sid)
		var card := _vb(6)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.custom_minimum_size = Vector2(520, 0)
		var head := HBoxContainer.new()
		head.add_theme_constant_override("separation", 10)
		head.add_child(_pet_avatar(sid, 56))
		var tc := _vb(2)
		tc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tc.add_child(T.label("%s · cấp %d%s" % [str(m.get("name", sid)), int(st["lv"]), " · đang theo chủ" if on else ""], T.FS_M, T.C_GOLD if on else T.C_TEXT, true))
		tc.add_child(T.label(str(m.get("desc", "")), T.FS_S, T.C_MUTED))
		tc.add_child(T.label("HP %d · MP %d · STA %d · Công %d · Thủ %d" % [int(st["maxHp"]), int(st["maxMp"]), int(st["maxSta"]), int(st["atk"]), int(st["def"])], T.FS_S, T.C_TEXT))
		head.add_child(tc)
		head.add_child(W.action_button("Đang dùng" if picked else ("Đổi sang" if enabled else "Chọn"), func(): act("summon_pick", {"id": sid}), picked))
		card.add_child(head)
		if on:
			var cur: Dictionary = states.get(sid, {}) if typeof(states.get(sid, null)) == TYPE_DICTIONARY else {}
			card.add_child(W.bar("HP", int(cur.get("hp", st["maxHp"])), int(st["maxHp"]), T.C_GREEN))
			card.add_child(W.bar("MP", int(cur.get("mp", st["maxMp"])), int(st["maxMp"]), T.C_BLUE))
			card.add_child(W.bar("Thể lực", int(cur.get("sta", st["maxSta"])), int(st["maxSta"]), T.C_GOLD))
		# Kỹ năng linh thú theo cấp.
		var sks: Array = Data.calc.get("SUMMON_SKILLS", {}).get(sid, [])
		if not sks.is_empty():
			var bits: Array = []
			for sk in sks:
				if typeof(sk) != TYPE_DICTIONARY: continue
				var unlocked := int(sk.get("lv", 1)) <= int(st["lv"])
				bits.append(("%s %s" % [str(sk.get("icon", "")), str(sk.get("name", ""))]) if unlocked else ("🔒 %s (cấp %d)" % [str(sk.get("name", "")), int(sk.get("lv", 1))]))
			if not bits.is_empty(): card.add_child(T.label("Kỹ năng: " + " · ".join(bits), T.FS_S, T.C_MUTED))
		card.add_child(_pet_gear_section(pl, sid))
		vb.add_child(W.card_row(card))
	return vb

# ============================================================ COMPANION (thú đồng hành)
## Chỉ số thú đồng hành: cố định theo loài + cộng trang bị thú (khớp companionStats của web).
func _companion_stats(pl: Dictionary, mid: String) -> Dictionary:
	var m := Data.mount(mid)
	var s: Dictionary = m.get("stats", {}) if typeof(m.get("stats", {})) == TYPE_DICTIONARY else m
	var st := {
		"maxHp": int(s.get("hp", 1000)), "maxMp": int(s.get("mp", 60)), "maxSta": int(s.get("sta", 100)),
		"atk": float(s.get("atk", 100)), "def": float(s.get("def", 100)),
	}
	var gear: Dictionary = pl.get("petGear", {}) if typeof(pl.get("petGear", {})) == TYPE_DICTIONARY else {}
	var gm: Dictionary = gear.get(mid, {}) if typeof(gear.get(mid, null)) == TYPE_DICTIONARY else {}
	var table: Dictionary = Data.calc.get("PET_GEAR", {})
	for slot in gm.keys():
		var b: Dictionary = table.get(str(gm[slot]), {}) if typeof(table.get(str(gm[slot]), null)) == TYPE_DICTIONARY else {}
		if b.has("maxHp"): st["maxHp"] = int(st["maxHp"]) + int(b["maxHp"])
		if b.has("atk"): st["atk"] = float(st["atk"]) + float(b["atk"])
		if b.has("def"): st["def"] = float(st["def"]) + float(b["def"])
	return st

func build_companion() -> Control:
	var vb := _vb()
	var pl := p()
	var mounts: Dictionary = pl.get("mounts", {}) if typeof(pl.get("mounts", {})) == TYPE_DICTIONARY else {}
	var owned: Array = mounts.get("owned", [])
	var summoned: Array = mounts.get("summoned", [])
	vb.add_child(W.chip_row([["Sở hữu  %d" % owned.size(), T.C_GOLD], ["Đang triệu hồi  %d" % summoned.size(), T.C_GREEN]]))
	if owned.is_empty():
		vb.add_child(_empty("Bạn chưa có thú đồng hành.\nNhận thú qua mã quà tặng hoặc sự kiện.", "pet"))
		return vb
	vb.add_child(T.label("Thú đi theo và đánh cùng bạn. Chỉ số cố định theo loài, mạnh lên nhờ trang bị thú. Triệu hồi tốn 10 MP.", T.FS_S, T.C_MUTED))
	var pets: Dictionary = pl.get("pets", {}) if typeof(pl.get("pets", {})) == TYPE_DICTIONARY else {}
	var skill_map: Dictionary = mounts.get("skills", {}) if typeof(mounts.get("skills", {})) == TYPE_DICTIONARY else {}
	var pet_skills: Dictionary = Data.calc.get("PET_SKILLS", {})
	for mid in owned:
		var sid := str(mid)
		var active := sid in summoned
		var m := Data.mount(sid)
		var st := _companion_stats(pl, sid)
		var card := _vb(6)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.custom_minimum_size = Vector2(0, 0)
		var head := HBoxContainer.new()
		head.add_theme_constant_override("separation", 10)
		head.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		head.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		head.custom_minimum_size = Vector2(0, 58)
		head.add_child(_pet_avatar(sid, 56))
		var tc := _vb(2)
		tc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tc.custom_minimum_size = Vector2(120, 0)
		tc.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		tc.add_child(T.label(Data.mount_name(sid) + (" · đã triệu hồi" if active else ""), T.FS_L, T.C_GOLD if active else T.C_TEXT, true))
		if not m.is_empty(): tc.add_child(T.label(str(m.get("desc", "")), T.FS_S, T.C_MUTED))
		tc.add_child(T.label("HP %d · Công %d · Thủ %d · MP %d" % [int(st["maxHp"]), int(st["atk"]), int(st["def"]), int(st["maxMp"])], T.FS_S, T.C_TEXT))
		head.add_child(tc)
		# Nút phải có min-width + tắt autowrap: nếu không, tc (EXPAND_FILL) ép nút về ~20px
		# rồi chữ "Triệu hồi · 10 MP" xuống dòng thành cột cao -> card phình, nội dung bị đẩy xuống.
		var pb: Button
		if active:
			pb = W.action_button("Thu hồi", func(): act("mount_set", {"id": sid}))
		else:
			var can := int(pl.get("mp", 0)) >= 10 and int(pl.get("level", 1)) >= int(m.get("level", 1))
			pb = W.action_button("Triệu hồi · 10 MP", func(): act("mount_set", {"id": sid}), not can)
			if not can: pb.tooltip_text = "Cần 10 MP và cấp %d." % int(m.get("level", 1))
		pb.custom_minimum_size = Vector2(132, 40)
		pb.autowrap_mode = TextServer.AUTOWRAP_OFF
		pb.clip_text = true
		pb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		head.add_child(pb)
		card.add_child(head)
		if active:
			var cur: Dictionary = pets.get(sid, {}) if typeof(pets.get(sid, null)) == TYPE_DICTIONARY else {}
			card.add_child(W.bar("HP", int(cur.get("hp", st["maxHp"])), int(st["maxHp"]), T.C_GREEN))
			card.add_child(W.bar("MP", int(cur.get("mp", st["maxMp"])), int(st["maxMp"]), T.C_BLUE))
			card.add_child(W.bar("Thể lực", int(cur.get("sta", st["maxSta"])), int(st["maxSta"]), T.C_GOLD))
			# Kỹ năng thú: ô vuông theo phong cách app, ô đang dùng nổi bật (không disable).
			var skill_id := str(skill_map.get(sid, mounts.get("skill", "bite")))
			if not pet_skills.has(skill_id): skill_id = "bite"
			card.add_child(W.section_label("Kỹ năng thú"))
			card.add_child(T.label("Chạm ô để chọn chiêu thú dùng. Mỗi lần dùng tốn MP và thể lực.", T.FS_S, Color(T.C_MUTED, 0.85)))
			var sg := _grid(3)
			for skid in pet_skills.keys():
				var skill: Dictionary = pet_skills[skid] if typeof(pet_skills[skid]) == TYPE_DICTIONARY else {}
				var skid_s := str(skid)
				var chosen := skid_s == skill_id
				var glyph := T.GlyphArt.token_of(str(skill.get("icon", "")))
				if glyph.is_empty(): glyph = "@paw"
				# Kích thước CỐ ĐỊNH (giống ô trang bị 46x46): Button thường không lấy min size từ con,
				# để width 0 là grid ép cột về 0 -> chữ tràn xuống dòng khác.
				var cell := T.button("", Vector2(150, 84))
				cell.focus_mode = Control.FOCUS_NONE
				cell.add_theme_stylebox_override("normal", T.UISkin.slot(0, chosen, false))
				cell.add_theme_stylebox_override("hover", T.UISkin.slot(0, true, false))
				cell.add_theme_stylebox_override("pressed", T.UISkin.slot(0, true, false))
				cell.tooltip_text = "%s\n%d MP · %d STA\n%s" % [str(skill.get("name", skid_s)), int(skill.get("mp", 0)), int(skill.get("sta", 0)), str(skill.get("desc", ""))]
				var inner := _vb(2)
				inner.set_anchors_preset(Control.PRESET_FULL_RECT)
				inner.offset_left = 6; inner.offset_right = -6; inner.offset_top = 6; inner.offset_bottom = -6
				inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
				var ic := T.GlyphArt.make(glyph, 28.0, T.C_GOLD if chosen else T.C_TEXT)
				ic.set_anchors_preset(Control.PRESET_TOP_WIDE)
				ic.custom_minimum_size = Vector2(0, 30)
				inner.add_child(ic)
				var nm := T.label(str(skill.get("name", skid_s)), T.FS_S, T.C_GOLD if chosen else T.C_TEXT, chosen)
				nm.autowrap_mode = TextServer.AUTOWRAP_OFF
				nm.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
				nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				nm.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
				nm.custom_minimum_size = Vector2(0, 22)
				nm.size_flags_vertical = Control.SIZE_EXPAND_FILL
				inner.add_child(nm)
				cell.add_child(inner)
				cell.pressed.connect(func(): act("pet_skill_set", {"id": sid, "skill": skid_s}))
				sg.add_child(cell)
			card.add_child(sg)
		card.add_child(_pet_gear_section(pl, sid))
		vb.add_child(W.card_row(card))
	return vb

## Anh thú: dùng bộ sprite quái theo look của loài (giống web).
func _pet_avatar(mid: String, px: int) -> Control:
	var m := Data.mount(mid)
	if m.is_empty():
		var sm: Variant = Data.calc.get("SUMMONS", {}).get(mid, null)
		if typeof(sm) == TYPE_DICTIONARY: m = sm as Dictionary
	var look := str(m.get("look", "wolf"))
	if not MobSpriteCls.PET_DEF.has(look): look = "wolf"
	var pd: Dictionary = MobSpriteCls.PET_DEF[look]
	var files: Dictionary = pd["files"]
	var src := "walk" if (pd["frames"] as Dictionary).has("walk") else "run"
	var path := MobSpriteCls.PET_DIR + str(files[src]) + ".png"
	var fr := PanelContainer.new()
	fr.add_theme_stylebox_override("panel", T.UISkin.slot(0, false))
	fr.custom_minimum_size = Vector2(px, px)
	fr.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if ResourceLoader.exists(path):
		var tex := load(path) as Texture2D
		var fw := int(pd["fw"])
		var fh := int(pd["fh"])
		var at := AtlasTexture.new()
		at.atlas = tex
		at.region = Rect2(0, int((pd.get("rows", {}) as Dictionary).get(src, 0)) * fh, fw, fh)
		var r := TextureRect.new()
		r.texture = at
		r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		r.custom_minimum_size = Vector2(px - 8, px - 8)
		r.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		r.flip_h = bool(pd.get("left", false))
		var tint_v: Variant = m.get("tint", null)
		if tint_v != null: r.modulate = Color.hex((int(tint_v) << 8) | 0xff)
		fr.add_child(r)
	return fr

## Trang bị thú: 4 ô (yên, dây cương, giáp, vòng cổ). Chạm một ô để mở danh sách món phù hợp trong túi và gán vào,
## hoặc "Tháo" món đang mặc. Luật (cấp yêu cầu, túi đầy...) do server kiểm: action pet_equip / pet_unequip.
const PET_SLOTS := [["yen", "Yên"], ["cuong", "Cương"], ["giap", "Giáp"], ["vong", "Vòng"]]

func _pet_gear_section(pl: Dictionary, mid: String) -> Control:
	var all: Dictionary = pl.get("petGear", {}) if typeof(pl.get("petGear", {})) == TYPE_DICTIONARY else {}
	var gear: Dictionary = all.get(mid, {}) if typeof(all.get(mid, {})) == TYPE_DICTIONARY else {}
	var box := _vb(6)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 8)
	var gl := T.label("Trang bị", 12, T.C_MUTED)
	gl.autowrap_mode = TextServer.AUTOWRAP_OFF
	gl.custom_minimum_size = Vector2(52, 0)
	gl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(gl)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	for pair in PET_SLOTS:
		var slot := str(pair[0])
		var key := mid + "|" + slot
		var is_sel := pet_sel == key
		row.add_child(_pet_gear_cell(str(pair[1]), _pet_slot_item(gear, slot), is_sel, func():
			pet_sel = "" if is_sel else key
			refresh()))
	head.add_child(row)
	var hint := T.label("Chạm một ô để gán / tháo", 12, Color(T.C_MUTED, 0.8))
	hint.autowrap_mode = TextServer.AUTOWRAP_OFF
	hint.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(hint)
	box.add_child(head)
	if pet_sel.begins_with(mid + "|"):
		var slot_id := pet_sel.get_slice("|", 1)
		box.add_child(_pet_gear_picker(pl, mid, slot_id, _pet_slot_item(gear, slot_id)))
	return box

static func _pet_slot_item(gear: Dictionary, slot: String) -> String:
	var v: Variant = gear.get(slot, null)
	return "" if v == null else str(v)

func _pet_gear_cell(slot_name: String, iid: String, selected: bool, cb: Callable) -> Button:
	var empty := iid.is_empty() or Data.item(iid).is_empty()
	var q := 0 if empty else int(Data.item(iid).get("q", 0))
	var b := T.button("", Vector2(46, 46))
	b.focus_mode = Control.FOCUS_NONE
	b.tooltip_text = slot_name if empty else W.item_name(iid)
	var normal: StyleBox = T.UISkin.slot(q, selected, empty)
	var hot: StyleBox = T.UISkin.slot(q, true, empty)
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hot)
	b.add_theme_stylebox_override("pressed", hot)
	if empty:
		var lb := T.label(slot_name, 10, Color(T.C_MUTED, 0.8))
		lb.autowrap_mode = TextServer.AUTOWRAP_OFF
		lb.set_anchors_preset(Control.PRESET_FULL_RECT)
		lb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lb.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(lb)
	else:
		var ic := W.item_icon(iid, 32)
		ic.set_anchors_preset(Control.PRESET_FULL_RECT)
		ic.offset_left = 7; ic.offset_top = 7; ic.offset_right = -7; ic.offset_bottom = -7
		ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(ic)
	b.pressed.connect(cb)
	return b

func _pet_gear_picker(pl: Dictionary, mid: String, slot: String, cur_id: String) -> Control:
	var inner := _vb(6)
	var slot_name := slot
	for pair in PET_SLOTS:
		if str(pair[0]) == slot: slot_name = str(pair[1])
	var hr := HBoxContainer.new()
	hr.add_theme_constant_override("separation", 8)
	var title := T.label("Ô %s" % slot_name, T.FS_M, T.C_GOLD, true)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.autowrap_mode = TextServer.AUTOWRAP_OFF
	hr.add_child(title)
	if not cur_id.is_empty():
		var cur_l := T.label("Đang mặc: %s" % W.item_name(cur_id), T.FS_S, T.C_GREEN)
		cur_l.autowrap_mode = TextServer.AUTOWRAP_OFF
		cur_l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		hr.add_child(cur_l)
		var off := W.action_button("Tháo", func(): act("pet_unequip", {"pet": mid, "slot": slot}))
		off.custom_minimum_size = Vector2(72, 34)
		off.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		hr.add_child(off)
	inner.add_child(hr)
	var lv := int(pl.get("level", 1))
	var seen := {}
	for e in pl.get("bag", []):
		if typeof(e) != TYPE_DICTIONARY: continue
		var iid := str((e as Dictionary).get("id", ""))
		var d: Dictionary = Data.item(iid)
		if str(d.get("kind", "")) != "pet_gear" or str(d.get("petSlot", "")) != slot: continue
		seen[iid] = int(seen.get(iid, 0)) + int((e as Dictionary).get("n", (e as Dictionary).get("qty", 1)))
	for iid in seen.keys():
		var need := int(Data.item(str(iid)).get("refLv", 0))
		var ok: bool = lv >= need and str(iid) != cur_id
		var r := W.shop_row(str(iid), "Có ×%d" % int(seen[iid]), "Cấp %d" % need, false, Callable())
		r.disabled = not ok
		var item_id := str(iid)
		r.pressed.connect(func(): act("pet_equip", {"pet": mid, "item": item_id}))
		inner.add_child(r)
	if seen.is_empty():
		inner.add_child(T.label("Túi không có trang bị cho ô này. Mua ở tiệm tạp hóa.", T.FS_S, Color(T.C_MUTED, 0.9)))
	var pc := PanelContainer.new()
	pc.add_theme_stylebox_override("panel", T.UISkin.inset(8))
	pc.add_child(inner)
	return pc

# ============================================================ SHADOWS
func build_shadows() -> Control:
	var vb := _vb()
	var sh: Dictionary = p().get("shadows", {})
	var roster: Array = sh.get("roster", [])
	var active: Array = sh.get("active", [])
	vb.add_child(W.action_button("Gọi / giải trừ đội bóng", func(): act("shadow_toggle", {})))
	if roster.is_empty(): vb.add_child(_empty("Chưa có bóng ma. Hạ quái để thu thập."))
	for s in roster:
		if typeof(s) != TYPE_DICTIONARY: continue
		var sd := s as Dictionary
		var uid := int(sd.get("uid", 0))
		var on := uid in active
		var h := W.list_row(null, "%s · Lv%d" % [W.monster_name(str(sd.get("monster", ""))), int(sd.get("lv", 1))], "Trong đội" if on else "Nghỉ", T.C_GOLD if on else T.C_TEXT)
		h.add_child(W.action_button("Bỏ khỏi đội" if on else "Đưa vào đội", func(): act("shadow_party", {"uid": uid})))
		var do_rel := func(): act("shadow_release", {"uid": uid})
		var rel := W.action_button("Giải phóng", func():
			host.confirm("Giải phóng bóng ma?", "%s sẽ biến mất vĩnh viễn." % W.monster_name(str(sd.get("monster", ""))), "Giải phóng", do_rel, true))
		rel.add_theme_color_override("font_color", T.C_RED)
		h.add_child(rel)
		vb.add_child(W.card_row(h))
	return vb

# ============================================================ CONFIG
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

# ============================================================ BIẾN HÌNH (Ấn thức tỉnh)
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

# ============================================================ KỲ NGUYÊN
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

# ============================================================ SOCIAL (đội, khu, chợ) + TRADE
var social_tab := "near"
var _social_data_requested := false   # chợ/khu: gửi request đúng 1 lần mỗi lần mở từ NPC
var market_tab := "buy"
var market_sel_uid := ""
var market_confirm := 0
var market_q := ""
var market_sort := "price_asc"
var market_page := 0

func _class_name(sc: String) -> String:
	var d: Dictionary = Data.school(sc)
	return str(d.get("name", "Tập sự")) if not d.is_empty() else "Tập sự"

func _player_row(info: Dictionary, buttons: Array) -> Control:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	var col := _vb(0)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_child(T.label(str(info.get("name", "?")), T.FS_M, T.C_TEXT, true))
	col.add_child(T.label("Lv %d · %s" % [int(info.get("lv", 1)), _class_name(str(info.get("sc", "")))], T.FS_S, T.C_MUTED))
	h.add_child(col)
	for b in buttons: h.add_child(b)
	# Hang phang: khong vien vang, khong nen xanh cho o bat/tat.
	return h

func _soc_tab(t: String) -> void:
	social_tab = t
	if t == "khu": Socket.send_chlist()
	if t == "market": _market_refresh()
	refresh()

func _market_refresh() -> void:
	if market_tab == "buy":
		Net.action("market_browse", {"q": market_q, "sort": market_sort, "page": market_page})
	elif market_tab == "mine":
		Net.action("market_mine", {})

func build_social() -> Control:
	var vb := _vb(8)
	# Chợ / chọn khu chỉ mở từ NPC (NpcDialog truyền tab qua ctx_extra). Menu Xã hội
	# tự nó chỉ có Quanh đây / Đội, nên mọi refresh không có extra thì về lại "near".
	if ctx_extra.has("tab"):
		var wanted := str(ctx_extra["tab"])
		ctx_extra.erase("tab")
		social_tab = wanted if wanted in ["near", "party", "khu", "market"] else "near"
		_social_data_requested = false   # NPC vừa mở panel: cho gửi request dữ liệu lần đầu
	else:
		if social_tab not in ["near", "party"]: social_tab = "near"
	# Tab khu/chợ là NPC-only: hiện nội dung tương ứng nhưng không đưa vào thanh segmented.
	if social_tab == "khu":
		if not _social_data_requested:
			Socket.send_chlist()
			_social_data_requested = true
		vb.add_child(T.heading("Chọn khu", T.C_GOLD))
		_social_khu(vb)
		return W.fill(vb)
	if social_tab == "market":
		if not _social_data_requested:
			_market_refresh()
			_social_data_requested = true
		vb.add_child(T.heading("Chợ người chơi", T.C_GOLD))
		_social_market(vb)
		return W.fill(vb)
	vb.add_child(W.segmented([["near", "Quanh đây"], ["party", "Đội"]], social_tab, _soc_tab))
	if social_tab == "party": _social_party(vb)
	else: _social_near(vb)
	return vb

func _social_near(vb: VBoxContainer) -> void:
	if Social.nearby.is_empty():
		vb.add_child(_empty("Chưa có người chơi nào cùng bản đồ.", "social"))
		return
	for id in Social.nearby.keys():
		var info: Dictionary = Social.nearby[id]
		var pid: int = int(id)
		var btns: Array = []
		if not _is_mate(pid):
			btns.append(W.action_button("Mời đội", func(): Socket.send_party("inv", {"to": pid}); host.toast("Đã gửi lời mời đội")))
		btns.append(W.action_button("Giao dịch", func(): Socket.send_trade("inv", {"to": pid}); host.toast("Đã gửi lời mời giao dịch")))
		vb.add_child(_player_row(info, btns))

func _is_mate(pid: int) -> bool:
	for m in Social.party.get("members", []):
		if typeof(m) == TYPE_DICTIONARY and int(m.get("id", 0)) == pid: return true
	return false

func _social_party(vb: VBoxContainer) -> void:
	if not Social.in_party():
		vb.add_child(_empty("Bạn chưa ở trong đội.\nMời người chơi ở tab Quanh đây. Chat đội: /p nội dung.", "social"))
		return
	var members: Array = Social.party.get("members", [])
	var lead: int = int(Social.party.get("leader", 0))
	var iam_lead := lead == Socket.my_id
	vb.add_child(W.chip_row([["%d/5 thành viên" % members.size(), T.C_GOLD]]))
	for m in members:
		if typeof(m) != TYPE_DICTIONARY: continue
		var mid: int = int(m.get("id", 0))
		var inner := _vb(4)
		var head := HBoxContainer.new()
		var nm := T.label(("★ " if mid == lead else "") + str(m.get("name", "?")), T.FS_M, T.C_GOLD if mid == lead else T.C_TEXT, true)
		nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		head.add_child(nm)
		var st := "Lv %d · %s" % [int(m.get("lv", 1)), _class_name(str(m.get("sc", "")))]
		if not bool(m.get("on", true)): st += " · mất kết nối"
		if bool(m.get("dead", false)): st += " · đã gục"
		head.add_child(T.label(st, T.FS_S, T.C_MUTED))
		inner.add_child(head)
		inner.add_child(W.bar("HP", int(m.get("hp", 0)) if bool(m.get("on", true)) else 0, 100, T.C_RED))
		if iam_lead and mid != Socket.my_id:
			var hb := HBoxContainer.new()
			hb.add_theme_constant_override("separation", 8)
			var b1 := W.action_button("Nhường trưởng", func(): Socket.send_party("lead", {"id": mid}))
			var b2 := W.action_button("Đuổi", func(): Socket.send_party("kick", {"id": mid}))
			b1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			b2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			hb.add_child(b1); hb.add_child(b2)
			inner.add_child(hb)
		vb.add_child(W.card_row(inner))
	vb.add_child(W.action_button("Rời đội", func(): Socket.send_party("leave")))

func _social_khu(vb: VBoxContainer) -> void:
	var ch: Dictionary = Social.channels
	if ch.is_empty():
		vb.add_child(_empty("Đang tải danh sách khu…", "map"))
		return
	var cur: int = int(ch.get("cur", 1))
	var cap: int = int(ch.get("cap", 20))
	vb.add_child(T.label("Đang ở Khu %d · mỗi khu tối đa %d người" % [cur, cap], T.FS_S, T.C_MUTED))
	var g := _grid(4)
	for e in ch.get("list", []):
		if typeof(e) != TYPE_ARRAY or (e as Array).size() < 2: continue
		var n: int = int(e[0]); var c: int = int(e[1])
		var b := T.button("Khu %d\n%d/%d" % [n, c, cap], Vector2(0, 56))
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var on := n == cur
		var sb: StyleBox = T.UISkin.tab(on)
		b.add_theme_stylebox_override("normal", sb)
		b.add_theme_stylebox_override("hover", sb)
		b.disabled = on or c >= cap
		b.pressed.connect(func(): Socket.send_channel(n); host.toast("Đang chuyển khu…"))
		g.add_child(b)
	vb.add_child(g)

func _time_left(ms: float) -> String:
	var h := int(ms / 3600000.0)
	var m := int(fmod(ms, 3600000.0) / 60000.0)
	return "%dg%dp" % [h, m] if h > 0 else "%dp" % m

func _listing_row(l: Dictionary, mine: bool) -> Control:
	var inst: Dictionary = l.get("inst", {}) if typeof(l.get("inst", {})) == TYPE_DICTIONARY else {}
	var iid := str(inst.get("id", l.get("item", "")))
	var d: Dictionary = Data.item(iid)
	var now := Time.get_unix_time_from_system() * 1000.0
	var left: String
	if bool(l.get("expired", false)): left = "hết hạn"
	elif str(l.get("status", "")) == "sold": left = "đã bán"
	else: left = "còn " + _time_left(maxf(0.0, float(l.get("expires", now)) - now))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	h.add_child(W.item_cell(iid, int(inst.get("qty", 1)), false, Callable(), ("+%d" % int(inst.get("plus", 0))) if int(inst.get("plus", 0)) > 0 else ""))
	var col := _vb(0)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	col.add_child(T.label(str(d.get("name", iid)), T.FS_M, T.C_TEXT, true))
	var sub := "Cấp %d · %s" % [int(l.get("level", 1)), left]
	if not mine: sub = "%s · %s" % [str(l.get("seller", "")), sub]
	col.add_child(T.label(sub, T.FS_S, T.C_MUTED))
	h.add_child(col)
	var price := T.label("%s xu" % W.fmt_num(int(l.get("price", 0))), T.FS_M, T.C_GOLD, true)
	price.autowrap_mode = TextServer.AUTOWRAP_OFF
	h.add_child(price)
	var lid: int = int(l.get("id", 0))
	if mine:
		if str(l.get("status", "")) == "active":
			h.add_child(W.action_button("Lấy lại" if bool(l.get("expired", false)) else "Huỷ", func(): Net.action("market_cancel", {"id": lid}); Net.action("market_mine", {})))
	else:
		var key := "L%d" % lid
		if confirm_buy == key:
			h.add_child(W.action_button("Chắc chắn?", func(): confirm_buy = ""; Net.action("market_buy", {"id": lid}); _market_refresh()))
		else:
			h.add_child(W.action_button("Mua", func(): confirm_buy = key; refresh()))
	# Hang phang: khong vien vang, khong nen xanh cho o bat/tat.
	return h

func _social_market(vb: VBoxContainer) -> void:
	vb.add_child(_gold_row(p(), false))
	vb.add_child(W.segmented([["buy", "Mua"], ["sell", "Đăng bán"], ["mine", "Tin của tôi"]], market_tab, func(t): market_tab = t; market_sel_uid = ""; confirm_buy = ""; _market_refresh(); refresh()))
	match market_tab:
		"buy":
			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation", 8)
			var le := LineEdit.new()
			le.placeholder_text = "Tìm theo tên"
			le.text = market_q
			le.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			le.custom_minimum_size = Vector2(0, 40)
			le.text_submitted.connect(func(t): market_q = t; market_page = 0; _market_refresh())
			row.add_child(le)
			row.add_child(W.action_button("Tìm", func(): market_q = le.text; market_page = 0; _market_refresh()))
			var sort_btn := W.action_button("Giá ↑" if market_sort == "price_asc" else ("Giá ↓" if market_sort == "price_desc" else "Mới"), func():
				market_sort = "price_desc" if market_sort == "price_asc" else ("new" if market_sort == "price_desc" else "price_asc")
				market_page = 0; _market_refresh(); refresh())
			row.add_child(sort_btn)
			vb.add_child(row)
			var br: Dictionary = Social.browse
			var list: Array = br.get("list", [])
			if list.is_empty(): vb.add_child(_empty("Chưa có món nào đang bán.\nChợ chỉ mở khi bạn đứng trong làng.", "shop"))
			for l in list:
				if typeof(l) == TYPE_DICTIONARY: vb.add_child(_listing_row(l, false))
			var per: int = maxi(1, int(br.get("per", 20)))
			var pages: int = maxi(1, int(ceil(float(int(br.get("total", 0))) / float(per))))
			var pg := HBoxContainer.new()
			pg.add_theme_constant_override("separation", 8)
			var prev := W.action_button("‹", func(): market_page = maxi(0, market_page - 1); _market_refresh(), market_page <= 0)
			var nxt := W.action_button("›", func(): market_page += 1; _market_refresh(), market_page + 1 >= pages)
			prev.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			nxt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			pg.add_child(prev)
			var pl := T.label("Trang %d/%d" % [market_page + 1, pages], T.FS_S, T.C_MUTED)
			pl.autowrap_mode = TextServer.AUTOWRAP_OFF
			pg.add_child(pl)
			pg.add_child(nxt)
			vb.add_child(pg)
		"sell":
			vb.add_child(T.label("Chạm một món trong túi rồi đặt giá. Thuế 5% khi bán được, tin tồn tại 48 giờ.", T.FS_S, T.C_MUTED))
			var g := _grid(7)
			for e in p().get("bag", []):
				if typeof(e) != TYPE_DICTIONARY: continue
				var d: Dictionary = Data.item(str(e.get("id", "")))
				if str(d.get("kind", "")) == "quest": continue
				var uid := str(e.get("uid", ""))
				g.add_child(W.item_cell(str(e.get("id", "")), int(e.get("n", e.get("qty", 1))), market_sel_uid == uid, func(): market_sel_uid = uid; refresh()))
			vb.add_child(g)
			if market_sel_uid != "":
				var e2 := _bag_entry(market_sel_uid)
				if not e2.is_empty():
					var inner := _vb(6)
					inner.add_child(T.label("Đăng bán: " + W.item_name(str(e2.get("id", ""))), T.FS_M, T.C_GOLD, true))
					var pr := HBoxContainer.new()
					pr.add_theme_constant_override("separation", 8)
					var price_le := LineEdit.new()
					price_le.placeholder_text = "Giá (xu)"
					price_le.custom_minimum_size = Vector2(0, 40)
					price_le.size_flags_horizontal = Control.SIZE_EXPAND_FILL
					price_le.virtual_keyboard_type = LineEdit.KEYBOARD_TYPE_NUMBER
					pr.add_child(price_le)
					var qty_all: int = int(e2.get("qty", e2.get("n", 1)))
					var is_stack := bool(Data.item(str(e2.get("id", ""))).get("stack", false))
					if is_stack and qty_all > 1:
						var qty_le := LineEdit.new()
						qty_le.text = str(qty_all)
						qty_le.placeholder_text = "Số lượng"
						qty_le.custom_minimum_size = Vector2(90, 40)
						qty_le.virtual_keyboard_type = LineEdit.KEYBOARD_TYPE_NUMBER
						pr.add_child(qty_le)
						pr.set_meta("qty_le", qty_le)
					pr.add_child(W.action_button("Đăng bán", func():
						var pv := int(price_le.text.to_int())
						if pv < 1: host.toast("Nhập giá hợp lệ", "warn"); return
						var sq := qty_all
						if pr.has_meta("qty_le"):
							sq = mini(maxi(1, (pr.get_meta("qty_le") as LineEdit).text.to_int()), qty_all)
						Net.action("market_list", {"uid": int(market_sel_uid), "qty": sq, "price": pv})
						market_sel_uid = ""; refresh()))
					inner.add_child(pr)
					vb.add_child(W.card_row(inner))
		_:
			var ml: Array = Social.mine.get("list", [])
			if ml.is_empty(): vb.add_child(_empty("Bạn chưa đăng bán món nào.", "shop"))
			for l2 in ml:
				if typeof(l2) == TYPE_DICTIONARY: vb.add_child(_listing_row(l2, true))

func _trade_side(s: Dictionary, title: String, mine: bool) -> Control:
	var inner := _vb(6)
	inner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var ttl := T.label(title + ("  [đã khoá]" if bool(s.get("locked", false)) else ""), T.FS_M, T.C_GREEN if bool(s.get("locked", false)) else T.C_GOLD, true)
	ttl.autowrap_mode = TextServer.AUTOWRAP_OFF
	ttl.clip_text = true
	inner.add_child(ttl)
	var g := _grid(4)
	var items: Array = s.get("items", [])
	for e in items:
		if typeof(e) != TYPE_DICTIONARY: continue
		var uid: int = int(e.get("uid", 0))
		g.add_child(W.item_cell(str(e.get("id", "")), int(e.get("qty", 1)), false, func(): if mine: _trade_unset(uid), ("+%d" % int(e.get("plus", 0))) if int(e.get("plus", 0)) > 0 else ""))
	if items.is_empty(): inner.add_child(T.label("Chưa đặt gì", T.FS_S, T.C_MUTED))
	inner.add_child(g)
	if mine:
		var gr := HBoxContainer.new()
		gr.add_theme_constant_override("separation", 6)
		var xl := T.label("Xu", T.FS_S, T.C_MUTED)
		xl.autowrap_mode = TextServer.AUTOWRAP_OFF
		gr.add_child(xl)
		var le := LineEdit.new()
		le.text = str(int(s.get("gold", 0)))
		le.custom_minimum_size = Vector2(0, 38)
		le.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		le.virtual_keyboard_type = LineEdit.KEYBOARD_TYPE_NUMBER
		le.text_submitted.connect(func(t): _trade_push(_trade_items(), maxi(0, t.to_int())))
		le.focus_exited.connect(func(): if le.text.to_int() != int(s.get("gold", 0)): _trade_push(_trade_items(), maxi(0, le.text.to_int())))
		gr.add_child(le)
		inner.add_child(gr)
	else:
		inner.add_child(T.label("Xu: %s" % W.fmt_num(int(s.get("gold", 0))), T.FS_S, T.C_GOLD))
	var card := W.card_row(inner)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.custom_minimum_size = Vector2(230, 0)
	return card

func _trade_items() -> Array:
	var out: Array = []
	for e in (Social.trade.get("me", {}) as Dictionary).get("items", []):
		if typeof(e) == TYPE_DICTIONARY: out.append({"uid": int(e.get("uid", 0)), "qty": int(e.get("qty", 1))})
	return out

func _trade_push(items: Array, gold: int) -> void:
	Socket.send_trade("set", {"items": items, "gold": gold})

func _trade_unset(uid: int) -> void:
	var items := _trade_items().filter(func(i): return int(i["uid"]) != uid)
	_trade_push(items, int((Social.trade.get("me", {}) as Dictionary).get("gold", 0)))

func build_trade() -> Control:
	var vb := _vb(8)
	if not Social.in_trade():
		vb.add_child(_empty("Không có giao dịch nào đang mở.", "bag"))
		return vb
	var me: Dictionary = Social.trade.get("me", {})
	var them: Dictionary = Social.trade.get("them", {})
	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 8)
	cols.add_child(_trade_side(me, "Bạn đưa", true))
	cols.add_child(_trade_side(them, "%s đưa" % str(them.get("name", "?")), false))
	vb.add_child(cols)
	var locked := bool(me.get("locked", false))
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 8)
	var lk := W.action_button("Bỏ khoá" if locked else "Khoá", func(): Socket.send_trade("lock", {"on": not locked}))
	lk.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(lk)
	var cn := W.action_button("Huỷ giao dịch", func(): Socket.send_trade("cancel"))
	cn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(cn)
	vb.add_child(hb)
	vb.add_child(T.label("Mọi thay đổi bỏ khoá cả hai bên. Khi cả hai cùng khoá, giao dịch được thực hiện.", T.FS_S, T.C_MUTED))
	vb.add_child(W.section_label("Túi của bạn (chạm để đặt vào, tối đa 8 món)"))
	var offered := {}
	for i in _trade_items(): offered[int(i["uid"])] = true
	var g := _grid(8)
	for e in p().get("bag", []):
		if typeof(e) != TYPE_DICTIONARY: continue
		var d: Dictionary = Data.item(str(e.get("id", "")))
		var uid: int = int(e.get("uid", 0))
		if offered.has(uid) or str(d.get("kind", "")) == "quest": continue
		var qty: int = int(e.get("n", e.get("qty", 1)))
		g.add_child(W.item_cell(str(e.get("id", "")), qty, false, func():
			var items := _trade_items()
			if items.size() >= 8: host.toast("Tối đa 8 món", "warn"); return
			items.append({"uid": uid, "qty": qty})
			_trade_push(items, int(me.get("gold", 0)))))
	vb.add_child(g)
	return vb

# ============================================================ DISPATCH
func build(tab: String, extra: Dictionary = {}) -> Control:
	ctx_extra = extra.duplicate()
	if tab.is_empty(): return T.label("Chọn một mục.", T.FS_M, T.C_MUTED)
	var fn_name := "build_" + tab
	if not has_method(fn_name): return T.label("Chưa có panel: " + tab, T.FS_M, T.C_RED)
	var node: Variant = call(fn_name)
	return node if node is Control else T.label("Lỗi panel: " + tab, T.FS_M, T.C_RED)