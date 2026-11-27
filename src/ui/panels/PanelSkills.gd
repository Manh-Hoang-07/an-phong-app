extends "res://src/ui/panels/PanelBase.gd"
## Kỹ năng + trường phái (build_skills, build_school). Dùng chung trạng thái/hàm trợ giúp qua PanelBase; hub = GamePanels.gd.

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
		if Formulas.is_broken(it): continue
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
