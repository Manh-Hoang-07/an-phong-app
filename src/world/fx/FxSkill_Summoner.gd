extends RefCounted
## Hiệu ứng kỹ năng VẼ LẠI RIÊNG — triệu hồi sư (linh hồn, linh thú). Đạn th1/th8/th10 xem FxProj.gd.
## Quy ước như FxSkill_Swordsman/Archer/Assassin: place "bodyf", gốc = thân nhân vật, +x = hướng nhìn, y âm = lên, mặt đất y~+32.
const E := preload("res://src/world/fx/FxSkill_Swordsman.gd")

const IDS := {
	"th11": "tl_gather", "th2": "tl_guardian", "th3": "tl_burst", "th4": "tl_command",
	"th5": "tl_summon", "th6": "tl_soulcall", "th7": "tl_ward", "th9": "tl_resonance",
	"ulLinh1": "tl_soulmeteor",
}
const CFG := {
	"tl_gather": {"place": "bodyf", "dur": 1.9, "nopop": true, "nobig": true, "rumble": 5.0},
	"tl_guardian": {"place": "bodyf", "dur": 1.4, "nopop": true, "nobig": true},
	"tl_burst": {"place": "bodyf", "dur": 1.1, "nopop": true, "nobig": true, "rumble": 4.0},
	"tl_command": {"place": "bodyf", "dur": 1.4, "nopop": true, "nobig": true},
	"tl_summon": {"place": "bodyf", "dur": 1.5, "nopop": true, "nobig": true},
	"tl_soulcall": {"place": "bodyf", "dur": 1.5, "nopop": true, "nobig": true},
	"tl_ward": {"place": "bodyf", "dur": 1.4, "nopop": true, "nobig": true},
	"tl_resonance": {"place": "bodyf", "dur": 1.4, "nopop": true, "nobig": true},
	"tl_soulmeteor": {"place": "bodyf", "dur": 1.7, "nopop": true, "nobig": true, "rumble": 6.0},
}
## Sig hỗ trợ hào quang buff kéo dài (s.steady): liệt kê tên sig ở đây và xử lý trong draw_aura.
const AURA_IDS := ["tl_guardian", "tl_command", "tl_ward", "tl_resonance"]

static func draw(s, sg: String, t: float, lowq: bool) -> void:
	match sg:
		"tl_gather": _gather(s, t, lowq)
		"tl_guardian": _guardian(s, t, lowq)
		"tl_burst": _burst(s, t, lowq)
		"tl_command": _command(s, t, lowq)
		"tl_summon": _summon(s, t, lowq)
		"tl_soulcall": _soulcall(s, t, lowq)
		"tl_ward": _ward(s, t, lowq)
		"tl_resonance": _resonance(s, t, lowq)
		"tl_soulmeteor": _soulmeteor(s, t, lowq)
		_: pass

static func draw_aura(s, sg: String, t: float, lowq: bool) -> void:
	var tt := 1.0 + t
	match sg:
		"tl_guardian": _guardian(s, tt, lowq)
		"tl_command": _command(s, tt, lowq)
		"tl_ward": _ward(s, tt, lowq)
		"tl_resonance": _resonance(s, tt, lowq)
		_: pass

# ============================================================ tiện ích
const GY := 32.0
const DK := Color(0.04, 0.03, 0.08)
const HEAL := Color(0.55, 1.0, 0.7)

static func ep(c: Vector2, a: float, rx: float, ry: float) -> Vector2:
	return c + Vector2(cos(a) * rx, sin(a) * ry)

## Linh hồn nhỏ (hình giọt, đuôi lượn, mắt) bay theo hướng ang.
static func wisp(s, p: Vector2, r: float, ang: float, al: float, ph: float) -> void:
	if al <= 0.02 or r < 2.0: return
	var d := Vector2(cos(ang), sin(ang))
	var nr := d.orthogonal()
	var pts := PackedVector2Array()
	for i in range(9):
		var u := float(i) / 8.0
		pts.append(p - d * r * 3.4 * u + nr * sin(u * 5.5 + ph) * r * 0.55 * u)
	E.PL(s, pts, E.A(s, al * 0.2), r * 1.7)
	E.PL(s, pts, E.A(s, al * 0.5), r * 1.0)
	E.PL(s, pts, E.K(s, al * 0.45), r * 0.4)
	E.glow(s, p, r * 1.9, al * 0.55)
	E.CI(s, p, r, E.A(s, al * 0.95))
	E.CI(s, p + d * r * 0.15, r * 0.6, E.K(s, al))
	E.CI(s, p + nr * r * 0.32 + d * r * 0.3, r * 0.16, Color(DK, al * 0.9))
	E.CI(s, p - nr * r * 0.32 + d * r * 0.3, r * 0.16, Color(DK, al * 0.9))

## Trận rune dưới đất: vòng đôi, sao nhiều cánh quay, chữ rune giữa hai vòng.
static func rune(s, c: Vector2, rx: float, ry: float, rot: float, al: float, n: int = 6) -> void:
	if al <= 0.02 or rx < 4.0: return
	E.ering(s, c, rx, ry, E.A(s, al * 0.25), 9.0)
	E.ering(s, c, rx, ry, E.A(s, al * 0.9), 2.4)
	E.ering(s, c, rx * 0.97, ry * 0.97, E.K(s, al * 0.8), 1.0)
	E.ering(s, c, rx * 0.78, ry * 0.78, E.A(s, al * 0.8), 1.6)
	for i in range(n):
		var a := rot + TAU * float(i) / float(n)
		var b := rot + TAU * float((i + 2) % n) / float(n)
		E.L(s, ep(c, a, rx * 0.78, ry * 0.78), ep(c, b, rx * 0.78, ry * 0.78), E.A(s, al * 0.6), 1.3)
	for i in range(n * 2):
		var a2 := -rot * 0.6 + TAU * float(i) / float(n * 2)
		var p0 := ep(c, a2, rx * 0.8, ry * 0.8)
		var p1 := ep(c, a2, rx * 0.95, ry * 0.95)
		E.L(s, p0, p1, E.K(s, al * 0.7), 1.4)
		if i % 2 == 0:
			var pm := ep(c, a2 + 0.12, rx * 0.88, ry * 0.88)
			E.CI(s, pm, 1.6, E.K(s, al))

## Tia sáng đứng (cột sáng giáng xuống) — nhiều lớp.
static func pillar(s, x: float, ytop: float, ybot: float, w: float, al: float) -> void:
	if al <= 0.02 or w < 1.0: return
	for i in range(5):
		var k := 1.0 - float(i) / 5.0
		E.PG(s, PackedVector2Array([Vector2(x - w * k * 0.5, ytop), Vector2(x + w * k * 0.5, ytop), Vector2(x + w * k, ybot), Vector2(x - w * k, ybot)]),
			PackedColorArray([E.A(s, 0.0), E.A(s, 0.0), E.A(s, al * (0.1 + 0.12 * (1.0 - k))), E.A(s, al * (0.1 + 0.12 * (1.0 - k)))]))
	E.L(s, Vector2(x, ytop), Vector2(x, ybot), E.K(s, al * 0.8), maxf(1.2, w * 0.12))

## Bóng linh thú (sói linh): thân, đầu, tai, bốn chân, đuôi, mắt sáng. base = giữa chân trên mặt đất.
static func beast(s, base: Vector2, sc: float, al: float, t: float) -> void:
	if al <= 0.02: return
	var f := func(v: Vector2) -> Vector2: return base + v * sc
	var body := PackedVector2Array([f.call(Vector2(-24, -20)), f.call(Vector2(-8, -29)), f.call(Vector2(14, -27)), f.call(Vector2(26, -19)), f.call(Vector2(22, -6)), f.call(Vector2(-18, -4))])
	var head := PackedVector2Array([f.call(Vector2(20, -29)), f.call(Vector2(34, -33)), f.call(Vector2(48, -24)), f.call(Vector2(44, -16)), f.call(Vector2(28, -15))])
	# quầng sáng + đuôi
	E.glow(s, base + Vector2(0, -18) * sc, 40.0 * sc, 0.1 * al)
	var tail := PackedVector2Array()
	for i in range(8):
		var u := float(i) / 7.0
		tail.append(f.call(Vector2(-24.0 - 20.0 * u, -16.0 - 20.0 * u + sin(u * 4.0 + t * 8.0) * 4.0)))
	E.PL(s, tail, E.A(s, 0.5 * al), 7.0 * sc)
	E.PL(s, tail, E.K(s, 0.7 * al), 2.2 * sc)
	for lx in [-16.0, -6.0, 12.0, 20.0]:
		E.L(s, f.call(Vector2(lx, -8)), f.call(Vector2(lx + 1.0, 0)), E.A(s, 0.9 * al), 5.0 * sc)
		E.L(s, f.call(Vector2(lx + 1.0, 0)), f.call(Vector2(lx + 4.0, 0)), E.K(s, 0.9 * al), 2.4 * sc)
	E.P(s, body, E.A(s, 0.92 * al))
	E.P(s, PackedVector2Array([f.call(Vector2(-18, -22)), f.call(Vector2(-2, -27)), f.call(Vector2(14, -24)), f.call(Vector2(8, -14)), f.call(Vector2(-14, -12))]), E.K(s, 0.4 * al))
	E.P(s, head, E.A(s, 0.95 * al))
	E.P(s, PackedVector2Array([f.call(Vector2(26, -32)), f.call(Vector2(27, -45)), f.call(Vector2(35, -34))]), E.A(s, al))
	E.P(s, PackedVector2Array([f.call(Vector2(34, -34)), f.call(Vector2(39, -45)), f.call(Vector2(42, -29))]), E.A(s, al))
	E.PL(s, body + PackedVector2Array([body[0]]), E.K(s, 0.8 * al), 1.2)
	E.PL(s, head + PackedVector2Array([head[0]]), E.K(s, 0.8 * al), 1.2)
	E.CI(s, f.call(Vector2(36, -25)), 2.6 * sc, E.K(s, al))
	E.glow(s, f.call(Vector2(36, -25)), 7.0 * sc, 0.6 * al)
	# vằn linh khí trên lưng
	for i in range(4):
		var x := -14.0 + 9.0 * float(i)
		E.L(s, f.call(Vector2(x, -27)), f.call(Vector2(x + 3.0, -15)), E.K(s, 0.5 * al), 1.2)

# ============================================================ ULT: VẠN LINH QUY TỤ (th11)
## Hồn từ khắp nơi quy tụ về người; linh quang giáng hai đợt tại ~170px và ~280px phía trước (trễ 0.6s + 0.42s),
## hồn xoáy quy tụ vào tâm rồi nổ; sinh lực hồi về cho chủ.
static func _gather(s, t: float, lowq: bool) -> void:
	var fa := E.fadeo(t, 0.88)
	# --- 1) quy tụ hồn về người (0..0.26)
	var g := E.sg(t, 0.0, 0.26)
	var n := 8 if lowq else 14
	if g < 1.0 or t < 0.32:
		for i in range(n):
			var a := TAU * float(i) / float(n) + 0.5 * E.rnd(i, 2)
			var r0 := 130.0 + 60.0 * E.rnd(i, 3)
			var q := E.eo(g)
			var rr := r0 * (1.0 - q)
			var p := Vector2(cos(a + q * 1.8) * rr, -16.0 + sin(a + q * 1.8) * rr * 0.55)
			var vis := (1.0 - E.sg(t, 0.24, 0.34)) * E.sg(t, 0.0, 0.05)
			wisp(s, p, 6.0, a + q * 1.8 + PI * 0.5 + 0.6, vis, float(i))
	var core := E.sg(t, 0.12, 0.3) * (1.0 - E.sg(t, 0.3, 0.45))
	if core > 0.0:
		E.glow(s, Vector2(0, -16), 56.0 * core, core)
		E.flare(s, Vector2(0, -16), 16.0 * core, core)
	rune(s, Vector2(0, GY - 4.0), 56.0, 14.0, t * 2.0, E.sg(t, 0.0, 0.12) * E.fadeo(t, 0.4), 6)
	# hồi sinh lực cho chủ: hạt xanh bay lên quanh người sau mỗi đợt
	for k in range(2):
		var tk := 0.33 + 0.21 * float(k)
		var q2 := E.sg(t, tk + 0.04, tk + 0.4)
		if q2 > 0.0 and q2 < 1.0:
			for i in range(0 if lowq else 7):
				var x := (E.rnd(i, 20 + k) - 0.5) * 40.0
				var y := 26.0 - 70.0 * E.eo(q2) * (0.6 + 0.5 * E.rnd(i, 21))
				E.CI(s, Vector2(x, y), 2.4, Color(HEAL, 0.9 * (1.0 - q2)))
				E.L(s, Vector2(x - 3, y), Vector2(x + 3, y), Color(HEAL, 0.9 * (1.0 - q2)), 1.2)
				E.L(s, Vector2(x, y - 3), Vector2(x, y + 3), Color(HEAL, 0.9 * (1.0 - q2)), 1.2)
	# --- 2) hai điểm rơi
	var spots := [[170.0, 0.34], [280.0, 0.56]]
	for k in range(2):
		var sp: Array = spots[k]
		var x := float(sp[0])
		var tk := float(sp[1])
		var gc := Vector2(x, GY - 4.0)
		# hồn xoáy quy tụ vào tâm điểm rơi
		var cq := E.sg(t, tk - 0.24, tk)
		if cq > 0.0 and t < tk + 0.06:
			var vis2 := E.sg(t, tk - 0.24, tk - 0.18) * (1.0 - E.sg(t, tk - 0.02, tk + 0.06))
			rune(s, gc, 64.0 * (0.5 + 0.5 * E.eo(cq)), 15.0 * (0.5 + 0.5 * E.eo(cq)), t * 3.0 * float(1 - 2 * k), vis2, 6)
			for i in range(5 if lowq else 9):
				var a2 := TAU * float(i) / 9.0 + cq * 5.0
				var rr2 := 70.0 * (1.0 - E.eo(cq)) + 4.0
				var pp := Vector2(x + cos(a2) * rr2, GY - 14.0 - 44.0 * cq * E.rnd(i, 4) + sin(a2) * rr2 * 0.25)
				wisp(s, pp, 5.0, a2 + PI * 0.5 + 0.4, vis2, float(i))
			E.glow(s, Vector2(x, GY - 14.0), 30.0 * cq, vis2 * 0.8)
		# linh quang giáng xuống
		var dq := E.sg(t, tk, tk + 0.07)
		var life := E.fadeo(t, tk + 0.1) if t > tk else 0.0
		if dq > 0.0:
			var ytop := -420.0
			var yb := lerpf(ytop, GY - 6.0, E.ei(dq))
			pillar(s, x, ytop, yb, 40.0 * (1.0 - 0.3 * E.sg(t, tk + 0.07, tk + 0.3)), life)
			if dq >= 1.0:
				var h := E.sg(t, tk + 0.07, tk + 0.45)
				E.star(s, Vector2(x, GY - 20.0), 54.0 * (1.0 - h * 0.5), 1.0 - h, 10)
				E.shock(s, gc, 20.0 + 190.0 * E.eo(h), 5.0 + 46.0 * E.eo(h), 1.0 - h)
				E.shock(s, gc, 10.0 + 120.0 * E.eo(h), 3.0 + 28.0 * E.eo(h), (1.0 - h) * 0.7)
				E.dust(s, gc, 90.0, h, 1.0 - h, 6 if lowq else 12, k)
				E.spark(s, Vector2(x, GY - 22.0), 10 if lowq else 18, 120.0, h, 1.0 - h, 3 + k)
				for i in range(0 if lowq else 6):
					var a3 := TAU * float(i) / 6.0 + 0.4
					var rp := 40.0 + 110.0 * E.eo(h)
					wisp(s, Vector2(x + cos(a3) * rp, GY - 20.0 - 40.0 * h + sin(a3) * rp * 0.3), 5.0, a3, (1.0 - h) * 0.9, float(i))

# ============================================================ ULT: VẠN LINH BÙNG NỔ (ulLinh1)
## Linh khí nổ tung quanh người, rồi hai đợt thiên thạch linh hồn (đầu lâu, đuôi lửa xanh) rơi chéo xuống chiến trường.
static func comet(s, head: Vector2, dir: Vector2, ln: float, r: float, al: float) -> void:
	if al <= 0.02: return
	var nr := dir.orthogonal()
	var tail := head - dir * ln
	E.PG(s, PackedVector2Array([tail, head + nr * r * 0.9, head - nr * r * 0.9]), PackedColorArray([E.A(s, 0.0), E.A(s, al * 0.5), E.A(s, al * 0.5)]))
	E.PG(s, PackedVector2Array([tail + dir * ln * 0.2, head + nr * r * 0.45, head - nr * r * 0.45]), PackedColorArray([E.K(s, 0.0), E.K(s, al * 0.7), E.K(s, al * 0.7)]))
	for j in range(3):
		var o := (float(j) - 1.0) * r * 0.55
		E.PL(s, PackedVector2Array([head + nr * o - dir * ln * 0.2, head + nr * o * 1.4 - dir * ln * 0.6, head + nr * o * 0.4 - dir * ln * 0.95]), E.A(s, al * 0.35), 2.0)
	E.glow(s, head, r * 2.2, al * 0.7)
	E.CI(s, head, r, E.A(s, al))
	E.CI(s, head + dir * r * 0.1, r * 0.72, E.K(s, al * 0.95))
	# mặt đầu lâu trên thiên thạch
	E.CI(s, head + nr * r * 0.28 + dir * r * 0.15, r * 0.17, Color(DK, al))
	E.CI(s, head - nr * r * 0.28 + dir * r * 0.15, r * 0.17, Color(DK, al))
	E.L(s, head + nr * r * 0.3 - dir * r * 0.3, head - nr * r * 0.3 - dir * r * 0.3, Color(DK, al * 0.8), 1.2)

static func _soulmeteor(s, t: float, lowq: bool) -> void:
	var fa := E.fadeo(t, 0.9)
	var gc := Vector2(0, GY - 4.0)
	# --- bùng nổ linh khí quanh người (0..0.3)
	var b := E.sg(t, 0.0, 0.3)
	if b > 0.0:
		var fb := 1.0 - E.sg(t, 0.28, 0.5)
		E.glow(s, Vector2(0, -14), (30.0 + 50.0 * E.eo(b)), 0.9 * fb)
		E.shock(s, gc, 20.0 + 150.0 * E.eo(b), 5.0 + 36.0 * E.eo(b), fb)
		rune(s, gc, 50.0 + 40.0 * E.eo(b), 12.0 + 10.0 * E.eo(b), t * 4.0, fb, 8)
		for i in range(6 if lowq else 12):
			var a := TAU * float(i) / 12.0
			var rr := 20.0 + 110.0 * E.eo(b) * (0.6 + 0.4 * E.rnd(i, 1))
			wisp(s, Vector2(cos(a) * rr, -14.0 + sin(a) * rr * 0.6), 6.0, a, fb * 0.95, float(i))
		E.star(s, Vector2(0, -14), 40.0 * (1.0 - E.sg(t, 0.2, 0.4)), fb, 12)
	# --- hai đợt thiên thạch: đợt 1 ~ 90..210, đợt 2 ~ 180..300 (r=220)
	for w in range(2):
		var t0 := 0.26 + 0.28 * float(w)
		var m := 4 if lowq else (5 if w == 0 else 7)
		for i in range(m):
			var tl := t0 + 0.045 * float(i)
			var land := Vector2(lerpf(90.0 + 90.0 * float(w), 220.0 + 90.0 * float(w), E.rnd(i, 3 + w)) + (float(i) - float(m) * 0.5) * 8.0, GY - 2.0 + (E.rnd(i, 7 + w) - 0.5) * 14.0)
			var fall := E.sg(t, tl - 0.16, tl)
			var dir := Vector2(0.4, 1.0).normalized()
			if fall > 0.0 and fall < 1.0:
				var hp := land - dir * 330.0 * (1.0 - E.ei(fall))
				comet(s, hp, dir, 120.0, 11.0 + 3.0 * float(w), 1.0)
			var h := E.sg(t, tl, tl + 0.3)
			if t >= tl and h < 1.0:
				var rr3 := 18.0 + 46.0 * E.eo(h)
				E.shock(s, land, rr3 * 1.6, rr3 * 0.4, (1.0 - h) * 0.9)
				E.star(s, land + Vector2(0, -10), 24.0 * (1.0 - h * 0.6), 1.0 - h, 8)
				E.spark(s, land + Vector2(0, -8), 5 if lowq else 8, 60.0, h, 1.0 - h, i + 3 * w)
				for q in range(0 if lowq else 3):
					var a4 := -PI * (0.2 + 0.6 * E.rnd(q + i * 3, 9))
					var dd := Vector2(cos(a4), sin(a4)) * 48.0 * E.eo(h)
					wisp(s, land + dd + Vector2(0, -6), 4.0, a4, (1.0 - h) * 0.9, float(q))
		# vòng nổ lớn khi đợt rơi xong
		var big := E.sg(t, t0 + 0.2, t0 + 0.5)
		if big > 0.0 and big < 1.0:
			var cx := 150.0 + 90.0 * float(w)
			E.shock(s, Vector2(cx, GY - 4.0), 40.0 + 150.0 * E.eo(big), 10.0 + 36.0 * E.eo(big), 1.0 - big)

# ============================================================ th3 NỔ LINH LỰC (aoe r170 quanh người)
static func _burst(s, t: float, lowq: bool) -> void:
	var R := 170.0
	var gc := Vector2(0, GY - 6.0)
	# nén linh lực (0..0.3): hồn bị hút vào ngực, lõi sáng co lại
	var c := E.sg(t, 0.0, 0.3)
	if t < 0.34:
		var vis := 1.0 - E.sg(t, 0.28, 0.36)
		for i in range(6 if lowq else 12):
			var a := TAU * float(i) / 12.0 + c * 3.0
			var rr := 90.0 * (1.0 - E.ei(c)) + 6.0
			wisp(s, Vector2(cos(a) * rr, -14.0 + sin(a) * rr * 0.5), 5.0, a + PI * 0.5 + 0.5, vis * E.sg(t, 0.0, 0.05), float(i))
		E.glow(s, Vector2(0, -14), 14.0 + 20.0 * c, 0.5 + 0.5 * c)
		E.ering(s, Vector2(0, -14), 40.0 * (1.0 - c) + 8.0, 40.0 * (1.0 - c) + 8.0, E.K(s, 0.7 * vis), 1.4)
	# vụ nổ (0.3..)
	var h := E.sg(t, 0.3, 1.0)
	if h > 0.0:
		var f := 1.0 - h
		var q := E.eo(h)
		# cầu linh lực nở: các lớp tròn mờ
		for i in range(6):
			E.CI(s, Vector2(0, -14), R * q * (1.0 - 0.14 * float(i)) * 0.75, E.A(s, 0.07 * f))
		E.ering(s, Vector2(0, -14), R * q * 0.8, R * q * 0.8, E.A(s, 0.8 * f), 3.0)
		E.ering(s, Vector2(0, -14), R * q * 0.8, R * q * 0.8, E.K(s, f), 1.4)
		E.shock(s, gc, R * q, R * q * 0.24, f)
		E.shock(s, gc, R * q * 0.6, R * q * 0.15, f * 0.7)
		E.star(s, Vector2(0, -14), 50.0 * (1.0 - h * 0.7), f, 12)
		# tia linh lực toả ra mọi hướng + hồn bay ra
		for i in range(10 if lowq else 18):
			var a2 := TAU * float(i) / 18.0
			var d := Vector2(cos(a2), sin(a2) * 0.6)
			E.cut(s, Vector2(0, -14) + d * 20.0, Vector2(0, -14) + d * (30.0 + (R - 30.0) * q), 3.0 * f + 0.6, f * 0.8)
		for i in range(5 if lowq else 9):
			var a3 := TAU * float(i) / 9.0 + 0.2
			var rr := R * q * (0.5 + 0.45 * E.rnd(i, 4))
			wisp(s, Vector2(cos(a3) * rr, -14.0 + sin(a3) * rr * 0.6), 6.0, a3, f, float(i))
		E.dust(s, gc, R * 0.7, h, f, 6 if lowq else 12, 2)
		E.spark(s, Vector2(0, -14), 10 if lowq else 20, R * 0.9, h, f, 5)

# ============================================================ th5 TRIỆU HỒI LINH THÚ
## Pháp trận triệu hồi mở ra dưới đất phía trước, cột sáng, bóng linh thú trồi lên từ trận (bật/tắt 1 linh thú).
static func _summon(s, t: float, lowq: bool) -> void:
	var x := 70.0
	var gc := Vector2(x, GY - 4.0)
	var fa := E.fadeo(t, 0.82)
	var open := E.eo(E.sg(t, 0.0, 0.25))
	rune(s, gc, 62.0 * open, 15.0 * open, t * 2.4, open * fa, 6)
	# dấu chân thú trong trận
	for k in range(3):
		var a := TAU * float(k) / 3.0 + t * 1.2
		var pc := ep(gc, a, 38.0 * open, 9.0 * open)
		E.CI(s, pc, 3.0, E.K(s, 0.8 * open * fa))
		for j in range(3):
			E.CI(s, pc + Vector2((float(j) - 1.0) * 4.0, -4.5), 1.4, E.K(s, 0.8 * open * fa))
	# cột sáng triệu hồi
	var pl := E.sg(t, 0.15, 0.4) * E.fadeo(t, 0.5) * 0.55
	if pl > 0.0:
		pillar(s, x, -150.0, GY - 4.0, 66.0, pl)
	# linh thú trồi lên: bóng hiện dần từ mặt đất
	var up := E.eo(E.sg(t, 0.32, 0.62))
	if up > 0.0 and not s.nocreature:
		var al := E.sg(t, 0.32, 0.5) * fa
		beast(s, Vector2(x, GY - 2.0 + 16.0 * (1.0 - up)), 1.5, al, t)
	# hồn tụ vào trận và bay vòng quanh con thú
	for i in range(5 if lowq else 9):
		var u := E.sg(t, 0.05 + 0.03 * float(i), 0.5 + 0.03 * float(i))
		var a2 := TAU * float(i) / 9.0 + t * 3.0
		var rr := 74.0 * (1.0 - u) + 22.0
		var p := Vector2(x + cos(a2) * rr, GY - 12.0 - 50.0 * u * (0.5 + E.rnd(i, 2)) + sin(a2) * rr * 0.3)
		wisp(s, p, 4.5, a2 + PI * 0.5, E.sg(t, 0.0, 0.06) * fa * (1.0 - 0.4 * u), float(i))
	var fl := E.sg(t, 0.45, 0.7) * (1.0 - E.sg(t, 0.7, 1.0))
	if fl > 0.0:
		E.star(s, Vector2(x, GY - 60.0), 22.0 * fl, fl * 0.7, 8)
		E.shock(s, gc, 20.0 + 70.0 * E.eo(E.sg(t, 0.45, 0.9)), 5.0 + 17.0 * E.eo(E.sg(t, 0.45, 0.9)), fl)
	E.spark(s, Vector2(x, GY - 24.0), 8 if lowq else 14, 70.0, E.sg(t, 0.4, 1.0), fa, 2)

# ============================================================ th6 TIẾNG GỌI LINH HỒN (hồi 22%)
static func _soulcall(s, t: float, lowq: bool) -> void:
	var fa := E.fadeo(t, 0.8)
	var gc := Vector2(0, GY - 4.0)
	var up := E.eo(E.sg(t, 0.0, 0.2))
	# vòng hồi phục dưới chân (xanh lục)
	E.ering(s, gc, 52.0 * up, 13.0 * up, Color(HEAL, 0.3 * fa), 9.0)
	E.ering(s, gc, 52.0 * up, 13.0 * up, Color(HEAL, 0.95 * fa), 2.2)
	E.ering(s, gc, 38.0 * up, 9.0 * up, E.K(s, 0.7 * fa), 1.3)
	pillar(s, 0.0, -130.0, GY - 4.0, 54.0 * up, 0.7 * fa)
	# linh hồn từ trên cao hạ xuống, xoắn quanh người rồi hoà vào thân
	var n := 5 if lowq else 8
	for i in range(n):
		var q := E.sg(t, 0.06 + 0.05 * float(i), 0.62 + 0.04 * float(i))
		if q <= 0.0 or q >= 1.0: continue
		var a := TAU * float(i) / float(n) + q * 6.0
		var rr := 54.0 * (1.0 - q * 0.9) + 6.0
		var y := -110.0 + 118.0 * q
		var p := Vector2(cos(a) * rr, y + sin(a) * rr * 0.25)
		var vis := sin(q * PI) * 1.0
		wisp(s, p, 6.0, a + PI * 0.5 + 0.9, vis * fa, float(i))
	# dấu cộng xanh + lá cuốn lên
	for i in range(0 if lowq else 8):
		var ph := fmod(t * 1.1 + E.rnd(i, 2), 1.0)
		var x := (E.rnd(i, 3) - 0.5) * 56.0
		var y := 28.0 - 80.0 * ph
		var al := sin(ph * PI) * fa * E.sg(t, 0.15, 0.3)
		if i % 2 == 0:
			E.L(s, Vector2(x - 4, y), Vector2(x + 4, y), Color(HEAL, al), 2.0)
			E.L(s, Vector2(x, y - 4), Vector2(x, y + 4), Color(HEAL, al), 2.0)
		else:
			var lf := PackedVector2Array([Vector2(x, y - 5), Vector2(x + 4, y), Vector2(x, y + 5), Vector2(x - 4, y)])
			E.P(s, lf, Color(HEAL, al * 0.9))
	var ht := E.sg(t, 0.55, 0.8) * (1.0 - E.sg(t, 0.8, 1.0))
	if ht > 0.0:
		E.glow(s, Vector2(0, -8), 46.0, ht * 0.6)
		E.flare(s, Vector2(0, -16), 14.0 * ht, ht)

# ============================================================ BUFF / HỘ THỂ
## th2 Linh Thể Hộ Vệ: hiệp sĩ linh hồn cầm khiên đứng chắn phía trước người (guard giảm sát thương).
static func _guardian(s, t: float, lowq: bool) -> void:
	var up := E.eo(E.sg(t, 0.0, 0.25))
	var fa := E.fo(s, t, 0.85)
	var al := up * fa
	var gc := Vector2(0, GY - 4.0)
	E.ering(s, gc, 50.0 * up, 12.0 * up, E.A(s, 0.3 * al), 7.0)
	E.ering(s, gc, 50.0 * up, 12.0 * up, E.A(s, 0.85 * al), 2.0)
	if s.nocreature: return   # hiệp sĩ do sprite (FxCreature) đảm nhận
	var kx := 40.0 * up
	var bob := sin(t * 3.0) * 1.8
	var base := Vector2(kx, GY - 4.0 + bob)
	E.glow(s, base + Vector2(0, -34), 50.0, 0.18 * al)
	# thân hiệp sĩ: giáp ngực, chân váy giáp, đuôi linh khí tan
	var tail := PackedVector2Array([base + Vector2(-12, -14), base + Vector2(12, -14), base + Vector2(8, 4), base + Vector2(0, -4), base + Vector2(-8, 6)])
	E.P(s, tail, E.A(s, 0.4 * al))
	E.P(s, PackedVector2Array([base + Vector2(-13, -48), base + Vector2(13, -48), base + Vector2(10, -14), base + Vector2(-10, -14)]), E.A(s, 0.82 * al))
	E.P(s, PackedVector2Array([base + Vector2(-8, -46), base + Vector2(0, -46), base + Vector2(0, -16), base + Vector2(-7, -16)]), E.K(s, 0.35 * al))
	# vai giáp
	E.CI(s, base + Vector2(-14, -46), 7.0, E.A(s, 0.95 * al))
	E.CI(s, base + Vector2(14, -46), 7.0, E.A(s, 0.95 * al))
	# mũ trụ + chùm lông + mắt sáng
	E.CI(s, base + Vector2(0, -58), 10.0, E.A(s, 0.95 * al))
	E.P(s, PackedVector2Array([base + Vector2(-9, -60), base + Vector2(9, -60), base + Vector2(9, -53), base + Vector2(-9, -53)]), E.A(s, 0.9 * al))
	E.L(s, base + Vector2(-6, -57), base + Vector2(6, -57), E.K(s, 0.9 * al), 1.6)
	E.CI(s, base + Vector2(3, -57), 1.8, E.K(s, al))
	var plume := PackedVector2Array()
	for i in range(7):
		var u := float(i) / 6.0
		plume.append(base + Vector2(-2.0 - 24.0 * u, -66.0 - 6.0 * sin(u * 3.0) + sin(t * 6.0 + u * 3.0) * 3.0 * u))
	E.PL(s, plume, E.A(s, 0.8 * al), 5.0)
	E.PL(s, plume, E.K(s, 0.7 * al), 1.6)
	# khiên lớn phía trước (hình khiên nhọn, huy hiệu)
	var sc := base + Vector2(18, -28)
	var shield := PackedVector2Array([sc + Vector2(-9, -26), sc + Vector2(9, -26), sc + Vector2(11, 0), sc + Vector2(0, 26), sc + Vector2(-11, 0)])
	E.glow(s, sc, 34.0, 0.25 * al)
	E.P(s, shield, E.A(s, 0.95 * al))
	E.P(s, PackedVector2Array([sc + Vector2(-5, -20), sc + Vector2(5, -20), sc + Vector2(6, 0), sc + Vector2(0, 18), sc + Vector2(-6, 0)]), E.K(s, 0.75 * al))
	E.PL(s, shield + PackedVector2Array([shield[0]]), E.K(s, al), 1.6)
	E.L(s, sc + Vector2(0, -20), sc + Vector2(0, 17), E.A(s, 0.9 * al), 1.6)
	E.L(s, sc + Vector2(-6, -5), sc + Vector2(6, -5), E.A(s, 0.9 * al), 1.6)
	# kiếm cắm đất bên cạnh
	E.sword(s, base + Vector2(-20, -2), -PI * 0.5, 52.0, 6.0, 0.9 * al)
	# gợn chắn sát thương quanh khiên
	var rp := fmod(t * 0.9, 1.0)
	E.AR(s, sc, 18.0 + 22.0 * rp, -1.0, 1.0, 14, E.K(s, 0.6 * al * (1.0 - rp)), 1.6)
	# tia hồn bay quanh
	for i in range(0 if lowq else 4):
		var a := TAU * float(i) / 4.0 + t * 1.6
		wisp(s, base + Vector2(cos(a) * 32.0, -30.0 + sin(a) * 34.0), 3.6, a + PI * 0.5, 0.7 * al, float(i))

## th7 Linh Giới Hộ Thân: quả cầu linh giới bao quanh người, lưới lục giác, ánh phản xạ quay, gợn khi hấp thụ sát thương.
static func _ward(s, t: float, lowq: bool) -> void:
	var up := E.eo(E.sg(t, 0.0, 0.25))
	var fa := E.fo(s, t, 0.85)
	var al := up * fa
	var c := Vector2(0, -8)
	var R := 52.0 * up
	var gc := Vector2(0, GY - 4.0)
	E.ering(s, gc, 44.0 * up, 11.0 * up, E.A(s, 0.5 * al), 2.0)
	# thân cầu: nhiều lớp tròn mờ + viền sáng
	for i in range(6):
		E.CI(s, c, R * (1.0 - float(i) * 0.04), E.A(s, 0.035 * al))
	E.CI(s, c + Vector2(-R * 0.25, -R * 0.35), R * 0.5, E.K(s, 0.05 * al))
	E.AR(s, c, R, 0.0, TAU, 56, E.A(s, 0.3 * al), 6.0)
	E.AR(s, c, R, 0.0, TAU, 56, E.A(s, 0.9 * al), 2.0)
	E.AR(s, c, R - 2.0, PI * 1.05, PI * 1.55, 14, E.K(s, 0.9 * al), 2.2)
	# lưới kinh tuyến / vĩ tuyến quay
	for k in range(3):
		var ph := t * 0.9 + float(k) * PI / 3.0
		E.ering(s, c, R * absf(cos(ph)), R, E.A(s, 0.4 * al), 1.2)
	for k in range(2):
		var yy := (float(k) * 2.0 - 1.0) * R * 0.5
		var w := sqrt(maxf(R * R - yy * yy, 1.0))
		E.ering(s, c + Vector2(0, yy), w, w * 0.22, E.A(s, 0.35 * al), 1.1)
	# hạt mana bay quanh bề mặt
	for i in range(4 if lowq else 8):
		var a := TAU * float(i) / 8.0 + t * 2.2
		var p := c + Vector2(cos(a) * R, sin(a) * R * 0.9)
		E.CI(s, p, 2.4, E.K(s, 0.9 * al))
		E.glow(s, p, 7.0, 0.4 * al)
	# gợn hấp thụ sát thương
	var rp := fmod(t * 0.8, 1.0)
	var rr := sg_pt(rp)
	E.AR(s, c, R * (0.8 + 0.2 * rr), -0.7 + rp * 4.0, 0.2 + rp * 4.0, 12, E.K(s, 0.8 * al * (1.0 - rp)), 2.4)
	E.glow(s, c + Vector2(cos(rp * 9.0), sin(rp * 9.0)) * R * 0.95, 12.0, 0.5 * al * (1.0 - rp))

static func sg_pt(x: float) -> float:
	return E.eo(x)

## th4 Hiệu Lệnh Triệu Hồi: cường hóa thú đồng hành + chủ (atk +14%, tốc +15%): hiệu lệnh (cờ lệnh/dấu tay) phát sáng,
## hào quang lửa đỏ cam bốc lên, mũi tên tăng công + vạch tốc độ.
static func _command(s, t: float, lowq: bool) -> void:
	var up := E.eo(E.sg(t, 0.0, 0.22))
	var fa := E.fo(s, t, 0.85)
	var al := up * fa
	var gc := Vector2(0, GY - 4.0)
	E.ering(s, gc, 48.0 * up, 12.0 * up, E.A(s, 0.3 * al), 7.0)
	E.ering(s, gc, 48.0 * up, 12.0 * up, E.A(s, 0.9 * al), 2.2)
	# dấu chân thú xoay quanh vòng
	for k in range(4):
		var a := TAU * float(k) / 4.0 + t * 1.4
		var pc := ep(gc, a, 40.0 * up, 9.5 * up)
		E.CI(s, pc, 2.8, E.K(s, 0.85 * al))
		for j in range(3):
			E.CI(s, pc + Vector2((float(j) - 1.0) * 3.8, -4.2), 1.3, E.K(s, 0.85 * al))
	# hào quang lửa khí thế
	E.glow(s, Vector2(0, -10), 54.0 * up, 0.16 * al)
	var n := 6 if lowq else 9
	for i in range(n):
		var a2 := TAU * float(i) / float(n)
		E.flame(s, Vector2(cos(a2) * 30.0, GY - 4.0 + sin(a2) * 7.0), (40.0 + 24.0 * E.rnd(i, 2)) * up, 6.0, t, float(i), al * (0.55 if sin(a2) < 0.0 else 0.95))
	# mũi tên tăng công bay lên (chevron kép)
	for i in range(3 if lowq else 5):
		var ph := fmod(t * 0.9 + 0.2 * float(i), 1.0)
		var x := -34.0 + 17.0 * float(i)
		var y := 28.0 - 80.0 * ph
		var f := sin(ph * PI) * al
		E.PL(s, PackedVector2Array([Vector2(x - 6, y + 4), Vector2(x, y - 3), Vector2(x + 6, y + 4)]), E.K(s, f), 2.2)
		E.PL(s, PackedVector2Array([Vector2(x - 6, y + 10), Vector2(x, y + 3), Vector2(x + 6, y + 10)]), E.A(s, f * 0.8), 2.0)
	# vạch tăng tốc ở sau lưng
	E.speedlines(s, -70.0, -18.0, -30.0, 26.0, 5, 0.6 * al, int(t * 2.0))
	# cờ hiệu lệnh trên tay: cán + lá cờ phất
	var bx := Vector2(22.0, -4.0)
	E.L(s, bx + Vector2(0, 30), bx + Vector2(0, -46), E.K(s, 0.85 * al), 2.4)
	var flag := PackedVector2Array()
	var low := PackedVector2Array()
	for i in range(9):
		var u := float(i) / 8.0
		var w := sin(u * 5.0 - t * 8.0) * 3.5 * u
		flag.append(bx + Vector2(u * 26.0, -46.0 + w))
		low.append(bx + Vector2(u * 26.0 * (1.0 - 0.2 * u), -28.0 + w * 1.1))
	low.reverse()
	E.P(s, flag + low, E.A(s, 0.85 * al))
	E.PL(s, flag, E.K(s, 0.9 * al), 1.4)
	E.CI(s, bx + Vector2(9, -37), 2.4, E.K(s, al))
	E.flare(s, bx + Vector2(0, -48), 6.0 * al, al * 0.8)
	E.spark(s, Vector2(0, -12), 4 if lowq else 8, 54.0, fmod(t, 1.0), 0.7 * al, 3)

## th9 Cộng Hưởng Linh Thú: chủ và linh thú cùng tăng công + tốc đánh: hai vòng liên kết đan nhau, dây cộng hưởng giữa hai nhịp,
## sóng âm lan toả; bóng linh thú nhỏ mờ bên cạnh dùng chung nhịp.
static func _resonance(s, t: float, lowq: bool) -> void:
	var up := E.eo(E.sg(t, 0.0, 0.25))
	var fa := E.fo(s, t, 0.85)
	var al := up * fa
	var gc := Vector2(0, GY - 4.0)
	var pc := Vector2(-52.0 * up, 0.0)   # vị trí tượng trưng của linh thú bên cạnh
	# hai vòng đất đan nhau (chủ / thú)
	var spin := t * 1.6
	E.ering(s, gc, 44.0 * up, 11.0 * up, E.A(s, 0.85 * al), 2.0)
	E.ering(s, gc + Vector2(pc.x, 0), 38.0 * up, 9.5 * up, E.A(s, 0.85 * al), 2.0)
	E.ering(s, gc, 44.0 * up, 11.0 * up, E.A(s, 0.22 * al), 7.0)
	E.ering(s, gc + Vector2(pc.x, 0), 38.0 * up, 9.5 * up, E.A(s, 0.22 * al), 7.0)
	for k in range(6):
		var a := spin + TAU * float(k) / 6.0
		E.CI(s, ep(gc, a, 44.0 * up, 11.0 * up), 2.0, E.K(s, 0.9 * al))
		E.CI(s, ep(gc + Vector2(pc.x, 0), -a, 38.0 * up, 9.5 * up), 2.0, E.K(s, 0.9 * al))
	# bóng thú mờ + hào quang
	beast(s, Vector2(pc.x, GY - 2.0), 0.95, 0.35 * al, t)
	E.glow(s, Vector2(pc.x + 6.0, -4.0), 34.0, 0.18 * al)
	E.glow(s, Vector2(0, -8), 40.0, 0.18 * al)
	# dây cộng hưởng giữa thú và chủ: sóng sin biên độ nhịp
	for k in range(3):
		var pts := PackedVector2Array()
		for i in range(26):
			var u := float(i) / 25.0
			var amp := (9.0 - 2.5 * float(k)) * sin(u * PI)
			pts.append(Vector2(lerpf(pc.x + 14.0, -8.0, u), -18.0 + sin(u * 14.0 - t * 12.0 + float(k) * 1.2) * amp))
		E.PL(s, pts, E.A(s, (0.5 - 0.12 * float(k)) * al), 2.4 - 0.5 * float(k))
	E.PL(s, PackedVector2Array([Vector2(pc.x + 14.0, -18.0), Vector2(-8.0, -18.0)]), E.K(s, 0.5 * al), 1.0)
	# sóng cộng hưởng lan toả từ hai tâm
	for k in range(2):
		var ph := fmod(t * 0.8 + 0.5 * float(k), 1.0)
		var cx := 0.0 if k == 0 else pc.x
		E.AR(s, Vector2(cx, -10), 22.0 + 40.0 * ph, 0.0, TAU, 40, E.A(s, 0.7 * al * (1.0 - ph)), 2.0)
		E.AR(s, Vector2(cx, -10), 14.0 + 40.0 * ph, 0.0, TAU, 40, E.K(s, 0.45 * al * (1.0 - ph)), 1.0)
	# hạt công/tốc bay lên từ cả hai
	for i in range(0 if lowq else 8):
		var ph2 := fmod(t * 0.9 + E.rnd(i, 3), 1.0)
		var x := (pc.x if i % 2 == 0 else 0.0) + (E.rnd(i, 2) - 0.5) * 30.0
		var y := 26.0 - 70.0 * ph2
		E.CI(s, Vector2(x, y), 2.0, E.K(s, sin(ph2 * PI) * al))
	E.flare(s, Vector2(-26.0 * up, -18.0), 8.0 * al * (0.6 + 0.4 * sin(t * 9.0)), al * 0.9)
