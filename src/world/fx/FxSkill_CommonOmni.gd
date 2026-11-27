extends RefCounted
## Hiệu ứng kỹ năng VẼ LẠI RIÊNG — chung + toàn năng (vn6 là đạn: xem FxProj.gd).
## Quy ước như FxSkill_Swordsman/Archer/Assassin: place "bodyf", gốc = thân nhân vật, +x = hướng nhìn, y âm = lên, mặt đất y~+32. Bộ nét vẽ dùng chung: E (FxSkill_Swordsman).
const E := preload("res://src/world/fx/FxSkill_Swordsman.gd")

const IDS := {
	"ulChung1": "mw_quake", "ulChung2": "mw_will", "ulChung3": "mw_voidslash", "ulSinhTu": "mw_lifedeath", "ulToanNangSuper": "mw_allin",
	"vn1": "mw_awaken", "vn2": "mw_elemfuse", "vn3": "mw_flow", "vn4": "mw_balance", "vn5": "mw_vigor", "vn7": "mw_tripleslash",
}
const CFG := {
	"mw_quake": {"place": "bodyf", "dur": 1.4, "nopop": true, "nobig": true, "rumble": 7.0},
	"mw_will": {"place": "bodyf", "dur": 1.5, "nopop": true, "nobig": true},
	"mw_voidslash": {"place": "bodyf", "dur": 1.4, "nopop": true, "nobig": true, "rumble": 5.0},
	"mw_lifedeath": {"place": "bodyf", "dur": 1.8, "nopop": true, "nobig": true},
	"mw_allin": {"place": "bodyf", "dur": 2.6, "nopop": true, "nobig": true, "rumble": 8.0},
	"mw_awaken": {"place": "bodyf", "dur": 1.6, "nopop": true, "nobig": true},
	"mw_elemfuse": {"place": "bodyf", "dur": 1.5, "nopop": true, "nobig": true, "rumble": 3.0},
	"mw_flow": {"place": "bodyf", "dur": 1.5, "nopop": true, "nobig": true},
	"mw_balance": {"place": "bodyf", "dur": 1.5, "nopop": true, "nobig": true},
	"mw_vigor": {"place": "bodyf", "dur": 1.3, "nopop": true, "nobig": true},
	"mw_tripleslash": {"place": "bodyf", "dur": 1.1, "nopop": true, "nobig": true, "rumble": 3.0},
}
## Sig hỗ trợ hào quang buff kéo dài (s.steady): liệt kê tên sig ở đây và xử lý trong draw_aura.
const AURA_IDS := ["mw_will", "mw_awaken", "mw_flow", "mw_balance"]

static func draw(s, sg: String, t: float, lowq: bool) -> void:
	match sg:
		"mw_quake": _quake(s, t, lowq)
		"mw_will": _will(s, t, lowq)
		"mw_voidslash": _voidslash(s, t, lowq)
		"mw_lifedeath": _lifedeath(s, t, lowq)
		"mw_allin": _allin(s, t, lowq)
		"mw_awaken": _awaken(s, t, lowq)
		"mw_elemfuse": _elemfuse(s, t, lowq)
		"mw_flow": _flow(s, t, lowq)
		"mw_balance": _balance(s, t, lowq)
		"mw_vigor": _vigor(s, t, lowq)
		"mw_tripleslash": _tripleslash(s, t, lowq)

static func draw_aura(s, sg: String, t: float, lowq: bool) -> void:
	var tt := 1.0 + t
	match sg:
		"mw_will": _will(s, tt, lowq)
		"mw_awaken": _awaken(s, tt, lowq)
		"mw_flow": _flow(s, tt, lowq)
		"mw_balance": _balance(s, tt, lowq)

# ============================================================ tiện ích
const GY := 32.0
const GOLD := Color(1.0, 0.8, 0.28)
const SILVER := Color(0.82, 0.85, 0.92)
const INK := Color(0.04, 0.04, 0.07)
const PAPER := Color(0.96, 0.96, 0.98)

static func HC(h: float, al: float, sat: float = 0.75, v: float = 1.0) -> Color:
	return Color.from_hsv(fposmod(h, 1.0), sat, v, clampf(al, 0.0, 1.0))

static func CA(c: Color, al: float) -> Color:
	return Color(c.r, c.g, c.b, clampf(al, 0.0, 1.0))

## Quả cầu sáng màu tuỳ ý (quầng + lõi trắng).
static func orb(s, p: Vector2, r: float, col: Color, al: float) -> void:
	if al <= 0.01 or r < 1.0: return
	E.CI(s, p, r * 1.9, CA(col, 0.09 * al))
	E.CI(s, p, r * 1.35, CA(col, 0.2 * al))
	E.CI(s, p, r, CA(col, 0.8 * al))
	E.CI(s, p, r * 0.5, Color(1, 1, 1, 0.9 * al))

## Hòn đá vụn (đa giác sao-lồi nâu xám, mặt sáng).
static func rock(s, p: Vector2, r: float, rot: float, al: float) -> void:
	if al <= 0.01 or r < 2.0: return
	var pts := PackedVector2Array()
	var hl := PackedVector2Array()
	for k in range(6):
		var a := TAU * float(k) / 6.0 + rot
		var rr := r * (0.7 + 0.45 * E.rnd(k, 11))
		pts.append(p + Vector2(cos(a), sin(a)) * rr)
		if k < 4:
			hl.append(p + Vector2(cos(a + 0.2), sin(a + 0.2)) * rr * 0.62 + Vector2(-r * 0.12, -r * 0.14))
	E.P(s, pts, Color(0.34, 0.28, 0.26, 0.95 * al))
	E.P(s, hl, Color(0.62, 0.54, 0.46, 0.85 * al))

## Thái cực đồ: đĩa đen + nửa trắng + hai chấm, quay theo rot.
static func taiji(s, c: Vector2, r: float, rot: float, al: float) -> void:
	if al <= 0.01 or r < 3.0: return
	E.CI(s, c, r * 1.25, Color(0.5, 0.5, 0.6, 0.12 * al))
	E.CI(s, c, r, CA(INK, 0.95 * al))
	var half := PackedVector2Array()
	for i in range(25):
		var a := rot + PI * float(i) / 24.0
		half.append(c + Vector2(cos(a), sin(a)) * r)
	E.P(s, half, CA(PAPER, 0.96 * al))
	var d0 := Vector2(cos(rot), sin(rot))
	var d1 := Vector2(cos(rot + PI), sin(rot + PI))
	E.CI(s, c + d0 * r * 0.5, r * 0.5, CA(PAPER, 0.96 * al))
	E.CI(s, c + d1 * r * 0.5, r * 0.5, CA(INK, 0.96 * al))
	E.CI(s, c + d0 * r * 0.5, r * 0.14, CA(INK, al))
	E.CI(s, c + d1 * r * 0.5, r * 0.14, CA(PAPER, al))
	E.AR(s, c, r, 0.0, TAU, 40, Color(0.75, 0.75, 0.85, 0.9 * al), 1.6)

## Chữ thập (hồi máu).
static func cross(s, p: Vector2, r: float, col: Color) -> void:
	if col.a <= 0.01 or r < 1.5: return
	var w := r * 0.36
	E.P(s, PackedVector2Array([p + Vector2(-w, -r), p + Vector2(w, -r), p + Vector2(w, r), p + Vector2(-w, r)]), col)
	E.P(s, PackedVector2Array([p + Vector2(-r, -w), p + Vector2(r, -w), p + Vector2(r, w), p + Vector2(-r, w)]), col)

## Mắt xích: vòng elip bạc xoay theo ang.
static func link(s, p: Vector2, ang: float, al: float) -> void:
	E.ering(s, p, 8.0, 3.6, Color(0.55, 0.58, 0.66, 0.9 * al), 3.4, ang)
	E.ering(s, p, 8.0, 3.6, Color(0.92, 0.94, 1.0, 0.95 * al), 1.4, ang)

## Lưỡi lửa màu: gốc đỏ cam đậm → thân cam → ngọn trong suốt, lõi vàng nhỏ ở gốc.
static func cflame(s, base: Vector2, h: float, w: float, t: float, ph: float, al: float) -> void:
	if al <= 0.01 or h < 4.0: return
	var steps := 9
	var l := PackedVector2Array()
	var r := PackedVector2Array()
	var c := PackedVector2Array()
	for i in range(steps + 1):
		var u := float(i) / float(steps)
		var sway := sin(t * 11.0 + ph + u * 3.0) * u * w * 0.55
		var hw := w * pow(1.0 - u, 0.75) * (1.0 + 0.18 * sin(u * 9.0 + t * 8.0 + ph))
		l.append(base + Vector2(sway - hw, -h * u))
		r.append(base + Vector2(sway + hw, -h * u))
		c.append(base + Vector2(sway, -h * u))
	for i in range(steps):
		var u0 := float(i) / float(steps)
		var u1 := float(i + 1) / float(steps)
		var k0 := Color(1.0, 0.18 + 0.5 * u0, 0.05 + 0.1 * u0).lerp(Color(1.0, 0.6, 0.15), u0)
		var k1 := Color(1.0, 0.18 + 0.5 * u1, 0.05 + 0.1 * u1).lerp(Color(1.0, 0.6, 0.15), u1)
		var a0 := al * 0.85 * (1.0 - u0)
		var a1 := al * 0.85 * (1.0 - u1)
		E.PG(s, PackedVector2Array([l[i], r[i], r[i + 1], l[i + 1]]), PackedColorArray([CA(k0, a0), CA(k0, a0), CA(k1, a1), CA(k1, a1)]))
		if u0 < 0.55:
			var f0 := 0.45
			var ca := Color(1.0, 0.9, 0.45)
			var q0 := al * (1.0 - u0 / 0.55)
			var q1 := al * maxf(0.0, 1.0 - u1 / 0.55)
			E.PG(s, PackedVector2Array([c[i].lerp(l[i], f0), c[i].lerp(r[i], f0), c[i + 1].lerp(r[i + 1], f0), c[i + 1].lerp(l[i + 1], f0)]), PackedColorArray([CA(ca, q0 * 0.85), CA(ca, q0 * 0.85), CA(ca, q1 * 0.85), CA(ca, q1 * 0.85)]))
	E.PL(s, l, CA(Color(1.0, 0.35, 0.08), al * 0.5), 1.0)
	E.PL(s, r, CA(Color(1.0, 0.35, 0.08), al * 0.5), 1.0)

## Vết nứt hư không thẳng đứng, xé từ trên xuống (p 0..1).
static func rift(s, x: float, p: float, al: float, seed: int) -> void:
	if p <= 0.02 or al <= 0.01: return
	var ytop := -235.0
	var n := 16
	var L := PackedVector2Array()
	var R := PackedVector2Array()
	var Li := PackedVector2Array()
	var Ri := PackedVector2Array()
	var Lc := PackedVector2Array()
	var Rc := PackedVector2Array()
	var wmax := 26.0
	for i in range(n + 1):
		var u := float(i) / float(n)
		var y := lerpf(ytop, GY - 2.0, u * p)
		var xo := x + (u - 0.5) * 34.0 + (E.rnd(i, seed + 3) - 0.5) * 8.0
		var w := (3.0 + wmax * pow(sin(PI * u), 0.8)) * (0.35 + 0.65 * E.sg(p, 0.0, 0.35))
		var wl := w * (0.55 + 0.45 * E.rnd(i, seed + 5))
		var wr := w * (0.55 + 0.45 * E.rnd(i, seed + 6))
		L.append(Vector2(xo - wl, y))
		R.append(Vector2(xo + wr, y))
		Li.append(Vector2(xo - wl * 0.55, y))
		Ri.append(Vector2(xo + wr * 0.55, y))
		Lc.append(Vector2(xo - wl * 0.2, y))
		Rc.append(Vector2(xo + wr * 0.2, y))
	var hull := L.duplicate()
	var inner := Li.duplicate()
	var core := Lc.duplicate()
	for i in range(n, -1, -1):
		hull.append(R[i])
		inner.append(Ri[i])
		core.append(Rc[i])
	# quầng sáng tím quanh mép
	E.PL(s, L, E.A(s, 0.22 * al), 12.0)
	E.PL(s, R, E.A(s, 0.22 * al), 12.0)
	E.P(s, hull, Color(0.03, 0.0, 0.08, 0.96 * al))
	E.P(s, inner, Color(0.26, 0.08, 0.5, 0.85 * al))
	E.P(s, core, Color(0.86, 0.66, 1.0, 0.85 * al))
	E.PL(s, L, E.K(s, al), 2.0)
	E.PL(s, R, E.K(s, al), 2.0)
	# sao trong khe hư không
	for i in range(10):
		var u2 := E.rnd(i, seed + 20) * p
		var yy := lerpf(ytop, GY - 2.0, u2)
		var xx := x + (u2 - 0.5) * 34.0 + (E.rnd(i, seed + 22) - 0.5) * 12.0
		E.CI(s, Vector2(xx, yy), 1.2 + 1.2 * E.rnd(i, seed + 23), Color(1, 1, 1, 0.9 * al))

# ============================================================ ulChung1 Thiên Địa Chấn Động
## aoe r240 quanh người: dồn nguyên lực → nổ tung, sóng xung kích trời (vòng tròn đứng) + đất (vòng elip), nứt đất, đá văng.
static func _quake(s, t: float, lowq: bool) -> void:
	var R := 240.0
	var fa := E.fadeo(t, 0.78)
	var bc := Vector2(0, -8.0)
	var gc := Vector2(0, GY - 4.0)
	# 0 - 0.14: dồn nguyên lực vào thân
	var ch := E.sg(t, 0.0, 0.14)
	if ch > 0.0 and ch < 1.0 or t < 0.2:
		for i in range(0 if lowq else 14):
			var a := TAU * E.rnd(i, 1)
			var d := (150.0 - 130.0 * ch) * (0.6 + 0.4 * E.rnd(i, 2))
			var p := bc + Vector2(cos(a), sin(a) * 0.8) * d
			E.L(s, p, p + (bc - p).normalized() * 16.0, E.K(s, (1.0 - ch) * 0.9), 2.0)
		E.glow(s, bc, 14.0 + 40.0 * ch, 0.55 * (1.0 - E.sg(t, 0.14, 0.24)))
	var e := E.eo(E.sg(t, 0.12, 0.62))
	var f := 1.0 - E.sg(t, 0.12, 0.9)
	if t < 0.12: return
	# cầu nguyên lực nổ
	var flash := 1.0 - E.sg(t, 0.12, 0.34)
	E.glow(s, bc, 150.0 * E.eo(E.sg(t, 0.12, 0.3)), 0.85 * flash)
	E.star(s, bc, 70.0 * (1.0 - E.sg(t, 0.12, 0.4)), flash, 12)
	# sóng xung kích trời: vòng tròn đứng + vòng ngoài
	for k in range(3):
		var rr := R * 0.95 * e * (1.0 - 0.22 * float(k))
		var kf := f * (1.0 - 0.25 * float(k))
		E.AR(s, bc, rr, 0.0, TAU, 72, E.A(s, 0.2 * kf), 12.0)
		E.AR(s, bc, rr, 0.0, TAU, 72, E.A(s, 0.7 * kf), 5.0)
		E.AR(s, bc, rr, 0.0, TAU, 72, E.K(s, kf), 1.8)
	# sóng xung kích đất
	E.shock(s, gc, R * e, R * e * 0.26, f * fa)
	E.shock(s, gc, R * 0.66 * E.eo(E.sg(t, 0.2, 0.7)), R * 0.66 * E.eo(E.sg(t, 0.2, 0.7)) * 0.26, f * fa * 0.8)
	# vết nứt lan trên đất
	E.crack(s, Vector2(0, GY - 2.0), R * 0.95 * e, fa * (1.0 - E.sg(t, 0.6, 1.0)), 5)
	# tia nguyên lực toả ra
	for k in range(0 if lowq else 12):
		var a2 := TAU * float(k) / 12.0 + 0.2
		var d0 := Vector2(cos(a2), sin(a2) * 0.9)
		var e2 := E.eo(E.sg(t, 0.14, 0.5))
		E.cut(s, bc + d0 * 30.0, bc + d0 * (40.0 + 190.0 * e2), 3.0, f * 0.8)
	# đá văng lên rồi rơi
	var n := 7 if lowq else 14
	for i in range(n):
		var u := E.sg(t, 0.14 + 0.03 * E.rnd(i, 4), 0.85)
		if u <= 0.0 or u >= 1.0: continue
		var x := (E.rnd(i, 5) - 0.5) * 2.0 * R * 0.8 * E.eo(E.sg(t, 0.12, 0.5))
		var hh := 70.0 + 100.0 * E.rnd(i, 6)
		var y := GY - 6.0 - hh * 4.0 * u * (1.0 - u)
		rock(s, Vector2(x, y), 5.0 + 6.0 * E.rnd(i, 7), u * 9.0 * (E.rnd(i, 8) - 0.5) * 2.0, fa * (1.0 - E.sg(u, 0.8, 1.0)))
	E.dust(s, gc, R * 0.9, E.sg(t, 0.12, 0.8), (1.0 - E.sg(t, 0.4, 0.95)) * 0.9, 12 if not lowq else 6, 2)
	E.spark(s, bc, 18 if not lowq else 8, R * 0.9, E.sg(t, 0.12, 0.8), f, 3)

# ============================================================ ulChung2 Ý Chí Bất Diệt (buff)
## Lửa ý chí quanh thân, xích bị bẻ gãy bắn ra, sao ý chí xoay quanh đầu.
static func _will(s, t: float, lowq: bool) -> void:
	var up := E.eo(E.sg(t, 0.0, 0.25))
	var fa := E.fo(s, t, 0.85)
	var al := up * fa
	var bc := Vector2(0, -6.0)
	var fire := Color(1.0, 0.36, 0.08)
	E.CI(s, bc + Vector2(0, -10.0), 56.0 * up, CA(fire, 0.07 * al))
	E.CI(s, bc + Vector2(0, 4.0), 40.0 * up, CA(fire, 0.08 * al))
	E.ering(s, Vector2(0, GY - 4.0), 48.0 * up, 12.0 * up, CA(fire, 0.9 * al), 3.0)
	E.ering(s, Vector2(0, GY - 4.0), 44.0 * up, 11.0 * up, E.A(s, 0.8 * al), 2.4)
	E.ering(s, Vector2(0, GY - 4.0), 30.0 * up, 7.5 * up, E.K(s, 0.5 * al), 1.4)
	# lửa ý chí: hai tầng
	var n := 7 if lowq else 12
	for i in range(n):
		var a := TAU * float(i) / float(n)
		var base := Vector2(cos(a) * 34.0, GY - 4.0 + sin(a) * 9.0)
		var back := 0.55 if sin(a) < 0.0 else 1.0
		cflame(s, base, (56.0 + 34.0 * E.rnd(i, 2)) * up, 8.0, t, float(i), al * back)
	# xích: vòng quanh thân → vỡ ra
	var pb := 1.0 if s.steady else E.sg(t, 0.14, 0.34)
	var nl := 8
	for i in range(nl):
		var a2 := TAU * float(i) / float(nl) + t * (0.6 * E.eo(pb))
		var rr := lerpf(24.0, 54.0, E.eo(pb))
		var p := Vector2(cos(a2) * rr, -8.0 + sin(a2) * rr * 0.55 + 6.0 * sin(t * 3.0 + float(i)))
		var tilt := a2 + PI * 0.5 + (E.rnd(i, 3) - 0.5) * 2.4 * E.eo(pb)
		link(s, p, tilt, al * (0.6 + 0.4 * (sin(a2) * 0.5 + 0.5)))
	if not s.steady and pb > 0.0 and pb < 1.0:
		for i in range(nl):
			var a3 := TAU * float(i) / float(nl)
			E.flare(s, Vector2(cos(a3) * 34.0, -8.0 + sin(a3) * 20.0), 7.0 * (1.0 - pb), al)
	# sao ý chí quanh đầu
	for k in range(4):
		var a4 := t * 2.4 + TAU * float(k) / 4.0
		var p2 := Vector2(cos(a4) * 24.0, -52.0 + sin(a4) * 7.0)
		E.star(s, p2, 6.0 + 2.0 * sin(t * 8.0 + float(k)), al * (0.5 + 0.5 * sin(a4) * 0.5 + 0.25), 5)
	# tàn lửa bay lên
	for i in range(0 if lowq else 14):
		var ph := fmod(t * 0.9 + E.rnd(i, 7), 1.0)
		var px := (E.rnd(i, 8) - 0.5) * 60.0 + sin(ph * 6.0 + float(i)) * 6.0
		E.CI(s, Vector2(px, GY - 6.0 - 100.0 * ph), 2.2 * (1.0 - ph) + 0.6, E.K(s, al * (1.0 - ph)))

# ============================================================ ulChung3 Hư Không Tuyệt Trảm
## Hai vết nứt hư không khổng lồ xé xuống trước mặt (x≈140 rồi x≈270): trễ 0.3s + 0.22s.
static func _voidslash(s, t: float, lowq: bool) -> void:
	var fa := E.fadeo(t, 0.78)
	var xs := [140.0, 270.0]
	var st := [0.23, 0.4]
	# tối sầm vùng chém
	E.glow(s, Vector2(200.0, -40.0), 160.0 * E.sg(t, 0.15, 0.4), 0.0)
	for k in range(2):
		var x: float = xs[k]
		var t0: float = st[k]
		# điểm báo dưới đất
		var wn := E.sg(t, t0 - 0.2, t0)
		if wn > 0.0 and t < t0 + 0.1:
			E.ering(s, Vector2(x, GY - 4.0), 40.0 * wn, 10.0 * wn, E.A(s, 0.8 * (1.0 - E.sg(t, t0, t0 + 0.1))), 2.0)
		var q := E.eo(E.sg(t, t0, t0 + 0.12))
		if q <= 0.0: continue
		# đường chém sáng rạch xuống rồi nứt toác
		var life := fa
		if q < 1.0:
			var yy := lerpf(-235.0, GY, q)
			E.cut(s, Vector2(x - 20.0, -235.0), Vector2(x + 14.0, yy), 5.0, 1.0)
			E.flare(s, Vector2(x + 14.0, yy), 12.0, 1.0)
		rift(s, x, q, life, 3 + k * 7)
		# hư không cuộn xoáy hút về khe
		if q >= 1.0:
			var h := E.sg(t, t0 + 0.12, t0 + 0.6)
			E.glow(s, Vector2(x, -90.0), 70.0, 0.25 * life)
			E.crack(s, Vector2(x, GY - 2.0), 110.0 * E.eo(h), life, 9 + k)
			E.shock(s, Vector2(x, GY - 3.0), 20.0 + 130.0 * E.eo(h), (20.0 + 130.0 * E.eo(h)) * 0.26, (1.0 - h) * life)
			for i in range(0 if lowq else 10):
				var u := E.rnd(i, 30 + k)
				var side := -1.0 if i % 2 == 0 else 1.0
				var ph := fmod(h * 1.2 + u, 1.0)
				E.CI(s, Vector2(x + side * (40.0 - 36.0 * ph) * (0.5 + u), -u * 190.0 + 30.0), 2.2 * (1.0 - ph) + 0.6, E.K(s, life * (1.0 - ph)))
			for i in range(5 if lowq else 9):
				var uu := E.sg(t, t0 + 0.1 + 0.02 * float(i), t0 + 0.7)
				if uu <= 0.0 or uu >= 1.0: continue
				var rx := x + (E.rnd(i, 40 + k) - 0.5) * 90.0 * uu
				var ry := GY - 6.0 - (60.0 + 50.0 * E.rnd(i, 41)) * 4.0 * uu * (1.0 - uu)
				rock(s, Vector2(rx, ry), 4.0 + 4.0 * E.rnd(i, 42), uu * 6.0, life * (1.0 - E.sg(uu, 0.75, 1.0)))
	# vệt sáng đứt giữa hai khe
	if t > 0.45:
		var e2 := E.sg(t, 0.45, 0.6)
		E.L(s, Vector2(140.0, -30.0), Vector2(140.0 + 130.0 * e2, -30.0), E.K(s, fa * 0.5 * (1.0 - e2)), 2.0)

# ============================================================ ulSinhTu Sinh Tử Đồng Quy
## Thái cực đồ xoáy phía trước (≈140px): hút xoáy đen-trắng, nén lại rồi tan thành khói trắng-đen.
static func _lifedeath(s, t: float, lowq: bool) -> void:
	var C := Vector2(140.0, -34.0)
	var grow := E.eo(E.sg(t, 0.0, 0.3))
	var fa := 1.0 - E.sg(t, 0.62, 0.86)
	var rot := t * 7.0 + 8.0 * E.ei(E.sg(t, 0.3, 0.62)) * 0.4
	# vòng dưới đất đen-trắng
	if t < 0.9:
		E.ering(s, Vector2(C.x, GY - 4.0), 70.0 * grow, 18.0 * grow, Color(0.9, 0.9, 1.0, 0.35 * fa), 5.0)
		E.ering(s, Vector2(C.x, GY - 4.0), 70.0 * grow, 18.0 * grow, Color(0.05, 0.05, 0.1, 0.7 * fa), 2.4, 0.0)
	# xoáy hút: hai nhánh xoắn đen/trắng
	var rr := 92.0 * grow * (1.0 - 0.55 * E.ei(E.sg(t, 0.35, 0.62)))
	for arm in range(4):
		var pts := PackedVector2Array()
		for i in range(26):
			var u := float(i) / 25.0
			var a := rot * 0.8 + float(arm) * PI * 0.5 + u * 3.4
			pts.append(C + Vector2(cos(a), sin(a) * 0.9) * (rr * (0.25 + 0.75 * u)))
		var white := arm % 2 == 0
		E.PL(s, pts, (Color(0.9, 0.9, 1.0, 0.18 * fa) if white else Color(0.1, 0.05, 0.2, 0.3 * fa)), 10.0)
		E.PL(s, pts, (Color(1, 1, 1, 0.85 * fa) if white else Color(0.03, 0.02, 0.06, 0.95 * fa)), 3.0)
	# bát quái: 8 vạch xung quanh
	for k in range(8):
		var a2 := -rot * 0.5 + TAU * float(k) / 8.0
		var d := Vector2(cos(a2), sin(a2))
		var br := 64.0 * grow
		var tg := d.orthogonal() * 6.0
		var full := k % 3 != 1
		if full:
			E.L(s, C + d * br - tg, C + d * (br + 9.0) + tg, Color(1, 1, 1, 0.8 * fa), 2.2)
		else:
			E.L(s, C + d * br - tg, C + d * br - tg * 0.2, Color(1, 1, 1, 0.8 * fa), 2.2)
			E.L(s, C + d * (br + 9.0) + tg * 0.2, C + d * (br + 9.0) + tg, Color(1, 1, 1, 0.8 * fa), 2.2)
	# thái cực đồ
	var sz := 52.0 * grow * (1.0 - 0.7 * E.ei(E.sg(t, 0.5, 0.64)))
	taiji(s, C, sz, rot, fa)
	# chốt: nén rồi chớp
	var imp := E.sg(t, 0.52, 0.66)
	if imp > 0.0:
		E.star(s, C, 36.0 * (1.0 - E.sg(t, 0.62, 0.9)), (1.0 - E.sg(t, 0.62, 0.9)), 10)
		E.cut(s, C + Vector2(-90.0, 0), C + Vector2(90.0, 0), 3.0, (1.0 - E.sg(t, 0.62, 0.8)) * imp)
	# tan thành khói trắng-đen
	var sm := E.sg(t, 0.6, 1.0)
	if sm > 0.0:
		var n := 9 if lowq else 18
		for i in range(n):
			var a3 := TAU * E.rnd(i, 1)
			var d3 := (14.0 + 62.0 * E.rnd(i, 2)) * E.eo(sm)
			var p := C + Vector2(cos(a3) * d3, sin(a3) * d3 * 0.7 - 50.0 * sm * (0.3 + E.rnd(i, 3)))
			var r := (9.0 + 12.0 * E.rnd(i, 4)) * (0.6 + sm)
			var al := (1.0 - sm) * 0.8
			var white := i % 2 == 0
			E.CI(s, p, r, (Color(0.96, 0.96, 1.0, 0.45 * al) if white else Color(0.06, 0.05, 0.1, 0.55 * al)))
			E.CI(s, p + Vector2(-r * 0.2, -r * 0.2), r * 0.55, (Color(1, 1, 1, 0.4 * al) if white else Color(0.2, 0.18, 0.28, 0.4 * al)))
	E.spark(s, C, 12 if not lowq else 6, 90.0, E.sg(t, 0.55, 1.0), 1.0 - E.sg(t, 0.55, 1.0), 4)

# ============================================================ ulToanNangSuper Vạn Pháp Quy Nhất
## Ghép: dồn lực → Địa Chấn + Hư Không Trảm + Ý Chí Bất Diệt đồng thời → vụ nổ cầu vồng.
static func _allin(s, t: float, lowq: bool) -> void:
	var bc := Vector2(0, -8.0)
	# 0 - 0.12 sáu viên ngọc nguyên tố hội tụ
	var g := E.sg(t, 0.0, 0.14)
	if t < 0.2:
		var fo := 1.0 - E.sg(t, 0.14, 0.2)
		for i in range(6):
			var a := TAU * float(i) / 6.0 + g * 3.0
			var d := 150.0 * (1.0 - E.eo(g)) + 10.0
			var p := bc + Vector2(cos(a) * d, sin(a) * d * 0.7)
			orb(s, p, 9.0, HC(float(i) / 6.0, 1.0), fo)
		E.glow(s, bc, 20.0 + 60.0 * g, 0.5 * fo)
		E.ering(s, Vector2(0, GY - 4.0), 60.0 * g, 15.0 * g, Color(1, 1, 1, 0.6 * fo), 2.0)
	# ba tuyệt kỹ chung cùng lúc
	_quake(s, E.sg(t, 0.1, 0.5), lowq)
	_voidslash(s, E.sg(t, 0.16, 0.66), lowq)
	_will(s, E.sg(t, 0.1, 0.7), lowq)
	# vụ nổ cầu vồng
	var b := E.sg(t, 0.64, 1.0)
	if b <= 0.0: return
	var R := 400.0
	var e := E.eo(E.sg(b, 0.0, 0.6))
	var f := 1.0 - E.sg(b, 0.5, 1.0)
	var gc := Vector2(0, GY - 4.0)
	var fl := 1.0 - E.sg(b, 0.0, 0.35)
	E.glow(s, bc, 230.0 * E.eo(E.sg(b, 0.0, 0.3)), 0.9 * fl)
	E.star(s, bc, 110.0 * (1.0 - E.sg(b, 0.0, 0.5) * 0.6), f, 16)
	# 7 vòng sóng cầu vồng: trời (vòng tròn) + đất (elip)
	for i in range(7):
		var h := float(i) / 7.0
		var k := 1.0 - 0.07 * float(i)
		var rr := R * e * k
		E.ering(s, gc, rr, rr * 0.26, HC(h, 0.25 * f, 0.8), 12.0)
		E.ering(s, gc, rr, rr * 0.26, HC(h, 0.9 * f, 0.7), 4.0)
		E.AR(s, bc, rr * 0.72, 0.0, TAU, 72, HC(h, 0.22 * f, 0.8), 9.0)
		E.AR(s, bc, rr * 0.72, 0.0, TAU, 72, HC(h, 0.9 * f, 0.6), 2.6)
	# tia cầu vồng toả ra
	var nr := 10 if lowq else 24
	for k in range(nr):
		var a2 := TAU * float(k) / float(nr) + 0.1
		var d := Vector2(cos(a2), sin(a2) * 0.9)
		var e2 := E.eo(E.sg(b, 0.0, 0.5))
		var p0 := bc + d * 36.0
		var p1 := bc + d * (50.0 + 320.0 * e2)
		E.L(s, p0, p1, HC(float(k) / float(nr), 0.35 * f), 8.0)
		E.L(s, p0, p1, HC(float(k) / float(nr), 0.95 * f, 0.4), 2.4)
	# cột sáng cầu vồng dọc
	for i in range(5):
		var h2 := float(i) / 5.0
		var w := 30.0 - 5.0 * float(i)
		E.PG(s, PackedVector2Array([Vector2(-w, -300.0), Vector2(w, -300.0), Vector2(w * 1.2, GY), Vector2(-w * 1.2, GY)]), PackedColorArray([HC(h2, 0.0), HC(h2, 0.0), HC(h2, 0.14 * f * E.sg(b, 0.0, 0.2)), HC(h2, 0.14 * f * E.sg(b, 0.0, 0.2))]))
	E.crack(s, Vector2(0, GY - 2.0), R * 0.9 * e, f, 7)
	E.spark(s, bc, 30 if not lowq else 12, R, E.sg(b, 0.0, 0.8), f, 5)
	E.dust(s, gc, R * 0.9, E.sg(b, 0.0, 0.8), f, 14 if not lowq else 6, 6)

# ============================================================ vn1 Thức Tỉnh Tối Thượng (buff)
## Vàng-trắng rực rỡ: cột sáng, tia quang quay phía sau, cánh sáng, vầng hào quang trên đầu, mắt sáng.
static func _awaken(s, t: float, lowq: bool) -> void:
	var up := E.eo(E.sg(t, 0.0, 0.28))
	var fa := E.fo(s, t, 0.85)
	var al := up * fa
	var bc := Vector2(0, -8.0)
	# cột sáng vàng
	for i in range(5):
		var k := 1.0 - float(i) / 5.0
		E.PG(s, PackedVector2Array([Vector2(-30.0 * k, -270.0), Vector2(30.0 * k, -270.0), Vector2(36.0 * k, GY), Vector2(-36.0 * k, GY)]), PackedColorArray([CA(GOLD, 0.0), CA(GOLD, 0.0), CA(GOLD, 0.09 * al), CA(GOLD, 0.09 * al)]))
	# tia quang quay phía sau
	var nr := 10 if lowq else 16
	for i in range(nr):
		var a := t * 0.7 + TAU * float(i) / float(nr)
		var d := Vector2(cos(a), sin(a) * 0.95)
		var ln := (90.0 + 70.0 * E.rnd(i, 2)) * up
		var n2 := d.orthogonal() * 4.5
		E.PG(s, PackedVector2Array([bc + d * 26.0 + n2, bc + d * ln, bc + d * 26.0 - n2]), PackedColorArray([CA(GOLD, 0.5 * al), CA(GOLD, 0.0), CA(GOLD, 0.5 * al)]))
	E.glow(s, bc, 56.0 * up, 0.2 * al)
	# cánh sáng hai bên lưng
	for side in range(2):
		var sd := -1.0 if side == 0 else 1.0
		for f in range(6):
			var u := float(f) / 5.0
			var ang := -PI * 0.5 + sd * (0.55 + 0.95 * u) + 0.06 * sin(t * 3.0 + float(f))
			var ln2 := (84.0 - 30.0 * u) * up
			var root := Vector2(sd * 8.0, -16.0)
			var dd := Vector2(cos(ang), sin(ang))
			var nn := dd.orthogonal() * 5.5
			E.PG(s, PackedVector2Array([root + nn * 0.4, root + dd * ln2 * 0.55 + nn, root + dd * ln2, root + dd * ln2 * 0.55 - nn, root - nn * 0.4]), PackedColorArray([CA(GOLD, 0.8 * al), CA(GOLD, 0.6 * al), CA(Color(1, 1, 0.9), 0.15 * al), CA(GOLD, 0.6 * al), CA(GOLD, 0.8 * al)]))
			E.L(s, root, root + dd * ln2, Color(1, 1, 0.92, 0.85 * al), 1.5)
	# vầng hào quang trên đầu
	var hp := Vector2(2.0, -62.0)
	E.ering(s, hp, 24.0 * up, 7.0 * up, CA(GOLD, 0.9 * al), 3.0)
	E.ering(s, hp, 24.0 * up, 7.0 * up, Color(1, 1, 0.95, al), 1.2)
	E.star(s, hp + Vector2(0, -22.0), 13.0 * up, al, 8)
	# mắt sáng
	for k in range(2):
		var ex := Vector2(-2.0 + 11.0 * float(k), -26.0)
		E.L(s, ex + Vector2(-4, 1), ex + Vector2(4, -1.5), Color(1, 1, 0.95, al), 2.8)
		E.glow(s, ex, 9.0, 0.5 * al)
	# vòng đất vàng
	E.ering(s, Vector2(0, GY - 4.0), 50.0 * up, 12.5 * up, CA(GOLD, 0.85 * al), 2.6)
	E.ering(s, Vector2(0, GY - 4.0), 36.0 * up, 9.0 * up, Color(1, 1, 0.95, 0.6 * al), 1.4)
	var ph0 := fmod(t * 0.8, 1.0)
	E.ering(s, Vector2(0, GY - 4.0), 30.0 + 60.0 * ph0, (30.0 + 60.0 * ph0) * 0.25, CA(GOLD, 0.5 * (1.0 - ph0) * al), 2.0)
	# hạt vàng bay lên
	for i in range(0 if lowq else 18):
		var ph := fmod(t * 0.85 + E.rnd(i, 7), 1.0)
		var px := (E.rnd(i, 8) - 0.5) * 70.0 + sin(ph * 7.0 + float(i)) * 6.0
		E.CI(s, Vector2(px, GY - 6.0 - 130.0 * ph), 2.6 * (1.0 - ph) + 0.7, Color(1.0, 0.95, 0.6, al * (1.0 - ph)))

# ============================================================ vn2 Hợp Nhất Nguyên Tố
## aoe r210: lửa-nước-gió-đất xoáy quanh người rồi hợp nhất thành cầu sáng, nổ vòng 4 màu, băng nhẹ, hồi máu.
static func _elemfuse(s, t: float, lowq: bool) -> void:
	var R := 210.0
	var fa := E.fadeo(t, 0.8)
	var bc := Vector2(0, -10.0)
	var gc := Vector2(0, GY - 4.0)
	var cols := [Color(1.0, 0.42, 0.12), Color(0.25, 0.6, 1.0), Color(0.55, 1.0, 0.7), Color(0.72, 0.52, 0.28)]
	var sw := E.sg(t, 0.0, 0.46)
	var mg := E.sg(t, 0.42, 0.56)
	if t < 0.58:
		var rad := (130.0 * (1.0 - E.ei(sw) * 0.85)) * (1.0 - mg)
		for k in range(4):
			var pts := PackedVector2Array()
			var spin := t * 9.0 + float(k) * PI * 0.5
			for i in range(22):
				var u := float(i) / 21.0
				var a := spin - u * 2.2
				var r := rad * (1.0 - 0.35 * u) + 8.0
				pts.append(bc + Vector2(cos(a) * r, sin(a) * r * 0.5))
			var al2 := E.eo(E.sg(t, 0.0, 0.1)) * (1.0 - mg)
			E.PL(s, pts, CA(cols[k], 0.22 * al2), 12.0)
			E.PL(s, pts, CA(cols[k], 0.85 * al2), 4.0)
			E.PL(s, pts, Color(1, 1, 1, 0.8 * al2), 1.4)
			var hd := pts[0]
			orb(s, hd, 9.0, cols[k], al2)
		E.glow(s, bc, 20.0 + 30.0 * sw, 0.35 * (1.0 - mg))
	# hợp nhất: cầu trắng bảy màu nén rồi nổ
	var ex := E.sg(t, 0.52, 0.68)
	if t > 0.4 and t < 0.74:
		var ball := (14.0 + 14.0 * E.sg(t, 0.4, 0.55)) * (1.0 - E.sg(t, 0.6, 0.74))
		for k in range(4):
			var a3 := t * 12.0 + float(k) * PI * 0.5
			orb(s, bc + Vector2(cos(a3), sin(a3)) * ball * 0.5, ball * 0.6, cols[k], 0.9)
		E.CI(s, bc, ball, Color(1, 1, 1, 0.95))
	if ex <= 0.0: return
	var e := E.eo(E.sg(t, 0.55, 0.88))
	var f := 1.0 - E.sg(t, 0.55, 1.0)
	E.star(s, bc, 56.0 * (1.0 - E.sg(t, 0.55, 0.8)), 1.0 - E.sg(t, 0.55, 0.8), 12)
	for k in range(4):
		var kr := R * e * (1.0 - 0.12 * float(k))
		E.ering(s, gc, kr, kr * 0.26, CA(cols[k], 0.25 * f * fa), 11.0)
		E.ering(s, gc, kr, kr * 0.26, CA(cols[k], 0.95 * f * fa), 3.6)
		E.AR(s, bc, kr * 0.7, 0.0, TAU, 64, CA(cols[k], 0.8 * f * fa), 2.4)
	E.shock(s, gc, R * 0.5 * e, R * 0.5 * e * 0.26, f * fa)
	# đóng băng nhẹ: tinh thể băng ở rìa vòng
	var ni := 8 if lowq else 16
	for i in range(ni):
		var a4 := TAU * float(i) / float(ni) + 0.15
		var p := gc + Vector2(cos(a4) * R * 0.82 * e, sin(a4) * R * 0.82 * e * 0.26)
		var h := (10.0 + 14.0 * E.rnd(i, 3)) * E.sg(t, 0.62, 0.8) * (1.0 - E.sg(t, 0.88, 1.0))
		E.P(s, PackedVector2Array([p + Vector2(-3.0, 0), p + Vector2(0, -h), p + Vector2(3.0, 0), p + Vector2(0, 3.0)]), Color(0.7, 0.92, 1.0, 0.85 * fa))
		E.L(s, p, p + Vector2(0, -h), Color(1, 1, 1, 0.9 * fa), 1.0)
	# hồi máu: dấu cộng xanh lục bay lên quanh người
	for i in range(0 if lowq else 8):
		var ph := E.sg(t, 0.62 + 0.03 * float(i), 1.0)
		if ph <= 0.0: continue
		cross(s, Vector2((E.rnd(i, 2) - 0.5) * 60.0, 10.0 - 70.0 * ph), 5.0, Color(0.45, 1.0, 0.6, 0.85 * (1.0 - ph)))
	E.spark(s, bc, 20 if not lowq else 8, R * 0.85, E.sg(t, 0.55, 1.0), f, 3)

# ============================================================ vn3 Dòng Chảy Toàn Năng (buff)
## Các dòng năng lượng cầu vồng chảy xoắn quanh người từ chân lên đầu.
static func _flow(s, t: float, lowq: bool) -> void:
	var up := E.eo(E.sg(t, 0.0, 0.25))
	var fa := E.fo(s, t, 0.85)
	var al := up * fa
	var bc := Vector2(0, -8.0)
	E.glow(s, bc, 46.0 * up, 0.12 * al)
	# vòng cầu vồng dưới chân
	for k in range(3):
		E.ering(s, Vector2(0, GY - 4.0), (46.0 - 7.0 * float(k)) * up, (11.5 - 1.8 * float(k)) * up, HC(t * 0.3 + float(k) * 0.12, 0.8 * al), 2.4)
	var nribbon := 3 if lowq else 5
	for k in range(nribbon):
		var back_p := PackedVector2Array()
		var front_p := PackedVector2Array()
		var hs := PackedFloat32Array()
		var n := 30
		var prev := Vector2.ZERO
		for i in range(n + 1):
			var u := float(i) / float(n)
			var a := u * TAU * 1.6 + float(k) * TAU / float(nribbon) - t * 3.2
			var r := 25.0 + 6.0 * sin(u * 5.0 + t * 2.0)
			var p := Vector2(cos(a) * r, GY - 4.0 - u * 104.0 * up + sin(a) * 6.0)
			var f2 := sin(PI * u)
			var col_h := u * 0.55 + float(k) * 0.2 + t * 0.25
			var front := sin(a) > 0.0
			if i > 0:
				var seg_al := al * pow(f2, 0.6) * (1.0 if front else 0.45)
				E.L(s, prev, p, HC(col_h, 0.22 * seg_al), 9.0)
				E.L(s, prev, p, HC(col_h, 0.9 * seg_al, 0.55), 3.4)
				if front:
					E.L(s, prev, p, Color(1, 1, 1, 0.7 * seg_al), 1.2)
			prev = p
	# hạt năng lượng chảy lên
	for i in range(0 if lowq else 20):
		var ph := fmod(t * 0.8 + E.rnd(i, 7), 1.0)
		var a2 := E.rnd(i, 3) * TAU + t * 2.0
		var pp := Vector2(cos(a2) * (22.0 + 10.0 * E.rnd(i, 5)), GY - 4.0 - 110.0 * ph)
		E.CI(s, pp, 2.4 * (1.0 - ph * 0.5), HC(E.rnd(i, 2) + t * 0.3, al * (1.0 - ph)))

# ============================================================ vn4 Thế Cân Bằng (buff)
## Cán cân bạc trên đầu nghiêng nhẹ, thái cực đồ mờ sau lưng, hai viên đen-trắng xoay quanh; tông trắng-bạc/đen.
static func _balance(s, t: float, lowq: bool) -> void:
	var up := E.eo(E.sg(t, 0.0, 0.25))
	var fa := E.fo(s, t, 0.85)
	var al := up * fa
	# thái cực đồ mờ sau lưng
	taiji(s, Vector2(0, -6.0), 36.0 * up, t * 1.6, 0.4 * al)
	# vòng đất đen-trắng
	E.ering(s, Vector2(0, GY - 4.0), 46.0 * up, 11.5 * up, Color(0.95, 0.95, 1.0, 0.7 * al), 3.0)
	E.ering(s, Vector2(0, GY - 4.0), 46.0 * up, 11.5 * up, Color(0.05, 0.05, 0.1, 0.8 * al), 1.4)
	E.ering(s, Vector2(0, GY - 4.0), 34.0 * up, 8.5 * up, Color(0.75, 0.78, 0.88, 0.55 * al), 1.6)
	# hai viên cầu đen/trắng quay đối xứng
	for k in range(2):
		var a := t * 2.4 + PI * float(k)
		var p := Vector2(cos(a) * 36.0, -6.0 + sin(a) * 14.0)
		var front := sin(a) > 0.0
		var white := k == 0
		var ca := al * (1.0 if front else 0.55)
		E.CI(s, p, 8.0, Color(0.7, 0.72, 0.85, 0.22 * ca))
		E.CI(s, p, 5.5, (CA(PAPER, 0.95 * ca) if white else CA(INK, 0.95 * ca)))
		E.AR(s, p, 5.5, 0.0, TAU, 14, Color(0.85, 0.85, 0.95, 0.9 * ca), 1.2)
	# cán cân trên đầu
	var ctr := Vector2(0, -84.0 - 3.0 * sin(t * 2.0))
	var tilt := 0.2 * sin(t * 2.2)
	var arm := 34.0 * up
	var pl := ctr + Vector2(-cos(tilt), -sin(tilt)) * arm
	var pr := ctr + Vector2(cos(tilt), sin(tilt)) * arm
	E.L(s, ctr, ctr + Vector2(0, 24.0), Color(0.7, 0.72, 0.8, 0.9 * al), 3.0)
	E.L(s, pl, pr, Color(0.88, 0.9, 0.97, al), 3.2)
	E.L(s, pl, pr, Color(1, 1, 1, 0.8 * al), 1.2)
	E.CI(s, ctr, 4.0, CA(GOLD, al))
	for k in range(2):
		var anc := pl if k == 0 else pr
		var pc := anc + Vector2(0, 22.0)
		E.L(s, anc, pc + Vector2(-11.0, 0), Color(0.75, 0.78, 0.88, 0.8 * al), 1.0)
		E.L(s, anc, pc + Vector2(11.0, 0), Color(0.75, 0.78, 0.88, 0.8 * al), 1.0)
		var half := PackedVector2Array()
		for i in range(13):
			var aa := PI * float(i) / 12.0
			half.append(pc + Vector2(cos(aa) * 11.0, sin(aa) * 6.0))
		E.P(s, half, (Color(0.95, 0.95, 1.0, 0.9 * al) if k == 0 else Color(0.12, 0.1, 0.2, 0.92 * al)))
		E.AR(s, pc, 11.0, 0.0, PI, 12, Color(0.9, 0.92, 1.0, al), 1.6)
		E.CI(s, pc + Vector2(0, -4.0), 3.5, (CA(INK, 0.9 * al) if k == 0 else CA(PAPER, 0.95 * al)))
	E.glow(s, ctr, 22.0, 0.1 * al)
	# bụi sáng đen-trắng lơ lửng
	for i in range(0 if lowq else 12):
		var ph := fmod(t * 0.7 + E.rnd(i, 7), 1.0)
		var pp := Vector2((E.rnd(i, 8) - 0.5) * 70.0, GY - 8.0 - 100.0 * ph)
		E.CI(s, pp, 2.2 * (1.0 - ph) + 0.6, (CA(PAPER, 0.9 * al * (1.0 - ph)) if i % 2 == 0 else CA(Color(0.15, 0.12, 0.25), 0.9 * al * (1.0 - ph))))

# ============================================================ vn5 Tinh Lực Dồi Dào
## Hồi máu + MP 30%: hạt xanh lục xoắn lên cùng hạt xanh dương, hai vòng đan nhau dưới chân, dấu cộng.
static func _vigor(s, t: float, lowq: bool) -> void:
	var up := E.eo(E.sg(t, 0.0, 0.3))
	var fa := E.fadeo(t, 0.7)
	var al := up * fa
	var GR := Color(0.3, 1.0, 0.5)
	var BL := Color(0.3, 0.62, 1.0)
	var bc := Vector2(0, -6.0)
	# hai vòng đan nhau
	for k in range(2):
		var sd := -1.0 if k == 0 else 1.0
		var col := GR if k == 0 else BL
		var c2 := Vector2(sd * 11.0 * up, GY - 4.0)
		E.ering(s, c2, 40.0 * up, 10.0 * up, CA(col, 0.25 * al), 8.0)
		E.ering(s, c2, 40.0 * up, 10.0 * up, CA(col, 0.9 * al), 2.6)
	E.glow(s, bc, 44.0 * up, 0.0)
	E.CI(s, bc, 36.0 * up, CA(GR, 0.05 * al))
	E.CI(s, bc + Vector2(0, -4), 26.0 * up, CA(BL, 0.06 * al))
	# hạt xoắn lên: xanh lục (HP) và xanh dương (MP)
	var n := 8 if lowq else 16
	for k in range(2):
		var col2 := GR if k == 0 else BL
		for i in range(n):
			var ph := fmod(E.sg(t, 0.0, 1.0) * 1.1 + float(i) / float(n), 1.0)
			var a := ph * TAU * 2.0 + float(k) * PI + float(i)
			var p := Vector2(cos(a) * 26.0 * (1.0 - 0.3 * ph), GY - 6.0 - 100.0 * ph)
			var fl := sin(PI * ph) * al
			E.CI(s, p, 3.2 * (1.0 - ph * 0.5), CA(col2, 0.9 * fl))
			E.CI(s, p, 6.5, CA(col2, 0.16 * fl))
			E.CI(s, p, 1.4, Color(1, 1, 1, 0.9 * fl))
	# dấu cộng xanh lục + giọt MP xanh dương
	for i in range(4 if lowq else 6):
		var ph2 := E.sg(t, 0.1 + 0.07 * float(i), 0.85)
		if ph2 <= 0.0: continue
		var x := (E.rnd(i, 2) - 0.5) * 70.0
		var y := 6.0 - 70.0 * E.eo(ph2)
		if i % 2 == 0:
			cross(s, Vector2(x, y), 6.0, CA(GR, 0.9 * (1.0 - ph2)))
		else:
			E.P(s, PackedVector2Array([Vector2(x, y - 7.0), Vector2(x + 4.5, y + 1.0), Vector2(x, y + 5.0), Vector2(x - 4.5, y + 1.0)]), CA(BL, 0.9 * (1.0 - ph2)))
			E.L(s, Vector2(x - 1.0, y - 3.0), Vector2(x - 1.5, y + 1.0), Color(1, 1, 1, 0.8 * (1.0 - ph2)), 1.2)
	E.spark(s, bc, 8 if lowq else 14, 60.0, E.sg(t, 0.0, 0.9), fa * 0.8, 2)

# ============================================================ vn7 Trảm Hợp Nhất
## 4 nhát chém liên tiếp (tầm 200): chém xuống, chém ngược, chém ngang, rồi nhát cuối nổ lực mạnh.
static func _tripleslash(s, t: float, lowq: bool) -> void:
	var fa := E.fadeo(t, 0.78)
	var c := Vector2(10.0, -4.0)
	var plan := [[-1.2, 0.5, 0.05], [0.8, -0.95, 0.2], [-0.35, 0.35, 0.34]]
	for k in range(3):
		var a0: float = plan[k][0]
		var a1: float = plan[k][1]
		var tk: float = plan[k][2]
		var q := E.sg(t, tk, tk + 0.14)
		if q <= 0.0: continue
		var life := E.fadeo(t, tk + 0.2)
		var r := 150.0 + 30.0 * float(k)
		E.swoosh(s, c, r, a0, a1, E.eo(q), 0.85, 44.0, life, 0.9)
		E.swing(s, c, r, a0, a1, E.eo(q), life, 0.9)
		if q > 0.7:
			E.flare(s, c + Vector2(cos(a1), sin(a1) * 0.9) * r, 9.0 * (1.0 - E.sg(t, tk + 0.12, tk + 0.3)), life)
	# nhát cuối: bổ dọc xuống, nổ lực
	var tq := 0.5
	var q4 := E.sg(t, tq, tq + 0.1)
	if q4 > 0.0:
		var T := Vector2(170.0, -10.0)
		var life4 := E.fadeo(t, 0.72)
		var e4 := E.eo(q4)
		E.cut(s, Vector2(T.x - 34.0, -150.0), Vector2(T.x + 14.0, -150.0 + 190.0 * e4), 11.0, life4)
		E.cut(s, Vector2(T.x - 30.0, -140.0), Vector2(T.x + 12.0, -140.0 + 180.0 * e4), 5.0, life4)
		if q4 >= 1.0:
			var h := E.sg(t, tq + 0.1, 1.0)
			E.star(s, T, 60.0 * (1.0 - h), 1.0 - h, 12)
			var gc := Vector2(T.x, GY - 4.0)
			E.shock(s, gc, 20.0 + 140.0 * E.eo(h), (20.0 + 140.0 * E.eo(h)) * 0.26, 1.0 - h)
			E.AR(s, T, 20.0 + 100.0 * E.eo(h), 0.0, TAU, 48, E.A(s, 0.8 * (1.0 - h)), 4.0)
			E.AR(s, T, 20.0 + 100.0 * E.eo(h), 0.0, TAU, 48, E.K(s, 1.0 - h), 1.6)
			E.crack(s, Vector2(T.x, GY - 2.0), 120.0 * E.eo(h), 1.0 - h, 4)
			E.dust(s, gc, 100.0, h, (1.0 - h) * 0.9, 8 if lowq else 12, 3)
			E.spark(s, T, 12 if lowq else 24, 110.0, h, 1.0 - h, 2)
			for i in range(0 if lowq else 6):
				var u := E.sg(h, 0.0, 0.8)
				var rx := T.x + (E.rnd(i, 2) - 0.5) * 120.0 * u
				var ry := GY - 6.0 - (40.0 + 60.0 * E.rnd(i, 3)) * 4.0 * u * (1.0 - u)
				rock(s, Vector2(rx, ry), 4.0 + 3.0 * E.rnd(i, 4), u * 6.0, (1.0 - u) * fa)
