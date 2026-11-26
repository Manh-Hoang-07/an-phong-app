extends RefCounted
## Hiệu ứng kỹ năng VẼ LẠI RIÊNG (nhóm j) — tri_lieu_su. File này do một người/tiến trình riêng phụ trách.
## Quy ước như FxExt_e/f/g: place "bodyf", gốc = thân nhân vật, +x = hướng nhìn, y âm = lên, mặt đất y~+32. Bộ nét vẽ dùng chung: E (FxExt_e).
## Màu: vàng thánh = màu kỹ năng (E.A/E.K); hồi máu = xanh lục (g); hồi năng lượng = xanh dương (m).
const E := preload("res://src/world/fx/FxExt_e.gd")

const IDS := {
	"tl1": "tj_heal", "tl8": "tj_drop", "tl6": "tj_aura2", "tl25": "tj_sanctum", "tl11": "tj_lightrain",
	"tg38": "tj_decree", "tg45": "tj_phoenix", "ulTri1": "tj_phoenix2",
	"tg42": "tj_judge", "tl40": "tj_sunrise", "tl5": "tj_allheal", "tl7": "tj_lifedome",
	"tg32": "tj_bless", "tl3": "tj_dove", "tl10": "tj_purify",
	"tg37": "tj_angel", "tl35": "tj_hexdome", "tl4": "tj_lightshield",
}
const CFG := {
	"tj_heal": {"place": "bodyf", "dur": 1.1, "nopop": true, "nobig": true},
	"tj_drop": {"place": "bodyf", "dur": 1.0, "nopop": true, "nobig": true},
	"tj_aura2": {"place": "bodyf", "dur": 1.3, "nopop": true, "nobig": true},
	"tj_sanctum": {"place": "bodyf", "dur": 1.5, "nopop": true, "nobig": true},
	"tj_lightrain": {"place": "bodyf", "dur": 1.7, "nopop": true, "nobig": true},
	"tj_decree": {"place": "bodyf", "dur": 1.6, "nopop": true, "nobig": true},
	"tj_phoenix": {"place": "bodyf", "dur": 1.9, "nopop": true, "nobig": true},
	"tj_phoenix2": {"place": "bodyf", "dur": 2.2, "nopop": true, "nobig": true},
	"tj_judge": {"place": "bodyf", "dur": 1.3, "nopop": true, "nobig": true, "rumble": 5.0},
	"tj_sunrise": {"place": "bodyf", "dur": 1.7, "nopop": true, "nobig": true, "rumble": 3.0},
	"tj_allheal": {"place": "bodyf", "dur": 1.9, "nopop": true, "nobig": true, "rumble": 5.0},
	"tj_lifedome": {"place": "bodyf", "dur": 1.6, "nopop": true, "nobig": true},
	"tj_bless": {"place": "bodyf", "dur": 1.3, "nopop": true, "nobig": true},
	"tj_dove": {"place": "bodyf", "dur": 1.3, "nopop": true, "nobig": true},
	"tj_purify": {"place": "bodyf", "dur": 1.3, "nopop": true, "nobig": true},
	"tj_angel": {"place": "bodyf", "dur": 1.2, "nopop": true, "nobig": true},
	"tj_hexdome": {"place": "bodyf", "dur": 1.2, "nopop": true, "nobig": true},
	"tj_lightshield": {"place": "bodyf", "dur": 1.1, "nopop": true, "nobig": true},
}
## Sig hỗ trợ hào quang buff kéo dài (s.steady): liệt kê tên sig ở đây và xử lý trong draw_aura.
const AURA_IDS := ["tj_bless", "tj_dove", "tj_purify", "tj_angel", "tj_hexdome", "tj_lightshield"]

static func draw(s, sg: String, t: float, lowq: bool) -> void:
	match sg:
		"tj_heal": _heal(s, t, lowq)
		"tj_drop": _drop(s, t, lowq)
		"tj_aura2": _aura2(s, t, lowq)
		"tj_sanctum": _sanctum(s, t, lowq)
		"tj_lightrain": _lightrain(s, t, lowq)
		"tj_decree": _decree(s, t, lowq)
		"tj_phoenix": _phoenix(s, t, lowq)
		"tj_phoenix2": _phoenix2(s, t, lowq)
		"tj_judge": _judge(s, t, lowq)
		"tj_sunrise": _sunrise(s, t, lowq)
		"tj_allheal": _allheal(s, t, lowq)
		"tj_lifedome": _lifedome(s, t, lowq)
		"tj_bless": _bless(s, t, lowq)
		"tj_dove": _dove(s, t, lowq)
		"tj_purify": _purify(s, t, lowq)
		"tj_angel": _angel(s, t, lowq)
		"tj_hexdome": _hexdome(s, t, lowq)
		"tj_lightshield": _lightshield(s, t, lowq)

static func draw_aura(s, sg: String, t: float, lowq: bool) -> void:
	match sg:
		"tj_bless": _bless_a(s, t, lowq)
		"tj_dove": _dove_a(s, t, lowq)
		"tj_purify": _purify_a(s, t, lowq)
		"tj_angel": _angel_a(s, t, lowq)
		"tj_hexdome": _hexdome_a(s, t, lowq)
		"tj_lightshield": _lightshield_a(s, t, lowq)

# ============================================================ tiện ích
const GY := 32.0
const GC := Vector2(0, -6)   # tâm thân

static func g(al: float, u: float = 0.0) -> Color:   # xanh lục (máu)
	return Color(0.4 + 0.5 * u, 1.0, 0.5 + 0.4 * u, clampf(al, 0.0, 1.0))
static func m(al: float, u: float = 0.0) -> Color:   # xanh dương (mana)
	return Color(0.35 + 0.55 * u, 0.7 + 0.28 * u, 1.0, clampf(al, 0.0, 1.0))
static func wh(al: float) -> Color:
	return Color(1.0, 1.0, 0.94, clampf(al, 0.0, 1.0))
static func wm(al: float, u: float = 0.0) -> Color:   # cam vàng phượng hoàng
	return Color(1.0, 0.62 + 0.34 * u, 0.2 + 0.5 * u, clampf(al, 0.0, 1.0))

## Quầng sáng mềm theo màu chỉ định.
static func hg(s, c: Vector2, r: float, col: Color, al: float) -> void:
	if r < 2.0 or al <= 0.01: return
	for i in range(8):
		var u := float(i) / 7.0
		E.CI(s, c, r * (1.0 - u * 0.85), Color(col.r, col.g, col.b, clampf(al * (0.03 + 0.2 * u * u), 0.0, 1.0)))

## Dấu cộng bo (thập tự hồi phục): viền màu + lõi trắng.
static func plus(s, p: Vector2, r: float, col: Color, al: float) -> void:
	if al <= 0.02 or r < 3.0: return
	hg(s, p, r * 1.7, col, al * 0.7)
	for q in range(3):
		var k := 1.0 + 0.3 * float(2 - q)
		var w := r * 0.3 * k
		var rr := r * k
		var c2 := Color(col.r, col.g, col.b, al * (0.25 if q == 0 else (0.6 if q == 1 else 0.95)))
		if q == 2: c2 = Color(col.r, col.g, col.b, al)
		E.P(s, PackedVector2Array([p + Vector2(-w, -rr), p + Vector2(w, -rr), p + Vector2(w, -w), p + Vector2(rr, -w), p + Vector2(rr, w), p + Vector2(w, w), p + Vector2(w, rr), p + Vector2(-w, rr), p + Vector2(-w, w), p + Vector2(-rr, w), p + Vector2(-rr, -w), p + Vector2(-w, -w)]), c2)
	var w2 := r * 0.15
	var r2 := r * 0.62
	E.P(s, PackedVector2Array([p + Vector2(-w2, -r2), p + Vector2(w2, -r2), p + Vector2(w2, -w2), p + Vector2(r2, -w2), p + Vector2(r2, w2), p + Vector2(w2, w2), p + Vector2(w2, r2), p + Vector2(-w2, r2), p + Vector2(-w2, w2), p + Vector2(-r2, w2), p + Vector2(-r2, -w2), p + Vector2(-w2, -w2)]), wh(al * 0.95))

## Chiếc lá: hình thoi cong có gân giữa.
static func leaf(s, p: Vector2, ang: float, sz: float, al: float, col: Color) -> void:
	if al <= 0.02 or sz < 3.0: return
	var d := Vector2(cos(ang), sin(ang))
	var n := d.orthogonal()
	var top := PackedVector2Array()
	var bot := PackedVector2Array()
	for k in range(7):
		var u := float(k) / 6.0
		var w := sin(u * PI) * sz * 0.34
		top.append(p + d * sz * u + n * w)
		bot.append(p + d * sz * u - n * w)
	var pts := PackedVector2Array()
	for k in range(7): pts.append(top[k])
	for k in range(5, 0, -1): pts.append(bot[k])
	E.P(s, pts, Color(col.r, col.g, col.b, al * 0.9))
	var half := PackedVector2Array()
	for k in range(7): half.append(top[k].lerp(p + d * sz * float(k) / 6.0, 0.5))
	E.PL(s, half, wh(al * 0.5), 1.0)
	E.L(s, p, p + d * sz * 0.92, wh(al * 0.8), 1.2)

## Lông vũ: thoi thon, lõi sáng.
static func feather(s, p: Vector2, ang: float, ln: float, w: float, al: float, c1: Color, c2: Color) -> void:
	if al <= 0.02 or ln < 6.0: return
	var d := Vector2(cos(ang), sin(ang))
	var n := d.orthogonal()
	var pts := PackedVector2Array()
	var pin := PackedVector2Array()
	for k in range(6):
		var u := float(k) / 5.0
		var ww := w * sin(pow(u, 0.7) * PI) * (1.0 - 0.15 * u)
		pts.append(p + d * ln * u + n * ww)
		pin.append(p + d * ln * u + n * ww * 0.5)
	for k in range(5, -1, -1):
		var u := float(k) / 5.0
		var ww := w * sin(pow(u, 0.7) * PI) * (1.0 - 0.15 * u)
		pts.append(p + d * ln * u - n * ww)
		pin.append(p + d * ln * u - n * ww * 0.5)
	E.P(s, pts, Color(c1.r, c1.g, c1.b, al * 0.5))
	E.P(s, pin, Color(c2.r, c2.g, c2.b, al * 0.4))
	var oc := pts.duplicate()
	oc.append(pts[0])
	E.PL(s, oc, Color(c1.r, c1.g * 0.85, c1.b * 0.6, al * 0.6), 1.2)
	E.L(s, p, p + d * ln * 0.95, Color(1, 1, 1, al * 0.4), 1.0)

## Cánh (một bên): dir=+1 bên phải, -1 bên trái; 2 hàng lông nở theo spread 0..1.
static func wing(s, base: Vector2, dir: float, size: float, spread: float, al: float, c1: Color, c2: Color, n: int = 7) -> void:
	if al <= 0.02 or size < 8.0 or spread <= 0.02: return
	for row in range(2):
		var cnt := n if row == 0 else n - 1
		for k in range(cnt):
			var u := float(k) / float(cnt - 1)
			var a := lerpf(-1.55, 0.55, u) * spread - 0.1 * (1.0 - spread)
			var a2 := a if dir > 0.0 else PI - a
			var ln := size * (0.5 + 0.5 * sin(u * 2.3 + 0.5)) * (0.72 if row == 1 else 1.0)
			var rr := base + Vector2(0.0, 5.0 * float(row)) * 1.0
			feather(s, rr, a2, ln, size * 0.065, al * (0.85 if row == 1 else 1.0), c1, c2)

## Hạt bay lên từ mặt đất (xanh lục + xanh dương theo tỉ lệ bf).
static func motes(s, cx: float, rx: float, ytop: float, t: float, n: int, seed: int, bf: float, al: float, lowq: bool, spd: float = 1.3) -> void:
	if al <= 0.02: return
	var cnt := n / 2 if lowq else n
	for i in range(cnt):
		var ph := fmod(t * spd + E.rnd(i, seed), 1.0)
		var x := cx + (E.rnd(i, seed + 1) - 0.5) * 2.0 * rx + sin(ph * 7.0 + float(i)) * 6.0
		var y := (GY - 4.0) + (ytop - (GY - 4.0)) * ph
		var bl := E.rnd(i, seed + 2) < bf
		var f := sin(ph * PI) * al
		var r := 2.6 + 2.2 * E.rnd(i, seed + 3)
		hg(s, Vector2(x, y), r * 3.0, m(1.0) if bl else g(1.0), f * 0.8)
		E.CI(s, Vector2(x, y), r * 0.75, wh(f))
		E.L(s, Vector2(x, y + r * 2.0), Vector2(x, y + r * 6.0 * f), (m(f * 0.4) if bl else g(f * 0.4)), 1.4)

## Hạt bay VỀ thân (hồi phục dồn vào người).
static func inflow(s, t: float, n: int, seed: int, bf: float, al: float, rad: float, lowq: bool) -> void:
	if al <= 0.02: return
	var cnt := n / 2 if lowq else n
	for i in range(cnt):
		var ph := fmod(t * 1.1 + E.rnd(i, seed), 1.0)
		var a := TAU * E.rnd(i, seed + 1)
		var dr := Vector2(cos(a), sin(a) * 0.7)
		var q := 1.0 - ph
		var p := GC + dr * rad * q * q
		var bl := E.rnd(i, seed + 2) < bf
		var f := sin(ph * PI) * al
		var tail := GC + dr * rad * pow(minf(q + 0.12, 1.0), 2.0)
		E.L(s, tail, p, (m(f * 0.5) if bl else g(f * 0.5)), 2.2)
		hg(s, p, 9.0, m(1.0) if bl else g(1.0), f * 0.7)
		E.CI(s, p, 2.0, wh(f))

## Trận rune trên đất: hai vành + ngôi sao n cánh + các nút sáng.
static func rune(s, c: Vector2, rx: float, ry: float, rot: float, al: float, col: Color, n: int, skip: int = 2) -> void:
	if al <= 0.02 or rx < 4.0: return
	E.ering(s, c, rx, ry, Color(col.r, col.g, col.b, al * 0.25), 8.0)
	E.ering(s, c, rx, ry, Color(col.r, col.g, col.b, al * 0.9), 2.4)
	E.ering(s, c, rx * 0.9, ry * 0.9, wh(al * 0.7), 1.0)
	E.ering(s, c, rx * 0.62, ry * 0.62, Color(col.r, col.g, col.b, al * 0.5), 1.4)
	var pts := []
	for i in range(n):
		var a := TAU * float(i) / float(n) + rot
		pts.append(c + Vector2(cos(a) * rx * 0.9, sin(a) * ry * 0.9))
	for i in range(n):
		E.L(s, pts[i], pts[(i + skip) % n], Color(col.r, col.g, col.b, al * 0.8), 1.6)
		E.CI(s, pts[i], 3.0, wh(al))
	# ký tự nhỏ quanh vành
	for i in range(n * 2):
		var a2 := TAU * (float(i) + 0.5) / float(n * 2) - rot * 0.7
		var q := c + Vector2(cos(a2) * rx * 0.76, sin(a2) * ry * 0.76)
		E.L(s, q - Vector2(0, 2.0), q + Vector2(0, 2.0), Color(col.r, col.g, col.b, al * 0.7), 1.2)

## Cột sáng mảnh bay lên từ điểm đất.
static func pillar(s, x: float, ytop: float, w: float, col: Color, al: float) -> void:
	if al <= 0.02: return
	var y0 := GY - 4.0
	E.PG(s, PackedVector2Array([Vector2(x - w, ytop), Vector2(x + w, ytop), Vector2(x + w * 1.3, y0), Vector2(x - w * 1.3, y0)]), PackedColorArray([Color(col.r, col.g, col.b, 0.0), Color(col.r, col.g, col.b, 0.0), Color(col.r, col.g, col.b, al * 0.35), Color(col.r, col.g, col.b, al * 0.35)]))
	E.PG(s, PackedVector2Array([Vector2(x - w * 0.35, ytop), Vector2(x + w * 0.35, ytop), Vector2(x + w * 0.45, y0), Vector2(x - w * 0.45, y0)]), PackedColorArray([wh(0.0), wh(0.0), wh(al * 0.45), wh(al * 0.45)]))

## Tia nan hoa từ tâm.
static func rays(s, c: Vector2, n: int, r0: float, r1: float, rot: float, w: float, col: Color, al: float) -> void:
	if al <= 0.02: return
	for i in range(n):
		var a := TAU * float(i) / float(n) + rot
		var d := Vector2(cos(a), sin(a))
		var nr := d.orthogonal()
		var lw := w * (1.0 + 0.5 * E.rnd(i, 4))
		E.PG(s, PackedVector2Array([c + d * r0 + nr * lw, c + d * r1, c + d * r0 - nr * lw]), PackedColorArray([Color(col.r, col.g, col.b, al * 0.7), Color(col.r, col.g, col.b, 0.0), Color(col.r, col.g, col.b, al * 0.7)]))

## Nhịp xung hồi phục: dấu cộng nhỏ bay lên quanh thân.
static func pulse_plus(s, t: float, per: float, al: float, col: Color) -> void:
	var ph := fmod(t, per) / per
	var q := E.eo(ph)
	var f := sin(ph * PI) * al
	plus(s, Vector2(0, GC.y - 28.0 - 34.0 * q), 11.0 + 4.0 * q, col, f)
	E.ering(s, Vector2(0, GY - 4.0), 30.0 + 36.0 * q, 8.0 + 9.0 * q, Color(col.r, col.g, col.b, f * 0.7), 2.2)

## Chớp bùng sáng chớp lóe nhẹ ở thân.
static func burst(s, p: Vector2, r: float, al: float, col: Color) -> void:
	hg(s, p, r, col, al)
	E.flare(s, p, r * 0.25, al)

# ============================================================ HỒI PHỤC ĐƠN
## tl1 Chữa Lành (hồi 35%): vòng thập tự nhỏ gọn xanh lục + dấu cộng + lá nhỏ bay lên.
static func _heal(s, t: float, lowq: bool) -> void:
	var fa := E.fadeo(t, 0.65)
	var gp := E.eo(E.sg(t, 0.0, 0.3))
	rune(s, Vector2(0, GY - 3.0), 44.0 * gp, 11.0 * gp, t * 2.4, fa, g(1.0), 4, 1)
	hg(s, GC, 42.0 * gp, g(1.0), fa * 0.45)
	var p := E.eo(E.sg(t, 0.05, 0.75))
	plus(s, Vector2(0, GY - 14.0 - 76.0 * p), 15.0 * (0.6 + 0.4 * gp), g(1.0), fa * sin(clampf(p * PI * 0.85 + 0.3, 0.0, PI)))
	var nl := 4 if lowq else 7
	for i in range(nl):
		var ph := E.sg(t, 0.1 + 0.07 * float(i), 0.95)
		if ph <= 0.0 or ph >= 1.0: continue
		var a := float(i) * 1.1 + t * 2.0
		var pos := Vector2(sin(a) * 28.0, GY - 6.0 - 96.0 * E.eo(ph))
		leaf(s, pos, -PI * 0.5 + sin(a * 1.3) * 0.9, 12.0, sin(ph * PI) * fa, g(1.0, 0.1))
	motes(s, 0.0, 28.0, -62.0, t, 8, 3, 0.0, fa, lowq)

## tl8 Giọt Thánh (hồi 15%, nhỏ): giọt nước thánh rơi xuống, gợn sóng nhỏ, bắn tia nước.
static func _drop(s, t: float, lowq: bool) -> void:
	var fa := E.fadeo(t, 0.7)
	var fall := E.ei(E.sg(t, 0.0, 0.38))
	var y := lerpf(-96.0, -6.0, fall)
	if t < 0.4:
		var al := 1.0
		# đuôi sáng + giọt hình giọt nước
		E.L(s, Vector2(0, y - 40.0), Vector2(0, y - 6.0), wh(0.5 * al), 2.4)
		var pts := PackedVector2Array()
		pts.append(Vector2(0, y - 17.0))
		for k in range(0, 13):
			var a := -PI * 0.5 + 0.55 + (TAU - 1.1) * float(k) / 12.0
			pts.append(Vector2(cos(a) * 8.0, y + 2.0 + sin(a) * 8.0))
		hg(s, Vector2(0, y), 20.0, m(1.0, 0.3), 0.6)
		E.P(s, pts, m(0.9, 0.2))
		E.CI(s, Vector2(-2.5, y), 2.4, wh(0.9))
	var q := E.sg(t, 0.38, 1.0)
	if q > 0.0:
		for k in range(3):
			var qq := clampf(q * 1.2 - 0.15 * float(k), 0.0, 1.0)
			E.ering(s, Vector2(0, -2.0), 6.0 + 30.0 * E.eo(qq), 3.0 + 10.0 * E.eo(qq), Color(0.6, 0.95, 1.0, (1.0 - qq) * 0.9 * fa), 2.0)
		hg(s, Vector2(0, -2.0), 30.0 * (1.0 - q * 0.5), g(1.0), (1.0 - q) * 0.6)
		var nn := 5 if lowq else 9
		for i in range(nn):
			var a := -PI * 0.5 + (E.rnd(i, 2) - 0.5) * 2.6
			var d := Vector2(cos(a), sin(a))
			var dist := (14.0 + 26.0 * E.rnd(i, 3)) * E.eo(q)
			var pp := Vector2(0, -2.0) + d * dist + Vector2(0, 14.0 * q * q)
			E.CI(s, pp, 2.6 * (1.0 - q) + 0.8, Color(0.75, 1.0, 0.95, fa))
		plus(s, Vector2(0, -34.0 - 20.0 * E.eo(q)), 8.0, g(1.0), sin(q * PI) * fa)
		E.CI(s, Vector2(26, -18.0 - 18.0 * q), 3.0, m(fa * sin(q * PI)))   # chút mana
		E.CI(s, Vector2(-24, -10.0 - 22.0 * q), 2.4, m(fa * sin(q * PI)))

## tl6 Thánh Quang Hộ Thể (hồi 30% + mana 12%): hai vòng sáng xoay quanh thân + hạt xanh lục/xanh dương.
static func _aura2(s, t: float, lowq: bool) -> void:
	var fa := E.fadeo(t, 0.7)
	var gp := E.eo(E.sg(t, 0.0, 0.25))
	hg(s, GC, 56.0 * gp, E.A(s, 1.0), fa * 0.3)
	for k in range(2):
		var rot := t * (4.0 if k == 0 else -3.2) + float(k) * 1.4
		var tilt := 0.32 if k == 0 else 0.5
		var rr := 50.0 * gp
		var col := g(1.0) if k == 0 else Color(0.98, 0.92, 0.55, 1.0)
		for j in range(28):
			var u0 := TAU * float(j) / 28.0 + rot
			var u1 := TAU * float(j + 1) / 28.0 + rot
			var f := (0.5 + 0.5 * cos(u0 - rot)) * fa
			var a := Vector2(cos(u0) * rr, sin(u0) * rr * tilt * (1.0 if k == 0 else -1.0))
			var b := Vector2(cos(u1) * rr, sin(u1) * rr * tilt * (1.0 if k == 0 else -1.0))
			E.L(s, GC + a, GC + b, Color(col.r, col.g, col.b, f * 0.35), 7.0)
			E.L(s, GC + a, GC + b, Color(col.r, col.g, col.b, f * 0.95), 2.6)
			E.L(s, GC + a, GC + b, wh(f * 0.8), 1.0)
		var hp := GC + Vector2(cos(rot) * rr, sin(rot) * rr * tilt * (1.0 if k == 0 else -1.0))
		E.flare(s, hp, 6.0, fa)
	motes(s, 0.0, 34.0, -66.0, t, 10, 5, 0.12 / 0.42 * 0.4, fa, lowq)
	motes(s, 0.0, 30.0, -70.0, t + 0.3, 3, 9, 1.0, fa, lowq)
	E.ering(s, Vector2(0, GY - 3.0), 36.0 * gp, 9.0 * gp, g(fa * 0.7), 2.0)

## tl25 Thánh Vực (hồi 50%): thánh vực — pháp trận lớn + 6 cột sáng ở đỉnh sao.
static func _sanctum(s, t: float, lowq: bool) -> void:
	var fa := E.fadeo(t, 0.75)
	var gp := E.eo(E.sg(t, 0.0, 0.3))
	var R := 112.0 * gp
	rune(s, Vector2(0, GY - 3.0), R, R * 0.27, t * 1.2, fa, Color(0.55, 1.0, 0.6, 1.0), 6, 2)
	rune(s, Vector2(0, GY - 3.0), R * 0.58, R * 0.58 * 0.27, -t * 1.6, fa * 0.9, Color(1.0, 0.95, 0.6, 1.0), 3, 1)
	hg(s, Vector2(0, GY - 10.0), R * 0.8, g(1.0), fa * 0.25)
	var rise := E.eo(E.sg(t, 0.15, 0.55))
	for i in range(6):
		var a := TAU * float(i) / 6.0 + t * 1.2
		var px := cos(a) * R * 0.9
		var py := GY - 3.0 + sin(a) * R * 0.27 * 0.9
		var h := (-64.0 - 70.0 * E.rnd(i, 2)) * rise
		pillar(s, px, py + h, 9.0, g(1.0), fa * 0.9)
		E.CI(s, Vector2(px, py + h), 3.4, wh(fa))
	var core := E.sg(t, 0.2, 0.6)
	pillar(s, 0.0, GY - 4.0 - 150.0 * E.eo(core), 14.0, Color(1.0, 0.96, 0.7, 1.0), fa * 0.5)
	motes(s, 0.0, 86.0, -80.0, t, 16, 8, 0.1, fa, lowq)
	plus(s, Vector2(0, -78.0 - 20.0 * E.eo(core)), 14.0, g(1.0), fa * E.sg(t, 0.25, 0.4))

## tl11 Quang Vũ Tái Sinh (hồi 60% + mana 30%): mưa ánh sáng rơi, mầm xanh nảy lên.
static func _lightrain(s, t: float, lowq: bool) -> void:
	var fa := E.fadeo(t, 0.78)
	var cl := E.eo(E.sg(t, 0.0, 0.2))
	# mây sáng trên cao
	E.cloud(s, Vector2(-40, -150), 50.0 * cl, fa * 0.5)
	E.cloud(s, Vector2(30, -158), 60.0 * cl, fa * 0.5)
	E.cloud(s, Vector2(95, -146), 44.0 * cl, fa * 0.5)
	hg(s, Vector2(24, -150), 120.0 * cl, Color(1.0, 0.95, 0.7, 1.0), fa * 0.35)
	var n := 14 if lowq else 30
	for i in range(n):
		var x := -90.0 + 200.0 * E.rnd(i, 1)
		var ph := fmod(t * 1.5 + E.rnd(i, 2), 1.0)
		if t < 0.12: continue
		var y := -140.0 + (GY + 4.0 + 140.0) * ph
		var bl := E.rnd(i, 3) < 0.3
		var f := fa * (0.4 + 0.6 * sin(ph * PI))
		var ln := 20.0 + 14.0 * E.rnd(i, 4)
		E.L(s, Vector2(x, y - ln), Vector2(x, y), (m(f * 0.5) if bl else Color(1.0, 0.96, 0.6, f * 0.5)), 2.6)
		E.L(s, Vector2(x, y - ln * 0.5), Vector2(x, y), wh(f), 1.6)
		E.CI(s, Vector2(x, y), 2.2, wh(f))
		# tia nước nảy khi chạm đất
		if ph > 0.92: E.shock(s, Vector2(x, GY), 10.0, 3.0, f * 0.5)
	# mầm xanh nảy lên từ mặt đất
	var sp := E.sg(t, 0.35, 0.8)
	for i in range(6):
		var x := -80.0 + 32.0 * float(i) + 8.0 * (E.rnd(i, 7) - 0.5)
		var h := (16.0 + 14.0 * E.rnd(i, 8)) * E.eo(clampf(sp * 1.3 - 0.1 * float(i), 0.0, 1.0))
		if h < 3.0: continue
		var base := Vector2(x, GY)
		E.L(s, base, base + Vector2(0, -h), g(fa), 2.4)
		leaf(s, base + Vector2(0, -h * 0.85), -PI * 0.5 - 0.9, h * 0.6, fa, g(1.0, 0.1))
		leaf(s, base + Vector2(0, -h * 0.85), -PI * 0.5 + 0.9, h * 0.6, fa, g(1.0, 0.1))
	inflow(s, t, 10, 11, 0.45, fa, 90.0, lowq)
	E.ering(s, Vector2(0, GY - 3.0), 86.0 * E.eo(E.sg(t, 0.1, 0.4)), 20.0, g(fa * 0.6), 2.0)

## tg38 Thánh Dụ (hồi 60%): cuộn sắc lệnh mở ra giữa trời, chữ vàng bay xuống thành hạt xanh lục chảy vào người.
static func _decree(s, t: float, lowq: bool) -> void:
	var fa := E.fadeo(t, 0.78)
	var open := E.eo(E.sg(t, 0.05, 0.4))
	var cx := 38.0
	var cy := -92.0
	var hw := 42.0 * open
	var hh := 30.0
	var bob := sin(t * 5.0) * 3.0
	hg(s, Vector2(cx, cy + bob), 100.0, Color(1.0, 0.92, 0.55, 1.0), fa * 0.35 * open)
	rays(s, Vector2(cx, cy + bob), 12, 52.0, 110.0, t * 0.6, 5.0, Color(1.0, 0.95, 0.65, 1.0), fa * 0.6 * open)
	if hw > 3.0:
		# thân giấy
		var top := cy + bob - hh
		var bot := cy + bob + hh
		E.PG(s, PackedVector2Array([Vector2(cx - hw, top), Vector2(cx + hw, top), Vector2(cx + hw, bot), Vector2(cx - hw, bot)]), PackedColorArray([Color(0.93, 0.82, 0.58, fa), Color(0.95, 0.85, 0.62, fa), Color(0.82, 0.66, 0.4, fa), Color(0.78, 0.6, 0.36, fa)]))
		E.PL(s, PackedVector2Array([Vector2(cx - hw, top), Vector2(cx + hw, top), Vector2(cx + hw, bot), Vector2(cx - hw, bot), Vector2(cx - hw, top)]), Color(0.8, 0.6, 0.25, fa), 1.6)
		for k in range(4):
			var ly := top + 9.0 + 12.0 * float(k)
			var lw := hw * (0.7 if k % 2 == 0 else 0.5)
			E.L(s, Vector2(cx - lw, ly), Vector2(cx + lw, ly), Color(0.45, 0.25, 0.05, fa * 0.9), 2.2)
		plus(s, Vector2(cx, cy + bob), 9.0, g(1.0), fa * 0.9 * open)
		# hai trục cuộn
		for sd in range(2):
			var xx := cx - hw if sd == 0 else cx + hw
			E.L(s, Vector2(xx, top - 6.0), Vector2(xx, bot + 6.0), Color(0.62, 0.36, 0.14, fa), 7.0)
			E.L(s, Vector2(xx - 2.0, top - 6.0), Vector2(xx - 2.0, bot + 6.0), Color(0.95, 0.75, 0.35, fa), 2.0)
			E.CI(s, Vector2(xx, top - 7.0), 5.0, Color(1.0, 0.85, 0.35, fa))
			E.CI(s, Vector2(xx, bot + 7.0), 5.0, Color(1.0, 0.85, 0.35, fa))
	# chữ vàng tách ra rồi rơi thành dòng chảy xanh vào người
	var fl := E.sg(t, 0.35, 0.95)
	var n := 8 if lowq else 18
	for i in range(n):
		var ph := E.sg(fl, E.rnd(i, 1) * 0.4, 0.6 + E.rnd(i, 1) * 0.4)
		if ph <= 0.0 or ph >= 1.0: continue
		var p0 := Vector2(cx + (E.rnd(i, 2) - 0.5) * hw * 1.6, cy + 10.0)
		var p1 := GC + Vector2((E.rnd(i, 3) - 0.5) * 14.0, 0.0)
		var mid := (p0 + p1) * 0.5 + Vector2(-30.0 + 60.0 * E.rnd(i, 4), 0.0)
		var pos := p0.lerp(mid, ph).lerp(mid.lerp(p1, ph), ph)
		var pv := p0.lerp(mid, maxf(ph - 0.08, 0.0)).lerp(mid.lerp(p1, maxf(ph - 0.08, 0.0)), maxf(ph - 0.08, 0.0))
		var bl := E.rnd(i, 5) < 0.2
		var col := Color(1.0, 0.9, 0.45, 1.0).lerp(m(1.0) if bl else g(1.0), ph)
		var f := sin(ph * PI) * fa
		E.L(s, pv, pos, Color(col.r, col.g, col.b, f * 0.6), 3.0)
		hg(s, pos, 9.0, col, f * 0.8)
		E.CI(s, pos, 2.0, wh(f))
	hg(s, GC, 46.0, g(1.0), fa * 0.4 * E.sg(t, 0.5, 0.75))

## Phượng hoàng nhìn nghiêng (tg45): thân bay chéo lên, cánh giương, đuôi lửa dài.
static func _phoenix_side(s, c: Vector2, ang: float, sz: float, flap: float, al: float, t: float) -> void:
	var d := Vector2(cos(ang), sin(ang))
	var nrm := Vector2(d.y, -d.x)   # hướng "lên" so với thân
	hg(s, c, sz * 1.4, wm(1.0), al * 0.4)
	# đuôi: 3 dải lửa
	for k in range(3):
		var off := (float(k) - 1.0) * 0.14
		var pts := PackedVector2Array()
		for j in range(11):
			var u := float(j) / 10.0
			var sw := sin(t * 9.0 + u * 5.0 + float(k)) * sz * 0.08 * u
			pts.append(c - d * (sz * 0.42 + sz * 0.7 * u) + nrm * (off * sz * (1.0 + u * 1.4) + sw))
		E.PL(s, pts, wm(al * 0.22, 0.0), 12.0)
		E.PL(s, pts, wm(al * 0.6, 0.4), 5.0)
		E.PL(s, pts, wh(al * 0.85), 1.6)
	# cánh xa (sau thân) rồi cánh gần
	for sd in range(2):
		var sdir := -0.5 if sd == 0 else 1.0
		for f in range(7):
			var u := float(f) / 6.0
			var fa2 := ang - (0.55 + 1.05 * u) * sdir - flap * 0.3
			var ln := sz * (0.55 + 0.6 * sin(u * 2.4 + 0.4))
			var base := c + d * sz * 0.05 + nrm * sz * 0.1
			feather(s, base, fa2 if sd == 1 else fa2 + 0.0, ln * (0.8 if sd == 0 else 1.0), sz * 0.09, al * (0.55 if sd == 0 else 1.0), wm(1.0, 0.1 + 0.3 * u), wm(1.0, 0.6))
	# thân
	var body := PackedVector2Array()
	for k in range(8):
		var u := float(k) / 7.0
		body.append(c - d * sz * 0.4 + d * sz * 0.95 * u + nrm * sin(u * PI) * sz * 0.18)
	for k in range(7, -1, -1):
		var u2 := float(k) / 7.0
		body.append(c - d * sz * 0.4 + d * sz * 0.95 * u2 - nrm * sin(u2 * PI) * sz * 0.15)
	E.P(s, body, wm(al, 0.1))
	E.P(s, PackedVector2Array([c - d * sz * 0.3 + nrm * sz * 0.02, c + d * sz * 0.1 + nrm * sz * 0.12, c + d * sz * 0.35 + nrm * sz * 0.02, c + d * sz * 0.1 - nrm * sz * 0.02]), wh(al * 0.7))
	# đầu + mỏ + mào
	var hp := c + d * sz * 0.62 + nrm * sz * 0.1
	E.CI(s, hp, sz * 0.13, wm(al, 0.2))
	E.P(s, PackedVector2Array([hp + d * sz * 0.1 + nrm * sz * 0.05, hp + d * sz * 0.3, hp + d * sz * 0.1 - nrm * sz * 0.04]), Color(1.0, 0.85, 0.25, al))
	E.CI(s, hp + d * sz * 0.03 + nrm * sz * 0.02, sz * 0.03, Color(0.2, 0.05, 0.0, al))
	for k in range(3):
		E.L(s, hp + nrm * sz * 0.1, hp + nrm * sz * 0.3 - d * sz * (0.12 + 0.12 * float(k)), wm(al, 0.5), 3.0)

## tg45 Phục Sinh Ánh Quang (hồi 80% + mana 40%): phượng hoàng bay chéo từ đất lên trời, rải lông + hạt xanh lục & xanh dương.
static func _phoenix(s, t: float, lowq: bool) -> void:
	var fa := E.fadeo(t, 0.8)
	var rise := E.eo(E.sg(t, 0.1, 0.75))
	var gp := E.eo(E.sg(t, 0.0, 0.3))
	rune(s, Vector2(0, GY - 3.0), 70.0 * gp, 18.0 * gp, t * 1.6, fa * 0.9, wm(1.0, 0.3), 5, 2)
	hg(s, GC, 80.0 * gp, wm(1.0, 0.3), fa * 0.3)
	var pos := Vector2(lerpf(-30.0, 70.0, rise), lerpf(GY - 10.0, -150.0, rise))
	if t > 0.04:
		# vệt lửa sau lưng
		for k in range(1, 6):
			var r2 := clampf(rise - 0.06 * float(k), 0.0, 1.0)
			var pp := Vector2(lerpf(-30.0, 70.0, r2), lerpf(GY - 10.0, -150.0, r2))
			E.CI(s, pp, 18.0 - 2.4 * float(k), wm(fa * 0.2, 0.2))
		_phoenix_side(s, pos, -1.05, 96.0 * (0.7 + 0.3 * gp), sin(t * 14.0), fa, t)
	# hồi phục: hạt xanh lục + mana bay về thân
	inflow(s, t, 16, 4, 0.4, fa * E.sg(t, 0.3, 0.5), 110.0, lowq)
	motes(s, 0.0, 40.0, -80.0, t, 12, 6, 0.4, fa, lowq)
	# lông rơi
	for i in range(0 if lowq else 6):
		var ph := E.sg(t, 0.25 + 0.06 * float(i), 1.0)
		if ph <= 0.0: continue
		var fp := pos + Vector2(-20.0 - 12.0 * float(i), 8.0 + 90.0 * ph * (0.6 + E.rnd(i, 1)))
		feather(s, fp, 1.2 + sin(t * 4.0 + float(i)), 14.0, 3.0, sin(ph * PI) * fa, wm(1.0, 0.3), wm(1.0, 0.8))
	var fl := E.sg(t, 0.62, 0.78)
	if fl > 0.0: plus(s, GC + Vector2(0, -56.0 * E.eo(fl)), 14.0, g(1.0), sin(fl * PI) * fa)

## ulTri1 Thánh Quang Hồi Sinh (hồi 85% + mana 40%): phượng hoàng nhìn thẳng giang cánh bay lên, vầng hào quang + mưa lông vàng.
static func _phoenix2(s, t: float, lowq: bool) -> void:
	var fa := E.fadeo(t, 0.82)
	var gp := E.eo(E.sg(t, 0.0, 0.25))
	var rise := E.eo(E.sg(t, 0.12, 0.6))
	var cp := Vector2(0, lerpf(GY - 20.0, -96.0, rise))
	rune(s, Vector2(0, GY - 3.0), 96.0 * gp, 25.0 * gp, t * 1.2, fa, wm(1.0, 0.4), 8, 3)
	pillar(s, 0.0, -230.0 * E.eo(E.sg(t, 0.05, 0.45)), 34.0, Color(1.0, 0.92, 0.6, 1.0), fa * 0.9)
	if t > 0.08:
		var sp := E.eo(E.sg(t, 0.12, 0.55))
		hg(s, cp, 150.0 * sp, wm(1.0, 0.4), fa * 0.45)
		rays(s, cp, 18, 70.0, 190.0 * sp, t * 0.5, 7.0, Color(1.0, 0.9, 0.55, 1.0), fa * 0.7)
		E.ering(s, cp, 78.0 * sp, 78.0 * sp, wm(fa * 0.8, 0.6), 3.0)
		E.AR(s, cp, 88.0 * sp, t * 2.0, t * 2.0 + 2.2, 20, wh(fa), 2.0)
		E.AR(s, cp, 88.0 * sp, t * 2.0 + PI, t * 2.0 + PI + 2.2, 20, wh(fa), 2.0)
		# đuôi quạt 3 dải lửa phía dưới
		for k in range(5):
			var a := PI * 0.5 + (float(k) - 2.0) * 0.28
			var pts := PackedVector2Array()
			for j in range(10):
				var u := float(j) / 9.0
				pts.append(cp + Vector2(cos(a), sin(a)) * (26.0 + 100.0 * u) + Vector2(sin(t * 8.0 + u * 5.0 + float(k)) * 7.0 * u, 0.0))
			E.PL(s, pts, wm(fa * 0.25, 0.0), 14.0)
			E.PL(s, pts, wm(fa * 0.7, 0.4), 5.0)
			E.PL(s, pts, wh(fa), 1.5)
		# cánh giang hai bên
		var fl := 0.82 + 0.18 * sin(t * 12.0)
		wing(s, cp + Vector2(14, -6), 1.0, 130.0, sp * fl, fa, wm(1.0, 0.15), wm(1.0, 0.65), 8)
		wing(s, cp + Vector2(-14, -6), -1.0, 130.0, sp * fl, fa, wm(1.0, 0.15), wm(1.0, 0.65), 8)
		# thân + đầu
		E.P(s, PackedVector2Array([cp + Vector2(0, -34), cp + Vector2(17, -8), cp + Vector2(12, 26), cp + Vector2(0, 38), cp + Vector2(-12, 26), cp + Vector2(-17, -8)]), wm(fa, 0.15))
		E.P(s, PackedVector2Array([cp + Vector2(0, -26), cp + Vector2(8, -4), cp + Vector2(0, 22), cp + Vector2(-8, -4)]), wh(fa * 0.75))
		var hd := cp + Vector2(0, -46)
		E.CI(s, hd, 13.0, wm(fa, 0.25))
		E.P(s, PackedVector2Array([hd + Vector2(-5, 3), hd + Vector2(0, 17), hd + Vector2(5, 3)]), Color(1.0, 0.85, 0.25, fa))
		for k in range(5):
			var ca := -PI * 0.5 + (float(k) - 2.0) * 0.4
			E.L(s, hd + Vector2(cos(ca), sin(ca)) * 11.0, hd + Vector2(cos(ca), sin(ca)) * (24.0 + 6.0 * float(2 - absi(k - 2))), wm(fa, 0.5), 3.0)
		E.CI(s, hd + Vector2(-4, -1), 2.0, Color(0.2, 0.05, 0.0, fa))
		E.CI(s, hd + Vector2(4, -1), 2.0, Color(0.2, 0.05, 0.0, fa))
	inflow(s, t, 22, 5, 0.4, fa * E.sg(t, 0.35, 0.55), 150.0, lowq)
	motes(s, 0.0, 70.0, -110.0, t, 16, 8, 0.4, fa, lowq)
	# mưa lông vàng
	for i in range(0 if lowq else 10):
		var ph := fmod(t * 0.9 + E.rnd(i, 1), 1.0)
		if t < 0.3: break
		var fp := Vector2(-110.0 + 220.0 * E.rnd(i, 2) + sin(ph * 6.0 + float(i)) * 14.0, -150.0 + 180.0 * ph)
		feather(s, fp, 1.57 + sin(ph * 6.0 + float(i)) * 0.7, 14.0, 3.2, sin(ph * PI) * fa, wm(1.0, 0.3), wm(1.0, 0.8))
	var pf := E.sg(t, 0.55, 0.8)
	if pf > 0.0: plus(s, GC + Vector2(0, -50.0 * E.eo(pf)), 18.0, g(1.0), sin(pf * PI) * fa)

# ============================================================ SÁT THƯƠNG + HỒI
## tg42 Ánh Sáng Phán Xét (aoe 280): búa ánh sáng khổng lồ giáng xuống, sóng nổ quanh người bán kính 280.
static func _judge(s, t: float, lowq: bool) -> void:
	var fa := E.fadeo(t, 0.7)
	var R := 280.0
	var fall := E.ei(E.sg(t, 0.0, 0.3))
	var hit := E.sg(t, 0.3, 1.0)
	var x := 40.0
	# pháp trận cán cân dưới đất hiện dần
	var ap := E.eo(E.sg(t, 0.0, 0.3))
	rune(s, Vector2(0, GY - 3.0), R * 0.55 * ap * (1.0 + hit * 0.4), R * 0.55 * 0.26 * ap * (1.0 + hit * 0.4), t * 1.4, fa * 0.8, Color(1.0, 0.92, 0.5, 1.0), 6, 2)
	if t < 0.5:
		var yy := lerpf(-300.0, GY - 28.0, fall)
		var al := 1.0 if t < 0.3 else 1.0 - E.sg(t, 0.3, 0.5)
		# cán búa
		E.PG(s, PackedVector2Array([Vector2(x - 7, yy - 280), Vector2(x + 7, yy - 280), Vector2(x + 7, yy), Vector2(x - 7, yy)]), PackedColorArray([wh(0.0), wh(0.0), Color(0.95, 0.82, 0.4, al), Color(0.8, 0.6, 0.2, al)]))
		# đầu búa
		hg(s, Vector2(x, yy), 70.0, Color(1.0, 0.92, 0.55, 1.0), al * 0.5)
		E.PG(s, PackedVector2Array([Vector2(x - 44, yy - 22), Vector2(x + 44, yy - 22), Vector2(x + 44, yy + 22), Vector2(x - 44, yy + 22)]), PackedColorArray([Color(1.0, 0.97, 0.8, al), Color(1.0, 0.97, 0.8, al), Color(0.95, 0.72, 0.25, al), Color(0.95, 0.72, 0.25, al)]))
		E.PL(s, PackedVector2Array([Vector2(x - 44, yy - 22), Vector2(x + 44, yy - 22), Vector2(x + 44, yy + 22), Vector2(x - 44, yy + 22), Vector2(x - 44, yy - 22)]), wh(al), 2.0)
		E.L(s, Vector2(x - 36, yy - 10), Vector2(x + 36, yy - 10), wh(al * 0.8), 2.0)
		E.CI(s, Vector2(x, yy), 8.0, Color(1.0, 0.85, 0.3, al))
		E.CI(s, Vector2(x, yy), 4.0, wh(al))
		# vệt sáng phía sau lúc rơi
		E.beam(s, x, yy - 300.0, yy, 40.0, 60.0, al)
	if hit > 0.0:
		var e := E.eo(hit)
		var fh := 1.0 - hit
		hg(s, Vector2(0, -6), R * 0.6 * e, Color(1.0, 0.95, 0.7, 1.0), fh * 0.6)
		E.shock(s, Vector2(0, GY - 2.0), R * e, R * 0.27 * e, fh)
		E.shock(s, Vector2(0, GY - 2.0), R * 0.66 * e, R * 0.18 * e, fh * 0.8)
		# vòng trụ ánh sáng quanh vành bán kính 280
		var np := 10 if lowq else 18
		for i in range(np):
			var a := TAU * float(i) / float(np) + 0.2
			var pxx := cos(a) * R * e * 0.95
			var pyy := GY - 2.0 + sin(a) * R * 0.27 * e * 0.95
			var h := (90.0 + 70.0 * E.rnd(i, 2)) * E.sg(hit, 0.0, 0.5) * fh
			pillar(s, pxx, pyy - h, 6.0, Color(1.0, 0.92, 0.55, 1.0), fh)
		E.star(s, Vector2(x, GY - 20.0), 44.0 * (1.0 - hit * 0.4), fh * 0.8, 10)
		E.crack(s, Vector2(x, GY), 150.0 * e, fh, 5)
		E.dust(s, Vector2(x, GY), R * 0.5, hit, fh * 0.7, 12, 2)
		E.spark(s, Vector2(x, GY - 30.0), 22, 190.0, hit, fh, 4)

## tl40 Bình Minh Tái Sinh (aoe 260 + hồi 40%): mặt trời mọc từ đường chân trời, tia nắng quét ra, dòng xanh lục chảy về người.
static func _sunrise(s, t: float, lowq: bool) -> void:
	var fa := E.fadeo(t, 0.75)
	var R := 260.0
	var up := E.eo(E.sg(t, 0.05, 0.5))
	var sc := Vector2(0, lerpf(GY + 24.0, -30.0, up))
	# bầu trời ửng cam phía sau
	hg(s, Vector2(0, -20), 210.0 * up, Color(1.0, 0.72, 0.3, 1.0), fa * 0.45)
	hg(s, sc, 130.0 * up, Color(1.0, 0.9, 0.55, 1.0), fa * 0.6)
	# tia nắng quạt phía trên
	rays(s, sc, 20, 52.0, 200.0 * up + 60.0, t * 0.35, 8.0, Color(1.0, 0.85, 0.4, 1.0), fa * 0.8 * up)
	# mặt trời (cắt bởi mặt đất bằng cách dựng mảng đất đè lên)
	E.CI(s, sc, 50.0, Color(1.0, 0.7, 0.2, fa * 0.5))
	E.CI(s, sc, 44.0, Color(1.0, 0.8, 0.3, fa * 0.55))
	E.CI(s, sc, 34.0, Color(1.0, 0.9, 0.5, fa * 0.4))
	E.CI(s, sc, 22.0, wh(fa * 0.5))
	E.AR(s, sc, 50.0, 0.0, TAU, 40, Color(1.0, 0.95, 0.7, fa), 2.0)
	# đường chân trời sáng
	var hz := GY + 6.0
	E.L(s, Vector2(-R * up, hz), Vector2(R * up, hz), Color(1.0, 0.85, 0.4, fa * 0.5), 6.0)
	E.L(s, Vector2(-R * up, hz), Vector2(R * up, hz), wh(fa * 0.9), 1.8)
	# bùng nổ lan theo bán kính 260
	var bl := E.sg(t, 0.38, 1.0)
	if bl > 0.0:
		var e := E.eo(bl)
		var fb := 1.0 - bl
		E.shock(s, Vector2(0, GY - 2.0), R * e, R * 0.27 * e, fb)
		E.ering(s, Vector2(0, -20.0), R * 0.7 * e, R * 0.7 * e, Color(1.0, 0.85, 0.4, fb * 0.5), 5.0)
		E.AR(s, Vector2(0, -20.0), R * 0.7 * e, 0.0, TAU, 56, wh(fb * 0.9), 1.8)
		hg(s, GC, R * 0.5 * e, Color(1.0, 0.92, 0.6, 1.0), fb * 0.4)
		for i in range(0 if lowq else 14):
			var a := TAU * E.rnd(i, 1)
			var d := Vector2(cos(a), sin(a) * 0.5)
			E.CI(s, Vector2(0, -20.0) + d * R * 0.8 * e, 3.0 * fb + 1.0, wh(fb))
	inflow(s, t, 16, 14, 0.0, fa * E.sg(t, 0.45, 0.65), 170.0, lowq)
	motes(s, 0.0, 60.0, -90.0, t, 10, 3, 0.0, fa * E.sg(t, 0.4, 0.55), lowq)
	var pf := E.sg(t, 0.55, 0.8)
	if pf > 0.0: plus(s, GC + Vector2(0, -44.0 * E.eo(pf)), 14.0, g(1.0), sin(pf * PI) * fa)

## tl5 Phép Thánh Toàn Trị (ult aoe 240 + hồi 25%): thập tự thánh khổng lồ trồi lên rồi nổ tung ánh sáng.
static func _allheal(s, t: float, lowq: bool) -> void:
	var fa := E.fadeo(t, 0.78)
	var R := 240.0
	var cp := Vector2(0, -50)
	var gr := E.eo(E.sg(t, 0.0, 0.4))
	var exp := E.sg(t, 0.4, 1.0)
	var e := E.eo(exp)
	rune(s, Vector2(0, GY - 3.0), 80.0 * gr + R * 0.3 * e, (80.0 * gr + R * 0.3 * e) * 0.26, t * 1.4, fa, Color(1.0, 0.95, 0.6, 1.0), 6, 2)
	# thập tự khổng lồ nhô lên từ đất, xoay nhẹ trước khi nổ
	var cs := (1.0 + 0.5 * E.ei(exp)) * gr
	if cs > 0.05 and exp < 0.9:
		var al := fa * (1.0 - E.sg(t, 0.8, 1.0) * 0.4)
		var cy := lerpf(GY - 20.0, cp.y, gr)
		var vw := 14.0 * cs
		var vh := 112.0 * cs
		var hh := 78.0 * cs
		var hy := cy - 22.0 * cs
		hg(s, Vector2(0, cy), 160.0 * cs, Color(1.0, 0.94, 0.65, 1.0), al * 0.5)
		E.PG(s, PackedVector2Array([Vector2(-vw, cy - vh), Vector2(vw, cy - vh), Vector2(vw, cy + vh * 0.7), Vector2(-vw, cy + vh * 0.7)]), PackedColorArray([Color(1.0, 0.92, 0.6, al * 0.55), Color(1.0, 0.92, 0.6, al * 0.55), Color(1.0, 0.8, 0.35, al * 0.45), Color(1.0, 0.8, 0.35, al * 0.45)]))
		E.PG(s, PackedVector2Array([Vector2(-hh, hy - vw), Vector2(hh, hy - vw), Vector2(hh, hy + vw), Vector2(-hh, hy + vw)]), PackedColorArray([Color(1.0, 0.8, 0.35, al * 0.45), Color(1.0, 0.92, 0.6, al * 0.55), Color(1.0, 0.92, 0.6, al * 0.55), Color(1.0, 0.8, 0.35, al * 0.45)]))
		E.PL(s, PackedVector2Array([Vector2(0, cy - vh), Vector2(0, cy + vh * 0.7)]), Color(1.0, 0.75, 0.2, al), 2.0)
		E.PL(s, PackedVector2Array([Vector2(-hh, hy), Vector2(hh, hy)]), Color(1.0, 0.75, 0.2, al), 2.0)
		E.CI(s, Vector2(0, hy), vw * 1.6, Color(1.0, 0.95, 0.7, al))
		E.CI(s, Vector2(0, hy), vw * 0.8, g(al))
		rays(s, Vector2(0, hy), 16, 40.0 * cs, 130.0 * cs, t * 0.8, 5.0, Color(1.0, 0.92, 0.55, 1.0), al * 0.6)
	if exp > 0.0:
		var fe := 1.0 - exp
		E.shock(s, Vector2(0, GY - 2.0), R * e, R * 0.27 * e, fe)
		E.ering(s, cp, R * 0.8 * e, R * 0.8 * e, Color(1.0, 0.92, 0.55, fe * 0.45), 8.0)
		E.AR(s, cp, R * 0.8 * e, 0.0, TAU, 64, wh(fe), 2.4)
		hg(s, cp, R * 0.9 * e, Color(1.0, 0.96, 0.75, 1.0), fe * 0.6)
		# bốn tia thập tự bắn ra theo 4 hướng
		for k in range(4):
			var a := PI * 0.5 * float(k)
			var d := Vector2(cos(a), sin(a))
			E.cut(s, cp + d * 30.0, cp + d * R * e * 1.05, 11.0 * fe, fe)
		E.star(s, cp, 70.0 * (1.0 - exp * 0.5), fe, 12)
		E.spark(s, cp, 24, R * 0.9, exp, fe, 3)
	inflow(s, t, 18, 22, 0.0, fa * E.sg(t, 0.5, 0.7), 150.0, lowq)
	var pf := E.sg(t, 0.65, 0.9)
	if pf > 0.0: plus(s, GC + Vector2(0, -48.0 * E.eo(pf)), 14.0, g(1.0), sin(pf * PI) * fa)

## tl7 Kết Giới Sinh Mệnh (aoe 260 + hồi 35%): dây leo mọc vòng quanh, uốn lên thành vòm hoa lá.
static func _lifedome(s, t: float, lowq: bool) -> void:
	var fa := E.fadeo(t, 0.78)
	var R := 190.0
	var gp := E.eo(E.sg(t, 0.0, 0.3))
	var grow := E.eo(E.sg(t, 0.12, 0.6))
	var cc := Vector2(0, GY - 4.0)
	E.ering(s, cc, R * gp, R * 0.26 * gp, g(fa * 0.3), 8.0)
	E.ering(s, cc, R * gp, R * 0.26 * gp, g(fa * 0.95), 2.2)
	E.ering(s, cc, R * 0.9 * gp, R * 0.23 * gp, wh(fa * 0.6), 1.0)
	hg(s, Vector2(0, -50), R * 0.85, g(1.0), fa * 0.18 * grow)
	var nv := 7 if lowq else 11
	for i in range(nv):
		var a := TAU * float(i) / float(nv) + 0.2
		var bx := cos(a) * R
		var by := GY - 4.0 + sin(a) * R * 0.26
		# dây leo từ gốc, cong về phía đỉnh vòm (0, -150)
		var top := Vector2(0, -140.0)
		var pts := PackedVector2Array()
		var steps := 14
		for j in range(steps + 1):
			var u := float(j) / float(steps) * grow
			var bez := Vector2(bx, by).lerp(Vector2(bx * 0.9, -150.0), u).lerp(top.lerp(Vector2(bx * 0.3, -120.0), 1.0 - u), u * u)
			var sw := sin(u * 11.0 + float(i)) * 6.0 * (1.0 - u)
			pts.append(Vector2(bez.x + sw, bez.y))
		E.PL(s, pts, g(fa * 0.28), 8.0)
		E.PL(s, pts, Color(0.3, 0.85, 0.35, fa), 3.0)
		E.PL(s, pts, Color(0.8, 1.0, 0.75, fa * 0.7), 1.0)
		# lá dọc dây + hoa ở ngọn
		for j in range(2, pts.size(), 3):
			var side := 1.0 if (j / 3) % 2 == 0 else -1.0
			leaf(s, pts[j], -PI * 0.5 + side * 1.0, 13.0, fa, g(1.0, 0.1))
		if grow > 0.85:
			var tp := pts[pts.size() - 1]
			for k in range(5):
				var pa := TAU * float(k) / 5.0 + t * 1.0
				E.CI(s, tp + Vector2(cos(pa), sin(pa)) * 5.0, 4.0, Color(1.0, 0.95, 0.7, fa))
			E.CI(s, tp, 3.4, Color(1.0, 0.8, 0.25, fa))
	# sóng sát thương lan ra theo bán kính 260
	var bl := E.sg(t, 0.4, 1.0)
	if bl > 0.0:
		var e := E.eo(bl)
		E.shock(s, cc, 260.0 * e, 260.0 * 0.26 * e, (1.0 - bl) * 0.9 * fa)
	inflow(s, t, 14, 31, 0.0, fa * E.sg(t, 0.4, 0.55), 140.0, lowq)
	motes(s, 0.0, 100.0, -90.0, t, 12, 4, 0.0, fa, lowq)
	var pf := E.sg(t, 0.6, 0.85)
	if pf > 0.0: plus(s, GC + Vector2(0, -44.0 * E.eo(pf)), 14.0, g(1.0), sin(pf * PI) * fa)

# ============================================================ BUFF HỒI LIÊN TỤC
## tg32 Phước Lành: tia vàng rơi từ trời xuống như mưa phước, dấu cộng xanh lục.
static func _bless(s, t: float, lowq: bool) -> void:
	var fa := E.fadeo(t, 0.75)
	var gp := E.eo(E.sg(t, 0.0, 0.3))
	rune(s, Vector2(0, GY - 3.0), 46.0 * gp, 12.0 * gp, t * 2.0, fa, Color(1.0, 0.92, 0.5, 1.0), 5, 2)
	pillar(s, 0.0, -140.0 * E.eo(E.sg(t, 0.0, 0.4)), 26.0, Color(1.0, 0.94, 0.65, 1.0), fa * 0.8)
	_bless_rain(s, t * 1.5, lowq, fa)
	plus(s, Vector2(0, -48.0 - 24.0 * E.eo(E.sg(t, 0.2, 0.8))), 14.0, g(1.0), fa * sin(E.sg(t, 0.15, 0.9) * PI))
static func _bless_rain(s, t: float, lowq: bool, fa: float) -> void:
	for i in range(8 if lowq else 16):
		var x := -34.0 + 68.0 * E.rnd(i, 1)
		var ph := fmod(t * 0.9 + E.rnd(i, 2), 1.0)
		var y := -130.0 + 160.0 * ph
		var f := fa * sin(ph * PI)
		E.L(s, Vector2(x, y - 22.0), Vector2(x, y), Color(1.0, 0.92, 0.45, f * 0.5), 3.0)
		E.L(s, Vector2(x, y - 10.0), Vector2(x, y), wh(f), 1.6)
		E.CI(s, Vector2(x, y), 2.4, wh(f))
static func _bless_a(s, t: float, lowq: bool) -> void:
	rune(s, Vector2(0, GY - 3.0), 40.0, 10.0, t * 1.4, 0.8, Color(1.0, 0.92, 0.5, 1.0), 5, 2)
	hg(s, GC, 50.0, Color(1.0, 0.92, 0.55, 1.0), 0.14)
	_bless_rain(s, t, lowq, 1.0)
	pulse_plus(s, t, 1.4, 1.0, g(1.0))

## tl3 Ân Sủng: bồ câu trắng lượn quanh người, lông vũ rơi, dấu cộng xanh lục theo nhịp.
static func _dove_shape(s, p: Vector2, dir: float, sz: float, flap: float, al: float) -> void:
	# bồ câu nhìn ngang: thân thoi, đầu, mỏ, đuôi, cánh vỗ
	var d := Vector2(dir, 0.0)
	var body := PackedVector2Array([p + d * sz * 0.5, p + d * sz * 0.1 + Vector2(0, -sz * 0.24), p - d * sz * 0.4 + Vector2(0, -sz * 0.1), p - d * sz * 0.65 + Vector2(0, sz * 0.05), p - d * sz * 0.4 + Vector2(0, sz * 0.18), p + d * sz * 0.1 + Vector2(0, sz * 0.22)])
	hg(s, p, sz * 1.1, Color(1.0, 0.96, 0.8, 1.0), al * 0.45)
	# cánh xa
	E.P(s, PackedVector2Array([p + Vector2(0, -sz * 0.1), p - d * sz * 0.35 + Vector2(0, -sz * (0.9 + 0.3 * flap)), p - d * sz * 0.7 + Vector2(0, -sz * (0.4 + 0.2 * flap)), p - d * sz * 0.3]), Color(0.85, 0.9, 1.0, al * 0.55))
	E.P(s, body, Color(1.0, 1.0, 1.0, al))
	E.PL(s, body, Color(0.8, 0.85, 0.95, al * 0.8), 1.0)
	E.CI(s, p + d * sz * 0.38 + Vector2(0, -sz * 0.12), sz * 0.17, Color(1.0, 1.0, 1.0, al))
	E.P(s, PackedVector2Array([p + d * sz * 0.5 + Vector2(0, -sz * 0.16), p + d * sz * 0.72 + Vector2(0, -sz * 0.1), p + d * sz * 0.5 + Vector2(0, -sz * 0.08)]), Color(1.0, 0.7, 0.3, al))
	E.CI(s, p + d * sz * 0.42 + Vector2(0, -sz * 0.15), sz * 0.04, Color(0.1, 0.1, 0.2, al))
	# cánh gần
	var wp := PackedVector2Array([p + d * sz * 0.1 + Vector2(0, -sz * 0.1), p - d * sz * 0.1 + Vector2(0, -sz * (1.05 + 0.35 * flap)), p - d * sz * 0.55 + Vector2(0, -sz * (0.6 + 0.3 * flap)), p - d * sz * 0.6 + Vector2(0, -sz * 0.05)])
	E.P(s, wp, Color(1.0, 1.0, 1.0, al))
	E.PL(s, wp, Color(0.78, 0.85, 1.0, al * 0.8), 1.0)
	E.L(s, wp[1], p - d * sz * 0.3 + Vector2(0, -sz * 0.1), Color(0.8, 0.86, 1.0, al * 0.7), 1.0)
	E.L(s, p - d * sz * 0.65 + Vector2(0, sz * 0.05), p - d * sz * 1.0 + Vector2(0, sz * 0.15), Color(1.0, 1.0, 1.0, al * 0.9), 3.0)
static func _dove_orbit(s, t: float, lowq: bool, fa: float, n: int) -> void:
	for i in range(n):
		var a := TAU * float(i) / float(n) + t * 1.5
		var rx := 64.0
		var pos := GC + Vector2(cos(a) * rx, sin(a) * 22.0 - 24.0 * sin(t * 2.0 + float(i)))
		var dirx := 1.0 if -sin(a) >= 0.0 else -1.0   # hướng bay theo chiều quay
		var back := 1.0 if sin(a) > 0.0 else 0.65   # phía sau xa -> mờ
		E.L(s, pos - Vector2(dirx * 18.0, 0.0), pos - Vector2(dirx * 46.0, -4.0), Color(1.0, 0.96, 0.8, fa * 0.12 * back), 3.0)
		_dove_shape(s, pos, dirx, 15.0, sin(t * 11.0 + float(i) * 2.0), fa * back)
static func _dove(s, t: float, lowq: bool) -> void:
	var fa := E.fadeo(t, 0.75)
	var gp := E.eo(E.sg(t, 0.0, 0.3))
	hg(s, GC, 70.0 * gp, Color(1.0, 0.95, 0.7, 1.0), fa * 0.3)
	E.ering(s, Vector2(0, GY - 3.0), 54.0 * gp, 14.0 * gp, wh(fa * 0.8), 2.0)
	_dove_orbit(s, t * 1.3, lowq, fa, 3)
	for i in range(0 if lowq else 7):
		var ph := E.sg(t, 0.1 + 0.07 * float(i), 1.0)
		feather(s, Vector2(-50.0 + 100.0 * E.rnd(i, 1) + sin(ph * 5.0) * 8.0, -70.0 + 100.0 * ph), 1.57 + sin(ph * 5.0 + float(i)) * 0.8, 12.0, 2.8, sin(ph * PI) * fa, Color(1, 1, 1, 1), Color(0.9, 0.95, 1.0, 1.0))
	plus(s, Vector2(0, -58.0 - 20.0 * E.eo(E.sg(t, 0.2, 0.8))), 13.0, g(1.0), fa * sin(E.sg(t, 0.15, 0.9) * PI))
static func _dove_a(s, t: float, lowq: bool) -> void:
	hg(s, GC, 56.0, Color(1.0, 0.95, 0.7, 1.0), 0.15)
	_dove_orbit(s, t * 0.9, lowq, 1.0, 2)
	E.ering(s, Vector2(0, GY - 3.0), 44.0, 11.0, wh(0.5), 1.6)
	pulse_plus(s, t, 1.5, 1.0, g(1.0))

## tl10 Thanh Tẩy: các vòng nước xanh lơ quét từ chân lên đầu, bọt nước bay lên.
static func _purify_rings(s, t: float, fa: float, n: int, lowq: bool) -> void:
	for k in range(n):
		var ph := fmod(t * 0.9 + float(k) / float(n), 1.0)
		var y := lerpf(GY - 4.0, -64.0, ph)
		var f := sin(ph * PI) * fa
		var rr := 38.0 + 6.0 * sin(ph * PI)
		E.ering(s, Vector2(0, y), rr, rr * 0.28, Color(0.55, 0.92, 1.0, f * 0.3), 8.0)
		E.ering(s, Vector2(0, y), rr, rr * 0.28, Color(0.7, 0.97, 1.0, f * 0.9), 2.4)
		E.ering(s, Vector2(0, y), rr * 0.97, rr * 0.28 * 0.97, wh(f * 0.8), 1.0)
		hg(s, Vector2(0, y), 40.0, Color(0.6, 0.95, 1.0, 1.0), f * 0.25)
	for i in range(5 if lowq else 12):
		var ph2 := fmod(t * 1.1 + E.rnd(i, 1), 1.0)
		var a := TAU * E.rnd(i, 2) + t * 2.0
		var p := Vector2(cos(a) * 32.0, GY - 6.0 - 92.0 * ph2)
		var f2 := sin(ph2 * PI) * fa
		E.CI(s, p, 4.0 * f2 + 1.0, Color(0.7, 0.96, 1.0, f2 * 0.35))
		E.AR(s, p, 4.0 * f2 + 1.0, 0.0, TAU, 10, Color(0.85, 1.0, 1.0, f2), 1.2)
		E.CI(s, p + Vector2(-1, -1), 1.0, wh(f2))
static func _purify(s, t: float, lowq: bool) -> void:
	var fa := E.fadeo(t, 0.78)
	var gp := E.eo(E.sg(t, 0.0, 0.25))
	hg(s, GC, 56.0 * gp, Color(0.6, 0.95, 1.0, 1.0), fa * 0.3)
	_purify_rings(s, t * 1.3, fa, 3, lowq)
	var sw := E.sg(t, 0.1, 0.7)
	E.flare(s, Vector2(0, lerpf(GY - 6.0, -70.0, sw)), 9.0, fa * sin(sw * PI))
	plus(s, Vector2(0, -52.0 - 22.0 * sw), 12.0, g(1.0), fa * sin(clampf((t - 0.3) * 1.6, 0.0, 1.0) * PI))
static func _purify_a(s, t: float, lowq: bool) -> void:
	hg(s, GC, 52.0, Color(0.6, 0.95, 1.0, 1.0), 0.12)
	_purify_rings(s, t * 0.7, 0.85, 2, lowq)
	E.ering(s, Vector2(0, GY - 3.0), 40.0, 10.0, Color(0.7, 0.97, 1.0, 0.7), 2.0)
	pulse_plus(s, t, 1.4, 1.0, g(1.0))

# ============================================================ HỘ THỂ / MANASHIELD
static func _angel_wings(s, t: float, fa: float, spread: float) -> void:
	var flap := 0.9 + 0.1 * sin(t * 3.0)
	var base := Vector2(-6, -16)
	# cánh phía sau thân: hai bên, cánh trái (sau) mờ hơn
	wing(s, base + Vector2(-6, 0), -1.0, 112.0, spread * flap, fa, Color(0.5, 0.68, 1.0, 1.0), Color(1.0, 0.85, 0.4, 1.0), 6)
	wing(s, base + Vector2(6, 0), 1.0, 112.0, spread * flap, fa, Color(0.5, 0.68, 1.0, 1.0), Color(1.0, 0.85, 0.4, 1.0), 6)
## tg37 Thiên Sứ Hộ Tống: cánh thiên sứ giang sau lưng, vòng hào quang trên đầu, lông vũ rơi, khiên ánh sáng chắn trước.
static func _angel(s, t: float, lowq: bool) -> void:
	var fa := E.fadeo(t, 0.8)
	var sp := E.eo(E.sg(t, 0.0, 0.45))
	hg(s, GC, 90.0 * sp, Color(1.0, 0.95, 0.75, 1.0), fa * 0.4)
	E.ering(s, Vector2(0, GY - 3.0), 62.0 * sp, 15.0 * sp, Color(1.0, 0.92, 0.55, fa * 0.9), 2.2)
	_angel_wings(s, t, fa, sp)
	_halo(s, Vector2(0, -52.0 - 6.0 * sp), fa * sp, t)
	E.flare(s, Vector2(0, -6.0), 20.0 * sp * (1.0 - E.sg(t, 0.4, 0.8)), fa)
	for i in range(0 if lowq else 8):
		var ph := E.sg(t, 0.2 + 0.05 * float(i), 1.0)
		feather(s, Vector2(-70.0 + 140.0 * E.rnd(i, 1), -50.0 + 90.0 * ph), 1.57 + sin(ph * 5.0 + float(i)) * 0.8, 12.0, 3.0, sin(ph * PI) * fa, Color(1, 1, 1, 1), Color(1.0, 0.95, 0.8, 1.0))
static func _halo(s, p: Vector2, al: float, t: float) -> void:
	E.ering(s, p, 17.0, 5.0, Color(1.0, 0.9, 0.4, al * 0.3), 7.0)
	E.ering(s, p, 17.0, 5.0, Color(1.0, 0.92, 0.5, al), 2.6)
	E.ering(s, p, 17.0, 5.0, wh(al), 1.0)
	E.flare(s, p + Vector2(cos(t * 3.0) * 17.0, sin(t * 3.0) * 5.0), 3.0, al * 0.8)
static func _angel_a(s, t: float, lowq: bool) -> void:
	_angel_wings(s, t, 0.85, 1.0)
	hg(s, GC, 70.0, Color(1.0, 0.95, 0.75, 1.0), 0.18)
	_halo(s, Vector2(0, -54.0 + sin(t * 3.0) * 2.0), 1.0, t)
	E.ering(s, Vector2(0, GY - 3.0), 50.0, 12.0, Color(1.0, 0.92, 0.55, 0.7), 2.0)
	for i in range(2 if lowq else 5):
		var ph := fmod(t * 0.35 + E.rnd(i, 1), 1.0)
		feather(s, Vector2(-70.0 + 140.0 * E.rnd(i, 2) + sin(ph * 6.0) * 6.0, -60.0 + 90.0 * ph), 1.57 + sin(ph * 5.0 + float(i)) * 0.8, 11.0, 2.8, sin(ph * PI) * 0.9, Color(1, 1, 1, 1), Color(1.0, 0.95, 0.8, 1.0))

## Lưới lục giác của kết giới (R bán kính, wave 0..1 vị trí gợn sóng).
static func _hexgrid(s, c: Vector2, R: float, size: float, al: float, wave: float, t: float, col: Color) -> void:
	var dx := size * 1.732
	var dy := size * 1.5
	var rows := int(R / dy) + 1
	for r in range(-rows, rows + 1):
		var cols := int(R / dx) + 1
		for q in range(-cols, cols + 1):
			var p := Vector2(float(q) * dx + (dx * 0.5 if r % 2 != 0 else 0.0), float(r) * dy)
			var dist := p.length()
			if dist > R - size * 0.6: continue
			var wv := 1.0 - clampf(absf(dist - wave * R) / (R * 0.22), 0.0, 1.0)
			var f := al * (0.35 + 0.65 * wv)
			var pts := PackedVector2Array()
			for k in range(7):
				var a := PI / 6.0 + TAU * float(k % 6) / 6.0
				pts.append(c + p + Vector2(cos(a), sin(a)) * size * 0.9)
			E.PL(s, pts, Color(col.r, col.g, col.b, f * 0.9), 1.4)
			if wv > 0.3:
				E.P(s, PackedVector2Array([pts[0], pts[1], pts[2], pts[3], pts[4], pts[5]]), Color(col.r, col.g, col.b, wv * al * 0.22))
static func _dome_frame(s, c: Vector2, R: float, al: float, t: float, wave: float, hex: bool) -> void:
	for i in range(8):
		var u := float(i) / 7.0
		E.CI(s, c, R * (1.0 - u * 0.1), m(al * (0.02 + 0.035 * u)))
	E.AR(s, c, R, 0.0, TAU, 56, m(al * 0.35), 7.0)
	E.AR(s, c, R, 0.0, TAU, 56, m(al, 0.5), 2.2)
	E.AR(s, c, R - 2.0, -2.5, -0.6, 24, wh(al), 1.6)   # vệt phản chiếu
	E.ering(s, Vector2(c.x, GY - 4.0), R * 0.85, R * 0.22, m(al * 0.8, 0.4), 2.0)
	if hex:
		_hexgrid(s, c, R - 2.0, 13.0, al * 0.7, wave, t, m(1.0, 0.45))
## tl35 Kết Giới Thánh Quang: vòm cầu lục giác thánh quang tông mana, sóng gợn chạy dọc vòm.
static func _hexdome(s, t: float, lowq: bool) -> void:
	var fa := E.fadeo(t, 0.78)
	var gp := E.eo(E.sg(t, 0.0, 0.35))
	var R := 60.0 * gp + 4.0 * sin(t * 6.0) * (1.0 - gp)
	_dome_frame(s, GC, R, fa, t, E.sg(t, 0.15, 0.9), true)
	hg(s, GC, 70.0, Color(1.0, 0.94, 0.65, 1.0), fa * 0.2 * gp)
	E.flare(s, GC + Vector2(cos(-1.0), sin(-1.0)) * R, 8.0 * gp, fa)
	for i in range(0 if lowq else 8):
		var a := TAU * E.rnd(i, 1) + t * 2.0
		E.CI(s, GC + Vector2(cos(a), sin(a)) * R, 2.2, wh(fa * 0.9))
static func _hexdome_a(s, t: float, lowq: bool) -> void:
	var R := 60.0 + 1.5 * sin(t * 2.0)
	var wave := fmod(t, 1.8) / 1.8
	_dome_frame(s, GC, R, 0.85, t, wave, true)
	# gợn sóng định kỳ lan ra ngoài
	var rp := fmod(t, 1.8) / 1.8
	E.AR(s, GC, R + 16.0 * rp, 0.0, TAU, 48, m((1.0 - rp) * 0.6, 0.4), 2.2)
	hg(s, GC, 64.0, Color(1.0, 0.94, 0.65, 1.0), 0.1)
	for i in range(3 if lowq else 7):
		var a := TAU * E.rnd(i, 1) + t * 0.8
		E.CI(s, GC + Vector2(cos(a), sin(a)) * R, 2.0, wh(0.8))

## Khiên hình huy hiệu (kite shield) tại tâm p, cao h.
static func _kite(s, p: Vector2, h: float, al: float, bright: float) -> void:
	var w := h * 0.36
	var pts := PackedVector2Array([p + Vector2(0, -h * 0.5), p + Vector2(w, -h * 0.38), p + Vector2(w, h * 0.08), p + Vector2(w * 0.55, h * 0.3), p + Vector2(0, h * 0.5), p + Vector2(-w * 0.55, h * 0.3), p + Vector2(-w, h * 0.08), p + Vector2(-w, -h * 0.38)])
	hg(s, p, h * 0.85, m(1.0), al * 0.45 * bright)
	E.PG(s, pts, PackedColorArray([m(al, 0.55), m(al, 0.5), m(al, 0.15), m(al, 0.0), m(al, 0.0), m(al, 0.0), m(al, 0.15), m(al, 0.5)]))
	var inner := PackedVector2Array()
	for q in pts: inner.append(p + (q - p) * 0.78)
	E.PG(s, inner, PackedColorArray([m(al * 0.7, 0.85), m(al * 0.7, 0.7), m(al * 0.5, 0.35), m(al * 0.4, 0.2), m(al * 0.4, 0.1), m(al * 0.4, 0.2), m(al * 0.5, 0.35), m(al * 0.7, 0.7)]))
	var oc := pts.duplicate()
	oc.append(pts[0])
	E.PL(s, oc, wh(al), 2.2)
	var ic := inner.duplicate()
	ic.append(inner[0])
	E.PL(s, ic, m(al, 0.8), 1.2)
	plus(s, p + Vector2(0, -h * 0.04), h * 0.2, Color(1.0, 0.94, 0.6, 1.0), al)
## tl4 Khiên Ánh Sáng: tấm khiên huy hiệu tông mana hiện ra trước mặt, bọc quanh người bằng màng sáng mỏng.
static func _lightshield(s, t: float, lowq: bool) -> void:
	var fa := E.fadeo(t, 0.78)
	var gp := E.eo(E.sg(t, 0.0, 0.35))
	var R := 50.0 * gp
	E.AR(s, GC, R, 0.0, TAU, 44, m(fa * 0.25), 6.0)
	E.AR(s, GC, R, 0.0, TAU, 44, m(fa * 0.8, 0.5), 1.8)
	hg(s, GC, R * 1.2, m(1.0), fa * 0.18)
	var sp := E.eo(E.sg(t, 0.05, 0.4))
	_kite(s, Vector2(40.0 * sp, -6.0), 84.0 * sp, fa, 1.0)
	var rp := E.sg(t, 0.3, 0.9)
	E.AR(s, GC, R + 20.0 * E.eo(rp), 0.0, TAU, 44, m((1.0 - rp) * 0.7 * fa, 0.4), 2.0)
	for i in range(0 if lowq else 8):
		var ph := E.sg(t, 0.1 + 0.04 * float(i), 0.9)
		var a := TAU * E.rnd(i, 1)
		E.CI(s, GC + Vector2(cos(a), sin(a)) * (R + 24.0 * ph), 2.2 * (1.0 - ph) + 0.6, wh(fa * (1.0 - ph)))
static func _lightshield_a(s, t: float, lowq: bool) -> void:
	var R := 50.0
	E.AR(s, GC, R, 0.0, TAU, 44, m(0.2), 6.0)
	E.AR(s, GC, R, 0.0, TAU, 44, m(0.7, 0.5), 1.8)
	hg(s, GC, R * 1.2, m(1.0), 0.12)
	_kite(s, Vector2(38.0, -6.0 + sin(t * 2.4) * 3.0), 78.0, 0.95, 0.8)
	var rp := fmod(t, 1.6) / 1.6
	E.AR(s, GC, R + 18.0 * rp, 0.0, TAU, 44, m((1.0 - rp) * 0.6, 0.4), 2.0)
	for i in range(3 if lowq else 6):
		var a := TAU * float(i) / 6.0 + t * 0.7
		E.CI(s, GC + Vector2(cos(a), sin(a)) * R, 2.0, wh(0.85))
