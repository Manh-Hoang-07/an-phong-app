extends RefCounted
## Hiệu ứng kỹ năng VẼ LẠI RIÊNG (nhóm e) — kiếm sĩ. Đăng ký ĐẦU TIÊN trong FxExt.ALL nên đè lên bản cũ ở FxExt_b.
## Quy ước: place "bodyf" = gốc toạ độ ở thân nhân vật, +x = hướng nhìn (node tự lật), y âm = lên, mặt đất y~+32.
## Mọi kích thước lấy theo tham số thật của kỹ năng (range/radius/distance) trong gamedata.json.
const AURA_IDS := ["ke_mindcounter", "ke_orbitswords", "ke_trueawaken", "ke_rage", "ke_willshield", "ke_parry", "au_buff", "au_guard", "au_shield"]
const IDS := {
	"ks25": "ke_sweep4", "ks27": "ke_windslash", "ks30": "ke_mindcounter", "ks32": "ke_orbitswords",
	"ks35": "ke_dragonslash", "ks37": "ke_triblade", "ks38": "ke_riverqi", "ks40": "ke_tenthousand",
	"ks42": "ke_cloudcyclone", "ks45": "ke_trueawaken",
	"pa1": "ke_dashcut", "pa2": "ke_chain4", "pa3": "ke_rage", "pa4": "ke_willshield", "pa5": "ke_heavensword",
	"pa6": "ke_bladewhirl", "pa7": "ke_armybreak", "pa8": "ke_lance", "pa9": "ke_parry", "pa10": "ke_cyclone",
	"pa11": "ke_crossqi", "ulKiem1": "ke_swordarray", "ulKiem2": "ke_swordlotus",
}
const CFG := {
	"pj_muzzle_bow": {"place": "bodyf", "dur": 0.4, "nopop": true, "nobig": true},
	"pj_muzzle": {"place": "bodyf", "dur": 0.3, "nopop": true, "nobig": true},
	"hit_slash": {"place": "body", "dur": 0.4, "nopop": true, "nobig": true},
	"hit_pierce": {"place": "body", "dur": 0.4, "nopop": true, "nobig": true},
	"hit_fire": {"place": "body", "dur": 0.4, "nopop": true, "nobig": true},
	"hit_ice": {"place": "body", "dur": 0.4, "nopop": true, "nobig": true},
	"hit_bolt": {"place": "body", "dur": 0.4, "nopop": true, "nobig": true},
	"hit_holy": {"place": "body", "dur": 0.4, "nopop": true, "nobig": true},
	"hit_dark": {"place": "body", "dur": 0.4, "nopop": true, "nobig": true},
	"hit_blood": {"place": "body", "dur": 0.4, "nopop": true, "nobig": true},
	"hit_soul": {"place": "body", "dur": 0.4, "nopop": true, "nobig": true},
	"hit_rock": {"place": "body", "dur": 0.4, "nopop": true, "nobig": true},
	"hit_water": {"place": "body", "dur": 0.4, "nopop": true, "nobig": true},
	"hit_arcane": {"place": "body", "dur": 0.4, "nopop": true, "nobig": true},
	"au_buff": {"place": "bodyf", "dur": 1.0, "nopop": true, "nobig": true},
	"au_guard": {"place": "bodyf", "dur": 1.0, "nopop": true, "nobig": true},
	"au_shield": {"place": "bodyf", "dur": 1.0, "nopop": true, "nobig": true},
	"ke_sweep4": {"place": "bodyf", "dur": 1.0, "nopop": true, "nobig": true},
	"ke_windslash": {"place": "bodyf", "dur": 0.8, "nopop": true, "nobig": true},
	"ke_mindcounter": {"place": "bodyf", "dur": 1.4, "nopop": true, "nobig": true},
	"ke_orbitswords": {"place": "bodyf", "dur": 1.4, "nopop": true, "nobig": true},
	"ke_dragonslash": {"place": "bodyf", "dur": 0.9, "nopop": true, "nobig": true},
	"ke_triblade": {"place": "bodyf", "dur": 0.9, "nopop": true, "nobig": true},
	"ke_riverqi": {"place": "bodyf", "dur": 1.0, "nopop": true, "nobig": true},
	"ke_tenthousand": {"place": "bodyf", "dur": 1.3, "nopop": true, "nobig": true, "rumble": 4.0},
	"ke_cloudcyclone": {"place": "bodyf", "dur": 1.2, "nopop": true, "nobig": true},
	"ke_trueawaken": {"place": "bodyf", "dur": 1.6, "nopop": true, "nobig": true},
	"ke_dashcut": {"place": "bodyf", "dur": 0.7, "nopop": true, "nobig": true},
	"ke_chain4": {"place": "bodyf", "dur": 0.9, "nopop": true, "nobig": true},
	"ke_rage": {"place": "bodyf", "dur": 1.4, "nopop": true, "nobig": true},
	"ke_willshield": {"place": "bodyf", "dur": 1.4, "nopop": true, "nobig": true},
	"ke_heavensword": {"place": "bodyf", "dur": 1.3, "nopop": true, "nobig": true, "rumble": 5.0},
	"ke_bladewhirl": {"place": "bodyf", "dur": 1.1, "nopop": true, "nobig": true},
	"ke_armybreak": {"place": "bodyf", "dur": 1.0, "nopop": true, "nobig": true, "rumble": 4.0},
	"ke_lance": {"place": "bodyf", "dur": 0.8, "nopop": true, "nobig": true},
	"ke_parry": {"place": "bodyf", "dur": 1.0, "nopop": true, "nobig": true},
	"ke_cyclone": {"place": "bodyf", "dur": 1.1, "nopop": true, "nobig": true},
	"ke_crossqi": {"place": "bodyf", "dur": 1.0, "nopop": true, "nobig": true},
	"ke_swordarray": {"place": "bodyf", "dur": 1.8, "nopop": true, "nobig": true, "rumble": 8.0},
	"ke_swordlotus": {"place": "bodyf", "dur": 1.5, "nopop": true, "nobig": true, "rumble": 5.0},
}

static func draw(s, sg: String, t: float, lowq: bool) -> void:
	if sg == "pj_muzzle":
		_muzzle(s, t)
		return
	if sg == "pj_muzzle_bow":
		_muzzle(s, t)
		# cánh cung: kéo dây rồi buông (dây rung)
		var pull := 14.0 * (1.0 - eo(sg(t, 0.0, 0.25)))
		var wob := sin(t * 90.0) * 2.0 * (1.0 - sg(t, 0.25, 0.9)) * sg(t, 0.25, 0.3)
		bow(s, Vector2(14.0, -4.0), 0.0, 24.0, pull, wob, 1.0 - sg(t, 0.55, 1.0), t < 0.25)
		return
	if sg.begins_with("hit_"):
		draw_hit(s, sg.substr(4), t, lowq)
		return
	if sg.begins_with("au_"):
		draw_aura(s, sg, t, lowq)
		return
	match sg:
		"ke_sweep4": _sweep4(s, t, lowq)
		"ke_windslash": _windslash(s, t, lowq)
		"ke_mindcounter": _mindcounter(s, t, lowq)
		"ke_orbitswords": _orbitswords(s, t, lowq)
		"ke_dragonslash": _dragonslash(s, t, lowq)
		"ke_triblade": _triblade(s, t, lowq)
		"ke_riverqi": _riverqi(s, t, lowq)
		"ke_tenthousand": _tenthousand(s, t, lowq)
		"ke_cloudcyclone": _cloudcyclone(s, t, lowq)
		"ke_trueawaken": _trueawaken(s, t, lowq)
		"ke_dashcut": _dashcut(s, t, lowq)
		"ke_chain4": _chain4(s, t, lowq)
		"ke_rage": _rage(s, t, lowq)
		"ke_willshield": _willshield(s, t, lowq)
		"ke_heavensword": _heavensword(s, t, lowq)
		"ke_bladewhirl": _bladewhirl(s, t, lowq)
		"ke_armybreak": _armybreak(s, t, lowq)
		"ke_lance": _lance(s, t, lowq)
		"ke_parry": _parry(s, t, lowq)
		"ke_cyclone": _cyclone(s, t, lowq)
		"ke_crossqi": _crossqi(s, t, lowq)
		"ke_swordarray": _swordarray(s, t, lowq)
		"ke_swordlotus": _swordlotus(s, t, lowq)
		_: pass

# ============================================================ tiện ích (bộ nét vẽ khử răng cưa, có gradient)
const GY := 32.0   # mặt đất (so với thân)

static func A(s, al: float) -> Color:
	return s._a(clampf(al, 0.0, 1.0))
static func K(s, al: float) -> Color:
	return s._k(clampf(al, 0.0, 1.0))
static func M(s, u: float, al: float) -> Color:
	return s._mix(u, clampf(al, 0.0, 1.0))
static func rst(s) -> void:
	s.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
static func sg(t: float, a: float, b: float) -> float:   # đoạn thời gian 0..1 trong [a,b]
	return clampf((t - a) / maxf(0.0001, b - a), 0.0, 1.0)
static func eo(x: float) -> float:
	return 1.0 - pow(1.0 - clampf(x, 0.0, 1.0), 3.0)
static func ei(x: float) -> float:
	return pow(clampf(x, 0.0, 1.0), 3.0)
static func rnd(i: int, k: int = 0) -> float:   # ngẫu nhiên cố định theo chỉ số
	var v := sin(float(i) * 12.9898 + float(k) * 78.233) * 43758.5453
	return v - floor(v)
## Như fadeo nhưng giữ nguyên (không mờ) khi vẽ hào quang buff kéo dài (s.steady).
static func fo(s, t: float, from: float) -> float:
	return 1.0 if s.steady else fadeo(t, from)
static func fadeo(t: float, from: float) -> float:
	return 1.0 - clampf((t - from) / maxf(0.001, 1.0 - from), 0.0, 1.0)

# --- nét vẽ khử răng cưa
static func L(s, a: Vector2, b: Vector2, c: Color, w: float = 1.0) -> void:
	s.draw_line(a, b, c, w, true)
static func PL(s, pts: PackedVector2Array, c: Color, w: float = 1.0) -> void:
	if pts.size() >= 2: s.draw_polyline(pts, c, w, true)
static func AR(s, c: Vector2, r: float, a0: float, a1: float, n: int, col: Color, w: float = 1.0) -> void:
	if r > 0.5: s.draw_arc(c, r, a0, a1, n, col, w, true)
static func CI(s, p: Vector2, r: float, col: Color) -> void:
	if r > 0.3: s.draw_circle(p, r, col, true, -1.0, true)
## Đa giác đặc + viền khử răng cưa cùng màu (mép mịn).
static func P(s, pts: PackedVector2Array, col: Color) -> void:
	if pts.size() < 3: return
	s.draw_colored_polygon(pts, col)
	var o := pts.duplicate()
	o.append(pts[0])
	s.draw_polyline(o, col, 1.2, true)
## Đa giác tô gradient theo đỉnh.
static func PG(s, pts: PackedVector2Array, cols: PackedColorArray) -> void:
	if pts.size() < 3 or pts.size() != cols.size(): return
	# bỏ đa giác suy biến (diện tích ~0 hoặc tự cắt) để engine không báo lỗi triangulation
	var ar := 0.0
	for i in range(pts.size()):
		var a: Vector2 = pts[i]
		var b: Vector2 = pts[(i + 1) % pts.size()]
		ar += a.x * b.y - b.x * a.y
	if pts.size() == 4:
		# tứ giác vẽ thành hai tam giác: luôn hợp lệ kể cả khi tứ giác tự cắt
		for tri in [[0, 1, 2], [0, 2, 3]]:
			var p0: Vector2 = pts[tri[0]]
			var p1: Vector2 = pts[tri[1]]
			var p2: Vector2 = pts[tri[2]]
			if absf((p1 - p0).cross(p2 - p0)) < 0.5: continue
			s.draw_polygon(PackedVector2Array([p0, p1, p2]), PackedColorArray([cols[tri[0]], cols[tri[1]], cols[tri[2]]]))
		return
	if absf(ar) < 1.0: return
	s.draw_polygon(pts, cols)

## Quầng sáng mềm nhiều lớp.
static func glow(s, c: Vector2, r: float, al: float) -> void:
	if r < 1.0 or al <= 0.01: return
	for i in range(10):
		var u := float(i) / 9.0
		CI(s, c, r * (1.0 - u * 0.86), M(s, u, al * (0.05 + 0.42 * u * u)))

static func ering(s, c: Vector2, rx: float, ry: float, col: Color, w: float, rot: float = 0.0) -> void:
	if ry < 0.5 or rx < 0.5: return
	s.draw_set_transform(c, rot, Vector2(rx / ry, 1.0))
	s.draw_arc(Vector2.ZERO, ry, 0.0, TAU, 48, col, w, true)
	rst(s)

## Vệt sáng 4 cánh (lóe sao) với tia dài mảnh.
static func flare(s, p: Vector2, r: float, al: float) -> void:
	if al <= 0.02 or r < 1.0: return
	glow(s, p, r * 0.9, al * 0.5)
	for k in range(2):
		var d := Vector2(1.0, 0.0) if k == 0 else Vector2(0.0, 1.0)
		var ln := r * (2.4 if k == 0 else 1.7)
		for j in range(4):
			var u0 := float(j) / 4.0
			var u1 := float(j + 1) / 4.0
			var w := (1.0 - u0) * 2.6
			L(s, p + d * ln * u0, p + d * ln * u1, K(s, al * (1.0 - u0)), w)
			L(s, p - d * ln * u0, p - d * ln * u1, K(s, al * (1.0 - u0)), w)
	CI(s, p, r * 0.22, K(s, al))

## Vệt chém cong (swoosh) quanh tâm c bán kính r, quét góc a0→a1. head 0..1 = đầu vệt đã quét, tail = độ dài đuôi.
## Có gradient: mép ngoài lõi trắng sáng → thân màu chính → trong mờ dần; đuôi mờ dần; chớp sao ở đầu.
static func swoosh(s, c: Vector2, r: float, a0: float, a1: float, head: float, tail: float, th: float, al: float, ry: float = 1.0) -> void:
	if al <= 0.01 or head <= 0.01: return
	th = minf(th, r * 0.85)
	var u0 := maxf(0.0, head - tail)
	var steps := 22
	var o := PackedVector2Array()
	var m := PackedVector2Array()
	var n := PackedVector2Array()
	var h := PackedVector2Array()
	var fs := PackedFloat32Array()
	for i in range(steps + 1):
		var u := lerpf(u0, head, float(i) / float(steps))
		var a := lerpf(a0, a1, u)
		var k := float(i) / float(steps)
		var thk := th * pow(k, 0.7) * (1.0 - 0.25 * pow(k, 6.0))
		var dir := Vector2(cos(a), sin(a) * ry)
		o.append(c + dir * r)
		m.append(c + dir * (r - thk * 0.42))
		n.append(c + dir * (r - thk))
		h.append(c + dir * (r + 6.0 + thk * 0.15))
		fs.append(al * pow(k, 0.85))
	PL(s, h, A(s, al * 0.22), 9.0)
	PL(s, o, A(s, al * 0.35), 5.0)
	for j in range(steps):
		var f0 := fs[j]
		var f1 := fs[j + 1]
		if o[j].distance_to(n[j]) + o[j + 1].distance_to(n[j + 1]) < 1.0: continue
		PG(s, PackedVector2Array([o[j], o[j + 1], m[j + 1], m[j]]), PackedColorArray([K(s, f0), K(s, f1), A(s, f1 * 0.9), A(s, f0 * 0.9)]))
		PG(s, PackedVector2Array([m[j], m[j + 1], n[j + 1], n[j]]), PackedColorArray([A(s, f0 * 0.9), A(s, f1 * 0.9), A(s, 0.0), A(s, 0.0)]))
	# lõi sáng viền ngoài + vệt gió mảnh bên trong
	var core := PackedVector2Array()
	for j in range(steps / 3, steps + 1):
		core.append(o[j])
	PL(s, core, K(s, al), 1.8)
	for q in range(2):
		var li := PackedVector2Array()
		for j in range(steps / 2, steps + 1):
			var f := 0.28 + 0.2 * float(q)
			li.append(o[j].lerp(n[j], f))
		PL(s, li, K(s, al * 0.45), 1.0)
	if head < 1.0 or al > 0.6:
		flare(s, o[steps], 7.0 + th * 0.12, al * 0.9)

## Thanh kiếm đang vung theo vệt chém (đầu vệt), kèm 2 tàn ảnh phía sau.
static func swing(s, c: Vector2, r: float, a0: float, a1: float, head: float, al: float, ry: float = 1.0) -> void:
	if al <= 0.02 or head <= 0.02: return
	for j in range(3):
		var hh := head - 0.09 * float(j)
		if hh <= 0.0: continue
		var a := lerpf(a0, a1, hh)
		var dir := Vector2(cos(a), sin(a) * ry)
		sword(s, c + dir * r * 0.12, atan2(dir.y, dir.x), r * 0.95, 9.0, al * (1.0 if j == 0 else 0.28 / float(j)))

## Nhát chém thẳng thon hai đầu, có gradient + tia sáng dọc thân.
static func cut(s, a: Vector2, b: Vector2, w: float, al: float) -> void:
	var d := b - a
	if d.length() < 1.0 or al <= 0.01: return
	var nr := d.orthogonal().normalized()
	var m := a.lerp(b, 0.45)
	PG(s, PackedVector2Array([a, m + nr * w * 1.9, b, m - nr * w * 1.9]), PackedColorArray([A(s, 0.0), A(s, al * 0.3), A(s, 0.0), A(s, al * 0.3)]))
	PG(s, PackedVector2Array([a, m + nr * w, b, m - nr * w]), PackedColorArray([A(s, 0.0), A(s, al * 0.9), A(s, 0.0), A(s, al * 0.9)]))
	for j in range(6):
		var u0 := float(j) / 6.0
		var u1 := float(j + 1) / 6.0
		var f := sin((u0 + u1) * 0.5 * PI)
		L(s, a.lerp(b, u0), a.lerp(b, u1), K(s, al * f), maxf(1.3, w * 0.4) * f)

## Thanh kiếm chi tiết: nửa lưỡi sáng/tối, rãnh máu, tay kiếm cong có ngọc, chuôi quấn dây, đuôi chuôi.
static func sword(s, hilt: Vector2, ang: float, ln: float, w: float, al: float) -> void:
	if al <= 0.01 or ln < 8.0 or w < 1.0: return
	var d := Vector2(cos(ang), sin(ang))
	var nr := d.orthogonal()
	var gd := hilt + d * ln * 0.15
	var shoulder := hilt + d * ln * 0.86
	var tip := hilt + d * ln
	var hw := w * 0.5
	# quầng sáng mềm quanh lưỡi (các lớp nét mờ chồng nhau, không có mép cứng)
	for hq in range(4):
		L(s, gd + d * 2.0, tip, A(s, al * 0.05), w * (2.6 - 0.5 * float(hq)))
	# chuôi + dây quấn + đuôi
	L(s, hilt, gd, M(s, 0.55, al * 0.95), maxf(2.2, w * 0.36))
	var wr := int(ln * 0.15 / 3.5)
	for i in range(wr):
		var q := hilt.lerp(gd, (float(i) + 0.5) / float(maxi(wr, 1)))
		L(s, q + nr * w * 0.2 - d * 1.4, q - nr * w * 0.2 + d * 1.4, K(s, al * 0.5), 1.0)
	CI(s, hilt - d * 1.5, maxf(2.0, w * 0.34), M(s, 0.2, al))
	CI(s, hilt - d * 1.5, maxf(0.9, w * 0.14), K(s, al))
	# thân lưỡi: nửa sáng (lõi trắng) + nửa tối (màu chính)
	P(s, PackedVector2Array([gd, gd + nr * hw, shoulder + nr * hw * 0.82, tip, shoulder]), K(s, al * 0.85))
	P(s, PackedVector2Array([gd, gd - nr * hw, shoulder - nr * hw * 0.82, tip, shoulder]), A(s, al * 0.8))
	PL(s, PackedVector2Array([gd + nr * hw, shoulder + nr * hw * 0.82, tip, shoulder - nr * hw * 0.82, gd - nr * hw]), K(s, al), 1.1)
	L(s, gd + d * 3.0, hilt + d * ln * 0.8, A(s, al * 0.95), maxf(1.0, w * 0.1))   # rãnh máu
	# tay kiếm (cong lên hai đầu) + ngọc
	var gw := maxf(w * 1.15, 6.0)
	P(s, PackedVector2Array([gd + nr * gw + d * 4.0, gd + nr * gw * 0.7 - d * 1.5, gd - nr * gw * 0.7 - d * 1.5, gd - nr * gw + d * 4.0, gd - nr * gw * 0.45 + d * 1.0, gd + nr * gw * 0.45 + d * 1.0]), M(s, 0.45, al))
	CI(s, gd - d * 0.5, maxf(1.6, w * 0.22), K(s, al))
	# lóe mũi
	if ln > 40.0 and al > 0.35:
		flare(s, tip, w * 0.55, al * 0.55)

## Hạt tia lửa có đuôi gradient.
static func spark(s, p: Vector2, n: int, r: float, t: float, al: float, seed: int = 0) -> void:
	if al <= 0.01: return
	for i in range(n):
		var a := TAU * rnd(i, seed)
		var dd := Vector2(cos(a), sin(a))
		var dist := r * (0.3 + 0.7 * rnd(i, seed + 7)) * eo(t)
		var q := p + dd * dist
		var ln := (5.0 + 9.0 * rnd(i, seed + 4)) * (1.0 - t * 0.5)
		L(s, q - dd * ln, q - dd * ln * 0.45, K(s, al * 0.25), 1.2)
		L(s, q - dd * ln * 0.45, q, K(s, al), 1.8)
		CI(s, q, 1.4, K(s, al))

## Lóe sao nổ: lõi sáng + cánh sao + tia dài + vòng.
static func star(s, p: Vector2, r: float, al: float, n: int = 8) -> void:
	if al <= 0.01 or r < 1.0: return
	glow(s, p, r * 1.3, al * 0.7)
	var pts := PackedVector2Array()
	for k in range(n * 2):
		var a := TAU * float(k) / float(n * 2) - PI * 0.5
		var rr := r if k % 2 == 0 else r * 0.2
		pts.append(p + Vector2(cos(a), sin(a)) * rr)
	P(s, pts, A(s, al * 0.85))
	var pts2 := PackedVector2Array()
	for k in range(n * 2):
		var a2 := TAU * float(k) / float(n * 2) - PI * 0.5 + PI / float(n * 2)
		var rr2 := r * 0.62 if k % 2 == 0 else r * 0.18
		pts2.append(p + Vector2(cos(a2), sin(a2)) * rr2)
	P(s, pts2, K(s, al * 0.8))
	CI(s, p, r * 0.24, K(s, al))
	flare(s, p, r * 0.55, al * 0.6)

## Bụi cuộn lên từ mặt đất.
static func dust(s, c: Vector2, rx: float, t: float, al: float, n: int = 10, seed: int = 0) -> void:
	if al <= 0.01: return
	for i in range(n):
		var x := (rnd(i, seed) - 0.5) * 2.0 * rx * (0.3 + 0.7 * eo(t))
		var r0 := 5.0 + 9.0 * rnd(i, seed + 3)
		var rise := 18.0 * eo(t) * (0.4 + rnd(i, seed + 5))
		var p := c + Vector2(x, -rise)
		CI(s, p, r0 * (0.6 + 0.9 * t), Color(0.86, 0.84, 0.78, 0.2 * al))
		CI(s, p + Vector2(-r0 * 0.25, -r0 * 0.2), r0 * (0.4 + 0.5 * t), Color(1.0, 0.98, 0.92, 0.14 * al))

## Sóng xung kích trên mặt đất: vòng nhiều lớp + gai sáng + bụi.
static func shock(s, c: Vector2, rx: float, ry: float, al: float) -> void:
	if al <= 0.01 or rx < 2.0: return
	ering(s, c, rx, ry, A(s, al * 0.22), 11.0)
	ering(s, c, rx, ry, A(s, al * 0.55), 6.0)
	ering(s, c, rx, ry, A(s, al * 0.95), 3.0)
	ering(s, c, rx * 0.96, ry * 0.96, K(s, al), 1.4)
	ering(s, c, rx * 0.62, ry * 0.62, A(s, al * 0.4), 2.0)
	for i in range(12):
		var a := TAU * float(i) / 12.0 + 0.2
		var p := c + Vector2(cos(a) * rx, sin(a) * ry)
		var up := Vector2(0, -1.0) * (6.0 + 14.0 * rnd(i, 2)) * clampf(rx / 70.0, 0.4, 1.6)
		P(s, PackedVector2Array([p + Vector2(-2.6, 0), p + up, p + Vector2(2.6, 0)]), K(s, al * 0.7))

## Chùm sáng đứng mềm (nhiều lớp chồng).
static func beam(s, x: float, ytop: float, ybot: float, wtop: float, wbot: float, al: float) -> void:
	for i in range(6):
		var k := 1.0 - float(i) / 6.0
		PG(s, PackedVector2Array([Vector2(x - wtop * k, ytop), Vector2(x + wtop * k, ytop), Vector2(x + wbot * k, ybot), Vector2(x - wbot * k, ybot)]), PackedColorArray([A(s, 0.0), A(s, 0.0), A(s, al * 0.09), A(s, al * 0.09)]))

## Lưỡi lửa cong có gradient (gốc sáng → ngọn trong suốt), lay động theo t.
static func flame(s, base: Vector2, h: float, w: float, t: float, ph: float, al: float) -> void:
	if al <= 0.01 or h < 4.0: return
	var steps := 9
	var l := PackedVector2Array()
	var r := PackedVector2Array()
	var c := PackedVector2Array()
	for i in range(steps + 1):
		var u := float(i) / float(steps)
		var sway := sin(t * 11.0 + ph + u * 3.0) * u * w * 0.55
		var hw := w * pow(1.0 - u, 0.75) * (1.0 + 0.18 * sin(u * 9.0 + t * 8.0 + ph))
		var y := -h * u
		l.append(base + Vector2(sway - hw, y))
		r.append(base + Vector2(sway + hw, y))
		c.append(base + Vector2(sway, y))
	for i in range(steps):
		var a0 := al * (1.0 - float(i) / float(steps))
		var a1 := al * (1.0 - float(i + 1) / float(steps))
		PG(s, PackedVector2Array([l[i], r[i], r[i + 1], l[i + 1]]), PackedColorArray([A(s, a0 * 0.85), A(s, a0 * 0.85), A(s, a1 * 0.85), A(s, a1 * 0.85)]))
		var k0 := 0.55
		PG(s, PackedVector2Array([c[i].lerp(l[i], k0), c[i].lerp(r[i], k0), c[i + 1].lerp(r[i + 1], k0), c[i + 1].lerp(l[i + 1], k0)]), PackedColorArray([K(s, a0), K(s, a0), K(s, a1 * 0.6), K(s, a1 * 0.6)]))
	PL(s, l, A(s, al * 0.5), 1.0)
	PL(s, r, A(s, al * 0.5), 1.0)

## Đám mây: cụm vòng tròn mềm, đáy xám xanh, đỉnh sáng.
static func cloud(s, c: Vector2, r: float, al: float) -> void:
	if al <= 0.01 or r < 2.0: return
	var offs := [Vector2(-0.9, 0.1), Vector2(-0.35, -0.35), Vector2(0.3, -0.25), Vector2(0.9, 0.05), Vector2(0.0, 0.2)]
	var rs := [0.62, 0.78, 0.72, 0.58, 0.7]
	for i in range(5):
		CI(s, c + (offs[i] as Vector2) * r + Vector2(0, r * 0.12), r * float(rs[i]), Color(0.62, 0.7, 0.82, 0.16 * al))
	for i in range(5):
		CI(s, c + (offs[i] as Vector2) * r, r * float(rs[i]) * 0.92, Color(0.95, 0.97, 1.0, 0.2 * al))
	for i in range(5):
		CI(s, c + (offs[i] as Vector2) * r + Vector2(-r * 0.1, -r * 0.18), r * float(rs[i]) * 0.5, Color(1, 1, 1, 0.16 * al))

static func speedlines(s, x0: float, x1: float, y0: float, y1: float, n: int, al: float, seed: int = 0) -> void:
	for i in range(n):
		var y := lerpf(y0, y1, rnd(i, seed))
		var xa := lerpf(x0, x1, rnd(i, seed + 3) * 0.6)
		var xb := minf(xa + (x1 - x0) * (0.25 + 0.35 * rnd(i, seed + 5)), x1)
		var f := al * (0.4 + 0.5 * rnd(i, seed + 9))
		L(s, Vector2(xa, y), Vector2((xa + xb) * 0.5, y), A(s, f * 0.35), 1.6)
		L(s, Vector2((xa + xb) * 0.5, y), Vector2(xb, y), A(s, f), 1.8)

static func man(s, pos: Vector2, al: float) -> void:
	s.draw_set_transform(pos, 0.0, Vector2.ONE)
	s._man(0.0, al)
	rst(s)

## Vết nứt đất phát sáng có nhánh.
static func crack(s, c: Vector2, rx: float, al: float, seed: int = 0) -> void:
	if al <= 0.01: return
	for i in range(9):
		var a := PI * (0.05 + 0.9 * float(i) / 8.0) * (1.0 if i % 2 == 0 else -1.0)
		var d := Vector2(cos(a), sin(a) * 0.28)
		var pts := PackedVector2Array([c])
		for k in range(1, 6):
			var p := c + d * rx * float(k) / 5.0 * (0.6 + 0.4 * rnd(i, seed)) + Vector2(0, (rnd(i * 5 + k, seed) - 0.5) * 7.0)
			pts.append(p)
			if k == 3:
				var bd := Vector2(d.x, d.y + (rnd(i, seed + 9) - 0.5) * 0.8).normalized()
				PL(s, PackedVector2Array([p, p + bd * rx * 0.18]), K(s, al * 0.6), 1.1)
		PL(s, pts, A(s, al * 0.45), 5.0)
		PL(s, pts, K(s, al * 0.95), 1.6)

# ============================================================ KIẾM SĨ
## ks25 Kiếm Khí Hoành Tảo — 4 nhát liên tiếp (range 200), nhát cuối to hơn và bắn kiếm khí.
static func _sweep4(s, t: float, lowq: bool) -> void:
	var c := Vector2(-6.0, 0.0)
	var specs := [[-1.15, 0.55, 118.0, 26.0], [0.7, -0.9, 128.0, 28.0], [-0.5, 0.5, 140.0, 30.0]]
	for k in range(3):
		var p := sg(t, 0.04 + 0.19 * k, 0.17 + 0.19 * k)
		var sp: Array = specs[k]
		var life := fadeo(t, 0.17 + 0.19 * k + 0.08)
		swoosh(s, c, float(sp[2]), float(sp[0]), float(sp[1]), eo(p), 0.7, float(sp[3]), life)
		swing(s, c, float(sp[2]), float(sp[0]), float(sp[1]), eo(p), life)
		if p > 0.7 and p < 1.0 or (p >= 1.0 and life > 0.5):
			spark(s, Vector2(float(sp[2]) * 0.75, 0), 5, 22.0, sg(t, 0.14 + 0.19 * k, 0.4 + 0.19 * k), life, k)
	# nhát 4 to hơn + kiếm khí bay ra
	var p4 := sg(t, 0.62, 0.78)
	var l4 := fadeo(t, 0.8)
	swoosh(s, c, 180.0, -1.1, 0.9, eo(p4), 0.8, 54.0, l4)
	swing(s, c, 180.0, -1.1, 0.9, eo(p4), l4)
	if p4 >= 1.0:
		var fp := sg(t, 0.78, 1.0)
		var x := 90.0 + 130.0 * eo(fp)
		swoosh(s, Vector2(x - 60.0, 0), 62.0, -1.0, 1.0, 1.0, 1.0, 22.0, (1.0 - fp) * 0.9, 1.35)
		star(s, Vector2(190.0, 0), 22.0 * (1.0 - fp), 1.0 - fp)

## ks27 Nhất Kiếm Thiên Phong — lướt 300px rồi một nhát chém cực mạnh, gió xoáy dọc đường.
static func _windslash(s, t: float, lowq: bool) -> void:
	var D := 300.0
	var run := sg(t, 0.0, 0.3)
	var life := fadeo(t, 0.7)
	if t < 0.55:
		speedlines(s, -20.0, D + 20.0, -24.0, 28.0, 8 if lowq else 14, (1.0 - sg(t, 0.3, 0.55)) * 0.9, 2)
		for i in range(4):
			var x := D * eo(run) * (1.0 - 0.22 * float(i))
			man(s, Vector2(x, 0), 0.28 * (1.0 - 0.2 * float(i)) * (1.0 - sg(t, 0.3, 0.55)))
		# xoáy gió dọc đường
		for i in range(5):
			var x2 := D * (0.15 + 0.17 * float(i)) * eo(run)
			AR(s, Vector2(x2, 4), 16.0 + 4.0 * float(i % 2), -1.2, 1.2, 10, A(s, 0.5 * (1.0 - sg(t, 0.35, 0.6))), 2.4)
	# nhát chém cuối
	var p := sg(t, 0.22, 0.45)
	swoosh(s, Vector2(D - 70.0, 4), 150.0, -1.25, 1.1, eo(p), 0.85, 62.0, life)
	swing(s, Vector2(D - 70.0, 4), 150.0, -1.25, 1.1, eo(p), life)
	if p >= 1.0:
		var h := sg(t, 0.45, 1.0)
		cut(s, Vector2(D + 20.0, -90.0), Vector2(D - 20.0, 70.0), 7.0 * (1.0 - h), life)
		shock(s, Vector2(D, GY - 4.0), 20.0 + 90.0 * eo(h), 5.0 + 22.0 * eo(h), 1.0 - h)
		spark(s, Vector2(D, 0), 12, 70.0, h, 1.0 - h, 3)

## ks30 Kiếm Tâm Phản Kích — thế thủ kiếm ngang ngực trong trận kiếm tâm (mandala quay); đỡ đòn rồi phản chấn bật ra.
static func _mindcounter(s, t: float, lowq: bool) -> void:
	var up := eo(sg(t, 0.0, 0.2))
	var life := fo(s, t, 0.85)
	var al := up * life
	var gc := Vector2(0, GY - 6.0)
	ering(s, gc, 58.0 * up, 14.0 * up, A(s, 0.3 * al), 8.0)
	ering(s, gc, 58.0 * up, 14.0 * up, A(s, 0.9 * al), 2.4)
	ering(s, gc, 42.0 * up, 10.0 * up, K(s, 0.7 * al), 1.4)
	for i in range(8):
		var a := TAU * float(i) / 8.0 + t * 1.8
		var b := TAU * float((i + 3) % 8) / 8.0 + t * 1.8
		L(s, gc + Vector2(cos(a) * 46.0 * up, sin(a) * 11.0), gc + Vector2(cos(b) * 46.0 * up, sin(b) * 11.0), A(s, 0.5 * al), 1.2)
		var p := gc + Vector2(cos(a) * 52.0 * up, sin(a) * 12.5)
		P(s, PackedVector2Array([p + Vector2(-2.6, 0), p + Vector2(0, -12.0), p + Vector2(2.6, 0)]), K(s, 0.85 * al))
	glow(s, Vector2(-4.0, -20.0), 44.0 * up, 0.18 * al)
	AR(s, Vector2(-4.0, -20.0), 34.0 * up, 0.0, TAU, 40, A(s, 0.4 * al), 1.6)
	sword(s, Vector2(8.0, -2.0), -0.14, 62.0, 9.0, al)
	glow(s, Vector2(40.0, -6.0), 28.0, 0.28 * al)
	var hit := sg(t, 0.38, 0.5)
	if hit > 0.0:
		var q := sg(t, 0.4, 1.0)
		var pt := Vector2(54.0, -9.0)
		star(s, pt, 26.0 * (1.0 - q) + 4.0, (1.0 - q), 8)
		spark(s, pt, 14, 54.0, q, 1.0 - q, 1)
		for k in range(4):
			var qk := clampf(q * 1.4 - 0.12 * float(k), 0.0, 1.0)
			if qk <= 0.0: continue
			s.draw_set_transform(pt + Vector2(10.0 + 150.0 * eo(qk), 0.0), 0.0, Vector2(0.5, 1.0))
			swoosh(s, Vector2.ZERO, 40.0 + 12.0 * float(k), -1.2, 1.2, 1.0, 1.0, 14.0, (1.0 - qk) * (1.0 - 0.15 * float(k)))
			rst(s)
		for i in range(6):
			var y := -36.0 + 14.0 * float(i)
			var x := 60.0 + 130.0 * eo(q)
			L(s, Vector2(x - 56.0, y), Vector2(x - 20.0, y), A(s, 0.25 * (1.0 - q)), 1.4)
			L(s, Vector2(x - 20.0, y), Vector2(x, y), A(s, 0.8 * (1.0 - q)), 1.8)

## ks32 Kiếm Ý Hộ Thân — 8 thanh kiếm bay vòng quanh người trên quỹ đạo nghiêng, để lại vệt sáng; vòng kiếm ý dưới chân.
static func _orbitswords(s, t: float, lowq: bool) -> void:
	var up := eo(sg(t, 0.0, 0.18))
	var life := fo(s, t, 0.85)
	var al := up * life
	var cy := Vector2(0, -6)
	ering(s, Vector2(0, GY - 4.0), 52.0 * up, 13.0 * up, A(s, 0.35 * al), 7.0)
	ering(s, Vector2(0, GY - 4.0), 52.0 * up, 13.0 * up, A(s, 0.85 * al), 2.2)
	ering(s, Vector2(0, GY - 4.0), 38.0 * up, 9.0 * up, K(s, 0.6 * al), 1.4)
	for i in range(8):
		var a := TAU * float(i) / 8.0 - t * 2.0
		var p := Vector2(cos(a) * 45.0 * up, GY - 4.0 + sin(a) * 11.0)
		P(s, PackedVector2Array([p + Vector2(-2.5, 0), p + Vector2(0, -9.0), p + Vector2(2.5, 0)]), K(s, 0.75 * al))
	for tr in range(2):
		var pts := PackedVector2Array()
		for k in range(28):
			var a2 := float(k) / 27.0 * TAU
			pts.append(cy + Vector2(cos(a2) * 46.0, sin(a2) * 16.0 - 6.0 + 9.0 * float(tr)))
		PL(s, pts, A(s, 0.22 * al), 3.0)
	var n := 8
	for pass_i in range(2):
		for i in range(n):
			var a := TAU * float(i) / float(n) + t * 6.0
			var front := sin(a) > 0.0
			if (pass_i == 0) == front: continue
			var r := 46.0 * up
			var p := cy + Vector2(cos(a) * r, sin(a) * 16.0 - 6.0 * sin(t * 6.0 + float(i)))
			var tang := a + PI * 0.5
			var dv := Vector2(cos(tang), sin(tang) * 0.35)
			var depth := 0.5 + 0.5 * (sin(a) * 0.5 + 0.5)
			var tail := PackedVector2Array()
			for q in range(7):
				var aa := a - 0.09 * float(q)
				tail.append(cy + Vector2(cos(aa) * r, sin(aa) * 16.0 - 6.0))
			PL(s, tail, A(s, 0.35 * al * depth), 3.5)
			sword(s, p - dv * 16.0, atan2(dv.y, dv.x), 32.0, 6.0, al * depth)
	glow(s, cy, 36.0, 0.2 * al)
	spark(s, cy, 6, 60.0, fmod(t * 2.0, 1.0), 0.6 * al, 2)

## ks35 Long Ảnh Liên Trảm — rồng bóng uốn lượn lao 220px (thân vảy 2 tông, chân vuốt, sừng, râu, mây), để lại nhát chém chéo.
static func _dragonslash(s, t: float, lowq: bool) -> void:
	if s.nocreature:
		_dragonslash_cuts(s, t, lowq)
		return
	var D := 220.0
	var p := eo(sg(t, 0.0, 0.5))
	var life := fadeo(t, 0.7)
	var segs := 26
	var pts: Array = []
	for i in range(segs):
		var u := float(i) / float(segs - 1)
		var x := D * p - u * 190.0 * minf(1.0, p * 1.5)
		var y := sin(u * 6.5 - t * 14.0) * (12.0 + 20.0 * u) - 12.0 * (1.0 - u)
		pts.append(Vector2(x, y))
	# mây/khói sau rồng
	for i in range(0 if lowq else 9):
		var u2 := rnd(i, 1)
		var q: Vector2 = pts[int(u2 * float(segs - 1))]
		CI(s, q + Vector2(-8.0 - 14.0 * rnd(i, 2), 10.0 * (rnd(i, 3) - 0.5)), 9.0 + 12.0 * rnd(i, 4), A(s, 0.1 * life))
	for i in range(segs - 1, 0, -1):
		var u := float(i) / float(segs - 1)
		var w := 13.0 * (1.0 - u * 0.88) + 1.0
		var a: Vector2 = pts[i]
		var b: Vector2 = pts[i - 1]
		var nr := (b - a).orthogonal().normalized()
		# thân: lưng (màu chính) + bụng (lõi sáng) + viền
		PG(s, PackedVector2Array([a - nr * w, b - nr * w, b + nr * w, a + nr * w]), PackedColorArray([A(s, 0.0), A(s, 0.0), A(s, 0.0), A(s, 0.0)]))
		L(s, a, b, A(s, 0.35 * life), w * 2.6)
		L(s, a, b, A(s, 0.92 * life), w * 1.7)
		L(s, a + nr * w * 0.45, b + nr * w * 0.45, K(s, 0.75 * life), w * 0.7)   # bụng sáng
		if i % 2 == 0:
			PL(s, PackedVector2Array([a - nr * w * 0.8, a, a + nr * w * 0.8]), K(s, 0.55 * life), 1.0)   # vảy
		if i % 3 == 0 and i > 2:
			var spn := -nr * (w + 6.0)
			P(s, PackedVector2Array([a - nr * w * 0.9 - (b - a).normalized() * 3.0, a + spn, a - nr * w * 0.9 + (b - a).normalized() * 3.0]), K(s, 0.9 * life))   # gai lưng
		# chân vuốt ở 2 điểm
		if i == 8 or i == 15:
			var lg := nr * (w + 11.0)
			L(s, a + nr * w * 0.6, a + lg, A(s, life), 3.0)
			PL(s, PackedVector2Array([a + lg + Vector2(-5, 0), a + lg, a + lg + Vector2(5, -1)]), K(s, life), 1.6)
			PL(s, PackedVector2Array([a + lg + Vector2(-3, 3), a + lg, a + lg + Vector2(4, 3)]), K(s, life), 1.4)
	var h: Vector2 = pts[0]
	var hd: Vector2 = (pts[0] - pts[2]).normalized()
	if p > 0.02:
		glow(s, h + hd * 6.0, 34.0, 0.4 * life)
		# đầu: sọ, mõm, hàm dưới, sừng nhánh, tóc bờm, râu dài, mắt
		P(s, PackedVector2Array([h + Vector2(-12, -11), h + Vector2(14, -8), h + Vector2(32, -1), h + Vector2(26, 5), h + Vector2(8, 11), h + Vector2(-12, 10)]), A(s, 0.95 * life))
		P(s, PackedVector2Array([h + Vector2(-2, -3), h + Vector2(24, -1), h + Vector2(18, 4), h + Vector2(0, 8)]), K(s, 0.7 * life))
		P(s, PackedVector2Array([h + Vector2(8, 6), h + Vector2(30, 4), h + Vector2(14, 14)]), A(s, 0.85 * life))     # hàm dưới
		for ho in range(2):
			var bx := h + Vector2(-4.0 - 7.0 * float(ho), -10.0)
			PL(s, PackedVector2Array([bx, bx + Vector2(-8, -14), bx + Vector2(-2, -24)]), K(s, life), 2.4)
			PL(s, PackedVector2Array([bx + Vector2(-8, -14), bx + Vector2(-17, -17)]), K(s, life), 1.6)
		for mn in range(4):
			PL(s, PackedVector2Array([h + Vector2(-10, -6 + 3 * mn), h + Vector2(-26, -4 + 6 * mn + sin(t * 18.0 + float(mn)) * 3.0), h + Vector2(-42, 2 + 7 * mn)]), A(s, 0.7 * life), 2.0)
		PL(s, PackedVector2Array([h + Vector2(28, 0), h + Vector2(46, -10), h + Vector2(66, -4), h + Vector2(80, -12)]), K(s, 0.85 * life), 1.6)
		PL(s, PackedVector2Array([h + Vector2(26, 4), h + Vector2(44, 14), h + Vector2(62, 10), h + Vector2(76, 18)]), K(s, 0.85 * life), 1.6)
		CI(s, h + Vector2(8, -4), 3.6, A(s, life))
		CI(s, h + Vector2(8.5, -4), 1.8, K(s, life))
		P(s, PackedVector2Array([h + Vector2(28, -2), h + Vector2(34, -6), h + Vector2(32, 0)]), K(s, life))   # răng/ngọc rồng
		# hơi thở long
		for i in range(0 if lowq else 6):
			var fp := h + Vector2(34.0 + 22.0 * float(i), -2.0 + 6.0 * sin(t * 20.0 + float(i)))
			CI(s, fp, 4.0 - 0.4 * float(i), K(s, 0.6 * life * (1.0 - float(i) / 6.0)))
	# nhát chém chéo để lại ở điểm đến
	var c := sg(t, 0.38, 0.62)
	if c > 0.0:
		var cl := fadeo(t, 0.65)
		cut(s, Vector2(D + 40.0, -86.0 * eo(c)), Vector2(D - 50.0 * eo(c) - 20.0, 86.0 * eo(c)), 8.0, cl)
		cut(s, Vector2(D + 40.0, 74.0 * eo(c)), Vector2(D - 60.0 * eo(c) - 10.0, -74.0 * eo(c)), 6.0, cl * 0.85)
		flare(s, Vector2(D, 0), 20.0, cl)
		spark(s, Vector2(D, 0), 14, 70.0, c, cl, 5)

## ks37 Tam Kiếm Hợp Nhất — ba nhát liên hoàn, nhát cuối nổ kiếm khí.
static func _triblade(s, t: float, lowq: bool) -> void:
	var c := Vector2(-4.0, 0.0)
	var specs := [[-1.0, 0.7, 112.0], [0.75, -0.75, 120.0], [-0.55, 0.6, 134.0]]
	for k in range(3):
		var p := sg(t, 0.05 + 0.2 * k, 0.2 + 0.2 * k)
		var life := fadeo(t, 0.2 + 0.2 * k + 0.1)
		var sp: Array = specs[k]
		swoosh(s, c, float(sp[2]), float(sp[0]), float(sp[1]), eo(p), 0.7, 26.0 + 6.0 * k, life)
		swing(s, c, float(sp[2]), float(sp[0]), float(sp[1]), eo(p), life)
	var e := sg(t, 0.55, 1.0)
	if e > 0.0:
		var ex := Vector2(150.0, -2.0)
		star(s, ex, 44.0 * (1.0 - e * 0.5), 1.0 - e, 10)
		for i in range(10):
			var a := TAU * float(i) / 10.0
			var d := Vector2(cos(a), sin(a))
			cut(s, ex + d * 14.0, ex + d * (30.0 + 70.0 * eo(e)), 3.0 * (1.0 - e), 1.0 - e)
		shock(s, Vector2(150.0, GY - 4.0), 20.0 + 70.0 * eo(e), 5.0 + 16.0 * eo(e), 1.0 - e)

## ks38 Kiếm Khí Trường Hà — dòng sông kiếm khí (tầm 640): thân nước có gradient, sóng, bọt, nhiều thanh kiếm cưỡi trên sóng, đầu sóng lưỡi liềm.
static func _riverqi(s, t: float, lowq: bool) -> void:
	var p := eo(sg(t, 0.0, 0.75))
	var life := fadeo(t, 0.75)
	var head := 60.0 + 540.0 * p
	var tail := maxf(0.0, head - 340.0)
	var n := 28
	var top := PackedVector2Array()
	var bot := PackedVector2Array()
	for i in range(n + 1):
		var u := float(i) / float(n)
		var x := lerpf(tail, head, u)
		var w := 24.0 * (0.25 + 0.75 * pow(u, 0.6))
		var wv := sin(x * 0.04 - t * 12.0) * 7.0 * (0.3 + u)
		top.append(Vector2(x, -w + wv - 4.0))
		bot.append(Vector2(x, w + wv * 0.7 + 2.0))
	for i in range(n):
		var u0 := float(i) / float(n)
		var u1 := float(i + 1) / float(n)
		var a0 := life * pow(u0, 1.1)
		var a1 := life * pow(u1, 1.1)
		PG(s, PackedVector2Array([top[i], top[i + 1], bot[i + 1], bot[i]]), PackedColorArray([A(s, a0 * 0.55), A(s, a1 * 0.55), A(s, a1 * 0.2), A(s, a0 * 0.2)]))
	PL(s, top, K(s, 0.8 * life), 1.6)
	PL(s, bot, A(s, 0.6 * life), 1.4)
	for b in range(4):
		var pts := PackedVector2Array()
		for i in range(n + 1):
			var u := float(i) / float(n)
			var x := lerpf(tail, head, u)
			pts.append(Vector2(x, (float(b) - 1.5) * 8.0 + sin(x * 0.05 - t * 14.0 + float(b) * 1.3) * 6.0 * (0.3 + u)))
		PL(s, pts, A(s, 0.55 * life), 2.6)
		PL(s, pts, K(s, 0.7 * life), 1.0)
	for i in range(5):
		var u2 := 0.2 + 0.16 * float(i)
		var x2 := lerpf(tail, head, u2)
		var y2 := sin(x2 * 0.04 - t * 12.0) * 6.0 - 2.0 + (float(i % 3) - 1.0) * 9.0
		sword(s, Vector2(x2 - 18.0, y2), 0.0, 36.0, 6.0, life * (0.5 + 0.5 * u2))
	swoosh(s, Vector2(head - 78.0, 0), 86.0, -1.0, 1.0, 1.0, 1.0, 38.0, life, 1.2)
	swoosh(s, Vector2(head - 100.0, 0), 70.0, -0.9, 0.9, 1.0, 1.0, 20.0, life * 0.7, 1.2)
	for i in range(0 if lowq else 18):
		var x3 := lerpf(tail, head, rnd(i, 1))
		var y3 := (rnd(i, 2) - 0.5) * 60.0 - 10.0 * sin(t * 9.0 + float(i))
		CI(s, Vector2(x3, y3), 1.4 + 1.8 * rnd(i, 3), K(s, 0.8 * life))
		CI(s, Vector2(x3, y3), 3.0 + 3.0 * rnd(i, 3), A(s, 0.2 * life))
	flare(s, Vector2(head, 0), 14.0, life * 0.8)

## ks40 Vạn Kiếm Quy Tông — kiếm từ mọi phía quy về người rồi bung thành vòng kiếm khí chém mọi hướng (r=240).
static func _tenthousand(s, t: float, lowq: bool) -> void:
	var R := 240.0
	var conv := sg(t, 0.0, 0.34)
	var boom := sg(t, 0.36, 1.0)
	var n := 16 if lowq else 28
	if conv < 1.0 or t < 0.42:
		for i in range(n):
			var a := TAU * (float(i) + rnd(i, 3) * 0.7) / float(n)
			var d := Vector2(cos(a), sin(a) * 0.55)
			var r0 := R * (0.75 + 0.25 * rnd(i, 4))
			var q := eo(conv)
			var p := d * r0 * (1.0 - q) + Vector2(0, -8)
			var al := 1.0 - sg(t, 0.3, 0.42)
			L(s, p, p + d * 34.0, A(s, 0.5 * al), 3.0)
			sword(s, p + d * 26.0, atan2(-d.y, -d.x), 24.0, 4.0, al)
	# điểm tụ: quầng + tia
	var fl := sg(t, 0.28, 0.42) * (1.0 - sg(t, 0.42, 0.62))
	if fl > 0.0:
		glow(s, Vector2(0, -8), 60.0, fl)
		star(s, Vector2(0, -8), 40.0 * fl, fl, 12)
	# bung ra: vòng chém mọi hướng
	if boom > 0.0:
		var e := eo(boom)
		var fa := 1.0 - sg(t, 0.7, 1.0)
		shock(s, Vector2(0, GY - 8.0), R * e, R * e * 0.24, fa)
		ering(s, Vector2(0, GY - 8.0), R * 0.6 * e, R * 0.6 * e * 0.24, A(s, 0.5 * fa), 3.0)
		var m := 12
		for i in range(m):
			var a := TAU * float(i) / float(m) + 0.26
			var d := Vector2(cos(a), sin(a) * 0.5)
			var r1 := R * e
			cut(s, d * (r1 * 0.25), d * r1, 4.0 * (1.0 - boom * 0.5), fa)
		for i in range(6):
			var a2 := PI * float(i) / 5.0 - PI
			swoosh(s, Vector2(0, -8), R * 0.9 * e, a2 - 0.35, a2 + 0.35, 1.0, 1.0, 20.0, fa * 0.9, 0.55)
		spark(s, Vector2(0, -8), 20, R * 0.8, boom, fa, 9)

## ks42 Phong Vân Kiếm Vũ — lốc xoáy mây và kiếm múa (r=260): dải gió xoáy mịn, cụm mây, 8 kiếm có vệt, vòng sóng đất đẩy lùi.
static func _cloudcyclone(s, t: float, lowq: bool) -> void:
	var R := 260.0
	var e := eo(sg(t, 0.0, 0.6))
	var fa := fadeo(t, 0.72)
	var cy := Vector2(0, -8)
	shock(s, Vector2(0, GY - 6.0), R * e, R * e * 0.22, fa * 0.8)
	for k in range(3):
		var rot := t * (10.0 - 3.0 * float(k)) + float(k) * 2.0
		s.draw_set_transform(Vector2(0, GY - 22.0 - 16.0 * float(k)), 0.0, Vector2(1.0, 0.3))
		swoosh(s, Vector2.ZERO, R * e * (1.0 - 0.22 * float(k)), rot, rot + TAU * 0.8, 1.0, 0.75, 26.0, fa * 0.9)
		rst(s)
	for i in range(5 if lowq else 9):
		var a := TAU * float(i) / 9.0 + t * 3.6
		var rr := R * e * (0.45 + 0.4 * rnd(i, 2))
		cloud(s, cy + Vector2(cos(a) * rr, sin(a) * rr * 0.26 - 26.0 * rnd(i, 4)), 14.0 + 10.0 * rnd(i, 5), fa)
	for i in range(8):
		var a2 := TAU * float(i) / 8.0 + t * 7.0
		var rr2 := R * e * (0.35 + 0.4 * fmod(float(i) * 0.37, 1.0))
		var p := cy + Vector2(cos(a2) * rr2, sin(a2) * rr2 * 0.3)
		var tang := a2 + PI * 0.5
		var dv := Vector2(cos(tang), sin(tang) * 0.3)
		var tl := PackedVector2Array()
		for q in range(10):
			var aq := a2 - 0.07 * float(q)
			tl.append(cy + Vector2(cos(aq) * rr2, sin(aq) * rr2 * 0.3))
		PL(s, tl, A(s, 0.35 * fa), 3.0)
		sword(s, p - dv * 18.0, atan2(dv.y, dv.x), 38.0, 6.5, fa)
	for i in range(3):
		var pts := PackedVector2Array()
		for k in range(64):
			var u := float(k) / 63.0
			var a3 := u * TAU * 1.6 + t * 8.0 + float(i) * 2.1
			var rr3 := R * e * (0.1 + 0.85 * u)
			pts.append(cy + Vector2(cos(a3) * rr3, sin(a3) * rr3 * 0.26 - 40.0 * (1.0 - u)))
		PL(s, pts, A(s, 0.35 * fa), 4.0)
		PL(s, pts, K(s, 0.6 * fa), 1.2)

## ks45 Chân Kiếm Thức Tỉnh — chân kiếm khổng lồ trồi lên sau lưng, hào quang kiếm ý, thanh kiếm tách lấp lánh.
static func _trueawaken(s, t: float, lowq: bool) -> void:
	var up := eo(sg(t, 0.0, 0.4))
	var fa := fo(s, t, 0.8)
	var al := up * fa
	# vầng hào quang sau lưng
	glow(s, Vector2(-6, -40), 80.0 * up, 0.3 * al)
	ering(s, Vector2(-6, -44), 50.0 * up, 50.0 * up, A(s, 0.5 * al), 2.0)
	for i in range(12):
		var a := TAU * float(i) / 12.0 + t * 1.2
		var d := Vector2(cos(a), sin(a))
		L(s, Vector2(-6, -44) + d * 56.0 * up, Vector2(-6, -44) + d * (66.0 + 12.0 * sin(t * 8.0 + float(i))) * up, K(s, 0.8 * al), 1.8)
	# chân kiếm khổng lồ: mũi chúc xuống chạm đất sau lưng, chuôi lên cao
	var rise := eo(sg(t, 0.02, 0.45))
	sword(s, Vector2(-24.0, GY - 8.0 - 190.0 * rise), PI * 0.5, 190.0 * rise, 22.0, al)
	glow(s, Vector2(-24.0, -60.0), 40.0, 0.25 * al)
	# kiếm nhỏ bay lên quanh người
	for i in range(0 if lowq else 8):
		var u := fmod(t * 1.4 + rnd(i, 1), 1.0)
		var x := -52.0 + 104.0 * rnd(i, 2)
		var y := GY - 8.0 - 110.0 * u
		sword(s, Vector2(x, y + 14.0), -PI * 0.5, 22.0, 4.0, al * (1.0 - u))
	shock(s, Vector2(-24.0, GY - 4.0), 60.0 * up, 12.0 * up, 0.9 * al)

## pa1 Trảm Kích Lướt — lướt 170px để lại tàn ảnh, kết bằng nhát chém chéo.
static func _dashcut(s, t: float, lowq: bool) -> void:
	var D := 170.0
	var run := eo(sg(t, 0.0, 0.32))
	var life := fadeo(t, 0.6)
	speedlines(s, -10.0, D, -22.0, 28.0, 8, (1.0 - sg(t, 0.25, 0.55)), 4)
	for i in range(1, 5):
		man(s, Vector2(D * run * (1.0 - 0.2 * float(i)), 0), 0.32 * (1.0 - 0.18 * float(i)) * (1.0 - sg(t, 0.3, 0.6)))
	var p := sg(t, 0.24, 0.48)
	swoosh(s, Vector2(D - 40.0, 6), 90.0, -1.2, 0.9, eo(p), 0.85, 40.0, life)
	swing(s, Vector2(D - 40.0, 6), 90.0, -1.2, 0.9, eo(p), life)
	if p >= 1.0:
		var h := sg(t, 0.48, 1.0)
		cut(s, Vector2(D + 40.0, -60.0), Vector2(D - 30.0, 60.0), 6.0 * (1.0 - h), 1.0 - h)
		spark(s, Vector2(D, 0), 9, 50.0, h, 1.0 - h, 6)

## pa2 Liên Trảm — 4 nhát liên tiếp gần thân (range 100).
static func _chain4(s, t: float, lowq: bool) -> void:
	for k in range(4):
		var a0 := 0.04 + 0.2 * k
		var p := sg(t, a0, a0 + 0.13)
		var life := fadeo(t, a0 + 0.14)
		var flip := 1.0 if k % 2 == 0 else -1.0
		var c := Vector2(10.0, -4.0 * flip)
		swoosh(s, c, 78.0 + 8.0 * k, -0.9 * flip, 0.85 * flip, eo(p), 0.8, 22.0 + 3.0 * k, life)
		swing(s, c, 78.0 + 8.0 * k, -0.9 * flip, 0.85 * flip, eo(p), life)
		if p >= 1.0 and life > 0.6:
			star(s, Vector2(84.0 + 10.0 * k, 0), 10.0 + 2.0 * k, life, 6)

## pa3 Cuồng Nộ — hỏa khí bùng quanh người (lưỡi lửa cong gradient), vòng lửa dưới chân, mắt đỏ rực, ký hiệu nổi gân.
static func _rage(s, t: float, lowq: bool) -> void:
	var up := eo(sg(t, 0.0, 0.2))
	var fa := fo(s, t, 0.82)
	var al := up * fa
	var cy := Vector2(0, -6)
	glow(s, cy, 60.0 * up, 0.22 * al)
	ering(s, Vector2(0, GY - 4.0), 48.0 * up, 12.0 * up, A(s, 0.3 * al), 8.0)
	ering(s, Vector2(0, GY - 4.0), 48.0 * up, 12.0 * up, A(s, 0.9 * al), 2.4)
	var n := 8 if lowq else 14
	for i in range(n):
		var a := TAU * float(i) / float(n)
		var base := Vector2(cos(a) * 44.0, GY - 4.0 + sin(a) * 11.0)
		var hh := (46.0 + 34.0 * rnd(i, 2)) * up * (0.8 + 0.2 * sin(t * 9.0 + float(i)))
		flame(s, base, hh, 8.0 + 3.0 * rnd(i, 1), t, float(i), al * (0.65 if sin(a) < 0.0 else 1.0))
	for i in range(5):
		flame(s, Vector2(-22.0 + 11.0 * float(i), GY - 10.0), 54.0 + 18.0 * rnd(i, 4), 7.0, t, 2.0 * float(i), al * 0.9)
	var ey := Vector2(4.0, -26.0)
	L(s, ey + Vector2(-10, 1), ey + Vector2(-2, -3), K(s, al), 2.8)
	L(s, ey + Vector2(2, -3), ey + Vector2(10, 1), K(s, al), 2.8)
	glow(s, ey + Vector2(-5, -1), 12.0, 0.6 * al)
	glow(s, ey + Vector2(6, -1), 12.0, 0.6 * al)
	var sy := Vector2(26.0, -54.0 - 3.0 * sin(t * 14.0))
	for i in range(4):
		var a2 := PI * 0.5 * float(i) + PI * 0.25
		var d := Vector2(cos(a2), sin(a2))
		AR(s, sy + d * 7.0, 6.0, a2 + PI * 0.5, a2 + PI * 1.5, 8, A(s, 0.95 * al), 2.8)
	for i in range(0 if lowq else 14):
		var ph2 := fmod(t * 1.6 + rnd(i, 7), 1.0)
		var p2 := Vector2((rnd(i, 8) - 0.5) * 80.0 + sin(t * 6.0 + float(i)) * 6.0, GY - 120.0 * ph2)
		CI(s, p2, 2.2 * (1.0 - ph2) + 0.6, K(s, al * (1.0 - ph2)))
		CI(s, p2, 4.5 * (1.0 - ph2), A(s, al * 0.3 * (1.0 - ph2)))

## pa4 Khiên Ý Chí — tấm khiên ánh sáng khắc kiếm trước người, sóng ý chí lan ra.
static func _willshield(s, t: float, lowq: bool) -> void:
	var up := eo(sg(t, 0.0, 0.22))
	var fa := fo(s, t, 0.85)
	var al := up * fa
	var c := Vector2(38.0, -4.0)
	glow(s, c, 56.0 * up, 0.3 * al)
	var h := 48.0 * up
	var w := h * 0.74
	var pts := PackedVector2Array([c + Vector2(-w, -h), c + Vector2(w, -h), c + Vector2(w, -h * 0.1), c + Vector2(w * 0.5, h * 0.62), c + Vector2(0, h), c + Vector2(-w * 0.5, h * 0.62), c + Vector2(-w, -h * 0.1)])
	P(s, pts, A(s, 0.4 * al))
	var cl := pts.duplicate()
	cl.append(pts[0])
	PL(s, cl, K(s, al), 3.0)
	# kiếm khắc dọc khiên
	sword(s, c + Vector2(0, h * 0.7), -PI * 0.5, h * 1.45, 9.0 * up, 0.9 * al)
	# sóng ý chí lan ra
	for i in range(3):
		var q := fmod(t * 1.6 + float(i) / 3.0, 1.0)
		ering(s, c, 20.0 + 50.0 * q, 30.0 + 60.0 * q, A(s, 0.55 * (1.0 - q) * al), 2.2)

## pa5 Thiên Kiếm Giáng — thanh kiếm trời khổng lồ giáng xuống cách 140px, sóng nổ r=180.
static func _heavensword(s, t: float, lowq: bool) -> void:
	var X := 140.0
	var q := sg(t, 0.12, 0.42)
	var fa := fadeo(t, 0.8)
	var y := lerpf(-340.0, GY - 6.0, ei(q))
	# báo trước: vòng sáng trên đất
	if t < 0.42:
		var w := sg(t, 0.0, 0.2)
		ering(s, Vector2(X, GY - 6.0), 180.0 * eo(w), 180.0 * eo(w) * 0.24, A(s, 0.5 * w * (1.0 - q)), 2.5)
	# cột sáng hẹp + kiếm to
	var al := 1.0 if t < 0.8 else fa
	beam(s, X, y - 240.0, y, 22.0, 8.0, al)
	glow(s, Vector2(X, y - 70.0), 60.0, 0.3 * al)
	sword(s, Vector2(X, y - 250.0), PI * 0.5, 250.0, 38.0, al)
	if q >= 1.0:
		var h := sg(t, 0.42, 1.0)
		var e := eo(h)
		shock(s, Vector2(X, GY - 4.0), 180.0 * e, 180.0 * e * 0.24, 1.0 - h)
		shock(s, Vector2(X, GY - 4.0), 110.0 * e, 110.0 * e * 0.24, (1.0 - h) * 0.8)
		crack(s, Vector2(X, GY - 4.0), 150.0 * e, 1.0 - h, 3)
		for i in range(10):
			var a := PI + PI * float(i) / 9.0
			var d := Vector2(cos(a), sin(a))
			cut(s, Vector2(X, GY - 8.0) + d * 20.0, Vector2(X, GY - 8.0) + d * (30.0 + 110.0 * e), 4.0 * (1.0 - h), 1.0 - h)
		spark(s, Vector2(X, GY - 10.0), 16, 90.0, h, 1.0 - h, 4)
		glow(s, Vector2(X, GY - 14.0), 60.0 * (1.0 - h), 0.6 * (1.0 - h))

## pa6 Kiếm Vũ Liên Hoàn — xoay kiếm chém 6 nhát liên tiếp, vòng kiếm khí lồng nhau.
static func _bladewhirl(s, t: float, lowq: bool) -> void:
	var cy := Vector2(0, -6)
	for k in range(5):
		var a0 := 0.04 + 0.14 * k
		var p := sg(t, a0, a0 + 0.2)
		var life := fadeo(t, a0 + 0.2)
		var rot := float(k) * 1.1
		var rr := 60.0 + 14.0 * k
		s.draw_set_transform(cy, rot, Vector2(1.0, 0.42))
		swoosh(s, Vector2.ZERO, rr, 0.0, TAU * 0.85, eo(p), 0.6, 20.0, life)
		rst(s)
	# thanh kiếm đang xoay quanh người
	var a := t * 22.0
	var sp := cy + Vector2(cos(a) * 34.0, sin(a) * 14.0)
	sword(s, sp, a + PI * 0.5 * (1.0 if sin(a) < 0.0 else -1.0), 52.0, 7.0, 0.9 * fadeo(t, 0.8))
	# nhát kết liễu: chữ thập lớn
	var e := sg(t, 0.68, 0.95)
	if e > 0.0:
		var fe := fadeo(t, 0.9)
		cut(s, Vector2(30.0, -80.0 * eo(e)), Vector2(150.0, 80.0 * eo(e)), 8.0, fe)
		cut(s, Vector2(30.0, 80.0 * eo(e)), Vector2(150.0, -80.0 * eo(e)), 8.0, fe)
		star(s, Vector2(90.0, 0), 40.0 * eo(e), fe, 10)

## pa7 Phá Quân Trảm — 3 nhát rồi nhát bổ chéo khổng lồ phá giáp, giáp vỡ văng.
static func _armybreak(s, t: float, lowq: bool) -> void:
	var c := Vector2(0, -4.0)
	for k in range(3):
		var p := sg(t, 0.04 + 0.14 * k, 0.15 + 0.14 * k)
		var life := fadeo(t, 0.16 + 0.14 * k + 0.08)
		var flip := 1.0 if k % 2 == 0 else -1.0
		swoosh(s, c, 100.0 + 10.0 * k, -0.9 * flip, 0.7 * flip, eo(p), 0.75, 24.0, life)
		swing(s, c, 100.0 + 10.0 * k, -0.9 * flip, 0.7 * flip, eo(p), life)
	var p4 := sg(t, 0.5, 0.64)
	var l4 := fadeo(t, 0.8)
	# nhát bổ chéo lớn từ trên-trái xuống dưới-phải
	swoosh(s, Vector2(-30.0, -20.0), 200.0, -1.5, 0.35, eo(p4), 0.9, 70.0, l4, 0.9)
	swing(s, Vector2(-30.0, -20.0), 200.0, -1.5, 0.35, eo(p4), l4, 0.9)
	if p4 >= 1.0:
		var h := sg(t, 0.64, 1.0)
		cut(s, Vector2(40.0, -120.0), Vector2(190.0, 50.0), 9.0 * (1.0 - h * 0.5), 1.0 - h)
		crack(s, Vector2(150.0, GY - 4.0), 120.0 * eo(h), 1.0 - h, 6)
		for i in range(0 if lowq else 8):
			var a := -PI * (0.1 + 0.8 * rnd(i, 1))
			var d := Vector2(cos(a), sin(a)) * (30.0 + 90.0 * rnd(i, 2)) * eo(h)
			var p := Vector2(150.0, 6.0) + d + Vector2(0, 40.0 * h * h)
			s.draw_set_transform(p, h * 8.0 * (rnd(i, 3) - 0.5), Vector2.ONE)
			P(s, PackedVector2Array([Vector2(-6, -4), Vector2(0, -7), Vector2(7, -3), Vector2(6, 4), Vector2(-1, 6)]), A(s, 0.85 * (1.0 - h)))
			rst(s)
		shock(s, Vector2(150.0, GY - 4.0), 20.0 + 90.0 * eo(h), 5.0 + 20.0 * eo(h), 1.0 - h)

## pa8 Đâm Xuyên — mũi kiếm đâm thẳng 240px xuyên mọi quái: kiếm khí gradient, xoáy xoắn quanh, vòng thủng, nón xung kích.
static func _lance(s, t: float, lowq: bool) -> void:
	var L0 := 240.0
	var q := eo(sg(t, 0.0, 0.28))
	var fa := fadeo(t, 0.5)
	var tipx := 30.0 + L0 * q
	speedlines(s, 0.0, tipx, -18.0, 22.0, 9, 0.8 * fa, 7)
	PG(s, PackedVector2Array([Vector2(10, 0), Vector2(tipx * 0.5, -12.0), Vector2(tipx, 0), Vector2(tipx * 0.5, 12.0)]), PackedColorArray([A(s, 0.0), A(s, 0.25 * fa), A(s, 0.9 * fa), A(s, 0.25 * fa)]))
	PG(s, PackedVector2Array([Vector2(10, 0), Vector2(tipx * 0.55, -5.0), Vector2(tipx, 0), Vector2(tipx * 0.55, 5.0)]), PackedColorArray([K(s, 0.0), K(s, 0.5 * fa), K(s, fa), K(s, 0.5 * fa)]))
	for k in range(2):
		var pts := PackedVector2Array()
		for i in range(40):
			var u := float(i) / 39.0
			var x := lerpf(10.0, tipx, u)
			pts.append(Vector2(x, sin(x * 0.12 - t * 30.0 + PI * float(k)) * 9.0 * u))
		PL(s, pts, A(s, 0.6 * fa), 1.8)
	sword(s, Vector2(tipx - 86.0, 0), 0.0, 96.0, 13.0, fa)
	for i in range(4):
		var x := L0 * (0.22 + 0.22 * float(i))
		var pr := sg(t, 0.08 + 0.07 * float(i), 0.55 + 0.07 * float(i))
		if pr > 0.0 and x < tipx:
			ering(s, Vector2(x, 0), 5.0 + 12.0 * pr, 14.0 + 34.0 * pr, A(s, 0.85 * (1.0 - pr)), 2.4)
			ering(s, Vector2(x, 0), 3.0 + 8.0 * pr, 9.0 + 22.0 * pr, K(s, 0.6 * (1.0 - pr)), 1.2)
	star(s, Vector2(tipx, 0), 26.0 * (1.0 - sg(t, 0.3, 0.8)), 1.0 - sg(t, 0.3, 0.8), 8)
	spark(s, Vector2(tipx, 0), 10, 50.0, sg(t, 0.28, 0.8), 1.0 - sg(t, 0.3, 0.8), 4)

## pa9 Kiếm Phản Kích — đỡ đòn bằng kiếm, tia lửa thép, chém trả.
static func _parry(s, t: float, lowq: bool) -> void:
	var up := eo(sg(t, 0.0, 0.15))
	var fa := fo(s, t, 0.85)
	var al := up * fa
	sword(s, Vector2(6.0, 4.0), -0.95, 62.0, 8.0, al)   # kiếm chắn chéo
	var hit := sg(t, 0.26, 0.46)
	if hit > 0.0:
		var q := sg(t, 0.28, 0.7)
		var pt := Vector2(34.0, -34.0)
		star(s, pt, 24.0 * (1.0 - q) + 4.0, 1.0 - q, 6)
		for i in range(10):
			var a := -PI * 0.5 + (rnd(i, 1) - 0.5) * 2.6
			var d := Vector2(cos(a), sin(a)) * (14.0 + 50.0 * rnd(i, 2)) * eo(q)
			L(s, pt + d, pt + d * 1.25, K(s, 1.0 - q), 1.6)
	# chém trả
	var p := sg(t, 0.5, 0.7)
	swoosh(s, Vector2(0, 2), 108.0, -1.1, 0.75, eo(p), 0.8, 36.0, fadeo(t, 0.75))
	swing(s, Vector2(0, 2), 108.0, -1.1, 0.75, eo(p), fadeo(t, 0.75))
	if p >= 1.0:
		spark(s, Vector2(100.0, 0), 8, 40.0, sg(t, 0.7, 1.0), fadeo(t, 0.75), 2)

## pa10 Cuồng Phong Trảm — xoay kiếm thành lốc xoáy chém quanh người (r=200).
static func _cyclone(s, t: float, lowq: bool) -> void:
	var R := 200.0
	var e := eo(sg(t, 0.0, 0.5))
	var fa := fadeo(t, 0.72)
	var cy := Vector2(0, -6)
	# phễu lốc
	for i in range(6):
		var u := float(i) / 5.0
		var rr := (30.0 + (R - 30.0) * u) * e
		ering(s, cy + Vector2(0, -80.0 * (1.0 - u) + 10.0), rr, rr * 0.2, A(s, (0.25 + 0.4 * u) * fa), 2.6, 0.0)
	for i in range(0 if lowq else 14):
		var a := TAU * float(i) / 14.0 + t * 9.0
		var u := fmod(float(i) * 0.31 + t * 1.2, 1.0)
		var rr := (20.0 + (R - 40.0) * u) * e
		var p := cy + Vector2(cos(a) * rr, sin(a) * rr * 0.2 - 70.0 * (1.0 - u))
		CI(s, p, 2.0 + 1.6 * rnd(i, 1), K(s, 0.8 * fa))
	# hai vòng chém lớn
	for k in range(2):
		var rot := t * (26.0 if k == 0 else -20.0)
		s.draw_set_transform(Vector2(0, GY - 14.0), 0.0, Vector2(1.0, 0.28))
		swoosh(s, Vector2.ZERO, R * e * (1.0 - 0.28 * k), rot, rot + TAU * 0.9, 1.0, 0.6, 30.0, fa * 0.95)
		rst(s)
	# kiếm xoay ở giữa
	var a2 := t * 28.0
	for sd in [0.0, PI]:
		var d := Vector2(cos(a2 + sd), sin(a2 + sd) * 0.3)
		sword(s, cy + d * 14.0, atan2(d.y, d.x), 56.0, 8.0, fa)

## pa11 Kiếm Khí Tung Hoành — hai luồng kiếm khí đứng và nằm giao nhau thành chữ thập, kèm các luồng chéo và tàn ảnh; nổ sao ở cuối tầm.
static func _crossqi(s, t: float, lowq: bool) -> void:
	var q := eo(sg(t, 0.0, 0.7))
	var fa := fadeo(t, 0.72)
	var x := 40.0 + 440.0 * q
	for j in range(4, 0, -1):
		var xj := x - 34.0 * float(j)
		if xj < 20.0: continue
		var fj := fa * (0.5 / float(j))
		swoosh(s, Vector2(xj - 60.0, 0), 70.0, -0.95, 0.95, 1.0, 1.0, 22.0, fj, 1.0)
		s.draw_set_transform(Vector2(xj - 36.0, 0), PI * 0.5, Vector2.ONE)
		swoosh(s, Vector2.ZERO, 56.0, -0.9, 0.9, 1.0, 1.0, 18.0, fj * 0.8, 0.8)
		rst(s)
	swoosh(s, Vector2(x - 60.0, 0), 70.0, -0.95, 0.95, 1.0, 1.0, 30.0, fa, 1.0)
	s.draw_set_transform(Vector2(x - 36.0, 0), PI * 0.5, Vector2.ONE)
	swoosh(s, Vector2.ZERO, 56.0, -0.9, 0.9, 1.0, 1.0, 24.0, fa * 0.95, 0.8)
	rst(s)
	cut(s, Vector2(x - 120.0, -58.0), Vector2(x + 18.0, 32.0), 6.0, fa)
	cut(s, Vector2(x - 120.0, 58.0), Vector2(x + 18.0, -32.0), 6.0, fa)
	flare(s, Vector2(x - 18.0, 0), 16.0, fa)
	for i in range(0 if lowq else 8):
		var ph := fmod(t * 2.0 + rnd(i, 1), 1.0)
		CI(s, Vector2(x - 20.0 - 90.0 * ph, (rnd(i, 2) - 0.5) * 70.0), 1.8, K(s, fa * (1.0 - ph)))
	if q >= 1.0:
		var h := sg(t, 0.7, 1.0)
		star(s, Vector2(x, 0), 32.0 * (1.0 - h), 1.0 - h, 8)
		spark(s, Vector2(x, 0), 12, 70.0, h, 1.0 - h, 5)

## ulKiem1 Kiếm Trận Hủy Diệt — trận kiếm trên đất, hai thanh kiếm khổng lồ giáng liên tiếp (140px, 270px).
static func _swordarray(s, t: float, lowq: bool) -> void:
	var cx := 205.0
	var arr := eo(sg(t, 0.0, 0.25))
	var fa := fadeo(t, 0.85)
	var gc := Vector2(cx, GY - 4.0)
	# trận kiếm: vòng + ngôi sao
	ering(s, gc, 160.0 * arr, 38.0 * arr, A(s, 0.8 * fa), 3.0)
	ering(s, gc, 118.0 * arr, 28.0 * arr, K(s, 0.6 * fa), 1.6)
	for i in range(8):
		var a := TAU * float(i) / 8.0 + 0.2
		var b := TAU * float((i + 3) % 8) / 8.0 + 0.2
		L(s, gc + Vector2(cos(a) * 140.0, sin(a) * 33.0) * arr, gc + Vector2(cos(b) * 140.0, sin(b) * 33.0) * arr, A(s, 0.45 * fa), 1.6)
	# kiếm cắm quanh trận
	var n := 10
	for i in range(n):
		var a := TAU * float(i) / float(n)
		var p := gc + Vector2(cos(a) * 150.0, sin(a) * 36.0) * arr
		var grow := eo(sg(t, 0.05 + 0.02 * float(i), 0.3))
		sword(s, p, -PI * 0.5, 40.0 * grow, 6.0, fa)
	# hai thanh kiếm khổng lồ rơi lần lượt
	for k in range(2):
		var X := 140.0 + 130.0 * float(k)
		var t0 := 0.34 + 0.2 * float(k)
		var q := sg(t, t0, t0 + 0.14)
		if q <= 0.0: continue
		var y := lerpf(-300.0, GY - 6.0, ei(q))
		var al := fa
		beam(s, X, y - 220.0, y, 18.0, 7.0, al)
		sword(s, Vector2(X, y - 220.0), PI * 0.5, 220.0, 32.0, al * (1.0 if q < 1.0 else fadeo(t, t0 + 0.5)))
		if q >= 1.0:
			var h := sg(t, t0 + 0.14, t0 + 0.6)
			var e := eo(h)
			shock(s, Vector2(X, GY - 4.0), 170.0 * e, 170.0 * e * 0.24, 1.0 - h)
			crack(s, Vector2(X, GY - 4.0), 130.0 * e, 1.0 - h, 2 + k)
			spark(s, Vector2(X, GY - 10.0), 14, 80.0, h, 1.0 - h, 5 + k)
			glow(s, Vector2(X, GY - 12.0), 50.0 * (1.0 - h), 0.5 * (1.0 - h))

## ulKiem2 Kiếm Vũ Tuyệt Diệt — hoa kiếm nở dưới trăng máu: trăng có quầng/mây máu, 9 nhát dồn dập, hoa sen 3 tầng cánh kiếm rồi bùng nổ.
static func _swordlotus(s, t: float, lowq: bool) -> void:
	var fa := fadeo(t, 0.82)
	var cy := Vector2(50.0, -10.0)
	var moon := eo(sg(t, 0.0, 0.3))
	var mc := Vector2(50.0, -130.0)
	for i in range(8):
		var u := float(i) / 7.0
		CI(s, mc, (96.0 - 60.0 * u) * moon, Color(0.9, 0.1, 0.12, (0.04 + 0.06 * u) * fa))
	CI(s, mc, 46.0 * moon, Color(0.82, 0.1, 0.1, 0.55 * fa))
	CI(s, mc, 40.0 * moon, Color(0.96, 0.22, 0.18, 0.7 * fa))
	CI(s, mc + Vector2(-9.0, -8.0) * moon, 30.0 * moon, Color(1.0, 0.42, 0.34, 0.35 * fa))
	for i in range(5):
		var cp := mc + Vector2((rnd(i, 1) - 0.5) * 50.0, (rnd(i, 2) - 0.5) * 50.0) * moon
		CI(s, cp, (4.0 + 5.0 * rnd(i, 3)) * moon, Color(0.5, 0.05, 0.08, 0.35 * fa))
	for i in range(3):
		var cx := mc.x - 60.0 + fmod(t * 40.0 + 55.0 * float(i), 130.0)
		CI(s, Vector2(cx, mc.y + 10.0 + 14.0 * float(i)), 18.0, Color(0.35, 0.04, 0.08, 0.3 * fa))
	for k in range(9):
		var a0 := 0.05 + 0.065 * float(k)
		var p := sg(t, a0, a0 + 0.09)
		var life := fadeo(t, a0 + 0.1)
		var ang := PI * 0.39 * float(k)
		var d := Vector2(cos(ang), sin(ang) * 0.75)
		cut(s, cy + d * 78.0 * eo(p), cy - d * 78.0 * eo(p), 4.5, life * 0.9)
	var open := eo(sg(t, 0.34, 0.75))
	for layer in range(3):
		var cnt := 5 + 2 * layer
		for i in range(cnt):
			var u := float(i) / float(cnt - 1)
			var a := lerpf(-PI * 0.97, -PI * 0.03, u) + 0.06 * sin(t * 6.0 + float(i))
			var rr := 16.0 + 16.0 * float(layer)
			var ln := (46.0 + 20.0 * float(layer)) * open
			var d := Vector2(cos(a), sin(a) * 0.9)
			var depth := 1.0 - 0.18 * float(layer)
			sword(s, cy + d * rr, atan2(d.y, d.x), ln, 7.0 + 1.5 * float(layer), fa * depth)
	glow(s, cy, 34.0 * open, 0.6 * fa)
	CI(s, cy, 8.0 * open, K(s, fa))
	for i in range(0 if lowq else 12):
		var ph := fmod(t * 1.2 + rnd(i, 4), 1.0)
		var px := cy.x + (rnd(i, 5) - 0.5) * 160.0
		var py := cy.y - 50.0 + 80.0 * ph
		P(s, PackedVector2Array([Vector2(px, py), Vector2(px + 3.0, py + 6.0), Vector2(px - 3.0, py + 6.0)]), Color(0.95, 0.3, 0.3, 0.6 * fa * open))
	var e := sg(t, 0.78, 1.0)
	if e > 0.0:
		shock(s, Vector2(50.0, GY - 6.0), 200.0 * eo(e), 200.0 * eo(e) * 0.24, 1.0 - e)
		star(s, cy, 76.0 * (1.0 - e * 0.4), 1.0 - e, 12)
		spark(s, cy, 22, 170.0, e, 1.0 - e, 3)
		dust(s, Vector2(50.0, GY - 6.0), 150.0 * eo(e), e, 1.0 - e, 12, 5)

# ============================================================ HIỆU ỨNG TRÚNG ĐÒN TRÊN TỪNG QUÁI (gốc toạ độ = giữa thân quái, +x = hướng đòn)
const HIT_STYLES := ["slash", "pierce", "fire", "ice", "bolt", "holy", "dark", "blood", "soul", "rock", "water", "arcane"]

static func draw_hit(s, st: String, t: float, lowq: bool) -> void:
	var fa := 1.0 - sg(t, 0.55, 1.0)
	var e := eo(sg(t, 0.0, 0.5))
	match st:
		"slash":
			# hai nhát chém chéo cắt nhau + sao nổ + tia lửa thép
			cut(s, Vector2(-30.0, -34.0) * e, Vector2(30.0, 34.0) * e, 5.0, fa)
			cut(s, Vector2(-34.0, 26.0) * e, Vector2(34.0, -26.0) * e, 4.0, fa * 0.9)
			star(s, Vector2.ZERO, 16.0 * (1.0 - t * 0.5), fa, 6)
			spark(s, Vector2.ZERO, 8, 46.0, t, fa, 1)
		"pierce":
			# mũi tên/đâm cắm vào + vòng bụi + chớp
			var d := Vector2(1.0, 0.0)
			L(s, Vector2(-34.0 + 16.0 * e, -2.0), Vector2(8.0, 0.0), K(s, fa), 2.6)
			P(s, PackedVector2Array([Vector2(8, 0), Vector2(0, -4.0), Vector2(0, 4.0)]), K(s, fa))
			L(s, Vector2(-34.0 + 16.0 * e, -2.0), Vector2(-42.0 + 16.0 * e, -7.0), A(s, fa), 2.0)
			L(s, Vector2(-34.0 + 16.0 * e, -2.0), Vector2(-42.0 + 16.0 * e, 3.0), A(s, fa), 2.0)
			ering(s, Vector2(4.0, 0), 6.0 + 22.0 * e, 4.0 + 22.0 * e, A(s, fa * 0.9), 2.4)
			star(s, Vector2(4.0, 0), 11.0 * (1.0 - t * 0.6), fa, 6)
			spark(s, Vector2(4.0, 0), 6, 32.0, t, fa, 2)
		"fire":
			glow(s, Vector2.ZERO, 34.0 * (0.6 + e), 0.55 * fa)
			for i in range(5):
				flame(s, Vector2((float(i) - 2.0) * 9.0, 14.0), (26.0 + 22.0 * rnd(i, 1)) * e, 7.0, t * 1.5, float(i), fa)
			ering(s, Vector2.ZERO, 8.0 + 34.0 * e, 6.0 + 18.0 * e, A(s, fa * 0.8), 2.6)
			for i in range(0 if lowq else 8):
				var a := -PI * (0.15 + 0.7 * rnd(i, 3))
				var p := Vector2(cos(a), sin(a)) * (14.0 + 46.0 * rnd(i, 4)) * e + Vector2(0, 30.0 * t * t)
				CI(s, p, 2.2 * (1.0 - t) + 0.6, K(s, fa))
		"ice":
			glow(s, Vector2.ZERO, 30.0, 0.4 * fa)
			for i in range(6):
				var a := TAU * float(i) / 6.0 + 0.3
				var dd := Vector2(cos(a), sin(a))
				var nr := dd.orthogonal()
				var ln := (16.0 + 22.0 * rnd(i, 2)) * e
				P(s, PackedVector2Array([dd * 4.0 + nr * 3.5, dd * ln, dd * 4.0 - nr * 3.5, dd * (ln * 0.2)]), K(s, fa * 0.9))
				L(s, dd * 4.0, dd * ln, A(s, fa), 1.4)
			ering(s, Vector2.ZERO, 8.0 + 30.0 * e, 6.0 + 20.0 * e, A(s, fa * 0.8), 2.4)
			star(s, Vector2.ZERO, 12.0 * (1.0 - t * 0.5), fa * 0.8, 6)
		"bolt":
			glow(s, Vector2.ZERO, 30.0, 0.5 * fa)
			for i in range(4):
				var a := TAU * float(i) / 4.0 + 0.5 + 0.3 * rnd(int(t * 12.0), i)
				var pts := PackedVector2Array([Vector2.ZERO])
				var p := Vector2.ZERO
				for k in range(1, 5):
					p += Vector2(cos(a), sin(a)) * 11.0 * e + Vector2((rnd(i * 7 + k, int(t * 14.0)) - 0.5) * 12.0, (rnd(i * 5 + k, int(t * 14.0) + 3) - 0.5) * 12.0)
					pts.append(p)
				PL(s, pts, A(s, fa * 0.5), 5.0)
				PL(s, pts, K(s, fa), 1.8)
			flare(s, Vector2.ZERO, 14.0, fa)
		"holy":
			glow(s, Vector2.ZERO, 36.0, 0.5 * fa)
			star(s, Vector2.ZERO, 20.0 * (0.6 + e), fa, 8)
			for i in range(8):
				var a := TAU * float(i) / 8.0
				L(s, Vector2(cos(a), sin(a)) * 10.0, Vector2(cos(a), sin(a)) * (18.0 + 26.0 * e), K(s, fa * 0.8), 1.6)
			for i in range(0 if lowq else 6):
				var p := Vector2((rnd(i, 1) - 0.5) * 40.0, 10.0 - 50.0 * t * (0.5 + rnd(i, 2)))
				CI(s, p, 2.0, K(s, fa))
		"dark":
			# nhát chém bóng + khói tối
			cut(s, Vector2(-34.0, -30.0) * e, Vector2(34.0, 30.0) * e, 5.0, fa)
			cut(s, Vector2(-30.0, 30.0) * e, Vector2(30.0, -34.0) * e, 4.0, fa * 0.8)
			for i in range(6):
				var a := TAU * float(i) / 6.0 + t * 2.0
				CI(s, Vector2(cos(a), sin(a)) * (10.0 + 22.0 * e), 6.0 * (1.0 - t * 0.5), A(s, fa * 0.45))
			spark(s, Vector2.ZERO, 6, 36.0, t, fa, 3)
		"blood":
			cut(s, Vector2(-32.0, -30.0) * e, Vector2(32.0, 30.0) * e, 5.0, fa)
			for i in range(0 if lowq else 10):
				var a := -PI * (0.05 + 0.9 * rnd(i, 1))
				var p := Vector2(cos(a), sin(a)) * (12.0 + 50.0 * rnd(i, 2)) * e + Vector2(0, 46.0 * t * t)
				CI(s, p, 2.6 * (1.0 - t * 0.5), A(s, fa))
				CI(s, p, 1.2, K(s, fa))
			star(s, Vector2.ZERO, 10.0, fa * 0.6, 6)
		"soul":
			glow(s, Vector2.ZERO, 28.0, 0.35 * fa)
			for i in range(4):
				var u := fmod(t * 1.3 + 0.25 * float(i), 1.0)
				var p := Vector2(sin(u * 8.0 + float(i)) * 12.0, 8.0 - 54.0 * u)
				CI(s, p, 5.0 * (1.0 - u * 0.5), A(s, fa * (1.0 - u)))
				CI(s, p, 2.4, K(s, fa * (1.0 - u)))
				for q in range(1, 4):
					CI(s, p + Vector2(0, 5.0 * float(q)), 3.0 - float(q) * 0.7, A(s, fa * 0.4 * (1.0 - u)))
			ering(s, Vector2.ZERO, 8.0 + 28.0 * e, 5.0 + 16.0 * e, A(s, fa * 0.7), 2.2)
		"rock":
			for i in range(7):
				var a := -PI * (0.1 + 0.8 * rnd(i, 1))
				var p := Vector2(cos(a), sin(a)) * (14.0 + 44.0 * rnd(i, 2)) * e + Vector2(0, 40.0 * t * t)
				s.draw_set_transform(p, t * 6.0 * (rnd(i, 3) - 0.5), Vector2.ONE)
				P(s, PackedVector2Array([Vector2(-5, -3), Vector2(-1, -6), Vector2(5, -2), Vector2(4, 4), Vector2(-3, 5)]), A(s, fa * 0.9))
				rst(s)
			dust(s, Vector2(0, 14.0), 24.0, t, fa, 6, 2)
			ering(s, Vector2(0, 14.0), 8.0 + 34.0 * e, 3.0 + 10.0 * e, A(s, fa * 0.8), 2.4)
		"water":
			for i in range(8):
				var a := -PI * (0.15 + 0.7 * float(i) / 7.0)
				var pts := PackedVector2Array()
				for k in range(8):
					var u := float(k) / 7.0 * e
					pts.append(Vector2(cos(a), sin(a)) * 36.0 * u + Vector2(0, 30.0 * u * u))
				PL(s, pts, A(s, fa * 0.7), 2.2)
				CI(s, pts[pts.size() - 1], 2.2, K(s, fa))
			ering(s, Vector2(0, 14.0), 8.0 + 32.0 * e, 3.0 + 9.0 * e, A(s, fa * 0.8), 2.2)
		"arcane":
			ering(s, Vector2.ZERO, 12.0 + 22.0 * e, 12.0 + 22.0 * e, A(s, fa * 0.9), 2.2)
			ering(s, Vector2.ZERO, 6.0 + 12.0 * e, 6.0 + 12.0 * e, K(s, fa * 0.8), 1.4, t * 4.0)
			for i in range(6):
				var a := TAU * float(i) / 6.0 + t * 3.0
				L(s, Vector2(cos(a), sin(a)) * (14.0 + 22.0 * e), Vector2(cos(a), sin(a)) * (22.0 + 22.0 * e), K(s, fa), 1.6)
			star(s, Vector2.ZERO, 14.0, fa * 0.9, 6)
		_:
			star(s, Vector2.ZERO, 14.0, fa, 6)

# ============================================================ BUFF KÉO DÀI: hào quang ổn định suốt thời gian hiệu lực
## t = giây đã trôi từ lúc dựng hào quang (s.steady = true để các hàm vẽ giữ trạng thái đầy đủ, không mờ dần).
static func has_aura(sg: String) -> bool:
	return sg in ["ke_mindcounter", "ke_orbitswords", "ke_trueawaken", "ke_rage", "ke_willshield", "ke_parry"] or sg.begins_with("au_")

static func draw_aura(s, sg: String, t: float, lowq: bool) -> void:
	var tt := 1.0 + t
	match sg:
		"ke_mindcounter": _mindcounter(s, tt, lowq)
		"ke_orbitswords": _orbitswords(s, tt, lowq)
		"ke_trueawaken": _trueawaken(s, tt, lowq)
		"ke_rage": _rage(s, tt, lowq)
		"ke_willshield": _willshield(s, tt, lowq)
		"ke_parry": _parry(s, tt, lowq)
		"au_buff": _au_buff(s, t, lowq)
		"au_guard": _au_guard(s, t, lowq, false)
		"au_shield": _au_guard(s, t, lowq, true)

## Hào quang chung cho buff chưa có hình riêng: vòng đất + hạt bay lên theo màu kỹ năng.
static func _au_buff(s, t: float, lowq: bool) -> void:
	ering(s, Vector2(0, GY - 4.0), 40.0, 10.0, A(s, 0.3), 6.0)
	ering(s, Vector2(0, GY - 4.0), 40.0, 10.0, A(s, 0.8), 2.0)
	glow(s, Vector2(0, -6), 34.0, 0.12)
	for i in range(0 if lowq else 10):
		var ph := fmod(t * 0.7 + rnd(i, 1), 1.0)
		var a := TAU * rnd(i, 2) + t * 1.5
		var p := Vector2(cos(a) * 34.0, GY - 6.0 - 84.0 * ph + sin(a) * 8.0)
		CI(s, p, 2.0 * (1.0 - ph) + 0.6, K(s, 0.9 * (1.0 - ph)))
		CI(s, p, 4.0 * (1.0 - ph), A(s, 0.25 * (1.0 - ph)))

## Quầng bảo hộ: vòng bao quanh người (khiên: gợn sóng định kỳ).
static func _au_guard(s, t: float, lowq: bool, shield: bool) -> void:
	var cy := Vector2(0, -6)
	ering(s, Vector2(0, GY - 4.0), 42.0, 10.0, A(s, 0.7), 2.0)
	AR(s, cy, 46.0, 0.0, TAU, 48, A(s, 0.35), 2.0)
	AR(s, cy, 46.0, -2.4, -0.7, 20, K(s, 0.8), 2.2)
	glow(s, cy, 48.0, 0.1)
	for i in range(3):
		var q := fmod(t * 0.5 + float(i) / 3.0, 1.0)
		AR(s, cy, 46.0 + 10.0 * q, 0.0, TAU, 40, A(s, 0.35 * (1.0 - q)), 1.6)
	if shield:
		for i in range(6):
			var a := TAU * float(i) / 6.0 + t * 0.6
			CI(s, cy + Vector2(cos(a), sin(a)) * 46.0, 2.4, K(s, 0.85))

## Loé nòng khi bắn: chớp sáng + vòng nhỏ + tia lửa ở tay (đạn bay mang hình riêng của kỹ năng).
static func _muzzle(s, t: float) -> void:
	var e := eo(sg(t, 0.0, 0.5))
	var fa := 1.0 - sg(t, 0.4, 1.0)
	var c := Vector2(24.0, -2.0)
	glow(s, c, 22.0 * (0.6 + e), 0.6 * fa)
	flare(s, c, 12.0 * (1.0 - t * 0.4), fa)
	ering(s, c, 6.0 + 16.0 * e, 10.0 + 22.0 * e, A(s, 0.8 * fa), 2.0)
	spark(s, c, 6, 30.0, t, fa, 7)

## Cánh cung: gốc = tay cầm, +x = hướng bắn (xoay theo ang), size = nửa chiều dài, pull = độ kéo dây, wob = độ rung dây, nock = có mũi tên lắp trên dây.
static func bow(s, pos: Vector2, ang: float, size: float, pull: float, wob: float, al: float, nock: bool) -> void:
	if al <= 0.01: return
	s.draw_set_transform(pos, ang, Vector2.ONE)
	var limb := PackedVector2Array()
	for i in range(17):
		var u := float(i) / 8.0 - 1.0
		limb.append(Vector2((1.0 - u * u) * size * 0.34, u * size))
	PL(s, limb, A(s, al * 0.3), 7.0)
	PL(s, limb, M(s, 0.55, al), 3.4)
	PL(s, limb, K(s, al * 0.8), 1.2)
	CI(s, Vector2(size * 0.34, 0), 2.4, K(s, al))
	var top := limb[0]
	var bot := limb[limb.size() - 1]
	var mid := Vector2(-pull + wob, 0)
	PL(s, PackedVector2Array([top, mid, bot]), K(s, al * 0.9), 1.1)
	if nock:
		L(s, mid, Vector2(size * 0.9, 0), M(s, 0.6, al), 2.0)
		P(s, PackedVector2Array([Vector2(size * 1.15, 0), Vector2(size * 0.85, -3.0), Vector2(size * 0.85, 3.0)]), K(s, al))
		L(s, mid, mid + Vector2(-6.0, -4.0), A(s, al), 1.4)
		L(s, mid, mid + Vector2(-6.0, 4.0), A(s, al), 1.4)
	rst(s)

## Long Ảnh Liên Trảm khi con rồng do sprite (FxCreature) đảm nhận: chỉ còn vệt lướt, luồng khí và nhát chém chéo ở điểm đến.
static func _dragonslash_cuts(s, t: float, lowq: bool) -> void:
	var D := 220.0
	var p := eo(sg(t, 0.0, 0.5))
	var life := fadeo(t, 0.7)
	# dải khí rồng kéo dài phía sau
	PG(s, PackedVector2Array([Vector2(-10, -16), Vector2(D * p, -6), Vector2(D * p, 6), Vector2(-10, 16)]), PackedColorArray([A(s, 0.0), A(s, 0.35 * life), A(s, 0.35 * life), A(s, 0.0)]))
	speedlines(s, -10.0, D * p + 30.0, -28.0, 22.0, 9, life * 0.8, 4)
	var c := sg(t, 0.38, 0.62)
	if c > 0.0:
		var cl := fadeo(t, 0.65)
		cut(s, Vector2(D + 40.0, -86.0 * eo(c)), Vector2(D - 50.0 * eo(c) - 20.0, 86.0 * eo(c)), 8.0, cl)
		cut(s, Vector2(D + 40.0, 74.0 * eo(c)), Vector2(D - 60.0 * eo(c) - 10.0, -74.0 * eo(c)), 6.0, cl * 0.85)
		flare(s, Vector2(D, 0), 20.0, cl)
		spark(s, Vector2(D, 0), 14, 70.0, c, cl, 5)
