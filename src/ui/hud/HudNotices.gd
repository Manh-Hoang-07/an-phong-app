extends "res://src/ui/hud/HudPart.gd"
## Thông báo: toast, khung nhặt/dùng đồ, tên khu vực, banner chữ lớn, mất kết nối, gợi ý lần đầu.
## Thành phần của MobileHUD (hud = MobileHUD): tự dựng node, tự giữ trạng thái; API công khai được MobileHUD chuyển tiếp.

var _toast_panel: PanelContainer = null

var _toast: Label = null

var _toast_tween: Tween = null

# Khung thông báo kết quả (dùng/nhặt đồ) ở giữa-dưới màn hình.
var _pickup_panel: PanelContainer = null

var _pickup_label: Label = null

var _pickup_icon: TextureRect = null

var _pickup_tween: Tween = null

var _last_pickup_text := ""

var _last_pickup_at := 0

# Khung tên map / khu vực ở giữa-trên màn hình.
var _zone_panel: PanelContainer = null

var _zone_title: Label = null

var _zone_sub: Label = null

var _zone_icon: TextureRect = null

var _zone_tween: Tween = null

var _zone_shown_at := 0

var _banner: Label = null

var _banner_tween: Tween = null

var _offline_bar: PanelContainer = null

var _hint_panel: PanelContainer = null

var _hint_label: Label = null

var _hint_tween: Tween = null

func _build_toast() -> void:
	_toast_panel = PanelContainer.new()
	_toast_panel.visible = false
	_toast_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast_panel.add_theme_stylebox_override("panel", T.UISkin.pill())
	_anchor_rect(_toast_panel, Control.PRESET_CENTER_TOP, 0, _inset.y + 50, 40, 36)
	_toast_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_root.add_child(_toast_panel)
	_toast = T.label("", T.FS_M, T.C_GOLD, true)
	_toast.autowrap_mode = TextServer.AUTOWRAP_OFF
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast_panel.add_child(_toast)

## Khung thông báo kết quả ở giữa-dưới (ngang tầm action bar), hiện trên cả panel đang mở.
func _build_pickup() -> void:
	_pickup_panel = PanelContainer.new()
	_pickup_panel.visible = false
	_pickup_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pickup_panel.add_theme_stylebox_override("panel", T.UISkin.pill())
	# Căn giữa theo chiều ngang, đáy cách mép một đoạn (cao hơn action bar).
	_pickup_panel.anchor_left = 0.5
	_pickup_panel.anchor_right = 0.5
	_pickup_panel.anchor_top = 1.0
	_pickup_panel.anchor_bottom = 1.0
	_pickup_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_pickup_panel.offset_left = -160.0
	_pickup_panel.offset_right = 160.0
	_pickup_panel.offset_top = -108.0
	_pickup_panel.offset_bottom = -70.0
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 8)
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	_pickup_panel.add_child(hb)
	_pickup_icon = T.icon_rect("bag", 22.0, T.C_GOLD)
	hb.add_child(_pickup_icon)
	_pickup_label = T.label("", T.FS_M, T.C_TEXT, true)
	_pickup_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_pickup_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_pickup_label.custom_minimum_size = Vector2(260, 0)
	hb.add_child(_pickup_label)
	_root.add_child(_pickup_panel)
	# Đưa lên trên cùng để không bị panel / scrim che khi đang mở túi.
	_root.move_child(_pickup_panel, _root.get_child_count() - 1)

## Khung tên map + khu vực ở giữa-trên (hiện khi vào map mới / đổi khu).
func _build_zone() -> void:
	_zone_panel = PanelContainer.new()
	_zone_panel.visible = false
	_zone_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# StyleBoxFlat thay vì pill() 9-slice: pill co mép khi có 2 dòng làm lọt chữ ra ngoài viền.
	_zone_panel.add_theme_stylebox_override("panel", T.sb_shadow(
		Color(0.035, 0.05, 0.09, 0.94), T.C_GOLD_DK, 2, 16, 8))
	_zone_panel.anchor_left = 0.5
	_zone_panel.anchor_right = 0.5
	_zone_panel.anchor_top = 0.0
	_zone_panel.anchor_bottom = 0.0
	_zone_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_zone_panel.offset_left = -160.0
	_zone_panel.offset_right = 160.0
	_zone_panel.offset_top = _inset.y + 90.0
	_zone_panel.offset_bottom = _inset.y + 154.0
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 2)
	vb.alignment = BoxContainer.ALIGNMENT_BEGIN
	_zone_panel.add_child(vb)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 6)
	head.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_child(head)
	_zone_icon = T.icon_rect("map", 18.0, T.C_GOLD)
	head.add_child(_zone_icon)
	_zone_title = T.label("", T.FS_L, T.C_GOLD, true)
	_zone_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_zone_title.autowrap_mode = TextServer.AUTOWRAP_OFF
	head.add_child(_zone_title)
	_zone_sub = T.label("", T.FS_M, T.C_BRASS, true)
	_zone_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_zone_sub.autowrap_mode = TextServer.AUTOWRAP_OFF
	vb.add_child(_zone_sub)
	_root.add_child(_zone_panel)
	_root.move_child(_zone_panel, _root.get_child_count() - 1)

## kind: "info" (vàng) | "success" (xanh) | "error" (đỏ) | "warn" (cam). Thông báo mới thay thế cái cũ, tự mờ dần.
func toast(text: String, kind: String = "info") -> void:
	if not _toast: return
	var col := T.C_GOLD
	var pre := ""
	match kind:
		"success": col = T.C_GREEN; pre = "✓  "
		"error": col = Color(1.0, 0.45, 0.45); pre = "✕  "
		"warn": col = Color(1.0, 0.7, 0.3); pre = "!  "
	_toast.text = pre + text
	_toast.add_theme_color_override("font_color", col)
	if kind == "error": Audio.play("error")
	_toast_panel.visible = true
	_toast_panel.modulate.a = 0.0
	_toast_panel.reset_size()
	_toast_panel.offset_left = -_toast_panel.size.x * 0.5
	_toast_panel.offset_right = _toast_panel.size.x * 0.5
	if _toast_tween: _toast_tween.kill()
	_toast_tween = create_tween()
	_toast_tween.tween_property(_toast_panel, "modulate:a", 1.0, 0.12)
	_toast_tween.tween_interval(1.8 if kind != "error" else 2.6)
	_toast_tween.tween_property(_toast_panel, "modulate:a", 0.0, 0.3)
	_toast_tween.tween_callback(func(): _toast_panel.visible = false)

## Hiện khung tên map + khu vực ở giữa-trên, tự mờ dần.
func show_zone(map_name: String, zone: int) -> void:
	if not _zone_panel: return
	_zone_title.text = map_name if not map_name.is_empty() else "Thức Tỉnh"
	if zone > 0:
		_zone_sub.text = "Khu %d" % zone
		_zone_sub.visible = true
	else:
		_zone_sub.text = ""
		_zone_sub.visible = false
	_zone_panel.visible = true
	_zone_panel.modulate.a = 0.0
	# Tự co theo nội dung rồi căn giữa; dùng StyleBoxFlat nên reset_size không làm lọt chữ.
	_zone_panel.reset_size()
	_zone_panel.offset_left = -_zone_panel.size.x * 0.5
	_zone_panel.offset_right = _zone_panel.size.x * 0.5
	_zone_shown_at = Time.get_ticks_msec()
	if _zone_tween: _zone_tween.kill()
	_zone_tween = create_tween().set_parallel(true)
	_zone_tween.tween_property(_zone_panel, "modulate:a", 1.0, 0.2)
	_zone_tween.tween_property(_zone_panel, "scale", Vector2(1.05, 1.05), 0.12).from_current()
	_zone_tween.tween_property(_zone_panel, "scale", Vector2.ONE, 0.14)
	_zone_tween.chain().tween_interval(2.2)
	_zone_tween.chain().tween_property(_zone_panel, "modulate:a", 0.0, 0.4)
	_zone_tween.chain().tween_callback(func(): _zone_panel.visible = false)

## Hiện khung kết quả cho các event liên quan đến đồ / thưởng.
func _on_event_pickup_feed(ev: Dictionary) -> void:
	var t := str(ev.get("t", ""))
	if t == "msg":
		var txt := str(ev.get("text", "")).strip_edges()
		if txt.is_empty(): return
		# Chỉ đưa vào khung các dòng kết quả (nhặt đồ, dùng đồ, nhận thưởng...),
		# bỏ qua hội thoại NPC / tin hệ thống dài để khung không bị spam.
		if txt.length() > 90: return
		var col := Color.from_string(str(ev.get("color", "")), T.C_GOLD)
		pickup(txt, "bag", col)
	elif t == "upgrade":
		var ok := bool(ev.get("ok", true))
		pickup("Cường hóa thành công!" if ok else "Cường hóa thất bại", "anvil", T.C_GREEN if ok else T.C_RED)

## Khung kết quả dùng/nhặt đồ ở giữa-dưới. icon: tên icon SVG; color: màu chữ.
func pickup(text: String, icon_name: String = "bag", color: Color = T.C_GOLD) -> void:
	if not _pickup_panel: return
	_last_pickup_text = text
	_last_pickup_at = Time.get_ticks_msec()
	# Dòng này có thể đã được World ghi vào log trước khi callback của ta chạy;
	# xóa bản trùng ở góc trái đi (không phụ thuộc thứ tự callback).
	var removed := false
	for i in range(hud.chat._log_lines.size() - 1, -1, -1):
		if str((hud.chat._log_lines[i] as Dictionary).get("text", "")) == text:
			hud.chat._log_lines.remove_at(i)
			removed = true
	if removed: hud._render_log()
	_pickup_label.text = text
	_pickup_label.add_theme_color_override("font_color", color)
	_pickup_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	_pickup_label.add_theme_constant_override("outline_size", 4)
	if _pickup_icon and T.icon(icon_name) != null:
		_pickup_icon.texture = T.icon(icon_name)
		_pickup_icon.modulate = color
	_pickup_panel.visible = true
	_pickup_panel.modulate.a = 0.0
	_pickup_panel.reset_size()
	# reset_size có thể đổi chiều rộng; căn lại giữa màn hình.
	_pickup_panel.offset_left = -_pickup_panel.size.x * 0.5
	_pickup_panel.offset_right = _pickup_panel.size.x * 0.5
	if _pickup_tween: _pickup_tween.kill()
	_pickup_tween = create_tween()
	_pickup_tween.tween_property(_pickup_panel, "modulate:a", 1.0, 0.14)
	_pickup_tween.tween_property(_pickup_panel, "scale", Vector2(1.06, 1.06), 0.10).from_current()
	_pickup_tween.tween_property(_pickup_panel, "scale", Vector2.ONE, 0.12)
	_pickup_tween.tween_interval(2.2)
	_pickup_tween.tween_property(_pickup_panel, "modulate:a", 0.0, 0.35)
	_pickup_tween.tween_callback(func(): _pickup_panel.visible = false)

func _build_banner() -> void:
	_banner = T.hud_label("", T.FS_XXL, T.C_GOLD, true)
	_banner.visible = false
	_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_banner.set_anchors_preset(Control.PRESET_CENTER)
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.add_theme_constant_override("outline_size", 8)
	_banner.offset_left = -300; _banner.offset_right = 300
	_banner.offset_top = -90; _banner.offset_bottom = -30
	_root.add_child(_banner)

## Chữ lớn giữa màn hình (lên cấp, hạng...), tự mờ dần.
func banner(text: String, color: Color = T.C_GOLD) -> void:
	if _banner == null: return
	_banner.text = text
	_banner.add_theme_color_override("font_color", color)
	_banner.visible = true
	_banner.modulate.a = 0.0
	_banner.pivot_offset = Vector2(300, 30)
	_banner.scale = Vector2(0.7, 0.7)
	if _banner_tween: _banner_tween.kill()
	_banner_tween = create_tween()
	_banner_tween.set_parallel(true)
	_banner_tween.tween_property(_banner, "modulate:a", 1.0, 0.2)
	_banner_tween.tween_property(_banner, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_banner_tween.chain().tween_interval(1.4)
	_banner_tween.chain().tween_property(_banner, "modulate:a", 0.0, 0.4)
	_banner_tween.chain().tween_callback(func(): _banner.visible = false)

func _build_net_status() -> void:
	_offline_bar = PanelContainer.new()
	_offline_bar.visible = false
	_offline_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb: StyleBoxTexture = T.UISkin.button("danger", "normal", 8)
	_offline_bar.add_theme_stylebox_override("panel", sb)
	_anchor_rect(_offline_bar, Control.PRESET_CENTER_TOP, 0, _inset.y + 44, 300, 34)
	_root.add_child(_offline_bar)
	var l := T.label("Mất kết nối máy chủ — đang thử lại…", T.FS_S, Color.WHITE, true)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_offline_bar.add_child(l)
	Net.offline_changed.connect(func(off): _offline_bar.visible = off)
	Socket.disconnected_from_server.connect(func(_c): _offline_bar.visible = true)
	Socket.connected_to_server.connect(func(): _offline_bar.visible = false)
	# Gợi ý
	_hint_panel = PanelContainer.new()
	_hint_panel.visible = false
	_hint_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hint_panel.add_theme_stylebox_override("panel", T.UISkin.panel(10))
	_hint_panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_hint_panel.offset_left = -190; _hint_panel.offset_right = 190
	_hint_panel.offset_top = -(_inset.w + 190.0); _hint_panel.offset_bottom = -(_inset.w + 136.0)
	_hint_label = T.label("", T.FS_S, T.C_TEXT)
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint_panel.add_child(_hint_label)
	_root.add_child(_hint_panel)

## Gợi ý hiện đúng một lần cho mỗi id (lưu trong Settings).
func hint_once(id: String, text: String) -> void:
	if Settings.hints_seen.has(id): return
	Settings.mark_hint(id)
	_hint_label.text = "💡 " + text
	_hint_panel.visible = true
	_hint_panel.modulate.a = 0.0
	if _hint_tween: _hint_tween.kill()
	_hint_tween = create_tween()
	_hint_tween.tween_property(_hint_panel, "modulate:a", 1.0, 0.25)
	_hint_tween.tween_interval(4.5)
	_hint_tween.tween_property(_hint_panel, "modulate:a", 0.0, 0.4)
	_hint_tween.tween_callback(func(): _hint_panel.visible = false)
