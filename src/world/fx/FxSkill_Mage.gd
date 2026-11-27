extends RefCounted
## Hiệu ứng kỹ năng VẼ LẠI RIÊNG — PHÁP SƯ (các kỹ năng không phải đạn bay; đạn bay xem FxProj.gd).
## Quy ước như FxSkill_Swordsman/Archer/Assassin: place "bodyf", gốc = thân nhân vật, +x = hướng nhìn, y âm = lên, mặt đất y~+32.
## Bảng màu đặt riêng cho từng hệ bằng _pal (ghi đè màu chủ đề của manifest để băng luôn lam, lửa luôn cam...).
const E := preload("res://src/world/fx/FxSkill_Swordsman.gd")

const IDS := {
	"ps30": "pm_firewall", "ps32": "pm_icecircle", "tn3": "pm_iceprison", "tn6": "pm_iceburst", "ulPhap2": "pm_frozensea",
	"ps35": "pm_crystalguard", "tn4": "pm_energyshield", "ps37": "pm_lightball", "ps38": "pm_manarestore", "tn2": "pm_moonheal",
	"ps40": "pm_elemstorm", "ps45": "pm_heavenearth", "ps42": "pm_teleport", "tn10": "pm_elemblink", "tn11": "pm_hellfire",
	"tn5": "pm_meteor", "tn7": "pm_emberburst", "ulPhap1": "pm_thunderlord", "ulPhapSuper": "pm_forbidden",
}
## dur = thời lượng node; node giữ nguyên độ sáng tới 0.5*dur rồi mờ dần, t chạy 0..1 trong 0.75*dur giây.
const CFG := {
	"pm_firewall": {"place": "bodyf", "dur": 2.4, "nopop": true, "nobig": true},
	"pm_icecircle": {"place": "bodyf", "dur": 2.4, "nopop": true, "nobig": true},
	"pm_iceprison": {"place": "bodyf", "dur": 2.4, "nopop": true, "nobig": true},
	"pm_iceburst": {"place": "bodyf", "dur": 2.2, "nopop": true, "nobig": true},
	"pm_frozensea": {"place": "bodyf", "dur": 3.0, "nopop": true, "nobig": true, "rumble": 4.0},
	"pm_crystalguard": {"place": "bodyf", "dur": 1.8, "nopop": true, "nobig": true},
	"pm_energyshield": {"place": "bodyf", "dur": 1.8, "nopop": true, "nobig": true},
	"pm_lightball": {"place": "bodyf", "dur": 3.4, "nopop": true, "nobig": true, "rumble": 5.0},
	"pm_manarestore": {"place": "bodyf", "dur": 2.4, "nopop": true, "nobig": true},
	"pm_moonheal": {"place": "bodyf", "dur": 2.2, "nopop": true, "nobig": true},
	"pm_elemstorm": {"place": "bodyf", "dur": 4.0, "nopop": true, "nobig": true, "rumble": 5.0},
	"pm_heavenearth": {"place": "bodyf", "dur": 5.2, "nopop": true, "nobig": true, "rumble": 7.0},
	"pm_teleport": {"place": "bodyf", "dur": 1.6, "nopop": true, "nobig": true},
	"pm_elemblink": {"place": "bodyf", "dur": 1.5, "nopop": true, "nobig": true},
	"pm_hellfire": {"place": "bodyf", "dur": 4.2, "nopop": true, "nobig": true, "rumble": 6.0},
	"pm_meteor": {"place": "bodyf", "dur": 3.0, "nopop": true, "nobig": true, "rumble": 12.0},
	"pm_emberburst": {"place": "bodyf", "dur": 3.4, "nopop": true, "nobig": true, "rumble": 5.0},
	"pm_thunderlord": {"place": "bodyf", "dur": 4.8, "nopop": true, "nobig": true, "rumble": 8.0},
	"pm_forbidden": {"place": "bodyf", "dur": 3.6, "nopop": true, "nobig": true, "rumble": 16.0},
}
## Hào quang buff kéo dài (s.steady): hai khiên mana.
const AURA_IDS := ["pm_crystalguard", "pm_energyshield"]

const GY := 32.0
const FR := 0.24   # tỉ lệ dẹt của vòng trên mặt đất

static func draw(s, sg: String, t: float, lowq: bool) -> void:
	match sg:
		"pm_firewall": _firewall(s, t, lowq)
		"pm_icecircle": _icecircle(s, t, lowq)
		"pm_iceprison": _iceprison(s, t, lowq)
		"pm_iceburst": _iceburst(s, t, lowq)
		"pm_frozensea": _frozensea(s, t, lowq)
		"pm_crystalguard": _crystalguard(s, t, lowq)
		"pm_energyshield": _energyshield(s, t, lowq)
		"pm_lightball": _lightball(s, t, lowq)
		"pm_manarestore": _manarestore(s, t, lowq)
		"pm_moonheal": _moonheal(s, t, lowq)
		"pm_elemstorm": _elemstorm(s, t, lowq)
		"pm_heavenearth": _heavenearth(s, t, lowq)
		"pm_teleport": _teleport(s, t, lowq)
		"pm_elemblink": _elemblink(s, t, lowq)
		"pm_hellfire": _hellfire(s, t, lowq)
		"pm_meteor": _meteor(s, t, lowq)
		"pm_emberburst": _emberburst(s, t, lowq)
		"pm_thunderlord": _thunderlord(s, t, lowq)
		"pm_forbidden": _forbidden(s, t, lowq)

static func draw_aura(s, sg: String, t: float, lowq: bool) -> void:
	match sg:
		"pm_crystalguard": _crystalguard(s, 1.0 + t, lowq)
		"pm_energyshield": _energyshield(s, 1.0 + t, lowq)

# ============================================================ BẢNG MÀU + TIỆN ÍCH
static func _pal(s, k: String) -> void:
	match k:
		"fire":
			s.col = Color(1.0, 0.45, 0.1); s.core = Color(1.0, 0.92, 0.55)
		"hell":
			s.col = Color(1.0, 0.25, 0.08); s.core = Color(1.0, 0.78, 0.3)
		"ice":
			s.col = Color(0.4, 0.78, 1.0); s.core = Color(0.92, 0.98, 1.0)
		"bolt":
			s.col = Color(0.5, 0.58, 1.0); s.core = Color(1.0, 1.0, 0.82)
		"mana":
			s.col = Color(0.2, 0.5, 1.0); s.core = Color(0.75, 0.92, 1.0)
		"heal":
			s.col = Color(0.3, 0.9, 0.5); s.core = Color(0.92, 1.0, 0.9)
		"arcane":
			s.col = Color(0.68, 0.4, 1.0); s.core = Color(1.0, 0.9, 1.0)
		"earth":
			s.col = Color(0.85, 0.6, 0.25); s.core = Color(1.0, 0.92, 0.65)
		"holy":
			s.col = Color(1.0, 0.82, 0.35); s.core = Color(1.0, 1.0, 0.9)

static func _sec(t: float, dur: float) -> float:
	return t * dur * 0.75

static func _ep(c: Vector2, R: float, a: float) -> Vector2:
	return c + Vector2(cos(a) * R, sin(a) * R * FR)

static func _gfill(s, c: Vector2, R: float, col: Color) -> void:
	if R < 2.0 or col.a <= 0.005: return
	s.draw_set_transform(c, 0.0, Vector2(1.0, FR))
	s.draw_circle(Vector2.ZERO, R, col, true, -1.0, true)
	E.rst(s)

static func _trail(s, ln: float, w: float, al: float) -> void:
	var c0 := E.A(s, al)
	var c1 := E.A(s, 0.0)
	E.PG(s, PackedVector2Array([Vector2(0, -w), Vector2(0, w), Vector2(-ln, w * 0.2), Vector2(-ln, -w * 0.2)]), PackedColorArray([c0, c0, c1, c1]))
	var k0 := E.K(s, al * 0.9)
	var k1 := E.K(s, 0.0)
	E.PG(s, PackedVector2Array([Vector2(0, -w * 0.4), Vector2(0, w * 0.4), Vector2(-ln * 0.7, 0.0)]), PackedColorArray([k0, k0, k1]))

## Đa giác sao {n/step} trên mặt đất (ellipse).
static func _gstar(s, c: Vector2, R: float, rot: float, n: int, step: int, col: Color, w: float) -> void:
	for k in range(n):
		var a := rot + TAU * float(k) / float(n)
		var b := rot + TAU * float((k + step) % n) / float(n)
		E.L(s, _ep(c, R, a), _ep(c, R, b), col, w)

## Trận rune dưới đất theo hệ: kind fire/ice/bolt/arcane/mana/elem/bagua.
static func _rune(s, c: Vector2, R: float, rot: float, kind: String, al: float) -> void:
	if R < 8.0 or al <= 0.01: return
	E.ering(s, c, R, R * FR, E.A(s, al * 0.28), 7.0)
	E.ering(s, c, R, R * FR, E.A(s, al * 0.9), 2.2)
	E.ering(s, c, R * 0.88, R * 0.88 * FR, E.K(s, al * 0.6), 1.2)
	for i in range(28):
		var a := rot + TAU * float(i) / 28.0
		E.L(s, _ep(c, R * 0.88, a), _ep(c, R * (0.96 if i % 2 == 0 else 0.93), a), E.A(s, al * 0.7), 1.2)
	var ca := E.A(s, al * 0.85)
	var ck := E.K(s, al * 0.7)
	match kind:
		"fire":
			_gstar(s, c, R * 0.78, rot, 3, 1, ca, 1.8)
			_gstar(s, c, R * 0.78, rot + PI, 3, 1, ca, 1.8)
			E.ering(s, c, R * 0.36, R * 0.36 * FR, ck, 1.4)
			for k in range(6):
				var a2 := rot + TAU * float(k) / 6.0
				E.flame(s, _ep(c, R * 0.78, a2), 12.0, 4.0, rot * 3.0, float(k), al * 0.8)
		"ice":
			for k in range(6):
				var a3 := rot + TAU * float(k) / 6.0
				var tip := _ep(c, R * 0.8, a3)
				E.L(s, c, tip, ca, 2.0)
				for sd in [-1.0, 1.0]:
					var bm := _ep(c, R * 0.5, a3)
					var ba := a3 + float(sd) * 0.7
					E.L(s, bm, bm + Vector2(cos(ba), sin(ba) * FR) * R * 0.2, ck, 1.4)
				E.CI(s, tip, 2.6, E.K(s, al))
			_gstar(s, c, R * 0.48, rot * 0.5, 6, 2, ck, 1.2)
		"bolt":
			var pts := PackedVector2Array()
			for k in range(17):
				var a4 := rot + TAU * float(k) / 16.0
				pts.append(_ep(c, R * (0.8 if k % 2 == 0 else 0.5), a4))
			E.PL(s, pts, ca, 1.8)
			E.ering(s, c, R * 0.3, R * 0.3 * FR, ck, 1.4)
		"arcane":
			_gstar(s, c, R * 0.78, rot, 5, 2, ca, 1.8)
			E.ering(s, c, R * 0.4, R * 0.4 * FR, ck, 1.4)
		"mana":
			_gstar(s, c, R * 0.78, rot, 8, 3, ca, 1.6)
			_gstar(s, c, R * 0.52, -rot, 4, 1, ck, 1.4)
		"elem":
			_gstar(s, c, R * 0.78, rot, 3, 1, ca, 1.8)
			_gstar(s, c, R * 0.78, rot + PI, 3, 1, ck, 1.8)
			for k in range(3):
				var a5 := rot - PI * 0.5 + TAU * float(k) / 3.0
				E.CI(s, _ep(c, R * 0.78, a5), 4.0, E.K(s, al))
		"bagua":
			for k in range(8):
				var a6 := rot + TAU * float(k) / 8.0
				var p0 := _ep(c, R * 0.66, a6)
				var p1 := _ep(c, R * 0.8, a6)
				var tg := (p1 - p0)
				for q in range(3):
					var broken := ((k * 5 + q * 3) % 4) < 2
					var mid := p0 + tg * (0.3 + 0.2 * float(q))
					var sd2 := Vector2(-tg.y, tg.x).normalized() * 6.0
					if broken:
						E.L(s, mid - sd2, mid - sd2 * 0.2, ca, 1.6)
						E.L(s, mid + sd2 * 0.2, mid + sd2, ca, 1.6)
					else:
						E.L(s, mid - sd2, mid + sd2, ca, 1.6)
			E.ering(s, c, R * 0.5, R * 0.5 * FR, ck, 1.4)

## Tia sét ngoằn ngoèo a -> b, hào quang + lõi sáng + nhánh phụ.
static func _bolt(s, a: Vector2, b: Vector2, sd: int, al: float, w: float = 2.0, jag: float = 16.0, branch: bool = true) -> void:
	var d := b - a
	var ln := d.length()
	if ln < 4.0 or al <= 0.01: return
	var nr := d.orthogonal() / ln
	var n := maxi(4, int(ln / 22.0))
	var pts := PackedVector2Array([a])
	for i in range(1, n):
		var u := float(i) / float(n)
		pts.append(a + d * u + nr * (E.rnd(i, sd) - 0.5) * 2.0 * jag * (0.35 + 0.65 * sin(u * PI)))
	pts.append(b)
	E.PL(s, pts, E.A(s, al * 0.22), w * 4.5)
	E.PL(s, pts, E.A(s, al * 0.8), w * 2.0)
	E.PL(s, pts, E.K(s, al), maxf(1.0, w * 0.8))
	if branch and n >= 5:
		for k in range(2):
			var bi := 2 + k * maxi(1, (n - 3) / 2)
			if bi >= n: continue
			var p0: Vector2 = pts[bi]
			var p1 := p0 + d / ln * ln * 0.22 + nr * (E.rnd(k + 3, sd + 5) - 0.5) * ln * 0.34
			E.PL(s, PackedVector2Array([p0, p0.lerp(p1, 0.5) + nr * (E.rnd(k, sd + 9) - 0.5) * 8.0, p1]), E.K(s, al * 0.7), maxf(1.0, w * 0.55))

## Tinh thể băng một khối: hai mặt sáng/tối + viền; base = chân, h = cao, w = nửa rộng.
static func _crystal(s, base: Vector2, h: float, w: float, al: float, lean: float = 0.0) -> void:
	if h < 6.0 or w < 1.5 or al <= 0.01: return
	var tip := base + Vector2(lean * h, -h)
	var m := base.lerp(tip, 0.58)
	var l := base + Vector2(-w, 0)
	var r := base + Vector2(w, 0)
	var ml := m + Vector2(-w * 0.82, 0)
	var mr := m + Vector2(w * 0.82, 0)
	E.P(s, PackedVector2Array([l, ml, tip, base + Vector2(0, -h * 0.04)]), E.A(s, al * 0.8))
	E.P(s, PackedVector2Array([r, mr, tip, base + Vector2(0, -h * 0.04)]), E.K(s, al * 0.75))
	E.PL(s, PackedVector2Array([l, ml, tip, mr, r]), E.K(s, al), 1.1)
	E.L(s, base + Vector2(0, -h * 0.04), tip, E.K(s, al * 0.7), 1.0)
	E.L(s, ml, mr, E.A(s, al * 0.6), 1.0)

## Bông tuyết 6 cánh thẳng đứng (biểu tượng đóng băng).
static func _snowflake(s, p: Vector2, r: float, rot: float, al: float) -> void:
	if r < 3.0 or al <= 0.01: return
	E.glow(s, p, r * 1.2, al * 0.4)
	for k in range(6):
		var a := rot + TAU * float(k) / 6.0
		var d := Vector2(cos(a), sin(a))
		var tip := p + d * r
		E.L(s, p, tip, E.A(s, al * 0.9), 2.2)
		E.L(s, p, tip, E.K(s, al), 1.0)
		for sd in [-1.0, 1.0]:
			var bm := p + d * r * 0.55
			var bd := Vector2(cos(a + float(sd) * 0.7), sin(a + float(sd) * 0.7))
			E.L(s, bm, bm + bd * r * 0.32, E.K(s, al * 0.85), 1.3)
	E.CI(s, p, r * 0.14, E.K(s, al))

## Quả cầu năng lượng phát sáng.
static func _orb(s, p: Vector2, r: float, al: float) -> void:
	if r < 2.0 or al <= 0.01: return
	E.glow(s, p, r * 2.4, al * 0.65)
	E.CI(s, p, r, E.A(s, al * 0.95))
	E.CI(s, p, r * 0.68, E.M(s, 0.5, al))
	E.CI(s, p + Vector2(-r * 0.12, -r * 0.14), r * 0.36, E.K(s, al))

## Tảng đá lởm chởm.
static func _rock(s, p: Vector2, r: float, rot: float, sd: int, al: float) -> void:
	if r < 2.0 or al <= 0.01: return
	var pts := PackedVector2Array()
	var n := 8
	for i in range(n):
		var a := rot + TAU * float(i) / float(n)
		pts.append(p + Vector2(cos(a), sin(a)) * r * (0.72 + 0.45 * E.rnd(i, sd)))
	E.P(s, pts, Color(0.3, 0.2, 0.16, al))
	var hi := PackedVector2Array([pts[0], pts[1], pts[2], pts[3]])
	E.PL(s, hi, E.K(s, al * 0.8), 1.4)
	E.L(s, pts[1].lerp(pts[5], 0.3), pts[2].lerp(pts[6], 0.5), E.A(s, al * 0.8), 1.2)

## Vật rơi từ trời (đầu sao băng) hướng theo vận tốc: ang = góc bay.
static func _comet(s, pos: Vector2, ang: float, r: float, style: String, sec: float) -> void:
	s.draw_set_transform(pos, ang, Vector2.ONE)
	match style:
		"fire", "hell":
			_trail(s, r * 8.0, r * 1.05, 0.6)
			s.draw_set_transform(pos, ang - PI * 0.5, Vector2.ONE)
			for k in range(5):
				E.flame(s, Vector2((float(k) - 2.0) * r * 0.3, r * 0.4 + float(k) * r * 0.22), r * 4.4, r * 0.72, sec, float(k), 0.6)
			s.draw_set_transform(pos, ang, Vector2.ONE)
			E.glow(s, Vector2.ZERO, r * 2.8, 0.75)
			E.CI(s, Vector2.ZERO, r, E.A(s, 0.95))
			E.CI(s, Vector2.ZERO, r * 0.7, E.M(s, 0.5, 0.95))
			E.CI(s, Vector2(r * 0.15, 0), r * 0.4, E.K(s, 1.0))
		"ice":
			_trail(s, r * 7.0, r * 0.8, 0.5)
			E.glow(s, Vector2.ZERO, r * 2.4, 0.55)
			E.P(s, PackedVector2Array([Vector2(r * 2.6, 0), Vector2(0, -r * 0.8), Vector2(-r * 1.5, 0), Vector2(0, r * 0.8)]), E.K(s, 0.92))
			E.P(s, PackedVector2Array([Vector2(r * 2.6, 0), Vector2(0, -r * 0.8), Vector2(-r * 1.5, 0)]), E.A(s, 0.85))
			E.L(s, Vector2(r * 2.6, 0), Vector2(-r * 1.5, 0), E.K(s, 0.9), 1.0)
			for i in range(5):
				var u := fmod(sec * 2.0 + float(i) / 5.0, 1.0)
				E.star(s, Vector2(-r * 1.4 - u * r * 5.0, (E.rnd(i, 3) - 0.5) * r * 1.6), r * 0.45 * (1.0 - u) + 1.0, 1.0 - u, 4)
		"bolt":
			_trail(s, r * 6.0, r * 0.7, 0.4)
			E.glow(s, Vector2.ZERO, r * 3.0, 0.7)
			E.CI(s, Vector2.ZERO, r * 1.1, E.A(s, 0.9))
			E.CI(s, Vector2.ZERO, r * 0.65, E.K(s, 1.0))
			var fr := int(sec * 24.0)
			for k in range(6):
				var a := TAU * E.rnd(k, fr)
				var d := Vector2(cos(a), sin(a))
				var mid := d * r * 1.7 + d.orthogonal() * (E.rnd(k + 6, fr) - 0.5) * r
				E.PL(s, PackedVector2Array([d * r, mid, d * r * 2.5 + d.orthogonal() * (E.rnd(k + 9, fr) - 0.5) * r]), E.K(s, 0.9), 1.5)
		"earth":
			_trail(s, r * 6.0, r * 0.9, 0.5)
			E.glow(s, Vector2.ZERO, r * 2.4, 0.5)
			_rock(s, Vector2.ZERO, r * 1.1, sec * 3.0, 3, 1.0)
		_:   # arcane / holy: cầu phép có vòng ấn
			_trail(s, r * 7.0, r * 0.9, 0.5)
			_orb(s, Vector2.ZERO, r, 1.0)
			E.AR(s, Vector2.ZERO, r * 1.9, sec * 6.0, sec * 6.0 + 3.6, 20, E.K(s, 0.8), 1.6)
			E.AR(s, Vector2.ZERO, r * 1.4, -sec * 5.0, -sec * 5.0 + 3.0, 16, E.A(s, 0.8), 1.4)
	E.rst(s)

## Vị trí vật rơi: xuất phát (x-150, -360) -> chạm (x, GY-8). p 0..1 (đã ease-in). Trả về [pos, ang].
static func _fallpos(x: float, p: float) -> Array:
	var a := Vector2(x - 150.0, -360.0)
	var b := Vector2(x, GY - 8.0)
	var q := E.ei(p) * 0.82 + p * 0.18
	return [a.lerp(b, q), (b - a).angle()]

# ============================================================ HỆ NGUYÊN TỐ DÙNG CHO BÃO NGUYÊN TỐ / THIÊN ĐỊA HỢP NHẤT
## Vụ nổ theo nguyên tố tại điểm chạm gp, age giây kể từ lúc chạm, R = bán kính vùng.
static func _ehit(s, el: String, gp: Vector2, R: float, age: float, lowq: bool, sd: int) -> void:
	_pal(s, el)
	var e := E.eo(E.sg(age, 0.0, 0.4))
	var fa := 1.0 - E.sg(age, 0.55, 1.5)
	if fa <= 0.0: return
	E.glow(s, gp + Vector2(0, -16), 110.0 * (1.0 - E.sg(age, 0.0, 0.3)), 0.7)
	_gfill(s, gp, R * e, E.A(s, 0.12 * fa))
	E.shock(s, gp, R * e, R * e * FR, fa)
	match el:
		"fire":
			for i in range(9):
				var a := TAU * float(i) / 9.0 + 0.3
				var p := _ep(gp, R * 0.8 * e * (0.4 + 0.6 * E.rnd(i, sd)), a)
				E.flame(s, p, (46.0 + 40.0 * E.rnd(i, sd + 1)) * e, 11.0, age * 2.0, float(i), fa)
			E.star(s, gp + Vector2(0, -24), 50.0 * (1.0 - age * 0.5), fa, 8)
		"ice":
			for i in range(10):
				var a2 := TAU * float(i) / 10.0 + 0.2
				var p2 := _ep(gp, R * 0.8 * e * (0.3 + 0.7 * E.rnd(i, sd)), a2)
				_crystal(s, p2, (40.0 + 46.0 * E.rnd(i, sd + 1)) * E.eo(E.sg(age, 0.03 * float(i), 0.03 * float(i) + 0.25)), 7.0, fa, (E.rnd(i, sd + 2) - 0.5) * 0.3)
			E.spark(s, gp + Vector2(0, -20), 0 if lowq else 14, R * 0.5, age * 1.4, fa, sd)
		"bolt":
			for i in range(7):
				var a3 := TAU * float(i) / 7.0 + 0.4
				var q := _ep(gp, R * 0.85 * e, a3)
				_bolt(s, gp, q, sd + i + int(age * 14.0), fa * (1.0 - E.sg(age, 0.3, 0.9)), 1.8, 12.0, false)
				E.flare(s, q, 6.0, fa * 0.7)
			E.star(s, gp + Vector2(0, -20), 36.0 * (1.0 - age * 0.5), fa, 6)
		"earth":
			for i in range(9):
				var a4 := TAU * float(i) / 9.0 + 0.1
				var p4 := _ep(gp, R * 0.7 * e * (0.3 + 0.7 * E.rnd(i, sd)), a4)
				var hh := (50.0 + 50.0 * E.rnd(i, sd + 1)) * E.eo(E.sg(age, 0.02 * float(i), 0.02 * float(i) + 0.2))
				if hh > 8.0:
					E.P(s, PackedVector2Array([p4 + Vector2(-9, 0), p4 + Vector2(-2, -hh), p4 + Vector2(8, 0)]), Color(0.42, 0.3, 0.2, fa))
					E.P(s, PackedVector2Array([p4 + Vector2(-2, -hh), p4 + Vector2(8, 0), p4 + Vector2(1, 0)]), Color(0.62, 0.46, 0.3, fa * 0.9))
					E.L(s, p4 + Vector2(-2, -hh), p4 + Vector2(-9, 0), E.K(s, fa * 0.8), 1.2)
			E.dust(s, gp, R * 0.5, age, fa, 4 if lowq else 8, sd)
		_:   # arcane: cột sáng + vòng ấn
			_rune(s, gp, R * 0.8 * e, age * 1.5, "arcane", fa)
			E.beam(s, gp.x, gp.y - 240.0, gp.y, 16.0, 28.0, fa * (1.0 - E.sg(age, 0.3, 0.9)))
			E.star(s, gp + Vector2(0, -24), 40.0 * (1.0 - age * 0.5), fa, 6)

# ============================================================ HỎA TƯỜNG
## ps30: dải lửa ma thuật dựng thành vòng quanh người (r=220), nền trận rune lửa, tàn lửa bay lên.
static func _firewall(s, t: float, lowq: bool) -> void:
	_pal(s, "fire")
	var R := 220.0
	var up := E.eo(E.sg(t, 0.0, 0.22))
	var fa := E.fadeo(t, 0.7)
	var gc := Vector2(0, GY - 4.0)
	_gfill(s, gc, R * up, E.A(s, 0.08 * fa))
	_rune(s, gc, R * up, t * 0.7, "fire", fa)
	var n := 22
	for pass_i in range(2):
		for i in range(n):
			var a := TAU * float(i) / float(n) + 0.12
			var front := sin(a) >= 0.0
			if (pass_i == 1) != front: continue
			var ta := 0.05 + 0.34 * float(i) / float(n)
			var u := E.eo(E.sg(t, ta, ta + 0.2))
			if u <= 0.0: continue
			var persp := 1.0 + 0.3 * sin(a)
			var p := _ep(gc, R * 0.97 * up, a)
			var h := (64.0 + 34.0 * E.rnd(i, 1)) * u * persp
			E.flame(s, p, h, 13.0 * persp, t * 2.4, float(i), fa)
			var pm := _ep(gc, R * 0.97 * up, a + PI / float(n))
			E.flame(s, pm, h * 0.55, 8.0 * persp, t * 2.4, float(i) + 4.0, fa * 0.85)
			if not lowq and i % 2 == 0:
				E.glow(s, p + Vector2(0, -h * 0.4), 24.0 * persp, 0.22 * fa * u)
	for i in range(0 if lowq else 18):
		var a2 := TAU * E.rnd(i, 4)
		var rise := fmod(t * 1.3 + E.rnd(i, 5), 1.0)
		var p2 := _ep(gc, R * up * (0.4 + 0.6 * E.rnd(i, 6)), a2) + Vector2(sin(rise * 9.0 + float(i)) * 6.0, -rise * 110.0)
		E.CI(s, p2, 1.9 * (1.0 - rise) + 0.6, E.K(s, fa * (1.0 - rise) * up))

# ============================================================ BĂNG PHONG TRẬN
## ps32: trận băng hoa tuyết r=240 bung ra, tinh thể băng trồi theo vòng, sóng lạnh đóng băng lan khắp vùng.
static func _icecircle(s, t: float, lowq: bool) -> void:
	_pal(s, "ice")
	var R := 240.0
	var up := E.eo(E.sg(t, 0.0, 0.25))
	var fa := E.fadeo(t, 0.72)
	var gc := Vector2(0, GY - 4.0)
	_gfill(s, gc, R * up, E.A(s, 0.12 * fa))
	_rune(s, gc, R * up, -t * 0.6, "ice", fa)
	for pass_i in range(2):
		for i in range(14):
			var a := TAU * float(i) / 14.0 + 0.2
			if (pass_i == 1) != (sin(a) >= 0.0): continue
			var ta := 0.16 + 0.26 * E.rnd(i, 1)
			var u := E.eo(E.sg(t, ta, ta + 0.24))
			var persp := 1.0 + 0.3 * sin(a)
			_crystal(s, _ep(gc, R * 0.93 * up, a), (72.0 + 52.0 * E.rnd(i, 2)) * u * persp, 9.0 * persp, fa, (E.rnd(i, 3) - 0.5) * 0.22)
	for i in range(8):
		var a2 := TAU * float(i) / 8.0 + 0.5
		var u2 := E.eo(E.sg(t, 0.3 + 0.03 * float(i), 0.55))
		_crystal(s, _ep(gc, R * 0.5 * up, a2), (34.0 + 22.0 * E.rnd(i, 4)) * u2, 6.0, fa * 0.9, (E.rnd(i, 5) - 0.5) * 0.3)
	# bông tuyết lớn trên đầu + sóng lạnh lan khắp vùng
	_snowflake(s, Vector2(0, -88.0 - 6.0 * sin(t * 5.0)), 20.0 * E.eo(E.sg(t, 0.05, 0.35)), t * 1.2, fa)
	var w := E.eo(E.sg(t, 0.4, 0.85))
	if w > 0.0:
		E.shock(s, gc, R * w, R * w * FR, 1.0 - E.sg(t, 0.6, 0.95))
		for i in range(0 if lowq else 16):
			var p := _ep(gc, R * w * E.rnd(i, 7), TAU * E.rnd(i, 8)) + Vector2(0, -16.0 * w)
			E.star(s, p, 4.0, fa * (1.0 - E.sg(t, 0.7, 1.0)), 4)
	for i in range(0 if lowq else 14):
		var fall := fmod(t * 0.9 + E.rnd(i, 9), 1.0)
		var sp := Vector2((E.rnd(i, 10) - 0.5) * R * 1.5, -130.0 + fall * 160.0)
		E.CI(s, sp, 1.6, E.K(s, fa * 0.9 * up))

# ============================================================ BĂNG NGỤC
## tn3: các trụ băng trồi quanh người, cong vào đỉnh thành chiếc lồng băng có vành ngang, khoá lại ở đỉnh.
static func _iceprison(s, t: float, lowq: bool) -> void:
	_pal(s, "ice")
	var R := 210.0
	var up := E.eo(E.sg(t, 0.0, 0.2))
	var fa := E.fadeo(t, 0.74)
	var gc := Vector2(0, GY - 4.0)
	var apex := Vector2(0, -160.0)
	_gfill(s, gc, R * up, E.A(s, 0.14 * fa))
	E.ering(s, gc, R * up, R * up * FR, E.A(s, 0.9 * fa), 2.4)
	E.ering(s, gc, R * 0.9 * up, R * 0.9 * up * FR, E.K(s, 0.6 * fa), 1.2)
	_gstar(s, gc, R * 0.7 * up, t * 0.4, 4, 1, E.A(s, 0.8 * fa), 1.6)   # ấn khoá hình thoi
	var nb := 10
	var bars: Array = []
	var gs: Array = []
	for i in range(nb):
		var a := TAU * float(i) / float(nb) + 0.15
		var base := _ep(gc, R * 0.9 * up, a)
		var ta := 0.1 + 0.25 * E.rnd(i, 1)
		var g := E.eo(E.sg(t, ta, ta + 0.38))
		var ctrl := Vector2(base.x * 0.95, -90.0)
		var pts := PackedVector2Array()
		for k in range(15):
			var u := float(k) / 14.0
			pts.append(base.lerp(ctrl, u).lerp(ctrl.lerp(apex, u), u))
		bars.append(pts)
		gs.append(g)
	# vành ngang nối các trụ ở hai độ cao
	for lv in [4, 8]:
		var ring := PackedVector2Array()
		var ok := true
		for i in range(nb):
			if float(lv) / 14.0 > float(gs[i]):
				ok = false
				break
			ring.append((bars[i] as PackedVector2Array)[lv])
		if ok:
			ring.append(ring[0])
			E.PL(s, ring, E.A(s, 0.35 * fa), 5.0)
			E.PL(s, ring, E.K(s, 0.85 * fa), 1.4)
	for i in range(nb):
		var pts2: PackedVector2Array = bars[i]
		var g2: float = gs[i]
		var cnt := int(g2 * 14.0) + 1
		if cnt < 2: continue
		var part := PackedVector2Array()
		for k in range(cnt):
			part.append(pts2[k])
		E.PL(s, part, E.A(s, 0.3 * fa), 9.0)
		E.PL(s, part, E.A(s, 0.85 * fa), 4.0)
		E.PL(s, part, E.K(s, fa), 1.5)
		_crystal(s, pts2[0], 30.0 * g2, 7.0, fa * 0.9, 0.0)
		E.flare(s, part[part.size() - 1], 4.0, fa * 0.7 * g2)
	# khoá ở đỉnh lồng
	var lk := E.eo(E.sg(t, 0.55, 0.72))
	if lk > 0.0:
		E.star(s, apex + Vector2(0, -4), 22.0 * lk, fa, 6)
		_snowflake(s, apex + Vector2(0, -34), 13.0 * lk, t, fa)
	E.dust(s, gc, 60.0, E.sg(t, 0.1, 0.8), fa * 0.6, 3 if lowq else 6, 5)

# ============================================================ BĂNG LƯU BẠO
## tn6: quả cầu băng gom ở ngực rồi nổ thành bão tuyết: gai băng toả, xoáy tuyết quét vòng, sóng lạnh r=190.
static func _iceburst(s, t: float, lowq: bool) -> void:
	_pal(s, "ice")
	var R := 190.0
	var fa := E.fadeo(t, 0.72)
	var gc := Vector2(0, GY - 4.0)
	var c := Vector2(0, -14.0)
	var gather := E.eo(E.sg(t, 0.0, 0.25))
	var boom := E.sg(t, 0.25, 0.8)
	var e := E.eo(boom)
	if boom <= 0.0:
		_orb(s, c, 7.0 + 12.0 * gather, gather)
		_snowflake(s, c, 18.0 * gather, t * 8.0, gather)
		for i in range(10):
			var a := TAU * float(i) / 10.0 - t * 6.0
			var rr := 70.0 * (1.0 - gather) + 12.0
			E.CI(s, c + Vector2(cos(a) * rr, sin(a) * rr * 0.6), 2.0, E.K(s, gather))
	else:
		E.glow(s, c, 120.0 * (1.0 - boom), 0.8 * fa)
		# xoáy tuyết 3 cánh quét quanh
		for k in range(3):
			var a0 := TAU * float(k) / 3.0 + t * 7.0
			E.swoosh(s, c, 40.0 + (R - 40.0) * e, a0, a0 + 3.2, 1.0, 0.8, 22.0, 0.75 * fa * (1.0 - 0.4 * boom), 0.34)
		# gai băng bắn ra
		for i in range(16):
			var a2 := TAU * float(i) / 16.0 + 0.1
			var d := Vector2(cos(a2), sin(a2) * 0.4)
			var p := c + d * R * (0.25 + 0.75 * e) * (0.7 + 0.3 * E.rnd(i, 1))
			var ang := d.angle()
			s.draw_set_transform(p, ang, Vector2.ONE)
			E.P(s, PackedVector2Array([Vector2(16, 0), Vector2(-4, -4.5), Vector2(-10, 0), Vector2(-4, 4.5)]), E.K(s, fa * 0.95))
			E.P(s, PackedVector2Array([Vector2(16, 0), Vector2(-4, -4.5), Vector2(-10, 0)]), E.A(s, fa * 0.9))
			E.rst(s)
		E.shock(s, gc, R * e, R * e * FR, fa)
		_gfill(s, gc, R * e, E.A(s, 0.14 * fa))
		for i in range(0 if lowq else 22):
			var a3 := TAU * E.rnd(i, 2) + t * 3.0
			var rr2 := R * e * E.rnd(i, 3)
			E.star(s, c + Vector2(cos(a3) * rr2, sin(a3) * rr2 * 0.45), 3.0 + 2.0 * E.rnd(i, 4), fa * (1.0 - boom * 0.5), 4)

# ============================================================ BĂNG HẢI PHONG THIÊN
## ulPhap2: biển băng r=330 — mặt biển đóng băng nứt vỡ, những con sóng bị đóng băng giữa chừng, núi băng trồi lên, tuyết rơi.
static func _wavefrozen(s, base: Vector2, h: float, w: float, al: float) -> void:
	if h < 8.0 or al <= 0.01: return
	var top := PackedVector2Array()
	var n := 12
	for i in range(n + 1):
		var u := float(i) / float(n)
		var y := -h * pow(sin(minf(u, 0.97) * PI * 0.92), 0.75) * (1.0 + 0.25 * u)
		top.append(base + Vector2(-w + 2.0 * w * u, y))
	top.append(base + Vector2(w * 1.18, -h * 0.5))   # mép sóng cuộn
	top.append(base + Vector2(w * 0.9, -h * 0.28))
	var poly := PackedVector2Array(top)
	poly.append(base + Vector2(w * 0.7, 0))
	poly.append(base + Vector2(-w, 0))
	E.P(s, poly, E.A(s, al * 0.7))
	var lit := PackedVector2Array()
	for i in range(n + 1):
		lit.append(top[i] + Vector2(0, h * 0.06))
	E.PG(s, PackedVector2Array([top[2], top[6], base + Vector2(w * 0.2, 0), base + Vector2(-w * 0.8, 0)]), PackedColorArray([E.K(s, al * 0.6), E.K(s, al * 0.6), E.K(s, 0.0), E.K(s, 0.0)]))
	E.PL(s, top, E.K(s, al), 1.8)
	for i in range(4):
		var ix := base.x + (-w * 0.5 + w * 0.35 * float(i))
		var iy := base.y
		E.P(s, PackedVector2Array([Vector2(ix - 3, iy), Vector2(ix, iy + 10.0 + 4.0 * float(i % 2)), Vector2(ix + 3, iy)]), E.K(s, al * 0.8))

static func _frozensea(s, t: float, lowq: bool) -> void:
	_pal(s, "ice")
	var R := 330.0
	var spread := E.eo(E.sg(t, 0.0, 0.32))
	var fa := E.fadeo(t, 0.74)
	var gc := Vector2(0, GY - 4.0)
	# mặt biển băng + nứt
	_gfill(s, gc, R * spread, E.A(s, 0.14 * fa))
	_gfill(s, gc, R * spread * 0.7, E.K(s, 0.06 * fa))
	E.ering(s, gc, R * spread, R * spread * FR, E.A(s, 0.9 * fa), 2.6)
	E.ering(s, gc, R * spread * 0.82, R * spread * 0.82 * FR, E.K(s, 0.45 * fa), 1.2)
	E.crack(s, gc, R * 0.95 * spread, 0.8 * fa, 7)
	_rune(s, gc + Vector2(0, 2), R * 0.5 * spread, t * 0.3, "ice", 0.8 * fa)
	# núi băng xa + sóng bị đóng băng
	for pass_i in range(2):
		for i in range(11):
			var a := TAU * float(i) / 11.0 + 0.35
			if (pass_i == 1) != (sin(a) >= 0.0): continue
			var ta := 0.14 + 0.3 * E.rnd(i, 1)
			var u := E.eo(E.sg(t, ta, ta + 0.28))
			if u <= 0.0: continue
			var rr := R * (0.55 + 0.4 * E.rnd(i, 2))
			var p := _ep(gc, rr * spread, a)
			var persp := 1.0 + 0.3 * sin(a)
			if i % 3 == 0:
				_crystal(s, p, (95.0 + 55.0 * E.rnd(i, 3)) * u * persp, 15.0 * persp, fa, (E.rnd(i, 4) - 0.5) * 0.2)
				_crystal(s, p + Vector2(14.0 * persp, 3.0), (50.0 + 24.0 * E.rnd(i, 5)) * u * persp, 9.0 * persp, fa * 0.9, 0.12)
			else:
				_wavefrozen(s, p, (46.0 + 34.0 * E.rnd(i, 6)) * u * persp, (34.0 + 12.0 * E.rnd(i, 7)) * persp, fa)
	# bông tuyết khổng lồ trên bầu trời
	var sf := E.eo(E.sg(t, 0.1, 0.45))
	_snowflake(s, Vector2(0, -120.0), 30.0 * sf, t * 0.8, fa * 0.9)
	var w := E.eo(E.sg(t, 0.4, 0.8))
	if w > 0.0:
		E.shock(s, gc, R * w, R * w * FR, (1.0 - E.sg(t, 0.55, 0.95)) * 0.9)
	for i in range(0 if lowq else 26):
		var fall := fmod(t * 1.1 + E.rnd(i, 11), 1.0)
		var sp := Vector2((E.rnd(i, 12) - 0.5) * R * 1.9 + sin(fall * 8.0 + float(i)) * 8.0, -190.0 + fall * 230.0)
		E.CI(s, sp, 1.4 + 1.2 * E.rnd(i, 13), E.K(s, fa * 0.9 * spread))
	E.glow(s, Vector2(0, -20), 150.0 * spread, 0.1 * fa)

# ============================================================ KHIÊN
## ps35 Tinh Thạch Hộ Thể: các mảnh tinh thạch lục giác xoay quanh người, mái vòm khía tinh thể, gợn sóng định kỳ.
static func _shard_gem(s, p: Vector2, h: float, al: float, tilt: float) -> void:
	var w := h * 0.42
	var pts := PackedVector2Array([p + Vector2(0, -h), p + Vector2(w, -h * 0.2), p + Vector2(w * 0.7, h * 0.55), p + Vector2(0, h), p + Vector2(-w * 0.7, h * 0.55), p + Vector2(-w, -h * 0.2)])
	pts = _rot(pts, p, tilt)
	E.glow(s, p, h * 1.6, al * 0.4)
	E.P(s, pts, E.A(s, al * 0.85))
	E.P(s, PackedVector2Array([pts[0], pts[1], pts[2], pts[3]]), E.K(s, al * 0.55))
	E.L(s, pts[0], pts[3], E.K(s, al * 0.8), 1.0)
	E.L(s, pts[1], pts[5], E.K(s, al * 0.6), 1.0)
	var o := pts.duplicate()
	o.append(pts[0])
	E.PL(s, o, E.K(s, al), 1.3)

static func _rot(pts: PackedVector2Array, c: Vector2, a: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	var cs := cos(a)
	var sn := sin(a)
	for p in pts:
		var d := p - c
		out.append(c + Vector2(d.x * cs - d.y * sn, d.x * sn + d.y * cs))
	return out

static func _crystalguard(s, t: float, lowq: bool) -> void:
	_pal(s, "mana")
	var up := E.eo(E.sg(t, 0.0, 0.25))
	var fa := E.fo(s, t, 0.75)
	var al := up * fa
	var c := Vector2(0, -12.0)
	# vòm tinh thể khía (đỉnh + 6 kinh tuyến)
	var rx := 46.0 * up
	var ry := 58.0 * up
	E.ering(s, c, rx, ry, E.A(s, 0.28 * al), 5.0)
	E.ering(s, c, rx, ry, E.A(s, 0.8 * al), 1.6)
	var top := c + Vector2(0, -ry)
	for k in range(6):
		var a := TAU * float(k) / 6.0 + t * 0.4
		var eq := c + Vector2(cos(a) * rx, sin(a) * 9.0 + ry * 0.2)
		E.L(s, top, eq, E.A(s, 0.22 * al), 1.0)
		var nx := c + Vector2(cos(a + TAU / 6.0) * rx, sin(a + TAU / 6.0) * 9.0 + ry * 0.2)
		E.L(s, eq, nx, E.K(s, 0.4 * al), 1.0)
	# gợn sóng định kỳ (mỗi 2.4s) khi đỡ đòn
	var rp := fmod(t, 2.4) / 2.4
	if t > 1.0 or s.steady:
		var rw := E.eo(rp)
		E.ering(s, c, rx * (1.0 + 0.3 * rw), ry * (1.0 + 0.3 * rw), E.K(s, 0.7 * al * (1.0 - rp)), 2.0)
	# 6 mảnh tinh thạch xoay quanh (sau -> trước)
	var ang := t * 1.9
	for pass_i in range(2):
		for k in range(6):
			var a2 := ang + TAU * float(k) / 6.0
			if (pass_i == 1) != (sin(a2) >= 0.0): continue
			var sz := 11.0 + 3.0 * sin(a2)
			var p := c + Vector2(cos(a2) * 40.0 * up, sin(a2) * 12.0 - 4.0 + sin(t * 3.0 + float(k)) * 3.0)
			_shard_gem(s, p, sz, al * (0.55 if pass_i == 0 else 1.0), 0.15 * cos(a2))
	# mọc tinh thể dưới chân lúc tung chiêu
	var sp := 1.0 - E.sg(t, 0.35, 0.7)
	if t < 0.7 and not s.steady:
		for k in range(6):
			var a3 := TAU * float(k) / 6.0 + 0.3
			_crystal(s, _ep(Vector2(0, GY - 3.0), 34.0, a3), 26.0 * E.eo(E.sg(t, 0.0, 0.2)) * sp, 5.0, fa * sp, (E.rnd(k, 1) - 0.5) * 0.3)

## tn4 Khiên Năng Lượng: bong bóng năng lượng xanh có lưới lục giác, gợn sóng khi đỡ đòn.
static func _energyshield(s, t: float, lowq: bool) -> void:
	_pal(s, "mana")
	var up := E.eo(E.sg(t, 0.0, 0.25))
	var fa := E.fo(s, t, 0.75)
	var al := up * fa
	var c := Vector2(0, -10.0)
	var rx := 38.0 * up
	var ry := 54.0 * up
	# thân bong bóng: các lớp elip mờ + viền sáng
	for i in range(5):
		var k := 1.0 - float(i) * 0.1
		s.draw_set_transform(c, 0.0, Vector2(rx * k / ry, 1.0))
		s.draw_circle(Vector2.ZERO, ry * k, E.A(s, 0.045 * al), true, -1.0, true)
		E.rst(s)
	E.ering(s, c, rx, ry, E.A(s, 0.3 * al), 6.0)
	E.ering(s, c, rx, ry, E.A(s, 0.85 * al), 1.8)
	E.ering(s, c, rx * 0.97, ry * 0.97, E.K(s, 0.55 * al), 1.0)
	# lưới lục giác bên trong (chỉ ô nằm trong bong bóng)
	var hr := 11.0
	for gy in range(-5, 6):
		for gx in range(-4, 5):
			var px := float(gx) * hr * 1.73 + (hr * 0.865 if gy % 2 != 0 else 0.0)
			var py := float(gy) * hr * 1.5
			var q := Vector2(px / (rx * 0.92), py / (ry * 0.92))
			if q.length() > 1.0: continue
			var pulse := 0.5 + 0.5 * sin(t * 2.4 - q.length() * 4.0 + float(gx))
			var hx := PackedVector2Array()
			for k2 in range(7):
				var a := TAU * float(k2) / 6.0 + PI / 6.0
				hx.append(c + Vector2(px + cos(a) * hr * 0.55, py + sin(a) * hr * 0.55))
			E.PL(s, hx, E.A(s, (0.16 + 0.3 * pulse) * al), 1.0)
	# gợn sóng định kỳ + chớp sáng ở mép trước
	var rp := fmod(t, 1.7) / 1.7
	var rw := E.eo(rp)
	E.ering(s, c, rx * (1.0 + 0.35 * rw), ry * (1.0 + 0.35 * rw), E.K(s, 0.8 * al * (1.0 - rp)), 2.4)
	E.ering(s, c, rx * (1.0 + 0.18 * rw), ry * (1.0 + 0.18 * rw), E.A(s, 0.5 * al * (1.0 - rp)), 5.0)
	var hl := Vector2(rx * 0.7, -ry * 0.5)
	E.flare(s, c + hl, 4.0 + 1.6 * sin(t * 5.0), 0.8 * al)
	for i in range(0 if lowq else 5):
		var a2 := TAU * E.rnd(i, 3) + t * 0.6
		E.CI(s, c + Vector2(cos(a2) * rx, sin(a2) * ry), 1.5, E.K(s, al * (0.5 + 0.5 * sin(t * 4.0 + float(i)))))

# ============================================================ LÔI CẦU XOÁY
## ps37: 2 quả cầu sét lần lượt rơi (170px, +110px mỗi quả; trễ 0.6s + 0.42s), nổ lan bán kính 260 bằng tia sét bò trên đất.
static func _lightball(s, t: float, lowq: bool) -> void:
	_pal(s, "bolt")
	var sec := _sec(t, 3.4)
	var R := 260.0
	var fa := 1.0
	# trận rune sét dưới chân người niệm chú
	var ra := E.eo(E.sg(sec, 0.0, 0.3)) * (1.0 - E.sg(sec, 0.9, 1.5))
	_rune(s, Vector2(0, GY - 4.0), 64.0 * ra, sec * 1.5, "bolt", ra)
	for i in range(2):
		var x := 170.0 + 110.0 * float(i)
		var L := 0.6 + 0.42 * float(i)
		var gp := Vector2(x, GY - 2.0)
		# vùng nổ báo trước
		var wa := E.eo(E.sg(sec, L - 0.55, L - 0.3)) * (1.0 - E.sg(sec, L + 0.2, L + 0.9))
		if wa > 0.0:
			E.ering(s, gp, R, R * FR, E.A(s, 0.28 * wa), 1.6)
			_gfill(s, gp, R, E.A(s, 0.035 * wa))
		var p := (sec - (L - 0.45)) / 0.45
		if p > 0.0 and p < 1.0:
			var fp := _fallpos(x, p)
			_comet(s, fp[0], fp[1], 15.0, "bolt", sec)
		if p >= 1.0:
			var age := sec - L
			var e := E.eo(E.sg(age, 0.0, 0.45))
			var fb := 1.0 - E.sg(age, 0.45, 1.2)
			if fb <= 0.0: continue
			E.glow(s, gp + Vector2(0, -20), 130.0 * (1.0 - E.sg(age, 0.0, 0.35)), 0.8)
			# cột sét trút xuống
			var pc := 1.0 - E.sg(age, 0.0, 0.22)
			if pc > 0.0:
				_bolt(s, Vector2(x - 10.0, -340.0), gp, 3 + int(age * 30.0), pc, 3.0, 22.0, true)
			E.shock(s, gp, R * 0.9 * e, R * 0.9 * e * FR, fb)
			# tia sét bò lan ra các điểm trong vùng
			for k in range(7):
				var q := _ep(gp, R * (0.5 + 0.45 * E.rnd(k, i + 1)), TAU * (float(k) / 7.0) + 0.3 * float(i))
				var ta := 0.06 + 0.045 * float(k)
				var g := E.sg(age, ta, ta + 0.16)
				if g <= 0.0: continue
				var tip := gp.lerp(q, g)
				_bolt(s, gp + Vector2(0, -2), tip, k + i * 10 + int(age * 16.0), fb * (1.0 - 0.5 * E.sg(age, 0.5, 1.2)), 1.5, 9.0, false)
				if g >= 1.0:
					var bb := 1.0 - E.sg(age, ta + 0.16, ta + 0.6)
					E.flare(s, q, 9.0 * bb + 2.0, fb * bb)
					_bolt(s, q + Vector2(0, -60.0 * bb), q, k + 40, fb * bb, 1.4, 6.0, false)
			E.spark(s, gp + Vector2(0, -16), 0 if lowq else 14, 130.0, age * 1.5, fb, i + 3)

# ============================================================ HỒI NGUYÊN (NĂNG LƯỢNG)
## ps38: viên ngọc mana trên đầu toả dòng hạt xanh dương chảy vào người (hồi năng lượng lớn), vài hạt xanh lục (chút máu).
static func _manarestore(s, t: float, lowq: bool) -> void:
	_pal(s, "mana")
	var fa := E.fadeo(t, 0.74)
	var gc := Vector2(0, GY - 4.0)
	var body := Vector2(0, -14.0)
	var up := E.eo(E.sg(t, 0.0, 0.2))
	_gfill(s, gc, 70.0 * up, E.A(s, 0.12 * fa))
	_rune(s, gc, 70.0 * up, -t * 0.9, "mana", fa)
	# cột sáng mảnh từ viên ngọc xuống người
	var gem := Vector2(0, -92.0 - 5.0 * sin(t * 6.0))
	E.beam(s, 0.0, gem.y, 20.0, 5.0, 18.0, up * fa)
	var rot := t * 1.6
	# ngọc: kim cương mana xoay (thu hẹp bề ngang theo cos)
	var gw := 14.0 * absf(cos(rot)) + 3.0
	var gh := 20.0
	var gpts := PackedVector2Array([gem + Vector2(0, -gh), gem + Vector2(gw, 0), gem + Vector2(0, gh), gem + Vector2(-gw, 0)])
	E.glow(s, gem, 34.0 * up, 0.55 * fa)
	E.P(s, gpts, E.A(s, 0.9 * fa * up))
	E.P(s, PackedVector2Array([gpts[0], gpts[1], gem + Vector2(0, 2)]), E.K(s, 0.7 * fa * up))
	E.PL(s, PackedVector2Array([gpts[0], gpts[1], gpts[2], gpts[3], gpts[0]]), E.K(s, fa * up), 1.5)
	# hạt chảy vào ngực theo đường cong: từ trời/từ đất xoáy vào
	var nn := 14 if lowq else 30
	for i in range(nn):
		var ph := E.rnd(i, 1)
		var ts := 0.1 + 0.5 * ph
		var u := E.sg(t, ts, ts + 0.32)
		if u <= 0.0 or u >= 1.0: continue
		var green := (i % 7) == 3
		if green: _pal(s, "heal")
		else: _pal(s, "mana")
		var a0 := TAU * E.rnd(i, 2)
		var r0 := 120.0 + 70.0 * E.rnd(i, 3)
		var from := body + Vector2(cos(a0) * r0, sin(a0) * r0 * 0.5 - 30.0)
		if i % 3 == 0: from = gem + Vector2((E.rnd(i, 4) - 0.5) * 20.0, 0)
		var path := PackedVector2Array()
		for k in range(8):
			var uu := E.ei(clampf(u - float(k) * 0.04, 0.0, 1.0))
			var sw := sin(uu * PI) * 22.0 * (E.rnd(i, 5) - 0.5)
			path.append(from.lerp(body, uu) + Vector2(sw, -sw * 0.4))
		E.PL(s, path, E.A(s, 0.45 * fa), 3.0)
		E.PL(s, path, E.K(s, 0.7 * fa), 1.2)
		E.CI(s, path[0], 3.0 if not green else 3.6, E.K(s, fa))
		E.glow(s, path[0], 7.0, 0.35 * fa)
	_pal(s, "mana")
	# nạp đầy: vòng xung + lóe sáng ở ngực
	var pu := E.sg(t, 0.62, 0.9)
	if pu > 0.0:
		var e := E.eo(pu)
		E.ering(s, body, 22.0 + 46.0 * e, 28.0 + 56.0 * e, E.K(s, (1.0 - pu) * fa), 2.4)
		E.ering(s, body, 14.0 + 30.0 * e, 18.0 + 38.0 * e, E.A(s, (1.0 - pu) * fa), 4.0)
		E.star(s, body, 22.0 * (1.0 - pu) + 6.0, (1.0 - pu) * fa, 6)
	E.glow(s, body, 24.0 * E.sg(t, 0.2, 0.7), 0.4 * fa)
	for i in range(0 if lowq else 8):
		var rs := fmod(t * 0.9 + E.rnd(i, 6), 1.0)
		E.CI(s, Vector2(cos(float(i) * 0.8) * 16.0, GY - rs * 90.0), 1.8 * (1.0 - rs) + 0.6, E.K(s, fa * (1.0 - rs) * up))

# ============================================================ HỒI PHỤC
## tn2: trăng lưỡi liềm xanh lục toả ánh dịu xuống, thập tự hồi phục nở trước ngực, lá nhỏ và dấu cộng bay lên.
static func _plus(s, p: Vector2, sz: float, al: float) -> void:
	if sz < 2.0 or al <= 0.01: return
	var th := sz * 0.34
	E.P(s, PackedVector2Array([p + Vector2(-th, -sz), p + Vector2(th, -sz), p + Vector2(th, -th), p + Vector2(sz, -th), p + Vector2(sz, th), p + Vector2(th, th),
		p + Vector2(th, sz), p + Vector2(-th, sz), p + Vector2(-th, th), p + Vector2(-sz, th), p + Vector2(-sz, -th), p + Vector2(-th, -th)]), E.A(s, al * 0.9))
	E.L(s, p + Vector2(0, -sz * 0.7), p + Vector2(0, sz * 0.7), E.K(s, al), maxf(1.0, th * 0.7))
	E.L(s, p + Vector2(-sz * 0.7, 0), p + Vector2(sz * 0.7, 0), E.K(s, al), maxf(1.0, th * 0.7))

static func _moonheal(s, t: float, lowq: bool) -> void:
	_pal(s, "heal")
	var fa := E.fadeo(t, 0.72)
	var up := E.eo(E.sg(t, 0.0, 0.3))
	var gc := Vector2(0, GY - 4.0)
	var body := Vector2(0, -16.0)
	_gfill(s, gc, 58.0 * up, E.A(s, 0.1 * fa))
	E.ering(s, gc, 58.0 * up, 58.0 * up * FR, E.A(s, 0.9 * fa), 2.0)
	E.ering(s, gc, 44.0 * up, 44.0 * up * FR, E.K(s, 0.6 * fa), 1.2)
	# trăng lưỡi liềm trên đầu: hai đường cung lệch tâm
	var mc := Vector2(0, -86.0)
	var mr := 22.0 * up
	if mr > 3.0:
		E.glow(s, mc, mr * 2.2, 0.35 * fa)
		var out := PackedVector2Array()
		var inn := PackedVector2Array()
		for i in range(17):
			var a := lerpf(-PI * 0.78, PI * 0.78, float(i) / 16.0) + PI
			var o := mc + Vector2(cos(a), sin(a)) * mr
			out.append(o)
			var w := sin(float(i) / 16.0 * PI)
			inn.append(o.lerp(mc + Vector2(mr * 0.42, 0) + Vector2(cos(a), sin(a)) * mr * 0.55, w))
		for i in range(16):
			E.P(s, PackedVector2Array([out[i], out[i + 1], inn[i + 1], inn[i]]), E.K(s, 0.92 * fa))
		E.PL(s, out, E.A(s, fa), 1.8)
		E.PL(s, inn, E.A(s, 0.6 * fa), 1.2)
	# ánh trăng rọi xuống
	E.beam(s, 0.0, -80.0, 30.0, 6.0, 26.0, up * fa * 0.9)
	# thập tự nở ra rồi bay lên
	var cp := E.eo(E.sg(t, 0.15, 0.5))
	var cy := -16.0 - 20.0 * E.sg(t, 0.5, 1.0)
	_plus(s, Vector2(0, cy), 20.0 * cp, fa)
	E.ering(s, Vector2(0, cy), 14.0 + 34.0 * cp, 14.0 + 34.0 * cp, E.A(s, 0.7 * fa * (1.0 - E.sg(t, 0.5, 0.9))), 2.0)
	for i in range(0 if lowq else 12):
		var ph := E.rnd(i, 1)
		var u := fmod(t * 0.9 + ph, 1.0)
		var p := Vector2((E.rnd(i, 2) - 0.5) * 70.0 + sin(u * 7.0 + float(i)) * 6.0, GY - 6.0 - u * 110.0)
		if i % 2 == 0:
			_plus(s, p, 4.5 * (1.0 - u * 0.5), fa * (1.0 - u) * up)
		else:
			# lá nhỏ
			E.P(s, PackedVector2Array([p + Vector2(0, -5), p + Vector2(3.5, 0), p + Vector2(0, 5), p + Vector2(-3.5, 0)]), E.A(s, 0.85 * fa * (1.0 - u)))
			E.L(s, p + Vector2(0, -4), p + Vector2(0, 4), E.K(s, 0.8 * fa * (1.0 - u)), 1.0)
	E.glow(s, body, 36.0 * up, 0.25 * fa)

# ============================================================ BÃO NGUYÊN TỐ
## ps40: ba nguyên tố (lửa, băng, sét) quay trên đầu rồi lần lượt giáng xuống 3 đợt (170px, +110px; trễ 0.6s + 0.42s), vùng nổ r=250.
static func _elemstorm(s, t: float, lowq: bool) -> void:
	var sec := _sec(t, 4.0)
	var R := 250.0
	var els := ["fire", "ice", "bolt"]
	var gc := Vector2(0, GY - 4.0)
	var ra := E.eo(E.sg(sec, 0.0, 0.3)) * (1.0 - E.sg(sec, 1.5, 2.2))
	_pal(s, "arcane")
	_rune(s, gc, 74.0 * ra, sec * 0.8, "elem", ra)
	# ba quả cầu nguyên tố quay trên đầu, lần lượt bay lên trời khi đến đợt của mình
	for i in range(3):
		var L := 0.6 + 0.42 * float(i)
		var leave := E.sg(sec, L - 0.95, L - 0.5)
		if leave >= 1.0: continue
		var a := sec * 3.2 + TAU * float(i) / 3.0
		var pos := Vector2(cos(a) * 30.0, -78.0 + sin(a) * 9.0)
		pos += Vector2(0, -260.0 * E.ei(leave))
		_pal(s, els[i])
		_orb(s, pos, 7.5 * (1.0 - 0.3 * leave), ra * (1.0 - leave * 0.6))
		if leave > 0.0:
			E.L(s, pos, pos + Vector2(0, 40.0), E.A(s, 0.5 * (1.0 - leave)), 3.0)
	for i in range(3):
		var el: String = els[i]
		var x := 170.0 + 110.0 * float(i)
		var L2 := 0.6 + 0.42 * float(i)
		var gp := Vector2(x, GY - 2.0)
		_pal(s, el)
		var wa := E.eo(E.sg(sec, L2 - 0.5, L2 - 0.25)) * (1.0 - E.sg(sec, L2 + 0.1, L2 + 0.7))
		if wa > 0.0:
			E.ering(s, gp, R, R * FR, E.A(s, 0.26 * wa), 1.6)
		var p := (sec - (L2 - 0.45)) / 0.45
		if p > 0.0 and p < 1.0:
			var fp := _fallpos(x, p)
			_comet(s, fp[0], fp[1], 14.0, el, sec)
		if p >= 1.0:
			_ehit(s, el, gp, R, sec - L2, lowq, i * 7)

# ============================================================ THIÊN ĐỊA HỢP NHẤT PHÁP
## ps45: bát quái dưới chân, 5 đợt nguyên tố (lửa, băng, sét, thổ, phép) giáng xuống kèm cột sáng trời – gai đất (170px + 110px/đợt), r=280.
static func _heavenearth(s, t: float, lowq: bool) -> void:
	var sec := _sec(t, 5.2)
	var R := 280.0
	var els := ["fire", "ice", "bolt", "earth", "arcane"]
	var gc := Vector2(0, GY - 4.0)
	var ra := E.eo(E.sg(sec, 0.0, 0.35)) * (1.0 - E.sg(sec, 2.2, 3.2))
	_pal(s, "holy")
	_rune(s, gc, 86.0 * ra, sec * 0.5, "bagua", ra)
	# thái cực xoay giữa trận
	E.ering(s, gc, 14.0 * ra, 14.0 * ra * FR, E.K(s, 0.9 * ra), 1.6)
	# hai luồng sáng trời – đất đối nhau trên người
	E.beam(s, 0.0, -300.0, GY, 10.0, 22.0, 0.55 * ra)
	for i in range(5):
		var el: String = els[i]
		var x := 170.0 + 110.0 * float(i)
		var L := 0.6 + 0.42 * float(i)
		var gp := Vector2(x, GY - 2.0)
		_pal(s, el)
		var wa := E.eo(E.sg(sec, L - 0.5, L - 0.25)) * (1.0 - E.sg(sec, L + 0.1, L + 0.7))
		if wa > 0.0:
			E.ering(s, gp, R, R * FR, E.A(s, 0.22 * wa), 1.6)
		var p := (sec - (L - 0.45)) / 0.45
		if p > 0.0 and p < 1.0:
			# cột sáng trời báo trước vị trí rơi
			E.beam(s, gp.x, -330.0, gp.y, 5.0, 14.0, 0.5 * E.sg(p, 0.0, 0.5))
			var fp := _fallpos(x, p)
			_comet(s, fp[0], fp[1], 14.0, el, sec)
		if p >= 1.0:
			var age := sec - L
			_ehit(s, el, gp, R, age, lowq, i * 5 + 1)
			# gai đất trồi lên đối ứng với cột sáng trời
			if el != "earth":
				_pal(s, "earth")
				for k in range(5):
					var q := gp + Vector2((float(k) - 2.0) * 30.0, 4.0 * float(k % 2))
					var hh := (44.0 + 20.0 * E.rnd(k, i)) * E.eo(E.sg(age, 0.08, 0.3)) * (1.0 - E.sg(age, 0.6, 1.4))
					if hh > 8.0:
						E.P(s, PackedVector2Array([q + Vector2(-6, 0), q + Vector2(0, -hh), q + Vector2(6, 0)]), Color(0.42, 0.3, 0.2, 0.85))
						E.L(s, q + Vector2(0, -hh), q + Vector2(-6, 0), E.K(s, 0.7), 1.0)

# ============================================================ DỊCH CHUYỂN (PHÁP SƯ)
## ps42: cổng phép mở ở chỗ cũ, người tan vào cổng, vệt phép lùi 260px, cổng thứ hai mở và người hiện ra; 4 ấn phép nhỏ bật loé (mỗi loé = một loạt đạn).
static func _gate(s, c: Vector2, h: float, w: float, rot: float, al: float) -> void:
	if h < 4.0 or w < 1.0 or al <= 0.01: return
	E.glow(s, c, h * 0.9, al * 0.4)
	E.ering(s, c, w, h, E.A(s, al * 0.3), 7.0)
	E.ering(s, c, w, h, E.A(s, al * 0.95), 2.2)
	E.ering(s, c, w * 0.8, h * 0.8, E.K(s, al * 0.7), 1.2)
	for i in range(12):
		var a := rot + TAU * float(i) / 12.0
		var p0 := c + Vector2(cos(a) * w * 0.8, sin(a) * h * 0.8)
		var p1 := c + Vector2(cos(a) * w * 0.94, sin(a) * h * 0.94)
		E.L(s, p0, p1, E.K(s, al * 0.8), 1.4)
	for k in range(5):
		var a2 := rot * 1.5 + TAU * float(k) / 5.0
		var b2 := rot * 1.5 + TAU * float((k + 2) % 5) / 5.0
		E.L(s, c + Vector2(cos(a2) * w * 0.6, sin(a2) * h * 0.6), c + Vector2(cos(b2) * w * 0.6, sin(b2) * h * 0.6), E.A(s, al * 0.8), 1.4)

static func _teleport(s, t: float, lowq: bool) -> void:
	_pal(s, "arcane")
	var D := 260.0
	var fa := E.fadeo(t, 0.74)
	var c0 := Vector2(0, -12.0)
	var c1 := Vector2(-D, -12.0)
	# cổng ở chỗ cũ: mở rồi co lại
	var o0 := E.eo(E.sg(t, 0.0, 0.18)) * (1.0 - E.eo(E.sg(t, 0.4, 0.62)))
	_gate(s, c0, 48.0 * o0, 14.0 * o0 + 2.0, t * 4.0, o0 * fa)
	E.ering(s, Vector2(0, GY - 3.0), 40.0 * o0, 40.0 * o0 * FR, E.A(s, 0.8 * o0), 2.0)
	# vệt phép dọc đường lùi: hai dải xoắn + tàn ảnh mờ
	var tr := E.eo(E.sg(t, 0.2, 0.55))
	if tr > 0.0:
		for k in range(2):
			var pts := PackedVector2Array()
			for i in range(24):
				var u := float(i) / 23.0 * tr
				pts.append(Vector2(-D * u, -12.0 + sin(u * 18.0 + float(k) * PI + t * 12.0) * 14.0 * (1.0 - u * 0.5)))
			E.PL(s, pts, E.A(s, 0.28 * fa), 8.0)
			E.PL(s, pts, E.K(s, 0.8 * fa), 1.3)
		for k in range(1, 5):
			var u2 := maxf(0.0, tr - 0.14 * float(k))
			E.man(s, Vector2(-D * u2, -4.0), 0.32 * (1.0 - 0.2 * float(k)) * fa * (1.0 - E.sg(t, 0.55, 0.75)))
		for i in range(0 if lowq else 14):
			var u3 := E.rnd(i, 1) * tr
			E.star(s, Vector2(-D * u3, -12.0 + (E.rnd(i, 2) - 0.5) * 36.0), 3.0, fa * (1.0 - u3 * 0.3), 4)
	# cổng đích: mở, người hiện ra, rồi khép
	var o1 := E.eo(E.sg(t, 0.38, 0.55)) * (1.0 - E.eo(E.sg(t, 0.7, 0.9)))
	_gate(s, c1, 48.0 * o1, 14.0 * o1 + 2.0, -t * 4.0, o1 * fa)
	var ar := E.sg(t, 0.52, 0.8)
	if ar > 0.0 and ar < 1.0:
		E.ering(s, c1, 14.0 + 50.0 * E.eo(ar), 20.0 + 70.0 * E.eo(ar), E.K(s, (1.0 - ar) * fa), 2.4)
		E.star(s, c1, 26.0 * (1.0 - ar), (1.0 - ar) * fa, 6)
		E.spark(s, c1, 0 if lowq else 10, 60.0, ar, (1.0 - ar) * fa, 2)
	# 4 ấn phép nhỏ ở phía trước, mỗi lần loé là một loạt đạn bắn ra
	for k in range(4):
		var tk := 0.1 + 0.11 * float(k)
		var q := E.sg(t, tk, tk + 0.22)
		if q > 0.0 and q < 1.0:
			var pc := Vector2(30.0 + 6.0 * float(k % 2), -26.0 + 12.0 * float(k % 3))
			E.ering(s, pc, 5.0 + 9.0 * q, 11.0 + 7.0 * q, E.A(s, 0.9 * (1.0 - q)), 2.0, 0.0)
			E.flare(s, pc, 8.0 * (1.0 - q) + 2.0, 1.0 - q)

## tn10: cả người tan thành ba luồng nguyên tố (lửa, băng, sét) lướt lùi 220px rồi tụ lại; ba loé nòng nguyên tố phía trước.
static func _elemblink(s, t: float, lowq: bool) -> void:
	var D := 220.0
	var fa := E.fadeo(t, 0.74)
	var els := ["fire", "ice", "bolt"]
	var g := E.eo(E.sg(t, 0.12, 0.6))
	var gc := Vector2(0, GY - 3.0)
	_pal(s, "arcane")
	var o0 := E.eo(E.sg(t, 0.0, 0.2)) * (1.0 - E.sg(t, 0.35, 0.6))
	_rune(s, gc, 52.0 * o0, t * 3.0, "elem", o0 * fa)
	var o1 := E.eo(E.sg(t, 0.5, 0.7)) * (1.0 - E.sg(t, 0.75, 1.0))
	_rune(s, Vector2(-D, GY - 3.0), 52.0 * o1, -t * 3.0, "elem", o1 * fa)
	for k in range(3):
		_pal(s, els[k])
		var ph := TAU * float(k) / 3.0
		# dải xoắn nguyên tố từ chỗ cũ tới chỗ mới
		var pts := PackedVector2Array()
		for i in range(26):
			var u := float(i) / 25.0 * g
			pts.append(Vector2(-D * u, -12.0 + sin(u * 14.0 + ph + t * 10.0) * 16.0 * sin(minf(u * 1.0, 1.0) * PI)))
		E.PL(s, pts, E.A(s, 0.3 * fa), 8.0)
		E.PL(s, pts, E.A(s, 0.85 * fa), 3.0)
		E.PL(s, pts, E.K(s, 0.9 * fa), 1.2)
		if g > 0.0:
			var hd: Vector2 = pts[pts.size() - 1]
			_orb(s, hd, 7.0, fa * (1.0 - E.sg(t, 0.6, 0.8)))
		# bùng nguyên tố ở nơi đến
		var ar := E.sg(t, 0.55, 1.0)
		if ar > 0.0:
			var q := Vector2(-D + (float(k) - 1.0) * 14.0, -12.0)
			var e := E.eo(ar)
			match k:
				0: E.flame(s, q + Vector2(0, 28), 52.0 * e * (1.0 - ar * 0.6), 11.0, t * 3.0, float(k), fa)
				1:
					_crystal(s, q + Vector2(0, 30), 46.0 * e, 7.0, fa * (1.0 - ar * 0.5), 0.0)
				2: _bolt(s, q + Vector2(0, -60.0 * (1.0 - ar)), q + Vector2(0, 30), k + int(t * 20.0), fa * (1.0 - ar), 1.6, 8.0, false)
			E.ering(s, Vector2(-D, -12.0), 10.0 + 44.0 * e, 14.0 + 60.0 * e, E.A(s, (1.0 - ar) * fa * 0.7), 2.0)
	# ba loé nòng (lửa, băng, sét) về phía trước
	for k in range(3):
		var tk := 0.1 + 0.15 * float(k)
		var q2 := E.sg(t, tk, tk + 0.24)
		if q2 > 0.0 and q2 < 1.0:
			_pal(s, els[k])
			var pc := Vector2(30.0 + 5.0 * float(k % 2), -24.0 + 14.0 * float(k))
			E.flare(s, pc, 9.0 * (1.0 - q2) + 2.0, 1.0 - q2)
			E.ering(s, pc, 4.0 + 12.0 * q2, 9.0 + 10.0 * q2, E.A(s, 0.8 * (1.0 - q2)), 2.0)

# ============================================================ ĐỊA NGỤC LIỆT HỎA
## tn11: trận rune lửa nhỏ, 3 cầu lửa địa ngục khổng lồ rơi (170px, +110px; trễ 0.6s + 0.42s), nổ thành biển dung nham r=270.
static func _hellfire(s, t: float, lowq: bool) -> void:
	_pal(s, "hell")
	var sec := _sec(t, 4.2)
	var R := 270.0
	var gc := Vector2(0, GY - 4.0)
	var ra := E.eo(E.sg(sec, 0.0, 0.3)) * (1.0 - E.sg(sec, 1.2, 1.9))
	_rune(s, gc, 66.0 * ra, sec * 1.2, "fire", ra)
	var lava_a := 1.0 - E.sg(t, 0.78, 1.0)
	# biển dung nham: các vũng lan ra tại điểm rơi
	for i in range(3):
		var x := 170.0 + 110.0 * float(i)
		var L := 0.6 + 0.42 * float(i)
		var gp := Vector2(x, GY - 2.0)
		var age := sec - L
		if age > 0.0:
			var sp := E.eo(E.sg(age, 0.0, 0.7))
			_gfill(s, gp, R * sp * 0.92, Color(0.9, 0.2, 0.05, 0.16 * lava_a))
			_gfill(s, gp, R * sp * 0.62, Color(1.0, 0.45, 0.1, 0.2 * lava_a))
			E.ering(s, gp, R * sp * 0.92, R * sp * 0.92 * FR, E.A(s, 0.8 * lava_a), 2.2)
			E.ering(s, gp, R * sp * 0.6, R * sp * 0.6 * FR, E.K(s, 0.55 * lava_a), 1.3)
	for i in range(3):
		var x2 := 170.0 + 110.0 * float(i)
		var L2 := 0.6 + 0.42 * float(i)
		var gp2 := Vector2(x2, GY - 2.0)
		var wa := E.eo(E.sg(sec, L2 - 0.55, L2 - 0.3)) * (1.0 - E.sg(sec, L2, L2 + 0.2))
		if wa > 0.0:
			E.ering(s, gp2, R, R * FR, E.A(s, 0.3 * wa), 1.6)
		var p := (sec - (L2 - 0.45)) / 0.45
		if p > 0.0 and p < 1.0:
			var fp := _fallpos(x2, p)
			_comet(s, fp[0], fp[1], 24.0, "hell", sec)
		if p >= 1.0:
			var age2 := sec - L2
			var e := E.eo(E.sg(age2, 0.0, 0.35))
			var fb := 1.0 - E.sg(age2, 0.6, 1.5)
			E.glow(s, gp2 + Vector2(0, -24), 160.0 * (1.0 - E.sg(age2, 0.0, 0.3)), 0.9)
			if fb > 0.0:
				E.shock(s, gp2, R * 0.9 * e, R * 0.9 * e * FR, fb)
				E.star(s, gp2 + Vector2(0, -30), 66.0 * (1.0 - age2 * 0.5), fb, 10)
			# cột lửa phun và dung nham bắn
			for k in range(7):
				var q := _ep(gp2, R * 0.8 * e * (0.15 + 0.85 * E.rnd(k, i)), TAU * float(k) / 7.0 + 0.2)
				E.flame(s, q, (70.0 + 60.0 * E.rnd(k, i + 4)) * e, 14.0, sec * 1.8, float(k + i), lava_a * 0.95)
			if not lowq:
				for k in range(10):
					var ph := E.rnd(k, i + 8)
					var u := E.sg(age2, 0.0, 0.9)
					var q2 := gp2 + Vector2((ph - 0.5) * 220.0 * u, -(130.0 * (1.0 - ph * 0.4)) * 4.0 * u * (1.0 - u))
					E.CI(s, q2, 3.0 * (1.0 - u) + 1.0, E.K(s, (1.0 - u)))
	# nền cháy rực
	if sec > 0.7:
		E.glow(s, Vector2(260.0, GY - 20.0), 230.0, 0.1 * lava_a * E.sg(sec, 0.7, 1.4))

# ============================================================ THIÊN THẠCH
## tn5: pháp trận mở trên trời, thiên thạch đá cháy khổng lồ lao xuống (170px, trễ 0.6s), nổ r=200, hố va chạm, đá văng, khói.
static func _meteor(s, t: float, lowq: bool) -> void:
	_pal(s, "fire")
	var sec := _sec(t, 3.0)
	var R := 200.0
	var x := 170.0
	var L := 0.6
	var gp := Vector2(x, GY - 2.0)
	# pháp trận trên trời nơi thiên thạch đi ra
	var sk := E.eo(E.sg(sec, 0.0, 0.3)) * (1.0 - E.sg(sec, 0.5, 0.8))
	var sc := Vector2(x - 150.0, -360.0)
	if sk > 0.0:
		E.ering(s, sc, 70.0 * sk, 26.0 * sk, E.A(s, 0.9 * sk), 2.4)
		E.ering(s, sc, 52.0 * sk, 19.0 * sk, E.K(s, 0.7 * sk), 1.4)
		E.glow(s, sc, 60.0 * sk, 0.4)
	var wa := E.eo(E.sg(sec, 0.15, 0.4)) * (1.0 - E.sg(sec, L, L + 0.2))
	if wa > 0.0:
		E.ering(s, gp, R, R * FR, E.A(s, 0.3 * wa), 1.8)
		E.ering(s, gp, R * 0.5, R * 0.5 * FR, E.A(s, 0.2 * wa), 1.2)
	var p := (sec - (L - 0.45)) / 0.45
	if p > 0.0 and p < 1.0:
		var fp := _fallpos(x, p)
		var pos: Vector2 = fp[0]
		var ang: float = fp[1]
		s.draw_set_transform(pos, ang - PI * 0.5, Vector2.ONE)
		for k in range(7):
			E.flame(s, Vector2((float(k) - 3.0) * 8.0, 10.0 + float(k) * 4.0), 130.0, 20.0, sec, float(k), 0.55)
		s.draw_set_transform(pos, ang, Vector2.ONE)
		_trail(s, 170.0, 26.0, 0.55)
		E.glow(s, Vector2.ZERO, 80.0, 0.7)
		E.rst(s)
		_rock(s, pos, 24.0, sec * 3.0, 5, 1.0)
		E.glow(s, pos, 30.0, 0.5)
	if p >= 1.0:
		var age := sec - L
		var e := E.eo(E.sg(age, 0.0, 0.4))
		var fb := 1.0 - E.sg(age, 0.65, 1.7)
		E.glow(s, gp + Vector2(0, -30), 220.0 * (1.0 - E.sg(age, 0.0, 0.4)), 0.95)
		if fb > 0.0:
			# hố va chạm sẫm + viền nóng
			_gfill(s, gp, R * 0.45 * e, Color(0.1, 0.06, 0.04, 0.6 * fb))
			E.ering(s, gp, R * 0.45 * e, R * 0.45 * e * FR, E.K(s, 0.9 * fb), 2.2)
			E.shock(s, gp, R * e, R * e * FR, fb)
			E.crack(s, gp, R * 0.8 * e, 0.85 * fb, 3)
			# quầng cầu lửa nổ
			E.CI(s, gp + Vector2(0, -50.0 * e), 80.0 * e * (1.0 - age * 0.35), E.A(s, 0.28 * fb))
			E.CI(s, gp + Vector2(0, -50.0 * e), 56.0 * e * (1.0 - age * 0.35), E.M(s, 0.5, 0.35 * fb))
			E.star(s, gp + Vector2(0, -36), 90.0 * (1.0 - age * 0.5), fb, 10)
			for k in range(9):
				var q := _ep(gp, R * 0.7 * e * E.rnd(k, 1), TAU * float(k) / 9.0)
				E.flame(s, q, (60.0 + 50.0 * E.rnd(k, 2)) * e, 13.0, sec * 2.0, float(k), fb)
			E.dust(s, gp, R * 0.7, age, fb * 0.9, 6 if lowq else 12, 3)
		# đá văng theo đường parabol
		for k in range(0 if lowq else 12):
			var ph := E.rnd(k, 5)
			var u := E.sg(age, 0.0, 1.2)
			if u <= 0.0 or u >= 1.0: continue
			var vx := (ph - 0.5) * 2.0 * R * 0.95
			var q2 := gp + Vector2(vx * u, -(90.0 + 110.0 * E.rnd(k, 6)) * 4.0 * u * (1.0 - u))
			_rock(s, q2, 4.0 + 5.0 * E.rnd(k, 7), u * 9.0 + float(k), k, 1.0 - u * 0.6)
			E.glow(s, q2, 8.0, 0.3 * (1.0 - u))

# ============================================================ HỎA TINH BẠO LIỆT
## tn7: 2 thiên thạch lửa nhỏ rơi (170px, +110px; trễ 0.6s + 0.42s), mỗi quả vỡ thành các hỏa tinh bắn ra rồi nổ lan (chain) trong vùng r=250.
static func _emberburst(s, t: float, lowq: bool) -> void:
	_pal(s, "fire")
	var sec := _sec(t, 3.4)
	var R := 250.0
	var gc := Vector2(0, GY - 4.0)
	var ra := E.eo(E.sg(sec, 0.0, 0.3)) * (1.0 - E.sg(sec, 1.0, 1.6))
	_rune(s, gc, 60.0 * ra, -sec * 1.4, "fire", ra)
	for i in range(2):
		var x := 170.0 + 110.0 * float(i)
		var L := 0.6 + 0.42 * float(i)
		var gp := Vector2(x, GY - 2.0)
		var wa := E.eo(E.sg(sec, L - 0.5, L - 0.25)) * (1.0 - E.sg(sec, L + 0.1, L + 0.6))
		if wa > 0.0:
			E.ering(s, gp, R, R * FR, E.A(s, 0.26 * wa), 1.6)
		var p := (sec - (L - 0.45)) / 0.45
		if p > 0.0 and p < 1.0:
			var fp := _fallpos(x, p)
			_comet(s, fp[0], fp[1], 15.0, "fire", sec)
		if p >= 1.0:
			var age := sec - L
			var fb := 1.0 - E.sg(age, 0.9, 1.7)
			E.glow(s, gp + Vector2(0, -18), 110.0 * (1.0 - E.sg(age, 0.0, 0.3)), 0.8)
			var e := E.eo(E.sg(age, 0.0, 0.3))
			E.shock(s, gp, R * 0.35 * e, R * 0.35 * e * FR, fb)
			E.star(s, gp + Vector2(0, -22), 46.0 * (1.0 - age * 0.6), fb, 8)
			# 8 hỏa tinh bắn ra theo cung, rơi chạm đất rồi nổ nhỏ (nổ lan)
			var nn := 5 if lowq else 8
			for k in range(nn):
				var tgt := _ep(gp, R * (0.4 + 0.55 * E.rnd(k, i + 1)), TAU * float(k) / float(nn) + 0.4 * float(i))
				var u := E.sg(age, 0.05, 0.55)
				if u > 0.0 and u < 1.0:
					var q := gp.lerp(tgt, u) + Vector2(0, -(70.0 + 50.0 * E.rnd(k, 2)) * 4.0 * u * (1.0 - u))
					s.draw_set_transform(q, (tgt - gp).angle() * 0.2, Vector2.ONE)
					E.glow(s, Vector2.ZERO, 12.0, 0.5)
					E.CI(s, Vector2.ZERO, 4.5, E.A(s, 0.95))
					E.CI(s, Vector2.ZERO, 2.6, E.K(s, 1.0))
					E.rst(s)
				elif u >= 1.0:
					var ag := age - 0.55
					var ee := E.eo(E.sg(ag, 0.0, 0.3))
					var fe := 1.0 - E.sg(ag, 0.25, 0.9)
					if fe > 0.0:
						E.ering(s, tgt, 8.0 + 34.0 * ee, (8.0 + 34.0 * ee) * 0.45, E.A(s, 0.9 * fe), 2.4)
						E.flame(s, tgt, 46.0 * ee, 9.0, sec * 2.0, float(k), fe)
						E.star(s, tgt + Vector2(0, -12), 16.0 * (1.0 - ag), fe, 6)
						E.spark(s, tgt + Vector2(0, -10), 0 if lowq else 5, 32.0, ag, fe, k + 3)

# ============================================================ LÔI ĐẾ GIÁNG THẾ
## ulPhap1: mây bão đen kéo tới phía trước, 4 đợt sấm sét khổng lồ (170px, +110px; trễ 0.6s + 0.42s) giáng xuống nổ r=170.
static func _thunderlord(s, t: float, lowq: bool) -> void:
	_pal(s, "bolt")
	var sec := _sec(t, 4.8)
	var R := 170.0
	var gc := Vector2(0, GY - 4.0)
	var ra := E.eo(E.sg(sec, 0.0, 0.3)) * (1.0 - E.sg(sec, 1.6, 2.4))
	_rune(s, gc, 70.0 * ra, sec * 1.0, "bolt", ra)
	# vòng hào quang sét trên đầu (vương miện Lôi Đế)
	var cr := ra
	if cr > 0.0:
		E.ering(s, Vector2(0, -66.0), 26.0 * cr, 8.0 * cr, E.A(s, 0.8 * cr), 2.0)
		for k in range(8):
			var a := TAU * float(k) / 8.0 + sec * 2.0
			var px := cos(a) * 26.0 * cr
			var py := -66.0 + sin(a) * 8.0 * cr
			E.L(s, Vector2(px, py), Vector2(px, py - (10.0 + 8.0 * E.rnd(k, int(sec * 12.0))) * cr), E.K(s, cr), 1.8)
	# mây bão phủ vùng phía trước
	var ca := E.eo(E.sg(sec, 0.1, 0.8)) * (1.0 - E.sg(sec, 3.0, 3.8))
	if ca > 0.0:
		for i in range(7):
			var cc := Vector2(190.0 + (float(i) - 3.0) * 84.0, -270.0 + sin(sec * 1.2 + float(i)) * 4.0 - 14.0 * absf(float(i) - 3.0))
			for j in range(3):
				E.CI(s, cc + Vector2((float(j) - 1.0) * 30.0, (E.rnd(i + j, 3) - 0.5) * 14.0 + 8.0), 36.0 + 10.0 * E.rnd(i, j), Color(0.14, 0.15, 0.3, 0.3 * ca))
			E.CI(s, cc + Vector2(0, -12.0), 32.0, Color(0.3, 0.34, 0.6, 0.22 * ca))
			E.CI(s, cc + Vector2(-8.0, -20.0), 18.0, Color(0.6, 0.66, 0.95, 0.12 * ca))
	for i in range(4):
		var x := 170.0 + 110.0 * float(i)
		var L := 0.6 + 0.42 * float(i)
		var gp := Vector2(x, GY - 2.0)
		var wa := E.eo(E.sg(sec, L - 0.5, L - 0.25)) * (1.0 - E.sg(sec, L, L + 0.15))
		if wa > 0.0:
			E.ering(s, gp, R, R * FR, E.A(s, 0.3 * wa), 1.8)
			_gstar(s, gp, R * 0.7, sec * 2.0, 8, 3, E.K(s, 0.4 * wa), 1.2)
		var age := sec - L
		if age < 0.0: continue
		var e := E.eo(E.sg(age, 0.0, 0.35))
		var fb := 1.0 - E.sg(age, 0.4, 1.1)
		if fb <= 0.0: continue
		var fl := 1.0 - E.sg(age, 0.0, 0.3)
		# nhát sét to từ mây xuống đất (nhấp nháy)
		var top := Vector2(x + 20.0, -290.0)
		_bolt(s, top, gp, i * 31 + int(age * 24.0), maxf(fl, 0.35 * fb), 4.5, 26.0, true)
		_bolt(s, top + Vector2(-8, 0), gp + Vector2(6, 0), i * 17 + 3 + int(age * 24.0), 0.6 * fl, 2.0, 18.0, false)
		E.glow(s, gp + Vector2(0, -30), 160.0 * (1.0 - E.sg(age, 0.0, 0.35)), 0.9)
		E.shock(s, gp, R * e, R * e * FR, fb)
		_gfill(s, gp, R * e, E.A(s, 0.12 * fb))
		E.star(s, gp + Vector2(0, -20), 50.0 * (1.0 - age * 1.2), fb, 8)
		for k in range(6):
			var q := _ep(gp, R * 0.9 * e, TAU * float(k) / 6.0 + 0.5)
			_bolt(s, gp, q, k + i * 7 + int(age * 18.0), fb * 0.8, 1.4, 8.0, false)
		E.spark(s, gp + Vector2(0, -14), 0 if lowq else 10, 90.0, age * 1.6, fb, i + 2)

# ============================================================ CẤM CHÚ GIẢI PHÓNG
## ulPhapSuper: cuốn cấm thư mở trên đầu, pháp trận khổng lồ, mana xanh từ khắp nơi dồn thành quả cầu nén lại rồi nổ bán kính 340.
static func _forbidden(s, t: float, lowq: bool) -> void:
	_pal(s, "mana")
	var R := 340.0
	var gc := Vector2(0, GY - 4.0)
	var body := Vector2(0, -16.0)
	var charge := E.sg(t, 0.0, 0.34)
	var boom := E.sg(t, 0.34, 0.8)
	var fa := 1.0 - E.sg(t, 0.74, 1.0)
	# trận pháp khổng lồ nở theo đà dồn mana
	var ru := E.eo(E.sg(t, 0.0, 0.2))
	var rune_fade := 1.0 - E.sg(t, 0.5, 0.85)
	_gfill(s, gc, 150.0 * ru, E.A(s, 0.1 * rune_fade))
	_rune(s, gc, 150.0 * ru, t * 2.0, "mana", rune_fade)
	_rune(s, gc, 92.0 * ru, -t * 3.0, "arcane", 0.8 * rune_fade)
	if charge < 1.0 or boom < 0.15:
		# cuốn cấm thư mở ra trên đầu: hai trang sáng + chữ cổ
		var bk := Vector2(0, -92.0)
		var bo := E.eo(E.sg(t, 0.0, 0.18)) * (1.0 - E.sg(t, 0.3, 0.4))
		if bo > 0.0:
			E.glow(s, bk, 46.0 * bo, 0.5)
			for sd in [-1.0, 1.0]:
				var q := PackedVector2Array([bk + Vector2(float(sd) * 2.0, 0), bk + Vector2(float(sd) * 24.0 * bo, -6.0 - 4.0 * bo), bk + Vector2(float(sd) * 24.0 * bo, 14.0), bk + Vector2(float(sd) * 2.0, 18.0)])
				E.P(s, q, E.A(s, 0.8 * bo))
				E.PL(s, q, E.K(s, bo), 1.4)
				for k in range(4):
					var yy := bk.y + 3.0 + 3.0 * float(k)
					E.L(s, Vector2(bk.x + float(sd) * 6.0, yy), Vector2(bk.x + float(sd) * 20.0 * bo, yy - 1.0), E.K(s, 0.7 * bo), 1.0)
		# mana từ khắp vùng bán kính 340 dồn vào người
		var nn := 18 if lowq else 40
		for i in range(nn):
			var ph := E.rnd(i, 1)
			var ts := 0.02 + 0.22 * ph
			var u := E.sg(t, ts, ts + 0.16)
			if u <= 0.0 or u >= 1.0: continue
			var a := TAU * E.rnd(i, 2)
			var from := body + Vector2(cos(a) * R * (0.5 + 0.5 * E.rnd(i, 3)), sin(a) * R * 0.34 * (0.5 + 0.5 * E.rnd(i, 3)) - 30.0)
			var path := PackedVector2Array()
			for k in range(7):
				var uu := E.ei(clampf(u - float(k) * 0.035, 0.0, 1.0))
				var sw := sin(uu * PI) * 26.0 * (E.rnd(i, 4) - 0.5)
				path.append(from.lerp(body, uu) + Vector2(0, sw))
			E.PL(s, path, E.A(s, 0.4), 3.2)
			E.PL(s, path, E.K(s, 0.75), 1.2)
			E.CI(s, path[0], 2.6, E.K(s, 1.0))
		# quả cầu mana: phình rồi bị nén lại rất nhỏ trước khi nổ
		var rr := 8.0 + 18.0 * E.eo(E.sg(t, 0.04, 0.22))
		rr *= 1.0 - 0.7 * E.sg(t, 0.24, 0.34)
		rr += sin(t * 60.0) * 0.6
		_orb(s, body, rr, 1.0)
		E.AR(s, body, rr * 1.6, t * 14.0, t * 14.0 + 3.6, 22, E.K(s, 0.8), 1.6)
		E.AR(s, body, rr * 2.1, -t * 10.0, -t * 10.0 + 2.8, 22, E.A(s, 0.7), 1.4)
	if boom > 0.0:
		var e := E.eo(boom)
		var ring_r := R * e
		# chớp trắng tức thì
		E.glow(s, body, 320.0 * (1.0 - E.sg(boom, 0.0, 0.35)), 0.95)
		# vòm nổ + sóng nền đất đúng bán kính 340
		_gfill(s, gc, ring_r, E.A(s, 0.13 * fa))
		E.shock(s, gc, ring_r, ring_r * FR, fa)
		E.ering(s, gc, ring_r * 0.7, ring_r * 0.7 * FR, E.K(s, 0.6 * fa), 2.0)
		s.draw_set_transform(Vector2(0, GY - 4.0), 0.0, Vector2(1.0, 0.62))
		s.draw_arc(Vector2.ZERO, ring_r, PI, TAU, 64, E.A(s, 0.35 * fa), 8.0, true)
		s.draw_arc(Vector2.ZERO, ring_r, PI, TAU, 64, E.K(s, 0.9 * fa), 2.4, true)
		s.draw_arc(Vector2.ZERO, ring_r * 0.9, PI, TAU, 64, E.A(s, 0.5 * fa), 3.0, true)
		E.rst(s)
		# tia toả ra từ tâm
		for i in range(24):
			var a2 := TAU * float(i) / 24.0 + 0.1
			var d := Vector2(cos(a2), sin(a2) * 0.55)
			var l0 := ring_r * 0.12
			var l1 := ring_r * (0.55 + 0.4 * E.rnd(i, 5))
			E.cut(s, body + d * l0, body + d * l1, 3.5, fa * 0.85)
		E.star(s, body, 120.0 * (1.0 - boom * 0.6), fa, 12)
		for i in range(0 if lowq else 26):
			var a3 := TAU * E.rnd(i, 6)
			var rd := ring_r * (0.2 + 0.8 * E.rnd(i, 7))
			E.star(s, body + Vector2(cos(a3) * rd, sin(a3) * rd * 0.55), 4.0 + 4.0 * E.rnd(i, 8), fa, 4)
		E.dust(s, gc, ring_r * 0.7, boom, fa * 0.8, 6 if lowq else 14, 9)
