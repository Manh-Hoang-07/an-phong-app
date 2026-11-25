extends RefCounted
## Hiệu ứng kỹ năng riêng (nhóm b): tanker + kiếm sĩ. Vẽ lên node `s` (Node2D đang trong _draw): s.draw_*, s._a(alpha) màu chính, s._k(alpha) màu lõi, s._rng.
## IDS: id kỹ năng -> sig. CFG: sig -> {"place": "front"|"body"|"ground"|"far", "dur": giây, "nopop": bool, "rumble": số}.
## Quy ước toạ độ: +x là hướng nhìn (node tự lật theo hướng), y=0 gần ngang người, mặt đất ở y~+28 (place ground: y=0 là mặt đất).
const IDS := {
	# --- tanker
	"hv25": "t_disc", "hv27": "t_bash", "hv30": "t_wall", "hv32": "t_willguard", "hv35": "t_crack",
	"hv37": "t_shieldvortex", "hv38": "t_bastion", "hv40": "t_march", "hv42": "t_earthdragon", "hv45": "t_banner",
	"tk1": "t_shieldbreak", "tk2": "t_steelring", "tk3": "t_fury", "tk4": "t_ironarmor", "tk5": "t_steelwave",
	"tk6": "t_tremor", "tk7": "t_keep", "tk8": "t_charge", "tk9": "t_roar", "tk10": "t_thorns", "tk11": "t_hammer",
	"ulTank1": "t_bronzewall", "ulTank2": "t_worldquake", "ulTankSuper": "t_hexdome",
	# --- kiếm sĩ
	"ks25": "k_sweep", "ks27": "k_windthrust", "ks32": "k_swordintent", "ks35": "k_dragonshadow", "ks37": "k_trisword",
	"ks38": "k_riverqi", "ks42": "k_cloudsword", "pa1": "k_dashslash", "pa2": "k_chain", "pa3": "k_berserk",
	"pa4": "k_willshield", "pa5": "k_heavensword", "pa6": "k_swordloop", "pa7": "k_armybreak", "pa8": "k_pierce",
	"pa10": "k_cyclone", "pa11": "k_crossqi", "ulKiem2": "k_swordbloom",
}
const CFG := {
	"t_disc": {"place": "front", "dur": 0.75, "nopop": true},
	"t_bash": {"place": "front", "dur": 0.7, "nopop": true},
	"t_wall": {"place": "front", "dur": 1.0, "nopop": true},
	"t_willguard": {"place": "body", "dur": 1.2, "nopop": true},
	"t_crack": {"place": "ground", "dur": 1.0, "nopop": true, "rumble": 6.0},
	"t_shieldvortex": {"place": "body", "dur": 1.0, "nopop": true},
	"t_bastion": {"place": "ground", "dur": 1.2, "nopop": true},
	"t_march": {"place": "front", "dur": 0.8, "nopop": true},
	"t_earthdragon": {"place": "ground", "dur": 1.1, "nopop": true, "rumble": 5.0},
	"t_banner": {"place": "front", "dur": 1.2, "nopop": true},
	"t_shieldbreak": {"place": "front", "dur": 0.8, "nopop": true},
	"t_steelring": {"place": "body", "dur": 1.0, "nopop": true},
	"t_fury": {"place": "body", "dur": 1.1, "nopop": true},
	"t_ironarmor": {"place": "body", "dur": 1.1, "nopop": true},
	"t_steelwave": {"place": "front", "dur": 1.0, "nopop": true, "rumble": 4.0},
	"t_tremor": {"place": "ground", "dur": 1.1, "nopop": true, "rumble": 8.0},
	"t_keep": {"place": "ground", "dur": 1.3, "nopop": true},
	"t_charge": {"place": "front", "dur": 0.75, "nopop": true},
	"t_roar": {"place": "front", "dur": 0.95, "nopop": true},
	"t_thorns": {"place": "body", "dur": 1.0, "nopop": true},
	"t_hammer": {"place": "far", "dur": 1.0, "nopop": true, "rumble": 8.0},
	"t_bronzewall": {"place": "ground", "dur": 1.4, "nopop": true},
	"t_worldquake": {"place": "ground", "dur": 1.5, "nopop": true, "rumble": 14.0},
	"t_hexdome": {"place": "body", "dur": 1.5, "nopop": true},
	"k_sweep": {"place": "front", "dur": 0.7, "nopop": true},
	"k_windthrust": {"place": "front", "dur": 0.7, "nopop": true},
	"k_swordintent": {"place": "body", "dur": 1.2, "nopop": true},
	"k_dragonshadow": {"place": "front", "dur": 0.9, "nopop": true},
	"k_trisword": {"place": "front", "dur": 0.9, "nopop": true},
	"k_riverqi": {"place": "front", "dur": 0.8, "nopop": true},
	"k_cloudsword": {"place": "body", "dur": 1.1, "nopop": true},
	"k_dashslash": {"place": "front", "dur": 0.7, "nopop": true},
	"k_chain": {"place": "front", "dur": 0.9, "nopop": true},
	"k_berserk": {"place": "body", "dur": 1.1, "nopop": true},
	"k_willshield": {"place": "body", "dur": 1.2, "nopop": true},
	"k_heavensword": {"place": "far", "dur": 1.1, "nopop": true, "rumble": 7.0},
	"k_swordloop": {"place": "body", "dur": 1.0, "nopop": true},
	"k_armybreak": {"place": "front", "dur": 0.95, "nopop": true},
	"k_pierce": {"place": "front", "dur": 0.7, "nopop": true},
	"k_cyclone": {"place": "body", "dur": 1.0, "nopop": true},
	"k_crossqi": {"place": "front", "dur": 0.85, "nopop": true},
	"k_swordbloom": {"place": "body", "dur": 1.3, "nopop": true},
}

static func draw(s: Node2D, sg: String, t: float, lowq: bool) -> void:
	var n = s
	match sg:
		"t_disc": _disc(n, t, lowq)
		"t_bash": _bash(n, t, lowq)
		"t_wall": _wall(n, t, lowq)
		"t_willguard": _willguard(n, t, lowq)
		"t_crack": _crack(n, t, lowq)
		"t_shieldvortex": _shieldvortex(n, t, lowq)
		"t_bastion": _bastion(n, t, lowq)
		"t_march": _march(n, t, lowq)
		"t_earthdragon": _earthdragon(n, t, lowq)
		"t_banner": _banner(n, t, lowq)
		"t_shieldbreak": _shieldbreak(n, t, lowq)
		"t_steelring": _steelring(n, t, lowq)
		"t_fury": _fury(n, t, lowq)
		"t_ironarmor": _ironarmor(n, t, lowq)
		"t_steelwave": _steelwave(n, t, lowq)
		"t_tremor": _tremor(n, t, lowq)
		"t_keep": _keep(n, t, lowq)
		"t_charge": _charge(n, t, lowq)
		"t_roar": _roar(n, t, lowq)
		"t_thorns": _thorns(n, t, lowq)
		"t_hammer": _hammer(n, t, lowq)
		"t_bronzewall": _bronzewall(n, t, lowq)
		"t_worldquake": _worldquake(n, t, lowq)
		"t_hexdome": _hexdome(n, t, lowq)
		"k_sweep": _sweep(n, t, lowq)
		"k_windthrust": _windthrust(n, t, lowq)
		"k_swordintent": _swordintent(n, t, lowq)
		"k_dragonshadow": _dragonshadow(n, t, lowq)
		"k_trisword": _trisword(n, t, lowq)
		"k_riverqi": _riverqi(n, t, lowq)
		"k_cloudsword": _cloudsword(n, t, lowq)
		"k_dashslash": _dashslash(n, t, lowq)
		"k_chain": _chain(n, t, lowq)
		"k_berserk": _berserk(n, t, lowq)
		"k_willshield": _willshield(n, t, lowq)
		"k_heavensword": _heavensword(n, t, lowq)
		"k_swordloop": _swordloop(n, t, lowq)
		"k_armybreak": _armybreak(n, t, lowq)
		"k_pierce": _pierce(n, t, lowq)
		"k_cyclone": _cyclone(n, t, lowq)
		"k_crossqi": _crossqi(n, t, lowq)
		"k_swordbloom": _swordbloom(n, t, lowq)
		_: pass

# ============================================================ tiện ích
static func A(s, al: float) -> Color:
	return s._a(clampf(al, 0.0, 1.0))

static func K(s, al: float) -> Color:
	return s._k(clampf(al, 0.0, 1.0))

static func M(s, u: float, al: float) -> Color:
	return s._mix(u, clampf(al, 0.0, 1.0))

static func rst(s) -> void:
	s.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

static func sm(x: float) -> float:
	return smoothstep(0.0, 1.0, clampf(x, 0.0, 1.0))

static func glow(s, c: Vector2, r: float, al: float) -> void:
	for i in range(5):
		var u := float(i) / 4.0
		s.draw_circle(c, r * (1.0 - u * 0.8), M(s, u, al * (0.25 + 0.55 * u)))

## Vòng elip (rx ngang, ry dọc), xoay rot.
static func ering(s, c: Vector2, rx: float, ry: float, col: Color, w: float, rot: float = 0.0) -> void:
	if ry < 0.5 or rx < 0.5: return
	s.draw_set_transform(c, rot, Vector2(rx / ry, 1.0))
	s.draw_arc(Vector2.ZERO, ry, 0.0, TAU, 36, col, w)
	rst(s)

## Vệt chém thon hai đầu từ a đến b, rộng w.
static func slash(s, a: Vector2, b: Vector2, w: float, al: float) -> void:
	var d := b - a
	if d.length() < 1.0 or al <= 0.01: return
	var nr := d.orthogonal().normalized()
	var m := a.lerp(b, 0.5)
	s.draw_colored_polygon(PackedVector2Array([a, m + nr * w * 1.6, b, m - nr * w * 1.6]), A(s, al * 0.35))
	s.draw_colored_polygon(PackedVector2Array([a, m + nr * w, b, m - nr * w]), A(s, al * 0.85))
	s.draw_line(a, b, K(s, al), maxf(1.2, w * 0.35))

## Lưỡi kiếm (mũi ở b).
static func blade(s, a: Vector2, b: Vector2, w: float, al: float) -> void:
	var d := b - a
	if d.length() < 1.0 or al <= 0.01: return
	var nr := d.orthogonal().normalized()
	var m := a.lerp(b, 0.82)
	s.draw_colored_polygon(PackedVector2Array([a + nr * w * 0.6, m + nr * w, b, m - nr * w, a - nr * w * 0.6]), A(s, al * 0.85))
	s.draw_line(a, b, K(s, al), 1.4)
	s.draw_line(a + nr * w * 1.6, a - nr * w * 1.6, A(s, al), 2.5)

static func shield(s, p: Vector2, h: float, al: float, rot: float = 0.0) -> void:
	if al <= 0.01: return
	s.draw_set_transform(p, rot, Vector2.ONE)
	var w := h * 0.72
	var pts := PackedVector2Array([Vector2(-w, -h), Vector2(w, -h), Vector2(w, -h * 0.1), Vector2(w * 0.5, h * 0.55), Vector2(0, h), Vector2(-w * 0.5, h * 0.55), Vector2(-w, -h * 0.1)])
	s.draw_colored_polygon(pts, A(s, al * 0.5))
	var cl := pts.duplicate()
	cl.append(pts[0])
	s.draw_polyline(cl, K(s, al), 2.5)
	s.draw_line(Vector2(0, -h * 0.85), Vector2(0, h * 0.85), A(s, al), 2.0)
	s.draw_line(Vector2(-w * 0.8, -h * 0.1), Vector2(w * 0.8, -h * 0.1), A(s, al), 2.0)
	s.draw_circle(Vector2(0, -h * 0.1), h * 0.17, K(s, al))
	rst(s)

static func spike(s, base: Vector2, ang: float, ln: float, w: float, al: float) -> void:
	if ln < 1.0 or al <= 0.01: return
	var dir := Vector2(cos(ang), sin(ang))
	var nr := dir.orthogonal()
	var tip := base + dir * ln
	s.draw_colored_polygon(PackedVector2Array([base + nr * w, tip, base - nr * w]), A(s, al))
	s.draw_line(base, tip, K(s, al), 1.2)

static func rock(s, p: Vector2, sz: float, rot: float, al: float) -> void:
	s.draw_set_transform(p, rot, Vector2.ONE)
	s.draw_colored_polygon(PackedVector2Array([Vector2(-sz, -sz * 0.5), Vector2(-sz * 0.2, -sz), Vector2(sz * 0.9, -sz * 0.4), Vector2(sz, sz * 0.6), Vector2(-sz * 0.4, sz)]), A(s, al * 0.8))
	s.draw_line(Vector2(-sz * 0.2, -sz), Vector2(sz * 0.9, -sz * 0.4), K(s, al), 1.4)
	rst(s)

static func hexpoly(s, c: Vector2, r: float, rot: float, fill: Color, line: Color) -> void:
	var pts := PackedVector2Array()
	for k in range(6):
		var a := rot + TAU * float(k) / 6.0
		pts.append(c + Vector2(cos(a), sin(a)) * r)
	s.draw_colored_polygon(pts, fill)
	pts.append(pts[0])
	s.draw_polyline(pts, line, 1.6)

static func zig(s, a: Vector2, b: Vector2, jag: float, segs: int, al: float, w: float) -> void:
	var pts := PackedVector2Array([a])
	var d := b - a
	var nr := d.orthogonal().normalized()
	for i in range(1, segs):
		var u := float(i) / float(segs)
		pts.append(a + d * u + nr * rf(s, -jag, jag))
	pts.append(b)
	s.draw_polyline(pts, A(s, al * 0.4), w * 2.4)
	s.draw_polyline(pts, K(s, al), w)

static func man(s, pos: Vector2, rot: float, sc: float, al: float) -> void:
	s.draw_set_transform(pos, rot, Vector2(sc, sc))
	s._man(0.0, al)
	rst(s)

static func fade(t: float, from: float) -> float:
	return 1.0 - clampf((t - from) / maxf(0.001, 1.0 - from), 0.0, 1.0)

# ============================================================ TANKER
## Khiên Phi Trảm: đĩa khiên răng cưa xoay tít bay thẳng, để lại vệt.
static func _disc(s, t: float, lowq: bool) -> void:
	var x := lerpf(-34.0, 170.0, t)
	var spin := t * 46.0
	s._streak(Vector2(x - 100.0, -6.0), Vector2(x - 14.0, -6.0), 11.0)
	for i in range(1, 4 if lowq else 6):
		s.draw_arc(Vector2(x - i * 17.0, -6.0), 15.0, 0.0, TAU, 18, A(s, 0.32 / float(i)), 2.0)
	var c := Vector2(x, -6.0)
	glow(s, c, 28.0, 0.5)
	var sq := 0.5 + 0.5 * absf(cos(spin * 0.35))
	s.draw_set_transform(c, 0.0, Vector2(sq, 1.0))
	s.draw_circle(Vector2.ZERO, 17.0, A(s, 0.6))
	for k in range(8):
		var a := spin + TAU * float(k) / 8.0
		var dir := Vector2(cos(a), sin(a))
		var nr := dir.orthogonal()
		s.draw_colored_polygon(PackedVector2Array([dir * 15.0 + nr * 4.0, dir * 26.0, dir * 15.0 - nr * 4.0]), A(s, 0.9))
	s.draw_arc(Vector2.ZERO, 17.0, 0.0, TAU, 28, K(s, 0.95), 3.0)
	s.draw_arc(Vector2.ZERO, 10.0, 0.0, TAU, 20, A(s, 0.95), 2.0)
	s.draw_circle(Vector2.ZERO, 4.5, K(s, 1.0))
	rst(s)
	if t > 0.85:
		var h := (t - 0.85) / 0.15
		s.draw_arc(c + Vector2(14, 0), 10.0 + 26.0 * h, 0.0, TAU, 24, K(s, 0.8 * (1.0 - h)), 3.0)

## Thuẫn Kích: khiên to đập mạnh về trước, nổ tia va chạm + sóng dọc.
static func _bash(s, t: float, lowq: bool) -> void:
	var q := minf(1.0, t * 3.2)
	var px := lerpf(-34.0, 50.0, q * q * (3.0 - 2.0 * q))
	var hit := clampf((t - 0.3) / 0.7, 0.0, 1.0)
	var shake := 0.0
	if t > 0.3 and hit < 0.4: shake = sin(t * 120.0) * 2.5
	if q < 1.0:
		for k in range(4):
			s.draw_line(Vector2(px - 30.0 - k * 6.0, -24.0 + k * 14.0), Vector2(px - 70.0, -24.0 + k * 14.0), A(s, 0.5 * (1.0 - q)), 3.0)
	shield(s, Vector2(px + shake, -6.0), 34.0, 1.0)
	if t > 0.3:
		var c := Vector2(66.0, -6.0)
		glow(s, c, 18.0 + 46.0 * hit, 0.55 * (1.0 - hit))
		var nr := 7 if lowq else 12
		for k in range(nr):
			var a := TAU * float(k) / float(nr) + 0.2
			spike(s, c + Vector2(cos(a), sin(a)) * (10.0 + 16.0 * hit), a, 12.0 + 40.0 * hit * (0.6 + 0.4 * float(k % 2)), 3.5, 1.0 - hit)
		ering(s, c, 8.0 + 26.0 * hit, 22.0 + 52.0 * hit, K(s, 0.9 * (1.0 - hit)), 4.0)
		ering(s, c, 4.0 + 16.0 * hit, 14.0 + 36.0 * hit, A(s, 0.8 * (1.0 - hit)), 2.0)

## Thuẫn Trận Phản Chấn: hàng khiên tháp dựng lên, sóng chấn dội ngược ra.
static func _wall(s, t: float, lowq: bool) -> void:
	var f := sm(t * 2.6)
	for i in range(5):
		var yy := -48.0 + 24.0 * float(i)
		var xx := 22.0 + 7.0 * absf(float(i) - 2.0)
		var rise := clampf(f * 1.4 - 0.12 * float(i), 0.0, 1.0)
		shield(s, Vector2(xx, yy + (1.0 - rise) * 70.0), 18.0, rise)
	glow(s, Vector2(24.0, -6.0), 60.0, 0.22 * f)
	var nw := 2 if lowq else 4
	for i in range(nw):
		var r := clampf(t * 1.5 - 0.14 * float(i) - 0.25, 0.0, 1.0)
		if r <= 0.0: continue
		var c := Vector2(26.0, -4.0)
		var rad := 16.0 + 130.0 * r
		var al := 1.0 - r
		s.draw_arc(c, rad, -0.9, 0.9, 20, A(s, 0.35 * al), 9.0)
		s.draw_arc(c, rad, -0.9, 0.9, 20, K(s, 0.9 * al), 3.0)
		# tia phản ngược lại
		var a2 := PI + (float(i) - 1.5) * 0.4
		s.draw_line(c + Vector2(cos(a2), sin(a2)) * 20.0, c + Vector2(cos(a2), sin(a2)) * (20.0 + 60.0 * r), K(s, 0.7 * al), 2.0)

## Ý Chí Hộ Vệ: các khiên nhỏ xoay quanh người cùng vòng ý chí vàng.
static func _willguard(s, t: float, lowq: bool) -> void:
	var f := sm(t * 3.0)
	var pulse := 1.0 + 0.05 * sin(t * 24.0)
	glow(s, Vector2(0, -4), 44.0 * f, 0.3)
	ering(s, Vector2(0, 26), 46.0 * f * pulse, 14.0 * f, A(s, 0.8), 3.0)
	ering(s, Vector2(0, 26), 34.0 * f, 10.0 * f, K(s, 0.7), 1.5)
	var n := 3 if lowq else 4
	for k in range(n):
		var a := t * 6.0 + TAU * float(k) / float(n)
		var depth := sin(a)
		var p := Vector2(cos(a) * 46.0 * f, depth * 14.0 - 4.0)
		shield(s, p, 11.0 + 3.0 * depth, 0.55 + 0.45 * (depth * 0.5 + 0.5))
	for k in range(6):
		var u := fposmod(t * 0.9 + float(k) * 0.17, 1.0)
		var xx := -30.0 + 12.0 * float(k)
		s.draw_line(Vector2(xx, 24.0 - 70.0 * u), Vector2(xx, 14.0 - 70.0 * u), K(s, 0.8 * sin(u * PI)), 2.0)

## Chấn Địa: vết nứt đất toả ra, trụ đá trồi lên.
static func _crack(s, t: float, lowq: bool) -> void:
	var g := minf(1.0, t * 3.0)
	glow(s, Vector2(0, -4), 30.0, 0.4 * (1.0 - t))
	var n := 5 if lowq else 8
	for k in range(n):
		var side := 1.0 if k % 2 == 0 else -1.0
		var L := (60.0 + 90.0 * rf(s, 0.0, 1.0)) * g
		var pts := PackedVector2Array([Vector2.ZERO])
		var cur := Vector2.ZERO
		var segs := 6
		var yy := rf(s, -6.0, 8.0)
		for i in range(segs):
			cur += Vector2(side * L / float(segs), rf(s, -6.0, 6.0) * 0.4 + yy * 0.05)
			pts.append(cur)
		s.draw_polyline(pts, K(s, 0.55 * (1.0 - t * 0.5)), 7.0)
		s.draw_polyline(pts, A(s, 0.95), 3.0)
		# trụ đá trồi dọc vết nứt
		var u := clampf((t - 0.1 - 0.05 * float(k % 4)) / 0.4, 0.0, 1.0)
		if u > 0.0:
			var px: float = pts[3].x
			var ph := (30.0 + 20.0 * float(k % 3)) * sm(u) * (1.0 - 0.4 * clampf((t - 0.7) / 0.3, 0.0, 1.0))
			s.draw_colored_polygon(PackedVector2Array([Vector2(px - 7, 2), Vector2(px - 3, -ph), Vector2(px + 5, -ph * 0.7), Vector2(px + 8, 2)]), A(s, 0.8))
			s.draw_line(Vector2(px - 3, -ph), Vector2(px + 5, -ph * 0.7), K(s, 0.95), 2.0)
	for k in range(5 if lowq else 9):
		var u2 := fposmod(t * 1.1 + float(k) * 0.13, 1.0)
		var x2 := -50.0 + 12.0 * float(k)
		s.draw_circle(Vector2(x2, -u2 * 38.0), 3.0 + 3.0 * u2, A(s, 0.35 * (1.0 - u2)))

## Khiên Xoáy: cơn lốc khiên xoắn ốc.
static func _shieldvortex(s, t: float, lowq: bool) -> void:
	var f := sm(t * 3.0)
	glow(s, Vector2(0, -2), 48.0 * f, 0.2)
	var n := 6 if lowq else 10
	for k in range(n):
		var u := float(k) / float(n - 1)
		var a := t * 14.0 + u * 7.0
		var r := (16.0 + 52.0 * u) * f
		var p := Vector2(cos(a) * r, sin(a) * r * 0.5 - 4.0 - 14.0 * u)
		var depth := sin(a) * 0.5 + 0.5
		shield(s, p, 7.0 + 6.0 * u, 0.45 + 0.55 * depth, a * 0.3)
	for j in range(2):
		var pts := PackedVector2Array()
		for i in range(18):
			var u2 := float(i) / 17.0
			var a2 := t * 14.0 + u2 * 7.0 + j * 0.6 - 0.5
			pts.append(Vector2(cos(a2) * (16.0 + 52.0 * u2) * f, sin(a2) * (16.0 + 52.0 * u2) * f * 0.5 - 4.0 - 14.0 * u2))
		s.draw_polyline(pts, A(s, 0.5), 3.0)

## Thành Lũy Bất Diệt: bức tường thành có lỗ châu mai trồi lên.
static func _bastion(s, t: float, lowq: bool) -> void:
	var q := sm(t * 2.2)
	var H := 58.0 * q
	var hw := 52.0
	glow(s, Vector2(0, -H * 0.5), 70.0, 0.18 * q)
	s.draw_rect(Rect2(-hw, -H, hw * 2.0, H), A(s, 0.5))
	var rows := int(H / 12.0)
	for r in range(rows):
		var yy := -H + 12.0 * float(r)
		s.draw_line(Vector2(-hw, yy), Vector2(hw, yy), A(s, 0.7), 1.4)
		var off := 0.0 if r % 2 == 0 else 8.0
		var xx := -hw + off
		while xx < hw:
			s.draw_line(Vector2(xx, yy), Vector2(xx, yy + 12.0), A(s, 0.4), 1.2)
			xx += 16.0
	for k in range(5):
		var mx := -hw + 4.0 + float(k) * 25.0
		s.draw_rect(Rect2(mx, -H - 9.0 * q, 14.0, 9.0 * q), A(s, 0.8))
	s.draw_rect(Rect2(-hw, -H, hw * 2.0, H), K(s, 0.9), false, 2.0)
	for sd in [-1.0, 1.0]:
		var tx: float = sd * hw
		s.draw_rect(Rect2(tx - 9.0, -H - 22.0 * q, 18.0, H + 22.0 * q), A(s, 0.7))
		s.draw_rect(Rect2(tx - 9.0, -H - 22.0 * q, 18.0, H + 22.0 * q), K(s, 0.9), false, 2.0)
		s.draw_colored_polygon(PackedVector2Array([Vector2(tx - 12, -H - 22.0 * q), Vector2(tx, -H - 38.0 * q), Vector2(tx + 12, -H - 22.0 * q)]), K(s, 0.85 * q))
	if t > 0.4:
		var sh := clampf((t - 0.4) / 0.4, 0.0, 1.0)
		ering(s, Vector2(0, 0), 20.0 + 100.0 * sh, 6.0 + 28.0 * sh, K(s, 0.8 * (1.0 - sh)), 3.0)

## Pháo Đài Tiến Quân: pháo đài di động có lỗ châu mai đẩy lên phía trước.
static func _march(s, t: float, lowq: bool) -> void:
	var x := lerpf(-50.0, 96.0, t)
	for k in range(6):
		var yy := -26.0 + 11.0 * float(k)
		s.draw_line(Vector2(x - 20.0 - float(k % 3) * 14.0, yy), Vector2(x - 74.0 - float(k % 2) * 20.0, yy), A(s, 0.5), 2.5)
	for k in range(3 if lowq else 5):
		var u := float(k) / 4.0
		s.draw_circle(Vector2(x - 24.0 - 26.0 * u, 28.0 - 8.0 * u), 8.0 + 10.0 * u, A(s, 0.28 * (1.0 - u)))
	glow(s, Vector2(x, -4.0), 52.0, 0.2)
	# thân pháo đài
	s.draw_colored_polygon(PackedVector2Array([Vector2(x - 36, -34), Vector2(x + 10, -38), Vector2(x + 16, 30), Vector2(x - 36, 30)]), A(s, 0.5))
	s.draw_rect(Rect2(x - 36, -34, 52, 64), K(s, 0.85), false, 2.5)
	for k in range(4):
		s.draw_rect(Rect2(x - 36.0 + 14.0 * float(k), -44.0, 9.0, 10.0), A(s, 0.85))
	s.draw_line(Vector2(x - 36, -8), Vector2(x + 16, -8), A(s, 0.8), 2.0)
	s.draw_line(Vector2(x - 10, -34), Vector2(x - 10, 30), A(s, 0.8), 2.0)
	s.draw_circle(Vector2(x - 10, -8), 7.0, K(s, 0.95))
	s.draw_arc(Vector2(x + 16, -4), 18.0 + 4.0 * sin(t * 30.0), -0.9, 0.9, 12, K(s, 0.85), 3.0)
	s.draw_arc(Vector2(x + 16, -4), 32.0, -0.8, 0.8, 12, A(s, 0.5), 5.0)

## Phản Chấn Địa Long: địa long trồi lên khỏi mặt đất, gầm về trước.
static func _earthdragon(s, t: float, lowq: bool) -> void:
	var rev := sm(t * 1.7)
	ering(s, Vector2(-30, 0), 26.0 + 90.0 * t, 6.0 + 24.0 * t, K(s, 0.8 * (1.0 - t)), 3.0)
	var n := 12 if lowq else 18
	var prev := Vector2(-30.0, 2.0)
	var head := prev
	for i in range(n):
		var u := float(i) / float(n - 1) * rev
		var p := Vector2(-30.0 + 140.0 * u, -sin(u * PI * 0.95) * 66.0 + sin(u * 10.0 - t * 12.0) * 5.0)
		if i > 0:
			var w := lerpf(11.0, 5.0, float(i) / float(n))
			s.draw_line(prev, p, A(s, 0.55), w * 2.0)
			s.draw_line(prev, p, K(s, 0.6), w * 0.8)
			if i % 3 == 0:
				s.draw_line(p + Vector2(0, -w), p + Vector2(3, -w - 8.0), A(s, 0.9), 2.5)
		prev = p
		head = p
	# đầu rồng
	var hp := head
	s.draw_colored_polygon(PackedVector2Array([hp + Vector2(-8, -12), hp + Vector2(22, -4), hp + Vector2(26, 4), hp + Vector2(-8, 10)]), A(s, 0.85))
	s.draw_line(hp + Vector2(-4, -10), hp + Vector2(-20, -26), K(s, 0.95), 3.0)
	s.draw_line(hp + Vector2(2, -12), hp + Vector2(-10, -30), K(s, 0.95), 3.0)
	s.draw_circle(hp + Vector2(6, -4), 3.0, K(s, 1.0))
	if rev > 0.9:
		var r := clampf((t - 0.55) / 0.45, 0.0, 1.0)
		s.draw_arc(hp + Vector2(26, 0), 12.0 + 60.0 * r, -0.6, 0.6, 14, K(s, 0.85 * (1.0 - r)), 3.0)

## Tuyên Chiến: cắm chiến kỳ, sóng hô xung trận lan ra.
static func _banner(s, t: float, lowq: bool) -> void:
	var q := clampf(t * 3.4, 0.0, 1.0)
	var oy := -(1.0 - q * q) * 90.0
	var bx := 14.0
	glow(s, Vector2(bx, -20), 46.0, 0.2 * q)
	s.draw_line(Vector2(bx, 34.0 + oy), Vector2(bx, -62.0 + oy), K(s, 0.95), 3.5)
	s.draw_circle(Vector2(bx, -64.0 + oy), 4.0, K(s, 1.0))
	var top := PackedVector2Array()
	var bot := PackedVector2Array()
	for i in range(9):
		var u := float(i) / 8.0
		var wv := sin(u * 6.0 - t * 16.0) * 5.0 * u
		top.append(Vector2(bx + 4.0 + 46.0 * u, -58.0 + oy + wv))
		bot.append(Vector2(bx + 4.0 + 46.0 * u, -24.0 + oy + wv - 8.0 * u))
	bot.reverse()
	top.append_array(bot)
	s.draw_colored_polygon(top, A(s, 0.72))
	s.draw_polyline(top, K(s, 0.9), 1.6)
	var ec := Vector2(bx + 22.0, -40.0 + oy)
	s.draw_line(ec + Vector2(-8, 8), ec + Vector2(8, -8), K(s, 0.95), 3.0)
	s.draw_line(ec + Vector2(-8, -8), ec + Vector2(8, 8), K(s, 0.95), 3.0)
	if q >= 1.0:
		var h := clampf((t - 0.3) / 0.7, 0.0, 1.0)
		ering(s, Vector2(bx, 32), 14.0 + 90.0 * h, 4.0 + 22.0 * h, K(s, 0.85 * (1.0 - h)), 3.0)
		var nw := 2 if lowq else 3
		for i in range(nw):
			var r := clampf(t * 1.5 - 0.2 - 0.15 * float(i), 0.0, 1.0)
			s.draw_arc(Vector2(bx, -40), 20.0 + 110.0 * r, -0.7, 0.7, 14, A(s, 0.7 * (1.0 - r)), 4.0)

## Khiên Phá: khiên rạn nứt rồi vỡ tan thành mảnh.
static func _shieldbreak(s, t: float, lowq: bool) -> void:
	var c := Vector2(36.0, -6.0)
	if t < 0.45:
		var q := t / 0.45
		shield(s, c + Vector2(sin(t * 90.0) * 1.5 * q, 0), 34.0, 1.0)
		for k in range(5):
			var a := TAU * float(k) / 5.0 + 0.4
			var e := c + Vector2(cos(a), sin(a)) * 36.0 * q
			zig(s, c, e, 5.0, 4, 1.0, 2.0)
		glow(s, c, 30.0 + 20.0 * q, 0.3 * q)
	else:
		var h := (t - 0.45) / 0.55
		var n := 7 if lowq else 12
		for k in range(n):
			var a := TAU * float(k) / float(n) + float(k % 3) * 0.2
			var d := 8.0 + 84.0 * h
			var p := c + Vector2(cos(a), sin(a)) * d + Vector2(0, 40.0 * h * h)
			s.draw_set_transform(p, h * 8.0 + float(k), Vector2.ONE)
			var sz := 6.0 + 3.0 * float(k % 3)
			s.draw_colored_polygon(PackedVector2Array([Vector2(-sz, -sz * 0.5), Vector2(sz, -sz * 0.2), Vector2(sz * 0.2, sz)]), A(s, 0.9 * (1.0 - h)))
			rst(s)
		s.draw_arc(c, 14.0 + 70.0 * h, 0.0, TAU, 28, K(s, 0.9 * (1.0 - h)), 4.0)
		s.draw_set_transform(c, 0.0, Vector2.ONE)
		s._starpoly(8, 12.0 + 44.0 * h, 4.0, K(s, 0.8 * (1.0 - h)))
		rst(s)

## Vòng Thép: ba vòng thép nghiêng xoay quanh người, nở rồi siết.
static func _steelring(s, t: float, lowq: bool) -> void:
	var ex := 1.0 + 0.35 * sin(minf(1.0, t * 1.3) * PI)
	glow(s, Vector2(0, -4), 36.0, 0.18)
	for i in range(3):
		var dir := 1.0 if i % 2 == 0 else -1.0
		var rot := t * (4.0 + 2.0 * float(i)) * dir + float(i)
		var rx := (32.0 + 14.0 * float(i)) * ex
		var ry := rx * (0.3 + 0.15 * float(i))
		var c := Vector2(0, -4)
		ering(s, c, rx, ry, A(s, 0.3), 9.0, rot)
		ering(s, c, rx, ry, A(s, 0.95), 4.0, rot)
		ering(s, c, rx, ry, K(s, 0.8), 1.5, rot)
		var nb := 5 if lowq else 8
		for k in range(nb):
			var a := TAU * float(k) / float(nb) + t * 3.0
			var p := Vector2(cos(a) * rx, sin(a) * ry).rotated(rot) + c
			s.draw_circle(p, 2.6, K(s, 0.95))

## Thịnh Nộ: lửa giận bốc quanh người + ký hiệu nổi gân.
static func _fury(s, t: float, lowq: bool) -> void:
	var f := minf(1.0, t * 3.0)
	glow(s, Vector2(0, -2), 62.0, 0.32 * f)
	var n := 5 if lowq else 9
	for k in range(n):
		var xx := -44.0 + 11.0 * float(k)
		var h := (34.0 + 22.0 * (0.5 + 0.5 * sin(t * 16.0 + float(k) * 1.7)) + 14.0 * float(k % 3)) * f
		s._flame(Vector2(xx, 26.0), h, 8.0)
	var ac := Vector2(30.0, -54.0)
	var pu := 1.0 + 0.25 * sin(t * 26.0)
	for k in range(4):
		var a := PI * 0.25 + PI * 0.5 * float(k)
		var cc := ac + Vector2(cos(a), sin(a)) * 10.0 * pu
		s.draw_arc(cc, 7.0 * pu, a + PI - 1.1, a + PI + 1.1, 8, A(s, 0.95), 4.0)
		s.draw_arc(cc, 7.0 * pu, a + PI - 1.1, a + PI + 1.1, 8, K(s, 0.95), 1.6)
	ering(s, Vector2(0, 26), 30.0 + 60.0 * fposmod(t * 2.0, 1.0), 8.0 + 16.0 * fposmod(t * 2.0, 1.0), K(s, 0.7 * (1.0 - fposmod(t * 2.0, 1.0))), 3.0)

## Giáp Sắt: các mảnh giáp lục giác bay vào lắp thành bộ giáp, ánh thép quét qua.
static func _ironarmor(s, t: float, lowq: bool) -> void:
	var tg := [Vector2(-20, -24), Vector2(20, -24), Vector2(-22, -2), Vector2(22, -2), Vector2(-12, 16), Vector2(12, 16), Vector2(0, -38), Vector2(0, -8)]
	for k in range(tg.size()):
		var q := clampf((t - 0.05 * float(k)) / 0.4, 0.0, 1.0)
		var e := q * q * (3.0 - 2.0 * q)
		var target: Vector2 = tg[k]
		var p := (target * 3.8).lerp(target, e)
		var al := 0.4 + 0.6 * q
		hexpoly(s, p, 9.0, float(k) * 0.3 + (1.0 - q) * 5.0, A(s, al * 0.55), K(s, al))
		if q >= 1.0 and q < 1.0 + 0.001 and t < 0.75:
			s.draw_circle(p, 3.0, K(s, 0.9))
	if t > 0.45:
		var f := clampf((t - 0.45) / 0.3, 0.0, 1.0)
		s.draw_colored_polygon(PackedVector2Array([Vector2(-18, -24), Vector2(18, -24), Vector2(14, 8), Vector2(0, 16), Vector2(-14, 8)]), A(s, 0.35 * f))
		s.draw_arc(Vector2(0, -26), 11.0, PI, TAU, 12, K(s, 0.9 * f), 3.0)
		for sd in [-1.0, 1.0]:
			s.draw_arc(Vector2(sd * 24.0, -22), 10.0, 0.0, TAU, 14, A(s, 0.9 * f), 3.0)
		var g := clampf((t - 0.6) / 0.4, 0.0, 1.0)
		s.draw_line(Vector2(-34.0 + 68.0 * g, -40), Vector2(-14.0 + 68.0 * g, 24), K(s, 0.9 * (1.0 - g)), 5.0)

## Sóng Thép: bức sóng thép đầy mũi nhọn ập về trước.
static func _steelwave(s, t: float, lowq: bool) -> void:
	var fx := lerpf(-50.0, 180.0, sm(t * 1.1))
	for j in range(3):
		var x := fx - 38.0 * float(j)
		var al := 1.0 - 0.28 * float(j)
		var hh := 74.0 - 14.0 * float(j)
		var crest := PackedVector2Array()
		for i in range(9):
			var u := float(i) / 8.0
			crest.append(Vector2(x + 26.0 * sin(u * PI), -hh + (hh + 34.0) * u))
		var poly := PackedVector2Array(crest)
		poly.append(Vector2(x - 50, 34))
		poly.append(Vector2(x - 50, -hh))
		s.draw_colored_polygon(poly, A(s, 0.22 * al))
		s.draw_polyline(crest, K(s, 0.9 * al), 3.0)
		var ns := 6 if lowq else 9
		for k in range(ns):
			var u2 := float(k) / float(ns - 1)
			var p := Vector2(x + 26.0 * sin(u2 * PI), -hh + (hh + 34.0) * u2)
			spike(s, p, -0.25 + 0.5 * u2 * 0.0 - 0.15, 18.0 + 10.0 * float(k % 2), 4.0, al)
	for k in range(5):
		var yy := -50.0 + 20.0 * float(k)
		s.draw_line(Vector2(fx - 130.0, yy), Vector2(fx - 50.0 - float(k % 2) * 30.0, yy), A(s, 0.4), 2.0)

## Địa Chấn: sàn đá nảy tung từng tảng, bụi mù, vòng chấn động.
static func _tremor(s, t: float, lowq: bool) -> void:
	var n := 7 if lowq else 11
	for k in range(n):
		var xx := -100.0 + 200.0 * float(k) / float(n - 1)
		var delay := absf(xx) / 260.0
		var q := clampf((t - delay * 0.6) / 0.5, 0.0, 1.0)
		var hop := sin(q * PI) * (16.0 + 18.0 * float((k * 7) % 3))
		var tilt := sin(q * PI * 2.0) * 0.4 * (1.0 if k % 2 == 0 else -1.0)
		s.draw_set_transform(Vector2(xx, -hop), tilt, Vector2.ONE)
		s.draw_rect(Rect2(-9, -6, 18, 12), A(s, 0.7))
		s.draw_rect(Rect2(-9, -6, 18, 3), K(s, 0.9))
		rst(s)
		if q > 0.0 and q < 1.0:
			s.draw_circle(Vector2(xx, -2.0 - hop * 0.2), 6.0 + 10.0 * q, A(s, 0.25 * (1.0 - q)))
	for i in range(2):
		var r := clampf(t * 1.3 - 0.2 * float(i), 0.0, 1.0)
		ering(s, Vector2.ZERO, 14.0 + 140.0 * r, 5.0 + 40.0 * r, K(s, 0.75 * (1.0 - r)), 3.0)

## Pháo Đài Bất Khuất: tháp canh sừng sững có cờ, cổng, vòng rune.
static func _keep(s, t: float, lowq: bool) -> void:
	var q := sm(t * 2.0)
	var H := 104.0 * q
	var hw := 22.0
	var rot := t * 3.0
	for k in range(8):
		var a := rot + TAU * float(k) / 8.0
		var p := Vector2(cos(a) * 44.0, sin(a) * 12.0)
		s.draw_circle(p, 2.5, K(s, 0.9))
	ering(s, Vector2.ZERO, 44.0, 12.0, A(s, 0.8), 2.5)
	glow(s, Vector2(0, -H * 0.5), 62.0, 0.2 * q)
	s.draw_rect(Rect2(-hw, -H, hw * 2.0, H), A(s, 0.55))
	for r in range(int(H / 14.0)):
		s.draw_line(Vector2(-hw, -H + 14.0 * float(r)), Vector2(hw, -H + 14.0 * float(r)), A(s, 0.55), 1.2)
	s.draw_rect(Rect2(-hw - 5.0, -H - 4.0, hw * 2.0 + 10.0, 6.0), A(s, 0.9))
	for k in range(4):
		s.draw_rect(Rect2(-hw - 5.0 + 13.0 * float(k) + 1.0, -H - 14.0, 8.0, 10.0), A(s, 0.9))
	s.draw_rect(Rect2(-hw, -H, hw * 2.0, H), K(s, 0.9), false, 2.5)
	s.draw_rect(Rect2(-3.0, -H * 0.62, 6.0, 18.0), K(s, 0.95))
	s.draw_arc(Vector2(0, 0), 10.0, PI, TAU, 12, K(s, 0.95), 3.0)
	s.draw_line(Vector2(0, -H - 14.0), Vector2(0, -H - 44.0), K(s, 0.95), 2.5)
	var fp := PackedVector2Array()
	for i in range(6):
		var u := float(i) / 5.0
		fp.append(Vector2(2.0 + 24.0 * u, -H - 44.0 + sin(u * 5.0 - t * 14.0) * 3.0))
	for i in range(5, -1, -1):
		var u2 := float(i) / 5.0
		fp.append(Vector2(2.0 + 24.0 * u2, -H - 30.0 + sin(u2 * 5.0 - t * 14.0) * 3.0 - 4.0 * u2))
	s.draw_colored_polygon(fp, A(s, 0.85 * q))

## Xung Phong: đầu trâu có sừng húc thẳng, bụi mù phía sau.
static func _charge(s, t: float, lowq: bool) -> void:
	var x := lerpf(-60.0, 110.0, t)
	for k in range(3 if lowq else 6):
		s.draw_line(Vector2(x - 30.0, -26.0 + 11.0 * float(k)), Vector2(x - 90.0 - float(k % 3) * 18.0, -26.0 + 11.0 * float(k)), A(s, 0.55), 3.0)
	for i in range(1, 3):
		_bullhead(s, Vector2(x - 28.0 * float(i), -6.0), 0.3 / float(i))
	_bullhead(s, Vector2(x, -6.0), 1.0)
	for k in range(4 if lowq else 7):
		var u := float(k) / 6.0
		s.draw_circle(Vector2(x - 20.0 - 70.0 * u, 28.0 - 6.0 * u), 6.0 + 12.0 * u, A(s, 0.3 * (1.0 - u)))

static func _bullhead(s, c: Vector2, al: float) -> void:
	s.draw_colored_polygon(PackedVector2Array([c + Vector2(-16, -16), c + Vector2(20, -5), c + Vector2(20, 5), c + Vector2(-16, 16)]), A(s, al * 0.65))
	s.draw_colored_polygon(PackedVector2Array([c + Vector2(20, -5), c + Vector2(26, 0), c + Vector2(20, 5)]), K(s, al))
	for sd in [-1.0, 1.0]:
		var hp := PackedVector2Array([c + Vector2(-10, sd * 14.0), c + Vector2(-2, sd * 28.0), c + Vector2(12, sd * 34.0), c + Vector2(24, sd * 28.0)])
		s.draw_polyline(hp, A(s, al * 0.5), 9.0)
		s.draw_polyline(hp, K(s, al), 3.5)
	s.draw_circle(c + Vector2(8, -6), 2.4, K(s, al))
	s.draw_circle(c + Vector2(8, 6), 2.4, K(s, al))

## Tiếng Gầm Uy Hiếp: sóng âm răng cưa lan từ miệng, bụi đá bị thổi bay.
static func _roar(s, t: float, lowq: bool) -> void:
	var m := Vector2(-30.0, -14.0)
	var open := sin(minf(1.0, t * 3.0) * PI * 0.5) * 12.0
	s.draw_colored_polygon(PackedVector2Array([m, m + Vector2(14, -open - 2), m + Vector2(16, -open * 0.3)]), A(s, 0.9))
	s.draw_colored_polygon(PackedVector2Array([m, m + Vector2(14, open + 2), m + Vector2(16, open * 0.3)]), A(s, 0.9))
	glow(s, m + Vector2(10, 0), 22.0, 0.5 * (1.0 - t))
	var nw := 3 if lowq else 5
	for i in range(nw):
		var r := clampf(t * 1.45 - 0.16 * float(i), 0.0, 1.0)
		if r <= 0.0: continue
		var rad := 24.0 + 160.0 * r
		var pts := PackedVector2Array()
		for j in range(15):
			var a := -0.55 + 1.1 * float(j) / 14.0
			var rr := rad + (5.0 if j % 2 == 0 else -5.0)
			pts.append(m + Vector2(cos(a) * rr, sin(a) * rr))
		s.draw_polyline(pts, A(s, 0.35 * (1.0 - r)), 9.0)
		s.draw_polyline(pts, K(s, 0.9 * (1.0 - r)), 2.5)
	for k in range(5 if lowq else 9):
		var u := fposmod(t * 1.4 + float(k) * 0.11, 1.0)
		var yy := 28.0 - 8.0 * float(k % 3)
		s.draw_line(Vector2(10.0 + 150.0 * u, yy - 24.0 * u), Vector2(22.0 + 150.0 * u, yy - 24.0 * u - 2.0), A(s, 0.6 * (1.0 - u)), 2.5)

## Phản Giáp: giáp gai nhọn bung ra, tia phản đòn bật ngược.
static func _thorns(s, t: float, lowq: bool) -> void:
	var ext := sm(t * 3.0) * (1.0 - 0.3 * clampf((t - 0.8) / 0.2, 0.0, 1.0))
	var c := Vector2(0, -4)
	glow(s, c, 40.0, 0.28)
	s.draw_arc(c, 24.0, 0.0, TAU, 28, K(s, 0.9), 3.0)
	s.draw_arc(c, 19.0, 0.0, TAU, 24, A(s, 0.7), 5.0)
	var n := 8 if lowq else 12
	for k in range(n):
		var a := TAU * float(k) / float(n) + t * 0.8
		var dir := Vector2(cos(a), sin(a))
		spike(s, c + dir * 22.0, a, (22.0 + 18.0 * float(k % 2)) * ext, 5.0, 1.0)
	if t > 0.45:
		var r := clampf((t - 0.45) / 0.55, 0.0, 1.0)
		for k in range(4):
			var a2 := TAU * float(k) / 4.0 + 0.7
			var d := Vector2(cos(a2), sin(a2))
			s.draw_line(c + d * (56.0 + 40.0 * r), c + d * (44.0 + 40.0 * r), K(s, 0.9 * (1.0 - r)), 3.0)
			s.draw_line(c + d * (44.0 + 40.0 * r), c + d * (50.0 + 40.0 * r) + d.orthogonal() * 6.0, A(s, 0.8 * (1.0 - r)), 2.0)

## Búa Thiên Lôi: búa khổng lồ giáng xuống kèm sét.
static func _hammer(s, t: float, lowq: bool) -> void:
	var q := clampf(t / 0.4, 0.0, 1.0)
	var hy := lerpf(-250.0, -20.0, q * q)
	if q < 1.0:
		s.draw_line(Vector2(0, hy - 80.0), Vector2(0, hy - 220.0), A(s, 0.35), 14.0)
	glow(s, Vector2(0, hy), 44.0, 0.45)
	s.draw_line(Vector2(0, hy), Vector2(0, hy - 88.0), A(s, 0.9), 6.0)
	s.draw_line(Vector2(0, hy), Vector2(0, hy - 88.0), K(s, 0.6), 2.0)
	s.draw_rect(Rect2(-32, hy - 18, 64, 36), A(s, 0.75))
	s.draw_rect(Rect2(-32, hy - 18, 64, 36), K(s, 0.95), false, 3.0)
	s.draw_line(Vector2(-24, hy - 6), Vector2(24, hy - 6), K(s, 0.8), 2.0)
	for k in range(2 if lowq else 4):
		var a := TAU * float(k) / 4.0 + t * 30.0
		zig(s, Vector2(0, hy), Vector2(0, hy) + Vector2(cos(a), sin(a)) * 40.0, 6.0, 4, 0.9, 1.6)
	if t >= 0.4:
		var h := (t - 0.4) / 0.6
		for k in range(3 if lowq else 5):
			var tx := -60.0 + 30.0 * float(k) + rf(s, -8.0, 8.0)
			zig(s, Vector2(tx * 0.4, -250.0), Vector2(tx, 0.0), 14.0, 7, 1.0 - h, 2.5)
		ering(s, Vector2.ZERO, 16.0 + 130.0 * h, 5.0 + 38.0 * h, K(s, 0.9 * (1.0 - h)), 4.0)
		ering(s, Vector2.ZERO, 8.0 + 80.0 * h, 3.0 + 22.0 * h, A(s, 0.8 * (1.0 - h)), 3.0)
		glow(s, Vector2(0, -6), 50.0 * (1.0 - h * 0.5), 0.4 * (1.0 - h))

## Thành Đồng Bất Hoại: cổng thành đồng với hai tháp, hào quang tỏa sau lưng.
static func _bronzewall(s, t: float, lowq: bool) -> void:
	var q := sm(t * 1.8)
	var H := 76.0 * q
	var hw := 74.0
	for k in range(9):
		var a := -PI + PI * float(k) / 8.0
		s.draw_line(Vector2(0, -H * 0.5), Vector2(cos(a), sin(a)) * (90.0 + 30.0 * sin(t * 6.0 + k)) + Vector2(0, -H * 0.5), A(s, 0.3 * q), 5.0)
	glow(s, Vector2(0, -H * 0.5), 90.0, 0.2 * q)
	s.draw_rect(Rect2(-hw, -H, hw * 2.0, H), A(s, 0.55))
	for r in range(int(H / 11.0)):
		var yy := -H + 11.0 * float(r)
		s.draw_line(Vector2(-hw, yy), Vector2(hw, yy), A(s, 0.7), 1.3)
		var xx := -hw + (0.0 if r % 2 == 0 else 9.0)
		while xx < hw:
			s.draw_line(Vector2(xx, yy), Vector2(xx, yy + 11.0), A(s, 0.4), 1.1)
			xx += 18.0
	for k in range(7):
		s.draw_rect(Rect2(-hw + 6.0 + 22.0 * float(k), -H - 8.0 * q, 12.0, 8.0 * q), A(s, 0.85))
	s.draw_rect(Rect2(-hw, -H, hw * 2.0, H), K(s, 0.95), false, 3.0)
	for sd in [-1.0, 1.0]:
		var tx: float = sd * hw
		var th := H + 30.0 * q
		s.draw_rect(Rect2(tx - 14.0, -th, 28.0, th), A(s, 0.7))
		s.draw_rect(Rect2(tx - 14.0, -th, 28.0, th), K(s, 0.95), false, 3.0)
		s.draw_colored_polygon(PackedVector2Array([Vector2(tx - 18, -th), Vector2(tx, -th - 24.0 * q), Vector2(tx + 18, -th)]), K(s, 0.85 * q))
		s.draw_rect(Rect2(tx - 3.0, -th * 0.6, 6.0, 16.0), K(s, 0.9))
	# cổng vòm sáng
	var gw := 22.0
	s.draw_rect(Rect2(-gw, -H * 0.6, gw * 2.0, H * 0.6), K(s, 0.35 * q))
	s.draw_arc(Vector2(0, -H * 0.6), gw, PI, TAU, 16, K(s, 0.95), 3.0)
	s.draw_line(Vector2(0, -H * 0.6 - gw), Vector2(0, 0), K(s, 0.7), 2.0)
	if t > 0.5:
		var h := clampf((t - 0.5) / 0.5, 0.0, 1.0)
		ering(s, Vector2.ZERO, 30.0 + 110.0 * h, 8.0 + 30.0 * h, K(s, 0.8 * (1.0 - h)), 3.0)

## Địa Chấn Thiên Hạ: đất nứt toác khắp nơi, dung nham sáng, đá bay ngược lên trời.
static func _worldquake(s, t: float, lowq: bool) -> void:
	var g := minf(1.0, t * 2.4)
	for i in range(3):
		var r := clampf(t * 1.4 - 0.18 * float(i), 0.0, 1.0)
		ering(s, Vector2.ZERO, 20.0 + 190.0 * r, 6.0 + 54.0 * r, K(s, 0.8 * (1.0 - r)), 4.0)
	if t < 0.5:
		s.draw_colored_polygon(PackedVector2Array([Vector2(-22, 0), Vector2(-10, -170), Vector2(10, -170), Vector2(22, 0)]), K(s, 0.35 * (1.0 - t * 2.0)))
	var n := 8 if lowq else 14
	for k in range(n):
		var a := TAU * float(k) / float(n) + rf(s, -0.15, 0.15)
		var L := (110.0 + 90.0 * rf(s, 0.0, 1.0)) * g
		var pts := PackedVector2Array([Vector2.ZERO])
		var cur := Vector2.ZERO
		for i in range(6):
			var aa := a + rf(s, -0.35, 0.35)
			cur += Vector2(cos(aa) * 1.15, sin(aa) * 0.38) * L / 6.0
			pts.append(cur)
		s.draw_polyline(pts, K(s, 0.45), 9.0)
		s.draw_polyline(pts, A(s, 0.95), 3.5)
		s.draw_polyline(pts, K(s, 0.95), 1.2)
	for k in range(6 if lowq else 12):
		var ang := rf(s, -2.5, -0.65)
		var sp := rf(s, 90.0, 190.0)
		var life := clampf(t * 1.1 - 0.04 * float(k % 4), 0.0, 1.0)
		var px := cos(ang) * sp * life * (1.0 if k % 2 == 0 else -1.0)
		var py := sin(ang) * sp * life + 190.0 * life * life
		rock(s, Vector2(px, py), 4.0 + float(k % 4) * 2.0, life * 7.0 + float(k), 1.0 - life * 0.5)

## Thiết Bích Vĩnh Cửu: vòm cầu lục giác, sóng sáng chạy qua các ô.
static func _hexdome(s, t: float, lowq: bool) -> void:
	var R := 78.0 * sm(t * 2.5)
	var cc := Vector2(0, -4)
	if R < 4.0: return
	glow(s, cc, R * 1.05, 0.14)
	var sz := 15.0 if lowq else 11.0
	var w := sqrt(3.0) * sz
	for row in range(-8, 8):
		for col in range(-8, 8):
			var p := Vector2(float(col) * w + (w * 0.5 if (row & 1) != 0 else 0.0), float(row) * sz * 1.5)
			var d := p.length()
			if d > R - sz * 0.6 or p.y > 30.0: continue
			var wave := maxf(0.0, sin(d * 0.09 - t * 12.0))
			hexpoly(s, cc + p, sz * 0.92, PI / 6.0, A(s, 0.08 + 0.35 * wave), K(s, 0.3 + 0.6 * wave))
	s.draw_arc(cc, R, PI, TAU, 40, A(s, 0.35), 9.0)
	s.draw_arc(cc, R, PI, TAU, 40, K(s, 0.95), 3.0)
	s.draw_arc(cc, R, 0.0, PI, 40, A(s, 0.35), 3.0)
	ering(s, Vector2(0, 28), R, R * 0.2, K(s, 0.9), 3.0)
	for k in range(8):
		var a := t * 2.0 + TAU * float(k) / 8.0
		s.draw_circle(cc + Vector2(cos(a), sin(a)) * (R + 8.0), 3.0, K(s, 0.9))

# ============================================================ KIẾM SĨ
## Kiếm Khí Hoành Tảo: một nhát quét ngang rộng, lưỡi kiếm khí lưỡi liềm.
static func _sweep(s, t: float, lowq: bool) -> void:
	var p := sm(t * 1.6)
	var fd := fade(t, 0.65)
	var c := Vector2(-80.0, -6.0)
	var Rr := 50.0 + 140.0 * p
	var am := 0.55 + 0.35 * p
	var outer := PackedVector2Array()
	var inner := PackedVector2Array()
	for i in range(17):
		var u := float(i) / 16.0
		var a := -am + 2.0 * am * u
		outer.append(c + Vector2(cos(a), sin(a) * 0.55) * Rr)
		var thick := 26.0 * (1.0 - pow(2.0 * u - 1.0, 2.0))
		inner.append(c + Vector2(cos(a), sin(a) * 0.55) * (Rr - thick))
	inner.reverse()
	var poly := PackedVector2Array(outer)
	poly.append_array(inner)
	s.draw_colored_polygon(poly, A(s, 0.7 * fd))
	s.draw_polyline(outer, K(s, 0.95 * fd), 3.0)
	for k in range(3 if lowq else 5):
		var yy := -18.0 + 9.0 * float(k)
		var x1 := c.x + Rr * (0.2 + 0.1 * float(k % 3))
		s.draw_line(Vector2(x1 - 60.0, yy), Vector2(x1, yy), A(s, 0.5 * fd), 2.0)

## Nhất Kiếm Thiên Phong: một mũi kiếm xuyên thẳng, ngàn luồng gió xoáy quanh.
static func _windthrust(s, t: float, lowq: bool) -> void:
	var x := lerpf(-30.0, 160.0, sm(t * 1.7))
	var al := fade(t, 0.7)
	for j in range(3 if lowq else 6):
		var pts := PackedVector2Array()
		for i in range(14):
			var u := float(i) / 13.0
			var px := x - 130.0 * (1.0 - u)
			var env := sin(u * PI * 0.5)
			pts.append(Vector2(px, -6.0 + sin(u * 9.0 + float(j) * 1.1 - t * 18.0) * (10.0 + 5.0 * float(j % 3)) * env))
		s.draw_polyline(pts, A(s, 0.55 * al), 2.0)
	glow(s, Vector2(x, -6.0), 24.0, 0.4 * al)
	blade(s, Vector2(x - 110.0, -6.0), Vector2(x, -6.0), 5.0, al)
	s.draw_set_transform(Vector2(x, -6.0), 0.0, Vector2.ONE)
	s._starpoly(4, 16.0, 2.5, K(s, 0.9 * al))
	rst(s)

## Kiếm Ý Hộ Thân: các thanh kiếm lơ lửng xoay quanh người như lồng kiếm.
static func _swordintent(s, t: float, lowq: bool) -> void:
	var f := sm(t * 3.0)
	glow(s, Vector2(0, -4), 46.0 * f, 0.22)
	ering(s, Vector2(0, 26), 46.0 * f, 13.0 * f, A(s, 0.7), 2.5)
	ering(s, Vector2(0, -34), 40.0 * f, 11.0 * f, A(s, 0.5), 2.0)
	var n := 4 if lowq else 6
	for k in range(n):
		var a := t * 5.0 + TAU * float(k) / float(n)
		var depth := sin(a) * 0.5 + 0.5
		var p := Vector2(cos(a) * 42.0 * f, sin(a) * 12.0 - 4.0)
		blade(s, p + Vector2(0, 22.0), p + Vector2(0, -22.0), 3.5 + depth, (0.45 + 0.55 * depth) * f)
	for k in range(5):
		var u := fposmod(t * 0.8 + float(k) * 0.2, 1.0)
		s.draw_circle(Vector2(-26.0 + 13.0 * float(k), 20.0 - 60.0 * u), 2.0, K(s, 0.8 * sin(u * PI)))

## Long Ảnh Liên Trảm: bóng rồng uốn lượn lao tới, để lại những nhát chém chéo.
static func _dragonshadow(s, t: float, lowq: bool) -> void:
	var hx := lerpf(-40.0, 150.0, sm(t * 1.4))
	var n := 12 if lowq else 18
	var prev := Vector2(hx, -6.0)
	var al := fade(t, 0.75)
	for i in range(n):
		var p := Vector2(hx - float(i) * 9.0, -6.0 + sin(t * 9.0 - float(i) * 0.5) * (8.0 + float(i) * 0.6))
		if i > 0:
			var w := lerpf(9.0, 2.0, float(i) / float(n))
			s.draw_line(prev, p, A(s, 0.5 * al), w * 2.2)
			s.draw_line(prev, p, K(s, 0.8 * al), w * 0.7)
		prev = p
	var hp := Vector2(hx, -6.0 + sin(t * 9.0) * 8.0)
	s.draw_colored_polygon(PackedVector2Array([hp + Vector2(-8, -9), hp + Vector2(22, -2), hp + Vector2(22, 4), hp + Vector2(-8, 9)]), A(s, 0.9 * al))
	s.draw_line(hp + Vector2(-4, -8), hp + Vector2(-20, -22), K(s, al), 3.0)
	s.draw_line(hp + Vector2(0, 8), hp + Vector2(-16, 20), K(s, al), 3.0)
	s.draw_circle(hp + Vector2(6, -3), 2.6, K(s, al))
	for k in range(3):
		var tk := 0.3 + 0.17 * float(k)
		if t < tk: continue
		var x0 := 20.0 + 42.0 * float(k)
		var f := clampf((t - tk) / 0.2, 0.0, 1.0)
		slash(s, Vector2(x0 - 16.0, -42.0), Vector2(x0 - 16.0 + 32.0 * f, -42.0 + 74.0 * f), 5.0, (1.0 - f * 0.6) * al)

## Tam Kiếm Hợp Nhất: ba thanh kiếm từ ba hướng quy về một, hợp thành nhát đâm lớn.
static func _trisword(s, t: float, lowq: bool) -> void:
	var F := Vector2(60.0, -6.0)
	if t < 0.55:
		var q := t / 0.55
		var d := 130.0 * (1.0 - q * q)
		for k in range(3):
			var a := -0.9 + 0.9 * float(k)
			var dir := Vector2(cos(a), sin(a))
			var tip := F - dir * d
			blade(s, tip - dir * 54.0, tip, 4.5, 0.4 + 0.6 * q)
		glow(s, F, 14.0 + 20.0 * q, 0.5 * q)
	else:
		var h := (t - 0.55) / 0.45
		glow(s, F, 40.0, 0.6 * (1.0 - h * 0.5))
		blade(s, F + Vector2(-70.0, 0), F + Vector2(30.0 + 90.0 * h, 0), 9.0, 1.0 - h * 0.4)
		s.draw_set_transform(F, 0.0, Vector2.ONE)
		s._starpoly(8, 18.0 + 44.0 * h, 5.0, K(s, 0.85 * (1.0 - h)))
		rst(s)
		ering(s, F + Vector2(40.0 * h, 0), 6.0 + 16.0 * h, 20.0 + 36.0 * h, K(s, 0.8 * (1.0 - h)), 3.0)

## Kiếm Khí Trường Hà: dòng sông kiếm khí uốn lượn tuôn về trước.
static func _riverqi(s, t: float, lowq: bool) -> void:
	var hx := lerpf(-30.0, 170.0, t)
	var al := fade(t, 0.8)
	var steps := 12 if lowq else 20
	for r in range(3):
		var off := (float(r) - 1.0) * 13.0
		var top := PackedVector2Array()
		var bot := PackedVector2Array()
		var mid := PackedVector2Array()
		for i in range(steps):
			var u := float(i) / float(steps - 1)
			var px := hx - 140.0 * (1.0 - u)
			var cy := off - 6.0 + sin(px * 0.07 - t * 16.0 + float(r) * 2.0) * 10.0
			var w := 1.0 + 7.0 * u
			top.append(Vector2(px, cy - w))
			bot.append(Vector2(px, cy + w))
			mid.append(Vector2(px, cy))
		bot.reverse()
		var poly := PackedVector2Array(top)
		poly.append_array(bot)
		s.draw_colored_polygon(poly, A(s, 0.55 * al))
		s.draw_polyline(mid, K(s, 0.9 * al), 1.6)
	for k in range(4 if lowq else 8):
		var u2 := fposmod(t * 1.5 + float(k) * 0.13, 1.0)
		s.draw_circle(Vector2(hx - 130.0 * u2, -6.0 + sin(float(k) * 2.3) * 24.0 - 14.0 * u2), 2.4, K(s, 0.8 * al))
	s.draw_set_transform(Vector2(hx + 6.0, -6.0), 0.0, Vector2.ONE)
	s._starpoly(4, 14.0, 3.0, K(s, 0.9 * al))
	rst(s)

## Phong Vân Kiếm Vũ: mây cuộn và kiếm múa trong gió.
static func _cloudsword(s, t: float, lowq: bool) -> void:
	var f := sm(t * 3.0)
	var nc := 4 if lowq else 6
	for k in range(nc):
		var a := t * 3.0 + TAU * float(k) / float(nc)
		var c := Vector2(cos(a) * 52.0 * f, sin(a) * 18.0 + 4.0)
		var depth := sin(a) * 0.5 + 0.5
		for j in range(3):
			var o := Vector2((float(j) - 1.0) * 10.0, -3.0 * absf(float(j) - 1.0))
			s.draw_circle(c + o, 11.0 - 2.0 * float(j % 2), A(s, 0.18 + 0.2 * depth))
		s.draw_circle(c + Vector2(0, -3), 6.0, K(s, 0.2 + 0.2 * depth))
	for k in range(3):
		var pts := PackedVector2Array()
		for i in range(14):
			var u := float(i) / 13.0
			var a2 := t * 7.0 + u * 2.2 + float(k) * 2.1
			pts.append(Vector2(cos(a2) * 40.0 * f, sin(a2) * 14.0 - 8.0 - 16.0 * float(k - 1)))
		s.draw_polyline(pts, K(s, 0.6), 2.0)
	var n := 3 if lowq else 4
	for k in range(n):
		var a3 := -t * 8.0 + TAU * float(k) / float(n)
		var p := Vector2(cos(a3) * 36.0 * f, sin(a3) * 16.0 - 6.0)
		var tg := Vector2(-sin(a3), cos(a3) * 0.45).normalized()
		blade(s, p - tg * 22.0, p + tg * 22.0, 4.0, 0.9)

## Trảm Kích Lướt: lướt nhanh để lại tàn ảnh, kết thúc bằng một nhát chém chéo.
static func _dashslash(s, t: float, lowq: bool) -> void:
	var p := minf(1.0, t * 1.5)
	for i in range(3 if lowq else 5):
		var px := lerpf(-70.0, 108.0, maxf(0.0, p - float(i) * 0.13))
		man(s, Vector2(px, 0.0), 0.0, 1.0, 0.32 * (1.0 - float(i) / 5.0))
	for k in range(4):
		var yy := -22.0 + 14.0 * float(k)
		s.draw_line(Vector2(lerpf(-70.0, 108.0, p) - 20.0, yy), Vector2(lerpf(-70.0, 108.0, p) - 80.0, yy), A(s, 0.5 * (1.0 - p * 0.5)), 2.5)
	if t > 0.5:
		var f := clampf((t - 0.5) / 0.5, 0.0, 1.0)
		var x0 := 112.0
		slash(s, Vector2(x0 - 30.0, -46.0), Vector2(x0 - 30.0 + 70.0 * minf(1.0, f * 2.5), -46.0 + 84.0 * minf(1.0, f * 2.5)), 8.0, 1.0 - f * 0.7)
		s.draw_set_transform(Vector2(x0 + 6.0, -4.0), 0.0, Vector2.ONE)
		s._starpoly(6, 10.0 + 28.0 * f, 3.0, K(s, 0.8 * (1.0 - f)))
		rst(s)

## Liên Trảm: chuỗi nhát chém nối tiếp theo nhiều góc.
static func _chain(s, t: float, lowq: bool) -> void:
	var c := Vector2(44.0, -8.0)
	var angs := [-0.75, 0.75, -0.2, 1.25, -1.2]
	var n := 4 if lowq else 5
	for k in range(n):
		var t0 := 0.14 * float(k)
		if t < t0: continue
		var f := clampf((t - t0) / 0.22, 0.0, 1.0)
		var life := clampf((t - t0 - 0.2) / 0.4, 0.0, 1.0)
		var dir := Vector2(cos(float(angs[k])), sin(float(angs[k])))
		var half := 62.0 - 6.0 * float(k)
		var a0 := c - dir * half
		var a1 := a0 + dir * half * 2.0 * f
		slash(s, a0, a1, 6.0 - 0.5 * float(k), 1.0 - life)
		s.draw_circle(a1, 4.0 * (1.0 - life), K(s, 0.95))
		if f >= 1.0:
			var r := clampf((t - t0 - 0.22) / 0.3, 0.0, 1.0)
			s.draw_arc(c, 8.0 + 22.0 * r, 0.0, TAU, 16, A(s, 0.5 * (1.0 - r)), 2.0)

## Cuồng Nộ: hỏa khí bùng cháy, mắt rực, vết chém điên cuồng.
static func _berserk(s, t: float, lowq: bool) -> void:
	var f := minf(1.0, t * 3.0)
	glow(s, Vector2(0, -4), 58.0 * (1.0 + 0.08 * sin(t * 30.0)), 0.3 * f)
	var n := 5 if lowq else 8
	for k in range(n):
		var xx := -34.0 + 68.0 * float(k) / float(n - 1)
		var h := (30.0 + 40.0 * (0.5 + 0.5 * sin(t * 18.0 + float(k) * 2.1))) * f
		s._flame(Vector2(xx, 28.0), h, 7.0)
	for k in range(3):
		var tk := 0.15 + 0.2 * float(k)
		if t < tk: continue
		var q := clampf((t - tk) / 0.15, 0.0, 1.0)
		var fd := 1.0 - clampf((t - tk - 0.15) / 0.4, 0.0, 1.0)
		var x0 := -20.0 + 20.0 * float(k)
		slash(s, Vector2(x0 - 24.0, -34.0 + 6.0 * float(k)), Vector2(x0 - 24.0 + 48.0 * q, -34.0 + 6.0 * float(k) + 62.0 * q), 4.5, fd)
	for sd in [-1.0, 1.0]:
		s.draw_line(Vector2(sd * 7.0, -25.0), Vector2(sd * 2.0, -22.0), K(s, 1.0), 3.0)
		s.draw_circle(Vector2(sd * 5.0, -23.5), 3.5, A(s, 0.6 * f))
	for k in range(4 if lowq else 8):
		var u := fposmod(t * 1.3 + float(k) * 0.125, 1.0)
		s.draw_circle(Vector2(-30.0 + 8.0 * float(k) + sin(t * 8.0 + k) * 6.0, 24.0 - 80.0 * u), 2.2, K(s, 0.9 * (1.0 - u)))

## Khiên Ý Chí: tấm khiên ánh sáng khắc kiếm, lan sóng ý chí.
static func _willshield(s, t: float, lowq: bool) -> void:
	var f := sm(t * 3.0)
	var pulse := 1.0 + 0.04 * sin(t * 24.0)
	var c := Vector2(24.0, -4.0)
	glow(s, c, 64.0 * f, 0.22)
	shield(s, c, 44.0 * f * pulse, f)
	blade(s, c + Vector2(0, 24.0 * f), c + Vector2(0, -34.0 * f), 4.0, 0.9 * f)
	for i in range(2 if lowq else 3):
		var r := fposmod(t * 1.1 + float(i) / 3.0, 1.0)
		s.draw_arc(c, 40.0 + 40.0 * r, -1.1, 1.1, 18, A(s, 0.6 * (1.0 - r)), 3.0)
	for k in range(6):
		var a := -t * 3.0 + TAU * float(k) / 6.0
		s.draw_circle(c + Vector2(cos(a) * 54.0, sin(a) * 40.0), 2.6, K(s, 0.9))

## Thiên Kiếm Giáng: thanh kiếm trời khổng lồ giáng xuống trong cột sáng.
static func _heavensword(s, t: float, lowq: bool) -> void:
	var q := clampf(t / 0.42, 0.0, 1.0)
	var y := lerpf(-330.0, 0.0, q * q)
	var al := fade(t, 0.8)
	if q < 1.0 or t < 0.7:
		s.draw_colored_polygon(PackedVector2Array([Vector2(-24, 0), Vector2(-14, -340), Vector2(14, -340), Vector2(24, 0)]), A(s, 0.22 * al))
	for k in range(5):
		var cx := -60.0 + 30.0 * float(k)
		s.draw_circle(Vector2(cx, -300.0 + 6.0 * float(k % 2)), 18.0, A(s, 0.22 * al))
	glow(s, Vector2(0, y - 100.0), 54.0, 0.4)
	s._sword_down(Vector2(0, y), 150.0, 0.0, 1.0)
	if q >= 1.0:
		var h := clampf((t - 0.42) / 0.58, 0.0, 1.0)
		ering(s, Vector2.ZERO, 20.0 + 140.0 * h, 6.0 + 40.0 * h, K(s, 0.9 * (1.0 - h)), 4.0)
		ering(s, Vector2.ZERO, 10.0 + 90.0 * h, 4.0 + 26.0 * h, A(s, 0.8 * (1.0 - h)), 3.0)
		var nr := 6 if lowq else 12
		for k in range(nr):
			var a := PI + PI * float(k) / float(nr - 1)
			spike(s, Vector2(cos(a) * 14.0, sin(a) * 6.0), a, 20.0 + 70.0 * h, 3.0, 1.0 - h)
		glow(s, Vector2(0, -8), 40.0, 0.5 * (1.0 - h))

## Kiếm Vũ Liên Hoàn: các vòng kiếm khí lồng nhau xoay nối đuôi nhau.
static func _swordloop(s, t: float, lowq: bool) -> void:
	var f := sm(t * 3.0)
	glow(s, Vector2(0, -4), 40.0, 0.18)
	for i in range(3):
		var dir := 1.0 if i % 2 == 0 else -1.0
		var rx := (28.0 + 15.0 * float(i)) * f
		var ry := rx * (0.45 + 0.1 * float(i))
		var base := t * (9.0 + 3.0 * float(i)) * dir
		var c := Vector2(0, -4)
		for j in range(2):
			var a0 := base + PI * float(j)
			var pts := PackedVector2Array()
			for k in range(10):
				var a := a0 + 1.5 * float(k) / 9.0 * dir
				pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
			s.draw_polyline(pts, A(s, 0.35), 8.0)
			s.draw_polyline(pts, A(s, 0.95), 4.0)
			s.draw_polyline(pts, K(s, 0.95), 1.5)
			s.draw_circle(pts[9], 3.0, K(s, 1.0))
		# mắt xích nối
		var al := base + PI * 0.5
		s.draw_arc(c + Vector2(cos(al) * rx, sin(al) * ry), 4.0, 0.0, TAU, 10, K(s, 0.8), 1.6)

## Phá Quân Trảm: nhát bổ chéo khổng lồ xé đôi trận địch, quân lính văng tứ tán.
static func _armybreak(s, t: float, lowq: bool) -> void:
	var q := clampf(t / 0.35, 0.0, 1.0)
	var fd := fade(t, 0.7)
	var a0 := Vector2(-26.0, -80.0)
	var b0 := Vector2(120.0, 40.0)
	slash(s, a0, a0.lerp(b0, q), 14.0, fd)
	var h := clampf((t - 0.3) / 0.7, 0.0, 1.0)
	if q >= 1.0:
		var pts := PackedVector2Array([Vector2(110.0, 34.0)])
		var cur := Vector2(110.0, 34.0)
		for i in range(6):
			cur += Vector2(14.0 * minf(1.0, h * 2.0), rf(s, -3.0, 3.0))
			pts.append(cur)
		s.draw_polyline(pts, K(s, 0.5 * fd), 8.0)
		s.draw_polyline(pts, A(s, 0.95 * fd), 3.0)
		glow(s, Vector2(110, 30), 26.0 * (1.0 - h * 0.5), 0.5 * (1.0 - h))
	var n := 3 if lowq else 4
	for k in range(n):
		var bx := 80.0 + 24.0 * float(k)
		var fl := sm(h * 1.4)
		var dirx := 1.0 if k % 2 == 0 else 0.6
		man(s, Vector2(bx + 50.0 * fl * dirx, 4.0 - 60.0 * sin(fl * PI) * (0.7 + 0.3 * float(k % 2))), fl * (3.0 + float(k)) * (1.0 if k % 2 == 0 else -1.0), 0.55, 0.85 * (1.0 - h * 0.6))

## Đâm Xuyên: mũi kiếm mảnh đâm xuyên, nón xung kích và vòng thủng.
static func _pierce(s, t: float, lowq: bool) -> void:
	var p := sm(t * 2.2)
	var x := lerpf(-40.0, 150.0, p)
	var al := fade(t, 0.75)
	blade(s, Vector2(x - 150.0, -6.0), Vector2(x, -6.0), 3.6, al)
	for sd in [-1.0, 1.0]:
		var a: float = PI + sd * 0.38
		s.draw_line(Vector2(x, -6.0), Vector2(x, -6.0) + Vector2(cos(a), sin(a)) * 64.0, A(s, 0.7 * al), 3.0)
		s.draw_line(Vector2(x, -6.0), Vector2(x, -6.0) + Vector2(cos(a), sin(a)) * 40.0, K(s, 0.9 * al), 1.5)
	glow(s, Vector2(x, -6.0), 16.0, 0.6 * al)
	var h := clampf((t - 0.35) / 0.65, 0.0, 1.0)
	var c := Vector2(150.0, -6.0)
	if t > 0.35:
		ering(s, c, 5.0 + 14.0 * h, 14.0 + 40.0 * h, K(s, 0.9 * (1.0 - h)), 3.5)
		ering(s, c, 3.0 + 8.0 * h, 8.0 + 22.0 * h, A(s, 0.9 * (1.0 - h)), 2.5)
		var nr := 6 if lowq else 10
		for k in range(nr):
			var a2 := TAU * float(k) / float(nr)
			spike(s, c + Vector2(cos(a2), sin(a2)) * 6.0, a2, 8.0 + 30.0 * h, 2.5, 1.0 - h)

## Cuồng Phong Trảm: lốc xoáy hình phễu cuốn theo nhát chém.
static func _cyclone(s, t: float, lowq: bool) -> void:
	var f := sm(t * 2.5)
	var L := 6 if lowq else 9
	for i in range(L):
		var u := float(i) / float(L - 1)
		var y := 28.0 - 92.0 * u * f
		var r := (10.0 + 46.0 * u) * f
		var a0 := t * 15.0 + float(i) * 0.9
		s.draw_set_transform(Vector2(0, y), 0.0, Vector2(1.0, 0.3))
		s.draw_arc(Vector2.ZERO, r, a0, a0 + 2.4, 14, A(s, 0.35 + 0.1 * u), 8.0)
		s.draw_arc(Vector2.ZERO, r, a0, a0 + 2.4, 14, K(s, 0.85), 2.2)
		s.draw_arc(Vector2.ZERO, r, a0 + PI, a0 + PI + 1.6, 12, A(s, 0.6), 3.0)
		rst(s)
	for k in range(3):
		var a := t * 10.0 + TAU * float(k) / 3.0
		var p := Vector2(cos(a) * 40.0 * f, sin(a) * 12.0 - 10.0 - 12.0 * float(k))
		var tg := Vector2(-sin(a), cos(a) * 0.3).normalized()
		slash(s, p - tg * 20.0, p + tg * 20.0, 4.0, 0.9)
	for k in range(4 if lowq else 8):
		var a2 := -t * 8.0 + TAU * float(k) / 8.0
		s.draw_circle(Vector2(cos(a2) * 56.0 * f, sin(a2) * 14.0 + 16.0 - 8.0 * float(k % 3)), 2.2, K(s, 0.8))

## Kiếm Khí Tung Hoành: kiếm khí đan chéo dọc ngang thành lưới.
static func _crossqi(s, t: float, lowq: bool) -> void:
	var n := 2 if lowq else 3
	for i in range(n):
		var q := clampf(t * 1.5 - float(i) * 0.25, 0.0, 1.0)
		if q <= 0.0: continue
		var c := Vector2(-10.0 + 150.0 * q, -6.0)
		var al := 1.0 - q * 0.6
		var arm := 38.0 + 8.0 * float(i)
		if i % 2 == 0:
			slash(s, c + Vector2(-arm, 0), c + Vector2(arm, 0), 5.0, al)
			slash(s, c + Vector2(0, -arm), c + Vector2(0, arm), 5.0, al)
		else:
			var d := Vector2(1, 1).normalized() * arm
			var e := Vector2(1, -1).normalized() * arm
			slash(s, c - d, c + d, 5.0, al)
			slash(s, c - e, c + e, 5.0, al)
		glow(s, c, 14.0, 0.5 * al)
		s.draw_line(c + Vector2(-80, 0), c + Vector2(-arm - 8.0, 0), A(s, 0.3 * al), 2.0)

## Kiếm Vũ Tuyệt Diệt: hoa kiếm nở rộ dưới trăng máu, bùng nổ cuối cùng.
static func _swordbloom(s, t: float, lowq: bool) -> void:
	var f := sm(t * 2.0)
	glow(s, Vector2(0, -6), 70.0 * f, 0.28)
	s.draw_circle(Vector2(0, -6), 40.0 * f, K(s, 0.18))
	s.draw_arc(Vector2(0, -6), 40.0 * f, 0.0, TAU, 36, K(s, 0.7), 2.0)
	var nl := 2 if lowq else 3
	for j in range(nl):
		var n := 8 if lowq else 12
		var spin := t * (2.5 + float(j)) * (1.0 if j % 2 == 0 else -1.0) + float(j) * 0.26
		for k in range(n):
			var a := spin + TAU * float(k) / float(n)
			var dir := Vector2(cos(a), sin(a))
			var r0 := 12.0 + 8.0 * float(j)
			var ex := f * (1.0 + 0.45 * sm((t - 0.65) / 0.35))
			var ln := (30.0 + 14.0 * float(j)) * ex
			blade(s, dir * (r0 * ex), dir * (r0 * ex + ln), 3.6, 0.75 + 0.25 * float(j % 2))
	if t > 0.65:
		var h := (t - 0.65) / 0.35
		ering(s, Vector2(0, -6), 20.0 + 120.0 * h, 20.0 + 120.0 * h, K(s, 0.9 * (1.0 - h)), 4.0)
		ering(s, Vector2(0, 26), 20.0 + 150.0 * h, 6.0 + 36.0 * h, A(s, 0.8 * (1.0 - h)), 3.0)

static func rf(s, a: float, b: float) -> float:
	return s._rng.randf_range(a, b)
