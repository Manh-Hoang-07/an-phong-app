extends RefCounted
## Hình đạn bay RIÊNG theo từng kỹ năng bắn (thay quả cầu cam chung). Vẽ lên Proj (Node2D): +x = hướng bay, gốc = đầu đạn.
## s cần có: _a(al), _k(al), _mix(u, al) và các hàm draw_*; t = giây kể từ lúc bắn.
const E := preload("res://src/world/fx/FxSkill_Swordsman.gd")

## id kỹ năng -> kiểu đạn. Kiểu "arrow:<style>:<len>" là mũi tên, các kiểu khác xem draw().
const SHAPES := {
	# --- cung thủ
	"hl1": "arrow:fire:58", "hl10": "arrow:holy:92", "hl11": "arrow:fire:44", "hl2": "arrow:plain:48", "hl6": "arrow:wind:54",
	"hl8": "arrow:ice:54", "hl4": "arrow:wind:46", "xa30": "arrow:plain:44", "hl9": "arrow:plain:42", "ulCung1": "arrow:star:72", "xa25": "arrow:seal:54", "xa27": "arrow:bolt:50",
	"xa32": "arrow:steel:62", "xa37": "arrow:plain:46", "xa42": "arrow:spirit:58",
	# --- sát thủ
	"av30": "dagger:shadow:38", "av27": "dagger:shadow:30", "st9": "shuriken:shadow:13", "av37": "dagger:shadow:28", "st5": "dagger:steel:26", "st8": "shuriken:poison:15", "ulSat1": "dagger:blood:36",
	# --- kiếm sĩ
	"ks38": "river", "pa11": "crossqi",
	# --- tử linh
	"nl1": "skull", "nl8": "chain",
	# --- pháp sư
	"ps25": "twinbolt", "ps27": "fireball:big", "tn8": "fireball:small", "tn1": "icewave", "tn9": "bolt",
	"ps42": "arcane", "tn10": "elembolt",
	# --- trị liệu
	"tg27": "lightray", "tl2": "holywave", "tl30": "arrow:holy:66", "tl9": "seal",
	# --- triệu hồi
	"th1": "wisp", "th8": "spritebird", "th10": "spritedragon",
	# --- toàn năng
	"vn6": "palm",
	# --- tanker
	"hv25": "disc",
}

## Sprite hoạt hình có sẵn của game (assets/pets) dùng làm "con vật" của kỹ năng. Proj dựng một Sprite2D con (hòa trộn thường)
## và tô lại theo màu kỹ năng bằng shader; phần ánh sáng (quầng, vệt, hạt) do FxProj.draw vẽ phía sau.
const SPRITES := {
	"th10": {"file": "dragon-run", "fw": 454, "fh": 249, "n": 8, "row": 0, "rate": 14.0, "scale": 0.52, "off": Vector2(34, -8), "dark": 0.22, "lum": 0.14, "mix": 0.7, "ghosts": 0, "rim": 0.9, "glow": 0.55},
	"th8": {"file": "bat-run", "fw": 150, "fh": 147, "n": 4, "row": 0, "rate": 12.0, "scale": 0.8, "off": Vector2(8, 0), "dark": 0.3, "lum": 0.45, "mix": 0.62, "flip": true, "ghosts": 0, "rim": 0.8, "glow": 0.5},
}

static func sprite_def(id: String) -> Dictionary:
	return SPRITES.get(id, {})

static var _shader: Shader = null
## Shader tô lại sprite: điểm tối -> màu tối của kỹ năng, điểm sáng -> màu sáng, giữ nguyên alpha và chi tiết.
static func sprite_shader() -> Shader:
	if _shader == null:
		_shader = Shader.new()
		_shader.code = "shader_type canvas_item;\nuniform vec4 tint_dark : source_color = vec4(0.1, 0.2, 0.3, 1.0);\nuniform vec4 tint_light : source_color = vec4(0.6, 0.9, 1.0, 1.0);\nuniform vec4 rim_color : source_color = vec4(0.8, 1.0, 1.0, 1.0);\nuniform float mix_amt = 0.85;\nuniform float lum_scale = 0.3;\nuniform float alpha = 0.95;\nuniform float rim_amt = 0.8;\nuniform float glow_amt = 0.5;\nvoid fragment() {\n\tvec4 c = texture(TEXTURE, UV);\n\tvec2 px = TEXTURE_PIXEL_SIZE * 2.0;\n\tfloat n = texture(TEXTURE, UV + vec2(px.x, 0.0)).a + texture(TEXTURE, UV - vec2(px.x, 0.0)).a + texture(TEXTURE, UV + vec2(0.0, px.y)).a + texture(TEXTURE, UV - vec2(0.0, px.y)).a;\n\tn /= 4.0;\n\tfloat l = dot(c.rgb, vec3(0.299, 0.587, 0.114));\n\tvec3 g = mix(tint_dark.rgb, tint_light.rgb, smoothstep(0.0, lum_scale, l));\n\tvec3 col = mix(c.rgb, g, mix_amt);\n\tfloat edge = (1.0 - n) * c.a;\n\tcol = mix(col, rim_color.rgb, clamp(edge * rim_amt * 1.6, 0.0, 1.0));\n\tfloat outer = (1.0 - c.a) * n * glow_amt;\n\tCOLOR = vec4(mix(col, rim_color.rgb, (1.0 - c.a)), max(c.a * alpha, outer));\n}\n"
	return _shader

static func has(id: String) -> bool:
	return SHAPES.has(id)

# ---- tiện ích (gọi sang bộ nét của FxSkill_Swordsman)
static func A(s, al: float) -> Color: return E.A(s, al)
static func K(s, al: float) -> Color: return E.K(s, al)
static func M(s, u: float, al: float) -> Color: return E.M(s, u, al)
static func L(s, a: Vector2, b: Vector2, c: Color, w: float = 1.0) -> void: E.L(s, a, b, c, w)
static func PL(s, p: PackedVector2Array, c: Color, w: float = 1.0) -> void: E.PL(s, p, c, w)
static func CI(s, p: Vector2, r: float, c: Color) -> void: E.CI(s, p, r, c)
static func P(s, p: PackedVector2Array, c: Color) -> void: E.P(s, p, c)
static func PG(s, p: PackedVector2Array, c: PackedColorArray) -> void: E.PG(s, p, c)

## Vòng elip vẽ bằng điểm (KHÔNG đổi draw_set_transform nên dùng được khi đạn đang vẽ trong phép biến đổi của nơi gọi).
static func _ering(s, c: Vector2, rx: float, ry: float, col: Color, w: float = 1.0, rot: float = 0.0) -> void:
	if rx < 0.5 or ry < 0.5: return
	var pts := PackedVector2Array()
	var cr := cos(rot)
	var sr := sin(rot)
	for i in range(33):
		var a := TAU * float(i) / 32.0
		var v := Vector2(cos(a) * rx, sin(a) * ry)
		pts.append(c + Vector2(v.x * cr - v.y * sr, v.x * sr + v.y * cr))
	PL(s, pts, col, w)

## Vệt đuôi mờ dần: từ đầu (x=0) ra sau (x=-len), rộng w.
static func trail(s, ln: float, w: float, al: float, core: bool = false) -> void:
	var cA := A(s, al)
	var c0 := A(s, 0.0)
	PG(s, PackedVector2Array([Vector2(0, -w), Vector2(0, w), Vector2(-ln, w * 0.15), Vector2(-ln, -w * 0.15)]), PackedColorArray([cA, cA, c0, c0]))
	if core:
		var kA := K(s, al)
		PG(s, PackedVector2Array([Vector2(0, -w * 0.4), Vector2(0, w * 0.4), Vector2(-ln * 0.7, 0.0)]), PackedColorArray([kA, kA, K(s, 0.0)]))

static func draw(s, id: String, t: float) -> bool:
	var spec: String = str(SHAPES.get(id, ""))
	if spec == "": return false
	var parts := spec.split(":")
	match parts[0]:
		"arrow": _arrow(s, id, t, parts[1], float(parts[2]) * 1.22)
		"dagger": _dagger(s, id, t, parts[1], float(parts[2]))
		"shuriken": _shuriken(s, id, t, float(parts[2]))
		"river": _river(s, t)
		"crossqi": _crossqi(s, t)
		"skull": _skull(s, t)
		"chain": _chain(s, t)
		"snake": _snake(s, t)
		"twinbolt": _twinbolt(s, t)
		"fireball": _fireball(s, t, parts[1] == "big")
		"icewave": _icewave(s, t)
		"bolt": _bolt(s, t)
		"arcane": _arcanebolt(s, t)
		"elembolt": _elembolt(s, t)
		"lightray": _lightray(s, t)
		"holywave": _holywave(s, t)
		"seal": _seal(s, t)
		"wisp": _wisp(s, t)
		"bird": _bird(s, t)
		"dragon": _dragon(s, t)
		"spritedragon": _spritelight(s, t, 150.0, 40.0)
		"spritebird": _spritelight(s, t, 90.0, 22.0)
		"palm": _palm(s, t)
		"disc": _disc(s, t)
		_: return false
	return true

# ============================================================ MŨI TÊN
## Mũi tên chi tiết: thân, đầu có ngạnh, lông đuôi; hiệu ứng theo style.
static func _arrow(s, id: String, t: float, style: String, ln: float) -> void:
	var w := 3.0 + ln * 0.012
	var tail := -ln * 0.8
	var head := ln * 0.2
	var fl := sin(t * 40.0)
	# vệt/hiệu ứng riêng theo style (vẽ trước, nằm sau thân)
	match style:
		"fire":
			trail(s, ln * 1.8, 9.0, 0.75, true)
			for i in range(5):
				var u := fmod(t * 2.4 + float(i) * 0.2, 1.0)
				CI(s, Vector2(-ln * 0.5 - u * ln, (E.rnd(i, 3) - 0.5) * 12.0), 3.4 * (1.0 - u) + 0.8, K(s, 0.9 * (1.0 - u)))
			E.glow(s, Vector2(head, 0), 14.0, 0.6)
		"ice":
			trail(s, ln * 1.6, 8.0, 0.6, true)
			for i in range(4):
				var u := fmod(t * 1.8 + float(i) * 0.25, 1.0)
				var p := Vector2(-ln * 0.4 - u * ln * 1.1, (E.rnd(i, 4) - 0.5) * 16.0)
				E.star(s, p, 3.0 * (1.0 - u) + 1.0, 1.0 - u, 4)
			E.glow(s, Vector2(head, 0), 13.0, 0.5)
		"holy":
			trail(s, ln * 1.7, 7.0, 0.55, true)
			E.glow(s, Vector2(head, 0), 18.0, 0.65)
			_ering(s, Vector2(head * 0.2, 0), 5.0, 11.0 + 2.0 * fl, A(s, 0.7), 1.6)
			_ering(s, Vector2(-ln * 0.2, 0), 4.0, 8.0, K(s, 0.5), 1.2)
			for k in range(3):
				var yy := (float(k) - 1.0) * 6.0
				L(s, Vector2(tail, yy), Vector2(tail - 22.0 - 8.0 * float(k), yy * 1.8), A(s, 0.5), 1.6)
		"wind":
			for k in range(2):
				var pts := PackedVector2Array()
				for i in range(24):
					var u := float(i) / 23.0
					pts.append(Vector2(-u * ln * 1.5, sin(u * 14.0 - t * 30.0 + PI * float(k)) * 7.0 * (0.4 + u)))
				PL(s, pts, A(s, 0.55), 2.2)
			trail(s, ln * 1.2, 5.0, 0.4)
		"bolt":
			trail(s, ln * 2.2, 5.0, 0.55, true)
			for k in range(2):
				var pts := PackedVector2Array()
				for i in range(8):
					pts.append(Vector2(-float(i) * ln * 0.18, (E.rnd(i + int(t * 22.0), k) - 0.5) * 16.0))
				PL(s, pts, K(s, 0.85), 1.4)
			E.flare(s, Vector2(head, 0), 9.0, 0.8)
		"star":
			trail(s, ln * 2.0, 8.0, 0.65, true)
			for i in range(6):
				var u := fmod(t * 1.5 + float(i) / 6.0, 1.0)
				E.star(s, Vector2(-ln * 0.3 - u * ln * 1.5, (E.rnd(i, 5) - 0.5) * 20.0), 4.0 * (1.0 - u) + 1.0, 1.0 - u, 5)
			E.glow(s, Vector2(head, 0), 20.0, 0.7)
		"steel":
			trail(s, ln * 1.0, 4.0, 0.4)
			for i in range(5):
				var x := head - 4.0 - float(i) * 5.0
				L(s, Vector2(x, -5.0 + float(i) * 0.6), Vector2(x - 5.0, 5.0 - float(i) * 0.6), K(s, 0.9), 1.6)
		"spirit":
			for i in range(8):
				var u := float(i) / 8.0
				CI(s, Vector2(-ln * 0.4 - u * ln * 1.3, sin(t * 12.0 + float(i)) * 6.0 * u), 6.0 * (1.0 - u), A(s, 0.5 * (1.0 - u)))
			E.glow(s, Vector2(head, 0), 15.0, 0.5)
		"seal":
			E.glow(s, Vector2(head, 0), 14.0, 0.45)
			_ering(s, Vector2(ln * 0.05, 0), 4.0, 14.0, A(s, 0.8), 1.8, 0.0)
			for k in range(6):
				var a := TAU * float(k) / 6.0 + t * 6.0
				CI(s, Vector2(ln * 0.05 + cos(a) * 3.0, sin(a) * 14.0), 1.6, K(s, 0.9))
			trail(s, ln * 1.2, 6.0, 0.45)
		_:
			trail(s, ln * 1.2, 4.0, 0.35)
			for i in range(3):
				var y := (float(i) - 1.0) * 5.0
				L(s, Vector2(tail - 10.0, y), Vector2(tail - 34.0 - 8.0 * float(i), y), A(s, 0.3), 1.2)
	# thân mũi tên
	var shaft_c := M(s, 0.6, 1.0)
	L(s, Vector2(tail, 0), Vector2(head, 0), shaft_c, w)
	L(s, Vector2(tail, -w * 0.3), Vector2(head, -w * 0.3), K(s, 0.5), 1.0)
	# đầu mũi tên có ngạnh
	var hw := w * 1.9
	P(s, PackedVector2Array([Vector2(head + ln * 0.2, 0), Vector2(head - 2.0, -hw), Vector2(head + 2.0, -hw * 0.35), Vector2(head - 5.0, 0), Vector2(head + 2.0, hw * 0.35), Vector2(head - 2.0, hw)]), K(s, 0.95))
	L(s, Vector2(head - 2.0, 0), Vector2(head + ln * 0.2, 0), A(s, 0.9), 1.0)
	# lông đuôi 3 cánh
	for k in range(3):
		var x := tail + 2.0 + float(k) * 5.0
		P(s, PackedVector2Array([Vector2(x, 0), Vector2(x - 8.0, -hw * 1.3), Vector2(x - 3.0, 0)]), A(s, 0.9))
		P(s, PackedVector2Array([Vector2(x, 0), Vector2(x - 8.0, hw * 1.3), Vector2(x - 3.0, 0)]), A(s, 0.7))

# ============================================================ PHI ĐAO / PHI TIÊU
static func _dagger(s, id: String, t: float, style: String, ln: float) -> void:
	var spin := t * 18.0
	# vệt đuôi theo style
	match style:
		"shadow":
			for i in range(7):
				var u := float(i) / 7.0
				CI(s, Vector2(-8.0 - u * 46.0, sin(t * 14.0 + float(i)) * 3.0 * u), 6.0 * (1.0 - u) + 1.0, A(s, 0.4 * (1.0 - u)))
		"blood":
			trail(s, 54.0, 6.0, 0.55, true)
			for i in range(5):
				var u := fmod(t * 2.0 + float(i) * 0.2, 1.0)
				CI(s, Vector2(-10.0 - u * 40.0, 6.0 * (E.rnd(i, 1) - 0.5) + 14.0 * u * u), 2.2 * (1.0 - u) + 0.6, A(s, 0.9 * (1.0 - u)))
		_:
			trail(s, 40.0, 4.0, 0.35)
	# phi đao: lưỡi + tay cầm + vòng đuôi (xoay nhẹ quanh trục dọc để thấy khối)
	var sq := 0.55 + 0.45 * absf(cos(spin * 0.3))
	var hl := ln * 0.5
	P(s, PackedVector2Array([Vector2(hl, 0), Vector2(0, -4.0 * sq), Vector2(-hl * 0.25, 0), Vector2(0, 4.0 * sq)]), K(s, 0.95))
	P(s, PackedVector2Array([Vector2(hl, 0), Vector2(0, -4.0 * sq), Vector2(-hl * 0.25, 0)]), A(s, 0.7))
	L(s, Vector2(-hl * 0.25, 0), Vector2(-hl * 0.8, 0), M(s, 0.55, 1.0), 3.0)
	L(s, Vector2(-hl * 0.25, -5.0 * sq), Vector2(-hl * 0.25, 5.0 * sq), K(s, 0.9), 2.0)
	_ering(s, Vector2(-hl * 0.95, 0), 4.0, 4.0 * sq + 1.0, K(s, 0.9), 1.6)
	if style == "blood": E.glow(s, Vector2(hl, 0), 10.0, 0.4)

static func _shuriken(s, id: String, t: float, r: float) -> void:
	var a := t * 26.0
	for i in range(5):
		var u := float(i) / 5.0
		CI(s, Vector2(-6.0 - u * 30.0, sin(t * 16.0 + float(i)) * 3.0), 4.0 * (1.0 - u) + 0.8, A(s, 0.4 * (1.0 - u)))
	var pts := PackedVector2Array()
	for k in range(8):
		var an := a + TAU * float(k) / 8.0
		var rr := r if k % 2 == 0 else r * 0.38
		pts.append(Vector2(cos(an), sin(an)) * rr)
	P(s, pts, A(s, 0.95))
	var pts2 := PackedVector2Array()
	for k in range(8):
		var an2 := a + TAU * float(k) / 8.0
		var rr2 := r * 0.7 if k % 2 == 0 else r * 0.3
		pts2.append(Vector2(cos(an2), sin(an2)) * rr2)
	P(s, pts2, K(s, 0.7))
	CI(s, Vector2.ZERO, 3.0, Color(0.05, 0.1, 0.05, 0.9))
	CI(s, Vector2.ZERO, 1.4, K(s, 1.0))
	# giọt độc rơi
	for i in range(4):
		var u := fmod(t * 1.6 + float(i) * 0.25, 1.0)
		CI(s, Vector2(-8.0 - 18.0 * u, 4.0 + 18.0 * u * u), 2.4 * (1.0 - u) + 0.6, A(s, 0.9 * (1.0 - u)))

# ============================================================ KIẾM KHÍ
## Ks38: thân sông kiếm khí dài phía sau đầu đạn, có sóng/bọt/kiếm cưỡi sóng, đầu là lưỡi liềm.
static func _river(s, t: float) -> void:
	var n := 20
	var top := PackedVector2Array()
	var bot := PackedVector2Array()
	for i in range(n + 1):
		var u := float(i) / float(n)
		var x := -u * 260.0
		var w := 22.0 * (0.9 - 0.6 * u)
		var wv := sin(x * 0.05 - t * 14.0) * 6.0
		top.append(Vector2(x, -w + wv))
		bot.append(Vector2(x, w + wv * 0.7))
	for i in range(n):
		var a0 := 0.7 * (1.0 - float(i) / float(n))
		var a1 := 0.7 * (1.0 - float(i + 1) / float(n))
		PG(s, PackedVector2Array([top[i], top[i + 1], bot[i + 1], bot[i]]), PackedColorArray([A(s, a0), A(s, a1), A(s, a1 * 0.3), A(s, a0 * 0.3)]))
	PL(s, top, K(s, 0.7), 1.4)
	for b in range(3):
		var pts := PackedVector2Array()
		for i in range(n + 1):
			var x := -float(i) / float(n) * 240.0
			pts.append(Vector2(x, (float(b) - 1.0) * 8.0 + sin(x * 0.06 - t * 16.0 + float(b)) * 5.0))
		PL(s, pts, K(s, 0.55), 1.2)
	for i in range(4):
		E.sword(s, Vector2(-30.0 - 52.0 * float(i), sin(t * 12.0 + float(i) * 1.7) * 7.0), 0.0, 34.0, 6.0, 0.9 - 0.15 * float(i))
	E.swoosh(s, Vector2(-62.0, 0), 70.0, -0.95, 0.95, 1.0, 1.0, 30.0, 1.0, 1.15)
	E.flare(s, Vector2(8.0, 0), 12.0, 0.9)

## Pa11: hai lưỡi kiếm khí đứng + ngang giao nhau, hai luồng chéo, tàn ảnh.
static func _crossqi(s, t: float) -> void:
	for j in range(3, 0, -1):
		var f := 0.4 / float(j)
		E.swoosh(s, Vector2(-60.0 - 26.0 * float(j), 0), 60.0, -0.95, 0.95, 1.0, 1.0, 18.0, f)
	E.swoosh(s, Vector2(-56.0, 0), 62.0, -0.95, 0.95, 1.0, 1.0, 26.0, 1.0)
	s.draw_set_transform(Vector2(-30.0, 0), PI * 0.5, Vector2.ONE)
	E.swoosh(s, Vector2.ZERO, 50.0, -0.9, 0.9, 1.0, 1.0, 22.0, 0.95, 0.8)
	E.rst(s)
	E.cut(s, Vector2(-96.0, -44.0), Vector2(10.0, 26.0), 5.0, 0.9)
	E.cut(s, Vector2(-96.0, 44.0), Vector2(10.0, -26.0), 5.0, 0.9)
	E.flare(s, Vector2(-8.0, 0), 14.0, 0.9)

# ============================================================ TỬ LINH
static func _skull(s, t: float) -> void:
	for i in range(8):
		var u := float(i) / 8.0
		CI(s, Vector2(-14.0 - u * 50.0, sin(t * 14.0 + float(i)) * 6.0 * u), 8.0 * (1.0 - u) + 1.0, A(s, 0.45 * (1.0 - u)))
	E.glow(s, Vector2.ZERO, 26.0, 0.5)
	# sọ: hộp sọ tròn + hàm
	CI(s, Vector2(0, -2), 11.0, K(s, 0.92))
	P(s, PackedVector2Array([Vector2(-7, 5), Vector2(7, 5), Vector2(5, 12), Vector2(-5, 12)]), K(s, 0.85))
	CI(s, Vector2(-4, -3), 3.0, Color(0.02, 0.05, 0.02, 0.95))
	CI(s, Vector2(4, -3), 3.0, Color(0.02, 0.05, 0.02, 0.95))
	CI(s, Vector2(-4, -3), 1.4, A(s, 1.0))
	CI(s, Vector2(4, -3), 1.4, A(s, 1.0))
	P(s, PackedVector2Array([Vector2(0, 1), Vector2(-1.8, 4), Vector2(1.8, 4)]), Color(0.05, 0.08, 0.05, 0.9))
	for k in range(4):
		L(s, Vector2(-5.0 + float(k) * 3.3, 6), Vector2(-5.0 + float(k) * 3.3, 11), Color(0.05, 0.08, 0.05, 0.8), 1.0)
	# ngọn lửa ma sau đầu
	for k in range(3):
		E.flame(s, Vector2(-8.0 - 6.0 * float(k), -6.0 + 6.0 * float(k)), 24.0, 5.0, t, float(k), 0.7)

static func _chain(s, t: float) -> void:
	# sợi xích hồn: các mắt xích nối nhau uốn lượn, đầu là móc khoá
	var n := 9
	var prev := Vector2.ZERO
	for i in range(n):
		var x := -float(i) * 15.0
		var y := sin(t * 10.0 - float(i) * 0.8) * 7.0
		var p := Vector2(x, y)
		var rot := 0.0 if i % 2 == 0 else PI * 0.5
		_ering(s, p, 8.0 if i % 2 == 0 else 3.5, 3.6 if i % 2 == 0 else 6.0, K(s, 0.9 * (1.0 - float(i) / float(n) * 0.7)), 2.2)
		_ering(s, p, 8.0 if i % 2 == 0 else 3.5, 3.6 if i % 2 == 0 else 6.0, A(s, 0.4 * (1.0 - float(i) / float(n))), 5.0)
		prev = p
	E.glow(s, Vector2.ZERO, 22.0, 0.5)
	# móc xích
	P(s, PackedVector2Array([Vector2(16, 0), Vector2(4, -9), Vector2(4, 9)]), K(s, 0.95))
	CI(s, Vector2(0, 0), 4.0, A(s, 0.95))

# ============================================================ PHÁP SƯ
## Dải thân sinh vật dùng chung: pts (từ đầu ra đuôi), ws = nửa bề rộng từng điểm.
## Vẽ nhiều lớp: quầng ngoài, thân tô gradient ngang (mép tối -> sống lưng sáng -> bụng), viền sáng; trả về mảng pháp tuyến để vẽ chi tiết.
static func ribbon(s, pts: Array, ws: PackedFloat32Array, al: float = 1.0) -> Array:
	var n := pts.size()
	var nrm: Array = []
	for i in range(n):
		var a: Vector2 = pts[maxi(i - 1, 0)]
		var b: Vector2 = pts[mini(i + 1, n - 1)]
		var d := (a - b)
		if d.length() < 0.001: d = Vector2(1, 0)
		nrm.append(d.normalized().orthogonal())
	# quầng ngoài mờ
	var halo := PackedVector2Array()
	for i in range(n): halo.append(pts[i])
	PL(s, halo, A(s, 0.18 * al), ws[0] * 3.4)
	for i in range(n - 1):
		var fa := al * (1.0 - 0.55 * float(i) / float(n - 1))
		var fb := al * (1.0 - 0.55 * float(i + 1) / float(n - 1))
		var l0: Vector2 = (pts[i] as Vector2) + (nrm[i] as Vector2) * ws[i]
		var l1: Vector2 = (pts[i + 1] as Vector2) + (nrm[i + 1] as Vector2) * ws[i + 1]
		var r0: Vector2 = (pts[i] as Vector2) - (nrm[i] as Vector2) * ws[i]
		var r1: Vector2 = (pts[i + 1] as Vector2) - (nrm[i + 1] as Vector2) * ws[i + 1]
		var c0: Vector2 = (pts[i] as Vector2) + (nrm[i] as Vector2) * ws[i] * 0.25
		var c1: Vector2 = (pts[i + 1] as Vector2) + (nrm[i + 1] as Vector2) * ws[i + 1] * 0.25
		PG(s, PackedVector2Array([l0, l1, c1, c0]), PackedColorArray([A(s, 0.85 * fa), A(s, 0.85 * fb), M(s, 0.55, 0.95 * fb), M(s, 0.55, 0.95 * fa)]))
		PG(s, PackedVector2Array([c0, c1, r1, r0]), PackedColorArray([M(s, 0.55, 0.95 * fa), M(s, 0.55, 0.95 * fb), A(s, 0.55 * fb), A(s, 0.55 * fa)]))
	var le := PackedVector2Array()
	var re := PackedVector2Array()
	for i in range(n):
		le.append((pts[i] as Vector2) + (nrm[i] as Vector2) * ws[i])
		re.append((pts[i] as Vector2) - (nrm[i] as Vector2) * ws[i])
	PL(s, le, K(s, 0.8 * al), 1.3)
	PL(s, re, A(s, 0.7 * al), 1.1)
	return nrm

## Lôi Xà: thân dải uốn lượn có vảy hình thoi, gân điện sáng dọc lưng, hồ quang tách nhánh, đầu rắn đầy đủ (hàm, nanh, mắt dọc, lưỡi chẻ).
static func _snake(s, t: float) -> void:
	s.draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.45, 1.45))
	var n := 28
	var pts: Array = []
	var ws := PackedFloat32Array()
	for i in range(n):
		var u := float(i) / float(n - 1)
		var x := -6.0 - u * 112.0
		pts.append(Vector2(x, sin(u * 9.0 - t * 17.0) * (3.0 + 11.0 * u)))
		ws.append(7.2 * pow(1.0 - u, 0.75) + 0.9 + 1.4 * sin(minf(u * 3.0, 1.0) * PI * 0.5))
	var nrm: Array = ribbon(s, pts, ws, 0.78)
	# vảy hình thoi dọc lưng + vằn ngang
	for i in range(1, n - 2, 2):
		var pi: Vector2 = pts[i]
		var ni: Vector2 = nrm[i]
		var dv := ((pts[i - 1] as Vector2) - (pts[i + 1] as Vector2)).normalized()
		var w := ws[i]
		P(s, PackedVector2Array([pi + dv * 3.0, pi + ni * w * 0.45, pi - dv * 3.0, pi - ni * w * 0.45]), K(s, 0.38))
		PL(s, PackedVector2Array([pi + ni * w * 0.95 - dv * 2.0, pi - dv * 3.5, pi - ni * w * 0.95 - dv * 2.0]), K(s, 0.5), 1.0)
	# gân điện sáng chạy dọc sống lưng
	var vein := PackedVector2Array()
	for i in range(n):
		vein.append((pts[i] as Vector2) + (nrm[i] as Vector2) * (ws[i] * 0.2 + (E.rnd(i, int(t * 24.0)) - 0.5) * 2.0))
	PL(s, vein, A(s, 0.3), 3.4)
	PL(s, vein, K(s, 0.7), 1.1)
	# hồ quang tách nhánh quanh thân (đổi hình theo nhịp)
	var q := int(t * 20.0)
	for k in range(5):
		var idx := 3 + k * 4
		var bp: Vector2 = pts[idx]
		var nn: Vector2 = nrm[idx]
		var sd := 1.0 if k % 2 == 0 else -1.0
		var bolt := PackedVector2Array([bp + nn * ws[idx] * sd])
		var cur: Vector2 = bolt[0]
		for z in range(1, 4):
			cur += nn * sd * (6.0 + 3.0 * E.rnd(k + z, q)) + Vector2((E.rnd(k * 3 + z, q + 1) - 0.5) * 12.0, (E.rnd(k * 5 + z, q + 2) - 0.5) * 6.0)
			bolt.append(cur)
		PL(s, bolt, A(s, 0.35), 4.0)
		PL(s, bolt, K(s, 0.9), 1.2)
		CI(s, cur, 1.6, K(s, 1.0))
	# đầu rắn: hộp sọ + mõm + hàm dưới
	E.glow(s, Vector2(4, 0), 20.0, 0.28)
	var head := PackedVector2Array([Vector2(-8, -6.5), Vector2(-1, -8.5), Vector2(7, -6.0), Vector2(16, -3.2), Vector2(18, 0), Vector2(16, 3.2), Vector2(7, 6.0), Vector2(-1, 8.5), Vector2(-8, 6.5)])
	P(s, head, A(s, 0.97))
	P(s, PackedVector2Array([Vector2(-6, -4.5), Vector2(4, -5.2), Vector2(14, -2.4), Vector2(14, 0), Vector2(2, 0), Vector2(-6, 0)]), M(s, 0.6, 0.95))
	PL(s, PackedVector2Array([Vector2(18, 0), Vector2(10, 1.6), Vector2(2, 2.4)]), Color(0.05, 0.05, 0.08, 0.6), 1.2)   # đường miệng
	# mắt dọc sáng + lông mày
	CI(s, Vector2(6, -4.2), 2.8, K(s, 1.0))
	E.P(s, PackedVector2Array([Vector2(6, -6.0), Vector2(7.0, -4.2), Vector2(6, -2.4), Vector2(5.0, -4.2)]), Color(0.03, 0.03, 0.06, 0.95))
	E.L(s, Vector2(2.0, -6.8), Vector2(9.0, -6.2), K(s, 0.9), 1.2)
	CI(s, Vector2(15.5, -1.4), 0.9, Color(0.03, 0.03, 0.06, 0.9))   # lỗ mũi
	# nanh
	P(s, PackedVector2Array([Vector2(14, 1.8), Vector2(12.4, 1.8), Vector2(13.2, 5.6)]), K(s, 1.0))
	P(s, PackedVector2Array([Vector2(10, 2.4), Vector2(8.6, 2.4), Vector2(9.3, 5.4)]), K(s, 0.9))
	# lưỡi chẻ thè ra
	var tl := 6.0 + 5.0 * absf(sin(t * 34.0))
	var tb := Vector2(18, 0)
	L(s, tb, tb + Vector2(tl, 0), A(s, 0.95), 1.6)
	L(s, tb + Vector2(tl, 0), tb + Vector2(tl + 4.5, -2.4), K(s, 0.95), 1.3)
	L(s, tb + Vector2(tl, 0), tb + Vector2(tl + 4.5, 2.4), K(s, 0.95), 1.3)
	# tia điện nhảy ở đầu mõm
	for k in range(3):
		var tp := Vector2(18.0 + 3.0 * float(k), (E.rnd(k, q) - 0.5) * 8.0)
		E.flare(s, tp, 3.0, 0.5)
	E.rst(s)

static func _fireball(s, t: float, big: bool) -> void:
	var r := 15.0 if big else 10.0
	# đuôi lửa cuộn (lưỡi lửa vốn hướng lên -> xoay -90 độ để hướng ra sau)
	s.draw_set_transform(Vector2.ZERO, -PI * 0.5, Vector2.ONE)
	for k in range(5):
		E.flame(s, Vector2((float(k) - 2.0) * 3.0, r * 0.5 + float(k) * 4.0), (50.0 if big else 34.0), r * 0.7, t, float(k), 0.55)
	E.rst(s)
	trail(s, r * 5.0, r * 0.9, 0.6, true)
	E.glow(s, Vector2.ZERO, r * 2.4, 0.7)
	CI(s, Vector2.ZERO, r, A(s, 0.95))
	CI(s, Vector2.ZERO, r * 0.7, M(s, 0.5, 0.95))
	CI(s, Vector2(r * 0.15, 0), r * 0.4, K(s, 1.0))
	for i in range(6):
		var u := fmod(t * 2.5 + float(i) / 6.0, 1.0)
		CI(s, Vector2(-r - u * r * 4.0, (E.rnd(i, 2) - 0.5) * r * 2.0), 2.2 * (1.0 - u) + 0.5, K(s, 1.0 - u))
	if big:
		_ering(s, Vector2.ZERO, r * 1.6, r * 1.6, A(s, 0.5), 1.6, 0.0)

static func _icewave(s, t: float) -> void:
	# sóng băng: lưỡi liềm gồm nhiều mũi băng nhọn, mảnh tuyết rơi
	E.swoosh(s, Vector2(-40.0, 0), 50.0, -1.0, 1.0, 1.0, 1.0, 22.0, 0.8, 1.15)
	for i in range(9):
		var a := lerpf(-0.9, 0.9, float(i) / 8.0)
		var base := Vector2(-40.0 + cos(a) * 46.0, sin(a) * 52.0)
		var ln := 18.0 + 12.0 * E.rnd(i, 1)
		var d := Vector2(cos(a), sin(a) * 1.1).normalized()
		var nr := d.orthogonal()
		P(s, PackedVector2Array([base + nr * 4.0, base + d * ln, base - nr * 4.0, base - d * 4.0]), K(s, 0.9))
		L(s, base, base + d * ln, A(s, 0.9), 1.2)
	trail(s, 80.0, 24.0, 0.4)
	for i in range(8):
		var u := fmod(t * 1.6 + float(i) / 8.0, 1.0)
		E.star(s, Vector2(-20.0 - u * 90.0, (E.rnd(i, 3) - 0.5) * 60.0), 3.0 * (1.0 - u) + 1.0, 1.0 - u, 4)

static func _bolt(s, t: float) -> void:
	# tia sét xuyên: một nhát dài zigzag sáng chói, phân nhánh
	var pts := PackedVector2Array()
	var n := 14
	for i in range(n + 1):
		var u := float(i) / float(n)
		pts.append(Vector2(-u * 130.0, (E.rnd(i, int(t * 24.0)) - 0.5) * 20.0 * (0.4 + u)))
	PL(s, pts, A(s, 0.25), 12.0)
	PL(s, pts, A(s, 0.8), 4.4)
	PL(s, pts, K(s, 1.0), 1.8)
	for k in range(3):
		var b := pts[2 + k * 4]
		PL(s, PackedVector2Array([b, b + Vector2(-10.0, (E.rnd(k, int(t * 24.0)) - 0.5) * 36.0), b + Vector2(-24.0, (E.rnd(k + 9, int(t * 24.0)) - 0.5) * 44.0)]), K(s, 0.75), 1.3)
	E.flare(s, Vector2(2, 0), 14.0, 1.0)

## ps42: đạn phép tím — viên ngọc phép có vòng ấn xoay, đuôi sao lấp lánh.
static func _arcanebolt(s, t: float) -> void:
	trail(s, 60.0, 8.0, 0.5, true)
	E.glow(s, Vector2.ZERO, 20.0, 0.6)
	CI(s, Vector2.ZERO, 7.5, A(s, 0.95))
	CI(s, Vector2.ZERO, 5.0, M(s, 0.5, 0.95))
	CI(s, Vector2(1.0, -1.0), 2.6, K(s, 1.0))
	var sq := 0.35 + 0.65 * absf(cos(t * 9.0))
	_ering(s, Vector2.ZERO, 5.0 * sq + 1.0, 12.0, K(s, 0.85), 1.6, 0.0)
	_ering(s, Vector2.ZERO, 12.0, 5.0 * (1.0 - sq) + 1.0, A(s, 0.8), 1.4, 0.0)
	for i in range(5):
		var u := fmod(t * 2.2 + float(i) / 5.0, 1.0)
		E.star(s, Vector2(-8.0 - u * 50.0, (E.rnd(i, 7) - 0.5) * 14.0), 3.0 * (1.0 - u) + 1.0, 1.0 - u, 4)

## tn10: đạn nguyên tố — ba hạt lửa, băng, sét xoay quanh một lõi sáng.
static func _elembolt(s, t: float) -> void:
	var cols := [Color(1.0, 0.45, 0.1), Color(0.4, 0.8, 1.0), Color(0.75, 0.75, 1.0)]
	for k in range(3):
		var a := t * 12.0 + TAU * float(k) / 3.0
		var p := Vector2(cos(a) * 3.0, sin(a) * 8.0)
		var c: Color = cols[k]
		var ln := 34.0
		PG(s, PackedVector2Array([p + Vector2(0, -3.0), p + Vector2(0, 3.0), p + Vector2(-ln, 0.8), p + Vector2(-ln, -0.8)]), PackedColorArray([Color(c.r, c.g, c.b, 0.7), Color(c.r, c.g, c.b, 0.7), Color(c.r, c.g, c.b, 0.0), Color(c.r, c.g, c.b, 0.0)]))
		CI(s, p, 6.0, Color(c.r, c.g, c.b, 0.3))
		CI(s, p, 4.2, Color(c.r, c.g, c.b, 0.95))
		CI(s, p, 2.0, Color(1, 1, 1, 0.95))
	E.glow(s, Vector2.ZERO, 14.0, 0.35)
	CI(s, Vector2.ZERO, 3.2, K(s, 1.0))

# ============================================================ TRỊ LIỆU
static func _lightray(s, t: float) -> void:
	# tia sáng thánh dài: lõi trắng + quầng + hạt sáng
	trail(s, 150.0, 9.0, 0.7, true)
	PG(s, PackedVector2Array([Vector2(6, -3), Vector2(6, 3), Vector2(-150, 1), Vector2(-150, -1)]), PackedColorArray([K(s, 1.0), K(s, 1.0), K(s, 0.0), K(s, 0.0)]))
	E.glow(s, Vector2.ZERO, 22.0, 0.8)
	E.flare(s, Vector2(4, 0), 16.0, 1.0)
	for i in range(8):
		var u := fmod(t * 1.6 + float(i) / 8.0, 1.0)
		CI(s, Vector2(-u * 130.0, (E.rnd(i, 4) - 0.5) * 18.0), 1.8 * (1.0 - u) + 0.6, K(s, 1.0 - u))

static func _holywave(s, t: float) -> void:
	E.swoosh(s, Vector2(-34.0, 0), 56.0, -0.95, 0.95, 1.0, 1.0, 26.0, 1.0, 1.15)
	E.swoosh(s, Vector2(-54.0, 0), 44.0, -0.9, 0.9, 1.0, 1.0, 14.0, 0.6, 1.15)
	trail(s, 90.0, 22.0, 0.4)
	E.glow(s, Vector2(10, 0), 16.0, 0.6)
	for i in range(6):
		var u := fmod(t * 1.4 + float(i) / 6.0, 1.0)
		E.star(s, Vector2(-10.0 - u * 80.0, (E.rnd(i, 6) - 0.5) * 50.0), 3.0 * (1.0 - u) + 1.0, 1.0 - u, 4)

static func _seal(s, t: float) -> void:
	# thánh ấn: đĩa ấn có vòng chữ + thập tự xoay
	E.glow(s, Vector2.ZERO, 26.0, 0.55)
	trail(s, 50.0, 12.0, 0.4)
	s.draw_set_transform(Vector2.ZERO, t * 5.0, Vector2(0.55, 1.0))
	E.AR(s, Vector2.ZERO, 16.0, 0.0, TAU, 40, A(s, 0.9), 2.2)
	E.AR(s, Vector2.ZERO, 11.0, 0.0, TAU, 32, K(s, 0.8), 1.4)
	for k in range(8):
		var a := TAU * float(k) / 8.0
		L(s, Vector2(cos(a), sin(a)) * 11.0, Vector2(cos(a), sin(a)) * 16.0, K(s, 0.9), 1.4)
	L(s, Vector2(-9, 0), Vector2(9, 0), K(s, 1.0), 2.0)
	L(s, Vector2(0, -9), Vector2(0, 9), K(s, 1.0), 2.0)
	E.rst(s)
	E.flare(s, Vector2.ZERO, 8.0, 0.8)

# ============================================================ TRIỆU HỒI
static func _wisp(s, t: float) -> void:
	for i in range(9):
		var u := float(i) / 9.0
		CI(s, Vector2(-8.0 - u * 54.0, sin(t * 16.0 - float(i)) * 8.0 * u), 6.0 * (1.0 - u) + 1.0, A(s, 0.5 * (1.0 - u)))
	E.glow(s, Vector2.ZERO, 20.0, 0.6)
	# đầu quỷ hoả: giọt lửa có mắt
	P(s, PackedVector2Array([Vector2(13, 0), Vector2(2, -8), Vector2(-8, -4), Vector2(-8, 4), Vector2(2, 8)]), A(s, 0.95))
	P(s, PackedVector2Array([Vector2(9, 0), Vector2(2, -5), Vector2(-4, 0), Vector2(2, 5)]), K(s, 0.95))
	CI(s, Vector2(2, -2.5), 1.6, Color(0.05, 0.1, 0.1, 0.9))
	CI(s, Vector2(2, 2.5), 1.6, Color(0.05, 0.1, 0.1, 0.9))

static func _bird(s, t: float) -> void:
	# chim linh hồn: thân, đầu mỏ nhọn, hai cánh vỗ, đuôi xoè, lông rơi
	var fl := sin(t * 22.0)
	for i in range(7):
		var u := float(i) / 7.0
		CI(s, Vector2(-18.0 - u * 40.0, 0), 5.0 * (1.0 - u) + 1.0, A(s, 0.4 * (1.0 - u)))
	E.glow(s, Vector2.ZERO, 24.0, 0.5)
	P(s, PackedVector2Array([Vector2(16, -1), Vector2(8, -6), Vector2(-8, -4), Vector2(-14, 0), Vector2(-8, 4), Vector2(8, 5)]), A(s, 0.95))
	P(s, PackedVector2Array([Vector2(16, -1), Vector2(26, 1), Vector2(14, 3)]), K(s, 0.95))
	CI(s, Vector2(10, -2), 1.8, K(s, 1.0))
	# cánh
	for sd in [-1.0, 1.0]:
		P(s, PackedVector2Array([Vector2(2, 0), Vector2(-6, sd * (14.0 + 14.0 * fl)), Vector2(-20, sd * (10.0 + 12.0 * fl)), Vector2(-10, sd * 2.0)]), A(s, 0.85))
		L(s, Vector2(2, 0), Vector2(-16, sd * (11.0 + 12.0 * fl)), K(s, 0.8), 1.4)
	# đuôi
	for k in range(3):
		L(s, Vector2(-12, 0), Vector2(-30.0, (float(k) - 1.0) * 8.0), A(s, 0.8), 2.0)

static func _dragon(s, t: float) -> void:
	# rồng linh nhỏ: thân uốn lượn nhiều đốt, đầu có sừng/râu
	var segs := 14
	var pts: Array = []
	for i in range(segs):
		var u := float(i) / float(segs - 1)
		pts.append(Vector2(-u * 100.0, sin(u * 7.0 - t * 16.0) * 9.0 * (0.3 + u)))
	for i in range(segs - 1, 0, -1):
		var u := float(i) / float(segs - 1)
		var w := 7.0 * (1.0 - u * 0.85) + 0.8
		L(s, pts[i], pts[i - 1], A(s, 0.35), w * 2.6)
		L(s, pts[i], pts[i - 1], A(s, 0.95), w * 1.6)
		L(s, (pts[i] as Vector2) + Vector2(0, w * 0.4), (pts[i - 1] as Vector2) + Vector2(0, w * 0.4), K(s, 0.7), w * 0.6)
		if i % 3 == 0:
			P(s, PackedVector2Array([(pts[i] as Vector2) + Vector2(-2, -w), (pts[i] as Vector2) + Vector2(1, -w - 6.0), (pts[i] as Vector2) + Vector2(3, -w)]), K(s, 0.9))
	var h: Vector2 = pts[0]
	E.glow(s, h, 20.0, 0.5)
	P(s, PackedVector2Array([h + Vector2(-6, -7), h + Vector2(10, -4), h + Vector2(20, 0), h + Vector2(8, 6), h + Vector2(-6, 7)]), A(s, 0.95))
	P(s, PackedVector2Array([h + Vector2(0, -6), h + Vector2(-8, -16), h + Vector2(4, -6)]), K(s, 1.0))
	PL(s, PackedVector2Array([h + Vector2(18, 0), h + Vector2(30, -6), h + Vector2(42, -2)]), K(s, 0.85), 1.4)
	PL(s, PackedVector2Array([h + Vector2(18, 2), h + Vector2(30, 8), h + Vector2(40, 6)]), K(s, 0.85), 1.4)
	CI(s, h + Vector2(6, -2), 2.2, K(s, 1.0))

# ============================================================ TOÀN NĂNG
static func _palm(s, t: float) -> void:
	# thủ ấn: bàn tay kết ấn trong vòng hoa sen
	E.glow(s, Vector2.ZERO, 30.0, 0.5)
	trail(s, 70.0, 16.0, 0.4)
	s.draw_set_transform(Vector2.ZERO, t * 4.0, Vector2.ONE)
	for k in range(8):
		var a := TAU * float(k) / 8.0
		var d := Vector2(cos(a), sin(a))
		var nr := d.orthogonal()
		P(s, PackedVector2Array([d * 8.0 + nr * 4.0, d * 22.0, d * 8.0 - nr * 4.0]), A(s, 0.8))
		L(s, d * 8.0, d * 21.0, K(s, 0.9), 1.0)
	E.AR(s, Vector2.ZERO, 24.0, 0.0, TAU, 40, K(s, 0.6), 1.2)
	E.rst(s)
	# bàn tay (lòng bàn tay + 4 ngón + ngón cái)
	P(s, PackedVector2Array([Vector2(-6, 6), Vector2(-7, -3), Vector2(6, -3), Vector2(7, 6), Vector2(0, 9)]), K(s, 0.95))
	for k in range(4):
		var x := -5.0 + float(k) * 3.4
		L(s, Vector2(x, -3), Vector2(x, -12.0 - float(k % 2 == 1 or k == 2) * 2.0), K(s, 0.95), 2.4)
	L(s, Vector2(-6, 2), Vector2(-12, -3), K(s, 0.95), 2.4)
	E.flare(s, Vector2(0, -2), 9.0, 0.8)

# ============================================================ TANKER
## hv25 Khiên Phi Trảm: đĩa khiên răng cưa xoay (nhìn nghiêng nên co giãn theo góc xoay), vệt mờ + tia lửa thép phía sau.
static func _disc(s, t: float) -> void:
	var spin := t * 16.0
	var sq := 0.8 + 0.2 * absf(cos(t * 9.0))   # hơi lắc như đang bay xoay
	var r := 17.0
	# vệt đuôi mờ + tia lửa thép (nhẹ để không loá)
	trail(s, 80.0, 10.0, 0.22)
	for i in range(6):
		var u := fmod(t * 2.6 + float(i) / 6.0, 1.0)
		CI(s, Vector2(-16.0 - u * 58.0, (E.rnd(i, 3) - 0.5) * 22.0), 2.0 * (1.0 - u) + 0.5, K(s, 0.8 * (1.0 - u)))
	# hai tàn ảnh xoay: chỉ vẽ viền răng cưa (không tô, tránh cộng sáng chồng)
	for j in range(1, 3):
		var ghost := _disc_outline(Vector2(-11.0 * float(j), 0), r, spin - 0.55 * float(j), sq)
		PL(s, ghost, A(s, 0.5 / float(j)), 2.0)
	_disc_body(s, Vector2.ZERO, r, spin, sq)

## Viền răng cưa khép kín (12 răng).
static func _disc_outline(c: Vector2, r: float, spin: float, sq: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for k in range(24):
		var a := spin + TAU * float(k) / 24.0
		var rr := r * 1.2 if k % 2 == 0 else r * 0.92
		pts.append(c + Vector2(cos(a) * rr * sq, sin(a) * rr))
	pts.append(pts[0])
	return pts

static func _disc_body(s, c: Vector2, r: float, spin: float, sq: float) -> void:
	var out := _disc_outline(c, r, spin, sq)
	# vành răng cưa: các mảnh nối viền ngoài với vòng trong (không chồng lên mặt đĩa → không bị loá)
	for k in range(24):
		var a0 := spin + TAU * float(k) / 24.0
		var a1 := spin + TAU * float(k + 1) / 24.0
		var i0 := c + Vector2(cos(a0) * r * 0.8 * sq, sin(a0) * r * 0.8)
		var i1 := c + Vector2(cos(a1) * r * 0.8 * sq, sin(a1) * r * 0.8)
		var shade := 0.55 + 0.45 * sin(a0 - 0.8)
		var col := Color(0.5 * shade + 0.2, 0.56 * shade + 0.22, 0.7 * shade + 0.2, 0.95)
		P(s, PackedVector2Array([out[k], out[k + 1], i1, i0]), col)
	PL(s, out, K(s, 0.9), 1.6)
	# mặt khiên (xanh thép sẫm) + vòng viền sáng
	var face := PackedVector2Array()
	for k in range(24):
		var a2 := TAU * float(k) / 24.0 + spin
		face.append(c + Vector2(cos(a2) * r * 0.74 * sq, sin(a2) * r * 0.74))
	P(s, face, Color(0.16, 0.26, 0.5, 0.95))
	face.append(face[0])
	PL(s, face, K(s, 0.7), 1.3)
	# thập tự trên mặt
	for k in range(4):
		var a4 := spin + PI * 0.5 * float(k)
		L(s, c + Vector2(cos(a4) * r * 0.2 * sq, sin(a4) * r * 0.2), c + Vector2(cos(a4) * r * 0.66 * sq, sin(a4) * r * 0.66), A(s, 0.95), 2.4)
		L(s, c + Vector2(cos(a4) * r * 0.2 * sq, sin(a4) * r * 0.2), c + Vector2(cos(a4) * r * 0.66 * sq, sin(a4) * r * 0.66), K(s, 0.8), 1.0)
	CI(s, c, r * 0.2 * sq, M(s, 0.3, 0.9))
	CI(s, c, r * 0.08, K(s, 0.9))

## Phần ánh sáng đi kèm thú sprite: quầng sau lưng, vệt linh khí kéo dài phía sau, hạt bay, tia lửa ở đầu.
static func _spritelight(s, t: float, ln: float, w: float) -> void:
	E.glow(s, Vector2(-8.0, 0), w * 1.0, 0.25)
	trail(s, ln, w * 0.42, 0.3, false)
	for i in range(8):
		var u := fmod(t * 1.6 + float(i) / 8.0, 1.0)
		CI(s, Vector2(-w * 0.5 - u * ln, (E.rnd(i, 5) - 0.5) * w * 1.6), 2.2 * (1.0 - u) + 0.6, K(s, 0.9 * (1.0 - u)))
		CI(s, Vector2(-w * 0.5 - u * ln, (E.rnd(i, 5) - 0.5) * w * 1.6), 5.0 * (1.0 - u), A(s, 0.3 * (1.0 - u)))
	for i in range(3):
		var u2 := fmod(t * 2.2 + float(i) / 3.0, 1.0)
		L(s, Vector2(-w * 0.3 - ln * 0.4 * u2, (float(i) - 1.0) * w * 0.7), Vector2(-w * 0.3 - ln * 0.4 * u2 - 22.0, (float(i) - 1.0) * w * 0.7), A(s, 0.5 * (1.0 - u2)), 1.6)

## Song Lôi Xuyên: hai tia sét zigzag đan nhau bay song song (mỗi tia một nhịp giật riêng).
static func _twinbolt(s, t: float) -> void:
	s.draw_set_transform(Vector2(0, -7), 0.0, Vector2.ONE)
	_bolt(s, t)
	s.draw_set_transform(Vector2(-10, 7), 0.0, Vector2.ONE)
	_bolt(s, t + 0.41)
	E.rst(s)
