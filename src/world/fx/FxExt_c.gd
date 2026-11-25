extends RefCounted
## Hiệu ứng kỹ năng riêng (nhóm c): pháp sư (phap_su) + tử linh thuật sư (tu_linh_thuat_su).
## Vẽ lên node `s` (Node2D đang trong _draw): s.draw_*, s._a(alpha) màu chính, s._k(alpha) màu lõi, s._mix(u, a), s._rng, s.vs.
## IDS: id kỹ năng -> sig. CFG: sig -> {"place": "front"|"body"|"ground"|"far", "dur": giây, "nopop": bool, "rumble": số}.
## (ps37 Lôi Cầu Xoáy giữ nguyên ở hệ thống cũ.) Tham số `s` để không kiểu để gọi hàm động của node vẽ.
const IDS := {
	"ps25": "c_thundersnake",
	"ps27": "c_fireboom",
	"tn8": "c_fireball",
	"ps30": "c_firewall",
	"ps32": "c_icecircle",
	"tn3": "c_iceprison",
	"tn1": "c_icewave",
	"tn6": "c_iceburst",
	"ulPhap2": "c_frozensea",
	"ps35": "c_crystalguard",
	"tn4": "c_energyshield",
	"ps38": "c_restoremoon",
	"tn2": "c_healcross",
	"ps40": "c_elemstorm",
	"ps45": "c_heavenearth",
	"ps42": "c_teleport",
	"tn10": "c_elemblink",
	"tn11": "c_hellfire",
	"tn5": "c_meteor",
	"tn7": "c_emberburst",
	"tn9": "c_piercebolt",
	"ulPhap1": "c_thunderlord",
	"ulPhapSuper": "c_forbidden",
	"nl1": "c_witherskull",
	"nl8": "c_soulchains",
	"nl10": "c_soulchainblast",
	"nl6": "c_soulsplit",
	"nl11": "c_deathmist",
	"nl2": "c_shadowsummon",
	"nl3": "c_soulsiphon",
	"nl4": "c_phantomarmy",
	"nl5": "c_netherportal",
	"nl7": "c_demonclaw",
	"nl9": "c_soulward",
	"ulLinh2": "c_ghosttide",
	"ulTuLinhDungHop": "c_soulfusion",
}
const CFG := {
	"c_thundersnake": {"place": "front", "dur": 0.8},
	"c_fireboom": {"place": "front", "dur": 0.9, "rumble": 2.0},
	"c_fireball": {"place": "front", "dur": 0.75},
	"c_firewall": {"place": "ground", "dur": 1.0, "nopop": true},
	"c_icecircle": {"place": "ground", "dur": 1.0, "nopop": true},
	"c_iceprison": {"place": "ground", "dur": 1.0, "nopop": true},
	"c_icewave": {"place": "ground", "dur": 0.9, "nopop": true},
	"c_iceburst": {"place": "front", "dur": 0.8},
	"c_frozensea": {"place": "far", "dur": 1.4, "nopop": true, "rumble": 3.0},
	"c_crystalguard": {"place": "body", "dur": 1.0},
	"c_energyshield": {"place": "body", "dur": 1.0},
	"c_restoremoon": {"place": "body", "dur": 1.1, "nopop": true},
	"c_healcross": {"place": "body", "dur": 1.0, "nopop": true},
	"c_elemstorm": {"place": "body", "dur": 1.2},
	"c_heavenearth": {"place": "body", "dur": 1.4, "nopop": true},
	"c_teleport": {"place": "body", "dur": 0.6, "nopop": true},
	"c_elemblink": {"place": "body", "dur": 0.8, "nopop": true},
	"c_hellfire": {"place": "ground", "dur": 1.2, "nopop": true, "rumble": 4.0},
	"c_meteor": {"place": "far", "dur": 1.2, "nopop": true, "rumble": 5.0},
	"c_emberburst": {"place": "front", "dur": 0.7},
	"c_piercebolt": {"place": "front", "dur": 0.55, "nopop": true},
	"c_thunderlord": {"place": "far", "dur": 1.4, "nopop": true, "rumble": 7.0},
	"c_forbidden": {"place": "ground", "dur": 1.5, "nopop": true, "rumble": 6.0},
	"c_witherskull": {"place": "front", "dur": 0.95},
	"c_soulchains": {"place": "front", "dur": 1.0},
	"c_soulchainblast": {"place": "front", "dur": 0.95},
	"c_soulsplit": {"place": "body", "dur": 0.9, "nopop": true},
	"c_deathmist": {"place": "ground", "dur": 1.3, "nopop": true},
	"c_shadowsummon": {"place": "ground", "dur": 1.1, "nopop": true},
	"c_soulsiphon": {"place": "body", "dur": 1.0, "nopop": true},
	"c_phantomarmy": {"place": "ground", "dur": 1.3, "nopop": true},
	"c_netherportal": {"place": "front", "dur": 1.1},
	"c_demonclaw": {"place": "front", "dur": 0.7, "nopop": true},
	"c_soulward": {"place": "body", "dur": 1.1},
	"c_ghosttide": {"place": "far", "dur": 1.4, "nopop": true, "rumble": 3.0},
	"c_soulfusion": {"place": "body", "dur": 1.4, "nopop": true},
}

const FIRE := Color(1.0, 0.45, 0.1)
const FIRE2 := Color(1.0, 0.86, 0.35)
const ICE := Color(0.5, 0.86, 1.0)
const ICE2 := Color(0.93, 0.99, 1.0)
const DARK := Color(0.04, 0.0, 0.08)

static func draw(s: Node2D, sg: String, t: float, lowq: bool) -> void:
	match sg:
		"c_thundersnake": _thundersnake(s, t, lowq)
		"c_fireboom": _fireboom(s, t, lowq)
		"c_fireball": _fireball(s, t, lowq)
		"c_firewall": _firewall(s, t, lowq)
		"c_icecircle": _icecircle(s, t, lowq)
		"c_iceprison": _iceprison(s, t, lowq)
		"c_icewave": _icewave(s, t, lowq)
		"c_iceburst": _iceburst(s, t, lowq)
		"c_frozensea": _frozensea(s, t, lowq)
		"c_crystalguard": _crystalguard(s, t, lowq)
		"c_energyshield": _energyshield(s, t, lowq)
		"c_restoremoon": _restoremoon(s, t, lowq)
		"c_healcross": _healcross(s, t, lowq)
		"c_elemstorm": _elemstorm(s, t, lowq)
		"c_heavenearth": _heavenearth(s, t, lowq)
		"c_teleport": _teleport(s, t, lowq)
		"c_elemblink": _elemblink(s, t, lowq)
		"c_hellfire": _hellfire(s, t, lowq)
		"c_meteor": _meteor(s, t, lowq)
		"c_emberburst": _emberburst(s, t, lowq)
		"c_piercebolt": _piercebolt(s, t, lowq)
		"c_thunderlord": _thunderlord(s, t, lowq)
		"c_forbidden": _forbidden(s, t, lowq)
		"c_witherskull": _witherskull(s, t, lowq)
		"c_soulchains": _soulchains(s, t, lowq)
		"c_soulchainblast": _soulchainblast(s, t, lowq)
		"c_soulsplit": _soulsplit(s, t, lowq)
		"c_deathmist": _deathmist(s, t, lowq)
		"c_shadowsummon": _shadowsummon(s, t, lowq)
		"c_soulsiphon": _soulsiphon(s, t, lowq)
		"c_phantomarmy": _phantomarmy(s, t, lowq)
		"c_netherportal": _netherportal(s, t, lowq)
		"c_demonclaw": _demonclaw(s, t, lowq)
		"c_soulward": _soulward(s, t, lowq)
		"c_ghosttide": _ghosttide(s, t, lowq)
		"c_soulfusion": _soulfusion(s, t, lowq)
		_: pass

# ---------------------------------------------------------------- helpers

static func _c(c: Color, a: float) -> Color:
	return Color(c.r, c.g, c.b, clampf(a, 0.0, 1.0))

static func _rs(s, t: float, rate: float, salt: int = 0) -> void:
	s._rng.seed = int(s.vs) + int(t * rate) * 31 + salt

static func _x0(s) -> void:
	s.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

static func _glow(s, c: Vector2, r: float, a: float) -> void:
	if r < 1.0: return
	for i in range(5):
		var u := float(i) / 4.0
		s.draw_circle(c, r * (1.0 - u * 0.8), s._mix(u, (0.12 + 0.1 * u) * a))

static func _cglow(s, c: Vector2, r: float, col: Color, col2: Color, a: float) -> void:
	if r < 1.0: return
	for i in range(5):
		var u := float(i) / 4.0
		s.draw_circle(c, r * (1.0 - u * 0.8), _c(col.lerp(col2, u), (0.12 + 0.12 * u) * a))

## vòng elip nằm trên mặt đất
static func _ering(s, c: Vector2, rx: float, ry: float, col: Color, w: float) -> void:
	if rx < 1.0: return
	s.draw_set_transform(c, 0.0, Vector2(1.0, ry / rx))
	s.draw_arc(Vector2.ZERO, rx, 0.0, TAU, 40, col, w)
	_x0(s)

static func _efill(s, c: Vector2, rx: float, ry: float, col: Color) -> void:
	if rx < 1.0: return
	s.draw_set_transform(c, 0.0, Vector2(1.0, ry / rx))
	s.draw_circle(Vector2.ZERO, rx, col)
	_x0(s)

static func _poly(s, pts: PackedVector2Array, col: Color) -> void:
	if pts.size() < 3: return
	s.draw_colored_polygon(pts, col)

## tia sét ngoằn ngoèo a -> b
static func _bolt(s, a: Vector2, b: Vector2, amp: float, segs: int, w: float, al: float, col2: Color = Color(0, 0, 0, 0)) -> PackedVector2Array:
	var pts := PackedVector2Array([a])
	var d := b - a
	var nr := d.orthogonal().normalized()
	for i in range(1, segs):
		var u := float(i) / float(segs)
		pts.append(a + d * u + nr * s._rng.randf_range(-amp, amp))
	pts.append(b)
	s.draw_polyline(pts, s._a(0.3 * al), w * 2.4)
	s.draw_polyline(pts, s._a(0.95 * al), w)
	s.draw_polyline(pts, s._k(al) if col2.a == 0.0 else _c(col2, al), maxf(1.0, w * 0.4))
	return pts

static func _flame(s, base: Vector2, h: float, w: float, c1: Color, c2: Color, a: float, ph: float) -> void:
	if h < 3.0 or w < 2.0: return
	var sw := sin(ph)
	_poly(s, PackedVector2Array([
		base + Vector2(-w * 0.5, 0), base + Vector2(-w * 0.55 + sw * w * 0.2, -h * 0.4),
		base + Vector2(sin(ph * 1.3) * w * 0.35, -h),
		base + Vector2(w * 0.55 + sin(ph + 1.0) * w * 0.2, -h * 0.4), base + Vector2(w * 0.5, 0)]), _c(c1, a))
	_poly(s, PackedVector2Array([
		base + Vector2(-w * 0.28, 0), base + Vector2(-w * 0.3 + sw * w * 0.1, -h * 0.28),
		base + Vector2(sin(ph * 1.3) * w * 0.2, -h * 0.68),
		base + Vector2(w * 0.3 + sin(ph + 1.0) * w * 0.1, -h * 0.28), base + Vector2(w * 0.28, 0)]), _c(c2, a))

## mũi băng nhọn, ang = nghiêng so với phương thẳng đứng
static func _shard(s, base: Vector2, h: float, w: float, ang: float, c1: Color, c2: Color, a: float) -> void:
	if h < 3.0 or w < 1.5: return
	var d := Vector2(sin(ang), -cos(ang))
	var n := Vector2(cos(ang), sin(ang))
	var tip := base + d * h
	_poly(s, PackedVector2Array([base - n * w * 0.5, base + d * h * 0.6 - n * w * 0.38, tip, base + d * h * 0.6 + n * w * 0.38, base + n * w * 0.5]), _c(c1, a))
	s.draw_line(base - n * w * 0.12, tip, _c(c2, a), 1.4)

static func _snow(s, c: Vector2, r: float, rot: float, col: Color, w: float) -> void:
	for k in range(6):
		var a := rot + TAU * float(k) / 6.0
		var d := Vector2(cos(a), sin(a))
		s.draw_line(c, c + d * r, col, w)
		var m := c + d * r * 0.62
		s.draw_line(m, m + d.rotated(0.7) * r * 0.3, col, w * 0.8)
		s.draw_line(m, m + d.rotated(-0.7) * r * 0.3, col, w * 0.8)

static func _star(s, c: Vector2, n: int, r1: float, r2: float, col: Color, rot: float = -PI * 0.5) -> void:
	var pts := PackedVector2Array()
	for k in range(n * 2):
		var a := rot + PI * float(k) / float(n)
		pts.append(c + Vector2(cos(a), sin(a)) * (r1 if k % 2 == 0 else r2))
	_poly(s, pts, col)

static func _skull(s, c: Vector2, r: float, col: Color, a: float) -> void:
	if r < 3.0: return
	s.draw_circle(c + Vector2(0, -r * 0.1), r, _c(col, a))
	s.draw_rect(Rect2(c.x - r * 0.55, c.y + r * 0.55, r * 1.1, r * 0.75), _c(col, a))
	var dk := Color(DARK.r, DARK.g, DARK.b, 0.95 * a)
	s.draw_circle(c + Vector2(-r * 0.4, -r * 0.05), r * 0.27, dk)
	s.draw_circle(c + Vector2(r * 0.4, -r * 0.05), r * 0.27, dk)
	_poly(s, PackedVector2Array([c + Vector2(0, r * 0.15), c + Vector2(-r * 0.12, r * 0.4), c + Vector2(r * 0.12, r * 0.4)]), dk)
	for k in range(-1, 2):
		s.draw_line(c + Vector2(k * r * 0.3, r * 0.75), c + Vector2(k * r * 0.3, r * 1.25), dk, 1.4)

static func _ghost(s, c: Vector2, sz: float, col: Color, a: float, ph: float, eyes: bool = true) -> void:
	if sz < 5.0: return
	var r := sz * 0.5
	var pts := PackedVector2Array()
	for i in range(9):
		var an := PI + PI * float(i) / 8.0
		pts.append(c + Vector2(cos(an) * r, sin(an) * r))
	for k in range(6):
		var x := r - 2.0 * r * float(k) / 5.0
		var y := sz * 0.78 + (sz * 0.13 if k % 2 == 1 else 0.0) + sin(ph + k * 1.3) * sz * 0.06
		pts.append(c + Vector2(x, y))
	_poly(s, pts, _c(col, a))
	if eyes:
		var dk := Color(DARK.r, DARK.g, DARK.b, 0.9 * a)
		s.draw_circle(c + Vector2(-r * 0.38, -r * 0.1), r * 0.2, dk)
		s.draw_circle(c + Vector2(r * 0.38, -r * 0.1), r * 0.2, dk)
		s.draw_circle(c + Vector2(0, r * 0.35), r * 0.17, dk)

## vệt hồn: đầu sáng + đuôi cong
static func _wisp(s, head: Vector2, dir: Vector2, ln: float, w: float, a: float) -> void:
	var nr := dir.orthogonal()
	var pts := PackedVector2Array()
	for i in range(7):
		var u := float(i) / 6.0
		pts.append(head + dir * ln * u + nr * sin(u * 6.0 + head.x * 0.1) * w * 0.8 * u)
	s.draw_polyline(pts, s._a(0.35 * a), w * 1.8)
	s.draw_polyline(pts, s._a(0.8 * a), w)
	s.draw_circle(head, w * 1.1, s._k(a))

# ---------------------------------------------------------------- phap su: lua

static func _thundersnake(s, t: float, lq: bool) -> void:
	_rs(s, t, 16)
	var hx := -34.0 + 150.0 * t
	var n := 14 if lq else 26
	var pts := PackedVector2Array()
	for i in range(n + 1):
		var u := float(i) / float(n)
		pts.append(Vector2(hx - u * 80.0, sin(u * 10.0 - t * 34.0) * 16.0 * (1.0 - u * 0.35)))
	s.draw_polyline(pts, s._a(0.28), 13.0)
	s.draw_polyline(pts, s._a(0.95), 5.5)
	s.draw_polyline(pts, s._k(1.0), 2.0)
	var hp := pts[0]
	_glow(s, hp, 26.0, 1.0)
	_poly(s, PackedVector2Array([hp + Vector2(-5, -8), hp + Vector2(14, 0), hp + Vector2(-5, 8)]), s._k(1.0))
	s.draw_circle(hp + Vector2(3, -2.5), 2.0, Color(0.05, 0, 0.1, 0.95))
	s.draw_line(hp + Vector2(14, 0), hp + Vector2(23, -5), s._k(0.95), 1.4)
	s.draw_line(hp + Vector2(14, 0), hp + Vector2(23, 5), s._k(0.95), 1.4)
	for k in range(4 if lq else 8):
		var p: Vector2 = pts[s._rng.randi_range(2, n)]
		_bolt(s, p, p + Vector2.from_angle(s._rng.randf() * TAU) * s._rng.randf_range(10.0, 20.0), 4.0, 3, 1.6, 0.9)

static func _fireboom(s, t: float, lq: bool) -> void:
	var tf := 0.45
	if t < tf:
		var q := t / tf
		var cx := -34.0 + 134.0 * q
		for i in range(7):
			var u := float(i) / 6.0
			s.draw_circle(Vector2(cx - 8.0 - i * 9.0, sin(i * 1.7 + t * 20.0) * 4.0), 13.0 * (1.0 - u * 0.7), _c(FIRE.lerp(Color(0.5, 0.1, 0.05), u), 0.5 * (1.0 - u * 0.6)))
		_cglow(s, Vector2(cx, 0), 30.0, FIRE, FIRE2, 1.0)
		s.draw_circle(Vector2(cx, 0), 10.0, _c(FIRE2, 1.0))
		s.draw_circle(Vector2(cx, 0), 5.0, s._k(1.0))
	else:
		var q := (t - tf) / (1.0 - tf)
		var c := Vector2(100, 0)
		for i in range(5):
			var u := float(i) / 4.0
			s.draw_circle(c + Vector2(0, -8.0 * q), (24.0 + 62.0 * q) * (1.0 - u * 0.75), _c(FIRE.lerp(FIRE2, u), 0.6 * (1.0 - q) * (0.6 + 0.4 * u)))
		var ns := 8 if lq else 14
		for k in range(ns):
			var a := TAU * float(k) / float(ns) + 0.2
			var d := Vector2(cos(a), sin(a))
			var L := (30.0 + 60.0 * q) * (1.0 if k % 2 == 0 else 0.65)
			_poly(s, PackedVector2Array([c + d * 14.0 + d.orthogonal() * 5.0, c + d * (14.0 + L), c + d * 14.0 - d.orthogonal() * 5.0]), _c(FIRE2, 0.85 * (1.0 - q)))
		s.draw_arc(c, 20.0 + 80.0 * q, 0.0, TAU, 40, _c(FIRE, 0.9 * (1.0 - q)), 4.0)
		for k in range(4):
			s.draw_circle(c + Vector2((k - 1.5) * 26.0 * q, -36.0 * q - k * 8.0 * q), 10.0 * q + 4.0, Color(0.15, 0.1, 0.1, 0.4 * (1.0 - q)))

static func _fireball(s, t: float, lq: bool) -> void:
	_rs(s, t, 20)
	var cx := -30.0 + 125.0 * t
	var n := 8 if lq else 14
	for i in range(n):
		var u := float(i) / float(n)
		var p := Vector2(cx - 6.0 - u * 62.0, sin(u * 9.0 - t * 30.0) * 6.0 * u)
		s.draw_circle(p, 11.0 * (1.0 - u * 0.8), _c(FIRE.lerp(Color(0.6, 0.12, 0.05), u), 0.65 * (1.0 - u)))
	_cglow(s, Vector2(cx, 0), 24.0, FIRE, FIRE2, 1.0)
	s.draw_circle(Vector2(cx, 0), 11.0, _c(FIRE, 1.0))
	s.draw_circle(Vector2(cx + 1.0, 0), 7.0, _c(FIRE2, 1.0))
	s.draw_circle(Vector2(cx + 2.0, 0), 3.5, s._k(1.0))
	for k in range(3 if lq else 6):
		var a := t * 14.0 + TAU * float(k) / 6.0
		s.draw_circle(Vector2(cx, 0) + Vector2(cos(a), sin(a)) * 17.0, 2.2, _c(FIRE2, 0.9))
	if t > 0.85:
		var q := (t - 0.85) / 0.15
		s.draw_arc(Vector2(cx + 8.0, 0), 10.0 + 22.0 * q, 0.0, TAU, 24, _c(FIRE2, 0.8 * (1.0 - q)), 3.0)

static func _firewall(s, t: float, lq: bool) -> void:
	var g := minf(1.0, t * 2.5)
	var fade := 1.0 - maxf(0.0, (t - 0.8) / 0.2)
	_efill(s, Vector2(0, 2), 74.0 * g, 12.0, _c(FIRE, 0.28 * fade))
	_ering(s, Vector2(0, 2), 74.0 * g, 12.0, _c(FIRE2, 0.75 * fade), 2.5)
	var n := 8 if lq else 15
	for i in range(n):
		var u := float(i) / float(n - 1)
		var x := -66.0 + 132.0 * u
		var env := 0.65 + 0.35 * sin(u * PI)
		var h := (62.0 + 22.0 * sin(i * 2.3 + t * 18.0)) * env * g
		_flame(s, Vector2(x, 4.0), h, 24.0, FIRE, FIRE2, 0.9 * fade, t * 14.0 + i * 1.7)
	for k in range(4 if lq else 9):
		var q := fposmod(t * 1.3 + float(k) * 0.21, 1.0)
		s.draw_circle(Vector2(-60.0 + fposmod(k * 37.0, 120.0), -20.0 - 80.0 * q), 2.0, _c(FIRE2, (1.0 - q) * fade))

static func _hellfire(s, t: float, lq: bool) -> void:
	var g := minf(1.0, t * 3.0)
	var fade := 1.0 - maxf(0.0, (t - 0.82) / 0.18)
	_efill(s, Vector2(0, 2), 90.0 * g, 16.0, Color(0.35, 0.02, 0.0, 0.5 * fade))
	_efill(s, Vector2(0, 2), 60.0 * g, 10.0, _c(FIRE, 0.3 * fade))
	s.draw_set_transform(Vector2(0, 2), 0.0, Vector2(1.0, 0.34))
	var nc := 6 if lq else 10
	for k in range(nc):
		var a := TAU * float(k) / float(nc) + 0.3
		var cur := Vector2.ZERO
		var pts := PackedVector2Array([cur])
		for j in range(5):
			var aa: float = a + s._rng.randf_range(-0.35, 0.35)
			cur += Vector2(cos(aa), sin(aa)) * 22.0 * g
			pts.append(cur)
		s.draw_polyline(pts, Color(1.0, 0.2, 0.0, 0.5 * fade), 7.0)
		s.draw_polyline(pts, _c(FIRE2, 0.95 * fade), 2.2)
	_x0(s)
	var np := 5 if lq else 9
	for i in range(np):
		var ang := TAU * float(i) / float(np) + 0.9
		var pos := Vector2(cos(ang) * 62.0 * 0.8, sin(ang) * 11.0)
		var d := float(i) * 0.06
		var q := clampf((t - d) / 0.4, 0.0, 1.0)
		if q <= 0.0: continue
		var h := 90.0 * sin(q * PI * 0.9) * (0.7 + 0.3 * sin(i * 1.9))
		_flame(s, pos + Vector2(0, 4), h, 26.0, Color(1.0, 0.18, 0.02), FIRE2, 0.9 * fade, t * 16.0 + i)
	for k in range(5 if lq else 11):
		var q := fposmod(t * 1.1 + float(k) * 0.17, 1.0)
		var x := -55.0 + fposmod(k * 41.0, 110.0)
		s.draw_circle(Vector2(x + sin(q * 8.0 + k) * 6.0, -10.0 - 90.0 * q), 2.4, _c(FIRE2, (1.0 - q) * fade))

static func _meteor(s, t: float, lq: bool) -> void:
	var nm := 3 if lq else 5
	for i in range(nm):
		var tx := -70.0 + 140.0 * float(i) / float(nm - 1)
		var d := float(i) * 0.12 + (0.06 if i % 2 == 1 else 0.0)
		var q := clampf((t - d) / 0.4, 0.0, 1.0)
		var tgt := Vector2(tx, 2.0 + (i % 2) * 5.0)
		var dirv := Vector2(0.45, -1.0).normalized()
		if q > 0.0 and q < 1.0:
			var p := tgt + dirv * 270.0 * (1.0 - q)
			for j in range(8):
				var u := float(j) / 7.0
				s.draw_circle(p + dirv * (10.0 + u * 70.0), 11.0 * (1.0 - u * 0.8), _c(FIRE.lerp(Color(0.5, 0.1, 0.0), u), 0.6 * (1.0 - u)))
			_cglow(s, p, 24.0, FIRE, FIRE2, 1.0)
			s.draw_colored_polygon(PackedVector2Array([p + Vector2(-8, -3), p + Vector2(-2, -9), p + Vector2(8, -5), p + Vector2(9, 5), p + Vector2(0, 9), p + Vector2(-8, 4)]), Color(0.28, 0.12, 0.06, 1.0))
			s.draw_circle(p + Vector2(-2, -2), 3.0, _c(FIRE2, 0.9))
		elif q >= 1.0:
			var r := clampf((t - d - 0.4) / 0.35, 0.0, 1.0)
			_efill(s, tgt, 30.0 * r + 8.0, 7.0, _c(FIRE, 0.5 * (1.0 - r)))
			_ering(s, tgt, 12.0 + 44.0 * r, 10.0, _c(FIRE2, 0.9 * (1.0 - r)), 3.0)
			_flame(s, tgt, 46.0 * (1.0 - r * 0.6), 24.0, FIRE, FIRE2, 0.85 * (1.0 - r), t * 20.0 + i)
			for k in range(4):
				var a := -0.6 - k * 0.65
				s.draw_circle(tgt + Vector2(cos(a), sin(a)) * 40.0 * r * (1.0 if k % 2 == 0 else -1.0), 2.6, Color(0.3, 0.15, 0.08, 1.0 - r))

static func _emberburst(s, t: float, lq: bool) -> void:
	_rs(s, t, 24)
	var c := Vector2(20, -2)
	var fl := maxf(0.0, 1.0 - t * 3.0)
	_cglow(s, c, 26.0 + 30.0 * t, FIRE, FIRE2, 1.0 - t)
	if fl > 0.0:
		_star(s, c, 4, 52.0 * (0.5 + fl), 6.0, _c(FIRE2, fl), 0.0)
		_star(s, c, 4, 38.0 * (0.5 + fl), 5.0, s._k(fl), PI * 0.25)
	var n := 12 if lq else 26
	for k in range(n):
		var a := TAU * float(k) / float(n) + float(k % 3) * 0.12
		var v := 50.0 + float(k % 5) * 18.0
		var life := minf(1.0, t * 1.25)
		var p := c + Vector2(cos(a), sin(a)) * v * life + Vector2(0, 40.0 * life * life)
		var p2 := p - Vector2(cos(a), sin(a)) * 10.0 * (1.0 - life * 0.5)
		s.draw_line(p2, p, _c(FIRE.lerp(FIRE2, float(k % 2)), 1.0 - life), 2.4)
		s.draw_circle(p, 1.6, _c(FIRE2, 1.0 - life))

# ---------------------------------------------------------------- phap su: bang

static func _icecircle(s, t: float, lq: bool) -> void:
	var g := minf(1.0, t * 2.5)
	var fade := 1.0 - maxf(0.0, (t - 0.8) / 0.2)
	_efill(s, Vector2(0, 2), 74.0 * g, 22.0, _c(ICE, 0.22 * fade))
	for r in [74.0, 56.0]:
		_ering(s, Vector2(0, 2), r * g, r * 0.3 * g, _c(ICE2, 0.85 * fade), 2.2)
	# ngôi sao 6 cánh trong trận
	s.draw_set_transform(Vector2(0, 2), t * 0.8, Vector2(1.0, 0.3))
	for k in range(2):
		var pts := PackedVector2Array()
		for j in range(3):
			var a := TAU * float(j) / 3.0 + k * PI / 3.0 - PI * 0.5
			pts.append(Vector2(cos(a), sin(a)) * 56.0 * g)
		pts.append(pts[0])
		s.draw_polyline(pts, _c(ICE, 0.9 * fade), 2.0)
	_x0(s)
	var n := 8 if lq else 14
	for i in range(n):
		var a := TAU * float(i) / float(n)
		var pos := Vector2(cos(a) * 66.0, 2.0 + sin(a) * 66.0 * 0.3)
		var q := clampf((t - 0.15 - fposmod(i * 0.07, 0.3)) / 0.3, 0.0, 1.0)
		var h := (38.0 + 22.0 * float(i % 3)) * q
		_shard(s, pos, h, 12.0, cos(a) * 0.25, ICE, ICE2, 0.9 * fade)
	_shard(s, Vector2(0, 4), 80.0 * minf(1.0, maxf(0.0, t - 0.2) * 3.0), 20.0, 0.0, ICE, ICE2, 0.9 * fade)

static func _iceprison(s, t: float, lq: bool) -> void:
	var g := minf(1.0, t * 2.2)
	var fade := 1.0 - maxf(0.0, (t - 0.82) / 0.18)
	_efill(s, Vector2(0, 2), 44.0, 10.0, _c(ICE, 0.35 * fade))
	# khối băng đóng chặt ở giữa
	var blk := PackedVector2Array([Vector2(-22, 4), Vector2(-26, -30 * g), Vector2(-10, -58 * g), Vector2(12, -56 * g), Vector2(26, -28 * g), Vector2(22, 4)])
	_poly(s, blk, _c(ICE, 0.22 * fade))
	s.draw_polyline(blk, _c(ICE2, 0.7 * fade), 1.6)
	var n := 5 if lq else 8
	for i in range(n):
		var u := float(i) / float(n - 1)
		var x := -46.0 + 92.0 * u
		var lean := (u - 0.5) * 0.9 * (1.0 - g * 0.6)
		var q := clampf((t - u * 0.15) * 2.4, 0.0, 1.0)
		_shard(s, Vector2(x, 4.0 - 6.0 * absf(u - 0.5)), 96.0 * q, 11.0, -lean, ICE, ICE2, 0.92 * fade)
	# song sắt băng ngang
	for lv in range(2):
		var y := -30.0 - lv * 30.0
		if g > 0.6:
			s.draw_line(Vector2(-44, y), Vector2(44, y), _c(ICE2, 0.8 * fade * (g - 0.6) * 2.5), 3.0)
	_snow(s, Vector2(0, -36), 16.0 * g, t * 1.5, _c(ICE2, 0.95 * fade), 1.6)

static func _icewave(s, t: float, lq: bool) -> void:
	var fade := 1.0 - maxf(0.0, (t - 0.78) / 0.22)
	var n := 8 if lq else 13
	_efill(s, Vector2(30, 2), 90.0, 10.0, _c(ICE, 0.18 * fade))
	for i in range(n):
		var x := -52.0 + float(i) * 12.5
		var q := clampf(t * 2.2 - float(i) * 0.1, 0.0, 1.0)
		if q <= 0.0: continue
		var peak := 38.0 + 26.0 * float(i) / float(n)
		var h := peak * sin(q * PI * 0.5) * (0.85 + 0.15 * sin(i * 2.1))
		_shard(s, Vector2(x, 4.0), h, 14.0 + float(i) * 0.7, 0.25 + 0.04 * sin(i), ICE, ICE2, 0.92 * fade)
	# đỉnh sóng cuộn ở mũi
	var ft := clampf(t * 2.2, 0.0, 1.0)
	var fx := -52.0 + 12.5 * (n - 1) * ft
	_snow(s, Vector2(fx + 10.0, -44.0 - 10.0 * ft), 11.0, t * 4.0, _c(ICE2, 0.9 * fade), 1.4)
	for k in range(3 if lq else 6):
		var q := fposmod(t * 1.5 + k * 0.17, 1.0)
		s.draw_circle(Vector2(fx - 30.0 * q + k * 5.0, -10.0 - 36.0 * q), 2.0, _c(ICE2, (1.0 - q) * fade))

static func _iceburst(s, t: float, lq: bool) -> void:
	var c := Vector2(30, -4)
	var fl := maxf(0.0, 1.0 - t * 2.5)
	_cglow(s, c, 24.0 + 40.0 * t, ICE, ICE2, 1.0 - t * 0.8)
	_snow(s, c, 22.0 + 50.0 * t, t * 2.0, _c(ICE2, 1.0 - t * 0.7), 2.2)
	if fl > 0.0: _star(s, c, 6, 40.0 * (0.4 + fl), 8.0, _c(ICE2, fl))
	var n := 8 if lq else 14
	for k in range(n):
		var a := TAU * float(k) / float(n)
		var q := minf(1.0, t * 1.3)
		var dist := 20.0 + (36.0 + float(k % 3) * 22.0) * q
		var base := c + Vector2(cos(a), sin(a)) * dist
		_shard(s, base, 20.0 + float(k % 2) * 8.0, 7.0, a + PI * 0.5, ICE, ICE2, 1.0 - t * 0.9)
	s.draw_arc(c, 12.0 + 90.0 * t, 0.0, TAU, 40, _c(ICE2, 0.8 * (1.0 - t)), 3.0)

static func _frozensea(s, t: float, lq: bool) -> void:
	var g := minf(1.0, t * 2.0)
	var fade := 1.0 - maxf(0.0, (t - 0.85) / 0.15)
	_efill(s, Vector2(0, 2), 150.0 * g, 24.0, _c(ICE, 0.3 * fade))
	# tuyết khổng lồ trên trời
	_snow(s, Vector2(0, -176), 52.0 * g, t * 0.8, _c(ICE2, 0.75 * fade), 3.0)
	_cglow(s, Vector2(0, -176), 60.0 * g, ICE, ICE2, 0.8 * fade)
	# ba lớp sóng đóng băng
	for L in range(3):
		var amp := 34.0 - L * 8.0
		var yb := 4.0 - L * 14.0
		var pts := PackedVector2Array()
		var n := 18 if lq else 30
		for i in range(n + 1):
			var u := float(i) / float(n)
			var x := -140.0 + 280.0 * u
			var rise := clampf(t * 2.0 - L * 0.18, 0.0, 1.0)
			pts.append(Vector2(x, yb - (amp * (0.6 + 0.4 * sin(u * 9.0 + L * 1.7 - t * 3.0)) * rise)))
		s.draw_polyline(pts, _c(ICE, 0.35 * fade), 10.0)
		s.draw_polyline(pts, _c(ICE2, 0.95 * fade), 2.4)
		# gai băng ở đỉnh sóng
		for i in range(2, n, 3):
			_shard(s, pts[i], 20.0 + 10.0 * float((i + L) % 3), 9.0, 0.0, ICE, ICE2, 0.85 * fade)
	for k in range(8 if lq else 18):
		var q := fposmod(t * 0.9 + float(k) * 0.083, 1.0)
		var x := -130.0 + fposmod(k * 53.0, 260.0)
		_snow(s, Vector2(x + sin(q * 6.0 + k) * 10.0, -170.0 + 170.0 * q), 4.0, q * 6.0, _c(ICE2, (1.0 - q * 0.5) * fade), 1.1)

# ---------------------------------------------------------------- phap su: ho the / hoi phuc / dich chuyen

static func _crystalguard(s, t: float, lq: bool) -> void:
	var g := minf(1.0, t * 3.0)
	_efill(s, Vector2(0, 26), 34.0, 8.0, s._a(0.3))
	for i in range(4):
		var u := float(i) / 3.0
		s.draw_circle(Vector2(0, -6), 40.0 * (1.0 - u * 0.5) * g, s._mix(u, 0.05 + 0.04 * u))
	var n := 5 if lq else 7
	for k in range(n):
		var a := t * 4.0 + TAU * float(k) / float(n)
		var p := Vector2(cos(a) * 40.0, -6.0 + sin(a) * 14.0) * g
		var front := sin(a) > 0.0
		var sz := 13.0 if front else 9.0
		var pts := PackedVector2Array([p + Vector2(0, -sz * 1.5), p + Vector2(sz * 0.7, 0), p + Vector2(0, sz * 1.1), p + Vector2(-sz * 0.7, 0)])
		_poly(s, pts, s._a(0.88 if front else 0.55))
		s.draw_polyline(PackedVector2Array([pts[0], pts[1], pts[2], pts[3], pts[0]]), s._k(0.95), 1.4)
		s.draw_line(pts[0], pts[2], s._k(0.6), 1.0)
		s.draw_circle(p + Vector2(-sz * 0.2, -sz * 0.5), 1.6, Color(1, 1, 1, 0.9))
	s.draw_arc(Vector2(0, -6), 44.0 * g, 0.0, TAU, 36, s._k(0.4 + 0.2 * sin(t * 18.0)), 1.6)

static func _energyshield(s, t: float, lq: bool) -> void:
	var g := minf(1.0, t * 4.0)
	var R := 46.0 * g
	var cc := Vector2(0, -6)
	s.draw_circle(cc, R, s._a(0.12))
	s.draw_arc(cc, R, 0.0, TAU, 44, s._a(0.9), 3.0)
	s.draw_arc(cc, R - 4.0, 0.0, TAU, 44, s._k(0.6), 1.2)
	var hs := 13.0 if not lq else 17.0
	var rows := int(ceil(R / (hs * 0.87))) + 1
	for ry in range(-rows, rows + 1):
		for cx in range(-rows, rows + 1):
			var p := Vector2(float(cx) * hs * 1.73 + (hs * 0.87 if ry % 2 != 0 else 0.0), float(ry) * hs * 1.5)
			if p.length() > R - 5.0: continue
			var rip := sin(p.length() * 0.18 - t * 16.0)
			var al := 0.12 + 0.6 * maxf(0.0, rip)
			var pts := PackedVector2Array()
			for k in range(7):
				var a := PI / 6.0 + TAU * float(k) / 6.0
				pts.append(cc + p + Vector2(cos(a), sin(a)) * hs * 0.95)
			s.draw_polyline(pts, s._k(al), 1.2)
	if t < 0.25:
		s.draw_arc(cc, R + 30.0 * (0.25 - t) * 4.0, 0.0, TAU, 40, s._k(1.0 - t * 4.0), 3.0)

static func _restoremoon(s, t: float, lq: bool) -> void:
	var fade := 1.0 - maxf(0.0, (t - 0.8) / 0.2)
	var g := minf(1.0, t * 2.5)
	_efill(s, Vector2(0, 26), 40.0 * g, 10.0, s._a(0.3 * fade))
	_ering(s, Vector2(0, 26), 30.0 + 26.0 * t, (30.0 + 26.0 * t) * 0.3, s._k(0.8 * fade), 2.0)
	# trăng khuyết trên đầu
	var mc := Vector2(0, -52.0 - 6.0 * sin(t * 6.0))
	_glow(s, mc, 30.0 * g, fade)
	var R := 16.0 * g
	if R > 3.0:
		var pts := PackedVector2Array()
		var a0 := 2.1
		for i in range(11):
			var ph := -a0 + 2.0 * a0 * float(i) / 10.0
			pts.append(mc + Vector2(cos(PI + ph), sin(PI + ph)) * R)
		for i in range(10, -1, -1):
			var ph2 := -a0 + 2.0 * a0 * float(i) / 10.0
			pts.append(mc + Vector2(cos(PI + ph2), sin(PI + ph2)) * R * (1.0 - 0.55 * cos(ph2 * PI / (2.0 * a0))))
		_poly(s, pts, s._k(0.95 * fade))
	# mana xoáy vào người
	var n := 6 if lq else 12
	for k in range(n):
		var q := fposmod(t * 1.0 + float(k) / float(n), 1.0)
		var a := TAU * float(k) / float(n) + q * 5.0
		var r := 46.0 * (1.0 - q)
		var p := Vector2(cos(a) * r, -6.0 + sin(a) * r * 0.5)
		s.draw_circle(p, 2.6 * (1.0 - q * 0.5), s._a(0.9 * sin(q * PI) * fade))
		s.draw_circle(p, 1.2, s._k(sin(q * PI) * fade))

static func _healcross(s, t: float, lq: bool) -> void:
	var fade := 1.0 - maxf(0.0, (t - 0.75) / 0.25)
	var pulse := 1.0 + 0.08 * sin(t * 24.0)
	_glow(s, Vector2(0, -8), 38.0 * pulse, fade)
	# dấu thập lớn ở ngực, nở rồi tan
	var sz := 26.0 * minf(1.0, t * 3.0) * pulse
	s.draw_rect(Rect2(-sz, -8.0 - sz * 0.28, sz * 2.0, sz * 0.56), s._a(0.85 * fade))
	s.draw_rect(Rect2(-sz * 0.28, -8.0 - sz, sz * 0.56, sz * 2.0), s._a(0.85 * fade))
	s.draw_rect(Rect2(-sz * 0.6, -8.0 - sz * 0.1, sz * 1.2, sz * 0.2), s._k(fade))
	s.draw_rect(Rect2(-sz * 0.1, -8.0 - sz * 0.6, sz * 0.2, sz * 1.2), s._k(fade))
	for r in [18.0, 34.0]:
		var q := fposmod(t * 1.4 + r * 0.02, 1.0)
		_ering(s, Vector2(0, 26), r + 18.0 * q, (r + 18.0 * q) * 0.3, s._a(0.8 * (1.0 - q) * fade), 2.4)
	for k in range(5 if lq else 10):
		var q := fposmod(t * 1.2 + float(k) * 0.1, 1.0)
		var x := -30.0 + fposmod(k * 23.0, 60.0)
		_star(s, Vector2(x, 24.0 - 80.0 * q), 4, 5.0 * sin(q * PI) + 1.0, 1.4, s._k(sin(q * PI) * fade))

static func _elemstorm(s, t: float, lq: bool) -> void:
	var g := minf(1.0, t * 2.5)
	var fade := 1.0 - maxf(0.0, (t - 0.82) / 0.18)
	_efill(s, Vector2(0, 26), 56.0 * g, 14.0, s._a(0.22 * fade))
	# gió xoáy
	for L in range(3):
		var pts := PackedVector2Array()
		for i in range(17):
			var u := float(i) / 16.0
			var a := t * 9.0 + u * TAU * 1.5 + L * 2.09
			pts.append(Vector2(cos(a) * (14.0 + 36.0 * u) * g, 24.0 - 84.0 * u + sin(a) * 6.0))
		s.draw_polyline(pts, s._a(0.35 * fade), 3.0)
	var cols := [FIRE, ICE, Color(1.0, 0.95, 0.3), Color(0.55, 0.78, 0.3)]
	for k in range(4):
		var a := t * 7.0 + TAU * float(k) / 4.0
		var p := Vector2(cos(a) * 46.0 * g, -8.0 + sin(a) * 18.0 * g)
		var col: Color = cols[k]
		for j in range(4):
			var u := float(j) / 4.0
			var ap := a - 0.32 * (j + 1)
			s.draw_circle(Vector2(cos(ap) * 46.0 * g, -8.0 + sin(ap) * 18.0 * g), 8.0 * (1.0 - u), _c(col, 0.4 * (1.0 - u) * fade))
		_cglow(s, p, 18.0, col, Color.WHITE, fade)
		s.draw_circle(p, 8.0, _c(col, fade))
		match k:
			0: _flame(s, p + Vector2(0, 5), 14.0, 9.0, FIRE, FIRE2, fade, t * 20.0)
			1: _snow(s, p, 8.0, t * 3.0, _c(ICE2, fade), 1.3)
			2: s.draw_polyline(PackedVector2Array([p + Vector2(2, -9), p + Vector2(-3, 0), p + Vector2(3, 0), p + Vector2(-2, 9)]), Color(1, 1, 0.8, fade), 2.0)
			3: _poly(s, PackedVector2Array([p + Vector2(-6, 3), p + Vector2(-2, -6), p + Vector2(5, -4), p + Vector2(6, 4)]), Color(0.35, 0.25, 0.1, fade))

static func _heavenearth(s, t: float, lq: bool) -> void:
	var g := minf(1.0, t * 2.2)
	var fade := 1.0 - maxf(0.0, (t - 0.82) / 0.18)
	# cột sáng từ trời xuống đất
	var w := 30.0 * g * (1.0 + 0.1 * sin(t * 20.0))
	_poly(s, PackedVector2Array([Vector2(-w, 26), Vector2(-w * 0.55, -200), Vector2(w * 0.55, -200), Vector2(w, 26)]), s._a(0.18 * fade))
	_poly(s, PackedVector2Array([Vector2(-w * 0.4, 26), Vector2(-w * 0.2, -200), Vector2(w * 0.2, -200), Vector2(w * 0.4, 26)]), s._k(0.3 * fade))
	# bát quái trên mặt đất
	_efill(s, Vector2(0, 26), 62.0 * g, 18.0, s._a(0.2 * fade))
	_ering(s, Vector2(0, 26), 62.0 * g, 18.0 * g, s._a(0.9 * fade), 2.4)
	_ering(s, Vector2(0, 26), 44.0 * g, 13.0 * g, s._k(0.7 * fade), 1.4)
	s.draw_set_transform(Vector2(0, 26), 0.0, Vector2(1.0, 0.29))
	for k in range(8):
		var a := t * 1.6 + TAU * float(k) / 8.0
		var d := Vector2(cos(a), sin(a))
		var tg := d.orthogonal()
		for j in range(1 + k % 3):
			var o := d * (46.0 + j * 5.0) * g
			s.draw_line(o - tg * 5.0, o + tg * 5.0, s._k(0.9 * fade), 2.0)
	_x0(s)
	# thái cực xoay
	var c := Vector2(0, -34)
	var r := 20.0 * g
	if r > 4.0:
		_glow(s, c, 40.0 * g, fade)
		s.draw_set_transform(c, t * 7.0, Vector2.ONE)
		s.draw_circle(Vector2.ZERO, r, s._a(0.95 * fade))
		var half := PackedVector2Array()
		for i in range(13):
			var a := -PI * 0.5 + PI * float(i) / 12.0
			half.append(Vector2(cos(a), sin(a)) * r)
		_poly(s, half, s._k(0.95 * fade))
		s.draw_circle(Vector2(0, -r * 0.5), r * 0.5, s._k(0.95 * fade))
		s.draw_circle(Vector2(0, r * 0.5), r * 0.5, s._a(0.95 * fade))
		s.draw_circle(Vector2(0, -r * 0.5), r * 0.14, s._a(fade))
		s.draw_circle(Vector2(0, r * 0.5), r * 0.14, s._k(fade))
		_x0(s)
	for k in range(5 if lq else 10):
		var q := fposmod(t * 1.0 + float(k) * 0.1, 1.0)
		var up := k % 2 == 0
		s.draw_circle(Vector2(sin(k * 3.0) * 26.0, (-190.0 + 210.0 * q) if up else (24.0 - 200.0 * q)), 2.2, s._k(sin(q * PI) * fade))

static func _teleport(s, t: float, lq: bool) -> void:
	_rs(s, t, 20)
	if t < 0.5:
		var q := t / 0.5
		for i in range(3):
			var r := (60.0 - 50.0 * q) * (1.0 - i * 0.22)
			s.draw_set_transform(Vector2(0, -6), 0.0, Vector2(0.55, 1.0))
			s.draw_arc(Vector2.ZERO, r, 0.0, TAU, 32, s._a((0.9 - i * 0.25) * q), 2.5)
			_x0(s)
		for k in range(8 if lq else 14):
			var a := TAU * float(k) / 14.0 + q * 3.0
			var rr := 70.0 * (1.0 - q)
			var p := Vector2(cos(a) * rr * 0.6, -6.0 + sin(a) * rr)
			s.draw_line(p, p * Vector2(0.8, 0.9) + Vector2(0, -1.2), s._k(0.7), 1.4)
		_efill(s, Vector2(0, -6), 14.0 * q, 34.0 * q, s._k(0.5 * q))
	else:
		var q := (t - 0.5) / 0.5
		var fl := 1.0 - q
		s.draw_rect(Rect2(-6.0 - 18.0 * q, -70.0, 12.0 + 36.0 * q, 100.0), s._a(0.5 * fl))
		s.draw_rect(Rect2(-2.5 - 6.0 * q, -90.0, 5.0 + 12.0 * q, 130.0), s._k(0.9 * fl))
		for k in range(6 if lq else 12):
			var x := -40.0 + fposmod(k * 29.0, 80.0)
			var h := 20.0 + fposmod(k * 17.0, 40.0)
			s.draw_line(Vector2(x * (0.3 + q), 20.0 - 60.0 * q), Vector2(x * (0.3 + q), 20.0 - 60.0 * q - h), s._a(0.8 * fl), 2.0)
		_ering(s, Vector2(0, 26), 10.0 + 60.0 * q, 6.0 + 18.0 * q, s._k(0.8 * fl), 2.5)

static func _elemblink(s, t: float, lq: bool) -> void:
	_rs(s, t, 20)
	var cols := [FIRE, Color(1.0, 0.95, 0.3), ICE, Color(0.5, 0.85, 0.3)]
	var cc := Vector2(0, -6)
	var fade := 1.0 - maxf(0.0, (t - 0.7) / 0.3)
	var R := 52.0 * (1.0 - 0.8 * minf(t * 1.4, 1.0)) if t < 0.55 else 10.0 + 70.0 * (t - 0.55) / 0.45
	for k in range(4):
		var a0 := t * 8.0 + k * PI * 0.5
		s.draw_arc(cc, R, a0, a0 + PI * 0.42, 10, _c(cols[k], 0.95 * fade), 5.0)
		s.draw_arc(cc, R - 4.0, a0, a0 + PI * 0.42, 10, Color(1, 1, 1, 0.6 * fade), 1.4)
	var n := 8 if lq else 16
	for k in range(n):
		var u := float(k) / float(n)
		var a := t * 10.0 + TAU * u * 2.0
		var rr := R * (0.35 + 0.65 * fposmod(u * 3.0, 1.0))
		var p := cc + Vector2(cos(a), sin(a)) * rr
		s.draw_circle(p, 2.6, _c(cols[k % 4], 0.9 * fade))
	if t > 0.5:
		var q := (t - 0.5) / 0.5
		for k in range(4):
			var a := PI * 0.25 + k * PI * 0.5
			_star(s, cc + Vector2(cos(a), sin(a)) * 30.0 * q, 4, 14.0 * (1.0 - q) + 3.0, 2.5, _c(cols[k], 0.95 * (1.0 - q)), a)

static func _piercebolt(s, t: float, lq: bool) -> void:
	_rs(s, t, 26)
	var ex := -50.0 + 220.0 * minf(1.0, t * 3.0)
	var fade := 1.0 - maxf(0.0, (t - 0.55) / 0.45)
	var a := Vector2(-52, 0)
	var b := Vector2(ex, 0)
	s.draw_rect(Rect2(-52, -3.0, ex + 52.0, 6.0), s._a(0.22 * fade))
	_bolt(s, a, b, 11.0, 9 if lq else 15, 5.0, fade)
	_bolt(s, a, b, 7.0, 9 if lq else 15, 2.2, 0.8 * fade)
	for k in range(2 if lq else 4):
		var u: float = s._rng.randf_range(0.2, 0.9)
		var p := a.lerp(b, u)
		_bolt(s, p, p + Vector2(s._rng.randf_range(10.0, 26.0), s._rng.randf_range(-30.0, 30.0)), 5.0, 3, 1.8, 0.8 * fade)
	# vòng xuyên thủng tại các điểm đi qua
	for i in range(3):
		var px := 20.0 + 45.0 * i
		if ex > px:
			var q := clampf((ex - px) / 100.0, 0.0, 1.0)
			s.draw_set_transform(Vector2(px, 0), 0.0, Vector2(0.35, 1.0))
			s.draw_arc(Vector2.ZERO, 8.0 + 26.0 * q, 0.0, TAU, 24, s._k(0.9 * (1.0 - q) * fade), 3.0)
			_x0(s)
	_glow(s, b, 22.0, fade)

static func _thunderlord(s, t: float, lq: bool) -> void:
	var fade := 1.0 - maxf(0.0, (t - 0.82) / 0.18)
	var fl := 0.5 + 0.5 * sin(t * 50.0)
	_rs(s, t, 22)
	# vòng sáng trời + vương miện sét
	var cr := Vector2(0, -190)
	var gc := minf(1.0, t * 3.0)
	_glow(s, cr, 70.0 * gc, 0.9 * fade)
	var crown := PackedVector2Array()
	for k in range(7):
		var x := -30.0 + 10.0 * float(k)
		crown.append(cr + Vector2(x, 0.0 if k % 2 == 0 else -18.0) * gc)
	crown.append(cr + Vector2(30, 14) * gc)
	crown.append(cr + Vector2(-30, 14) * gc)
	_poly(s, crown, s._k(0.92 * fade))
	s.draw_arc(cr, 42.0 * gc, 0.0, TAU, 36, s._a(0.85 * fade), 3.0)
	s.draw_arc(cr, 50.0 * gc + 4.0 * fl, 0.0, TAU, 36, s._k(0.5 * fade), 1.4)
	# ba tia sét cực lớn giáng xuống
	var xs := [-70.0, 0.0, 70.0]
	for i in range(3):
		var q := clampf((t - 0.12 - float(i) * 0.08) / 0.2, 0.0, 1.0)
		if q <= 0.0: continue
		var top := Vector2(xs[i] * 0.4, -190.0)
		var bot := Vector2(xs[i], 6.0)
		var tip := top.lerp(bot, q)
		_bolt(s, top, tip, 18.0, 10 if lq else 16, 8.0, fade)
		if not lq:
			var p := top.lerp(tip, 0.55)
			_bolt(s, p, p + Vector2(40.0 * (1.0 if i != 0 else -1.0), 30.0), 6.0, 4, 3.0, 0.8 * fade)
		if q >= 1.0:
			var r := clampf((t - 0.12 - float(i) * 0.08 - 0.2) / 0.5, 0.0, 1.0)
			_ering(s, bot, 10.0 + 70.0 * r, 6.0 + 20.0 * r, s._k(0.95 * (1.0 - r)), 3.0)
			_glow(s, bot + Vector2(0, -6), 26.0 * (1.0 - r * 0.5), fade)
	if t > 0.2 and t < 0.4:
		s.draw_rect(Rect2(-160, -200, 320, 230), s._k(0.12 * fl))

static func _forbidden(s, t: float, lq: bool) -> void:
	var g := minf(1.0, t * 2.4)
	var fade := 1.0 - maxf(0.0, (t - 0.85) / 0.15)
	_efill(s, Vector2(0, 8), 100.0 * g, 28.0, s._a(0.25 * fade))
	_ering(s, Vector2(0, 8), 100.0 * g, 28.0 * g, s._a(0.95 * fade), 3.0)
	_ering(s, Vector2(0, 8), 78.0 * g, 22.0 * g, s._k(0.8 * fade), 1.6)
	# vòng rune xoay + xích phong ấn
	s.draw_set_transform(Vector2(0, 8), 0.0, Vector2(1.0, 0.28))
	var nr := 10 if lq else 16
	for k in range(nr):
		var a := -t * 1.4 + TAU * float(k) / float(nr)
		var d := Vector2(cos(a), sin(a))
		var broken := t > 0.45 and k % 2 == 0
		var rr := 88.0 * g + (24.0 * (t - 0.45) * 2.0 if broken else 0.0)
		s.draw_line(d * rr - d.orthogonal() * 4.0, d * rr + d.orthogonal() * 4.0, s._k((0.9 if not broken else 0.5) * fade), 2.0)
		s.draw_line(d * (rr - 6.0), d * (rr + 6.0), s._a(0.8 * fade), 1.4)
	var pts := PackedVector2Array()
	for j in range(5):
		var a := t * 0.9 + TAU * float(j) * 2.0 / 5.0
		pts.append(Vector2(cos(a), sin(a)) * 72.0 * g)
	pts.append(pts[0])
	s.draw_polyline(pts, s._k(0.85 * fade), 1.8)
	_x0(s)
	# giải phóng: cột năng lượng khổng lồ + sóng xung kích
	if t > 0.4:
		var q := minf(1.0, (t - 0.4) / 0.25)
		var w := 34.0 * q * (1.0 + 0.12 * sin(t * 36.0))
		_poly(s, PackedVector2Array([Vector2(-w, 12), Vector2(-w * 0.6, -210), Vector2(w * 0.6, -210), Vector2(w, 12)]), s._a(0.35 * fade))
		_poly(s, PackedVector2Array([Vector2(-w * 0.45, 12), Vector2(-w * 0.25, -210), Vector2(w * 0.25, -210), Vector2(w * 0.45, 12)]), s._k(0.7 * fade))
		var r := (t - 0.4) / 0.6
		_ering(s, Vector2(0, 8), 20.0 + 150.0 * r, 6.0 + 42.0 * r, s._k(0.9 * (1.0 - r)), 4.0)
		_glow(s, Vector2(0, -24), 56.0 * q, fade)
		for k in range(6 if lq else 12):
			var a := TAU * float(k) / 12.0
			var p := Vector2(cos(a) * (30.0 + 100.0 * r), -20.0 + sin(a) * (14.0 + 40.0 * r) - 60.0 * r)
			_star(s, p, 4, 7.0 * (1.0 - r) + 1.0, 1.8, s._k(1.0 - r), a)
	for k in range(5 if lq else 9):
		var q := fposmod(t * 1.1 + float(k) * 0.12, 1.0)
		s.draw_circle(Vector2(-60.0 + fposmod(k * 31.0, 120.0), 6.0 - 80.0 * q), 2.0, s._k((1.0 - q) * fade))

# ---------------------------------------------------------------- tu linh thuat su

static func _witherskull(s, t: float, lq: bool) -> void:
	var fade := 1.0 - maxf(0.0, (t - 0.75) / 0.25)
	var c := Vector2(14.0 + 18.0 * t, -14.0 + sin(t * 9.0) * 3.0)
	_glow(s, c, 36.0, fade)
	for k in range(5 if lq else 8):
		var a := t * 5.0 + TAU * float(k) / 8.0
		var pts := PackedVector2Array()
		for i in range(7):
			var u := float(i) / 6.0
			var aa := a + u * 1.6
			pts.append(c + Vector2(cos(aa), sin(aa)) * (26.0 + 22.0 * u))
		s.draw_polyline(pts, s._a(0.4 * fade * (1.0 - 0.0)), 3.0)
	var sr := 15.0 * minf(1.0, t * 3.0)
	_skull(s, c, sr, s._k(1.0), 0.95 * fade)
	# cánh hoa héo úa rơi + tan
	for k in range(6 if lq else 11):
		var q := fposmod(t * 0.9 + float(k) * 0.09, 1.0)
		var x := c.x - 38.0 + fposmod(k * 29.0, 76.0) + sin(q * 7.0 + k) * 8.0
		var y := c.y - 30.0 + 80.0 * q
		var ang := q * 9.0 + k
		s.draw_set_transform(Vector2(x, y), ang, Vector2(1.0, 0.5))
		s.draw_circle(Vector2.ZERO, 5.0 * (1.0 - q * 0.6), Color(0.35 + 0.15 * (k % 2), 0.22, 0.12, 0.85 * (1.0 - q) * fade))
		_x0(s)
	s.draw_arc(c, 18.0 + 40.0 * t, 0.0, TAU, 32, s._a(0.6 * (1.0 - t) * fade), 2.0)

static func _soulchains(s, t: float, lq: bool) -> void:
	var fade := 1.0 - maxf(0.0, (t - 0.8) / 0.2)
	var cc := Vector2(0, -10)
	var close := minf(1.0, t * 2.0)
	for L in range(2):
		var n := 14 if lq else 22
		for i in range(n):
			var u := float(i) / float(n - 1)
			var a := t * 5.0 * (1.0 if L == 0 else -1.0) + u * TAU * 1.3 + L * PI
			var rr := lerpf(52.0, 24.0, close) * (0.9 + 0.1 * u)
			var p := cc + Vector2(cos(a) * rr * 0.6, -32.0 + 64.0 * u + sin(a) * 6.0)
			var q := clampf(t * 3.0 - u * 0.8, 0.0, 1.0)
			if q <= 0.0: continue
			var tg := Vector2(-sin(a) * 0.6, 0.0).rotated(0.0) + Vector2(0, 2.0)
			s.draw_set_transform(p, tg.angle(), Vector2.ONE)
			if i % 2 == 0:
				s.draw_arc(Vector2.ZERO, 4.0, 0.0, TAU, 8, s._a(0.95 * fade), 2.0)
			else:
				s.draw_line(Vector2(-4, 0), Vector2(4, 0), s._k(0.9 * fade), 2.4)
			_x0(s)
	# còng xiềng ở giữa siết lại
	_ering(s, Vector2(0, 26), 40.0 * (1.0 - 0.3 * close), 10.0, s._a(0.7 * fade), 3.0)
	_ering(s, Vector2(0, -10), 34.0 * (1.0 - 0.3 * close), 9.0, s._k(0.8 * fade), 2.2)
	for k in range(3):
		var q := fposmod(t * 1.2 + k * 0.33, 1.0)
		s.draw_circle(Vector2(-20.0 + k * 20.0, 22.0 - 56.0 * q), 3.0, s._k(sin(q * PI) * fade))

static func _soulchainblast(s, t: float, lq: bool) -> void:
	var fade := 1.0 - maxf(0.0, (t - 0.82) / 0.18)
	var n := 4 if lq else 5
	var pos: Array = []
	for i in range(n):
		pos.append(Vector2(-14.0 + 34.0 * i, -8.0 + (16.0 if i % 2 == 0 else -14.0) + sin(t * 6.0 + i) * 3.0))
	for i in range(n):
		var det := 0.12 + 0.15 * float(i)
		var p: Vector2 = pos[i]
		if i + 1 < n and t < det + 0.25:
			var p2: Vector2 = pos[i + 1]
			var mid := (p + p2) * 0.5 + Vector2(0, -10.0 - 4.0 * sin(t * 30.0 + i))
			s.draw_polyline(PackedVector2Array([p, mid, p2]), s._k(0.75 * fade), 1.6)
		if t < det:
			_glow(s, p, 15.0, fade)
			s.draw_circle(p, 6.0, s._a(0.95 * fade))
			s.draw_circle(p + Vector2(0, -1), 3.0, s._k(fade))
			_wisp(s, p + Vector2(-2, 6), Vector2(0, 1), 18.0, 2.0, 0.8 * fade)
		else:
			var q := clampf((t - det) / 0.4, 0.0, 1.0)
			s.draw_circle(p, 10.0 + 28.0 * q, s._a(0.4 * (1.0 - q) * fade))
			s.draw_arc(p, 8.0 + 36.0 * q, 0.0, TAU, 28, s._k((1.0 - q) * fade), 3.0)
			var m := 6 if lq else 9
			for k in range(m):
				var a := TAU * float(k) / float(m)
				var d := Vector2(cos(a), sin(a))
				s.draw_line(p + d * (8.0 + 16.0 * q), p + d * (14.0 + 30.0 * q), s._a(0.9 * (1.0 - q) * fade), 2.0)

static func _soulsplit(s, t: float, lq: bool) -> void:
	var fade := 1.0 - maxf(0.0, (t - 0.7) / 0.3)
	var e := minf(1.0, t * 1.6)
	var ph := t * 12.0
	# thân gốc mờ dần ở giữa
	_ghost(s, Vector2(0, -14), 52.0, s._a(1.0), 0.3 * (1.0 - e) * fade, ph, false)
	for sgn in [-1.0, 1.0]:
		var cx: float = sgn * 40.0 * e
		_glow(s, Vector2(cx, -10), 40.0, 0.7 * fade)
		_ghost(s, Vector2(cx, -14.0 - 6.0 * e), 52.0, s._k(1.0), 0.75 * fade, ph + sgn)
		var n := 4 if lq else 7
		for i in range(n):
			var u := float(i) / float(n - 1)
			var p := Vector2(cx * u, -14.0 + sin(u * PI) * -10.0)
			s.draw_circle(p, 1.8, s._a(0.8 * (1.0 - e * 0.7) * fade))
	s.draw_line(Vector2(-40.0 * e, -12), Vector2(40.0 * e, -12), s._k(0.5 * (1.0 - e) * fade), 1.5)
	_ering(s, Vector2(0, 26), 20.0 + 50.0 * e, 6.0 + 14.0 * e, s._a(0.6 * fade), 2.0)

static func _deathmist(s, t: float, lq: bool) -> void:
	var fade := minf(1.0, t * 3.0) * (1.0 - maxf(0.0, (t - 0.8) / 0.2))
	_efill(s, Vector2(0, 4), 96.0, 14.0, s._a(0.2 * fade))
	var n := 10 if lq else 20
	for i in range(n):
		var u := float(i) / float(n)
		var x := -88.0 + 176.0 * u + sin(t * 2.0 + i * 1.3) * 10.0
		var y := 4.0 - fposmod(i * 7.0, 20.0) * 0.6 + sin(t * 3.0 + i) * 3.0
		var r := 18.0 + 8.0 * sin(i * 2.7)
		s.draw_circle(Vector2(x, y), r, s._mix(0.0, 0.2 * fade))
		s.draw_circle(Vector2(x + 4.0, y - 4.0), r * 0.62, s._mix(0.5, 0.14 * fade))
	# vòi khí tử bốc lên
	for k in range(4 if lq else 7):
		var x0 := -74.0 + 148.0 * float(k) / 6.0
		var pts := PackedVector2Array()
		for i in range(8):
			var u := float(i) / 7.0
			pts.append(Vector2(x0 + sin(u * 5.0 + t * 4.0 + k) * 8.0, 0.0 - 70.0 * u * minf(1.0, t * 2.0)))
		s.draw_polyline(pts, s._a(0.32 * fade), 5.0)
	# mặt sọ mờ trôi trong sương
	for k in range(2 if lq else 3):
		var q := fposmod(t * 0.8 + float(k) * 0.33, 1.0)
		_skull(s, Vector2(-50.0 + 50.0 * k + sin(q * 5.0) * 6.0, -10.0 - 40.0 * q), 8.0, s._k(1.0), 0.5 * sin(q * PI) * fade)

static func _shadowsummon(s, t: float, lq: bool) -> void:
	var g := minf(1.0, t * 2.5)
	var fade := 1.0 - maxf(0.0, (t - 0.8) / 0.2)
	_efill(s, Vector2(0, 6), 56.0 * g, 16.0, Color(0.1, 0.0, 0.15, 0.6 * fade))
	_ering(s, Vector2(0, 6), 56.0 * g, 16.0 * g, s._a(0.95 * fade), 2.6)
	s.draw_set_transform(Vector2(0, 6), 0.0, Vector2(1.0, 0.29))
	for k in range(6):
		var a := t * 2.0 + TAU * float(k) / 6.0
		var d := Vector2(cos(a), sin(a))
		s.draw_line(d * 42.0 * g, d * 52.0 * g, s._k(0.9 * fade), 2.0)
	_x0(s)
	# bóng người trồi lên
	var rise := clampf((t - 0.1) * 1.8, 0.0, 1.0)
	var h := 66.0 * rise
	if h > 8.0:
		var base := Vector2(0, 8.0)
		var body := PackedVector2Array([base + Vector2(-17, 0), base + Vector2(-13, -h * 0.5), base + Vector2(-8, -h * 0.82), base + Vector2(8, -h * 0.82), base + Vector2(13, -h * 0.5), base + Vector2(17, 0)])
		_poly(s, body, Color(0.04, 0.0, 0.08, 0.88 * fade))
		s.draw_polyline(body, s._a(0.8 * fade), 1.6)
		s.draw_circle(base + Vector2(0, -h * 0.92), 9.0, Color(0.04, 0.0, 0.08, 0.92 * fade))
		s.draw_arc(base + Vector2(0, -h * 0.92), 9.0, 0.0, TAU, 16, s._a(0.7 * fade), 1.4)
		s.draw_circle(base + Vector2(-3.5, -h * 0.93), 1.8, s._k(fade))
		s.draw_circle(base + Vector2(3.5, -h * 0.93), 1.8, s._k(fade))
		for sg in [-1.0, 1.0]:
			s.draw_line(base + Vector2(sg * 12.0, -h * 0.6), base + Vector2(sg * (24.0 + 6.0 * sin(t * 9.0)), -h * 0.35), s._a(0.8 * fade), 3.0)
	for k in range(4 if lq else 8):
		var a := TAU * float(k) / 8.0 + 0.4
		var pts := PackedVector2Array()
		for i in range(6):
			var u := float(i) / 5.0
			pts.append(Vector2(cos(a) * 52.0 * (1.0 - 0.5 * u) + sin(u * 6.0 + t * 6.0) * 4.0, 6.0 + sin(a) * 14.0 - 46.0 * u * rise))
		s.draw_polyline(pts, Color(0.1, 0.0, 0.18, 0.5 * fade), 4.0)

static func _soulsiphon(s, t: float, lq: bool) -> void:
	var fade := 1.0 - maxf(0.0, (t - 0.82) / 0.18)
	var c := Vector2(0, -8)
	var n := 5 if lq else 9
	for k in range(n):
		var side := 1.0 if k % 2 == 0 else -1.0
		var q := fposmod(t * 1.15 + float(k) * 0.11, 1.0)
		var a := float(k) * 0.9
		var start := c + Vector2(side * 96.0, sin(a) * 40.0 - 6.0)
		var p := start.lerp(c, q * q * 0.5 + q * 0.5) + Vector2(0, sin(q * 7.0 + a) * 10.0 * (1.0 - q))
		var dirv := (start - p).normalized()
		_wisp(s, p, dirv, 30.0 * (1.0 - q * 0.4), 2.4 * (0.6 + q * 0.6), (0.4 + 0.6 * q) * fade)
	var pulse := 0.5 + 0.5 * sin(t * 22.0)
	_glow(s, c, 22.0 + 12.0 * t + 4.0 * pulse, fade)
	s.draw_arc(c, 30.0 * (1.0 - fposmod(t * 2.0, 1.0)) + 8.0, 0.0, TAU, 28, s._k(0.7 * fade), 1.6)
	_ering(s, Vector2(0, 26), 40.0, 10.0, s._a(0.3 * fade), 2.0)

static func _phantomarmy(s, t: float, lq: bool) -> void:
	var fade := minf(1.0, t * 3.0) * (1.0 - maxf(0.0, (t - 0.82) / 0.18))
	_efill(s, Vector2(30, 6), 100.0, 14.0, s._a(0.2 * fade))
	var rows := 1 if lq else 2
	for rw in range(rows):
		for i in range(4):
			var rise := clampf(t * 2.6 - float(i) * 0.12 - rw * 0.1, 0.0, 1.0)
			if rise <= 0.0: continue
			var sc := 1.0 - rw * 0.2
			var x := -34.0 + float(i) * 34.0 + t * 38.0 - rw * 16.0
			var base := Vector2(x, 8.0 - rw * 7.0)
			var h := 54.0 * sc * rise
			var al := (0.8 - rw * 0.25) * fade
			var bob := sin(t * 14.0 + i * 1.7) * 2.0
			if h < 14.0: continue
			# áo choàng rách
			_poly(s, PackedVector2Array([base + Vector2(-11 * sc, bob), base + Vector2(-8 * sc, -h * 0.6), base + Vector2(8 * sc, -h * 0.6), base + Vector2(11 * sc, bob), base + Vector2(6 * sc, bob - 5 * sc), base + Vector2(2 * sc, bob), base + Vector2(-3 * sc, bob - 6 * sc), base + Vector2(-7 * sc, bob)]), s._a(al))
			s.draw_circle(base + Vector2(0, -h * 0.74), 7.0 * sc, s._a(al))
			s.draw_circle(base + Vector2(2.5 * sc, -h * 0.76), 1.7 * sc, s._k(fade))
			s.draw_circle(base + Vector2(-1.5 * sc, -h * 0.76), 1.7 * sc, s._k(fade))
			# giáo
			var sp := base + Vector2(12.0 * sc, -h * 0.2)
			s.draw_line(sp + Vector2(-3, 18.0 * sc), sp + Vector2(5, -h * 0.75), s._k(0.9 * al), 1.6)
			_poly(s, PackedVector2Array([sp + Vector2(2, -h * 0.75), sp + Vector2(5, -h * 0.75 - 12.0 * sc), sp + Vector2(8, -h * 0.75)]), s._k(al))
	# cờ hiệu ma
	var fx := 6.0 + t * 38.0
	s.draw_line(Vector2(fx, 8), Vector2(fx, -84), s._k(0.7 * fade), 1.6)
	_poly(s, PackedVector2Array([Vector2(fx, -84), Vector2(fx + 20.0, -78.0 + sin(t * 12.0) * 3.0), Vector2(fx + 14.0, -70.0), Vector2(fx + 22.0, -62.0 + sin(t * 12.0 + 1.0) * 3.0), Vector2(fx, -60)]), s._a(0.8 * fade))

static func _netherportal(s, t: float, lq: bool) -> void:
	var fade := 1.0 - maxf(0.0, (t - 0.8) / 0.2)
	var g := minf(1.0, t * 3.0)
	var c := Vector2(10, -22)
	var rx := 26.0 * g
	var ry := 54.0 * g
	if rx < 4.0: return
	# lòng cổng: xoáy vô tận
	s.draw_set_transform(c, 0.0, Vector2(rx / ry, 1.0))
	s.draw_circle(Vector2.ZERO, ry, Color(0.02, 0.0, 0.06, 0.9 * fade))
	for L in range(4):
		var pts := PackedVector2Array()
		for i in range(13):
			var u := float(i) / 12.0
			var a := t * 8.0 + u * 7.0 + L * PI * 0.5
			pts.append(Vector2(cos(a), sin(a)) * ry * (1.0 - u * 0.9))
		s.draw_polyline(pts, s._a(0.75 * fade), 2.2)
	s.draw_arc(Vector2.ZERO, ry, 0.0, TAU, 40, s._a(0.95 * fade), 4.0)
	s.draw_arc(Vector2.ZERO, ry + 5.0, 0.0, TAU, 40, s._k(0.6 * fade), 1.5)
	_x0(s)
	# khung cổng đá
	s.draw_rect(Rect2(c.x - rx - 8.0, c.y - ry, 6.0, ry * 2.0 + 6.0), Color(0.1, 0.08, 0.14, 0.9 * fade))
	s.draw_rect(Rect2(c.x + rx + 2.0, c.y - ry, 6.0, ry * 2.0 + 6.0), Color(0.1, 0.08, 0.14, 0.9 * fade))
	s.draw_arc(Vector2(c.x, c.y - ry * 0.55), rx + 5.0, PI, TAU, 14, Color(0.1, 0.08, 0.14, 0.9 * fade), 7.0)
	# bàn tay xương trườn ra
	for k in range(2):
		var q := clampf((t - 0.3 - k * 0.12) * 2.2, 0.0, 1.0)
		var o := c + Vector2(rx * 0.3 + k * 8.0, 8.0 + k * 14.0)
		var tip := o + Vector2(46.0 * q, -6.0 * q)
		s.draw_line(o, tip, s._k(0.9 * fade), 3.0)
		for f in range(3):
			s.draw_line(tip, tip + Vector2(9.0, -6.0 + f * 6.0) * q, s._k(0.9 * fade), 1.8)
	for k in range(4 if lq else 8):
		var q := fposmod(t * 1.1 + float(k) * 0.125, 1.0)
		_wisp(s, c + Vector2(rx * 0.2 + 70.0 * q, sin(k * 2.1) * 36.0), Vector2(-1, 0), 18.0, 2.0, sin(q * PI) * fade)

static func _demonclaw(s, t: float, lq: bool) -> void:
	var fade := 1.0 - maxf(0.0, (t - 0.65) / 0.35)
	# bóng bàn tay quỷ phía sau
	var hp := Vector2(-30.0 + 30.0 * t, -38.0 + 76.0 * t)
	s.draw_circle(hp, 16.0, s._a(0.35 * fade))
	for k in range(4):
		var off := Vector2(-3.0 + k * 8.0, 0.0)
		_poly(s, PackedVector2Array([hp + off + Vector2(-3, 0), hp + off + Vector2(3, 0), hp + off + Vector2(8.0 + k, 18.0)]), s._a(0.5 * fade))
	# bốn vết cào cong, tăng dần theo tiến độ
	var n := 3 if lq else 4
	for k in range(n):
		var q := clampf(t * 1.9 - float(k) * 0.07, 0.0, 1.0)
		if q <= 0.0: continue
		var ox := (float(k) - float(n - 1) * 0.5) * 17.0
		var pts_o := PackedVector2Array()
		var pts_i := PackedVector2Array()
		var m := 10
		var m2 := maxi(2, int(float(m) * q))
		for i in range(m2 + 1):
			var u := float(i) / float(m)
			var p := Vector2(ox - 26.0 + 52.0 * u + sin(u * PI) * 12.0, -50.0 + 100.0 * u)
			var w := sin(u * PI) * 6.0 + 0.8
			pts_o.append(p + Vector2(w, 0.0))
			pts_i.append(p - Vector2(w, 0.0))
		var all := PackedVector2Array(pts_o)
		for i in range(pts_i.size() - 1, -1, -1):
			all.append(pts_i[i])
		_poly(s, all, s._a(0.9 * fade))
		if pts_o.size() > 1:
			s.draw_polyline(PackedVector2Array(pts_o), s._k(0.95 * fade), 1.6)
	for k in range(3 if lq else 7):
		var q := fposmod(t * 1.3 + float(k) * 0.14, 1.0)
		s.draw_circle(Vector2(-20.0 + 14.0 * k + 18.0 * q, -30.0 + 70.0 * q), 2.2, s._k((1.0 - q) * fade))
	_wisp(s, Vector2(28.0, 40.0), Vector2(-0.4, -1).normalized(), 30.0, 2.0, 0.6 * fade)

static func _soulward(s, t: float, lq: bool) -> void:
	var fade := 1.0 - maxf(0.0, (t - 0.85) / 0.15)
	var g := minf(1.0, t * 3.5)
	var cc := Vector2(0, -6)
	for i in range(4):
		var u := float(i) / 3.0
		s.draw_circle(cc, 44.0 * (1.0 - u * 0.5) * g, s._mix(u, 0.06 + 0.04 * u))
	s.draw_arc(cc, 44.0 * g, 0.0, TAU, 40, s._a(0.7 * fade), 2.2)
	var n := 3 if lq else 5
	for k in range(n):
		var a := t * 5.5 + TAU * float(k) / float(n)
		var p := cc + Vector2(cos(a) * 38.0, sin(a) * 38.0 * 0.55) * g
		var dirv := Vector2(sin(a), -cos(a) * 0.55).normalized()
		_wisp(s, p, -dirv, 34.0, 3.2, fade)
		s.draw_circle(p + Vector2(-2.0, -1.0), 1.1, Color(DARK.r, DARK.g, DARK.b, 0.9 * fade))
		s.draw_circle(p + Vector2(2.0, -1.0), 1.1, Color(DARK.r, DARK.g, DARK.b, 0.9 * fade))
	_skull(s, cc + Vector2(0, -2), 9.0 * g, s._k(1.0), 0.35 * (0.6 + 0.4 * sin(t * 12.0)) * fade)
	_ering(s, Vector2(0, 26), 36.0, 9.0, s._a(0.5 * fade), 2.0)

static func _ghosttide(s, t: float, lq: bool) -> void:
	var fade := 1.0 - maxf(0.0, (t - 0.85) / 0.15)
	var g := minf(1.0, t * 2.0)
	_efill(s, Vector2(0, 6), 150.0 * g, 18.0, s._a(0.2 * fade))
	var front := -140.0 + 280.0 * minf(1.0, t * 1.5)
	# mặt sóng cuộn
	var pts := PackedVector2Array()
	var n := 16 if lq else 28
	for i in range(n + 1):
		var u := float(i) / float(n)
		var x := -140.0 + (front + 140.0) * u
		var ph := u * 7.0 - t * 6.0
		pts.append(Vector2(x, 6.0 - (40.0 + 30.0 * u) * (0.55 + 0.45 * sin(ph)) * g))
	s.draw_polyline(pts, s._a(0.35 * fade), 14.0)
	s.draw_polyline(pts, s._a(0.95 * fade), 4.0)
	s.draw_polyline(pts, s._k(0.8 * fade), 1.6)
	var poly := PackedVector2Array([Vector2(-140, 8)])
	for p in pts: poly.append(p)
	poly.append(Vector2(front, 8))
	_poly(s, poly, s._mix(0.0, 0.2 * fade))
	# oan hồn cưỡi trên sóng
	var ng := 4 if lq else 8
	for k in range(ng):
		var u := float(k) / float(ng - 1) * 0.92 + 0.04
		var idx := int(u * float(n))
		var p: Vector2 = pts[idx] + Vector2(0, -16.0 - 6.0 * sin(t * 9.0 + k))
		var sz := 22.0 + 10.0 * u
		_ghost(s, p, sz, s._k(1.0), 0.75 * fade, t * 12.0 + k)
	# bọt linh hồn
	var nb := 4 if lq else 9
	for k in range(nb):
		var q := fposmod(t * 1.1 + float(k) * 0.11, 1.0)
		s.draw_circle(Vector2(-120.0 + fposmod(k * 61.0, 240.0) * g, 6.0 - 70.0 * q), 2.4, s._k((1.0 - q) * fade))

static func _soulfusion(s, t: float, lq: bool) -> void:
	var fade := 1.0 - maxf(0.0, (t - 0.88) / 0.12)
	var c := Vector2(0, -10)
	var conv := minf(1.0, t / 0.55)
	var n := 8 if lq else 14
	for k in range(n):
		var u := float(k) / float(n)
		var a := TAU * u + t * 6.0 * (1.0 - conv * 0.4)
		var r := (96.0 * (1.0 - conv) + 6.0) * (0.7 + 0.3 * fposmod(u * 5.0, 1.0))
		var p := c + Vector2(cos(a) * r, sin(a) * r * 0.7)
		var dirv := Vector2(-sin(a), cos(a) * 0.7).normalized()
		_wisp(s, p, -dirv, 26.0, 2.6, (0.5 + 0.5 * conv) * fade)
	var orb := (8.0 + 22.0 * conv) * (1.0 + 0.08 * sin(t * 26.0))
	_glow(s, c, orb * 2.0, fade)
	s.draw_circle(c, orb, s._a(0.9 * fade))
	s.draw_circle(c, orb * 0.6, s._k(0.95 * fade))
	if t > 0.5:
		var q := minf(1.0, (t - 0.5) / 0.3)
		_skull(s, c + Vector2(0, -4), 34.0 * q, s._k(1.0), 0.55 * q * fade)
		var r2 := (t - 0.5) / 0.5
		_ering(s, Vector2(0, 26), 20.0 + 100.0 * r2, 6.0 + 28.0 * r2, s._a(0.9 * (1.0 - r2)), 3.5)
		s.draw_arc(c, 30.0 + 90.0 * r2, 0.0, TAU, 40, s._k(0.8 * (1.0 - r2)), 3.0)
		for k in range(6 if lq else 12):
			var a := TAU * float(k) / 12.0
			var d := Vector2(cos(a), sin(a))
			s.draw_line(c + d * (26.0 + 60.0 * r2), c + d * (36.0 + 90.0 * r2), s._a(0.9 * (1.0 - r2)), 2.4)
