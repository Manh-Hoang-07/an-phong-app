extends Control
## Hội thoại NPC kiểu game: chân dung bên trái, bảng tên + lời thoại gõ từng chữ ở giữa, danh sách lựa chọn bên phải.
## Mọi lựa chọn gọi Net.action / mở panel dịch vụ; luật chơi ở server.

signal closed()
signal open_panel_requested(tab: String, extra: Dictionary)
signal confirm_requested(title: String, body: String, ok_text: String, cb: Callable)

const T := preload("res://src/ui/UITheme.gd")
const MapEntities := preload("res://src/world/MapEntities.gd")

const ROLE_NAMES := {"quest": "Nhiệm vụ", "shop": "Cửa hàng", "smith": "Thợ rèn", "storage": "Thủ kho", "teleport": "Dịch chuyển",
	"daily": "Bảng nhiệm vụ", "market": "Chợ", "zone": "Dẫn khu", "mystic": "Bí ẩn", "hidden": "Bí ẩn", "lao_su": "Đánh giá hạng"}
const ROLE_ICONS := {"shop": "shop", "smith": "anvil", "storage": "storage", "teleport": "portal", "daily": "quest", "market": "social", "quest": "quest"}

var npc_id := ""
var _name_label: Label
var _role_chip: Label
var _text: Label
var _opts: VBoxContainer
var _portrait_box: Control
var _sys: Label
var _type_tween: Tween
var _full_text := ""

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	var scrim := ColorRect.new()
	scrim.color = Color(0, 0, 0.02, 0.38)
	scrim.set_anchors_preset(Control.PRESET_FULL_RECT)
	scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(scrim)
	gui_input.connect(func(e):
		if e is InputEventMouseButton and e.pressed: _skip_or_close())

	var inset := T.safe_insets(get_viewport(), 14.0)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", T.UISkin.panel(10))
	panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	panel.offset_left = inset.x; panel.offset_right = -inset.z
	panel.offset_bottom = -inset.w; panel.offset_top = -inset.w - 190
	panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	panel.add_child(row)

	# ---- Chân dung ----
	var pf := PanelContainer.new()
	pf.add_theme_stylebox_override("panel", T.UISkin.inset(4))
	pf.custom_minimum_size = Vector2(128, 0)
	row.add_child(pf)
	_portrait_box = Control.new()
	_portrait_box.custom_minimum_size = Vector2(120, 150)
	_portrait_box.clip_contents = true
	pf.add_child(_portrait_box)

	# ---- Giữa: tên + lời thoại ----
	var mid := VBoxContainer.new()
	mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mid.add_theme_constant_override("separation", 6)
	row.add_child(mid)
	var plate := PanelContainer.new()
	plate.add_theme_stylebox_override("panel", T.UISkin.ribbon())
	plate.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	mid.add_child(plate)
	var ph := HBoxContainer.new()
	ph.add_theme_constant_override("separation", 10)
	plate.add_child(ph)
	_name_label = T.label("", T.FS_M, T.C_GOLD, true)
	_name_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	ph.add_child(_name_label)
	_role_chip = T.label("", T.FS_S, T.C_MUTED)
	_role_chip.autowrap_mode = TextServer.AUTOWRAP_OFF
	ph.add_child(_role_chip)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	mid.add_child(scroll)
	var tv := VBoxContainer.new()
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tv.add_theme_constant_override("separation", 6)
	scroll.add_child(tv)
	_text = T.label("", T.FS_M, T.C_TEXT)
	_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tv.add_child(_text)
	_sys = T.label("", T.FS_S, T.C_GREEN)
	tv.add_child(_sys)

	# ---- Phải: lựa chọn ----
	var right := VBoxContainer.new()
	right.custom_minimum_size = Vector2(214, 0)
	right.add_theme_constant_override("separation", 6)
	row.add_child(right)
	var top := HBoxContainer.new()
	right.add_child(top)
	var hint := T.label("Lựa chọn", T.FS_S, T.C_MUTED, true)
	hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(hint)
	var close := T.icon_button("close", 30)
	close.pressed.connect(close_dialog)
	top.add_child(close)
	var os := ScrollContainer.new()
	os.size_flags_vertical = Control.SIZE_EXPAND_FILL
	os.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	right.add_child(os)
	_opts = VBoxContainer.new()
	_opts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_opts.add_theme_constant_override("separation", 6)
	os.add_child(_opts)
	Game.event_received.connect(_on_event)

func open_for(id: String) -> void:
	npc_id = id
	var nd: Dictionary = Data.npc(id)
	_name_label.text = str(nd.get("name", "NPC"))
	var role := str(nd.get("role", ""))
	_role_chip.text = str(ROLE_NAMES.get(role, ""))
	_sys.text = ""
	_build_portrait(id, nd)
	_set_text(str(nd.get("greet", nd.get("say", "..."))))
	_rebuild_options()
	visible = true
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.15)

func close_dialog() -> void:
	if not visible: return
	visible = false
	if _type_tween: _type_tween.kill()
	closed.emit()

func refresh() -> void:
	if visible: _rebuild_options()

func _skip_or_close() -> void:
	if _type_tween and _type_tween.is_running():
		_type_tween.kill()
		_text.visible_ratio = 1.0
	else:
		close_dialog()

func _set_text(t: String) -> void:
	_full_text = t
	_text.text = t
	_text.visible_ratio = 0.0
	if _type_tween: _type_tween.kill()
	_type_tween = create_tween()
	var dur := clampf(float(t.length()) * 0.018, 0.2, 1.6)
	_type_tween.tween_property(_text, "visible_ratio", 1.0, dur)

func _on_event(ev: Dictionary) -> void:
	if not visible: return
	if str(ev.get("t", "")) == "msg":
		_sys.text = str(ev.get("text", ""))
		var c := str(ev.get("color", ""))
		_sys.add_theme_color_override("font_color", Color.from_string(c, T.C_GREEN) if not c.is_empty() else T.C_GREEN)

func _build_portrait(id: String, nd: Dictionary) -> void:
	for c in _portrait_box.get_children(): c.queue_free()
	var holder := Node2D.new()
	holder.position = Vector2(60, 142)
	holder.scale = Vector2(2.1, 2.1)
	_portrait_box.add_child(holder)
	var ent := MapEntities.new()
	var vis: Node2D = ent.make_npc_visual(id, nd)
	holder.add_child(vis)
	ent.queue_free()

func _opt(text: String, icon_name: String, primary: bool, cb: Callable, disabled: bool = false) -> void:
	var b: Button = T.button_primary(text, Vector2(0, 40)) if primary else T.button(text, Vector2(0, 40))
	b.add_theme_font_size_override("font_size", T.FS_M)
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	if not icon_name.is_empty():
		b.icon = T.icon(icon_name)
		b.expand_icon = true
		b.add_theme_constant_override("icon_max_width", 20)
		b.add_theme_constant_override("h_separation", 8)
		b.add_theme_color_override("icon_normal_color", Color(0.16, 0.09, 0.01) if primary else T.C_GOLD)
		b.add_theme_color_override("icon_hover_color", Color(0.16, 0.09, 0.01) if primary else T.C_GOLD)
	b.pressed.connect(cb)
	b.disabled = disabled
	_opts.add_child(b)

func _rebuild_options() -> void:
	for c in _opts.get_children(): c.queue_free()
	var nd: Dictionary = Data.npc(npc_id)
	var role := str(nd.get("role", ""))
	var pl: Dictionary = Game.player
	var q: Dictionary = pl.get("quest", {}) if typeof(pl.get("quest", {})) == TYPE_DICTIONARY else {}
	var id := npc_id
	if role == "quest" and not q.is_empty():
		var state := str(q.get("state", "none"))
		if state == "none":
			_opt("Nhận nhiệm vụ", "quest", true, func(): Net.action("quest_accept", {}))
		elif state == "done" or state == "active":
			_opt("Trả nhiệm vụ", "quest", state == "done", func(): Net.action("quest_complete", {}))
	var side: Dictionary = pl.get("side", {}) if typeof(pl.get("side", {})) == TYPE_DICTIONARY else {}
	if role == "quest":
		for sid in (side.get("active", {}) as Dictionary).keys():
			var s := str(sid)
			_opt("Trả phụ tuyến", "quest", false, func(): Net.action("side_complete", {"id": s}))
	match role:
		"daily": _opt("Bảng nhiệm vụ ngày", "quest", true, func(): _panel("daily"))
		"storage": _opt("Mở kho", "storage", true, func(): _panel("storage"))
		"smith": _opt("Lò rèn", "anvil", true, func(): _panel("smith"))
		"teleport": _opt("Dịch chuyển", "portal", true, func(): _panel("teleport"))
		"shop": _opt("Xem cửa hàng", "shop", true, func(): _panel("shop", {"npc": id}))
		"market": _opt("Chợ người chơi", "social", true, func(): _panel("social"))
		"mystic": _opt("Nhập mật mã", "quest", true, func(): _panel("code"))
	if id == "lao_su":
		_opt("Đánh giá hạng", "char", false, func(): Net.action("rank_eval", {}))
		_opt("Tẩy điểm kỹ năng", "skills", false, func(): confirm_requested.emit("Tẩy điểm kỹ năng?", "Toàn bộ điểm kỹ năng sẽ được hoàn lại và kỹ năng đã học bị đặt lại.", "Tẩy điểm", func(): Net.action("reset_skills", {})))
	if id == "npc_an": _hidden_npc_options(pl)
	_opt("Trò chuyện", "chat", false, func(): Net.action("talk", {"npc": id}))
	_opt("Đặt điểm hồi sinh ở đây", "gear", false, func():
		Net.action("set_respawn", {"x": roundi(float(pl.get("x", 0))), "y": roundi(float(pl.get("y", 0)))}))
	_opt("Rời đi", "", false, close_dialog)

func _panel(tab: String, extra: Dictionary = {}) -> void:
	close_dialog()
	open_panel_requested.emit(tab, extra)

## Người Gác Màn: nhận / trả thử thách để mở khóa Ấn thức tỉnh (Biến hình) và Tiến hóa chức nghiệp.
func _hidden_npc_options(pl: Dictionary) -> void:
	var adv: Dictionary = pl.get("advancement", {}) if typeof(pl.get("advancement", {})) == TYPE_DICTIONARY else {}
	var done: Dictionary = adv.get("done", {}) if typeof(adv.get("done", {})) == TYPE_DICTIONARY else {}
	var aq: Variant = adv.get("quest", null)
	if typeof(aq) == TYPE_DICTIONARY:
		var have := int((aq as Dictionary).get("progress", 0))
		var need := int((aq as Dictionary).get("need", 1))
		_sys.text = "Thử thách đang làm: hạ %d quái bất kỳ — %d/%d" % [need, have, need]
		_opt("Trả thử thách %d/%d" % [have, need], "quest", have >= need, func(): Net.action("advancement_complete", {}), have < need)
		return
	var lvl := int(pl.get("level", 1))
	var tier := int(pl.get("awakenTier", 0)) + 1
	if tier <= 5 and not bool(done.get("awaken%d" % tier, false)):
		var aw: Dictionary = Data.awaken(tier)
		var req := int(aw.get("level", 999))
		var mid := "awaken%d" % tier
		_opt("Biến Hình %s%s" % [str(Data.ROMAN[tier - 1]), "" if lvl >= req else " (cần cấp %d)" % req], "flame", lvl >= req, func(): Net.action("advancement_accept", {"milestone": mid}), lvl < req)
	var school := str(pl.get("school", ""))
	var base := str(Data.school(school).get("base", school))
	if base in Data.EVOLUTION_SCHOOLS and not bool(Data.school(school).get("evolved", false)) and not bool(done.get("evolution", false)):
		_opt("Tiến hóa chức nghiệp%s" % ("" if lvl >= 25 else " (cần cấp 25)"), "skills", lvl >= 25, func(): Net.action("advancement_accept", {"milestone": "evolution"}), lvl < 25)
