extends "res://src/ui/panels/PanelBase.gd"
## Túi đồ (build_bag). Dùng chung trạng thái/hàm trợ giúp qua PanelBase; hub = GamePanels.gd.

# Trạng thái riêng của panel này
var bag_filter := "all"

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
		var bag_cell := W.item_cell(str(e.get("id", "")), int(e.get("n", e.get("qty", 1))), selected_where == "bag" and selected_key == uid, func(): _select("bag", uid))
		if Formulas.is_broken(e): bag_cell.modulate = Color(1.0, 0.55, 0.55)
		g.add_child(bag_cell)
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

func _bag_detail(e: Dictionary) -> Control:
	var iid := str(e.get("id", ""))
	var d: Dictionary = Data.item(iid)
	var box := W.item_detail(iid, int(e.get("plus", 0)), true, e)
	var body := W.box_body(box)
	var uidn := int(e.get("uid", 0))
	var qty := int(e.get("n", e.get("qty", 1)))
	if qty > 1: body.add_child(T.label("Số lượng: %d" % qty, T.FS_S, T.C_TEXT))
	if not str(d.get("slot", "")).is_empty():
		body.add_child(W.action_button("Trang bị" if not Formulas.is_broken(e) else "Hỏng: sửa trước khi mặc", func(): act("equip", {"uid": uidn}); _deselect(), Formulas.is_broken(e)))
		_nhiem_block(body, e, {"uid": uidn})
	var dkind := str(d.get("kind", ""))
	if dkind in ["book", "potential_book", "skill_book", "ult_book", "slot_book", "erase_book", "transform_book"]:
		body.add_child(W.action_button("Đọc sách", func(): act("use", {"item": iid})))
	elif dkind == "boost":
		body.add_child(W.action_button("Sử dụng", func(): act("use", {"item": iid})))
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
