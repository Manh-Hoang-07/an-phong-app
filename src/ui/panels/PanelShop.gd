extends "res://src/ui/panels/PanelBase.gd"
## Dịch vụ NPC: cửa hàng, rèn, kho (build_shop, build_smith, build_storage). Dùng chung trạng thái/hàm trợ giúp qua PanelBase; hub = GamePanels.gd.

const NGOC_GROUP_NAMES := {"ky_nguyen": "Kỳ Nguyên", "util": "Tiện ích", "book": "Sách", "ult": "Tuyệt kỹ", "superult": "Tuyệt Phẩm"}

const NGOC_GROUP_ORDER := ["ky_nguyen", "util", "book", "ult", "superult"]

const SMITH_TABS := [["upgrade", "Cường hóa"], ["reforge", "Tẩy luyện"], ["repair", "Sửa chữa"], ["salvage", "Phân rã"], ["seal", "Khắc ấn"]]

const SMITH_DESC := {"upgrade": "Nâng cấp +1 cho trang bị. Càng cao càng dễ thất bại.", "reforge": "Đổi lại chỉ số ngẫu nhiên của trang bị.",
	"salvage": "Phân rã trang bị thành đá cường hóa.", "seal": "Khắc ấn tăng sức mạnh đặc biệt.",
	"repair": "Đưa độ bền về 100%. Tốn xu + đá cường hóa theo phần còn thiếu."}

# Trạng thái riêng của panel này
var shop_tab := "buy"

var shop_qty := 1

var smith_tab := "upgrade"

var storage_tab := "store"

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

func build_smith() -> Control:
	var vb := _vb()
	var pl := p()
	vb.add_child(_gold_row(pl, false))
	vb.add_child(W.segmented(SMITH_TABS, smith_tab, func(t): smith_tab = t; _deselect()))
	vb.add_child(T.label(str(SMITH_DESC.get(smith_tab, "")), T.FS_S, T.C_MUTED))
	if smith_tab == "repair":
		var need := 0
		for sl in pl.get("equip", {}).keys():
			var eqi: Variant = pl["equip"][sl]
			if typeof(eqi) == TYPE_DICTIONARY and not Formulas.repair_cost(eqi).is_empty(): need += 1
		vb.add_child(W.action_button("Sửa tất cả đang mặc (%d)" % need, func(): act("repair_all", {}), need == 0))
	# Ứng viên: tab Phân rã chỉ nhận đồ trong túi (server phân rã theo uid trong túi)
	var g := _grid(6)
	var cands := 0
	for e in pl.get("bag", []):
		if typeof(e) != TYPE_DICTIONARY: continue
		var iid := str(e.get("id", ""))
		if str(Data.item(iid).get("slot", "")).is_empty(): continue
		var key := "u" + str(e.get("uid", 0))
		cands += 1
		var sc_b := W.item_cell(iid, 1, selected_where == "smith" and selected_key == key, func(): _select("smith", key), ("+%d" % int(e.get("plus", 0))) if int(e.get("plus", 0)) > 0 else "")
		if Formulas.is_broken(e): sc_b.modulate = Color(1.0, 0.55, 0.55)
		g.add_child(sc_b)
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
		"repair": "Sửa chữa đưa độ bền về 100%. Món đã hỏng (0%) vẫn sửa được, chỉ tốn nhất.",
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
			elif tab == "repair":
				var rc := Formulas.repair_cost(sm_entry)
				var rpct := Formulas.dur_pct(sm_entry)
				if rpct < 0:
					body.add_child(T.label("Món này có độ bền vô hạn, không bao giờ hao mòn.", T.FS_S, T.C_MUTED))
				elif rc.is_empty():
					body.add_child(T.label("Món này còn nguyên độ bền, không cần sửa.", T.FS_S, T.C_MUTED))
				else:
					body.add_child(T.label("Sửa từ %d%% lên 100%%%s." % [rpct, " (đang hỏng)" if rpct <= 0 else ""], T.FS_S, T.C_TEXT))
					body.add_child(T.label("Chi phí: %s xu, %d đá cường hóa" % [W.fmt_num(int(rc["gold"])), int(rc["stones"])], T.FS_S, T.C_MUTED))
					can = gold >= int(rc["gold"]) and stones >= int(rc["stones"])
					label = "Sửa chữa"
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
