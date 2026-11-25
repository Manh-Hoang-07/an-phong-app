extends Control
## Biểu tượng kỹ năng / class VẼ BẰNG CODE (thay emoji).
## Lý do: emoji không có trong font đóng gói nên Godot phải nạp font emoji của hệ thống;
## trên iOS (Apple Color Emoji) việc này làm app treo/crash khi mở danh sách kỹ năng.
## Dữ liệu icon dạng emoji được đổi thành token "@họ" khi nạp (Data._fix_icons).

const FAMILY_EMOJI := {
	"blade": "⚔🗡🔪🪓🔨🔩",
	"shield": "🛡🔰🕶🪨💎",
	"flame": "🔥🌋☄🐉🐲😈",
	"bolt": "⚡💥",
	"ice": "🧊❄🌬",
	"wind": "💨🌪🌀🦘🦅🐂",
	"star": "🌟✨🌠💫✴🌌🌈🔆☀🌅🌄☯🔱🌼🪄",
	"drop": "💧🌊🌧☔",
	"heal": "💚🌿🕊🙏👼😇",
	"moon": "🌙🌑🌫🕳",
	"skull": "💀☠👻👤👥🩸📜📕",
	"bow": "🏹🎯📢📣",
	"orb": "🔷🔮💠🔗⛓⚙🏰🏯⚖🕸🪤",
	"paw": "🐾",
}
const FAMILY_COLOR := {
	"blade": Color("e8edf5"), "shield": Color("6fb4ff"), "flame": Color("ff8a3d"), "bolt": Color("ffe14d"),
	"ice": Color("8ee6ff"), "wind": Color("9fe8d0"), "star": Color("ffd96b"), "drop": Color("5fb0ff"),
	"heal": Color("6fe39a"), "moon": Color("b79cff"), "skull": Color("d7c9ff"), "bow": Color("e3c07a"),
	"orb": Color("7fa6ff"), "paw": Color("f0b27a"),
}

const SkillIcons = preload("res://src/ui/SkillIcons.gd")

static var _lookup: Dictionary = {}

## Emoji (hoặc token đã có) -> token "@họ". Rỗng -> "".
static func token_of(icon: String) -> String:
	if icon.begins_with("@"): return icon
	if _lookup.is_empty():
		for fam in FAMILY_EMOJI.keys():
			var s: String = FAMILY_EMOJI[fam]
			for i in range(s.length()): _lookup[s.unicode_at(i)] = fam
	for i in range(icon.length()):
		var cp := icon.unicode_at(i)
		if cp == 0xFE0F: continue
		if _lookup.has(cp): return "@" + str(_lookup[cp])
	return "@star" if not icon.is_empty() else ""

## Thứ tự của từng kỹ năng trong họ biểu tượng của nó (đánh số theo thứ tự trong dữ liệu).
static var _fam_idx: Dictionary = {}

static func _build_fam_idx() -> void:
	var count: Dictionary = {}
	for k in Data.SKILLS.keys():
		var d: Variant = Data.SKILLS[k]
		var ic := str((d as Dictionary).get("icon", "@star")) if typeof(d) == TYPE_DICTIONARY else "@star"
		var fam := token_of(ic).split(":")[0].substr(1)
		if fam.is_empty(): fam = "star"
		var n := int(count.get(fam, 0))
		_fam_idx[str(k)] = n
		count[fam] = n + 1

## Token glyph riêng cho từng kỹ năng: "@họ:số".
## Số = thứ tự của kỹ năng trong họ -> mỗi kỹ năng một cặp (sắc độ, họa tiết viền) khác nhau, không trùng ảnh.
static func skill_token(sid: String, icon_token: String) -> String:
	if sid.is_empty(): return icon_token
	var sk := SkillIcons.token_of_skill(sid)
	if not sk.is_empty(): return sk
	var fam := "star"
	if icon_token.begins_with("@"):
		var parts := icon_token.split(":")
		fam = parts[0].substr(1)
	if _fam_idx.is_empty(): _build_fam_idx()
	var k := 0
	if _fam_idx.has(sid):
		k = int(_fam_idx[sid])
	else:
		for i in range(sid.length()): k = (k * 31 + sid.unicode_at(i)) & 0x7FFFFFFF
		k = k % 40
	return "@%s:%d" % [fam, k]

## Chữ thường (không phải token): bỏ ký tự ngoài font để không kích hoạt font hệ thống.
static func clean(text: String) -> String:
	var out := ""
	for i in range(text.length()):
		var cp := text.unicode_at(i)
		if cp < 0x250 or (cp >= 0x1E00 and cp <= 0x1EFF) or (cp >= 0x2010 and cp <= 0x2027):
			out += text.substr(i, 1)
		else:
			match cp:
				0x2713, 0x2714: out += "+"
				0x2715, 0x2716: out += "x"
				0x25CB, 0x25CF: out += "o"
				0x25B2: out += "+"
				0x25BC: out += "-"
				0x2192: out += ">"
				0x2605, 0x2726, 0x25C6: out += "*"
				_: pass
	return out.strip_edges() if out.length() != text.length() else out

## Tạo node hiển thị glyph: token "@họ" -> hình vẽ, ngược lại -> Label sạch.
static func make(glyph: String, size: float, color: Color = Color.WHITE, bold: bool = false, framed: bool = false) -> Control:
	if glyph.begins_with("@"):
		var g = load("res://src/ui/GlyphArt.gd").new()
		var parts := glyph.split(":")
		g.fam = parts[0].substr(1)
		g.variant = int(parts[1]) if parts.size() > 1 else 0
		g.framed = framed
		g.custom_minimum_size = Vector2(size, size)
		g.size = Vector2(size, size)
		g.mouse_filter = Control.MOUSE_FILTER_IGNORE
		return g
	var T = load("res://src/ui/UITheme.gd")
	var l: Label = T.label(clean(glyph), int(size * 0.85), color, bold)
	l.autowrap_mode = TextServer.AUTOWRAP_OFF
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.custom_minimum_size = Vector2(size, size)
	return l

var fam := "star":
	set(v):
		fam = v
		queue_redraw()
var variant: int = 0:
	set(v):
		variant = v
		queue_redraw()
## Có khung: ô vuông bo góc tối, viền theo màu họ, quầng sáng sau biểu tượng (kiểu thẻ kỹ năng trên web).
var framed := false
var rot := 0.0
var rot_c := 1.0
var rot_s := 0.0
var tint := Color(0, 0, 0, 0)   # alpha 0 -> dùng màu của họ

func _ready() -> void:
	resized.connect(queue_redraw)
	call_deferred("queue_redraw")

func _draw() -> void:
	if size.x < 4.0 or size.y < 4.0: return
	var c := size * 0.5
	var s := minf(size.x, size.y) * 0.5 * 0.86
	var col: Color = tint if tint.a > 0.0 else FAMILY_COLOR.get(fam, SkillIcons.COLORS.get(fam, Color.WHITE))
	if variant > 0:
		col.h = fposmod(col.h + (float(variant % 8) - 3.5) * 0.03, 1.0)
	if framed:
		var bg := StyleBoxFlat.new()
		bg.bg_color = Color(col.r * 0.12 + 0.04, col.g * 0.12 + 0.045, col.b * 0.14 + 0.07, 1.0)
		bg.border_color = Color(col.r * 0.75, col.g * 0.75, col.b * 0.75, 0.9)
		bg.set_border_width_all(maxi(1, int(size.x * 0.045)))
		bg.set_corner_radius_all(int(size.x * 0.22))
		bg.shadow_color = Color(col.r, col.g, col.b, 0.28)
		bg.shadow_size = int(size.x * 0.08)
		draw_style_box(bg, Rect2(Vector2.ZERO, size))
		draw_circle(c, s * 0.82, Color(col.r, col.g, col.b, 0.13))
		draw_circle(c, s * 0.55, Color(col.r, col.g, col.b, 0.12))
		draw_arc(c, s * 0.95, PI * 1.1, PI * 1.6, 12, Color(1, 1, 1, 0.22), maxf(1.0, s * 0.07), true)
		s *= 0.78
	var dark := Color(col.r * 0.35, col.g * 0.35, col.b * 0.4, 0.9)
	var lw := maxf(1.5, s * 0.16)
	if SkillIcons.COLORS.has(fam):
		SkillIcons.draw(self, fam, c, s, col, lw)
		return
	rot = deg_to_rad(float(variant - 2) * 8.0) if variant > 0 else 0.0
	rot_c = cos(rot)
	rot_s = sin(rot)
	match fam:
		"blade":
			draw_line(_pt(Vector2(-0.62, 0.62), c, s), _pt(Vector2(0.72, -0.72), c, s), col, lw * 1.3, true)
			draw_line(_pt(Vector2(-0.52, 0.52), c, s), _pt(Vector2(0.16, -0.16), c, s), Color("e0b34a"), lw, true)
			draw_line(_pt(Vector2(-0.62, 0.62), c, s), _pt(Vector2(-0.84, 0.84), c, s), Color("e0b34a"), lw * 1.2, true)
		"shield":
			var p := PackedVector2Array([Vector2(-0.62, -0.68), Vector2(0.62, -0.68), Vector2(0.62, 0.1), Vector2(0, 0.86), Vector2(-0.62, 0.1)])
			draw_colored_polygon(_xf(p, c, s), dark)
			draw_polyline(_xf(p + PackedVector2Array([p[0]]), c, s), col, lw * 0.8, true)
			draw_line(_pt(Vector2(0, -0.5), c, s), _pt(Vector2(0, 0.55), c, s), col, lw * 0.6, true)
		"flame":
			var p2 := PackedVector2Array([Vector2(0.05, -0.92), Vector2(0.5, -0.25), Vector2(0.58, 0.3), Vector2(0.3, 0.78), Vector2(-0.3, 0.78), Vector2(-0.58, 0.3), Vector2(-0.42, -0.12), Vector2(-0.12, -0.3)])
			draw_colored_polygon(_xf(p2, c, s), col)
			var p3 := PackedVector2Array([Vector2(0.02, -0.2), Vector2(0.28, 0.25), Vector2(0.16, 0.66), Vector2(-0.16, 0.66), Vector2(-0.28, 0.25)])
			draw_colored_polygon(_xf(p3, c, s), Color("fff0a8"))
		"bolt":
			var p4 := PackedVector2Array([Vector2(0.2, -0.92), Vector2(-0.5, 0.08), Vector2(-0.04, 0.08), Vector2(-0.22, 0.92), Vector2(0.52, -0.16), Vector2(0.06, -0.16)])
			draw_colored_polygon(_xf(p4, c, s), col)
		"ice":
			for k in range(3):
				var a := PI * float(k) / 3.0
				var d := Vector2(cos(a), sin(a)) * 0.85
				draw_line(_pt(-d, c, s), _pt(d, c, s), col, lw * 0.7, true)
			draw_circle(c, s * 0.2, Color.WHITE)
		"wind":
			draw_arc(_pt(Vector2(0, -0.45), c, s), s * 0.42, PI, TAU + 0.6, 14, col, lw, true)
			draw_arc(c, s * 0.46, PI, TAU + 0.3, 14, col, lw, true)
			draw_arc(_pt(Vector2(0, 0.45), c, s), s * 0.4, PI, TAU + 0.8, 14, col, lw, true)
		"star":
			var p5 := PackedVector2Array([Vector2(0, -0.95), Vector2(0.2, -0.22), Vector2(0.95, 0), Vector2(0.2, 0.22), Vector2(0, 0.95), Vector2(-0.2, 0.22), Vector2(-0.95, 0), Vector2(-0.2, -0.22)])
			draw_colored_polygon(_xf(p5, c, s), col)
			draw_circle(c, s * 0.14, Color.WHITE)
		"drop":
			draw_circle(_pt(Vector2(0, 0.25), c, s), s * 0.52, col)
			draw_colored_polygon(_xf(PackedVector2Array([Vector2(0, -0.9), Vector2(0.48, 0.12), Vector2(-0.48, 0.12)]), c, s), col)
			draw_circle(_pt(Vector2(-0.16, 0.2), c, s), s * 0.12, Color(1, 1, 1, 0.7))
		"heal":
			var t := s * 0.3
			draw_rect(Rect2(c.x - t, c.y - s * 0.82, t * 2.0, s * 1.64), col)
			draw_rect(Rect2(c.x - s * 0.82, c.y - t, s * 1.64, t * 2.0), col)
		"moon":
			draw_arc(c, s * 0.58, 0.9, TAU - 0.9, 22, col, s * 0.42, true)
		"skull":
			draw_circle(_pt(Vector2(0, -0.12), c, s), s * 0.62, col)
			draw_rect(Rect2(c.x - s * 0.36, c.y + s * 0.3, s * 0.72, s * 0.5), col)
			draw_circle(_pt(Vector2(-0.24, -0.14), c, s), s * 0.16, dark)
			draw_circle(_pt(Vector2(0.24, -0.14), c, s), s * 0.16, dark)
		"bow":
			draw_arc(_pt(Vector2(-0.2, 0), c, s), s * 0.8, -1.2, 1.2, 16, col, lw, true)
			draw_line(_pt(Vector2(-0.2 + cos(-1.2) * 0.8, sin(-1.2) * 0.8), c, s), _pt(Vector2(-0.2 + cos(1.2) * 0.8, sin(1.2) * 0.8), c, s), Color(col.r, col.g, col.b, 0.6), lw * 0.4, true)
			draw_line(_pt(Vector2(-0.4, 0), c, s), _pt(Vector2(0.85, 0), c, s), Color.WHITE, lw * 0.6, true)
			draw_colored_polygon(_xf(PackedVector2Array([Vector2(0.95, 0), Vector2(0.62, -0.16), Vector2(0.62, 0.16)]), c, s), Color.WHITE)
		"orb":
			draw_circle(c, s * 0.78, dark)
			draw_arc(c, s * 0.78, 0, TAU, 28, col, lw * 0.8, true)
			draw_circle(c, s * 0.32, col)
		"paw":
			draw_circle(_pt(Vector2(0, 0.25), c, s), s * 0.42, col)
			for k in range(4):
				var a2 := -2.4 + float(k) * 0.55
				draw_circle(_pt(Vector2(cos(a2), sin(a2)) * 0.62 + Vector2(0, -0.05), c, s), s * 0.17, col)
		_:
			draw_colored_polygon(_xf(PackedVector2Array([Vector2(0, -0.9), Vector2(0.6, 0), Vector2(0, 0.9), Vector2(-0.6, 0)]), c, s), col)
	_decor(c, s, col)

## Họa tiết phụ theo số thứ tự (0..4) để hai kỹ năng cùng họ, cùng sắc độ vẫn khác nhau.
func _decor(c: Vector2, s: float, col: Color) -> void:
	var deco := (variant / 8) % 5 if variant > 0 else 0
	var soft := Color(col.r, col.g, col.b, 0.8)
	match deco:
		1: draw_arc(c, s * 1.08, 0.0, TAU, 36, Color(col.r, col.g, col.b, 0.55), maxf(1.2, s * 0.09), true)
		2:
			draw_circle(c + Vector2(-s * 0.98, -s * 0.98), s * 0.11, soft)
			draw_circle(c + Vector2(s * 0.98, -s * 0.98), s * 0.11, soft)
		3:
			for dx in [-0.4, 0.0, 0.4]:
				draw_circle(c + Vector2(float(dx) * s, s * 1.1), s * 0.08, soft)
		4:
			draw_colored_polygon(PackedVector2Array([c + Vector2(0, -s * 1.2), c + Vector2(s * 0.14, -s * 1.02), c + Vector2(0, -s * 0.86), c + Vector2(-s * 0.14, -s * 1.02)]), soft)

func _xf(p: PackedVector2Array, c: Vector2, s: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for v in p: out.append(_pt(v, c, s))
	return out

## Mot diem: c + v*s, xoay quanh tam c theo bien the.
func _pt(v: Vector2, c: Vector2, s: float) -> Vector2:
	var q := v * s
	if rot != 0.0:
		q = Vector2(q.x * rot_c - q.y * rot_s, q.x * rot_s + q.y * rot_c)
	return c + q