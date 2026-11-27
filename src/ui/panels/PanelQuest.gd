extends "res://src/ui/panels/PanelBase.gd"
## Nhiệm vụ, nhiệm vụ ngày/tuần, hội thoại NPC (build_quest, build_daily, build_npc). Dùng chung trạng thái/hàm trợ giúp qua PanelBase; hub = GamePanels.gd.

const WEEKLY_KILLS := 200

const WEEKLY_BOSSES := 5

const WEEKLY_BOOKS := 1

const DAILY_BONUS_STONES := 6

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
		var col: VBoxContainer = h.get_child(h.get_child_count() - 1) as VBoxContainer
		col.add_theme_constant_override("separation", 2)
		var rw := T.label(_reward_text(int(r["exp"]) * mul, int(r["gold"]) * mul, int(r["stones"]) * mul), T.FS_S, T.C_GOLD)
		rw.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		col.add_child(rw)
		var idx := i
		if claimed:
			col.add_child(T.label("✓ Đã nhận", T.FS_S, T.C_GREEN))
		else:
			var b := W.action_button("Nhận thưởng", func(): act("daily_claim", {"i": idx}), not done)
			b.custom_minimum_size = Vector2(110, 44)
			col.add_child(b)
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
			var rcol: VBoxContainer = rh.get_child(rh.get_child_count() - 1) as VBoxContainer
			var rl := T.label("Thưởng: " + str(row["reward"]), T.FS_S, T.C_GOLD)
			rl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			rcol.add_child(rl)
			if bool(row["claimed"]):
				rcol.add_child(T.label("✓ Đã nhận", T.FS_S, T.C_GREEN))
			else:
				var kind := str(row["kind"])
				var rb := W.action_button("Nhận", func(): act("weekly_claim", {"kind": kind}), not done)
				rb.custom_minimum_size = Vector2(90, 44)
				rcol.add_child(rb)
			vb.add_child(W.card_row(rh))
	return vb

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
