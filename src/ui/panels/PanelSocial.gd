extends "res://src/ui/panels/PanelBase.gd"
## Đội, khu, chợ người chơi, giao dịch (build_social, build_trade). Dùng chung trạng thái/hàm trợ giúp qua PanelBase; hub = GamePanels.gd.

var social_tab := "near"

var _social_data_requested := false   # chợ/khu: gửi request đúng 1 lần mỗi lần mở từ NPC

var market_tab := "buy"

var market_sel_uid := ""


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
		var sc := TouchScroll.new()
		sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
		sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		var inner := _vb(8)
		_social_khu(inner)
		sc.add_child(inner)
		vb.add_child(sc)
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
