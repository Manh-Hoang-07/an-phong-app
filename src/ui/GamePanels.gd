extends RefCounted
## 19 panel game, port từ web public/js/ui/panels/*.js. Bố cục hai cột (danh sách + chi tiết) cho điện thoại ngang.
## Mọi thao tác gọi Net.action(type, params); luật chơi ở server. host = MobileHUD.

const T := preload("res://src/ui/UITheme.gd")
const W := preload("res://src/ui/PanelWidgets.gd")

# Trạng thái UI cục bộ (tương đương S của web)
var selected_where := ""
var selected_key := ""
var confirm_drop := ""
var confirm_release := -1
var confirm_buy := ""
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
	confirm_drop = ""; confirm_buy = ""; refresh()

func _deselect() -> void:
	selected_where = ""; selected_key = ""; confirm_drop = ""; confirm_buy = ""; refresh()

func _gold_row(pl: Dictionary, ngoc: bool = true) -> Control:
	var items: Array = [["Vàng  %s" % W.fmt_num(int(pl.get("gold", 0))), T.C_GOLD]]
	if ngoc: items.append(["Linh Ngọc  %s" % W.fmt_num(int(pl.get("linhNgoc", 0))), T.C_PURPLE])
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
	var cap := T.label("Túi %d/%d" % [bag.size(), Data.const_int("BAG_SIZE", 40)], T.FS_S, T.C_MUTED)
	cap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	top.add_child(cap)
	vb.add_child(top)
	var g := _grid(6)
	var shown := 0
	for i in range(bag.size()):
		var e: Dictionary = bag[i] if typeof(bag[i]) == TYPE_DICTIONARY else {}
		if not _bag_match(str(e.get("id", ""))): continue
		shown += 1
		var uid := str(e.get("uid", i))
		g.add_child(W.item_cell(str(e.get("id", "")), int(e.get("n", e.get("qty", 1))), selected_where == "bag" and selected_key == uid, func(): _select("bag", uid)))
	var cap_n := Data.const_int("BAG_SIZE", 40) if bag_filter == "all" else maxi(shown, 12)
	for _i in range(shown, cap_n): g.add_child(W.empty_cell())
	var left_box := _vb(8)
	left_box.add_child(W.segmented([["all", "Tất cả"], ["gear", "Trang bị"], ["use", "Tiêu hao"], ["misc", "Khác"]], bag_filter, func(f): bag_filter = f; refresh()))
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
	var is_use := kind in ["potion", "boost", "book", "skill_book", "ult_book", "transform_book", "slot_book", "erase_book"]
	match bag_filter:
		"gear": return is_gear
		"use": return is_use and not is_gear
		_: return not is_gear and not is_use

func _bag_detail(e: Dictionary) -> Control:
	var iid := str(e.get("id", ""))
	var d: Dictionary = Data.item(iid)
	var box := W.item_detail(iid, int(e.get("plus", 0)))
	var body := W.box_body(box)
	var uidn := int(e.get("uid", 0))
	var qty := int(e.get("n", e.get("qty", 1)))
	if qty > 1: body.add_child(T.label("Số lượng: %d" % qty, T.FS_S, T.C_TEXT))
	if not str(d.get("slot", "")).is_empty():
		body.add_child(W.action_button("Trang bị", func(): act("equip", {"uid": uidn}); _deselect()))
	if d.has("kind") and str(d.get("kind", "")) in ["potion", "book", "transform_book", "buff", "box", "food", "consumable"]:
		body.add_child(W.action_button("Sử dụng", func(): act("use", {"item": iid})))
	elif d.has("hp") or d.has("mp"):
		body.add_child(W.action_button("Sử dụng", func(): act("use", {"item": iid})))
	if int(d.get("price", 0)) > 0:
		body.add_child(W.action_button("Bán 1", func(): act("sell", {"uid": uidn, "qty": 1}); _deselect()))
	var ck := "%d:all" % uidn
	var do_drop := func():
		act("drop", {"uid": uidn, "qty": qty})
		_deselect()
	var drop := W.action_button("Vứt bỏ", func():
		host.confirm("Vứt vật phẩm?", "Bạn sắp vứt %s%s. Không thể lấy lại." % [str(d.get("name", iid)), (" ×%d" % qty) if qty > 1 else ""], "Vứt", do_drop, true))
	drop.add_theme_color_override("font_color", T.C_RED)
	body.add_child(drop)
	return box

# ============================================================ EQUIP
const EQUIP_SLOTS := ["weapon", "mu", "ao", "gang_tay", "dai_lung", "quan", "giay", "nhan", "day_chuyen", "ngoc_boi"]
const EQUIP_NAMES := {"weapon": "Vũ khí", "mu": "Mũ", "ao": "Áo", "gang_tay": "Găng tay", "dai_lung": "Đai lưng", "quan": "Quần",
	"giay": "Giày", "nhan": "Nhẫn", "day_chuyen": "Dây chuyền", "ngoc_boi": "Ngọc bội"}

func _equip_col(slots: Array, eq: Dictionary) -> VBoxContainer:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	col.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	for sl in slots:
		var it: Variant = eq.get(sl, null)
		var iid := str((it as Dictionary).get("id", "")) if typeof(it) == TYPE_DICTIONARY else ""
		var plus := int((it as Dictionary).get("plus", 0)) if typeof(it) == TYPE_DICTIONARY else 0
		var slot := str(sl)
		col.add_child(W.equip_cell(str(EQUIP_NAMES.get(sl, sl)), iid, plus, selected_where == "equip" and selected_key == slot, func(): _select("equip", slot)))
	return col

func build_equip() -> Control:
	var vb := _vb()
	var pl := p()
	var eq: Dictionary = pl.get("equip", {})
	var school := str(pl.get("school", "kiem_si"))
	var st: Dictionary = Game.stats
	# Giữa: nhân vật trong khung lõm, tên + chỉ số bên dưới
	var mid := _vb(6)
	mid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var frame := PanelContainer.new()
	frame.add_theme_stylebox_override("panel", T.UISkin.inset(6))
	frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var body := W.char_body(school, Vector2(140, 190))
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	frame.add_child(body)
	mid.add_child(frame)
	var nm := T.label("%s · Lv %d" % [str(pl.get("name", "?")), int(pl.get("level", 1))], T.FS_S, T.C_GOLD, true)
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mid.add_child(nm)
	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 10)
	cols.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cols.add_child(_equip_col(["weapon", "mu", "ao", "gang_tay", "dai_lung"], eq))
	cols.add_child(mid)
	cols.add_child(_equip_col(["quan", "giay", "nhan", "day_chuyen", "ngoc_boi"], eq))
	mid.custom_minimum_size = Vector2(120, 0)
	var right: Control
	var sel_it: Variant = eq.get(selected_key, null) if selected_where == "equip" else null
	if selected_where == "equip" and typeof(sel_it) == TYPE_DICTIONARY:
		var box := W.item_detail(str((sel_it as Dictionary).get("id", "")), int((sel_it as Dictionary).get("plus", 0)))
		var sk := selected_key
		W.box_body(box).add_child(W.action_button("Tháo ra", func(): act("unequip", {"slot": sk}); _deselect()))
		right = box
	else:
		var box2 := W.detail_box()
		var bd := W.box_body(box2)
		if selected_where == "equip": bd.add_child(T.label("Ô %s đang trống.\nMở Túi để trang bị." % str(EQUIP_NAMES.get(selected_key, "")), T.FS_S, T.C_MUTED))
		else: bd.add_child(T.label("Chỉ số", T.FS_M, T.C_GOLD, true))
		bd.add_child(W.kv("Tấn công", str(int(st.get("atk", 0))), T.C_RED))
		bd.add_child(W.kv("Phòng thủ", str(int(st.get("def", 0))), T.C_BLUE))
		bd.add_child(W.kv("Máu", str(int(st.get("maxHp", 0))), T.C_RED))
		bd.add_child(W.kv("MP", str(int(st.get("maxMp", 0))), T.C_BLUE))
		bd.add_child(W.kv("Chí mạng", "%s%%" % str(snappedf(float(st.get("crit", 0)), 0.1))))
		bd.add_child(T.label("Chạm một ô để xem hoặc tháo trang bị.", T.FS_S, Color(T.C_MUTED, 0.8)))
		right = box2
	vb.add_child(W.split(cols, right, 210.0))
	return W.fill(vb)

# ============================================================ CHAR
func build_char() -> Control:
	var vb := _vb()
	var pl := p()
	var school := str(pl.get("school", "kiem_si"))
	var st: Dictionary = Game.stats
	if st.is_empty(): st = pl.get("stats", {})
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 12)
	var portrait := W.char_avatar(school, 76)
	portrait.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	head.add_child(W.card_row(portrait))
	var info := _vb(2)
	info.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	info.add_child(T.label(str(pl.get("name", "?")), T.FS_XL, T.C_GOLD, true))
	info.add_child(W.chip_row([["Lv %d" % int(pl.get("level", 1)), T.C_GOLD], ["Hạng %s" % str(pl.get("rank", "E")), T.C_BLUE], [W.school_name(school), T.C_PURPLE]]))
	head.add_child(info)
	vb.add_child(head)
	vb.add_child(W.bar("HP", Game.hp, int(st.get("maxHp", 100)), T.C_RED))
	vb.add_child(W.bar("MP", Game.mp, int(st.get("maxMp", 100)), T.C_BLUE))
	var g := _grid(3)
	g.add_child(W.stat_tile("Tấn công", str(int(st.get("atk", 0))), T.C_RED))
	g.add_child(W.stat_tile("Phòng thủ", str(int(st.get("def", 0))), T.C_BLUE))
	g.add_child(W.stat_tile("Chí mạng", "%s%%" % str(snappedf(float(st.get("crit", 0)), 0.1))))
	g.add_child(W.stat_tile("Sức mạnh KN", "×%s" % str(snappedf(float(st.get("skillMul", 1.0)), 0.01)), T.C_PURPLE))
	g.add_child(W.stat_tile("Kinh nghiệm", "%s / %s" % [W.fmt_num(int(pl.get("exp", 0))), W.fmt_num(Formulas.exp_to_next(int(pl.get("level", 1))))], T.C_GOLD))
	g.add_child(W.stat_tile("Vàng", W.fmt_num(int(pl.get("gold", 0))), T.C_GOLD))
	for c in g.get_children(): c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_child(g)
	vb.add_child(T.hsep())
	var free_pts := int(pl.get("freePoints", 0))
	vb.add_child(W.section_label("Tiềm năng · còn %d điểm" % free_pts))
	var pts: Dictionary = pl.get("points", {})
	var label_map := {"str": "Sức mạnh", "vit": "Thể lực", "agi": "Nhanh nhẹn", "spi": "Tinh thần"}
	var hint_map := {"str": "+2 tấn công / điểm", "vit": "+10 máu, +0.8 thủ / điểm", "agi": "+0.4% chí mạng / điểm", "spi": "+6 MP, sức mạnh kỹ năng"}
	for key in ["str", "vit", "agi", "spi"]:
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 8)
		var col := _vb(0)
		col.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		col.add_child(T.label("%s  %d" % [str(label_map[key]), int((pts as Dictionary).get(key, 0))], T.FS_M, T.C_TEXT, true))
		col.add_child(T.label(str(hint_map[key]), T.FS_S, T.C_MUTED))
		h.add_child(col)
		h.add_child(W.action_button("+1", func(): act("add_stat", {"stat": key, "n": 1}), free_pts < 1))
		h.add_child(W.action_button("+5", func(): act("add_stat", {"stat": key, "n": 5}), free_pts < 5))
		vb.add_child(W.card_row(h))
	var kn: Dictionary = pl.get("kyNguyen", {})
	var n_on: int = (kn.get("active", []) as Array).size()
	vb.add_child(T.hsep())
	var ky_btn := W.action_button("Kỳ Nguyên  ·  %d đang bật" % n_on, func(): host.open_panel("kynguyen"))
	ky_btn.add_theme_color_override("font_color", T.C_GOLD)
	vb.add_child(ky_btn)
	var tier := int(pl.get("awakenTier", 0))
	var fbtn := W.action_button(("Biến hình · Ấn %s%s" % [str(Data.ROMAN[clampi(maxi(1, Data.awaken_tier_of(pl.get("formChoice", ""))) - 1, 0, 4)]), "  ·  đang bật" if Game.form_active else ""]) if tier > 0 else "Biến hình · chưa mở khóa", func(): host.open_panel("form"))
	fbtn.add_theme_color_override("font_color", T.C_GOLD if tier > 0 else T.C_MUTED)
	vb.add_child(fbtn)
	return vb

# ============================================================ SKILLS
const SKILL_TYPES := {"dash": "Lướt", "melee": "Cận chiến", "guard": "Thủ thế", "buff": "Cường hóa", "sword_fall": "Kiếm giáng", "aoe": "Diện rộng",
	"projectile": "Phóng", "spread": "Tỏa", "backstep": "Lùi chém", "arrow_rain": "Mưa tên", "heal": "Hồi phục", "manashield": "Khiên năng lượng",
	"meteor": "Thiên thạch", "summon": "Triệu hồi", "shadow_toggle": "Bóng ma", "shadow_command": "Lệnh bóng", "execute": "Hành quyết",
	"fusion": "Hợp thể", "manaburst": "Bùng nổ", "allin": "Tất tay"}

func _skill_detail(sid: String, learned: Dictionary, pl: Dictionary) -> Control:
	var d: Dictionary = Data.skill(sid)
	var box := W.detail_box()
	var body := W.box_body(box)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 8)
	var gf := PanelContainer.new()
	gf.add_theme_stylebox_override("panel", T.UISkin.slot(4 if bool(d.get("ult", false)) else 3))
	var gl := T.label(str(d.get("icon", "✦")), 28, T.C_TEXT)
	gl.autowrap_mode = TextServer.AUTOWRAP_OFF
	gl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gl.custom_minimum_size = Vector2(40, 40)
	gf.add_child(gl)
	head.add_child(gf)
	var col := _vb(0)
	col.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	col.add_child(T.label(str(d.get("name", sid)), T.FS_M, T.C_GOLD, true))
	var is_super := bool(d.get("superUlt", false)) and (pl.get("superUlts", []) as Array).has(sid)
	var is_learned := learned.has(sid) or is_super
	var lv := 0
	if is_learned: lv = int((learned[sid] as Dictionary).get("lv", 1)) if typeof(learned[sid]) == TYPE_DICTIONARY else int(learned[sid])
	col.add_child(T.label("Sở hữu · chỉ số cố định" if is_super else (("Cấp %d / 10" % lv) if is_learned else "Chưa học · cần cấp %d" % int(d.get("level", 1))), T.FS_S, T.C_MUTED))
	head.add_child(col)
	body.add_child(head)
	var chips: Array = [[str(SKILL_TYPES.get(str(d.get("type", "")), "Kỹ năng")), T.C_PURPLE], ["MP %d" % int(d.get("mp", 0)), T.C_BLUE], ["Hồi %ss" % str(d.get("cd", 0)), T.C_MUTED]]
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
	if not stat_bits.is_empty(): body.add_child(T.label(" · ".join(stat_bits), T.FS_S, T.C_GREEN))
	# Mốc nâng cấp
	for ms in [[5, "t5"], [10, "t10"]]:
		if not d.has(str(ms[1])): continue
		var reached := is_learned and lv >= int(ms[0])
		body.add_child(T.label("%s Cấp %d: %s" % ["✓" if reached else "🔒", int(ms[0]), str(d[str(ms[1])])], T.FS_S, T.C_GREEN if reached else Color(T.C_MUTED, 0.8)))
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
		var targets: Array = [5, 6] if is_ult else [0, 1, 2, 3]
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
	else:
		var req := int(d.get("level", 1))
		var ok := int(pl.get("level", 1)) >= req
		body.add_child(W.action_button("Học" if ok else "Cần cấp %d" % req, func(): act("learn_skill", {"skill": sid}), not ok or pts < 1))
		if ok and pts < 1: body.add_child(T.label("Cần ít nhất 1 điểm kỹ năng.", 12, Color(T.C_MUTED, 0.85)))
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
	for i in [0, 1, 2, 3, 5, 6]:
		var raw: Variant = slots[i] if i < slots.size() else null
		var sid := "" if raw == null or str(raw) == "<null>" else str(raw)
		var idx: int = i
		bar.add_child(W.skill_cell(W.skill_icon(sid) if not sid.is_empty() else "", (i + 1 if i < 4 else i), selected_where == "skill" and not sid.is_empty() and selected_key == sid, func():
			if not sid.is_empty(): _select("skill", sid)))
	left.add_child(bar)
	left.add_child(T.label("Ô 1–4: kỹ năng thường · Ô 5–6: tuyệt kỹ hoặc tuyệt phẩm (R, X)", 12, Color(T.C_MUTED, 0.85)))
	var gsid := _gear_skill_of(pl)
	if gsid != "":
		var gd: Dictionary = Data.skill(gsid)
		left.add_child(T.label("Kỹ năng trang bị (phím V)", T.FS_S, T.C_MUTED, true))
		left.add_child(W.glyph_row(str(gd.get("icon", "✦")), str(gd.get("name", gsid)), "Do trang bị cấp · MP %d" % int(gd.get("mp", 0)), "Trang bị", selected_where == "skill" and selected_key == gsid, func(): _select("skill", gsid), Color(0.45, 0.92, 0.7)))
	var supers: Array = pl.get("superUlts", [])
	if not supers.is_empty():
		left.add_child(T.hsep())
		left.add_child(T.label("Tuyệt phẩm", T.FS_S, T.C_MUTED, true))
		for su in supers:
			var ss := str(su)
			var sd: Dictionary = Data.skill(ss)
			if sd.is_empty(): continue
			left.add_child(W.glyph_row(str(sd.get("icon", "✦")), str(sd.get("name", ss)), "MP %d · Hồi %ss" % [int(sd.get("mp", 0)), str(sd.get("cd", 0))], "Sở hữu", selected_where == "skill" and selected_key == ss, func(): _select("skill", ss), Color("ff8a4a")))
	left.add_child(T.hsep())
	left.add_child(T.label("Đã học", T.FS_S, T.C_MUTED, true))
	if learned.is_empty(): left.add_child(_empty("Chưa học kỹ năng nào."))
	for sid2 in learned.keys():
		var s2 := str(sid2)
		var lv := int((learned[sid2] as Dictionary).get("lv", 1)) if typeof(learned[sid2]) == TYPE_DICTIONARY else int(learned[sid2])
		var d2: Dictionary = Data.skill(s2)
		left.add_child(W.glyph_row(str(d2.get("icon", "✦")), str(d2.get("name", s2)), "MP %d · Hồi %ss" % [int(d2.get("mp", 0)), str(d2.get("cd", 0))], "Lv %d" % lv, selected_where == "skill" and selected_key == s2, func(): _select("skill", s2)))
	var school := str(pl.get("school", ""))
	var allowed := [school, str(Data.school(school).get("base", ""))]
	var avail: Array = []
	for sid3 in Data.SKILLS.keys():
		if str((Data.SKILLS[sid3] as Dictionary).get("school", "")) in allowed and not learned.has(sid3) and not bool((Data.SKILLS[sid3] as Dictionary).get("superUlt", false)): avail.append(str(sid3))
	avail.sort_custom(func(a, b): return int(Data.skill(a).get("level", 0)) < int(Data.skill(b).get("level", 0)))
	if not avail.is_empty():
		left.add_child(T.hsep())
		left.add_child(T.label("Có thể học", T.FS_S, T.C_MUTED, true))
		for s4 in avail:
			var d4: Dictionary = Data.skill(s4)
			left.add_child(W.glyph_row(str(d4.get("icon", "✦")), str(d4.get("name", s4)), "MP %d · Hồi %ss" % [int(d4.get("mp", 0)), str(d4.get("cd", 0))], "Cấp %d" % int(d4.get("level", 1)), selected_where == "skill" and selected_key == s4, func(): _select("skill", s4), T.C_MUTED))
	var right: Control = W.empty_detail("Chạm một kỹ năng để xem chi tiết, nâng cấp hoặc gán vào ô.")
	if selected_where == "skill" and not Data.skill(selected_key).is_empty():
		right = _skill_detail(selected_key, learned, pl)
	vb.add_child(W.split(left, right))
	return W.fill(vb)

# ============================================================ QUEST
func _npc_places(npc_id: String) -> String:
	var out: Array = []
	for mid in Data.MAPS.keys():
		var npcs: Dictionary = (Data.MAPS[mid] as Dictionary).get("npcs", {})
		for k in npcs.keys():
			if str(npcs[k]) == npc_id:
				out.append(W.map_name(str(mid)))
				break
		if out.size() >= 2: break
	return " · ".join(out)

## Dòng mục tiêu có tiến độ. prog: tiến độ lưu trong player.quest.progress (hình dạng linh hoạt).
func _objective_rows(obj: Dictionary, prog: Dictionary, vb: VBoxContainer) -> void:
	for kind in obj.keys():
		var spec: Variant = obj[kind]
		match str(kind):
			"kill":
				var pk: Dictionary = prog.get("kill", {}) if typeof(prog.get("kill", {})) == TYPE_DICTIONARY else {}
				for mid in (spec as Dictionary).keys():
					vb.add_child(_obj_row("Hạ %s" % W.monster_name(str(mid)), int(pk.get(mid, 0)), int(spec[mid])))
			"collect":
				var pc: Dictionary = prog.get("collect", {}) if typeof(prog.get("collect", {})) == TYPE_DICTIONARY else {}
				for iid in (spec as Dictionary).keys():
					vb.add_child(_obj_row("Thu thập %s" % W.item_name(str(iid)), int(pc.get(iid, 0)), int(spec[iid])))
			"visit":
				var pv: Variant = prog.get("visit", [])
				var arr: Array = spec as Array
				var done_n := 0
				if typeof(pv) == TYPE_ARRAY:
					for x in arr:
						if x in (pv as Array): done_n += 1
				elif typeof(pv) == TYPE_DICTIONARY:
					for x in arr:
						if (pv as Dictionary).get(x, false): done_n += 1
				vb.add_child(_obj_row("Đến %d địa điểm" % arr.size(), done_n, arr.size()))
			"level": vb.add_child(_obj_row("Đạt cấp %d" % int(spec), int(Game.player.get("level", 1)), int(spec)))
			"school": vb.add_child(_obj_row("Chọn class", 1 if not str(Game.player.get("school", "")).is_empty() else 0, 1))

func _obj_row(text: String, have: int, need: int) -> Control:
	var done := have >= need
	var vb := _vb(2)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	var mark := T.label("✓" if done else "○", T.FS_M, T.C_GREEN if done else T.C_MUTED, true)
	mark.autowrap_mode = TextServer.AUTOWRAP_OFF
	h.add_child(mark)
	var t := T.label(text, T.FS_S, T.C_MUTED if done else T.C_TEXT)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(t)
	var n := T.label("%d/%d" % [mini(have, need), need], T.FS_S, T.C_GREEN if done else T.C_GOLD, true)
	n.autowrap_mode = TextServer.AUTOWRAP_OFF
	h.add_child(n)
	vb.add_child(h)
	if need > 1:
		var pb := ProgressBar.new()
		pb.min_value = 0; pb.max_value = need; pb.value = mini(have, need)
		pb.show_percentage = false
		pb.custom_minimum_size = Vector2(0, 8)
		pb.add_theme_stylebox_override("background", T.UISkin.bar_frame())
		pb.add_theme_stylebox_override("fill", T.UISkin.bar_fill(T.C_GREEN if done else T.C_GOLD))
		vb.add_child(pb)
	return vb

func _reward_chips(rw: Dictionary) -> Control:
	var chips: Array = []
	if int(rw.get("exp", 0)) > 0: chips.append(["%s EXP" % W.fmt_num(int(rw["exp"])), T.C_BLUE])
	if int(rw.get("gold", 0)) > 0: chips.append(["%s xu" % W.fmt_num(int(rw["gold"])), T.C_GOLD])
	for it in rw.get("items", []):
		if typeof(it) == TYPE_ARRAY and (it as Array).size() >= 2: chips.append(["%s ×%d" % [W.item_name(str(it[0])), int(it[1])], T.C_PURPLE])
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
		vb.add_child(_empty("Cốt truyện đã hoàn tất.\nHãy làm phụ tuyến và nhiệm vụ ngày.", "quest"))
	else:
		var state := str(qd.get("state", "none"))
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
			inner2.add_child(T.label(str(sq.get("name", _prettify(str(sid)))), T.FS_M, T.C_TEXT, true))
			if sq.has("npc"): inner2.add_child(T.label("Gặp %s" % W.npc_name(str(sq["npc"])), T.FS_S, T.C_MUTED))
			var sp: Dictionary = active[sid] if typeof(active[sid]) == TYPE_DICTIONARY else {}
			_objective_rows(sq.get("obj", {}), sp, inner2)
			vb.add_child(W.card_row(inner2))
	var daily: Dictionary = pl.get("dailyByMap", {}).get(str(pl.get("map", "")), {})
	if not daily.is_empty():
		vb.add_child(W.section_label("Nhiệm vụ ngày"))
		for d in daily.get("list", []):
			if typeof(d) != TYPE_DICTIONARY: continue
			var dd := d as Dictionary
			var done := bool(dd.get("claimed", false))
			vb.add_child(W.card_row(T.label("%s %s" % ["✓" if done else "•", str(dd.get("name", ""))], T.FS_M, T.C_MUTED if done else T.C_TEXT)))
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
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(row)
	# Trái: sơ đồ có thể kéo
	var mapbox := PanelContainer.new()
	mapbox.add_theme_stylebox_override("panel", T.UISkin.inset(3))
	mapbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mapbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_child(mapbox)
	var view: Control = WorldMapView.new()
	view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	mapbox.add_child(view)
	# Phải: thông tin khu + chú giải
	var right := W.detail_box()
	right.custom_minimum_size = Vector2(214, 0)
	var rb := W.box_body(right)
	var info := _vb(4)
	rb.add_child(info)
	var here_btn := W.action_button("📍 Về vị trí của tôi", func(): view.center_on(str(p().get("map", ""))))
	rb.add_child(here_btn)
	rb.add_child(T.label("Kéo để di chuyển · chạm một điểm để xem. Muốn đi: tới cổng trong game.", 12, Color(T.C_MUTED, 0.9)))
	var rs := ScrollContainer.new()
	rs.custom_minimum_size = Vector2(214, 0)
	rs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rs.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rs.add_child(right)
	row.add_child(rs)
	var cur := WorldMapView.sel if not WorldMapView.sel.is_empty() else str(p().get("map", ""))
	_map_info(info, cur)
	view.selected.connect(func(id): _map_info(info, id))
	return W.fill(vb)

func _dict_values(d: Dictionary) -> Array:
	var a: Array = []
	for k in d.keys(): a.append(str(d[k]))
	return a

# ============================================================ SHOP
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
	vb.add_child(W.segmented([["buy", "Mua"], ["sell", "Bán"]], shop_tab, func(t): shop_tab = t; _deselect()))
	var left: Control
	var right: Control = W.empty_detail()
	if shop_tab == "buy":
		var items: Array = nd.get("shop", [])
		if items.is_empty(): items = nd.get("ngocShop", [])
		var lv := _vb(6)
		for iid in items:
			var sid := str(iid)
			var d0: Dictionary = Data.item(sid)
			var price := int(d0.get("price", 0))
			var sub_parts: Array = W.item_stat_lines(d0)
			var sub := ", ".join(sub_parts.slice(0, 2)) if not sub_parts.is_empty() else str(d0.get("desc", ""))
			lv.add_child(W.shop_row(sid, sub, "%s xu" % W.fmt_num(price), selected_where == "shop" and selected_key == sid, func(): _select("shop", sid)))
		left = lv if not items.is_empty() else _empty("Cửa hàng chưa mở. Hãy lại gần NPC bán hàng.")
		if selected_where == "shop":
			var box := W.item_detail(selected_key)
			var body := W.box_body(box)
			var qty_row := HBoxContainer.new()
			qty_row.add_theme_constant_override("separation", 8)
			var minus := W.action_button("−", func(): shop_qty = maxi(1, shop_qty - 1); refresh())
			minus.custom_minimum_size = Vector2(48, 44)
			qty_row.add_child(minus)
			var ql := T.label(str(shop_qty), T.FS_L, T.C_GOLD, true)
			ql.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			ql.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			qty_row.add_child(ql)
			var plus := W.action_button("+", func(): shop_qty = mini(99, shop_qty + 1); refresh())
			plus.custom_minimum_size = Vector2(48, 44)
			qty_row.add_child(plus)
			body.add_child(qty_row)
			var key := npc + ":" + selected_key
			var total := int(Data.item(selected_key).get("price", 0)) * shop_qty
			var buy := W.action_button(("Chạm lần nữa: mua %d (%s xu)" if confirm_buy == key else "Mua %d · %s xu") % [shop_qty, W.fmt_num(total)], func():
				if confirm_buy == key:
					act("buy", {"npc": npc, "item": selected_key, "qty": shop_qty})
					confirm_buy = ""; refresh()
				else:
					confirm_buy = key; refresh())
			if confirm_buy == key: buy.add_theme_color_override("font_color", T.C_GOLD)
			body.add_child(buy)
			if not nd.get("ngocShop", []).is_empty():
				body.add_child(W.action_button("Mua bằng Linh Ngọc", func(): act("buy_ngoc", {"npc": npc, "item": selected_key, "qty": shop_qty})))
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
				var box2 := W.item_detail(str(e3.get("id", "")), int(e3.get("plus", 0)))
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
	# Ứng viên: đồ trong túi có ô trang bị + đồ đang mặc
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
	for s in eq.keys():
		if typeof(eq[s]) != TYPE_DICTIONARY: continue
		var key2 := "s" + str(s)
		var iid2 := str((eq[s] as Dictionary).get("id", ""))
		cands += 1
		g.add_child(W.item_cell(iid2, 1, selected_where == "smith" and selected_key == key2, func(): _select("smith", key2), "Mặc"))
	var left: Control = g if cands > 0 else _empty("Không có trang bị.")
	var right: Control = W.empty_detail("Chọn trang bị để chế tác. Phải đứng cạnh Thợ rèn.")
	if selected_where == "smith":
		var params: Dictionary = {}
		var iid3 := ""
		var plus := 0
		if selected_key.begins_with("u"):
			var e2 := _bag_entry(selected_key.substr(1))
			iid3 = str(e2.get("id", "")); plus = int(e2.get("plus", 0))
			params = {"uid": int(e2.get("uid", 0))}
		else:
			var slot := selected_key.substr(1)
			var it: Dictionary = eq.get(slot, {}) if typeof(eq.get(slot, null)) == TYPE_DICTIONARY else {}
			iid3 = str(it.get("id", "")); plus = int(it.get("plus", 0))
			params = {"slot": slot}
		if not iid3.is_empty():
			var box := W.item_detail(iid3, plus)
			var names := {"upgrade": "Cường hóa lên +%d" % (plus + 1), "reforge": "Tẩy luyện", "salvage": "Phân rã lấy đá", "seal": "Khắc ấn"}
			var tab := smith_tab
			W.box_body(box).add_child(W.action_button(str(names.get(tab, tab)), func(): act(tab, params)))
			right = box
	vb.add_child(W.split(left, right))
	return W.fill(vb)

# ============================================================ STORAGE
func build_storage() -> Control:
	var vb := _vb()
	var pl := p()
	var here := str(pl.get("map", "lang"))
	var store: Array = pl.get("storageByMap", {}).get(here, [])
	vb.add_child(W.chip_row([["Kho %s" % W.map_name(here), T.C_GOLD], ["%d/%d" % [store.size(), Data.const_int("STORAGE_SIZE", 30)], T.C_MUTED]]))
	vb.add_child(W.segmented([["store", "Gửi vào kho"], ["take", "Lấy ra"]], storage_tab, func(t): storage_tab = t; _deselect()))
	var src: Array = pl.get("bag", []) if storage_tab == "store" else store
	var g := _grid(6)
	for e in src:
		if typeof(e) != TYPE_DICTIONARY: continue
		var uid := str(e.get("uid", 0))
		g.add_child(W.item_cell(str(e.get("id", "")), int(e.get("n", 1)), selected_where == "store" and selected_key == uid, func(): _select("store", uid)))
	var left: Control = g if not src.is_empty() else _empty("Không có đồ.")
	var right: Control = W.empty_detail()
	if selected_where == "store":
		var sel: Dictionary = {}
		for e2 in src:
			if typeof(e2) == TYPE_DICTIONARY and str(e2.get("uid", 0)) == selected_key: sel = e2; break
		if not sel.is_empty():
			var box := W.item_detail(str(sel.get("id", "")), int(sel.get("plus", 0)))
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
	vb.add_child(T.label("Chọn Tân Đô đã từng tới. Mỗi lần dịch chuyển tốn phí cố định.", T.FS_S, T.C_MUTED))
	var any := false
	for mid in pl.get("villages", []):
		var sid := str(mid)
		if sid == str(pl.get("map", "")): continue
		if not (Data.MAPS.get(sid, {}) as Dictionary).get("village", false): continue
		any = true
		var h := W.list_row(null, W.map_name(sid), "Tân Đô")
		var go := W.action_button("Đi", func(): act("teleport", {"to": sid, "hp": Game.hp, "mp": Game.mp}))
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
		var go := W.action_button("Đi" if ok else "Khoá", func(): act("change_map", {"portal": key, "hp": Game.hp, "mp": Game.mp}), not ok)
		go.custom_minimum_size = Vector2(90, 44)
		h.add_child(go)
		vb.add_child(W.card_row(h))
		shown += 1
	if shown == 0: vb.add_child(_empty("Không có cổng ở bản đồ này.", "portal"))
	return vb

# ============================================================ DAILY
func build_daily() -> Control:
	var vb := _vb()
	var pl := p()
	var here := str(pl.get("map", "lang"))
	var d: Dictionary = pl.get("dailyByMap", {}).get(here, {})
	vb.add_child(W.section_label("Bảng nhiệm vụ · %s" % W.map_name(here)))
	var list: Array = d.get("list", [])
	if list.is_empty(): vb.add_child(_empty("Chưa có nhiệm vụ ngày ở đây.\nMỗi làng có bảng nhiệm vụ riêng.", "quest"))
	for i in range(list.size()):
		var item: Dictionary = list[i] if typeof(list[i]) == TYPE_DICTIONARY else {}
		var done := bool(item.get("done", false))
		var claimed := bool(item.get("claimed", false))
		var h := W.list_row(null, str(item.get("name", "Nhiệm vụ %d" % (i + 1))), "Đã nhận thưởng" if claimed else ("Hoàn thành" if done else "Đang làm"), T.C_MUTED if claimed else T.C_TEXT)
		var idx := i
		var b := W.action_button("Nhận", func(): act("daily_claim", {"i": idx}), claimed or not done)
		b.custom_minimum_size = Vector2(90, 44)
		h.add_child(b)
		vb.add_child(W.card_row(h))
	var bonus: Dictionary = d.get("bonus", {})
	if not bonus.is_empty():
		vb.add_child(W.action_button("Nhận thưởng thêm", func(): act("daily_bonus", {}), bool(bonus.get("claimed", false))))
	var w: Dictionary = pl.get("weeklyByMap", {}).get(here, {})
	if not w.is_empty():
		vb.add_child(T.hsep())
		vb.add_child(W.section_label("Nhiệm vụ tuần"))
		vb.add_child(W.chip_row([["Quái  %d" % int(w.get("kills", 0)), T.C_BLUE], ["Boss  %d" % int(w.get("bosses", 0)), T.C_RED]]))
		var r := HBoxContainer.new()
		r.add_theme_constant_override("separation", 8)
		var b1 := W.action_button("Thưởng quái", func(): act("weekly_claim", {"kind": "kills"}))
		b1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var b2 := W.action_button("Thưởng boss", func(): act("weekly_claim", {"kind": "bosses"}))
		b2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		r.add_child(b1); r.add_child(b2)
		vb.add_child(r)
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
		Net.action("redeem", {"code": code_draft})
		code_draft = ""; refresh())
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
		inner2.add_child(T.label("%s %s" % [str(s.get("icon", "◆")), str(s.get("name", sid))], T.FS_M, T.C_GOLD, true))
		inner2.add_child(T.label(str(s.get("desc", "")), T.FS_S, T.C_MUTED))
		var cid := str(sid)
		inner2.add_child(W.action_button("Chọn", func(): host.open_panel("school", {"confirm": cid})))
		var card := W.card_row(inner2)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		g.add_child(card)
	vb.add_child(g)
	return vb

# ============================================================ MOUNT (Linh thú Triệu Hồi Sư)
func build_mount() -> Control:
	var vb := _vb()
	var summons: Dictionary = p().get("summons", {})
	if str(p().get("school", "")) != "trieu_hoi_su":
		vb.add_child(_empty("Chỉ Triệu Hồi Sư mới có linh thú.\nĐổi class để mở tính năng này.", "pet"))
		return vb
	vb.add_child(W.action_button("Bật / tắt linh thú", func(): act("summon_toggle", {})))
	var choice := str(summons.get("choice", ""))
	var g := _grid(2)
	for sid in Data.SKILLS.keys():
		var s: Dictionary = Data.SKILLS[sid] if typeof(Data.SKILLS[sid]) == TYPE_DICTIONARY else {}
		if str(s.get("school", "")) != "trieu_hoi_su" or str(s.get("summon", "")).is_empty(): continue
		var mid := str(s["summon"])
		var b := W.action_button(("Đang dùng · " if mid == choice else "Chọn · ") + W.monster_name(mid), func(): act("summon_pick", {"id": mid}))
		if mid == choice: b.add_theme_color_override("font_color", T.C_GOLD)
		g.add_child(b)
	if g.get_child_count() == 0: vb.add_child(_empty("Chỉ Triệu Hồi Sư mới có linh thú."))
	else: vb.add_child(g)
	var states: Dictionary = summons.get("states", {})
	for mid2 in states.keys():
		var st: Dictionary = states[mid2] if typeof(states[mid2]) == TYPE_DICTIONARY else {}
		vb.add_child(W.bar(W.monster_name(str(mid2)), int(st.get("hp", 0)), int(st.get("maxHp", 100)), T.C_GREEN))
	return vb

# ============================================================ COMPANION (thú đồng hành)
func build_companion() -> Control:
	var vb := _vb()
	var pl := p()
	var mounts: Dictionary = pl.get("mounts", {}) if typeof(pl.get("mounts", {})) == TYPE_DICTIONARY else {}
	var owned: Array = mounts.get("owned", [])
	var summoned: Array = mounts.get("summoned", [])
	var pets: Dictionary = pl.get("pets", {}) if typeof(pl.get("pets", {})) == TYPE_DICTIONARY else {}
	vb.add_child(W.chip_row([["Sở hữu  %d" % owned.size(), T.C_GOLD], ["Đang triệu hồi  %d" % summoned.size(), T.C_GREEN]]))
	if owned.is_empty():
		vb.add_child(_empty("Bạn chưa có thú đồng hành.\nNhận thú qua mã quà tặng hoặc sự kiện.", "pet"))
		return vb
	vb.add_child(T.label("Thú đồng hành đi theo, đánh cùng bạn và chia sẻ một phần sát thương nhận vào.", T.FS_S, T.C_MUTED))
	for mid in owned:
		var sid := str(mid)
		var active := sid in summoned
		var st: Dictionary = pets.get(sid, {}) if typeof(pets.get(sid, {})) == TYPE_DICTIONARY else {}
		var inner := _vb(6)
		var head := HBoxContainer.new()
		head.add_theme_constant_override("separation", 10)
		var frame := PanelContainer.new()
		frame.add_theme_stylebox_override("panel", T.UISkin.slot(4 if active else 1, active))
		var pic := T.icon_rect("pet", 30.0, T.C_GOLD if active else T.C_MUTED)
		pic.custom_minimum_size = Vector2(40, 40)
		frame.add_child(pic)
		head.add_child(frame)
		var tc := _vb(1)
		tc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tc.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		tc.add_child(T.label(W.monster_name(sid), T.FS_M, T.C_GOLD if active else T.C_TEXT, true))
		var sub := "Đang đồng hành" if active else "Đang nghỉ"
		if st.has("lv"): sub = "Cấp %d · %s" % [int(st.get("lv", 1)), sub]
		tc.add_child(T.label(sub, T.FS_S, T.C_GREEN if active else T.C_MUTED))
		head.add_child(tc)
		var tb: Button
		if active: tb = W.action_button("Thu hồi", func(): act("mount_set", {"id": sid}))
		else:
			tb = T.button_primary("Triệu hồi", Vector2(104, 42))
			tb.pressed.connect(func(): act("mount_set", {"id": sid}))
		tb.custom_minimum_size = Vector2(104, 42)
		head.add_child(tb)
		inner.add_child(head)
		if not st.is_empty():
			inner.add_child(W.bar("Sinh lực", int(st.get("hp", 0)), maxi(1, int(st.get("maxHp", 100))), T.C_GREEN))
		var card := W.card_row(inner)
		if active: card.add_theme_stylebox_override("panel", T.UISkin.tab(true))
		vb.add_child(card)
	return vb

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
	return W.card_row(h)

func build_config() -> Control:
	var vb := _vb()
	# Tài khoản
	var pl := p()
	var acc := _vb(2)
	acc.add_child(T.label(str(pl.get("name", "?")), T.FS_L, T.C_GOLD, true))
	acc.add_child(T.label("%s · Cấp %d" % [W.school_name(str(pl.get("school", ""))), int(pl.get("level", 1))], T.FS_S, T.C_MUTED))
	acc.add_child(T.label("Máy chủ: " + Settings.server_url, 12, Color(T.C_MUTED, 0.85)))
	vb.add_child(W.card_row(acc))
	vb.add_child(W.section_label("Hiển thị"))
	vb.add_child(_toggle("Đồ họa thấp", "Bớt hạt, tắt lớp nền giữa và thời tiết — nhẹ máy hơn", Settings.quality_low, func(v): Settings.set_quality_low(v)))
	vb.add_child(_toggle("Giới hạn 30 FPS", "Tiết kiệm pin, máy ít nóng", Settings.fps_cap == 30, func(v): Settings.set_fps_cap(30 if v else 60)))
	vb.add_child(_toggle("Hiện số sát thương", "Chữ nổi trên đầu quái khi đánh", Settings.show_damage, func(v): Settings.set_show_damage(v)))
	vb.add_child(W.section_label("Âm thanh & rung"))
	var vol_box := _vb(2)
	var vol_head := HBoxContainer.new()
	var vol_t := T.label("Âm lượng", T.FS_M, T.C_TEXT, true)
	vol_t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vol_head.add_child(vol_t)
	var vol_v := T.label("%d%%" % int(Settings.volume * 100.0), T.FS_S, T.C_GOLD, true)
	vol_head.add_child(vol_v)
	vol_box.add_child(vol_head)
	var vol := HSlider.new()
	vol.min_value = 0.0; vol.max_value = 1.0; vol.step = 0.05
	vol.value = Settings.volume
	vol.custom_minimum_size = Vector2(0, 28)
	vol.value_changed.connect(func(v):
		Settings.set_volume(v)
		vol_v.text = "%d%%" % int(v * 100.0))
	vol_box.add_child(vol)
	vb.add_child(W.card_row(vol_box))
	vb.add_child(_toggle("Rung khi bị đánh", "Chỉ có tác dụng trên điện thoại", Settings.haptics, func(v): Settings.set_haptics(v)))
	vb.add_child(W.section_label("Khác"))
	vb.add_child(W.action_button("Xem lại gợi ý hướng dẫn", func():
		Settings.reset_hints()
		host.toast("Các gợi ý sẽ hiện lại", "success")))
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
		var have := sid in owned
		var on := sid in active
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

# ============================================================ DISPATCH
func build(tab: String, extra: Dictionary = {}) -> Control:
	ctx_extra = extra.duplicate()
	if tab.is_empty(): return T.label("Chọn một mục.", T.FS_M, T.C_MUTED)
	var fn_name := "build_" + tab
	if not has_method(fn_name): return T.label("Chưa có panel: " + tab, T.FS_M, T.C_RED)
	var node: Variant = call(fn_name)
	return node if node is Control else T.label("Lỗi panel: " + tab, T.FS_M, T.C_RED)
