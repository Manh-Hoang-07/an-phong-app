extends RefCounted
## Hiệu ứng kỹ năng riêng (nhóm d): trị liệu sư, triệu hồi sư, kỹ năng chung, toàn năng.
## Vẽ lên node `s` (Node2D đang trong _draw): s.draw_*, s._a(alpha) màu chính, s._k(alpha) màu lõi, s._mix(t, alpha), s._rng.
## IDS: id kỹ năng -> sig. CFG: sig -> {"place": "front"|"body"|"ground"|"far", "dur", "nopop", "rumble"}.
## Toạ độ: +x = hướng nhìn, y âm = lên trên. Không tạo node; chỉ vẽ. (s để không kiểu vì gọi hàm của node vẽ.)
const IDS := {
	# --- Trị liệu sư
	"tg27": "dx_lightshaft", "tg32": "dx_bless", "tg37": "dx_angel", "tg38": "dx_decree",
	"tg42": "dx_judge", "tg45": "dx_phoenix", "ulTri1": "dx_phoenix2",
	"tl10": "dx_purify", "tl11": "dx_lightrain", "tl2": "dx_crescent", "tl25": "dx_sanctum",
	"tl3": "dx_dove", "tl30": "dx_lightarrow", "tl35": "dx_hexdome", "tl4": "dx_lightshield",
	"tl40": "dx_sunrise", "tl5": "dx_allheal", "tl6": "dx_aura", "tl7": "dx_lifedome",
	"tl8": "dx_holydrop", "tl9": "dx_seal",
	# --- Triệu hồi sư
	"th1": "dx_wisp", "th10": "dx_dragon", "th11": "dx_gather", "ulLinh1": "dx_soulburst",
	"th2": "dx_guardian", "th3": "dx_spiritblast", "th4": "dx_banner", "th5": "dx_beast",
	"th6": "dx_soulcall", "th7": "dx_soulorbit", "th8": "dx_spiritbird", "th9": "dx_resonance",
	# --- Chung
	"ulChung2": "dx_will", "ulChung3": "dx_voidslash", "ulSinhTu": "dx_taiji",
	# --- Toàn năng
	"ulToanNangSuper": "dx_allone", "vn1": "dx_awaken", "vn2": "dx_elemfuse", "vn3": "dx_flow",
	"vn4": "dx_balance", "vn5": "dx_vigor", "vn6": "dx_palm", "vn7": "dx_tripleslash",
}
const CFG := {
	"dx_lightshaft": {"place": "front", "dur": 1.0, "nopop": true},
	"dx_bless": {"place": "body", "dur": 1.2, "nopop": true},
	"dx_angel": {"place": "body", "dur": 1.3, "nopop": true},
	"dx_decree": {"place": "body", "dur": 1.2, "nopop": true},
	"dx_judge": {"place": "ground", "dur": 1.3, "nopop": true, "rumble": 5.0},
	"dx_phoenix": {"place": "body", "dur": 1.3, "nopop": true},
	"dx_phoenix2": {"place": "body", "dur": 1.5, "nopop": true, "rumble": 3.0},
	"dx_purify": {"place": "body", "dur": 1.1, "nopop": true},
	"dx_lightrain": {"place": "ground", "dur": 1.3, "nopop": true},
	"dx_crescent": {"place": "front", "dur": 0.9, "nopop": true},
	"dx_sanctum": {"place": "ground", "dur": 1.4, "nopop": true},
	"dx_dove": {"place": "body", "dur": 1.2, "nopop": true},
	"dx_lightarrow": {"place": "front", "dur": 0.8, "nopop": true},
	"dx_hexdome": {"place": "body", "dur": 1.3, "nopop": true},
	"dx_lightshield": {"place": "front", "dur": 1.1, "nopop": true},
	"dx_sunrise": {"place": "ground", "dur": 1.4, "nopop": true},
	"dx_allheal": {"place": "ground", "dur": 1.3, "nopop": true},
	"dx_aura": {"place": "body", "dur": 1.2, "nopop": true},
	"dx_lifedome": {"place": "ground", "dur": 1.4, "nopop": true},
	"dx_holydrop": {"place": "body", "dur": 1.1, "nopop": true},
	"dx_seal": {"place": "front", "dur": 1.0, "nopop": true},
	"dx_wisp": {"place": "front", "dur": 0.8, "nopop": true},
	"dx_dragon": {"place": "front", "dur": 1.0, "nopop": true},
	"dx_gather": {"place": "front", "dur": 1.2, "nopop": true},
	"dx_soulburst": {"place": "front", "dur": 1.5, "nopop": true, "rumble": 6.0},
	"dx_guardian": {"place": "front", "dur": 1.3, "nopop": true},
	"dx_spiritblast": {"place": "front", "dur": 1.0, "nopop": true, "rumble": 4.0},
	"dx_banner": {"place": "body", "dur": 1.2, "nopop": true},
	"dx_beast": {"place": "ground", "dur": 1.3, "nopop": true},
	"dx_soulcall": {"place": "body", "dur": 1.3, "nopop": true},
	"dx_soulorbit": {"place": "body", "dur": 1.3, "nopop": true},
	"dx_spiritbird": {"place": "front", "dur": 0.9, "nopop": true},
	"dx_resonance": {"place": "body", "dur": 1.2, "nopop": true},
	"dx_will": {"place": "body", "dur": 1.4, "nopop": true, "rumble": 3.0},
	"dx_voidslash": {"place": "front", "dur": 1.2, "nopop": true, "rumble": 5.0},
	"dx_taiji": {"place": "front", "dur": 1.3, "nopop": true, "rumble": 4.0},
	"dx_allone": {"place": "front", "dur": 1.5, "nopop": true, "rumble": 6.0},
	"dx_awaken": {"place": "body", "dur": 1.4, "nopop": true},
	"dx_elemfuse": {"place": "ground", "dur": 1.3, "nopop": true, "rumble": 4.0},
	"dx_flow": {"place": "body", "dur": 1.2, "nopop": true},
	"dx_balance": {"place": "body", "dur": 1.3, "nopop": true},
	"dx_vigor": {"place": "body", "dur": 1.2, "nopop": true},
	"dx_palm": {"place": "front", "dur": 0.9, "nopop": true},
	"dx_tripleslash": {"place": "front", "dur": 0.9, "nopop": true},
}

static func draw(s, sg: String, t: float, lowq: bool) -> void:
	match sg:
		"dx_lightshaft": _lightshaft(s, t, lowq)
		"dx_bless": _bless(s, t, lowq)
		"dx_angel": _angel(s, t, lowq)
		"dx_decree": _decree(s, t, lowq)
		"dx_judge": _judge(s, t, lowq)
		"dx_phoenix": _phoenix(s, t, lowq, 1.0)
		"dx_phoenix2": _phoenix(s, t, lowq, 1.4)
		"dx_purify": _purify(s, t, lowq)
		"dx_lightrain": _lightrain(s, t, lowq)
		"dx_crescent": _crescent_wave(s, t, lowq)
		"dx_sanctum": _sanctum(s, t, lowq)
		"dx_dove": _dove(s, t, lowq)
		"dx_lightarrow": _lightarrow(s, t, lowq)
		"dx_hexdome": _hexdome(s, t, lowq)
		"dx_lightshield": _lightshield(s, t, lowq)
		"dx_sunrise": _sunrise(s, t, lowq)
		"dx_allheal": _allheal(s, t, lowq)
		"dx_aura": _aura(s, t, lowq)
		"dx_lifedome": _lifedome(s, t, lowq)
		"dx_holydrop": _holydrop(s, t, lowq)
		"dx_seal": _seal(s, t, lowq)
		"dx_wisp": _wisp_bolt(s, t, lowq)
		"dx_dragon": _dragon(s, t, lowq)
		"dx_gather": _gather(s, t, lowq, false)
		"dx_soulburst": _gather(s, t, lowq, true)
		"dx_guardian": _guardian(s, t, lowq)
		"dx_spiritblast": _spiritblast(s, t, lowq)
		"dx_banner": _banner(s, t, lowq)
		"dx_beast": _beast(s, t, lowq)
		"dx_soulcall": _soulcall(s, t, lowq)
		"dx_soulorbit": _soulorbit(s, t, lowq)
		"dx_spiritbird": _spiritbird(s, t, lowq)
		"dx_resonance": _resonance(s, t, lowq)
		"dx_will": _will(s, t, lowq)
		"dx_voidslash": _voidslash(s, t, lowq)
		"dx_taiji": _taiji(s, t, lowq)
		"dx_allone": _allone(s, t, lowq)
		"dx_awaken": _awaken(s, t, lowq)
		"dx_elemfuse": _elemfuse(s, t, lowq)
		"dx_flow": _flow(s, t, lowq)
		"dx_balance": _balance(s, t, lowq)
		"dx_vigor": _vigor(s, t, lowq)
		"dx_palm": _palm(s, t, lowq)
		"dx_tripleslash": _tripleslash(s, t, lowq)
		_: pass

# ============================================================ Hàm vẽ dùng chung
static func _rst(s) -> void:
	s.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

static func _glow(s, c: Vector2, r: float, al: float) -> void:
	for i in range(5):
		var u := float(i) / 4.0
		s.draw_circle(c, r * (1.0 - u * 0.8), s._mix(u, al * (0.07 + 0.09 * u)))

static func _ell(s, c: Vector2, rx: float, ry: float, col: Color) -> void:
	s.draw_set_transform(c, 0.0, Vector2(rx, ry))
	s.draw_circle(Vector2.ZERO, 1.0, col)
	_rst(s)

## Cung elip (vòng trên mặt đất): rx bán kính ngang, ry bán kính dọc.
static func _ellarc(s, c: Vector2, rx: float, ry: float, col: Color, w: float, rot: float = 0.0, a0: float = 0.0, a1: float = TAU) -> void:
	if rx < 1.0: return
	s.draw_set_transform(c, rot, Vector2(1.0, ry / rx))
	s.draw_arc(Vector2.ZERO, rx, a0, a1, 40, col, w)
	_rst(s)

static func _flame(s, base: Vector2, h: float, w: float, al: float) -> void:
	s.draw_colored_polygon(PackedVector2Array([base + Vector2(-w, 0), base + Vector2(-w * 0.7, -h * 0.45), base + Vector2(0, -h), base + Vector2(w * 0.8, -h * 0.4), base + Vector2(w, 0)]), s._a(al))
	s.draw_colored_polygon(PackedVector2Array([base + Vector2(-w * 0.5, 0), base + Vector2(0, -h * 0.65), base + Vector2(w * 0.5, 0)]), s._k(al * 0.8))

static func _star4(s, p: Vector2, r: float, col: Color) -> void:
	s.draw_set_transform(p, 0.0, Vector2.ONE)
	s._starpoly(4, r, r * 0.26, col)
	_rst(s)

static func _leaf(s, base: Vector2, ang: float, ln: float, w: float, col: Color) -> void:
	var d := Vector2(cos(ang), sin(ang))
	var n := d.orthogonal()
	s.draw_colored_polygon(PackedVector2Array([base, base + d * ln * 0.45 + n * w, base + d * ln, base + d * ln * 0.45 - n * w]), col)

static func _wings(s, c: Vector2, span: float, flap: float, al: float, nf: int) -> void:
	for side in [-1.0, 1.0]:
		for i in range(nf):
			var u := float(i) / float(maxi(1, nf - 1))
			var ang: float = -PI * 0.5 + side * (0.28 + u * 1.15 + flap * 0.22)
			_leaf(s, c + Vector2(side * 5.0, 0.0), ang, span * (1.0 - u * 0.42), 6.5 - u * 2.0, s._mix(1.0 - u, 0.85 * al))

static func _orb(s, p: Vector2, r: float, c: Color, al: float) -> void:
	s.draw_circle(p, r * 2.0, Color(c.r, c.g, c.b, al * 0.14))
	s.draw_circle(p, r * 1.4, Color(c.r, c.g, c.b, al * 0.35))
	s.draw_circle(p, r, Color(c.r, c.g, c.b, al * 0.95))
	s.draw_circle(p, r * 0.45, Color(1, 1, 1, al * 0.9))

static func _crescent(s, c: Vector2, rad: float, a: float, d: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in range(13):
		var an := -a + 2.0 * a * float(i) / 12.0
		pts.append(c + Vector2(cos(an), sin(an)) * rad)
	var tip := Vector2(cos(a), sin(a)) * rad
	var cc := c + Vector2(-d, 0.0)
	var rr := (c + tip - cc).length()
	var b := atan2(tip.y, tip.x + d)
	for i in range(1, 12):
		var an2 := b - 2.0 * b * float(i) / 12.0
		pts.append(cc + Vector2(cos(an2), sin(an2)) * rr)
	s.draw_colored_polygon(pts, col)

## Chim nhìn ngang, đầu hướng +x. flap -1..1. hawk: mỏ nhọn + đuôi xoè.
static func _bird(s, p: Vector2, sz: float, flap: float, al: float, hawk: bool) -> void:
	var body: Color = s._k(al)
	var edge: Color = s._a(al * 0.9)
	_ell(s, p, sz, sz * 0.42, body)
	s.draw_circle(p + Vector2(sz * 0.9, -sz * 0.25), sz * 0.28, body)
	var bk := sz * (0.55 if hawk else 0.4)
	s.draw_colored_polygon(PackedVector2Array([p + Vector2(sz * 1.1, -sz * 0.4), p + Vector2(sz * 1.1 + bk, -sz * 0.2), p + Vector2(sz * 1.1, -sz * 0.08)]), edge)
	var nt := 3 if hawk else 1
	for i in range(nt):
		var yy := (float(i) - float(nt - 1) * 0.5) * sz * 0.35
		s.draw_colored_polygon(PackedVector2Array([p + Vector2(-sz * 0.8, -sz * 0.1), p + Vector2(-sz * 2.0, yy - sz * 0.12), p + Vector2(-sz * 2.0, yy + sz * 0.25), p + Vector2(-sz * 0.8, sz * 0.15)]), edge)
	for k in range(2):
		var wa := al * (1.0 if k == 0 else 0.55)
		var tipy := -sz * 1.5 * flap
		var base := p + Vector2(sz * 0.15 - k * sz * 0.25, -sz * 0.15)
		var tip := base + Vector2(-sz * (0.9 + 0.3 * k), tipy - sz * 0.2)
		var mid := base + Vector2(-sz * 1.4, tipy * 0.55 + sz * 0.1)
		var bb := base + Vector2(-sz * 0.9, sz * 0.15)
		s.draw_colored_polygon(PackedVector2Array([base + Vector2(sz * 0.4, 0.0), tip, bb]), s._a(wa * 0.9))
		s.draw_colored_polygon(PackedVector2Array([tip, mid, bb]), s._a(wa * 0.6))
		s.draw_line(base, tip, s._k(wa), 1.4)

## Linh hồn / bóng ma nhỏ: đầu tròn + đuôi lượn về hướng ngược dir.
static func _ghost(s, p: Vector2, r: float, dir: Vector2, al: float, ph: float) -> void:
	var back := -dir.normalized()
	var n := back.orthogonal()
	for j in range(5):
		var u := float(j) / 4.0
		var q := p + back * r * (0.6 + 2.6 * u) + n * sin(ph + u * 5.0) * r * 0.6 * u
		s.draw_circle(q, r * (0.85 - 0.6 * u), s._a(al * 0.55 * (1.0 - u)))
	s.draw_circle(p, r * 1.7, s._a(al * 0.2))
	s.draw_circle(p, r, s._k(al * 0.95))
	s.draw_circle(p + dir.normalized() * r * 0.25 + n * r * 0.3, r * 0.2, Color(0.05, 0.0, 0.12, al))
	s.draw_circle(p + dir.normalized() * r * 0.25 - n * r * 0.3, r * 0.2, Color(0.05, 0.0, 0.12, al))

static func _heart(s, c: Vector2, sz: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in range(28):
		var a := TAU * float(i) / 28.0
		var x := 16.0 * pow(sin(a), 3.0)
		var y := -(13.0 * cos(a) - 5.0 * cos(2.0 * a) - 2.0 * cos(3.0 * a) - cos(4.0 * a))
		pts.append(c + Vector2(x, y) * sz / 16.0)
	s.draw_colored_polygon(pts, col)

static func _shock(s, c: Vector2, r: float, ry: float, al: float, w: float) -> void:
	_ellarc(s, c, r, ry, s._a(al * 0.35), w * 2.2)
	_ellarc(s, c, r, ry, s._a(al), w)
	_ellarc(s, c, r, ry, s._k(al * 0.9), w * 0.4)

# ============================================================ TRỊ LIỆU SƯ
## Thánh Quang Chiếu: cột sáng chéo từ trời rọi xuống mục tiêu.
static func _lightshaft(s, t: float, lq: bool) -> void:
	var q := minf(1.0, t * 3.0)
	if q < 0.03: return
	var fade := 1.0 - maxf(0.0, t - 0.75) * 3.0
	var dst := Vector2(6, 8)
	var src := Vector2(-80, -220)
	var tip := src.lerp(dst, q)
	var nr := (dst - src).normalized().orthogonal()
	for L in [[44.0, 0.14], [28.0, 0.28], [12.0, 0.75]]:
		var w: float = L[0]
		var c: Color = s._k(L[1] * fade) if w < 20.0 else s._a(L[1] * fade)
		s.draw_colored_polygon(PackedVector2Array([src + nr * w * 0.25, tip + nr * w * 0.5, tip - nr * w * 0.5, src - nr * w * 0.25]), c)
	if q > 0.6:
		var pul := 1.0 + 0.1 * sin(t * 30.0)
		_glow(s, dst, 52.0 * pul, fade)
		_star4(s, dst, 34.0 * pul, s._k(0.9 * fade))
		_ellarc(s, dst + Vector2(0, 16), 14.0 + 40.0 * t, 5.0 + 12.0 * t, s._a(0.8 * (1.0 - t)), 3.0)
	var n := 4 if lq else 8
	for k in range(n):
		var q2 := fposmod(t * 1.3 + float(k) * 0.17, 1.0)
		var p := src.lerp(dst, q2) + nr * sin(float(k) * 3.1) * 12.0
		s.draw_circle(p, 2.2, s._k(sin(q2 * PI) * fade))

## Phước Lành: mưa tia sáng vàng rơi nhẹ + vầng hào quang trên đầu.
static func _bless(s, t: float, lq: bool) -> void:
	var g := minf(1.0, t * 3.0)
	_glow(s, Vector2(0, -4), 40.0 * g, 0.7)
	var hy := -46.0 + sin(t * 8.0) * 2.0
	_ellarc(s, Vector2(0, hy), 19.0 * g, 5.5 * g, s._a(0.35), 7.0)
	_ellarc(s, Vector2(0, hy), 19.0 * g, 5.5 * g, s._a(0.95), 3.0)
	_ellarc(s, Vector2(0, hy), 19.0 * g, 5.5 * g, s._k(0.9), 1.2)
	var n := 6 if lq else 11
	for k in range(n):
		var x := -34.0 + 68.0 * float(k) / float(n - 1) + sin(t * 5.0 + k) * 4.0
		var q := fposmod(t * 0.9 + float(k) * 0.131, 1.0)
		var y := -62.0 + 100.0 * q
		_star4(s, Vector2(x, y), 3.5 + float(k % 3) * 1.8, s._k(sin(q * PI)))
	_ellarc(s, Vector2(0, 26), 14.0 + 22.0 * g, 5.0 + 7.0 * g, s._a(0.7 * (1.0 - t * 0.6)), 2.5)

## Thiên Sứ Hộ Tống: đôi cánh thiên sứ lớn sau lưng + vầng sáng + lông vũ rơi.
static func _angel(s, t: float, lq: bool) -> void:
	var g := minf(1.0, t * 2.5)
	var flap := sin(t * 9.0) * 0.5
	_glow(s, Vector2(0, -6), 54.0 * g, 0.5)
	_wings(s, Vector2(0, -10), 66.0 * g, flap, 0.62, 7 if not lq else 5)
	_ellarc(s, Vector2(0, -46), 15.0, 4.5, s._a(0.95), 3.0)
	_ellarc(s, Vector2(0, -46), 15.0, 4.5, s._k(0.9), 1.2)
	var n := 3 if lq else 6
	for k in range(n):
		var q := fposmod(t * 0.8 + float(k) * 0.19, 1.0)
		var side := 1.0 if k % 2 == 0 else -1.0
		var fp := Vector2(side * (30.0 + 25.0 * q + sin(q * 9.0 + k) * 6.0), -30.0 + 70.0 * q)
		_leaf(s, fp, 1.1 + sin(q * 8.0 + k) * 0.7, 10.0, 2.6, s._k(sin(q * PI) * 0.9))

## Thánh Dụ: cuộn sắc lệnh sáng mở ra, chữ hiện dần, ánh sáng rót xuống.
static func _decree(s, t: float, lq: bool) -> void:
	var g := minf(1.0, t * 2.5)
	var c := Vector2(0, -50.0 + sin(t * 6.0) * 2.0)
	for k in range(10):
		var a := TAU * float(k) / 10.0 + t * 0.9
		var d := Vector2(cos(a), sin(a))
		s.draw_colored_polygon(PackedVector2Array([c + d * 18.0 + d.orthogonal() * 4.0, c + d * (46.0 + 14.0 * (k % 2)) * g, c + d * 18.0 - d.orthogonal() * 4.0]), s._a(0.22))
	var w := 44.0 * g
	var h := 36.0
	s.draw_rect(Rect2(c.x - w * 0.5, c.y - h * 0.5, w, h), s._a(0.4))
	s.draw_rect(Rect2(c.x - w * 0.5, c.y - h * 0.5, w, h), s._a(0.9), false, 1.6)
	s.draw_rect(Rect2(c.x - w * 0.5 - 3.0, c.y - h * 0.5 - 5.0, w + 6.0, 6.0), s._a(0.95))
	s.draw_rect(Rect2(c.x - w * 0.5 - 3.0, c.y + h * 0.5 - 1.0, w + 6.0, 6.0), s._a(0.95))
	var vis := int(6.0 * minf(1.0, t * 2.2))
	for i in range(vis):
		var lw := w * (0.78 - 0.14 * float(i % 3))
		s.draw_line(Vector2(c.x - w * 0.4, c.y - h * 0.38 + float(i) * 5.0), Vector2(c.x - w * 0.4 + lw, c.y - h * 0.38 + float(i) * 5.0), s._k(0.95), 1.8)
	s.draw_circle(c + Vector2(0, h * 0.5 - 3.0), 4.5, s._a(0.95))
	_star4(s, c + Vector2(0, h * 0.5 - 3.0), 4.0, s._k(0.95))
	var n := 5 if lq else 9
	for k in range(n):
		var q := fposmod(t * 1.0 + float(k) * 0.113, 1.0)
		var x := -20.0 + 40.0 * fposmod(float(k) * 0.381, 1.0)
		s.draw_circle(Vector2(x, c.y + 24.0 + 54.0 * q), 2.0, s._k(sin(q * PI)))
	_glow(s, Vector2(0, 6), 30.0, 0.6 * sin(t * PI))

## Ánh Sáng Phán Xét: búa phán xét ánh sáng giáng xuống vòng pháp trận, cột sáng bùng lên.
static func _judge(s, t: float, lq: bool) -> void:
	var g := minf(1.0, t * 4.0)
	_ellarc(s, Vector2.ZERO, 96.0 * g, 30.0 * g, s._a(0.7), 3.0)
	_ellarc(s, Vector2.ZERO, 70.0 * g, 22.0 * g, s._k(0.6), 1.6, t * 2.0)
	s.draw_set_transform(Vector2.ZERO, t * 1.0, Vector2(1.0, 0.31))
	for k in range(3):
		var a := TAU * float(k) / 3.0
		s.draw_line(Vector2(cos(a), sin(a)) * 84.0, Vector2(cos(a + PI), sin(a + PI)) * 84.0, s._a(0.4), 1.5)
	_rst(s)
	var q := clampf(t / 0.36, 0.0, 1.0)
	if t < 0.5:
		var gp := Vector2(0, lerpf(-210.0, -34.0, q * q))
		var rot := lerpf(-0.9, 0.0, q * q)
		s.draw_set_transform(gp, rot, Vector2.ONE)
		s.draw_rect(Rect2(-34, -16, 68, 32), s._a(0.95))
		s.draw_rect(Rect2(-34, -16, 68, 32), s._k(0.95), false, 2.0)
		s.draw_rect(Rect2(-40, -12, 8, 24), s._k(0.9))
		s.draw_rect(Rect2(32, -12, 8, 24), s._k(0.9))
		s.draw_rect(Rect2(-5, 16, 10, 78), s._a(0.9))
		s.draw_circle(Vector2(0, 96), 6.0, s._k(0.9))
		_rst(s)
		s.draw_line(gp + Vector2(0, -110), gp + Vector2(0, -20), s._a(0.3), 14.0)
	if t >= 0.36:
		var r := minf(1.0, (t - 0.36) / 0.5)
		var fa := 1.0 - r
		_shock(s, Vector2.ZERO, 20.0 + 150.0 * r, 6.0 + 48.0 * r, fa, 5.0)
		_shock(s, Vector2.ZERO, 10.0 + 100.0 * r, 4.0 + 32.0 * r, fa, 4.0)
		var pw := 38.0 * (1.0 - r * 0.4)
		for L in [[1.0, 0.18], [0.62, 0.35], [0.28, 0.9]]:
			var w2: float = pw * L[0]
			var cc: Color = s._k(L[1] * fa) if L[0] < 0.5 else s._a(L[1] * fa)
			s.draw_rect(Rect2(-w2, -240.0, w2 * 2.0, 242.0), cc)
		_glow(s, Vector2(0, -6), 60.0, fa)
		var nc := 5 if lq else 9
		for k in range(nc):
			var a := TAU * float(k) / float(nc) + 0.3
			var ln := (30.0 + 60.0 * r)
			s.draw_line(Vector2(cos(a), sin(a) * 0.32) * 12.0, Vector2(cos(a), sin(a) * 0.32) * ln, s._k(fa), 2.0)

## Phục Sinh Ánh Quang / Thánh Quang Hồi Sinh: phượng hoàng lửa vàng vút lên từ mặt đất.
static func _phoenix(s, t: float, lq: bool, big: float) -> void:
	var e := 1.0 - pow(1.0 - minf(1.0, t * 1.15), 2.0)
	var cy := lerpf(34.0, -22.0 * big, e)
	var fl := sin(t * 17.0)
	var al := minf(1.0, t * 5.0) * (1.0 - maxf(0.0, t - 0.85) * 4.0)
	if big > 1.0:
		var pw := 24.0 * (1.0 - t * 0.3)
		for L in [[1.0, 0.1], [0.55, 0.2]]:
			s.draw_rect(Rect2(-pw * L[0] * 1.6, -150.0, pw * L[0] * 3.2, 182.0), s._a(L[1] * al))
		_ellarc(s, Vector2(0, 26), 30.0 + 90.0 * t, 10.0 + 28.0 * t, s._a(0.9 * (1.0 - t)), 3.5)
		_ellarc(s, Vector2(0, 26), 16.0 + 60.0 * t, 6.0 + 19.0 * t, s._k(0.8 * (1.0 - t)), 2.0)
	_glow(s, Vector2(0, cy), 60.0 * big, al * 0.45)
	for side in [-1.0, 1.0]:
		for i in range(7):
			var u := float(i) / 6.0
			var ang: float = -PI * 0.5 + side * (0.3 + u * 1.05 + fl * 0.3)
			_leaf(s, Vector2(side * 5.0, cy - 2.0), ang, (50.0 - u * 16.0) * big, 6.5, s._mix(1.0 - u, 0.6 * al))
	for i in range(5):
		var u := float(i) / 4.0
		var ang: float = PI * 0.5 + (float(i) - 2.0) * 0.24 + sin(t * 9.0 + float(i)) * 0.14
		_leaf(s, Vector2(0, cy + 10.0), ang, (44.0 + 14.0 * (1.0 - absf(u - 0.5) * 2.0)) * big, 5.0, s._mix(u, 0.6 * al))
	_ell(s, Vector2(0, cy), 7.5, 14.0, s._k(0.95 * al))
	s.draw_circle(Vector2(0, cy - 16.0), 5.5, s._k(0.95 * al))
	s.draw_colored_polygon(PackedVector2Array([Vector2(4, cy - 18), Vector2(13, cy - 15), Vector2(4, cy - 12)]), s._a(al))
	for i in range(3):
		_leaf(s, Vector2(-2.0 + float(i) * 2.0, cy - 20.0), -PI * 0.5 - 0.5 + float(i) * 0.5, 12.0, 2.5, s._a(0.9 * al))
	var n := 5 if lq else 11
	for k in range(n):
		var x: float = s._rng.randf_range(-40.0, 40.0)
		var q := fposmod(t * 1.2 + float(k) * 0.093, 1.0)
		s.draw_circle(Vector2(x, cy + 30.0 - 96.0 * q), 2.2, s._a(0.9 * (1.0 - q) * al))

## Thanh Tẩy: vòng nước thanh lọc quét từ chân lên đầu, bong bóng + giọt xoắn ốc bay lên.
static func _purify(s, t: float, lq: bool) -> void:
	_glow(s, Vector2(0, -2), 38.0, 0.6)
	var n := 6 if lq else 12
	for arm in range(2):
		for k in range(n):
			var u := float(k) / float(n - 1)
			var q := fposmod(t * 0.9 + u, 1.0)
			var ang := q * TAU * 1.6 + float(arm) * PI
			var p := Vector2(cos(ang) * 22.0, 30.0 - 76.0 * q + sin(ang) * 4.0)
			var dep := 0.6 + 0.4 * sin(ang)
			s.draw_circle(p, 2.4 * dep + 0.8, s._a(0.85 * sin(q * PI)))
			s.draw_circle(p + Vector2(-0.6, -0.6), 0.9 * dep, s._k(sin(q * PI)))
	var m := 4 if lq else 8
	for k in range(m):
		var x := -26.0 + 52.0 * fposmod(float(k) * 0.381, 1.0)
		var q := fposmod(t * 0.7 + float(k) * 0.127, 1.0)
		var r := 3.0 + float(k % 3) * 2.0
		var p := Vector2(x + sin(q * 10.0 + k) * 3.0, 28.0 - 80.0 * q)
		s.draw_arc(p, r, 0.0, TAU, 14, s._a(0.8 * sin(q * PI)), 1.5)
		s.draw_circle(p + Vector2(-r * 0.35, -r * 0.35), r * 0.22, s._k(0.9 * sin(q * PI)))
	var sy := 30.0 - 74.0 * t
	var sa := sin(t * PI)
	_ellarc(s, Vector2(0, sy), 26.0, 8.0, s._a(0.35 * sa), 7.0)
	_ellarc(s, Vector2(0, sy), 26.0, 8.0, s._k(0.9 * sa), 2.2)

## Quang Vũ Tái Sinh: mưa ánh sáng rơi xuống vùng đất, gợn sóng, mầm sống nảy lên.
static func _lightrain(s, t: float, lq: bool) -> void:
	_glow(s, Vector2(0, -170), 80.0, 0.6)
	_ellarc(s, Vector2.ZERO, 92.0, 28.0, s._a(0.25), 10.0)
	_ellarc(s, Vector2.ZERO, 92.0, 28.0, s._a(0.7), 2.5)
	var n := 9 if lq else 18
	for k in range(n):
		var x := -78.0 + 156.0 * fposmod(float(k) * 0.618, 1.0)
		var q := fposmod(t * 1.7 + float(k) * 0.371, 1.0)
		var y := -190.0 + 190.0 * q
		var gy := (fposmod(float(k) * 0.37, 1.0) - 0.5) * 24.0
		if q < 0.93:
			var yy := y + gy * q
			s.draw_line(Vector2(x, yy), Vector2(x - 4.0, yy - 26.0), s._a(0.5), 3.2)
			s.draw_line(Vector2(x, yy), Vector2(x - 4.0, yy - 20.0), s._k(0.95), 1.3)
		else:
			var r := (q - 0.93) / 0.07
			_ellarc(s, Vector2(x, gy), 4.0 + 12.0 * r, 1.5 + 4.0 * r, s._k(1.0 - r), 1.5)
	var g := clampf((t - 0.45) * 2.0, 0.0, 1.0)
	for k in range(5 if lq else 8):
		var x := -66.0 + 132.0 * float(k) / 7.0
		s._plus(Vector2(x, -4.0 - 22.0 * g * (0.6 + 0.4 * sin(float(k) * 2.0))), 5.0 * g, s._a(0.9 * g), s._k(g))

## Sóng Thánh: lưỡi sóng ánh sáng hình lưỡi liềm lướt tới, để lại các vệt mờ.
static func _crescent_wave(s, t: float, lq: bool) -> void:
	var x := -40.0 + 150.0 * t
	var nt := 3 if lq else 5
	for j in range(nt - 1, 0, -1):
		var u := float(j) / float(nt)
		_crescent(s, Vector2(x - 20.0 * float(j), 0.0), 40.0 - 4.0 * float(j), 1.05, 26.0, s._a(0.32 * (1.0 - u)))
	_crescent(s, Vector2(x, 0.0), 46.0, 1.1, 30.0, s._a(0.55))
	_crescent(s, Vector2(x + 3.0, 0.0), 41.0, 1.0, 26.0, s._a(0.95))
	_crescent(s, Vector2(x + 6.0, 0.0), 36.0, 0.9, 22.0, s._k(0.95))
	var n := 4 if lq else 8
	for k in range(n):
		var q := fposmod(t * 2.0 + float(k) * 0.27, 1.0)
		var yy := (float(k) - float(n - 1) * 0.5) * 9.0
		s.draw_circle(Vector2(x - 6.0 - 50.0 * q, yy), 2.0, s._k((1.0 - q) * 0.9))

## Thánh Vực: pháp trận lục mang xoay trên mặt đất, sáu cột sáng + màn sáng.
static func _sanctum(s, t: float, lq: bool) -> void:
	var g := minf(1.0, t * 3.0)
	var R := 100.0 * g
	_ellarc(s, Vector2.ZERO, R, R * 0.34, s._a(0.2), 12.0)
	_ellarc(s, Vector2.ZERO, R, R * 0.34, s._a(0.85), 3.0)
	_ellarc(s, Vector2.ZERO, R * 0.62, R * 0.21, s._k(0.7), 1.6)
	s.draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.34))
	var rot := t * 1.4
	for tri in range(2):
		var pts := PackedVector2Array()
		for k in range(4):
			var a := rot + TAU * float(k % 3) / 3.0 + float(tri) * PI + TAU / 12.0 * 0.0
			pts.append(Vector2(cos(a), sin(a)) * R * 0.92)
		s.draw_polyline(pts, s._k(0.85), 2.0)
	_rst(s)
	var hp := PackedVector2Array()
	for k in range(6):
		var a := rot + TAU * float(k) / 6.0
		hp.append(Vector2(cos(a) * R * 0.92, sin(a) * R * 0.92 * 0.34))
	var hh := minf(1.0, maxf(0.0, t - 0.15) * 2.0) * 120.0
	for k in range(6):
		var p1 := hp[k]
		var p2 := hp[(k + 1) % 6]
		s.draw_colored_polygon(PackedVector2Array([p1, p2, p2 + Vector2(0, -hh), p1 + Vector2(0, -hh)]), s._a(0.1))
	for k in range(6):
		s.draw_line(hp[k], hp[k] + Vector2(0, -hh), s._a(0.5), 6.0)
		s.draw_line(hp[k], hp[k] + Vector2(0, -hh), s._k(0.95), 2.0)
		_star4(s, hp[k] + Vector2(0, -hh), 7.0, s._k(0.9))
	var n := 4 if lq else 9
	for k in range(n):
		var q := fposmod(t * 0.9 + float(k) * 0.117, 1.0)
		var a := TAU * fposmod(float(k) * 0.618, 1.0)
		s.draw_circle(Vector2(cos(a) * R * 0.6, sin(a) * R * 0.2 - 90.0 * q), 2.0, s._k(sin(q * PI)))

## Ân Sủng: chim bồ câu mang ánh sáng bay lượn trên đầu, rải lông vũ và nón sáng ban phước.
static func _dove(s, t: float, lq: bool) -> void:
	var u := minf(1.0, t * 1.3)
	var p := Vector2(lerpf(-80.0, 6.0, u), lerpf(-30.0, -62.0, u) - sin(u * PI) * 30.0)
	var flap := sin(t * 20.0) * (1.0 - u * 0.5)
	for j in range(1, 5):
		var tp := Vector2(p.x - 10.0 * float(j), p.y + 4.0 * float(j))
		s.draw_circle(tp, 3.5 - 0.6 * float(j), s._a(0.4 * (1.0 - float(j) * 0.2)))
	_glow(s, p, 24.0, 0.9)
	_bird(s, p, 11.0, flap, 0.95, false)
	if t > 0.45:
		var g := minf(1.0, (t - 0.45) * 3.0)
		var fa := g * (1.0 - maxf(0.0, t - 0.8) * 5.0)
		s.draw_colored_polygon(PackedVector2Array([p + Vector2(-4, 6), p + Vector2(4, 6), Vector2(34, 26), Vector2(-34, 26)]), s._a(0.14 * fa))
		_glow(s, Vector2(0, -6), 40.0 * g, fa)
		var n := 4 if lq else 8
		for k in range(n):
			var q := fposmod(t * 1.1 + float(k) * 0.17, 1.0)
			_leaf(s, Vector2(p.x + (float(k) - 3.5) * 8.0, p.y + 10.0 + 62.0 * q), 1.2 + sin(q * 7.0 + k) * 0.8, 9.0, 2.4, s._k(sin(q * PI) * fa))

## Quang Tiễn: mũi tên ánh sáng lớn bay thẳng, vệt sáng dài, nổ sao khi tới.
static func _lightarrow(s, t: float, lq: bool) -> void:
	var u := minf(1.0, t / 0.8)
	var x := -50.0 + 150.0 * u
	var nr := Vector2(0, 1)
	s._streak(Vector2(x - 110.0, 0.0), Vector2(x - 4.0, 0.0), 12.0)
	_glow(s, Vector2(x + 6, 0), 26.0, 0.9)
	s.draw_line(Vector2(x - 44.0, 0.0), Vector2(x + 4.0, 0.0), s._a(0.95), 4.0)
	s.draw_line(Vector2(x - 44.0, 0.0), Vector2(x + 4.0, 0.0), s._k(1.0), 1.6)
	s.draw_colored_polygon(PackedVector2Array([Vector2(x + 4, -8), Vector2(x + 28, 0), Vector2(x + 4, 8)]), s._k(0.98))
	s.draw_colored_polygon(PackedVector2Array([Vector2(x + 6, -5), Vector2(x + 22, 0), Vector2(x + 6, 5)]), s._a(0.9))
	for sg in [-1.0, 1.0]:
		s.draw_colored_polygon(PackedVector2Array([Vector2(x - 44, 0) + nr * 0.0, Vector2(x - 56, sg * 9.0), Vector2(x - 36, sg * 2.0)]), s._a(0.9))
		s.draw_colored_polygon(PackedVector2Array([Vector2(x - 34, 0), Vector2(x - 46, sg * 9.0), Vector2(x - 28, sg * 2.0)]), s._k(0.8))
	var n := 4 if lq else 8
	for k in range(n):
		var q := fposmod(t * 2.2 + float(k) * 0.21, 1.0)
		_star4(s, Vector2(x - 20.0 - 70.0 * q, sin(float(k) * 2.4) * 11.0), 3.5 * (1.0 - q), s._k(1.0 - q))
	if u >= 1.0:
		var r := (t - 0.8) / 0.2
		_star4(s, Vector2(x + 24.0, 0.0), 10.0 + 36.0 * r, s._k(1.0 - r))
		s.draw_arc(Vector2(x + 24.0, 0.0), 6.0 + 40.0 * r, 0.0, TAU, 24, s._a(1.0 - r), 3.0)

## Kết Giới Thánh Quang: vòm lục giác tổ ong lan sóng sáng quanh người.
static func _hexdome(s, t: float, lq: bool) -> void:
	var g := minf(1.0, t * 2.8)
	var c := Vector2(0, 14)
	var R := 56.0 * g
	for i in range(5):
		var u := float(i) / 4.0
		s.draw_circle(c, R * (1.0 - u * 0.5), s._mix(u, 0.035 + 0.02 * u))
	s.draw_arc(c, R, PI, TAU, 36, s._a(0.95), 3.0)
	s.draw_arc(c, R - 3.0, PI, TAU, 36, s._k(0.6), 1.2)
	_ellarc(s, Vector2(0, 24), R, R * 0.2, s._a(0.7), 2.5)
	var hs := 13.0
	for j in range(0, 5):
		for i in range(-3, 4):
			var cx := float(i) * hs * 1.75 + (hs * 0.875 if j % 2 == 1 else 0.0)
			var cy := 14.0 - float(j) * hs * 1.52
			var hc := Vector2(cx, cy)
			if (hc - c).length() > R - hs * 0.6 or cy > 20.0: continue
			var wv := 0.5 + 0.5 * sin((hc - c).length() * 0.18 - t * 22.0)
			var pts := PackedVector2Array()
			for k in range(7):
				var a := PI / 6.0 + TAU * float(k) / 6.0
				pts.append(hc + Vector2(cos(a), sin(a)) * hs * 0.92)
			s.draw_polyline(pts, s._a(0.35 + 0.6 * wv), 1.6)
			if wv > 0.85 and not lq: s.draw_circle(hc, hs * 0.55, s._k(0.18))

## Khiên Ánh Sáng: tấm khiên huy hiệu thập tự trước người, ánh sáng quét ngang.
static func _lightshield(s, t: float, lq: bool) -> void:
	var g := minf(1.0, t * 3.5)
	var c := Vector2(-24.0, -2.0)
	_glow(s, c, 50.0 * g, 0.5)
	s.draw_set_transform(c, 0.0, Vector2(g, g))
	var outer := PackedVector2Array([Vector2(-26, -36), Vector2(26, -36), Vector2(28, -6), Vector2(0, 42), Vector2(-28, -6)])
	s.draw_colored_polygon(outer, s._a(0.5))
	s.draw_colored_polygon(PackedVector2Array([Vector2(-20, -30), Vector2(20, -30), Vector2(22, -7), Vector2(0, 34), Vector2(-22, -7)]), s._a(0.22))
	s.draw_polyline(PackedVector2Array([Vector2(-26, -36), Vector2(26, -36), Vector2(28, -6), Vector2(0, 42), Vector2(-28, -6), Vector2(-26, -36)]), s._k(0.95), 2.0)
	s.draw_rect(Rect2(-4, -26, 8, 46), s._k(0.95))
	s.draw_rect(Rect2(-14, -12, 28, 8), s._k(0.95))
	var sw := fposmod(t * 1.6, 1.0)
	var sx := -40.0 + 80.0 * sw
	s.draw_line(Vector2(sx, -38), Vector2(sx + 16.0, 40), Color(1, 1, 1, 0.35 * sin(sw * PI)), 9.0)
	_rst(s)
	_ellarc(s, c + Vector2(0, 40), 28.0 * g, 7.0 * g, s._a(0.6), 2.5)
	var n := 3 if lq else 6
	for k in range(n):
		var q := fposmod(t * 1.0 + float(k) * 0.16, 1.0)
		_star4(s, c + Vector2(cos(float(k) * 2.4) * 34.0, 36.0 - 76.0 * q), 3.5, s._k(sin(q * PI)))

## Bình Minh Tái Sinh: mặt trời mọc từ chân trời, tia nắng toả, sóng sáng lan trên đất.
static func _sunrise(s, t: float, lq: bool) -> void:
	var e := minf(1.0, t * 1.5)
	var sc := Vector2(0, lerpf(34.0, -6.0, e))
	var R := 42.0
	var al := 1.0 - maxf(0.0, t - 0.8) * 4.0
	var nr := 10 if lq else 18
	for k in range(nr):
		var a := PI + PI * (float(k) + 0.5) / float(nr) + sin(t * 3.0) * 0.04
		var ln := (80.0 + 40.0 * float(k % 2)) * e
		var d := Vector2(cos(a), sin(a))
		var p1 := sc + d * R * 0.9 + d.orthogonal() * 4.0
		var p2 := sc + d * (R + ln)
		var p3 := sc + d * R * 0.9 - d.orthogonal() * 4.0
		for P in [p1, p2, p3]:
			pass
		p1.y = minf(p1.y, 0.0); p3.y = minf(p3.y, 0.0); p2.y = minf(p2.y, 0.0)
		s.draw_colored_polygon(PackedVector2Array([p1, p2, p3]), s._a(0.3 * al))
	var pts := PackedVector2Array()
	for i in range(28):
		var a := TAU * float(i) / 28.0
		var p := sc + Vector2(cos(a), sin(a)) * R
		p.y = minf(p.y, 0.0)
		pts.append(p)
	for L in [[1.5, 0.15], [1.2, 0.35], [1.0, 0.95]]:
		var pp := PackedVector2Array()
		for p in pts:
			pp.append(sc + (p - sc) * float(L[0]) + Vector2(0, 0))
		var cp := PackedVector2Array()
		for p in pp:
			cp.append(Vector2(p.x, minf(p.y, 0.0)))
		s.draw_colored_polygon(cp, s._mix(1.0 - float(L[1]), float(L[1]) * al) if L[0] < 1.1 else s._a(float(L[1]) * al))
	s.draw_line(Vector2(-120, 0), Vector2(120, 0), s._k(0.9 * al), 2.5)
	_ellarc(s, Vector2.ZERO, 30.0 + 110.0 * t, 8.0 + 36.0 * t, s._k(0.8 * (1.0 - t)), 3.0)
	_ellarc(s, Vector2.ZERO, 14.0 + 80.0 * t, 4.0 + 26.0 * t, s._a(0.8 * (1.0 - t)), 3.0)

## Phép Thánh Toàn Trị: thập tự lớn bay lên từ pháp trận, vòng dấu cộng nhỏ xoay quanh.
static func _allheal(s, t: float, lq: bool) -> void:
	var g := minf(1.0, t * 3.0)
	_ellarc(s, Vector2.ZERO, 96.0 * g, 30.0 * g, s._a(0.3), 10.0)
	_ellarc(s, Vector2.ZERO, 96.0 * g, 30.0 * g, s._a(0.85), 2.5)
	var n := 6 if lq else 10
	for k in range(n):
		var a := t * 2.0 + TAU * float(k) / float(n)
		var p := Vector2(cos(a) * 80.0 * g, sin(a) * 25.0 * g)
		var sz := 4.0 + 2.5 * (0.5 + 0.5 * sin(a))
		s._plus(p + Vector2(0, -3), sz, s._a(0.95), s._k(0.9))
	var y := lerpf(-4.0, -52.0, minf(1.0, t * 1.6))
	var al := 1.0 - maxf(0.0, t - 0.8) * 5.0
	_glow(s, Vector2(0, y), 62.0, al)
	var sz := 30.0 * minf(1.0, t * 2.5) * (1.0 + 0.05 * sin(t * 24.0))
	s._plus(Vector2(0, y), sz, s._a(0.95 * al), s._k(al))
	for k in range(8):
		var a := TAU * float(k) / 8.0 + t * 1.5
		var d := Vector2(cos(a), sin(a))
		s.draw_line(Vector2(0, y) + d * (sz + 6.0), Vector2(0, y) + d * (sz + 18.0 + 14.0 * t), s._k(0.7 * al), 2.0)

## Thánh Quang Hộ Thể: hai vòng sáng nghiêng xoay quanh người như con quay hồi chuyển.
static func _aura(s, t: float, lq: bool) -> void:
	var g := minf(1.0, t * 3.0)
	var c := Vector2(0, -2)
	_glow(s, c, 46.0 * g, 0.9)
	for r in range(2):
		var rot := (0.55 if r == 0 else -0.55) + sin(t * 4.0 + float(r)) * 0.08
		var sgn := 1.0 if r == 0 else -1.0
		s.draw_set_transform(c, rot, Vector2(1.0, 0.3))
		s.draw_arc(Vector2.ZERO, 40.0 * g, 0.0, TAU, 40, s._a(0.3), 6.0)
		s.draw_arc(Vector2.ZERO, 40.0 * g, 0.0, TAU, 40, s._a(0.9), 2.2)
		var ang := t * 9.0 * sgn
		s.draw_circle(Vector2(cos(ang), sin(ang)) * 40.0 * g, 3.8 / 0.3 * 0.3 + 1.5, s._k(1.0))
		s.draw_circle(Vector2(cos(ang + PI), sin(ang + PI)) * 40.0 * g, 3.0, s._k(0.9))
		_rst(s)
	var n := 5 if lq else 9
	for k in range(n):
		var x := -22.0 + 44.0 * float(k) / float(n - 1)
		var q := fposmod(t * 1.1 + float(k) * 0.19, 1.0)
		s.draw_line(Vector2(x, 28.0 - 70.0 * q), Vector2(x, 28.0 - 70.0 * q - 14.0), s._k(0.8 * sin(q * PI)), 2.2)
	_star4(s, Vector2(0, -50.0), 9.0 * g, s._k(0.9))

## Kết Giới Sinh Mệnh: mái vòm dây leo + lá + hoa mọc lên từ mặt đất.
static func _lifedome(s, t: float, lq: bool) -> void:
	var g := minf(1.0, t * 1.6)
	var gc: Color = s.col.lerp(Color(0.4, 0.95, 0.45), 0.55)
	var lc: Color = s.core.lerp(Color(0.85, 1.0, 0.7), 0.5)
	var R := 92.0
	_ellarc(s, Vector2.ZERO, R, R * 0.3, Color(gc.r, gc.g, gc.b, 0.25), 9.0)
	_ellarc(s, Vector2.ZERO, R, R * 0.3, Color(gc.r, gc.g, gc.b, 0.9), 2.5)
	s.draw_arc(Vector2.ZERO, R, PI, TAU, 40, Color(gc.r, gc.g, gc.b, 0.12 + 0.1 * g), 14.0)
	var nv := 5 if lq else 7
	for k in range(nv):
		var ph := PI * (float(k) + 0.5) / float(nv)
		var pts := PackedVector2Array()
		var steps := 14
		for i in range(steps + 1):
			var u := float(i) / float(steps) * g
			var a := PI + u * PI * 0.5
			var px := cos(ph) * R * (1.0 - sin(u * PI * 0.5 * 0.0)) * (1.0 - u * 0.55) + sin(u * 9.0 + ph * 3.0) * 4.0
			var py := -sin(u * PI * 0.5) * R * 0.95 * (0.6 + 0.4 * sin(ph))
			px = -cos(ph) * R * cos(u * PI * 0.5) * 1.0 + sin(u * 9.0 + ph * 3.0) * 4.0
			pts.append(Vector2(px, py * 0.9 + (R * 0.3 * sin(ph) * cos(u * PI * 0.5) * 0.0)))
			if i % 5 == 4:
				var side := 1.0 if (i / 4) % 2 == 0 else -1.0
				_leaf(s, Vector2(px, py * 0.9), -0.6 * side + float(i) * 0.1, 8.0, 2.6, Color(lc.r, lc.g, lc.b, 0.8))
		s.draw_polyline(pts, Color(gc.r, gc.g, gc.b, 0.95), 2.6)
		if g > 0.9:
			var tp: Vector2 = pts[pts.size() - 1]
			for p in range(5):
				var pa := TAU * float(p) / 5.0
				s.draw_circle(tp + Vector2(cos(pa), sin(pa)) * 4.0, 3.0, s._k(0.95))
			s.draw_circle(tp, 2.5, Color(1.0, 0.85, 0.3, 1.0))
	var n := 4 if lq else 8
	for k in range(n):
		var q := fposmod(t * 0.8 + float(k) * 0.131, 1.0)
		var x := (fposmod(float(k) * 0.618, 1.0) - 0.5) * 140.0
		s.draw_circle(Vector2(x, -4.0 - 60.0 * q), 2.2, Color(lc.r, lc.g, lc.b, sin(q * PI)))

## Giọt Thánh: giọt nước thánh lớn rơi xuống, toé gợn sóng và giọt nhỏ.
static func _holydrop(s, t: float, lq: bool) -> void:
	var fall := clampf(t / 0.38, 0.0, 1.0)
	var gy := 26.0
	if t < 0.4:
		var y := lerpf(-130.0, gy - 6.0, fall * fall)
		s.draw_line(Vector2(0, y - 70.0), Vector2(0, y - 24.0), s._a(0.3), 4.0)
		_glow(s, Vector2(0, y), 24.0, 1.0)
		s.draw_circle(Vector2(0, y), 11.0, s._a(0.9))
		s.draw_colored_polygon(PackedVector2Array([Vector2(-10.2, y - 4.0), Vector2(0, y - 28.0), Vector2(10.2, y - 4.0)]), s._a(0.9))
		s.draw_circle(Vector2(-4, y - 2), 3.5, s._k(0.95))
	else:
		var r := (t - 0.38) / 0.62
		var fa := 1.0 - r
		for j in range(3):
			var rr := clampf(r * 1.4 - float(j) * 0.2, 0.0, 1.0)
			if rr > 0.0: _shock(s, Vector2(0, gy), 8.0 + 52.0 * rr, 3.0 + 16.0 * rr, (1.0 - rr), 2.5)
		var n := 5 if lq else 10
		for k in range(n):
			var a := -PI * (0.1 + 0.8 * float(k) / float(n - 1))
			var v := 70.0 + float(k % 3) * 18.0
			var rt := minf(1.0, r * 1.6)
			var p := Vector2(cos(a) * v * rt, gy + sin(a) * v * rt + 130.0 * rt * rt)
			s.draw_circle(p, 3.0 * fa + 0.8, s._a(0.9 * fa))
			s.draw_circle(p + Vector2(-0.8, -0.8), 1.1, s._k(fa))
		_glow(s, Vector2(0, -6), 34.0, 0.8 * fa)
		s._plus(Vector2(0, -26.0 - 14.0 * r), 6.0, s._a(0.9 * fa), s._k(fa))

## Thánh Ấn: ấn triện thánh quang xoay bay tới rồi đóng dấu, toả sóng.
static func _seal(s, t: float, lq: bool) -> void:
	var u := minf(1.0, t / 0.6)
	var c := Vector2(lerpf(-60.0, 50.0, u), 0.0)
	var r := lerpf(14.0, 30.0, u)
	var rot := t * 8.0
	for j in range(1, 4):
		var tc := c - Vector2(14.0 * float(j), 0.0)
		s.draw_arc(tc, r * 0.9, 0.0, TAU, 24, s._a(0.3 / float(j)), 2.0)
	_glow(s, c, r * 2.0, 0.9)
	s.draw_arc(c, r, 0.0, TAU, 40, s._a(0.95), 3.0)
	s.draw_arc(c, r * 0.72, 0.0, TAU, 32, s._k(0.8), 1.4)
	s.draw_set_transform(c, rot, Vector2.ONE)
	for k in range(12):
		var a := TAU * float(k) / 12.0
		s.draw_line(Vector2(cos(a), sin(a)) * r * 1.05, Vector2(cos(a), sin(a)) * r * 1.22, s._a(0.9), 2.2)
	s._starpoly(8, r * 0.62, r * 0.28, s._a(0.55))
	_rst(s)
	s.draw_rect(Rect2(c.x - r * 0.14, c.y - r * 0.55, r * 0.28, r * 1.1), s._k(0.98))
	s.draw_rect(Rect2(c.x - r * 0.4, c.y - r * 0.16, r * 0.8, r * 0.32), s._k(0.98))
	if u >= 1.0:
		var q := (t - 0.6) / 0.4
		_shock(s, c, r + 70.0 * q, (r + 70.0 * q), 1.0 - q, 3.5)
		s.draw_arc(c, r * 0.4 + 100.0 * q, 0.0, TAU, 40, s._k(0.7 * (1.0 - q)), 2.0)
		_star4(s, c, 18.0 + 30.0 * q, s._k(0.9 * (1.0 - q)))

# ============================================================ TRIỆU HỒI SƯ
## Linh Tiễn: tia linh hồn lượn sóng, đầu quỷ hoả có mắt, đuôi ma mị.
static func _wisp_bolt(s, t: float, lq: bool) -> void:
	var x := -40.0 + 150.0 * t
	var seg := 8 if lq else 14
	for j in range(seg - 1, -1, -1):
		var u := float(j) / float(seg)
		var p := Vector2(x - 8.0 * float(j), sin(float(j) * 0.7 - t * 22.0) * 8.0 * u)
		s.draw_circle(p, 9.0 * (1.0 - u * 0.85), s._a(0.5 * (1.0 - u)))
		s.draw_circle(p, 5.5 * (1.0 - u * 0.85), s._mix(u, 0.8 * (1.0 - u * 0.6)))
	var h := Vector2(x, 0)
	_glow(s, h, 30.0, 0.9)
	s.draw_circle(h, 11.0, s._k(0.95))
	s.draw_colored_polygon(PackedVector2Array([h + Vector2(-8, -6), h + Vector2(-3, -17), h + Vector2(2, -7)]), s._k(0.9))
	s.draw_circle(h + Vector2(3, -3), 2.6, Color(0.05, 0.0, 0.12, 0.95))
	s.draw_circle(h + Vector2(3, 4), 2.6, Color(0.05, 0.0, 0.12, 0.95))
	for k in range(3 if lq else 5):
		var a := -t * 10.0 + TAU * float(k) / 5.0
		s.draw_circle(h + Vector2(cos(a) * 18.0, sin(a) * 12.0), 2.2, s._a(0.9))

## Linh Long Xung: rồng phương Đông uốn lượn lao tới, râu, sừng, gai lưng.
static func _dragon(s, t: float, lq: bool) -> void:
	var hx := -60.0 + 170.0 * t
	var n := 10 if lq else 17
	var ph := t * 15.0
	var pts: Array = []
	for j in range(n):
		var u := float(j) / float(n - 1)
		pts.append(Vector2(hx - 11.0 * float(j), sin(float(j) * 0.55 - ph) * (5.0 + 9.0 * u)))
	for j in range(n - 1, -1, -1):
		var u := float(j) / float(n - 1)
		var r := 10.0 - 7.0 * u
		var p: Vector2 = pts[j]
		s.draw_circle(p, r + 3.0, s._a(0.22 * (1.0 - u)))
		s.draw_circle(p, r, s._a(0.95 - 0.4 * u))
		s.draw_circle(p + Vector2(0, r * 0.4), r * 0.5, s._k(0.75 * (1.0 - u)))
		if j % 2 == 0 and j > 0:
			s.draw_colored_polygon(PackedVector2Array([p + Vector2(-3, -r), p + Vector2(3, -r), p + Vector2(0, -r - 7.0)]), s._k(0.85))
		if j % 4 == 2:
			s.draw_line(p + Vector2(0, r * 0.6), p + Vector2(-4.0, r * 0.6 + 9.0), s._a(0.9), 2.4)
	var h: Vector2 = pts[0]
	_glow(s, h + Vector2(16, 0), 26.0, 0.8)
	s.draw_colored_polygon(PackedVector2Array([h + Vector2(-8, -10), h + Vector2(10, -10), h + Vector2(26, -4), h + Vector2(24, 1), h + Vector2(-8, 3)]), s._a(0.98))
	s.draw_colored_polygon(PackedVector2Array([h + Vector2(-6, 3), h + Vector2(20, 2), h + Vector2(14, 9), h + Vector2(-6, 9)]), s._a(0.9))
	s.draw_circle(h + Vector2(3, -5), 2.6, s._k(1.0))
	s.draw_line(h + Vector2(-5, -10), h + Vector2(-20, -24), s._k(0.95), 3.0)
	s.draw_line(h + Vector2(0, -10), h + Vector2(-10, -26), s._k(0.85), 2.4)
	var wp := PackedVector2Array()
	for i in range(6):
		wp.append(h + Vector2(22.0 + 8.0 * float(i), 2.0 + sin(float(i) * 1.3 - ph * 0.5) * 5.0 + 3.0 * float(i)))
	s.draw_polyline(wp, s._k(0.85), 1.6)
	var tp := PackedVector2Array()
	for i in range(6):
		tp.append(h + Vector2(22.0 + 8.0 * float(i), -2.0 - sin(float(i) * 1.3 - ph * 0.5) * 5.0 - 3.0 * float(i)))
	s.draw_polyline(tp, s._k(0.85), 1.6)

## Vạn Linh Quy Tụ (vào) / Vạn Linh Bùng Nổ (ra): linh hồn xoáy vào tâm hoặc nổ bung ra, có đầu lâu khổng lồ.
static func _gather(s, t: float, lq: bool, out: bool) -> void:
	var c := Vector2(0, -16)
	var n := 10 if lq else (26 if out else 20)
	if out:
		var sk := minf(1.0, t * 3.0) * (1.0 - maxf(0.0, t - 0.55) * 2.0)
		if sk > 0.0:
			_glow(s, c, 50.0 * sk, sk * 0.5)
			var r := 30.0 * sk
			s.draw_circle(c, r, s._a(0.32 * sk))
			s.draw_rect(Rect2(c.x - r * 0.55, c.y + r * 0.6, r * 1.1, r * 0.7), s._a(0.32 * sk))
			s.draw_arc(c, r, 0.0, TAU, 28, s._k(sk), 2.4)
			s.draw_polyline(PackedVector2Array([c + Vector2(-r * 0.55, r * 0.6), c + Vector2(-r * 0.55, r * 1.3), c + Vector2(r * 0.55, r * 1.3), c + Vector2(r * 0.55, r * 0.6)]), s._k(sk), 2.0)
			for sx in [-1.0, 1.0]:
				s.draw_circle(c + Vector2(sx * r * 0.38, -r * 0.1), r * 0.27, s._k(0.9 * sk))
				s.draw_arc(c + Vector2(sx * r * 0.38, -r * 0.1), r * 0.27, 0.0, TAU, 12, s._k(sk), 1.5)
				s.draw_line(c + Vector2(sx * r * 0.2, r * 0.8), c + Vector2(sx * r * 0.2, r * 1.3), s._k(sk), 1.4)
			s.draw_polyline(PackedVector2Array([c + Vector2(0, r * 0.18), c + Vector2(-r * 0.1, r * 0.4), c + Vector2(r * 0.1, r * 0.4), c + Vector2(0, r * 0.18)]), s._k(sk), 1.6)
			s.draw_line(c + Vector2(0, r * 0.8), c + Vector2(0, r * 1.3), s._k(sk), 1.4)
		for k in range(n):
			var a := TAU * float(k) / float(n) + float(k % 3) * 0.2
			var q := clampf((t - 0.3) * 1.5, 0.0, 1.0)
			if q <= 0.0: continue
			var d := Vector2(cos(a), sin(a))
			var p := c + d * (14.0 + 150.0 * q) * Vector2(1.0, 0.8)
			_ghost(s, p, 6.0 + float(k % 3) * 1.5, d, 1.0 - q, t * 20.0 + float(k))
		if t > 0.3:
			var r2 := (t - 0.3) / 0.7
			_shock(s, c, 20.0 + 150.0 * r2, 20.0 + 150.0 * r2, 1.0 - r2, 4.0)
			_shock(s, Vector2(0, 26), 20.0 + 170.0 * r2, 6.0 + 50.0 * r2, 1.0 - r2, 3.0)
	else:
		var pull := clampf(t * 1.35, 0.0, 1.0)
		for k in range(n):
			var a0 := TAU * float(k) / float(n) + fposmod(float(k) * 0.618, 1.0)
			var R0 := 100.0 + 40.0 * fposmod(float(k) * 0.37, 1.0)
			var q := clampf(pull * 1.25 - 0.25 * fposmod(float(k) * 0.29, 1.0), 0.0, 1.0)
			var rr := R0 * pow(1.0 - q, 1.7)
			var a := a0 + q * 2.4
			var p := c + Vector2(cos(a), sin(a) * 0.8) * rr
			var dir := Vector2(-sin(a), cos(a) * 0.8) + Vector2(-cos(a), -sin(a)) * 0.6
			if q < 1.0: _ghost(s, p, 5.0 + float(k % 3), dir, 0.95, t * 20.0 + float(k))
		var g := clampf((t - 0.55) * 2.2, 0.0, 1.0)
		_glow(s, c, 22.0 + 40.0 * pull, 0.5 + 0.5 * pull)
		s.draw_circle(c, 10.0 * pull + 3.0, s._k(0.95))
		if t > 0.7:
			var r3 := (t - 0.7) / 0.3
			_shock(s, c, 14.0 + 80.0 * r3, 14.0 + 80.0 * r3, 1.0 - r3, 3.5)
			_star4(s, c, 12.0 + 36.0 * r3, s._k(1.0 - r3))
		_ellarc(s, Vector2(0, 28), 90.0 * (1.0 - pull * 0.5), 26.0, s._a(0.3 * g + 0.2), 2.0)

## Linh Thể Hộ Vệ: hiệp sĩ linh hồn mờ ảo cầm khiên và giáo đứng chắn phía trước.
static func _guardian(s, t: float, lq: bool) -> void:
	var rise := minf(1.0, t * 3.0)
	var fl := 0.82 + 0.18 * sin(t * 26.0)
	var al := rise * fl * (1.0 - maxf(0.0, t - 0.82) * 5.0)
	var b := Vector2(-48.0, 26.0 - 8.0 * (1.0 - rise))
	s.draw_set_transform(Vector2(-48.0, 26.0), 0.0, Vector2(1.4, 1.4))
	b = Vector2(0.0, -8.0 * (1.0 - rise))
	_glow(s, b + Vector2(0, -22), 48.0, al)
	var tail := PackedVector2Array()
	tail.append(b + Vector2(-14, -22))
	tail.append(b + Vector2(14, -22))
	for i in range(5):
		var u := float(i) / 4.0
		tail.append(b + Vector2(10.0 - 20.0 * u, 6.0 + sin(t * 18.0 + u * 7.0) * 3.0 + (4.0 if i % 2 == 1 else 0.0)))
	s.draw_colored_polygon(tail, s._a(0.7 * al))
	s.draw_colored_polygon(PackedVector2Array([b + Vector2(-12, -26), b + Vector2(12, -26), b + Vector2(9, -6), b + Vector2(-9, -6)]), s._k(0.8 * al))
	s.draw_line(b + Vector2(-8, -16), b + Vector2(8, -16), s._a(0.9 * al), 2.0)
	var hd := b + Vector2(0, -36)
	s.draw_circle(hd, 9.0, s._k(0.95 * al))
	s.draw_rect(Rect2(hd.x - 9.0, hd.y - 2.0, 18.0, 3.0), Color(0.05, 0.0, 0.12, al))
	s.draw_colored_polygon(PackedVector2Array([hd + Vector2(-2, -8), hd + Vector2(2, -8), hd + Vector2(-8, -24)]), s._a(0.95 * al))
	s.draw_line(b + Vector2(-16, 12), b + Vector2(-16, -64), s._k(al), 2.6)
	s.draw_colored_polygon(PackedVector2Array([b + Vector2(-20, -62), b + Vector2(-12, -62), b + Vector2(-16, -76)]), s._k(al))
	var sh := b + Vector2(18, -18)
	s.draw_colored_polygon(PackedVector2Array([sh + Vector2(-12, -18), sh + Vector2(12, -18), sh + Vector2(12, 0), sh + Vector2(0, 22), sh + Vector2(-12, 0)]), s._a(0.92 * al))
	s.draw_polyline(PackedVector2Array([sh + Vector2(-12, -18), sh + Vector2(12, -18), sh + Vector2(12, 0), sh + Vector2(0, 22), sh + Vector2(-12, 0), sh + Vector2(-12, -18)]), s._k(al), 1.8)
	s.draw_circle(sh + Vector2(0, -6), 4.0, s._k(al))
	for k in range(2 if lq else 4):
		var q := fposmod(t * 1.0 + float(k) * 0.25, 1.0)
		s.draw_circle(b + Vector2(-16.0 + 32.0 * fposmod(float(k) * 0.618, 1.0), 10.0 - 70.0 * q), 2.0, s._k(sin(q * PI) * al))
	_rst(s)

## Nổ Linh Lực: quả cầu linh lực phình ra rồi nổ, tia hồn toả ra khắp hướng.
static func _spiritblast(s, t: float, lq: bool) -> void:
	var c := Vector2(0, -6)
	if t < 0.28:
		var g := t / 0.28
		_glow(s, c, 12.0 + 40.0 * g, 1.0)
		s.draw_circle(c, 8.0 + 10.0 * g, s._k(0.95))
		for k in range(8):
			var a := TAU * float(k) / 8.0 - t * 18.0
			var rr := 60.0 * (1.0 - g)
			s.draw_circle(c + Vector2(cos(a), sin(a)) * rr, 2.8, s._a(0.95))
		return
	var r := (t - 0.28) / 0.72
	var fa := 1.0 - r
	_glow(s, c, 36.0 + 70.0 * r, fa)
	var n := 10 if lq else 16
	for k in range(n):
		var a := TAU * float(k) / float(n) + 0.2
		var d := Vector2(cos(a), sin(a))
		var L := 26.0 + 110.0 * minf(1.0, r * 1.5)
		var st := c + d * 14.0
		var en := c + d * L
		s.draw_line(st, en, s._a(0.5 * fa), 6.0)
		s.draw_line(st, en, s._k(fa), 2.0)
		s.draw_circle(en, 4.5 * fa + 1.0, s._k(fa))
		s.draw_circle(en, 8.0 * fa, s._a(0.4 * fa))
	_shock(s, c, 16.0 + 120.0 * r, 16.0 + 120.0 * r, fa, 4.0)
	_shock(s, Vector2(0, 30), 20.0 + 140.0 * r, 6.0 + 38.0 * r, fa, 3.0)
	_star4(s, c, 18.0 + 40.0 * (1.0 - r), s._k(fa))

## Hiệu Lệnh Triệu Hồi: lá cờ lệnh cắm xuống vẫy, xung lệnh toả ra từng vòng.
static func _banner(s, t: float, lq: bool) -> void:
	var g := minf(1.0, t * 3.5)
	var px := 26.0
	var top := 28.0 - 108.0 * g
	s.draw_line(Vector2(px, 28.0), Vector2(px, top), s._k(0.95), 3.5)
	s.draw_circle(Vector2(px, top), 4.5, s._a(0.95))
	_glow(s, Vector2(px + 20.0, top + 16.0), 34.0 * g, 0.7)
	var fp := PackedVector2Array()
	var fp2 := PackedVector2Array()
	var wd := 46.0 * g
	for i in range(9):
		var u := float(i) / 8.0
		var wv := sin(u * 6.0 - t * 18.0) * 5.0 * u
		fp.append(Vector2(px + wd * u, top + 2.0 + wv))
		fp2.append(Vector2(px + wd * u, top + 34.0 + wv + (u * 10.0 if u > 0.0 else 0.0) * 0.0))
	fp2.reverse()
	fp.append_array(fp2)
	s.draw_colored_polygon(fp, s._a(0.92))
	s.draw_polyline(fp, s._k(0.9), 1.5)
	var ec := Vector2(px + wd * 0.45, top + 18.0 + sin(0.45 * 6.0 - t * 18.0) * 2.0)
	s.draw_arc(ec, 8.0 * g, 0.0, TAU, 20, s._k(0.95), 2.0)
	s.draw_set_transform(ec, 0.0, Vector2.ONE)
	s._starpoly(5, 5.5 * g, 2.4 * g, s._k(0.95))
	_rst(s)
	var tp := Vector2(px, top)
	for k in range(3):
		var q := fposmod(t * 1.4 + float(k) * 0.33, 1.0)
		s.draw_arc(tp, 8.0 + 70.0 * q, 0.0, TAU, 32, s._a(0.7 * (1.0 - q)), 2.4)
	var n := 3 if lq else 6
	for k in range(n):
		var q := fposmod(t * 0.9 + float(k) * 0.17, 1.0)
		var a := TAU * float(k) / float(n)
		s.draw_circle(tp + Vector2(cos(a), sin(a)) * (60.0 * (1.0 - q)), 2.4, s._k(sin(q * PI)))

## Triệu Hồi Linh Thú: pháp trận triệu hồi, bóng sói linh hồn trồi lên giữa cột sáng.
static func _beast(s, t: float, lq: bool) -> void:
	var g := minf(1.0, t * 3.0)
	var R := 70.0 * g
	_ellarc(s, Vector2.ZERO, R, R * 0.32, s._a(0.25), 9.0)
	_ellarc(s, Vector2.ZERO, R, R * 0.32, s._a(0.9), 2.5)
	_ellarc(s, Vector2.ZERO, R * 0.66, R * 0.21, s._k(0.7), 1.5, 0.0, t * 5.0, t * 5.0 + 4.6)
	for k in range(8):
		var a := t * 2.0 + TAU * float(k) / 8.0
		s.draw_circle(Vector2(cos(a) * R * 0.82, sin(a) * R * 0.82 * 0.32), 2.4, s._k(0.9))
	var pw := 30.0 * minf(1.0, t * 2.0) * (1.0 - maxf(0.0, t - 0.7) * 2.0)
	s.draw_rect(Rect2(-pw, -90.0, pw * 2.0, 92.0), s._a(0.14))
	s.draw_rect(Rect2(-pw * 0.55, -90.0, pw * 1.1, 92.0), s._a(0.2))
	var e := clampf((t - 0.22) / 0.4, 0.0, 1.0)
	if e <= 0.0: return
	var al := e * (1.0 - maxf(0.0, t - 0.85) * 6.0)
	var by := 4.0 - 26.0 * e
	var wc := Vector2(0, by)
	_glow(s, wc + Vector2(0, -12), 46.0, al)
	_ell(s, wc + Vector2(-2, -14), 24.0, 11.0, s._a(0.95 * al))
	_ell(s, wc + Vector2(-2, -13), 21.0, 7.0, s._k(0.55 * al))
	var hd := wc + Vector2(24.0, -26.0)
	s.draw_circle(hd, 10.0, s._a(0.98 * al))
	s.draw_colored_polygon(PackedVector2Array([hd + Vector2(4, -4), hd + Vector2(22, 1), hd + Vector2(4, 8)]), s._a(0.98 * al))
	s.draw_colored_polygon(PackedVector2Array([hd + Vector2(-6, -7), hd + Vector2(-2, -22), hd + Vector2(3, -8)]), s._a(al))
	s.draw_colored_polygon(PackedVector2Array([hd + Vector2(1, -8), hd + Vector2(6, -21), hd + Vector2(9, -5)]), s._a(al))
	s.draw_circle(hd + Vector2(5, -2), 2.4, s._k(al))
	for lx in [-18.0, -8.0, 10.0, 20.0]:
		s.draw_line(wc + Vector2(lx, -6), wc + Vector2(lx + (3.0 if lx > 0.0 else -3.0), 14.0 + 4.0 * e), s._a(0.95 * al), 4.2)
	var tl := PackedVector2Array()
	for i in range(7):
		var u := float(i) / 6.0
		tl.append(wc + Vector2(-24.0 - 26.0 * u, -20.0 - 14.0 * sin(u * 2.4) + sin(t * 14.0 + u * 5.0) * 3.0))
	s.draw_polyline(tl, s._a(0.95 * al), 6.0)
	s.draw_polyline(tl, s._k(0.8 * al), 2.0)
	for k in range(3 if lq else 6):
		var q := fposmod(t * 1.3 + float(k) * 0.17, 1.0)
		s.draw_circle(wc + Vector2(-20.0 + 44.0 * fposmod(float(k) * 0.618, 1.0), -22.0 - 40.0 * q), 2.2, s._k(sin(q * PI) * al))

## Tiếng Gọi Linh Hồn: sóng âm vòng cung vang lên, các linh hồn bay vào hợp nhất với thân.
static func _soulcall(s, t: float, lq: bool) -> void:
	_glow(s, Vector2(0, -2), 44.0, 0.5 + 0.4 * sin(t * PI))
	for k in range(3):
		var q := fposmod(t * 1.5 + float(k) * 0.33, 1.0)
		var r := 20.0 + 80.0 * q
		s.draw_arc(Vector2(-10, -6), r, -0.9, 0.9, 20, s._a(0.8 * (1.0 - q)), 3.0)
		s.draw_arc(Vector2(10, -6), r, PI - 0.9, PI + 0.9, 20, s._a(0.8 * (1.0 - q)), 3.0)
	var n := 4 if lq else 7
	for k in range(n):
		var a0 := TAU * float(k) / float(n) + 0.4
		var q := clampf(t * 1.4 - 0.08 * float(k), 0.0, 1.0)
		if q >= 1.0: continue
		var rr := 96.0 * pow(1.0 - q, 1.4)
		var a := a0 + q * 1.8
		var p := Vector2(cos(a) * rr, -6.0 + sin(a) * rr * 0.7)
		var dir := (Vector2(0, -6) - p).normalized()
		_ghost(s, p, 6.0, dir, minf(1.0, (1.0 - q) * 3.0), t * 18.0 + float(k))
	if t > 0.6:
		var r2 := (t - 0.6) / 0.4
		s.draw_arc(Vector2(0, -6), 10.0 + 38.0 * r2, 0.0, TAU, 28, s._k(1.0 - r2), 2.5)
		s._plus(Vector2(0, -44.0 - 10.0 * r2), 6.0, s._a(1.0 - r2), s._k(1.0 - r2))

## Linh Giới Hộ Thân: cầu linh giới mờ, các linh hồn xoay quanh trên quỹ đạo nghiêng.
static func _soulorbit(s, t: float, lq: bool) -> void:
	var g := minf(1.0, t * 3.0)
	var c := Vector2(0, -4)
	for i in range(5):
		var u := float(i) / 4.0
		s.draw_circle(c, 46.0 * g * (1.0 - u * 0.5), s._mix(u, 0.035 + 0.02 * u))
	s.draw_arc(c, 46.0 * g, 0.0, TAU, 40, s._a(0.7), 2.0)
	_ellarc(s, c, 44.0 * g, 14.0 * g, s._k(0.5), 1.4, -0.3)
	var n := 3 if lq else 5
	var items: Array = []
	for k in range(n):
		var a := t * 6.0 + TAU * float(k) / float(n)
		items.append([sin(a), a])
	items.sort_custom(func(x, y): return x[0] < y[0])
	for it in items:
		var a: float = it[1]
		var dep: float = it[0]
		var p := c + Vector2(cos(a) * 40.0, dep * 14.0 - cos(a) * 3.0).rotated(-0.3)
		var d := Vector2(-sin(a), cos(a) * 0.35).rotated(-0.3)
		_ghost(s, p, 6.5 + 2.5 * dep, d, 0.7 + 0.3 * dep, t * 20.0 + a)

## Linh Điểu Truy Kích: chim linh hồn săn mồi lao tới, để lại bóng chim mờ và lông.
static func _spiritbird(s, t: float, lq: bool) -> void:
	var x := -50.0 + 160.0 * t
	var y := sin(t * 11.0) * 8.0
	for j in range(1, 4 if lq else 5):
		_bird(s, Vector2(x - 30.0 * float(j), y * (1.0 - 0.1 * float(j))), 16.0, sin(t * 26.0 - float(j)), 0.28 / float(j) * 1.6, true)
	_glow(s, Vector2(x, y), 40.0, 0.7)
	_bird(s, Vector2(x, y), 18.0, sin(t * 26.0), 0.98, true)
	for k in range(3 if lq else 6):
		var q := fposmod(t * 2.0 + float(k) * 0.17, 1.0)
		_leaf(s, Vector2(x - 20.0 - 60.0 * q, y + (float(k) - 2.5) * 6.0), PI + 0.3 * sin(float(k)), 8.0, 2.0, s._k((1.0 - q) * 0.9))

## Cộng Hưởng Linh Thú: dấu chân thú khổng lồ cộng hưởng, vòng sóng lan, bốn linh thể nối nhau.
static func _resonance(s, t: float, lq: bool) -> void:
	var c := Vector2(0, -4)
	var pul := 1.0 + 0.12 * sin(t * 22.0)
	for k in range(3):
		var q := fposmod(t * 1.3 + float(k) * 0.33, 1.0)
		s.draw_arc(c, 14.0 + 66.0 * q, 0.0, TAU, 36, s._a(0.8 * (1.0 - q)), 3.0)
		s.draw_arc(c, 8.0 + 44.0 * q, 0.0, TAU, 32, s._k(0.5 * (1.0 - q)), 1.5)
	_glow(s, c, 40.0 * pul, 0.7)
	_ell(s, c + Vector2(0, 8), 13.0 * pul, 10.0 * pul, s._a(0.95))
	for k in range(4):
		var a := -PI * 0.5 + (float(k) - 1.5) * 0.52
		var tp := c + Vector2(cos(a) * 21.0 * pul, sin(a) * 21.0 * pul - 5.0)
		_ell(s, tp, 5.2 * pul, 6.8 * pul, s._a(0.95))
		_ell(s, tp, 2.6, 3.4, s._k(0.8))
	_ell(s, c + Vector2(0, 8), 7.0, 5.0, s._k(0.75))
	var pts: Array = []
	for k in range(4):
		var a := t * 3.0 + TAU * float(k) / 4.0
		var p := c + Vector2(cos(a) * 52.0, sin(a) * 30.0)
		pts.append(p)
	for k in range(4):
		var p1: Vector2 = pts[k]
		var p2: Vector2 = pts[(k + 1) % 4]
		s.draw_line(p1, p2, s._a(0.45), 1.6)
		_ghost(s, p1, 5.0, (p2 - p1).normalized(), 0.95, t * 16.0 + float(k))

# ============================================================ CHUNG
## Ý Chí Bất Diệt: ngọn lửa ý chí bùng quanh người, xích gãy văng ra, sao ý chí trên đầu.
static func _will(s, t: float, lq: bool) -> void:
	var g := minf(1.0, t * 3.0)
	_glow(s, Vector2(0, -6), 60.0 * g, 0.5)
	_ellarc(s, Vector2(0, 26), 20.0 + 64.0 * g, 6.0 + 20.0 * g, s._a(0.8 * (1.0 - t * 0.5)), 3.0)
	var nf := 4 if lq else 7
	for k in range(nf):
		var x := -34.0 + 68.0 * float(k) / float(nf - 1)
		var hh := (62.0 - absf(x) * 0.7) * g * (0.85 + 0.15 * sin(t * 20.0 + float(k) * 1.7))
		_flame(s, Vector2(x, 28.0), hh, 8.0, 0.3)
	var sy := -64.0 - 4.0 * sin(t * 9.0)
	s.draw_set_transform(Vector2(0, sy), t * 2.0, Vector2.ONE)
	s._starpoly(8, 15.0 * g, 6.5 * g, s._k(0.95))
	_rst(s)
	_glow(s, Vector2(0, sy), 24.0, 0.8)
	var nl := 3 if lq else 6
	for k in range(nl):
		var q := clampf((t - 0.15) * 1.2, 0.0, 1.0)
		if q <= 0.0: break
		var a := -PI * (0.1 + 0.8 * float(k) / float(nl - 1)) + (PI if k % 2 == 1 else 0.0) * 0.0
		var side := 1.0 if k % 2 == 0 else -1.0
		var v := 70.0 + 14.0 * float(k)
		var p := Vector2(side * cos(a * 0.5) * v * q * 0.9, -20.0 + sin(a) * v * q + 150.0 * q * q * 0.5)
		s.draw_set_transform(p, q * 6.0 * side + float(k), Vector2(1.0, 0.6))
		s.draw_arc(Vector2.ZERO, 6.0, 0.0, TAU, 14, s._k(0.95 * (1.0 - q * 0.7)), 2.4)
		_rst(s)

## Hư Không Tuyệt Trảm: vết nứt hư không đen khổng lồ xé chéo không gian, mảnh vỡ bay ra.
static func _voidslash(s, t: float, lq: bool) -> void:
	var open := minf(1.0, t / 0.3)
	var close := 1.0 - maxf(0.0, t - 0.65) / 0.35
	var w := 24.0 * sin(open * PI * 0.5) * close
	var a := Vector2(-96, -90)
	var b := Vector2(96, 90)
	var q := minf(1.0, t * 4.0)
	var e := a.lerp(b, q)
	var d := (b - a).normalized()
	var nr := d.orthogonal()
	var m := a.lerp(e, 0.5)
	var poly := PackedVector2Array([a, m + nr * w, e, m - nr * w])
	s.draw_colored_polygon(poly, Color(0.02, 0.0, 0.06, 0.95 * close))
	_glow(s, m, 80.0 * close, 0.5)
	s.draw_polyline(PackedVector2Array([a, m + nr * w, e]), s._a(0.95), 3.0)
	s.draw_polyline(PackedVector2Array([a, m - nr * w, e]), s._a(0.95), 3.0)
	s.draw_polyline(PackedVector2Array([a, m + nr * w, e]), s._k(0.9), 1.2)
	s.draw_polyline(PackedVector2Array([a, m - nr * w, e]), s._k(0.9), 1.2)
	var ns := 4 if lq else 9
	for k in range(ns):
		var u := fposmod(float(k) * 0.618 + 0.1, 1.0)
		var p := a.lerp(e, u) + nr * (fposmod(float(k) * 0.37, 1.0) - 0.5) * w * 1.4
		s.draw_circle(p, 1.6, Color(1, 1, 1, 0.9 * close))
	var nk := 5 if lq else 10
	for k in range(nk):
		var u := fposmod(float(k) * 0.381 + 0.07, 1.0)
		var side := 1.0 if k % 2 == 0 else -1.0
		var qq := clampf((t - 0.15) * 1.3, 0.0, 1.0)
		var p := a.lerp(b, u) + nr * side * (w + 70.0 * qq * (0.6 + 0.4 * fposmod(float(k) * 0.7, 1.0)))
		var sz := 3.0 + float(k % 3) * 2.0
		s.draw_set_transform(p, qq * 6.0 + float(k), Vector2.ONE)
		s.draw_colored_polygon(PackedVector2Array([Vector2(-sz, -sz * 0.6), Vector2(sz, -sz * 0.2), Vector2(sz * 0.3, sz)]), s._a(0.95 * (1.0 - qq * 0.6)))
		_rst(s)
	for k in range(4):
		var u := 0.3 + 0.12 * float(k)
		var p0 := a.lerp(b, u)
		s.draw_line(p0, p0 + nr * (30.0 + 20.0 * float(k % 2)) * (1.0 if k % 2 == 0 else -1.0) * open, s._a(0.7 * close), 1.6)
	if t > 0.2 and t < 0.5:
		var f := 1.0 - (t - 0.2) / 0.3
		s._streak(a + (b - a) * 0.0, b, 20.0 * f)

## Sinh Tử Đồng Quy: thái cực đồ xoay, hai dòng sáng và tối xoáy tụ vào tâm.
static func _taiji(s, t: float, lq: bool) -> void:
	var c := Vector2(0, -6)
	var g := minf(1.0, t * 3.0)
	var R := 36.0 * g
	var dark := Color(0.08, 0.02, 0.16, 0.96)
	var light: Color = s._k(0.96)
	for arm in range(3):
		for sd in range(2):
			var pts := PackedVector2Array()
			var n := 14 if lq else 22
			for i in range(n):
				var u := float(i) / float(n - 1)
				var rr := lerpf(130.0, R * 1.1, minf(1.0, u + t * 0.4 * 0.0)) * (1.0 - 0.0)
				var a := float(arm) * TAU / 3.0 + float(sd) * PI + (1.0 - u) * 2.6 - t * 3.0
				pts.append(c + Vector2(cos(a), sin(a) * 0.8) * lerpf(130.0, R * 1.15, u))
			s.draw_polyline(pts, light if sd == 0 else dark, 3.0)
			s.draw_polyline(pts, s._a(0.5) if sd == 0 else Color(0.4, 0.1, 0.6, 0.5), 7.0)
	_glow(s, c, R * 2.0, 0.7)
	var rot := t * 7.0
	s.draw_set_transform(c, rot, Vector2.ONE)
	s.draw_circle(Vector2.ZERO, R, light)
	var hp := PackedVector2Array()
	for i in range(21):
		var a := -PI * 0.5 + PI * float(i) / 20.0
		hp.append(Vector2(cos(a), sin(a)) * R)
	s.draw_colored_polygon(hp, dark)
	s.draw_circle(Vector2(0, -R * 0.5), R * 0.5, light)
	s.draw_circle(Vector2(0, R * 0.5), R * 0.5, dark)
	s.draw_circle(Vector2(0, -R * 0.5), R * 0.14, dark)
	s.draw_circle(Vector2(0, R * 0.5), R * 0.14, light)
	s.draw_arc(Vector2.ZERO, R, 0.0, TAU, 40, s._a(1.0), 2.5)
	_rst(s)
	if t > 0.7:
		var r := (t - 0.7) / 0.3
		_shock(s, c, R + 90.0 * r, R + 90.0 * r, 1.0 - r, 4.0)
		_star4(s, c, 20.0 + 40.0 * r, s._k(1.0 - r))

# ============================================================ TOÀN NĂNG
## Vạn Pháp Quy Nhất: sáu viên ngọc bảy sắc xoáy vào tâm hợp nhất, bùng nổ cầu vồng.
static func _allone(s, t: float, lq: bool) -> void:
	var c := Vector2(0, -8)
	var pull := clampf(t / 0.55, 0.0, 1.0)
	for k in range(6):
		var col := Color.from_hsv(float(k) / 6.0, 0.7, 1.0)
		var a0 := TAU * float(k) / 6.0
		var trail := 6 if lq else 10
		for j in range(trail, -1, -1):
			var qq := maxf(0.0, pull - 0.025 * float(j))
			var rr := 105.0 * pow(1.0 - qq, 1.5)
			var a := a0 + qq * 5.0
			var p := c + Vector2(cos(a) * rr, sin(a) * rr * 0.8)
			if j == 0:
				if pull < 1.0: _orb(s, p, 7.0, col, 1.0)
			else:
				s.draw_circle(p, 5.0 * (1.0 - float(j) / float(trail + 1)), Color(col.r, col.g, col.b, 0.45 * (1.0 - float(j) / float(trail + 1))))
	_glow(s, c, 20.0 + 40.0 * pull, 0.4 + 0.6 * pull)
	s.draw_circle(c, 6.0 + 10.0 * pull, Color(1, 1, 1, 0.5 + 0.5 * pull))
	if t > 0.55:
		var r := (t - 0.55) / 0.45
		var fa := 1.0 - r
		for k in range(6):
			var col := Color.from_hsv(float(k) / 6.0, 0.6, 1.0)
			s.draw_arc(c, 10.0 + (60.0 + 14.0 * float(k)) * r, 0.0, TAU, 40, Color(col.r, col.g, col.b, fa), 4.0)
		var nr := 8 if lq else 14
		for k in range(nr):
			var a := TAU * float(k) / float(nr)
			var d := Vector2(cos(a), sin(a))
			var col2 := Color.from_hsv(float(k) / float(nr), 0.6, 1.0)
			s.draw_line(c + d * 14.0, c + d * (30.0 + 110.0 * r), Color(col2.r, col2.g, col2.b, fa), 3.0)
		_star4(s, c, 24.0 + 60.0 * (1.0 - r), Color(1, 1, 1, fa))

## Thức Tỉnh Tối Thượng: cột sáng vọt lên, con mắt thức tỉnh mở ra trên đầu, tia toả.
static func _awaken(s, t: float, lq: bool) -> void:
	var g := minf(1.0, t * 3.0)
	for L in [[1.0, 0.12], [0.6, 0.25], [0.28, 0.6]]:
		var w: float = 24.0 * L[0] * g
		s.draw_rect(Rect2(-w, -120.0, w * 2.0, 150.0), s._a(float(L[1])) if L[0] > 0.5 else s._k(float(L[1])))
	_glow(s, Vector2(0, -4), 56.0 * g, 0.9)
	_ellarc(s, Vector2(0, 26), 20.0 + 60.0 * g, 6.0 + 18.0 * g, s._a(0.8 * (1.0 - t * 0.6)), 3.0)
	var ec := Vector2(0, -74)
	var open := clampf((t - 0.15) * 3.0, 0.0, 1.0)
	for k in range(14):
		var a := TAU * float(k) / 14.0 + t * 1.0
		var d := Vector2(cos(a), sin(a))
		s.draw_line(ec + d * (26.0 + 4.0 * float(k % 2)) * 1.0, ec + d * (40.0 + 16.0 * float(k % 2)) * open, s._k(0.85 * open), 2.0)
	if open > 0.0:
		var h := 13.0 * open
		var top := PackedVector2Array()
		var bot := PackedVector2Array()
		for i in range(9):
			var x := -26.0 + 52.0 * float(i) / 8.0
			var f := 1.0 - pow(x / 26.0, 2.0)
			top.append(ec + Vector2(x, -h * f))
			bot.append(ec + Vector2(x, h * f))
		bot.reverse()
		top.append_array(bot)
		s.draw_colored_polygon(top, s._k(0.95))
		s.draw_polyline(top, s._a(1.0), 2.2)
		s.draw_circle(ec, 9.0 * open, s._a(0.95))
		s.draw_circle(ec, 4.5 * open, Color(0.05, 0.0, 0.12, 0.95))
		s.draw_circle(ec + Vector2(-2, -2), 1.8, Color(1, 1, 1, 0.95))
	var n := 4 if lq else 8
	for k in range(n):
		var q := fposmod(t * 1.2 + float(k) * 0.131, 1.0)
		var x := -18.0 + 36.0 * fposmod(float(k) * 0.618, 1.0)
		_star4(s, Vector2(x, 24.0 - 100.0 * q), 3.5, s._k(sin(q * PI)))

## Hợp Nhất Nguyên Tố: lửa, nước, gió, đất xoáy quanh rồi va chạm thành quả cầu hợp nhất.
static func _elemfuse(s, t: float, lq: bool) -> void:
	var c := Vector2(0, -22)
	var cols := [Color(1.0, 0.45, 0.15), Color(0.3, 0.65, 1.0), Color(0.55, 1.0, 0.7), Color(0.85, 0.65, 0.3)]
	var pull := clampf(t / 0.55, 0.0, 1.0)
	_ellarc(s, Vector2.ZERO, 90.0, 28.0, s._a(0.25), 8.0)
	_ellarc(s, Vector2.ZERO, 90.0, 28.0, s._a(0.7), 2.0)
	for k in range(4):
		var col: Color = cols[k]
		var a := t * 7.0 + TAU * float(k) / 4.0
		var rr := 72.0 * (1.0 - pow(pull, 2.0))
		var p := c + Vector2(cos(a) * rr, sin(a) * rr * 0.55)
		if pull < 1.0:
			for j in range(1, 4):
				var pa := a - 0.18 * float(j)
				s.draw_circle(c + Vector2(cos(pa) * rr, sin(pa) * rr * 0.55), 7.0 - 1.5 * float(j), Color(col.r, col.g, col.b, 0.5 - 0.12 * float(j)))
			_orb(s, p, 9.0, col, 1.0)
			match k:
				0: s.draw_colored_polygon(PackedVector2Array([p + Vector2(-4, 4), p + Vector2(0, -8), p + Vector2(4, 4)]), Color(1, 1, 0.8, 0.9))
				1: s.draw_circle(p + Vector2(0, 1), 3.0, Color(1, 1, 1, 0.9))
				2: s.draw_arc(p, 4.0, 0.0, 4.5, 8, Color(1, 1, 1, 0.9), 1.6)
				3: s.draw_rect(Rect2(p.x - 3, p.y - 3, 6, 6), Color(1, 1, 0.8, 0.9))
	if t > 0.5:
		var r := clampf((t - 0.5) / 0.5, 0.0, 1.0)
		var fa := 1.0 - maxf(0.0, r - 0.5) * 2.0
		_glow(s, c, 26.0 + 50.0 * r, fa)
		s.draw_circle(c, 12.0 + 8.0 * sin(r * PI), Color(1, 1, 1, 0.9 * fa))
		for k in range(4):
			var col: Color = cols[k]
			var a := TAU * float(k) / 4.0 + r * 2.0
			var d := Vector2(cos(a), sin(a))
			s.draw_line(c + d * 10.0, c + d * (30.0 + 90.0 * r), Color(col.r, col.g, col.b, fa), 6.0)
			s.draw_arc(c, 12.0 + (50.0 + 16.0 * float(k)) * r, a - 0.6, a + 0.6, 12, Color(col.r, col.g, col.b, fa), 4.0)
		_shock(s, Vector2.ZERO, 20.0 + 130.0 * r, 6.0 + 40.0 * r, 1.0 - r, 4.0)

## Dòng Chảy Toàn Năng: ba dòng năng lượng uốn lượn chảy ngang quanh người.
static func _flow(s, t: float, lq: bool) -> void:
	var g := minf(1.0, t * 3.0)
	_glow(s, Vector2(0, -4), 40.0, 0.6)
	for r in range(3):
		var yo := -22.0 + 22.0 * float(r)
		var pts := PackedVector2Array()
		var n := 16 if lq else 28
		for i in range(n):
			var u := float(i) / float(n - 1)
			var x := -62.0 + 124.0 * u
			var y := yo + sin(u * 9.0 - t * 14.0 + float(r) * 2.1) * 8.0 * sin(u * PI)
			pts.append(Vector2(x, y))
		var col: Color = s._a(0.9) if r != 1 else s._k(0.95)
		s.draw_polyline(pts, s._a(0.25 * g), 9.0)
		s.draw_polyline(pts, col, 3.0)
		for k in range(3):
			var q := fposmod(t * 1.6 + float(k) * 0.33 + float(r) * 0.11, 1.0)
			var idx := int(q * float(n - 1))
			var p: Vector2 = pts[idx]
			s.draw_colored_polygon(PackedVector2Array([p + Vector2(-5, -4), p + Vector2(4, 0), p + Vector2(-5, 4)]), s._k(0.95 * sin(q * PI)))
	var a := t * 8.0
	for k in range(2):
		var ang := a + float(k) * PI
		s.draw_circle(Vector2(cos(ang) * 46.0, sin(ang) * 14.0 - 4.0), 3.5, s._k(0.95))
	_ellarc(s, Vector2(0, 26), 30.0 * g, 8.0 * g, s._a(0.6), 2.0)

## Thế Cân Bằng: cán cân công lý lắc rồi cân bằng, hai viên ngọc đối nghịch.
static func _balance(s, t: float, lq: bool) -> void:
	var g := minf(1.0, t * 3.0)
	var c := Vector2(0, -34)
	var tilt := 0.5 * cos(t * 11.0) * (1.0 - t) * (1.0 - t * 0.0)
	var L := 34.0 * g
	_glow(s, c, 50.0 * g, 0.7)
	s.draw_line(c, c + Vector2(0, 38), s._a(0.95), 3.0)
	s.draw_arc(c + Vector2(0, 40), 10.0, PI, TAU, 10, s._a(0.95), 3.0)
	s.draw_circle(c, 4.0, s._k(0.95))
	var e1 := c + Vector2(-cos(tilt), -sin(tilt)) * L
	var e2 := c + Vector2(cos(tilt), sin(tilt)) * L
	s.draw_line(e1, e2, s._k(0.98), 3.2)
	s.draw_line(e1, e2, s._a(0.6), 6.0)
	var cols := [Color(1.0, 0.5, 0.3), Color(0.4, 0.7, 1.0)]
	var ends := [e1, e2]
	for i in range(2):
		var e: Vector2 = ends[i]
		var pc := e + Vector2(0, 24.0 * g)
		s.draw_line(e, pc + Vector2(-12, 0), s._k(0.7), 1.2)
		s.draw_line(e, pc + Vector2(12, 0), s._k(0.7), 1.2)
		s.draw_arc(pc, 12.0, 0.0, PI, 12, s._a(0.95), 3.0)
		_orb(s, pc + Vector2(0, -7), 5.0, cols[i], 1.0)
	if t > 0.65:
		var r := (t - 0.65) / 0.35
		_star4(s, c, 10.0 + 24.0 * r, s._k(1.0 - r))
		_shock(s, c, 10.0 + 50.0 * r, 10.0 + 50.0 * r, 1.0 - r, 2.5)
	var n := 3 if lq else 6
	for k in range(n):
		var q := fposmod(t * 0.9 + float(k) * 0.17, 1.0)
		var a := TAU * float(k) / float(n)
		s.draw_circle(c + Vector2(cos(a), sin(a)) * (30.0 + 20.0 * q), 2.0, s._k(sin(q * PI)))

## Tinh Lực Dồi Dào: trái tim sinh lực đập nhịp, tia sao phun lên như đài phun.
static func _vigor(s, t: float, lq: bool) -> void:
	var g := minf(1.0, t * 3.0)
	var pulse := 1.0 + 0.16 * pow(maxf(0.0, sin(t * 20.0)), 2.0)
	var c := Vector2(0, -8)
	_glow(s, c, 48.0 * g * pulse, 0.9)
	for k in range(3):
		var q := fposmod(t * 1.5 + float(k) * 0.33, 1.0)
		s.draw_arc(c, 14.0 + 50.0 * q, 0.0, TAU, 32, s._a(0.8 * (1.0 - q)), 2.5)
	_heart(s, c, 20.0 * g * pulse, s._a(0.55))
	_heart(s, c, 17.0 * g * pulse, s._mix(0.4, 0.95))
	_heart(s, c + Vector2(-3, -3), 7.0 * g * pulse, s._k(0.85))
	var n := 8 if lq else 16
	for k in range(n):
		var q := fposmod(t * 1.3 + float(k) * 0.0625, 1.0)
		var sp := (fposmod(float(k) * 0.618, 1.0) - 0.5) * 2.0
		var p := Vector2(sp * 46.0 * q, 28.0 - 100.0 * q + 56.0 * q * q)
		_star4(s, p, 3.0 + float(k % 3) * 1.2, s._k(sin(q * PI)))

## Thủ Ấn Toàn Năng: bàn tay kết ấn trong vòng hoa sen xoay, đẩy tới tạo sóng.
static func _palm(s, t: float, lq: bool) -> void:
	var u := minf(1.0, t / 0.65)
	var c := Vector2(lerpf(-50.0, 50.0, u), 0.0)
	var sc := lerpf(0.7, 1.35, u)
	for j in range(1, 4):
		s.draw_circle(c - Vector2(16.0 * float(j), 0.0), 18.0 * sc, s._a(0.18 / float(j)))
	_glow(s, c, 44.0 * sc, 0.9)
	s.draw_set_transform(c, t * 4.0, Vector2(sc, sc))
	for k in range(8):
		var a := TAU * float(k) / 8.0
		_leaf(s, Vector2(cos(a), sin(a)) * 18.0, a, 18.0, 5.0, s._a(0.7))
	s.draw_arc(Vector2.ZERO, 30.0, 0.0, TAU, 32, s._k(0.8), 1.5)
	s.draw_set_transform(c, 0.0, Vector2(sc, sc))
	s.draw_circle(Vector2(0, 6), 11.0, s._k(0.97))
	for k in range(4):
		var a := -PI * 0.5 + (float(k) - 1.5) * 0.36
		var ln := 20.0 - 3.0 * absf(float(k) - 1.5) + 4.0
		s.draw_line(Vector2(cos(a), sin(a)) * 6.0 + Vector2(0, 2), Vector2(cos(a), sin(a)) * (6.0 + ln) + Vector2(0, 2), s._k(0.97), 5.0)
	s.draw_line(Vector2(-8, 8), Vector2(-20, -3), s._k(0.97), 5.0)
	s.draw_circle(Vector2(0, 6), 5.0, s._a(0.8))
	_rst(s)
	if u >= 1.0:
		var q := (t - 0.65) / 0.35
		_shock(s, c, 20.0 + 70.0 * q, 20.0 + 70.0 * q, 1.0 - q, 3.5)
		_star4(s, c, 10.0 + 36.0 * q, s._k(1.0 - q))

## Trảm Hợp Nhất: ba nhát chém ba sắc từ ba hướng giao nhau rồi hợp thành sao sáng.
static func _tripleslash(s, t: float, lq: bool) -> void:
	var h0: float = s.col.h
	var dirs := [Vector2(-1, -0.9), Vector2(-1, 0.9), Vector2(-1.0, 0.0)]
	for i in range(3):
		var cc := Color.from_hsv(fposmod(h0 + float(i) * 0.33, 1.0), 0.7, 1.0)
		var q := clampf(t * 2.4 - 0.18 * float(i), 0.0, 1.0)
		var d: Vector2 = dirs[i].normalized()
		var a: Vector2 = -d * 86.0
		var b: Vector2 = d * 86.0
		var e := a.lerp(b, q)
		var fa := 1.0 - clampf((t - 0.55) * 3.0, 0.0, 1.0)
		if q > 0.0 and fa > 0.0:
			var nr := d.orthogonal()
			var m := a.lerp(e, 0.4)
			var w := 14.0
			s.draw_colored_polygon(PackedVector2Array([a, m + nr * w * 0.7, e, m - nr * w * 0.7]), Color(cc.r, cc.g, cc.b, 0.35 * fa))
			s.draw_colored_polygon(PackedVector2Array([a, m + nr * w * 0.3, e, m - nr * w * 0.3]), Color(cc.r, cc.g, cc.b, 0.95 * fa))
			s.draw_line(a, e, Color(1, 1, 1, fa), 1.5)
			s.draw_circle(e, 4.0, Color(1, 1, 1, fa))
	if t > 0.5:
		var r := (t - 0.5) / 0.5
		var fa2 := 1.0 - r
		_glow(s, Vector2.ZERO, 40.0 + 30.0 * r, fa2)
		s.draw_set_transform(Vector2.ZERO, 0.3, Vector2.ONE)
		s._starpoly(6, 20.0 + 70.0 * (1.0 - r * 0.3), 5.0, Color(1, 1, 1, 0.95 * fa2))
		_rst(s)
		s.draw_arc(Vector2.ZERO, 14.0 + 80.0 * r, 0.0, TAU, 32, s._k(fa2), 3.5)
		if not lq:
			for k in range(8):
				var a := TAU * float(k) / 8.0
				s.draw_line(Vector2(cos(a), sin(a)) * 20.0, Vector2(cos(a), sin(a)) * (20.0 + 70.0 * r), s._a(fa2), 2.0)
