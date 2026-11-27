extends "res://src/ui/panels/PanelBase.gd"
## Linh thú, thú đồng hành, bóng (build_mount, build_companion, build_shadows). Dùng chung trạng thái/hàm trợ giúp qua PanelBase; hub = GamePanels.gd.

## Trang bị thú: 4 ô (yên, dây cương, giáp, vòng cổ). Chạm một ô để mở danh sách món phù hợp trong túi và gán vào,
## hoặc "Tháo" món đang mặc. Luật (cấp yêu cầu, túi đầy...) do server kiểm: action pet_equip / pet_unequip.
const PET_SLOTS := [["yen", "Yên"], ["cuong", "Cương"], ["giap", "Giáp"], ["vong", "Vòng"]]

# Trạng thái riêng của panel này
var pet_sel := ""

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
