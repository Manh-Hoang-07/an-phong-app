extends RefCounted
## Widget dùng chung cho các panel: ô item, thanh, nút action, modal xác nhận.
## Không chứa luật chơi — mọi action đều gọi Net.action() ở GamePanels.

const T := preload("res://src/ui/UITheme.gd")

static func clear(node: Node) -> void:
	for c in node.get_children():
		c.queue_free()

static func row(text: String, color: Color = T.C_TEXT, size: int = 14) -> Label:
	return T.row(text, color, size)

static func hsep(color: Color = T.C_BORDER) -> HSeparator:
	return T.hsep(color)

static func item_name(iid: String) -> String:
	var d: Dictionary = Data.item(iid)
	return str(d.get("name", iid))

static func item_desc(iid: String) -> String:
	var d: Dictionary = Data.item(iid)
	return str(d.get("desc", ""))

static func skill_name(sid: String) -> String:
	var d: Dictionary = Data.skill(sid)
	return str(d.get("name", sid))

static func skill_icon(sid: String) -> String:
	var d: Dictionary = Data.skill(sid)
	return str(d.get("icon", "✦"))

static func school_name(sid: String) -> String:
	var d: Dictionary = Data.school(sid)
	return str(d.get("name", sid))

static func school_icon(sid: String) -> String:
	var d: Dictionary = Data.school(sid)
	return str(d.get("icon", "◆"))

static func map_name(mid: String) -> String:
	var d: Dictionary = Data.map_def(mid)
	return str(d.get("name", mid))

static func npc_name(nid: String) -> String:
	var v: Variant = Data.raw.get("NPCS", {}).get(nid, {})
	return str((v as Dictionary).get("name", nid)) if typeof(v) == TYPE_DICTIONARY else nid

static func monster_name(mid: String) -> String:
	var d: Dictionary = Data.monster(mid)
	return str(d.get("name", mid))

static func fmt_num(n: int) -> String:
	if n >= 1000000: return "%.1fM" % (float(n) / 1000000.0)
	if n >= 10000: return "%.1fK" % (float(n) / 1000.0)
	return str(n)

static func bar(label_text: String, value: int, maximum: int, color: Color) -> VBoxContainer:
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 5)
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var head := HBoxContainer.new()
	var l := T.label(label_text, T.FS_S, T.C_MUTED)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(l)
	var v := T.label("%d / %d" % [value, maximum], T.FS_S, color, true)
	v.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	v.custom_minimum_size = Vector2(80, 0)
	head.add_child(v)
	vb.add_child(head)
	var pb := ProgressBar.new()
	pb.min_value = 0
	pb.max_value = maxi(1, maximum)
	pb.value = clampi(value, 0, maxi(1, maximum))
	pb.custom_minimum_size = Vector2(0, 18)
	pb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pb.show_percentage = false
	pb.add_theme_stylebox_override("fill", T.UISkin.bar_fill(color))
	pb.add_theme_stylebox_override("background", T.UISkin.bar_frame())
	vb.add_child(pb)
	return vb

static func card(title: String, subtitle: String = "", color: Color = T.C_BORDER) -> PanelContainer:
	var p := PanelContainer.new()
	var sb := T._sb(T.C_CARD, color, 1, 10)
	p.add_theme_stylebox_override("panel", sb)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 3)
	p.add_child(vb)
	if not title.is_empty():
		vb.add_child(T.label(title, 15, T.C_TEXT, true))
	if not subtitle.is_empty():
		vb.add_child(T.label(subtitle, 12, T.C_MUTED))
	return p

static func card_body(p: PanelContainer) -> VBoxContainer:
	return p.get_child(0) as VBoxContainer

static func action_button(text: String, cb: Callable, disabled: bool = false) -> Button:
	var b := T.button(text, Vector2(0, 40))
	b.disabled = disabled
	if cb.is_valid(): b.pressed.connect(cb)
	return b

static func kv(k: String, v: String, vc: Color = T.C_TEXT) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var a := T.label(k, T.FS_M, T.C_MUTED)
	a.custom_minimum_size = Vector2(92, 26)
	h.add_child(a)
	# Value căn TRÁI ngay sau key. KHÔNG dùng clip_text: nó làm Label request chiều cao 0
	# trong VBoxContainer -> cả dòng bị ép mất (stats hiện không ra chữ).
	var b := T.label(v, T.FS_M, vc, true)
	b.custom_minimum_size = Vector2(80, 26)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(b)
	return h

static func grid(columns: int) -> GridContainer:
	var g := GridContainer.new()
	g.columns = columns
	g.add_theme_constant_override("h_separation", 6)
	g.add_theme_constant_override("v_separation", 6)
	return g

const ITEM_ICON_DIR := "res://assets/items/"

# fw/fh/cx/fy/s của từng class (khớp CharSprite.CHARS) để crop portrait.
const PORTRAIT_DEFS := {
	"kiem_si": [238, 194, 73, 189, 0.45], "cung_thu": [200, 200, 101, 134, 0.775],
	"phap_su": [231, 190, 110, 141, 0.68], "toan_nang": [311, 199, 156, 195, 0.452],
	"sat_thu": [221, 198, 89, 155, 0.45], "tanker": [199, 175, 101, 170, 0.45],
	"tri_lieu_su": [196, 146, 60, 138, 0.55], "trieu_hoi_su": [246, 202, 116, 202, 0.45],
	"tu_linh_thuat_su": [184, 222, 72, 210, 0.6], "kiem_thanh": [260, 245, 130, 237, 0.27],
}
const PORTRAIT_ALIAS := {"than_xa":"cung_thu", "anh_vuong":"sat_thu", "thanh_linh":"tri_lieu_su",
	"ho_ve_bat_khuat":"tanker", "dai_phap_su":"phap_su", "none":"kiem_si"}

## Portrait nhân vật: crop khung idle đầu tiên từ sprite sheet, căn giữa.
static func char_portrait(school_id: String, size: int = 96) -> TextureRect:
	var school: String = str(PORTRAIT_ALIAS.get(school_id, school_id))
	if not PORTRAIT_DEFS.has(school): school = "kiem_si"
	var def: Array = PORTRAIT_DEFS[school]
	var path := "res://assets/chars/%s/idle.png" % school
	var tr := TextureRect.new()
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.custom_minimum_size = Vector2(size, size)
	tr.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if not ResourceLoader.exists(path): return tr
	var tex := load(path) as Texture2D
	if tex == null: return tr
	var at := AtlasTexture.new()
	at.atlas = tex
	at.region = Rect2(0, 0, float(def[0]), float(def[1]))
	tr.texture = at
	return tr

## Avatar: crop vuông quanh thân trên của nhân vật (khung idle đầu tiên), cho HUD.
static func char_avatar(school_id: String, size: int = 56) -> TextureRect:
	var school: String = str(PORTRAIT_ALIAS.get(school_id, school_id))
	if not PORTRAIT_DEFS.has(school): school = "kiem_si"
	var def: Array = PORTRAIT_DEFS[school]
	var tr := TextureRect.new()
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.custom_minimum_size = Vector2(size, size)
	var path := "res://assets/chars/%s/idle.png" % school
	if not ResourceLoader.exists(path): return tr
	var tex := load(path) as Texture2D
	if tex == null: return tr
	var fw := float(def[0]); var fh := float(def[1]); var cx := float(def[2]); var fy := float(def[3])
	var side := minf(minf(fw, fh), 120.0)
	var x := clampf(cx - side * 0.5, 0.0, fw - side)
	var y := clampf(fy - side * 1.15, 0.0, fh - side)
	var at := AtlasTexture.new()
	at.atlas = tex
	at.region = Rect2(x, y, side, side)
	tr.texture = at
	return tr

## Texture icon của item (SVG do web ItemArt sinh ra, export sang assets/items).
static func item_icon(iid: String, size: int = 44) -> TextureRect:
	var tr := TextureRect.new()
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.custom_minimum_size = Vector2(size, size)
	var path := ITEM_ICON_DIR + iid + ".svg"
	if ResourceLoader.exists(path):
		var tex := load(path) as Texture2D
		if tex: tr.texture = tex
	return tr

const CELL := 58.0

## Ô vật phẩm kiểu game: vuông, chỉ có icon + viền độ hiếm + huy hiệu nhỏ.
## qty > 1: số lượng ở góc dưới phải. badge: chữ góc trên trái (vd "+3", "Mặc"). Tên / giá xem ở khung chi tiết.
static func item_cell(iid: String, qty: int, selected: bool, cb: Callable, badge: String = "") -> Button:
	var d: Dictionary = Data.item(iid)
	var q: int = int(d.get("q", 0))
	var qc: Color = T.quality_color(q) if q > 1 else T.C_BORDER
	var b := T.button("", Vector2(CELL, CELL))
	b.focus_mode = Control.FOCUS_NONE
	b.tooltip_text = str(d.get("name", iid))
	var normal: StyleBox = T.UISkin.slot(q)
	var sel: StyleBox = T.UISkin.slot(q, true)
	b.add_theme_stylebox_override("normal", sel if selected else normal)
	b.add_theme_stylebox_override("hover", sel)
	b.add_theme_stylebox_override("pressed", sel)
	var ic := item_icon(iid, 38)
	ic.set_anchors_preset(Control.PRESET_FULL_RECT)
	ic.offset_left = 8; ic.offset_top = 8; ic.offset_right = -8; ic.offset_bottom = -8
	ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(ic)
	if qty > 1:
		var ql := T.hud_label(str(qty) if qty < 1000 else "999+", 12, Color.WHITE, true)
		ql.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
		ql.offset_right = -5; ql.offset_bottom = -2; ql.offset_left = -40; ql.offset_top = -20
		ql.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		ql.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(ql)
	if not badge.is_empty():
		var bl := T.hud_label(badge, 11, T.C_GOLD, true)
		bl.offset_left = 5; bl.offset_top = 2
		bl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(bl)
	if cb.is_valid(): b.pressed.connect(cb)
	return b

## Ô trống (khung rỗng) — lấp đầy lưới túi/kho cho giống game.
static func empty_cell() -> Control:
	var p := Panel.new()
	p.custom_minimum_size = Vector2(CELL, CELL)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_theme_stylebox_override("panel", T.UISkin.slot(0, false, true))
	return p

const EQ_CELL := 52.0

## Ô trang bị: có đồ -> icon + viền độ hiếm; trống -> tên ô mờ ở giữa.
static func equip_cell(slot_label: String, iid: String, plus: int, selected: bool, cb: Callable) -> Control:
	var cell: Button
	if iid.is_empty():
		cell = T.button("", Vector2(EQ_CELL, EQ_CELL))
		cell.add_theme_stylebox_override("normal", T.UISkin.slot(0, selected, true))
		cell.add_theme_stylebox_override("hover", T.UISkin.slot(0, true, true))
		cell.add_theme_stylebox_override("pressed", T.UISkin.slot(0, true, true))
		var l := T.label(slot_label, 11, Color(T.C_MUTED, 0.85))
		l.set_anchors_preset(Control.PRESET_FULL_RECT)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cell.add_child(l)
		cell.pressed.connect(cb)
	else:
		cell = item_cell(iid, 1, selected, cb, ("+%d" % plus) if plus > 0 else "")
		cell.custom_minimum_size = Vector2(EQ_CELL, EQ_CELL)
	return cell

## Ảnh thân nhân vật (khung idle đầu tiên, cắt quanh thân) cho màn trang bị.
static func char_body(school_id: String, size: Vector2 = Vector2(150, 200)) -> TextureRect:
	var school: String = str(PORTRAIT_ALIAS.get(school_id, school_id))
	if not PORTRAIT_DEFS.has(school): school = "kiem_si"
	var def: Array = PORTRAIT_DEFS[school]
	var tr := TextureRect.new()
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.custom_minimum_size = size
	tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var path := "res://assets/chars/%s/idle.png" % school
	if not ResourceLoader.exists(path): return tr
	var tex := load(path) as Texture2D
	if tex == null: return tr
	var fw := float(def[0]); var fh := float(def[1]); var cx := float(def[2]); var fy := float(def[3])
	var h := minf(fy + 6.0, 170.0)
	var w := minf(h * size.x / size.y, fw)
	var at := AtlasTexture.new()
	at.atlas = tex
	at.region = Rect2(clampf(cx - w * 0.5, 0.0, fw - w), clampf(fy + 6.0 - h, 0.0, fh - h), w, minf(h, fh))
	tr.texture = at
	return tr

## Hàng danh sách mua bán: icon | tên + phụ đề | giá (vàng) bên phải. Chạm để chọn.
static func shop_row(iid: String, subtitle: String, price_text: String, selected: bool, cb: Callable) -> Button:
	var d: Dictionary = Data.item(iid)
	var q: int = int(d.get("q", 0))
	var b := T.button("", Vector2(0, 52))
	var normal: StyleBox = T.UISkin.card(0)
	var sel: StyleBox = T.UISkin.tab(true)
	b.add_theme_stylebox_override("normal", sel if selected else normal)
	b.add_theme_stylebox_override("hover", sel)
	b.add_theme_stylebox_override("pressed", sel)
	var h := HBoxContainer.new()
	h.set_anchors_preset(Control.PRESET_FULL_RECT)
	h.offset_left = 8; h.offset_right = -10
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_theme_constant_override("separation", 10)
	var ic := item_icon(iid, 36)
	ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(ic)
	var col := VBoxContainer.new()
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 0)
	h.add_child(col)
	var t1 := T.label(str(d.get("name", iid)), T.FS_M, T.quality_color(q) if q > 1 else T.C_TEXT, true)
	t1.autowrap_mode = TextServer.AUTOWRAP_OFF
	t1.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	t1.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(t1)
	if not subtitle.is_empty():
		var t2 := T.label(subtitle, 12, T.C_MUTED)
		t2.autowrap_mode = TextServer.AUTOWRAP_OFF
		t2.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		t2.mouse_filter = Control.MOUSE_FILTER_IGNORE
		col.add_child(t2)
	var pl := T.label(price_text, T.FS_M, T.C_GOLD, true)
	pl.autowrap_mode = TextServer.AUTOWRAP_OFF
	pl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	pl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(pl)
	b.add_child(h)
	if cb.is_valid(): b.pressed.connect(cb)
	return b

static func chip(text: String, color: Color = T.C_BORDER) -> PanelContainer:
	var p := PanelContainer.new()
	var sb: StyleBoxTexture = T.UISkin.pill()
	sb.content_margin_left = 12; sb.content_margin_right = 12; sb.content_margin_top = 3; sb.content_margin_bottom = 3
	sb.modulate_color = Color(1, 1, 1, 1)
	p.add_theme_stylebox_override("panel", sb)
	var l := T.label(text, T.FS_S, color, true)
	l.autowrap_mode = TextServer.AUTOWRAP_OFF
	p.add_child(l)
	return p

# ============================================================ Thành phần giao diện đợt 2
const STAT_NAMES := {"atk": "Tấn công", "def": "Phòng thủ", "hp": "Máu", "mp": "Năng lượng", "crit": "Chí mạng",
	"speed": "Tốc độ", "sta": "Thể lực", "skill": "Sức mạnh kỹ năng", "lifesteal": "Hút máu"}
const QUALITY_NAMES := ["Thường", "Thường", "Tốt", "Hiếm", "Huyền thoại", "Thần thoại"]

static func chip_row(items: Array) -> HBoxContainer:
	## items: [[text, color], ...]
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	for it in items:
		h.add_child(chip(str(it[0]), it[1] as Color))
	return h

static var left_scroll_pos := 0

## Hai cột chiếm trọn chiều cao còn lại: trái co giãn (danh sách), phải cố định (chi tiết). Mỗi cột tự cuộn.
static func split(left: Control, right: Control, right_w: float = 224.0) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	h.size_flags_vertical = Control.SIZE_EXPAND_FILL
	h.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var ls := ScrollContainer.new()
	ls.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ls.size_flags_vertical = Control.SIZE_EXPAND_FILL
	ls.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ls.add_child(left)
	h.add_child(ls)
	var rs := ScrollContainer.new()
	rs.custom_minimum_size = Vector2(right_w, 0)
	rs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rs.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rs.add_child(right)
	h.add_child(rs)
	# nhớ vị trí cuộn của cột trái qua các lần dựng lại
	ls.get_v_scroll_bar().value_changed.connect(func(v): left_scroll_pos = int(v))
	ls.set_deferred("scroll_vertical", left_scroll_pos)
	return h

## Đánh dấu một panel là "fill": HUD không bọc nó trong cuộn chung (các cột bên trong tự cuộn).
static func fill(c: Control) -> Control:
	c.set_meta("fill", true)
	c.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return c

## Khung chi tiết bên phải.
static func detail_box() -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", T.UISkin.inset(10))
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 6)
	p.add_child(vb)
	return p

static func box_body(p: PanelContainer) -> VBoxContainer:
	return p.get_child(0) as VBoxContainer

static func empty_detail(text: String = "Chạm vào một ô để xem chi tiết.") -> PanelContainer:
	var d := detail_box()
	var l := T.label(text, T.FS_S, Color(T.C_MUTED, 0.8))
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box_body(d).add_child(l)
	return d

## Thanh chọn kiểu tab: opts = [[id, nhãn], ...].
static func segmented(opts: Array, current: String, cb: Callable) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 6)
	for o in opts:
		var id := str(o[0])
		var active := id == current
		var b := T.button(str(o[1]), Vector2(0, 40))
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var n: StyleBox = T.UISkin.tab(active)
		b.add_theme_stylebox_override("normal", n)
		b.add_theme_stylebox_override("hover", n)
		b.add_theme_stylebox_override("pressed", T.UISkin.tab(true))
		b.add_theme_color_override("font_color", T.C_GOLD if active else T.C_MUTED)
		b.pressed.connect(func(): cb.call(id))
		h.add_child(b)
	return h

static func section_label(text: String) -> Label:
	var l := T.label(text, T.FS_M, T.C_GOLD, true)
	return l

## Ô thông số (nhãn nhỏ + giá trị lớn) dùng trong panel Nhân vật.
static func stat_tile(label_text: String, value: String, color: Color = T.C_TEXT) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", T.UISkin.card(8))
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 0)
	p.add_child(vb)
	vb.add_child(T.label(label_text, T.FS_S, T.C_MUTED))
	vb.add_child(T.label(value, T.FS_L, color, true))
	return p

## Dòng chỉ số của vật phẩm: "+13 Tấn công".
static func item_stat_lines(d: Dictionary) -> Array:
	var out: Array = []
	var st: Dictionary = d.get("stats", {})
	for k in st.keys():
		var v := float(st[k])
		var shown := ("%d" % int(v)) if is_equal_approx(v, roundf(v)) else ("%.1f" % v)
		var unit := "%" if str(k) == "crit" else ""
		out.append("+%s%s %s" % [shown, unit, str(STAT_NAMES.get(k, k))])
	if d.has("hp") and str(d.get("kind", "")) == "potion": out.append("Hồi %d máu" % int(d["hp"]))
	if d.has("mp") and str(d.get("kind", "")) == "potion": out.append("Hồi %d MP" % int(d["mp"]))
	return out

const QUALITY_TAGS := ["Thường", "Thường", "Tốt", "Hiếm", "Huyền thoại", "Thần thoại"]

## Chênh lệch chỉ số so với món đang mặc cùng ô: [[tên, delta], ...]
static func compare_with_equipped(d: Dictionary) -> Array:
	var out: Array = []
	var slot := str(d.get("slot", ""))
	if slot.is_empty(): return out
	var eq: Dictionary = Game.player.get("equip", {})
	var cur_stats: Dictionary = {}
	if typeof(eq.get(slot, null)) == TYPE_DICTIONARY:
		cur_stats = Data.item(str((eq[slot] as Dictionary).get("id", ""))).get("stats", {})
	var new_stats: Dictionary = d.get("stats", {})
	var keys := {}
	for k in new_stats.keys(): keys[k] = true
	for k in cur_stats.keys(): keys[k] = true
	for k in keys.keys():
		var dv := float(new_stats.get(k, 0)) - float(cur_stats.get(k, 0))
		if absf(dv) > 0.0001: out.append([str(STAT_NAMES.get(k, k)), dv, str(k) == "crit"])
	return out

## Thẻ chi tiết vật phẩm: icon + tên + độ hiếm + yêu cầu + chỉ số (+ so sánh với đang mặc) + mô tả.
static func item_detail(iid: String, extra_plus: int = 0, compare: bool = true) -> PanelContainer:
	var d: Dictionary = Data.item(iid)
	var q := int(d.get("q", 0))
	var box := detail_box()
	var body := box_body(box)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 8)
	body.add_child(head)
	var ic_frame := PanelContainer.new()
	ic_frame.add_theme_stylebox_override("panel", T.UISkin.slot(q))
	ic_frame.add_child(item_icon(iid, 40))
	head.add_child(ic_frame)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	col.add_theme_constant_override("separation", 2)
	head.add_child(col)
	var nm := str(d.get("name", iid)) + ((" +%d" % extra_plus) if extra_plus > 0 else "")
	col.add_child(T.label(nm, T.FS_M, T.quality_color(q) if q > 1 else T.C_TEXT, true))
	if q > 0: col.add_child(T.label(str(QUALITY_TAGS[clampi(q, 0, 5)]), 12, T.quality_color(q) if q > 1 else T.C_MUTED, true))
	# Yêu cầu: đỏ nếu chưa đạt
	var pl: Dictionary = Game.player
	var req_lv := int(d.get("level", 0))
	var school := str(d.get("school", ""))
	var reqs := HBoxContainer.new()
	reqs.add_theme_constant_override("separation", 6)
	if req_lv > 0:
		var ok := int(pl.get("level", 1)) >= req_lv
		reqs.add_child(chip("Cấp %d" % req_lv, T.C_GREEN if ok else T.C_RED))
	if not school.is_empty():
		var ok2 := str(pl.get("school", "")) == school or str(Data.school(str(pl.get("school", ""))).get("base", "")) == school
		reqs.add_child(chip(school_name(school), T.C_GREEN if ok2 else T.C_RED))
	if reqs.get_child_count() > 0: body.add_child(reqs)
	for line in item_stat_lines(d):
		body.add_child(T.label(line, T.FS_S, T.C_GREEN))
	if compare:
		var cmp := compare_with_equipped(d)
		if not cmp.is_empty():
			body.add_child(hsep())
			body.add_child(T.label("So với đang mặc", 12, T.C_MUTED, true))
			for c in cmp:
				var dv: float = c[1]
				var shown := ("%d" % int(absf(dv))) if is_equal_approx(absf(dv), roundf(absf(dv))) else ("%.1f" % absf(dv))
				body.add_child(T.label("%s %s%s %s" % ["▲" if dv > 0 else "▼", shown, "%" if bool(c[2]) else "", str(c[0])], T.FS_S, T.C_GREEN if dv > 0 else T.C_RED, true))
	if not str(d.get("desc", "")).is_empty():
		body.add_child(T.label(str(d["desc"]), T.FS_S, T.C_MUTED))
	if d.has("price"):
		body.add_child(T.label("Giá bán: %s xu" % fmt_num(int(d["price"])), T.FS_S, T.C_GOLD))
	return box

## Thẻ ngang (hàng danh sách): icon trái, 2 dòng chữ, nút phải (tuỳ chọn).
static func list_row(icon_node: Control, title: String, subtitle: String = "", title_color: Color = T.C_TEXT) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	if icon_node: h.add_child(icon_node)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	col.add_theme_constant_override("separation", 0)
	h.add_child(col)
	col.add_child(T.label(title, T.FS_M, title_color, true))
	if not subtitle.is_empty(): col.add_child(T.label(subtitle, T.FS_S, T.C_MUTED))
	return h

static func card_row(inner: Control) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", T.UISkin.card(8))
	p.add_child(inner)
	return p

static func slot_tile(title: String, subtitle: String, iid: String, selected: bool, cb: Callable) -> Button:
	var b := T.button("", Vector2(0, 76))
	var sb: StyleBox = T.UISkin.tab(selected)
	b.add_theme_stylebox_override("normal", sb)
	b.add_theme_stylebox_override("hover", sb)
	var h := HBoxContainer.new()
	h.set_anchors_preset(Control.PRESET_FULL_RECT)
	h.offset_left = 8; h.offset_right = -8
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_theme_constant_override("separation", 8)
	if not iid.is_empty():
		var ic := item_icon(iid, 44)
		ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(ic)
	var col := VBoxContainer.new()
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 0)
	h.add_child(col)
	var t1 := T.label(title, T.FS_S, T.C_MUTED)
	t1.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(t1)
	var t2 := T.label(subtitle, T.FS_S, T.C_TEXT, true)
	t2.mouse_filter = Control.MOUSE_FILTER_IGNORE
	t2.max_lines_visible = 2
	t2.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	col.add_child(t2)
	b.add_child(h)
	if cb.is_valid(): b.pressed.connect(cb)
	return b


## Hàng danh sách chung có glyph (emoji/chữ) thay icon: glyph | tiêu đề + phụ đề | chữ phải. Chạm để chọn.
static func glyph_row(glyph: String, title: String, subtitle: String, right_text: String, selected: bool, cb: Callable, title_color: Color = T.C_TEXT) -> Button:
	var b := T.button("", Vector2(0, 52))
	var normal: StyleBox = T.UISkin.card(0)
	var sel: StyleBox = T.UISkin.tab(true)
	b.add_theme_stylebox_override("normal", sel if selected else normal)
	b.add_theme_stylebox_override("hover", sel)
	b.add_theme_stylebox_override("pressed", sel)
	var h := HBoxContainer.new()
	h.set_anchors_preset(Control.PRESET_FULL_RECT)
	h.offset_left = 10; h.offset_right = -10
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_theme_constant_override("separation", 10)
	var g := T.label(glyph, 26, T.C_TEXT)
	g.autowrap_mode = TextServer.AUTOWRAP_OFF
	g.custom_minimum_size = Vector2(34, 0)
	g.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	g.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	g.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(g)
	var col := VBoxContainer.new()
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 0)
	h.add_child(col)
	var t1 := T.label(title, T.FS_M, title_color, true)
	t1.autowrap_mode = TextServer.AUTOWRAP_OFF
	t1.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	t1.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(t1)
	if not subtitle.is_empty():
		var t2 := T.label(subtitle, 12, T.C_MUTED)
		t2.autowrap_mode = TextServer.AUTOWRAP_OFF
		t2.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		t2.mouse_filter = Control.MOUSE_FILTER_IGNORE
		col.add_child(t2)
	if not right_text.is_empty():
		var r := T.label(right_text, T.FS_S, T.C_GOLD, true)
		r.autowrap_mode = TextServer.AUTOWRAP_OFF
		r.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		r.mouse_filter = Control.MOUSE_FILTER_IGNORE
		h.add_child(r)
	b.add_child(h)
	if cb.is_valid(): b.pressed.connect(cb)
	return b

## Ô kỹ năng trên thanh: emoji + số ô.
static func skill_cell(glyph: String, num: int, selected: bool, cb: Callable) -> Button:
	var b := T.button("", Vector2(CELL, CELL))
	var normal: StyleBox = T.UISkin.round_button(int(CELL), "normal", false)
	var sel: StyleBox = T.UISkin.round_button(int(CELL), "normal", true)
	b.add_theme_stylebox_override("normal", sel if selected else normal)
	b.add_theme_stylebox_override("hover", sel)
	b.add_theme_stylebox_override("pressed", sel)
	var g := T.label(glyph if not glyph.is_empty() else "·", 26, T.C_TEXT if not glyph.is_empty() else T.C_MUTED)
	g.autowrap_mode = TextServer.AUTOWRAP_OFF
	g.set_anchors_preset(Control.PRESET_FULL_RECT)
	g.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	g.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	g.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(g)
	var n := T.hud_label(str(num), 11, T.C_GOLD, true)
	n.offset_left = 8; n.offset_top = 2
	n.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(n)
	if cb.is_valid(): b.pressed.connect(cb)
	return b
