extends RefCounted
## Lớp nền cho mọi module panel: hằng dùng chung, truy cập trạng thái dùng chung ở hub (GamePanels) và các hàm dựng UI nhỏ.
## Module con `extends` file này và chỉ định nghĩa build_<tab>(); trạng thái riêng của panel khai báo ngay trong module.

const T := preload("res://src/ui/UITheme.gd")

const TouchScroll := preload("res://src/ui/TouchScroll.gd")

const MobSpriteCls := preload("res://src/world/MobSprite.gd")

const W := preload("res://src/ui/PanelWidgets.gd")

var gp  # GamePanels (hub)

# --- trạng thái dùng chung (lưu ở hub)
var selected_where: String:
	get: return gp.selected_where
	set(v): gp.selected_where = v
var selected_key: String:
	get: return gp.selected_key
	set(v): gp.selected_key = v
var confirm_drop: String:
	get: return gp.confirm_drop
	set(v): gp.confirm_drop = v
var confirm_buy: String:
	get: return gp.confirm_buy
	set(v): gp.confirm_buy = v
var equip_detail: bool:
	get: return gp.equip_detail
	set(v): gp.equip_detail = v
var npc_id: String:
	get: return gp.npc_id
	set(v): gp.npc_id = v
var ctx_extra: Dictionary:
	get: return gp.ctx_extra
	set(v): gp.ctx_extra = v
var host: Object:
	get: return gp.host

func _init(hub) -> void:
	gp = hub

# --- chuyển tiếp sang hub
func p() -> Dictionary:
	return gp.p()

func act(type: String, params: Dictionary = {}, silent: bool = true) -> void:
	gp.act(type, params, silent)

func refresh() -> void:
	gp.refresh()

func _select(where: String, key: String) -> void:
	gp._select(where, key)

func _deselect() -> void:
	gp._deselect()

# --- hàm dựng UI dùng chung
func _vb(sep: int = 10) -> VBoxContainer:
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", sep)
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return vb

func _gold_row(pl: Dictionary, ngoc: bool = true) -> Control:
	var items: Array = [["Vàng  %s" % W.full_num(int(pl.get("gold", 0))), T.C_GOLD]]
	if ngoc: items.append(["Linh Ngọc  %s" % W.full_num(int(pl.get("linhNgoc", 0))), T.C_PURPLE])
	return W.chip_row(items)

func _bag_entry(uid: String) -> Dictionary:
	for x in p().get("bag", []):
		if typeof(x) == TYPE_DICTIONARY and str(x.get("uid", "")) == uid: return x
	return {}

## Trạng thái rỗng: icon mờ + lời hướng dẫn, căn giữa.
func _empty(text: String, icon_name: String = "bag") -> Control:
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.custom_minimum_size = Vector2(0, 130)
	box.add_theme_constant_override("separation", 8)
	var ic := T.icon_rect(icon_name, 40.0, Color(T.C_MUTED, 0.45))
	ic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(ic)
	var l := T.label(text, T.FS_S, Color(T.C_MUTED, 0.9))
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(l)
	return box

func _grid(cols: int) -> GridContainer:
	return W.grid(cols)

## Vết Nhiễm đỏ: cảnh báo (trừ máu, chặn hồi máu ngoài giao chiến) + nút gột bằng Thuốc chữa nhiễm đỏ (cleanse_nhiem).
func _nhiem_block(parent: Control, entry: Dictionary, params: Dictionary) -> void:
	var n := int(entry.get("nhiem", 0))
	if n <= 0: return
	var meds := 0
	var bag: Variant = p().get("bag", [])
	if typeof(bag) == TYPE_ARRAY:
		for b in bag:
			if typeof(b) == TYPE_DICTIONARY and str((b as Dictionary).get("id", "")) == "thuoc_nhiem_do": meds += int((b as Dictionary).get("qty", (b as Dictionary).get("n", 1)))
	var warn := T.label("Nhiễm đỏ bậc %d: chỉ số chính +18%%, máu tối đa -%d%%, không hồi máu ngoài giao chiến." % [n, 6 * n], T.FS_S, T.C_RED)
	warn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(warn)
	var pl := p()
	var at_herb := Data.herb_shop_here(pl, str(pl.get("map", "")))
	var btn := W.action_button("Gột bằng Thuốc chữa nhiễm đỏ (%d)" % meds, func(): act("cleanse_nhiem", params), meds <= 0 or not at_herb)
	if not at_herb: btn.tooltip_text = "Hãy đến gặp Dược sư để gột vết nhiễm."
	parent.add_child(btn)

## Ô chỉ số: icon | nhãn | giá trị (giống web: nền thẻ tối, số đậm bên phải).
func _stat_cell(glyph: String, label_text: String, value: String, color: Color) -> Control:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", T.UISkin.inset(7))
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 6)
	var g := T.GlyphArt.make(glyph, 18.0, color)
	g.custom_minimum_size = Vector2(20, 20)
	g.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(g)
	if label_text.is_empty():
		h.alignment = BoxContainer.ALIGNMENT_CENTER
	else:
		var l := T.label(label_text, 11, T.C_MUTED)
		l.autowrap_mode = TextServer.AUTOWRAP_OFF
		l.clip_text = true
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(l)
	var v := T.label(value, T.FS_M, T.C_TEXT, true)
	v.autowrap_mode = TextServer.AUTOWRAP_OFF
	v.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(v)
	p.add_child(h)
	return p

func _prettify(id: String) -> String:
	return id.replace("_", " ").capitalize()
