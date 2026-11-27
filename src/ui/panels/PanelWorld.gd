extends "res://src/ui/panels/PanelBase.gd"
## Bản đồ, dịch chuyển, cổng (build_map, build_teleport, build_gate). Dùng chung trạng thái/hàm trợ giúp qua PanelBase; hub = GamePanels.gd.

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
