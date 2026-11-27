extends "res://src/ui/hud/HudPart.gd"
## Hàng hiệu ứng (buff) đang chạy.
## Thành phần của MobileHUD (hud = MobileHUD): tự dựng node, tự giữ trạng thái; API công khai được MobileHUD chuyển tiếp.

var _buff_row: HBoxContainer = null

var _buff_sig := ""

var _buff_cells: Dictionary = {}   # id -> {t: Label, bar: ColorRect}

func _build_buffs() -> void:
	_buff_row = HBoxContainer.new()
	_buff_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_buff_row.add_theme_constant_override("separation", 4)
	_anchor_rect(_buff_row, Control.PRESET_TOP_LEFT, _inset.x + 2, _inset.y + 108, 320, 46)
	_buff_row.visible = false
	_root.add_child(_buff_row)

## list: [{id, icon, label, left (ms), dur (ms)}]. Mỗi hiệu ứng một ô: biểu tượng, số giây còn lại, vạch thời gian chạy dần.
func set_buffs(list: Array) -> void:
	if _buff_row == null: return
	var sig := ""
	for b in list: sig += str((b as Dictionary)["id"]) + ","
	if sig != _buff_sig:
		_buff_sig = sig
		_buff_cells.clear()
		for c in _buff_row.get_children(): c.queue_free()
		for b in list:
			var d: Dictionary = b
			var cell := Control.new()
			cell.custom_minimum_size = Vector2(38, 46)
			cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var bg := Panel.new()
			bg.set_anchors_preset(Control.PRESET_FULL_RECT)
			bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
			bg.add_theme_stylebox_override("panel", T.sb(Color(0.03, 0.05, 0.1, 0.72), Color(T.C_GOLD, 0.6), 1, 6, 0))
			cell.add_child(bg)
			var ic := T.GlyphArt.make(str(d["icon"]), 26.0)
			ic.position = Vector2(6, 2)
			ic.size = Vector2(26, 26)
			ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
			cell.add_child(ic)
			var tl := T.hud_label("", 12, Color.WHITE, true)
			tl.position = Vector2(0, 27)
			tl.custom_minimum_size = Vector2(38, 0)
			tl.size = Vector2(38, 14)
			tl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			tl.add_theme_constant_override("outline_size", 3)
			cell.add_child(tl)
			var bar := ColorRect.new()
			bar.color = T.C_GOLD
			bar.position = Vector2(3, 41)
			bar.size = Vector2(32, 3)
			bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
			cell.add_child(bar)
			cell.tooltip_text = str(d["label"])
			_buff_row.add_child(cell)
			_buff_cells[str(d["id"])] = {"t": tl, "bar": bar}
	_buff_row.visible = not list.is_empty()
	for b in list:
		var d2: Dictionary = b
		var c: Dictionary = _buff_cells.get(str(d2["id"]), {})
		if c.is_empty(): continue
		var left := int(d2["left"])
		var secs := int(ceil(float(left) / 1000.0))
		(c["t"] as Label).text = str(secs)
		(c["t"] as Label).add_theme_color_override("font_color", Color(1.0, 0.55, 0.5) if left <= 3000 else Color.WHITE)
		(c["bar"] as ColorRect).size.x = 32.0 * clampf(float(left) / float(maxi(1, int(d2["dur"]))), 0.0, 1.0)
