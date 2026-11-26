extends RefCounted
## Hiệu ứng kỹ năng VẼ LẠI RIÊNG (nhóm k) — tu_linh_thuat_su. File này do một người/tiến trình riêng phụ trách.
## Quy ước như FxExt_e/f/g: place "bodyf", gốc = thân nhân vật, +x = hướng nhìn, y âm = lên, mặt đất y~+32. Bộ nét vẽ dùng chung: E (FxExt_e).
## nl1/nl8 là đạn bay (xem FxProj.gd) nên không vẽ ở đây.
const E := preload("res://src/world/fx/FxExt_e.gd")

const IDS := {
	"nl10": "tl_chainblast", "nl11": "tl_miasma", "nl3": "tl_drain", "nl2": "tl_shadowtoggle", "nl4": "tl_army",
	"nl5": "tl_portal", "nl6": "tl_shadowcmd", "nl7": "tl_claws", "nl9": "tl_soulshield",
	"ulLinh2": "tl_tide", "ulTuLinhDungHop": "tl_fusion",
}
const CFG := {
	"tl_chainblast": {"place": "bodyf", "dur": 1.2, "nopop": true, "nobig": true, "rumble": 3.0},
	"tl_miasma": {"place": "bodyf", "dur": 1.8, "nopop": true, "nobig": true},
	"tl_drain": {"place": "bodyf", "dur": 1.1, "nopop": true, "nobig": true},
	"tl_shadowtoggle": {"place": "bodyf", "dur": 1.2, "nopop": true, "nobig": true},
	"tl_army": {"place": "bodyf", "dur": 1.6, "nopop": true, "nobig": true},
	"tl_portal": {"place": "bodyf", "dur": 1.5, "nopop": true, "nobig": true, "rumble": 3.0},
	"tl_shadowcmd": {"place": "bodyf", "dur": 1.1, "nopop": true, "nobig": true},
	"tl_claws": {"place": "bodyf", "dur": 0.8, "nopop": true, "nobig": true},
	"tl_soulshield": {"place": "bodyf", "dur": 1.5, "nopop": true, "nobig": true},
	"tl_tide": {"place": "bodyf", "dur": 1.6, "nopop": true, "nobig": true},
	"tl_fusion": {"place": "bodyf", "dur": 2.2, "nopop": true, "nobig": true},
}
## Sig hỗ trợ hào quang buff kéo dài (s.steady): liệt kê tên sig ở đây và xử lý trong draw_aura.
const AURA_IDS := ["tl_army", "tl_soulshield", "tl_tide", "tl_fusion"]

static func draw(s, sg: String, t: float, lowq: bool) -> void:
	match sg:
		"tl_chainblast": _chainblast(s, t, lowq)
		"tl_miasma": _miasma(s, t, lowq)
		"tl_drain": _drain(s, t, lowq)
		"tl_shadowtoggle": _shadowtoggle(s, t, lowq)
		"tl_army": _army(s, t, lowq)
		"tl_portal": _portal(s, t, lowq)
		"tl_shadowcmd": _shadowcmd(s, t, lowq)
		"tl_claws": _claws(s, t, lowq)
		"tl_soulshield": _soulshield(s, t, lowq)
		"tl_tide": _tide(s, t, lowq)
		"tl_fusion": _fusion(s, t, lowq)
		_: pass

static func draw_aura(s, sg: String, t: float, lowq: bool) -> void:
	var tt := 1.0 + t
	match sg:
		"tl_army": _army(s, tt, lowq)
		"tl_soulshield": _soulshield(s, tt, lowq)
		"tl_tide": _tide(s, tt, lowq)
		"tl_fusion": _fusion(s, tt, lowq)
		_: pass

# ============================================================ tiện ích
const GY := 32.0
const EYE := Color(0.03, 0.02, 0.06)

static func bez(a: Vector2, b: Vector2, c: Vector2, u: float) -> Vector2:
	return a * (1.0 - u) * (1.0 - u) + b * 2.0 * u * (1.0 - u) + c * u * u

## Trận rune tử linh dưới đất: vòng đôi, vạch khắc xoay, sao 5 cánh.
static func rune(s, c: Vector2, rx: float, ry: float, rot: float, al: float, n: int = 12, pent: bool = true) -> void:
	if al <= 0.01 or rx < 6.0: return
	E.ering(s, c, rx, ry, E.A(s, 0.3 * al), 8.0)
	E.ering(s, c, rx, ry, E.A(s, 0.9 * al), 2.2)
	E.ering(s, c, rx * 0.8, ry * 0.8, E.K(s, 0.55 * al), 1.2)
	for i in range(n):
		var a := rot + TAU * float(i) / float(n)
		var d := Vector2(cos(a), sin(a) * ry / maxf(rx, 1.0))
		E.L(s, c + d * rx * 0.8, c + d * rx * 0.97, E.K(s, 0.75 * al), 1.5)
		if i % 2 == 0:
			E.CI(s, c + d * rx * 0.89, 1.6, E.K(s, al))
	if pent:
		var vs := PackedVector2Array()
		for i in range(5):
			var a2 := rot * -0.6 - PI * 0.5 + TAU * float(i) / 5.0
			vs.append(c + Vector2(cos(a2) * rx * 0.78, sin(a2) * ry * 0.78))
		for i in range(5):
			E.L(s, vs[i], vs[(i + 2) % 5], E.A(s, 0.75 * al), 1.4)

## Hồn lửa (đốm sáng có đuôi uốn) bay theo hướng d (vector đơn vị).
static func wisp(s, p: Vector2, d: Vector2, ln: float, r: float, al: float, ph: float = 0.0) -> void:
	if al <= 0.02 or r < 0.8: return
	var nr := d.orthogonal()
	var prev := p
	for j in range(1, 8):
		var u := float(j) / 7.0
		var q := p - d * ln * u + nr * sin(u * 5.0 + ph) * r * 0.9 * u
		var f := al * (1.0 - u)
		E.L(s, prev, q, E.A(s, 0.55 * f), maxf(1.0, r * 1.5 * (1.0 - u)))
		E.L(s, prev, q, E.K(s, 0.6 * f), maxf(0.8, r * 0.6 * (1.0 - u)))
		prev = q
	E.CI(s, p, r * 2.0, E.A(s, 0.22 * al))
	E.CI(s, p, r, E.A(s, 0.8 * al))
	E.CI(s, p, r * 0.5, E.K(s, al))

## Hồn ma trùm đầu: đầu tròn, thân loe, gấu áo lượn sóng, đôi mắt sáng. face: +1 nhìn phải, -1 nhìn trái.
static func ghost(s, c: Vector2, w: float, h: float, al: float, tt: float, face: float = 1.0) -> void:
	if al <= 0.02 or w < 3.0 or h < 8.0: return
	var pts := PackedVector2Array()
	for i in range(11):
		var a := PI + PI * float(i) / 10.0
		pts.append(c + Vector2(cos(a) * w * 0.82, -h * 0.12 + sin(a) * h * 0.4))
	for i in range(7):
		var u := float(i) / 6.0
		var x := lerpf(w, -w, u)
		pts.append(c + Vector2(x, h * 0.5 + sin(u * 11.0 + tt * 6.0) * h * 0.05 - (0.0 if i % 2 == 0 else h * 0.07)))
	E.CI(s, c + Vector2(0, -h * 0.05), w * 1.3, E.A(s, 0.1 * al))
	E.P(s, pts, E.A(s, 0.42 * al))
	var inner := PackedVector2Array()
	for p in pts:
		inner.append(c + (p - c) * 0.62 + Vector2(0, -h * 0.04))
	E.P(s, inner, E.K(s, 0.2 * al))
	var o := pts.duplicate()
	o.append(pts[0])
	E.PL(s, o, E.K(s, 0.55 * al), 1.1)
	for k in range(2):
		var ex := c + Vector2(face * w * 0.22 + (float(k) - 0.5) * w * 0.5, -h * 0.2)
		E.CI(s, ex, w * 0.15, Color(EYE.r, EYE.g, EYE.b, 0.9 * al))
		E.CI(s, ex + Vector2(face * 0.5, 0), w * 0.07, E.K(s, al))

## Đầu lâu.
static func skull(s, p: Vector2, r: float, al: float) -> void:
	if al <= 0.02 or r < 2.5: return
	E.CI(s, p, r * 1.5, E.A(s, 0.18 * al))
	E.CI(s, p, r, E.K(s, 0.85 * al))
	E.P(s, PackedVector2Array([p + Vector2(-r * 0.5, r * 0.55), p + Vector2(r * 0.5, r * 0.55), p + Vector2(r * 0.38, r * 1.15), p + Vector2(-r * 0.38, r * 1.15)]), E.K(s, 0.8 * al))
	for k in range(2):
		E.CI(s, p + Vector2((float(k) - 0.5) * r * 0.75, -r * 0.05), r * 0.27, Color(EYE.r, EYE.g, EYE.b, 0.92 * al))
	E.P(s, PackedVector2Array([p + Vector2(0, r * 0.2), p + Vector2(-r * 0.12, r * 0.42), p + Vector2(r * 0.12, r * 0.42)]), Color(EYE.r, EYE.g, EYE.b, 0.85 * al))

## Tia nối zigzag (sét âm khí) từ a đến b, tiến độ q.
static func zig(s, a: Vector2, b: Vector2, q: float, w: float, al: float, seed: int) -> void:
	if al <= 0.02 or q <= 0.02 or a.distance_to(b) < 4.0: return
	var nr := (b - a).orthogonal().normalized()
	var pts := PackedVector2Array()
	for i in range(10):
		var u := float(i) / 9.0 * q
		pts.append(a.lerp(b, u) + nr * (E.rnd(i, seed) - 0.5) * 16.0 * sin(float(i) / 9.0 * PI))
	E.PL(s, pts, E.A(s, 0.25 * al), w * 3.5)
	E.PL(s, pts, E.A(s, 0.85 * al), w * 1.5)
	E.PL(s, pts, E.K(s, al), maxf(1.0, w * 0.6))

## Thân hồn lửa dọc (cột hồn) cắm xuống đất.
static func soulfire(s, base: Vector2, h: float, w: float, t: float, al: float, n: int = 3) -> void:
	for i in range(n):
		var o := (float(i) - float(n - 1) * 0.5) * w * 1.1
		E.flame(s, base + Vector2(o, 0), h * (1.0 - 0.25 * absf(float(i) - float(n - 1) * 0.5)), w, t, float(i) * 1.7, al)

# ============================================================ nl10 HỒN NỔ DÂY CHUYỀN
## Nổ quanh người r210, mỗi kẻ trúng nổ lan sang kẻ bên cạnh: tia nối giữa các vụ nổ liên tiếp.
static func _chainblast(s, t: float, lowq: bool) -> void:
	var R := 210.0
	var fa := E.fadeo(t, 0.78)
	var gc := Vector2(0, GY - 6.0)
	var o := Vector2(0, -6.0)
	var e0 := E.sg(t, 0.0, 0.28)
	rune(s, gc, R * 0.5 * E.eo(E.sg(t, 0.0, 0.2)), R * 0.5 * 0.26 * E.eo(E.sg(t, 0.0, 0.2)), t * 3.0, fa * 0.8)
	E.shock(s, gc, R * E.eo(e0), R * 0.26 * E.eo(e0), (1.0 - E.sg(t, 0.12, 0.7)) * fa)
	E.star(s, o, 44.0 * (1.0 - E.sg(t, 0.15, 0.45) * 0.7), (1.0 - E.sg(t, 0.2, 0.5)) * fa, 10)
	E.spark(s, o, 0 if lowq else 14, R * 0.55, E.sg(t, 0.0, 0.7), fa, 2)
	# hai nhánh dây chuyền: phải và trái
	var chains := [
		[Vector2(104, 10), Vector2(168, -14), Vector2(204, 18)],
		[Vector2(-98, 14), Vector2(-158, -10), Vector2(-200, 16)],
	]
	for ci in range(2):
		var chain: Array = chains[ci]
		var prev := o
		for j in range(chain.size()):
			var tk := 0.2 + 0.15 * float(j) + 0.05 * float(ci)
			var np: Vector2 = chain[j]
			var life := E.fadeo(t, tk + 0.4)
			# tia nối từ vụ nổ trước sang kẻ kế bên
			var lq := E.sg(t, tk - 0.1, tk)
			zig(s, prev, np, E.eo(lq), 1.0, E.fadeo(t, tk + 0.12), int(t * 26.0) + j * 3 + ci)
			# đầu lâu báo hiệu kẻ bị nổ trước khi nổ
			if t < tk:
				skull(s, np + Vector2(0, -26.0), 7.0, E.sg(t, tk - 0.18, tk - 0.08))
			var p := E.sg(t, tk, tk + 0.34)
			if p > 0.0:
				var pg := np + Vector2(0, 24.0)
				E.shock(s, pg, 58.0 * E.eo(p), 15.0 * E.eo(p), (1.0 - p) * life)
				E.star(s, np, 34.0 * (1.0 - p * 0.45), (1.0 - p) * life, 8)
				soulfire(s, pg, 64.0 * (1.0 - p * 0.5), 8.0, t, (1.0 - E.sg(t, tk + 0.1, tk + 0.4)) * life, 3)
				E.spark(s, np, 0 if lowq else 9, 54.0, p, life, 5 + j)
			prev = np
	# vòng ma khí vỡ vụn bay ra
	for i in range(0 if lowq else 10):
		var a := TAU * E.rnd(i, 9)
		var u := E.sg(t, 0.05, 0.8)
		wisp(s, o + Vector2(cos(a), sin(a) * 0.4) * R * 0.7 * E.eo(u), Vector2(cos(a), sin(a) * 0.4).normalized(), 18.0, 2.6, (1.0 - u) * fa, float(i))

# ============================================================ nl11 TỬ KHÍ TRÀN NGẬP
## Tử khí lan ra r280 như sương độc, mặt ma lẩn trong sương, rồi sinh lực bị hút ngược về người.
static func _miasma(s, t: float, lowq: bool) -> void:
	var R := 280.0
	var fa := E.fadeo(t, 0.82)
	var gc := Vector2(0, GY - 6.0)
	var e := E.eo(E.sg(t, 0.0, 0.4))
	rune(s, gc, R * e, R * 0.24 * e, t * 1.6, 0.7 * fa, 16)
	# sương tử khí: cụm vòng mờ trôi lững lờ
	var n := 14 if lowq else 30
	for i in range(n):
		var a := TAU * E.rnd(i, 1)
		var d := sqrt(E.rnd(i, 2)) * R * e
		var p := gc + Vector2(cos(a) * d, sin(a) * d * 0.26 - 10.0 - 22.0 * E.rnd(i, 3) + sin(t * 3.0 + float(i)) * 4.0)
		var r := 26.0 + 22.0 * E.rnd(i, 4)
		E.CI(s, p, r, Color(0.07, 0.1, 0.09, 0.2 * fa))
		E.CI(s, p + Vector2(-r * 0.15, -r * 0.2), r * 0.7, E.A(s, 0.11 * fa))
		E.CI(s, p + Vector2(-r * 0.3, -r * 0.35), r * 0.35, E.K(s, 0.05 * fa))
	# mặt ma lẩn trong sương
	for i in range(4 if lowq else 7):
		var a2 := TAU * E.rnd(i, 11)
		var d2 := (0.3 + 0.65 * E.rnd(i, 12)) * R * e
		var u := E.sg(t, 0.15 + 0.05 * float(i), 0.75)
		var p2 := gc + Vector2(cos(a2) * d2, sin(a2) * d2 * 0.26 - 30.0 - 18.0 * u)
		skull(s, p2, 7.0 + 3.0 * E.rnd(i, 13), sin(u * PI) * 0.7 * fa)
	# giai đoạn hút lại sinh lực: dòng hồn bay về người
	var h := E.sg(t, 0.42, 0.9)
	if h > 0.0:
		for i in range(8 if lowq else 16):
			var a3 := TAU * E.rnd(i, 21)
			var d3 := (0.35 + 0.65 * E.rnd(i, 22)) * R * 0.95
			var src := gc + Vector2(cos(a3) * d3, sin(a3) * d3 * 0.26 - 12.0)
			var u2 := E.sg(h, E.rnd(i, 23) * 0.4, 0.6 + E.rnd(i, 23) * 0.4)
			if u2 <= 0.0 or u2 >= 1.0: continue
			var tgt := Vector2(0, -8.0)
			var mid := (src + tgt) * 0.5 + Vector2(0, -50.0 - 30.0 * E.rnd(i, 24))
			var q := bez(src, mid, tgt, E.ei(u2) * 0.8 + 0.2 * u2)
			var q2 := bez(src, mid, tgt, maxf(0.0, E.ei(u2) * 0.8 + 0.2 * u2 - 0.05))
			wisp(s, q, (q - q2).normalized(), 26.0, 3.0, sin(u2 * PI) * 1.0 * fa, float(i))
		var g := E.sg(h, 0.3, 0.8)
		E.glow(s, Vector2(0, -8), 46.0 * g, 0.55 * g * (1.0 - E.sg(h, 0.85, 1.0)))
		for k in range(3):
			var pl := Vector2((float(k) - 1.0) * 18.0, -30.0 - 36.0 * E.sg(h, 0.4 + 0.1 * float(k), 1.0))
			var f := sin(E.sg(h, 0.4 + 0.1 * float(k), 1.0) * PI) * fa
			E.L(s, pl + Vector2(-5, 0), pl + Vector2(5, 0), E.K(s, f), 2.4)
			E.L(s, pl + Vector2(0, -5), pl + Vector2(0, 5), E.K(s, f), 2.4)

# ============================================================ nl3 HÚT LINH
## Hút máu r190: các dòng hồn cong vút từ vòng ngoài bay về người, xoáy hút hội tụ.
static func _drain(s, t: float, lowq: bool) -> void:
	var R := 190.0
	var fa := E.fadeo(t, 0.8)
	var gc := Vector2(0, GY - 6.0)
	var o := Vector2(0, -8.0)
	var e := E.eo(E.sg(t, 0.0, 0.3))
	rune(s, gc, R * e, R * 0.26 * e, -t * 3.0, 0.8 * fa, 12, false)
	# xoáy hút: các cung xoắn co dần về tâm
	for k in range(4):
		var sh := fmod(t * 1.5 + 0.25 * float(k), 1.0)
		var rr := R * (1.0 - sh)
		E.ering(s, gc, rr, rr * 0.26, E.A(s, 0.5 * sin(sh * PI) * fa), 2.0, t * 2.0)
	# dòng hồn bay về người
	var n := 8 if lowq else 14
	for i in range(n):
		var a := TAU * float(i) / float(n) + 0.2
		var src := gc + Vector2(cos(a) * R * (0.7 + 0.3 * E.rnd(i, 1)), sin(a) * R * 0.28 - 14.0 * E.rnd(i, 2))
		var u := E.sg(t, 0.06 + 0.04 * float(i % 5), 0.7 + 0.05 * float(i % 4))
		if u <= 0.0 or u >= 1.0: continue
		var mid := (src + o) * 0.5 + Vector2(sin(a) * 30.0, -60.0 - 20.0 * E.rnd(i, 3))
		var uu := E.ei(u) * 0.75 + u * 0.25
		var q := bez(src, mid, o, uu)
		var q2 := bez(src, mid, o, maxf(0.0, uu - 0.06))
		wisp(s, q, (q - q2).normalized(), 30.0, 3.4 * (1.0 - u * 0.4), fa, float(i))
	# hút vào người: loé xanh + dấu cộng hồi máu
	var g := E.sg(t, 0.4, 0.85)
	if g > 0.0:
		E.glow(s, o, 40.0 * E.eo(g), 0.6 * sin(g * PI) * fa)
		E.ering(s, Vector2(0, GY - 4.0), 40.0 * E.eo(g), 10.0 * E.eo(g), E.K(s, (1.0 - g) * fa), 2.0)
		for k in range(4):
			var f := E.sg(g, 0.1 * float(k), 0.55 + 0.1 * float(k))
			var pl := Vector2(-24.0 + 16.0 * float(k), -26.0 - 26.0 * f)
			E.L(s, pl + Vector2(-4.5, 0), pl + Vector2(4.5, 0), E.K(s, sin(f * PI) * fa), 2.2)
			E.L(s, pl + Vector2(0, -4.5), pl + Vector2(0, 4.5), E.K(s, sin(f * PI) * fa), 2.2)

# ============================================================ nl2 TRIỆU HỒI BÓNG
## Bật/tắt đội bóng ma: bóng trồi lên từ trận rune dưới đất rồi tan thành tro hồn.
static func _shadowtoggle(s, t: float, lowq: bool) -> void:
	var fa := E.fadeo(t, 0.78)
	var gc := Vector2(-8.0, GY - 5.0)
	var e := E.eo(E.sg(t, 0.0, 0.3))
	rune(s, gc, 74.0 * e, 19.0 * e, t * 2.2, fa, 10)
	var spots := [Vector2(-44, -4), Vector2(-74, 10), Vector2(-22, 16), Vector2(-96, -8)]
	for k in range(4):
		var st := 0.1 + 0.09 * float(k)
		var up := E.eo(E.sg(t, st, st + 0.3))
		var dis := E.sg(t, 0.66 + 0.05 * float(k), 0.95)
		var p: Vector2 = spots[k]
		var al := up * (1.0 - dis)
		if al <= 0.02: continue
		E.ering(s, Vector2(p.x, GY - 3.0), 24.0 * up, 6.0 * up, E.A(s, 0.7 * fa * (1.0 - dis)), 2.0)
		var h := 56.0 + 8.0 * float(k % 2)
		var c := p + Vector2(0, (1.0 - up) * 40.0 - dis * 18.0)
		if not s.nocreature: ghost(s, c, 15.0, h, al, t + float(k), 1.0)
		# dải hồn kéo từ đất lên theo thân bóng
		for j in range(3):
			var xo := (float(j) - 1.0) * 9.0
			E.L(s, Vector2(p.x + xo, GY - 4.0), Vector2(p.x + xo, GY - 4.0 - (h * 0.8) * up), E.A(s, 0.3 * al * (1.0 - up * 0.6)), 2.0)
	# tro hồn bay lên (bóng vừa hiện hoặc vừa tan)
	if not lowq:
		for i in range(16):
			var x := -110.0 + 120.0 * E.rnd(i, 1)
			var u := fmod(t * 1.4 + E.rnd(i, 2), 1.0)
			E.CI(s, Vector2(x + sin(u * 6.0 + float(i)) * 6.0, GY - 6.0 - 80.0 * u), 2.0 * (1.0 - u) + 0.6, E.K(s, 0.8 * (1.0 - u) * fa))

# ============================================================ nl4 ĐỘI QUÂN U ẢNH
## Buff cường hóa bóng ma: đội quân bóng cầm giáo đứng sát bên, cờ trận phấp phới, mũi tên tăng lực bốc lên.
static func _army(s, t: float, lowq: bool) -> void:
	var up := E.eo(E.sg(t, 0.0, 0.25))
	var fa := E.fo(s, t, 0.85)
	var al := up * fa
	rune(s, Vector2(-30.0, GY - 4.0), 62.0 * up, 16.0 * up, t * 1.3, al, 10)
	var ranks := [Vector2(-58, -2), Vector2(-92, 6), Vector2(-30, 12)]
	for k in range(3):
		if s.nocreature: continue   # đội bóng do sprite (FxCreature) đảm nhận
		var p: Vector2 = ranks[k] + Vector2(0, sin(t * 3.0 + float(k) * 2.0) * 3.0)
		ghost(s, p, 14.0, 54.0, al * (0.95 - 0.12 * float(k)), t + float(k), 1.0)
		# giáo của mỗi bóng
		var tip := p + Vector2(20.0, -52.0)
		E.L(s, p + Vector2(14.0, 20.0), tip, E.K(s, 0.75 * al), 1.8)
		E.P(s, PackedVector2Array([tip + Vector2(0, -12), tip + Vector2(4, 0), tip + Vector2(-4, 0)]), E.K(s, al))
		# mũi tên tăng lực
		var ph := fmod(t * 0.9 + 0.31 * float(k), 1.0)
		var ap := p + Vector2(-2.0, -48.0 - 24.0 * ph)
		var fb := sin(ph * PI) * al
		E.L(s, ap + Vector2(-7, 5), ap, E.K(s, fb), 2.4)
		E.L(s, ap + Vector2(7, 5), ap, E.K(s, fb), 2.4)
		E.L(s, ap + Vector2(-7, 14), ap + Vector2(0, 9), E.A(s, fb), 2.0)
		E.L(s, ap + Vector2(7, 14), ap + Vector2(0, 9), E.A(s, fb), 2.0)
	# cờ chiến phía sau người: cột cờ + lá cờ rách lượn sóng + dấu đầu lâu
	var pole := Vector2(-18.0, 30.0)
	var ptop := Vector2(-18.0, -78.0 * up)
	E.L(s, pole, ptop, E.K(s, 0.7 * al), 2.0)
	if up > 0.4:
		var up2 := PackedVector2Array()
		var dn := PackedVector2Array()
		for i in range(9):
			var u := float(i) / 8.0
			var w := sin(u * 7.0 - t * 7.0) * 4.0 * u
			up2.append(ptop + Vector2(-u * 34.0, 2.0 + w - u * 2.0))
			dn.append(ptop + Vector2(-u * 34.0, 26.0 + w + u * 7.0 * (1.0 if i % 2 == 0 else 0.4)))
		var poly := PackedVector2Array()
		poly.append_array(up2)
		for i in range(8, -1, -1):
			poly.append(dn[i])
		E.P(s, poly, Color(0.07, 0.05, 0.12, 0.8 * al))
		E.PL(s, up2, E.A(s, 0.9 * al), 1.6)
		E.PL(s, dn, E.A(s, 0.6 * al), 1.2)
		skull(s, ptop + Vector2(-15.0, 14.0), 5.5, al)
	E.glow(s, Vector2(-50.0, -10.0), 48.0 * up, 0.12 * al)

# ============================================================ nl5 CỔNG ÂM GIỚI
## Cổng âm giới mở trên trời, hai thiên thạch ma rơi xuống ở 170px và 280px phía trước.
static func _portal(s, t: float, lowq: bool) -> void:
	var P := Vector2(225.0, -232.0)
	var open := E.eo(E.sg(t, 0.0, 0.22)) * (1.0 - E.eo(E.sg(t, 0.84, 1.0)))
	var gc := Vector2(0, GY)
	# vòng cổng: xoáy tối + vòng rune + ánh sáng âm khí
	if open > 0.02:
		var rx := 74.0 * open
		var ry := 34.0 * open
		E.glow(s, P, rx * 1.2, 0.35 * open)
		for k in range(8):
			var u := float(k) / 7.0
			E.ering(s, P, rx * (1.0 - u * 0.85), ry * (1.0 - u * 0.85), Color(0.04 + 0.1 * u, 0.03 + 0.15 * u, 0.07 + 0.12 * u, 0.55 * open), 8.0, t * (2.0 + float(k) * 0.4))
		E.ering(s, P, rx, ry, E.A(s, open), 3.0)
		E.ering(s, P, rx * 1.12, ry * 1.12, E.K(s, 0.5 * open), 1.2)
		# xoáy xoắn
		var sp := PackedVector2Array()
		for i in range(26):
			var u2 := float(i) / 25.0
			var a := u2 * TAU * 1.8 + t * 9.0
			sp.append(P + Vector2(cos(a) * rx * 0.9 * u2, sin(a) * ry * 0.9 * u2))
		E.PL(s, sp, E.K(s, 0.55 * open), 1.6)
		for i in range(10):
			var a2 := t * 1.4 + TAU * float(i) / 10.0
			var gp := P + Vector2(cos(a2) * rx * 1.12, sin(a2) * ry * 1.12)
			E.CI(s, gp, 2.0, E.K(s, 0.9 * open))
		# cột sáng hắt xuống
		E.beam(s, P.x, P.y, GY, 34.0 * open, 54.0 * open, 0.5 * open)
	# hai thiên thạch ma
	var targets := [170.0, 280.0]
	var hits := [0.42, 0.7]
	for k in range(2):
		var tx: float = targets[k]
		var th: float = hits[k]
		var fall := E.sg(t, th - 0.26, th)
		var tgt := Vector2(tx, GY - 6.0)
		var from := P + Vector2((float(k) - 0.5) * 24.0, 8.0)
		if fall > 0.0 and fall < 1.0:
			var m := from.lerp(tgt, E.ei(fall) * 0.9 + 0.1 * fall)
			var dirv := (tgt - from).normalized()
			# lửa đuôi xanh phía trên + vệt
			E.L(s, m - dirv * 80.0, m, E.A(s, 0.35), 14.0)
			E.L(s, m - dirv * 70.0, m, E.A(s, 0.8), 6.0)
			E.flame(s, m + Vector2(-8, -6), 74.0, 12.0, t, float(k), 0.95)
			E.flame(s, m + Vector2(9, -6), 58.0, 9.0, t, float(k) + 2.0, 0.85)
			# thân thiên thạch: đá gồ ghề tối + mặt đầu lâu + viền sáng
			var rock := PackedVector2Array()
			for i in range(10):
				var a3 := TAU * float(i) / 10.0
				rock.append(m + Vector2(cos(a3), sin(a3)) * (19.0 + 5.0 * E.rnd(i, 7 + k)))
			E.CI(s, m, 30.0, E.A(s, 0.25))
			E.P(s, rock, Color(0.09, 0.08, 0.12, 0.95))
			var ro := rock.duplicate()
			ro.append(rock[0])
			E.PL(s, ro, E.A(s, 0.95), 2.0)
			skull(s, m + Vector2(0, -1), 9.0, 0.95)
			E.flare(s, m + Vector2(-10, -12), 6.0, 0.8)
		# điểm báo trước trên mặt đất
		var warn := E.sg(t, th - 0.3, th - 0.1) * (1.0 - E.sg(t, th, th + 0.03))
		if warn > 0.0:
			E.ering(s, Vector2(tx, GY - 4.0), 38.0, 10.0, E.A(s, 0.8 * warn), 2.2, t * 2.0)
			E.ering(s, Vector2(tx, GY - 4.0), 20.0, 5.0, E.K(s, warn), 1.6)
		# va chạm
		var p := E.sg(t, th, th + 0.32)
		if p > 0.0:
			var life := E.fadeo(t, th + 0.28)
			var g := Vector2(tx, GY - 2.0)
			E.shock(s, g, 100.0 * E.eo(p), 26.0 * E.eo(p), (1.0 - p) * life)
			E.crack(s, g, 80.0 * E.eo(p), (1.0 - p * 0.7) * life, k + 3)
			E.star(s, g + Vector2(0, -14), 42.0 * (1.0 - p * 0.5), (1.0 - p) * life, 10)
			soulfire(s, g, 78.0 * (1.0 - p * 0.35), 9.0, t, (1.0 - E.sg(t, th + 0.12, th + 0.45)) * life, 4)
			E.spark(s, g + Vector2(0, -10), 0 if lowq else 14, 90.0, p, life, 8 + k)
			for i in range(0 if lowq else 5):
				var xo := (E.rnd(i, 5 + k) - 0.5) * 120.0
				wisp(s, g + Vector2(xo, -20.0 - 70.0 * p * (0.5 + E.rnd(i, 6))), Vector2(0, -1), 24.0, 3.0, (1.0 - p) * life, float(i))
	rune(s, Vector2(225.0, GY - 4.0), 118.0 * open, 29.0 * open, t * 1.5, 0.45 * open, 14, false)

# ============================================================ nl6 PHÂN HỒN
## Lệnh bóng ma: xung kích bóng tối r240 quét ra, các bóng ma lao về mục tiêu gần nhất và cào xé.
static func _shadowcmd(s, t: float, lowq: bool) -> void:
	var R := 240.0
	var fa := E.fadeo(t, 0.8)
	var gc := Vector2(0, GY - 6.0)
	var e := E.eo(E.sg(t, 0.0, 0.4))
	E.shock(s, gc, R * e, R * 0.26 * e, (1.0 - E.sg(t, 0.1, 0.8)) * fa)
	for i in range(5):
		E.CI(s, Vector2(0, -6), R * 0.38 * e * (1.0 - 0.13 * float(i)), Color(0.07, 0.04, 0.12, 0.05 * fa))
	# ấn lệnh: ba mũi tên chỉ hướng phía trước
	var cm := E.eo(E.sg(t, 0.05, 0.3))
	for k in range(3):
		var ax := 30.0 + 22.0 * float(k) + 8.0 * sin(t * 12.0 + float(k))
		var f := cm * (1.0 - E.sg(t, 0.4, 0.7)) * (1.0 - 0.2 * float(k))
		E.L(s, Vector2(ax, -26.0), Vector2(ax + 12.0, -10.0), E.A(s, 0.9 * f), 3.0)
		E.L(s, Vector2(ax + 12.0, -10.0), Vector2(ax, 6.0), E.A(s, 0.9 * f), 3.0)
		E.L(s, Vector2(ax + 1.0, -22.0), Vector2(ax + 10.0, -10.0), E.K(s, f), 1.2)
	# mục tiêu gần nhất: tâm ngắm
	var T := Vector2(190.0, -4.0)
	var lk := E.eo(E.sg(t, 0.15, 0.4))
	if lk > 0.0:
		var rr := 26.0 * (1.5 - 0.5 * lk)
		E.AR(s, T, rr, 0.0, TAU, 28, E.A(s, 0.85 * lk * fa), 2.0)
		for k in range(4):
			var a := PI * 0.5 * float(k) + t * 3.0
			E.L(s, T + Vector2(cos(a), sin(a)) * (rr - 5.0), T + Vector2(cos(a), sin(a)) * (rr + 8.0), E.K(s, lk * fa), 1.6)
		E.CI(s, T, 3.0, E.K(s, lk * fa))
	# bốn bóng ma lao vào mục tiêu
	var starts := [Vector2(-34, -30), Vector2(-26, 6), Vector2(-52, -8), Vector2(-18, -16)]
	var offs := [Vector2(-16, -22), Vector2(-20, 12), Vector2(-4, -2), Vector2(-26, -8)]
	for k in range(4):
		var a0 := 0.18 + 0.05 * float(k)
		var u := E.sg(t, a0, a0 + 0.36)
		var st: Vector2 = starts[k]
		var en: Vector2 = T + (offs[k] as Vector2)
		var pos := st.lerp(en, E.eo(u))
		var vis := E.sg(t, a0 - 0.08, a0) * (1.0 - E.sg(t, 0.78 + 0.03 * float(k), 0.95))
		if vis <= 0.02: continue
		# vệt chạy
		for j in range(1, 5):
			var pj := st.lerp(en, E.eo(maxf(0.0, u - 0.07 * float(j))))
			ghost(s, pj, 12.0, 44.0, 0.28 * vis * (1.0 - 0.2 * float(j)), t, 1.0)
		ghost(s, pos, 13.0, 48.0, vis * fa, t + float(k), 1.0)
		if u < 1.0:
			E.L(s, st, pos, E.A(s, 0.18 * vis), 10.0)
		else:
			var hq := E.sg(t, a0 + 0.36, a0 + 0.52)
			E.cut(s, en + Vector2(-10.0, -26.0), en + Vector2(22.0, 22.0), 3.2, (1.0 - hq) * fa)
	# loé trúng mục tiêu
	var hh := E.sg(t, 0.52, 0.85)
	if hh > 0.0:
		E.star(s, T, 30.0 * (1.0 - hh * 0.5), (1.0 - hh) * fa, 8)
		E.shock(s, T + Vector2(0, 30), 14.0 + 60.0 * E.eo(hh), 4.0 + 16.0 * E.eo(hh), (1.0 - hh) * fa)
		E.spark(s, T, 0 if lowq else 10, 60.0, hh, (1.0 - hh) * fa, 3)

# ============================================================ nl7 VUỐT QUỶ
## Ba móng vuốt âm khí xé liên tiếp (range 130): mỗi nhát ba vệt song song, hướng khác nhau.
static func _claw_stroke(s, a: Vector2, c: Vector2, b: Vector2, off: Vector2, q: float, w: float, al: float) -> void:
	if q <= 0.02 or al <= 0.02: return
	var segs := 16
	var tail := 0.7
	var prev := Vector2.ZERO
	for i in range(segs + 1):
		var u := E.eo(q) * float(i) / float(segs)
		var p := bez(a + off, c + off, b + off, u)
		if i > 0:
			var k := float(i) / float(segs)
			var f := al * pow(k, 0.9)
			var ww := w * sin(clampf(k, 0.05, 1.0) * PI * 0.5 + 0.0) * (1.0 - 0.0 * k)
			E.L(s, prev, p, E.A(s, 0.28 * f), ww * 3.2)
			E.L(s, prev, p, E.A(s, 0.85 * f), ww * 1.5)
			E.L(s, prev, p, E.K(s, f), maxf(1.0, ww * 0.55))
		prev = p
	# mũi vuốt nhọn ở đầu nét
	var hp := bez(a + off, c + off, b + off, E.eo(q))
	var hp2 := bez(a + off, c + off, b + off, maxf(0.0, E.eo(q) - 0.05))
	var dv := (hp - hp2).normalized()
	if dv.length() > 0.1:
		E.P(s, PackedVector2Array([hp + dv * 10.0, hp + dv.orthogonal() * 3.4, hp - dv.orthogonal() * 3.4]), E.K(s, al))

static func _claws(s, t: float, lowq: bool) -> void:
	var fa := E.fadeo(t, 0.78)
	var hit_defs := [
		{"a": Vector2(34, -62), "c": Vector2(82, -22), "b": Vector2(104, 34)},
		{"a": Vector2(40, 40), "c": Vector2(88, -2), "b": Vector2(110, -58)},
		{"a": Vector2(26, -50), "c": Vector2(96, -14), "b": Vector2(124, 44)},
	]
	for k in range(3):
		var tk := 0.04 + 0.26 * float(k)
		var q := E.sg(t, tk, tk + 0.2)
		if q <= 0.0: continue
		var d: Dictionary = hit_defs[k]
		var life := E.fadeo(t, tk + 0.28)
		var a: Vector2 = d["a"]
		var c: Vector2 = d["c"]
		var b: Vector2 = d["b"]
		var nr := (b - a).orthogonal().normalized()
		var sp := 17.0 if k < 2 else 20.0
		# ba vuốt song song
		for j in range(3):
			_claw_stroke(s, a, c, b, nr * (float(j) - 1.0) * sp, q, 4.6 if j == 1 else 3.6, life)
		# bàn tay ma ở đầu nét
		var hd := bez(a, c, b, E.eo(q))
		if q < 1.0:
			var hd2 := bez(a, c, b, maxf(0.0, E.eo(q) - 0.06))
			var dd := (hd - hd2).normalized()
			ghost(s, hd - dd * 18.0, 12.0, 30.0, 0.5 * life, t, 1.0)
		# đòn trúng: lóe + tia máu âm
		var hp := E.sg(t, tk + 0.16, tk + 0.4)
		if hp > 0.0:
			E.flare(s, c, 12.0 * (1.0 - hp), (1.0 - hp) * life)
			E.spark(s, c, 0 if lowq else 6, 46.0, hp, (1.0 - hp) * life, 2 + k)
	# nhát cuối nổ sao tử khí
	var fq := E.sg(t, 0.6, 0.85)
	if fq > 0.0:
		E.star(s, Vector2(96.0, -8.0), 34.0 * (1.0 - E.sg(t, 0.7, 1.0) * 0.6), fa * (1.0 - E.sg(t, 0.78, 1.0)), 8)
		E.ering(s, Vector2(96.0, GY - 6.0), 14.0 + 50.0 * E.eo(fq), 4.0 + 12.0 * E.eo(fq), E.A(s, (1.0 - fq) * fa), 2.0)

# ============================================================ nl9 HỒN PHÁCH HỘ THỂ
## Hộ thể (manashield): màn cầu hồn phách bao thân, các hồn lửa xoay quanh, đầu lâu hộ pháp trên mặt khiên.
static func _soulshield(s, t: float, lowq: bool) -> void:
	var up := E.eo(E.sg(t, 0.0, 0.25))
	var fa := E.fo(s, t, 0.85)
	var al := up * fa
	var o := Vector2(0, -6.0)
	var R := 50.0 * up
	# màn cầu: nhiều lớp mờ + viền sáng + ánh phản chiếu
	for i in range(6):
		E.CI(s, o, R * (1.0 - 0.13 * float(i)), E.A(s, (0.035 + 0.01 * float(i)) * al))
	E.CI(s, o, R * 1.04, E.A(s, 0.07 * al))
	E.AR(s, o, R, 0.0, TAU, 40, E.A(s, 0.85 * al), 2.2)
	E.AR(s, o, R * 1.07, 0.0, TAU, 40, E.A(s, 0.28 * al), 5.0)
	E.AR(s, o, R * 0.93, PI * 1.05, PI * 1.55, 12, E.K(s, 0.85 * al), 2.0)
	# vân lưới hồn trên mặt cầu
	for i in range(3):
		E.ering(s, o, R * (0.25 + 0.25 * float(i)), R, E.A(s, 0.25 * al), 1.1, t * (0.8 + 0.3 * float(i)) + float(i))
	# bốn hồn lửa xoay quanh vòng cầu
	var n := 4 if lowq else 6
	for i in range(n):
		var a := t * 2.4 + TAU * float(i) / float(n)
		var pos := o + Vector2(cos(a) * R * 0.98, sin(a) * R * 0.45)
		var dv := Vector2(-sin(a), cos(a) * 0.45).normalized()
		if sin(a) > 0.0:
			wisp(s, pos, dv, 24.0, 3.6, al, float(i))
	for i in range(n):
		var a2 := t * 2.4 + TAU * float(i) / float(n)
		var pos2 := o + Vector2(cos(a2) * R * 0.98, sin(a2) * R * 0.45)
		var dv2 := Vector2(-sin(a2), cos(a2) * 0.45).normalized()
		if sin(a2) <= 0.0:
			wisp(s, pos2, dv2, 24.0, 3.0, 0.55 * al, float(i))
	# đầu lâu hộ pháp ở mặt trước khiên
	skull(s, o + Vector2(R * 0.62, -R * 0.16), 6.0 * up, 0.8 * al)
	rune(s, Vector2(0, GY - 4.0), 42.0 * up, 11.0 * up, t * 1.4, 0.8 * al, 10, false)

# ============================================================ ulLinh2 U MINH CUỒNG TRIỀU
## Buff 12s: cơn triều hồn cuộn dưới chân, hồn ma xoáy ngược trên thân, đầu lâu vây quanh đầu.
static func _tide(s, t: float, lowq: bool) -> void:
	var up := E.eo(E.sg(t, 0.0, 0.25))
	var fa := E.fo(s, t, 0.85)
	var al := up * fa
	var o := Vector2(0, -8.0)
	E.glow(s, o, 54.0 * up, 0.18 * al)
	# sóng triều: ba lớp sóng cuộn quanh chân
	for k in range(3):
		var wx := 66.0 - 8.0 * float(k)
		var top := PackedVector2Array()
		for i in range(19):
			var x := -wx + 2.0 * wx * float(i) / 18.0
			var crest := sin(x * 0.09 + t * 5.0 + float(k) * 2.1) * (9.0 - 2.0 * float(k)) + 2.0 * sin(x * 0.2 - t * 8.0)
			top.append(Vector2(x * up, GY - 6.0 - 18.0 * float(k + 1) * up * 0.5 + crest))
		for i in range(18):
			var f := (1.0 - 0.15 * float(k))
			E.PG(s, PackedVector2Array([top[i], top[i + 1], Vector2(top[i + 1].x, GY - 2.0), Vector2(top[i].x, GY - 2.0)]), PackedColorArray([E.A(s, 0.55 * al * f), E.A(s, 0.55 * al * f), E.A(s, 0.0), E.A(s, 0.0)]))
		E.PL(s, top, E.K(s, 0.75 * al), 1.8)
		# bọt đầu sóng
		for i in range(0 if lowq else 4):
			var idx := 2 + i * 4
			E.CI(s, top[idx] + Vector2(0, -2.0), 2.0, E.K(s, 0.8 * al))
	E.ering(s, Vector2(0, GY - 4.0), 52.0 * up, 13.0 * up, E.A(s, 0.8 * al), 2.2)
	# hồn ma xoắn ốc đi lên
	var n := 4 if lowq else 6
	for i in range(n):
		var ph := fmod(t * 0.9 + float(i) / float(n), 1.0)
		var a := ph * TAU * 1.3 + float(i) * 1.7
		var pos := Vector2(cos(a) * 36.0, GY - 8.0 - 84.0 * ph + sin(a) * 6.0)
		var dv := Vector2(-sin(a) * 36.0, -84.0 / 1.3 / TAU * 36.0 * 0.15).normalized()
		var f := sin(ph * PI) * al
		if sin(a) > -0.2:
			ghost(s, pos, 6.0, 20.0, 0.7 * f, t + float(i), cos(a) if cos(a) > 0.0 else -1.0)
		else:
			wisp(s, pos, dv, 14.0, 2.4, 0.5 * f, float(i))
	# đầu lâu vây quanh đầu
	for i in range(4):
		var a2 := -t * 3.0 + TAU * float(i) / 4.0
		var hp := Vector2(cos(a2) * 24.0, -50.0 + sin(a2) * 7.0)
		skull(s, hp, 4.6, (0.85 if sin(a2) > 0.0 else 0.4) * al)
	# tia điên cuồng
	for k in range(3):
		var a3 := TAU * float(k) / 3.0 + 0.5 + 0.5 * E.rnd(int(t * 9.0), k)
		var pts := PackedVector2Array([Vector2(cos(a3) * 18.0, -8.0 + sin(a3) * 26.0)])
		var p := pts[0]
		for q in range(1, 4):
			p += Vector2(cos(a3), sin(a3) * 1.2) * 7.0 + Vector2((E.rnd(k * 5 + q, int(t * 12.0)) - 0.5) * 7.0, (E.rnd(k * 3 + q, int(t * 12.0) + 2) - 0.5) * 7.0)
			pts.append(p)
		E.PL(s, pts, E.K(s, 0.8 * al), 1.5)

# ============================================================ ulTuLinhDungHop TỬ LINH DUNG HỢP
## Các bóng ma bay vào hợp nhất vào người, rồi bóng ma khổng lồ khoác lên thân (hào quang kéo dài).
static func _fusion(s, t: float, lowq: bool) -> void:
	var fa := E.fo(s, t, 0.9)
	var o := Vector2(0, -8.0)
	var gc := Vector2(0, GY - 4.0)
	var gather := E.sg(t, 0.02, 0.5)
	# giai đoạn dung hợp: bóng ma xoáy vào người
	if gather < 1.0 or t < 0.62:
		rune(s, gc, 130.0 * E.eo(E.sg(t, 0.0, 0.2)) * (1.0 - 0.4 * gather), 34.0 * E.eo(E.sg(t, 0.0, 0.2)) * (1.0 - 0.4 * gather), t * 3.0, (1.0 - E.sg(t, 0.5, 0.7)) * fa, 14)
		var n := 5 if lowq else 8
		for i in range(n):
			var a0 := TAU * float(i) / float(n) + 0.3
			var g := E.sg(t, 0.04 + 0.03 * float(i), 0.52)
			var rad := 130.0 * (1.0 - g * g * (3.0 - 2.0 * g))
			var a := a0 + g * 2.4
			var pos := o + Vector2(cos(a) * rad, sin(a) * rad * 0.4)
			var vis := E.sg(t, 0.0, 0.08) * (1.0 - E.sg(g, 0.85, 1.0))
			if vis > 0.02:
				var a2 := a0 + maxf(0.0, g - 0.05) * 2.4
				var g2 := maxf(0.0, g - 0.05); var rad2 := 130.0 * (1.0 - g2 * g2 * (3.0 - 2.0 * g2))
				var pos2 := o + Vector2(cos(a2) * rad2, sin(a2) * rad2 * 0.4)
				var sc := 0.45 + 0.55 * (1.0 - g)
				E.PL(s, PackedVector2Array([pos2, pos2.lerp(pos, 0.5), pos]), E.A(s, 0.5 * vis * fa), 6.0 * sc)
				ghost(s, pos, 14.0 * sc, 50.0 * sc, vis * fa, t + float(i), 1.0 if cos(a) < 0.0 else -1.0)
		# điểm hội tụ
		var fl := E.sg(t, 0.46, 0.64)
		if fl > 0.0 and fl < 1.0:
			E.star(s, o, 50.0 * (1.0 - fl * 0.4), (1.0 - fl) * fa, 12)
			E.shock(s, gc, 20.0 + 90.0 * E.eo(fl), 5.0 + 24.0 * E.eo(fl), (1.0 - fl) * fa)
			E.spark(s, o, 0 if lowq else 16, 90.0, fl, (1.0 - fl) * fa, 5)
	# trạng thái hợp thể: bóng ma khổng lồ sau lưng, hào quang tử linh, hồn nhỏ xoay quanh
	var on := E.eo(E.sg(t, 0.5, 0.78))
	if on > 0.0:
		var al := on * fa
		E.glow(s, o, 60.0 * on, 0.2 * al)
		var big := Vector2(-14.0, -22.0 - 3.0 * sin(t * 2.4))
		ghost(s, big, 40.0 * on, 120.0 * on, 0.6 * al, t, 1.0)
		# hai cánh tay hồn giơ lên hai bên
		for sd in [-1.0, 1.0]:
			var sh := Vector2(big.x + float(sd) * 30.0, big.y + 6.0)
			var el := sh + Vector2(float(sd) * 26.0, -18.0 + 4.0 * sin(t * 3.0 + float(sd)))
			var hn := el + Vector2(float(sd) * 14.0, -22.0)
			E.PL(s, PackedVector2Array([sh, el, hn]), E.A(s, 0.35 * al), 9.0)
			E.PL(s, PackedVector2Array([sh, el, hn]), E.K(s, 0.55 * al), 1.6)
			for f in range(3):
				E.L(s, hn, hn + Vector2(float(sd) * (6.0 + 3.0 * float(f)), -10.0 - 4.0 * float(f)) , E.K(s, 0.8 * al), 1.4)
		E.ering(s, gc, 50.0 * on, 13.0 * on, E.A(s, 0.85 * al), 2.4)
		rune(s, gc, 64.0 * on, 16.0 * on, t * 1.6, 0.75 * al, 12)
		# hồn nhỏ dung hợp xoay quanh người
		var m := 3 if lowq else 5
		for i in range(m):
			var a3 := t * 2.0 + TAU * float(i) / float(m)
			var pp := o + Vector2(cos(a3) * 34.0, sin(a3) * 20.0 - 6.0)
			wisp(s, pp, Vector2(-sin(a3), cos(a3) * 0.6).normalized(), 18.0, 2.6, al * (1.0 if sin(a3) > 0.0 else 0.5), float(i))
		# đôi mắt hợp thể sáng rực trên đầu
		for k in range(2):
			var ex := Vector2(-2.0 + 10.0 * float(k), -30.0)
			E.L(s, ex + Vector2(-3, 1), ex + Vector2(4, -1), E.K(s, al), 2.4)
			E.glow(s, ex, 6.0, 0.5 * al)
