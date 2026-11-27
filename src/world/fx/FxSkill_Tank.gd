extends RefCounted
## Hiệu ứng kỹ năng VẼ LẠI RIÊNG — tanker: khiên, thép, đất, thành lũy.
## Quy ước như FxSkill_Swordsman/Archer/Assassin: place "bodyf", gốc = thân nhân vật, +x = hướng nhìn, y âm = lên, mặt đất y~+32.
## hv25 (đạn đĩa khiên) vẽ ở FxProj.gd; ở đây chỉ có thế ném lúc tung.
const E := preload("res://src/world/fx/FxSkill_Swordsman.gd")

const IDS := {
	"hv25": "tkr_throw", "hv27": "tkr_bash", "tk1": "tkr_shieldbreak", "hv30": "tkr_wall", "hv32": "tkr_resolve",
	"hv35": "tkr_stomp", "tk6": "tkr_tremor", "hv37": "tkr_vortex", "tk2": "tkr_ring", "hv38": "tkr_bastion",
	"tk7": "tkr_keep", "ulTank1": "tkr_bronze", "ulTankSuper": "tkr_hexdome", "hv40": "tkr_march", "tk8": "tkr_charge",
	"hv42": "tkr_dragon", "hv45": "tkr_banner", "tk3": "tkr_rage", "tk4": "tkr_armor", "tk10": "tkr_thorns",
	"tk5": "tkr_steelwave", "tk9": "tkr_roar", "tk11": "tkr_hammer", "ulTank2": "tkr_worldquake",
}
const CFG := {
	"tkr_throw": {"place": "bodyf", "dur": 0.5, "nopop": true, "nobig": true},
	"tkr_bash": {"place": "bodyf", "dur": 0.9, "nopop": true, "nobig": true},
	"tkr_shieldbreak": {"place": "bodyf", "dur": 0.9, "nopop": true, "nobig": true},
	"tkr_wall": {"place": "bodyf", "dur": 1.4, "nopop": true, "nobig": true},
	"tkr_resolve": {"place": "bodyf", "dur": 1.4, "nopop": true, "nobig": true},
	"tkr_stomp": {"place": "bodyf", "dur": 1.1, "nopop": true, "nobig": true, "rumble": 4.0},
	"tkr_tremor": {"place": "bodyf", "dur": 1.2, "nopop": true, "nobig": true, "rumble": 3.0},
	"tkr_vortex": {"place": "bodyf", "dur": 1.1, "nopop": true, "nobig": true},
	"tkr_ring": {"place": "bodyf", "dur": 0.9, "nopop": true, "nobig": true},
	"tkr_bastion": {"place": "bodyf", "dur": 1.4, "nopop": true, "nobig": true},
	"tkr_keep": {"place": "bodyf", "dur": 1.5, "nopop": true, "nobig": true},
	"tkr_bronze": {"place": "bodyf", "dur": 1.5, "nopop": true, "nobig": true},
	"tkr_hexdome": {"place": "bodyf", "dur": 1.6, "nopop": true, "nobig": true},
	"tkr_march": {"place": "bodyf", "dur": 0.9, "nopop": true, "nobig": true},
	"tkr_charge": {"place": "bodyf", "dur": 0.9, "nopop": true, "nobig": true},
	"tkr_dragon": {"place": "bodyf", "dur": 1.5, "nopop": true, "nobig": true, "rumble": 5.0},
	"tkr_banner": {"place": "bodyf", "dur": 1.5, "nopop": true, "nobig": true},
	"tkr_rage": {"place": "bodyf", "dur": 1.4, "nopop": true, "nobig": true},
	"tkr_armor": {"place": "bodyf", "dur": 1.4, "nopop": true, "nobig": true},
	"tkr_thorns": {"place": "bodyf", "dur": 1.4, "nopop": true, "nobig": true},
	"tkr_steelwave": {"place": "bodyf", "dur": 1.3, "nopop": true, "nobig": true, "rumble": 5.0},
	"tkr_roar": {"place": "bodyf", "dur": 1.1, "nopop": true, "nobig": true},
	"tkr_hammer": {"place": "bodyf", "dur": 1.3, "nopop": true, "nobig": true, "rumble": 5.0},
	"tkr_worldquake": {"place": "bodyf", "dur": 1.8, "nopop": true, "nobig": true, "rumble": 10.0},
}
## Buff / hộ thể kéo dài: hào quang giữ nguyên suốt thời gian hiệu lực.
const AURA_IDS := ["tkr_wall", "tkr_resolve", "tkr_bastion", "tkr_keep", "tkr_bronze", "tkr_hexdome", "tkr_banner", "tkr_rage", "tkr_armor", "tkr_thorns"]

static func draw(s, sg: String, t: float, lowq: bool) -> void:
	match sg:
		"tkr_throw": _throw(s, t, lowq)
		"tkr_bash": _bash(s, t, lowq, 2, false)
		"tkr_shieldbreak": _bash(s, t, lowq, 1, true)
		"tkr_wall": _wall(s, t, lowq)
		"tkr_resolve": _resolve(s, t, lowq)
		"tkr_stomp": _stomp(s, t, lowq)
		"tkr_tremor": _tremor(s, t, lowq)
		"tkr_vortex": _vortex(s, t, lowq)
		"tkr_ring": _ring(s, t, lowq)
		"tkr_bastion": _bastion(s, t, lowq)
		"tkr_keep": _keep(s, t, lowq)
		"tkr_bronze": _bronze(s, t, lowq)
		"tkr_hexdome": _hexdome(s, t, lowq)
		"tkr_march": _march(s, t, lowq)
		"tkr_charge": _charge(s, t, lowq)
		"tkr_dragon": _dragon(s, t, lowq)
		"tkr_banner": _banner(s, t, lowq)
		"tkr_rage": _rage(s, t, lowq)
		"tkr_armor": _armor(s, t, lowq)
		"tkr_thorns": _thorns(s, t, lowq)
		"tkr_steelwave": _steelwave(s, t, lowq)
		"tkr_roar": _roar(s, t, lowq)
		"tkr_hammer": _hammer(s, t, lowq)
		"tkr_worldquake": _worldquake(s, t, lowq)
		_: pass

static func draw_aura(s, sg: String, t: float, lowq: bool) -> void:
	var tt := 1.0 + t
	match sg:
		"tkr_wall": _wall(s, tt, lowq)
		"tkr_resolve": _resolve(s, tt, lowq)
		"tkr_bastion": _bastion(s, tt, lowq)
		"tkr_keep": _keep(s, tt, lowq)
		"tkr_bronze": _bronze(s, tt, lowq)
		"tkr_hexdome": _hexdome(s, tt, lowq)
		"tkr_banner": _banner(s, tt, lowq)
		"tkr_rage": _rage(s, tt, lowq)
		"tkr_armor": _armor(s, tt, lowq)
		"tkr_thorns": _thorns(s, tt, lowq)
		_: pass

# ============================================================ tiện ích
const GY := 32.0
const ROCK := Color(0.5, 0.44, 0.38)
const STEEL := Color(0.72, 0.78, 0.88)
const STEEL_D := Color(0.3, 0.35, 0.44)
const BRONZE := Color(0.82, 0.52, 0.2)
const COLD := Color(0.66, 0.78, 0.95)
const STONE := Color(0.6, 0.62, 0.68)
const GREEN := Color(0.45, 1.0, 0.55)
const RED := Color(1.0, 0.32, 0.2)

static func C(c: Color, a: float) -> Color:
	return Color(c.r, c.g, c.b, clampf(a, 0.0, 1.0))

static func tone(c: Color, k: float, a: float) -> Color:
	return Color(minf(1.0, c.r * k), minf(1.0, c.g * k), minf(1.0, c.b * k), clampf(a, 0.0, 1.0))

## Khiên tam giác bo (heater): viền thép, mặt màu chủ đạo, nửa sáng/nửa tối, núm giữa. sx/sy co theo chiều ngang/dọc (nghiêng nhìn cạnh).
## mark: 0 trơn, 1 thập tự, 2 kiếm.
static func shield(s, c: Vector2, sz: float, ang: float, al: float, sx: float = 1.0, sy: float = 1.0, mark: int = 0) -> void:
	if al <= 0.01 or sz < 4.0: return
	sx = maxf(absf(sx), 0.14)
	var base := PackedVector2Array([Vector2(-0.8, -0.95), Vector2(0, -1.1), Vector2(0.8, -0.95), Vector2(0.8, 0.1), Vector2(0.45, 0.7), Vector2(0, 1.1), Vector2(-0.45, 0.7), Vector2(-0.8, 0.1)])
	var o := PackedVector2Array()
	var f := PackedVector2Array()
	for v in base:
		var q := Vector2(v.x * sx, v.y * sy) * sz
		o.append(c + q.rotated(ang))
		f.append(c + (q * 0.8).rotated(ang))
	E.P(s, o, C(STEEL, 0.7 * al))
	E.P(s, f, Color(0.2, 0.3, 0.55, 0.9 * al))
	E.P(s, PackedVector2Array([f[1], f[2], f[3], f[4], f[5]]), K(s, 0.3 * al))
	E.P(s, PackedVector2Array([f[0], f[1], f[5], f[6], f[7]]), Color(0, 0, 0, 0.3 * al))
	var oc := o.duplicate()
	oc.append(o[0])
	E.PL(s, oc, K(s, al), 1.4)
	var ctr := c
	var ux := Vector2(cos(ang), sin(ang))
	var uy := Vector2(-sin(ang), cos(ang))
	var hx := ux * sz * sx
	var hy := uy * sz * sy
	if mark == 1:
		E.L(s, ctr - hy * 0.62, ctr + hy * 0.7, K(s, 0.85 * al), 2.0)
		E.L(s, ctr - hx * 0.55 - hy * 0.2, ctr + hx * 0.55 - hy * 0.2, K(s, 0.85 * al), 2.0)
	elif mark == 2:
		E.L(s, ctr - hy * 0.7, ctr + hy * 0.5, K(s, 0.9 * al), 2.2)
		E.L(s, ctr - hx * 0.4 - hy * 0.25, ctr + hx * 0.4 - hy * 0.25, K(s, 0.9 * al), 2.2)
	E.CI(s, ctr, maxf(2.0, sz * 0.2 * sx), E.M(s, 0.4, al))
	E.CI(s, ctr - ux * sz * 0.03, maxf(1.0, sz * 0.09 * sx), K(s, al))
	if sz > 14.0:
		for i in [0, 2, 3, 6, 7]:
			E.CI(s, o[i].lerp(ctr, 0.12), 1.3, K(s, 0.7 * al))

static func A(s, al: float) -> Color: return E.A(s, al)
static func K(s, al: float) -> Color: return E.K(s, al)

## Vệt mờ (đuôi chuyển động) nằm ngang từ x0 → x1.
static func mtrail(s, x0: float, x1: float, y: float, w: float, al: float) -> void:
	if al <= 0.01 or absf(x1 - x0) < 3.0: return
	E.PG(s, PackedVector2Array([Vector2(x0, y - w), Vector2(x1, y - w * 0.6), Vector2(x1, y + w * 0.6), Vector2(x0, y + w)]), PackedColorArray([A(s, 0.0), A(s, al * 0.55), A(s, al * 0.55), A(s, 0.0)]))
	E.PG(s, PackedVector2Array([Vector2(x0, y - w * 0.35), Vector2(x1, y - w * 0.2), Vector2(x1, y + w * 0.2), Vector2(x0, y + w * 0.35)]), PackedColorArray([K(s, 0.0), K(s, al * 0.8), K(s, al * 0.8), K(s, 0.0)]))

## Đá vụn.
static func rock(s, p: Vector2, r: float, ang: float, al: float) -> void:
	if al <= 0.02 or r < 1.5: return
	var pts := PackedVector2Array()
	for i in range(6):
		var a := ang + TAU * float(i) / 6.0
		var rr := r * (0.75 + 0.5 * E.rnd(i, 11))
		pts.append(p + Vector2(cos(a), sin(a)) * rr)
	E.P(s, pts, C(ROCK, 0.95 * al))
	E.P(s, PackedVector2Array([pts[0], pts[1], pts[2], p]), C(Color(0.85, 0.78, 0.68), 0.5 * al))

## Gai đá/thép nhọn dựng lên từ mặt đất.
static func spike(s, b: Vector2, w: float, h: float, lean: float, al: float, col: Color = ROCK) -> void:
	if al <= 0.02 or h < 3.0: return
	var tip := b + Vector2(lean, -h)
	E.P(s, PackedVector2Array([b + Vector2(-w, 0), tip, b + Vector2(w, 0)]), C(col, 0.95 * al))
	E.P(s, PackedVector2Array([b + Vector2(0, 0), tip, b + Vector2(w, 0)]), K(s, 0.4 * al))
	E.L(s, b + Vector2(-w * 0.4, 0), tip, K(s, 0.8 * al), 1.0)

## Mảnh đá bay lên rồi rơi (parabol). t0..t1 là đoạn thời gian bay.
static func rocks(s, c: Vector2, n: int, spread: float, hmax: float, t: float, t0: float, t1: float, al: float, seed: int = 0) -> void:
	for i in range(n):
		var u := E.sg(t, t0 + 0.06 * E.rnd(i, seed + 1), t1)
		if u <= 0.0 or u >= 1.0: continue
		var x := (E.rnd(i, seed) - 0.5) * 2.0 * spread
		var hh := hmax * (0.45 + 0.55 * E.rnd(i, seed + 2))
		var p := c + Vector2(x * (0.5 + 0.5 * u), -hh * 4.0 * u * (1.0 - u))
		rock(s, p, 3.5 + 6.0 * E.rnd(i, seed + 3), u * 6.0 * (E.rnd(i, seed + 4) - 0.5) * 2.0, al * (1.0 - E.sg(u, 0.85, 1.0)))

## Vòng gợn răng cưa (sóng âm / sóng nén).
static func jag(s, c: Vector2, rx: float, ry: float, n: int, amp: float, col: Color, w: float, rot: float = 0.0) -> void:
	if rx < 3.0 or ry < 1.0: return
	var pts := PackedVector2Array()
	for i in range(n * 2 + 1):
		var a := TAU * float(i) / float(n * 2) + rot
		var k := 1.0 + (amp if i % 2 == 0 else -amp) / rx
		pts.append(c + Vector2(cos(a) * rx * k, sin(a) * ry * k))
	E.PL(s, pts, col, w)

static func plus(s, p: Vector2, sz: float, al: float) -> void:
	if al <= 0.02 or sz < 2.0: return
	var a := sz * 0.34
	E.P(s, PackedVector2Array([p + Vector2(-a, -sz), p + Vector2(a, -sz), p + Vector2(a, -a), p + Vector2(sz, -a), p + Vector2(sz, a), p + Vector2(a, a), p + Vector2(a, sz), p + Vector2(-a, sz), p + Vector2(-a, a), p + Vector2(-sz, a), p + Vector2(-sz, -a), p + Vector2(-a, -a)]), C(GREEN, 0.9 * al))
	E.L(s, p + Vector2(0, -sz * 0.6), p + Vector2(0, sz * 0.6), Color(1, 1, 1, 0.85 * al), 1.4)
	E.L(s, p + Vector2(-sz * 0.6, 0), p + Vector2(sz * 0.6, 0), Color(1, 1, 1, 0.85 * al), 1.4)

static func chev(s, p: Vector2, sz: float, al: float) -> void:
	if al <= 0.02: return
	var pts := PackedVector2Array([p + Vector2(-sz, sz * 0.5), p + Vector2(0, -sz * 0.5), p + Vector2(sz, sz * 0.5)])
	E.PL(s, pts, A(s, 0.5 * al), 5.0)
	E.PL(s, pts, K(s, al), 2.0)

## Tường thành có lỗ châu mai: x0..x1, đáy yb, cao h, mer lỗ châu mai, màu gạch col.
static func wall(s, x0: float, x1: float, yb: float, h: float, mer: int, al: float, col: Color) -> void:
	if al <= 0.01 or x1 - x0 < 6.0 or h < 6.0: return
	var top := yb - h
	var cl := tone(col, 1.15, 0.95 * al)
	var cd := tone(col, 0.6, 0.95 * al)
	E.PG(s, PackedVector2Array([Vector2(x0, top), Vector2(x1, top), Vector2(x1, yb), Vector2(x0, yb)]), PackedColorArray([cl, cl, cd, cd]))
	# lỗ châu mai
	var mw := (x1 - x0) / float(mer * 2 - 1)
	var mh := minf(h * 0.2, 14.0)
	for i in range(mer):
		var mx := x0 + float(i) * 2.0 * mw
		E.PG(s, PackedVector2Array([Vector2(mx, top - mh), Vector2(mx + mw, top - mh), Vector2(mx + mw, top), Vector2(mx, top)]), PackedColorArray([cl, cl, tone(col, 0.9, 0.95 * al), tone(col, 0.9, 0.95 * al)]))
		E.PL(s, PackedVector2Array([Vector2(mx, top), Vector2(mx, top - mh), Vector2(mx + mw, top - mh), Vector2(mx + mw, top)]), K(s, 0.7 * al), 1.1)
	# gạch
	var rows := maxi(2, int(h / 12.0))
	for r in range(1, rows):
		var y := top + h * float(r) / float(rows)
		E.L(s, Vector2(x0, y), Vector2(x1, y), Color(0, 0, 0, 0.3 * al), 1.0)
		var off := 0.0 if r % 2 == 0 else 7.0
		var x := x0 + off
		while x < x1 - 2.0:
			E.L(s, Vector2(x, y), Vector2(x, y + h / float(rows)), Color(0, 0, 0, 0.22 * al), 1.0)
			x += 15.0
	E.PL(s, PackedVector2Array([Vector2(x0, yb), Vector2(x0, top), Vector2(x1, top), Vector2(x1, yb)]), K(s, 0.85 * al), 1.4)
	E.L(s, Vector2(x0 + 1, top + 2), Vector2(x1 - 1, top + 2), K(s, 0.45 * al), 1.4)

## Vòm cổng (cổng thành) với hai cánh cửa đinh tán.
static func gate(s, cx: float, yb: float, w: float, h: float, al: float, col: Color) -> void:
	if al <= 0.01 or w < 10.0: return
	var pts := PackedVector2Array([Vector2(cx - w, yb)])
	for i in range(0, 13):
		var a := PI - PI * float(i) / 12.0
		pts.append(Vector2(cx + cos(a) * w, yb - h + w - sin(a) * w * 0.0 - sin(a) * w))
	pts.append(Vector2(cx + w, yb))
	E.P(s, pts, Color(0.08, 0.05, 0.04, 0.9 * al))
	E.PL(s, pts, K(s, 0.9 * al), 1.6)
	# hai cánh cửa
	for sd in [-1.0, 1.0]:
		var x0: float = cx + sd * 1.0
		var x1: float = cx + sd * (w - 3.0)
		E.PG(s, PackedVector2Array([Vector2(x0, yb - h + w * 0.2), Vector2(x1, yb - h + w * 0.6), Vector2(x1, yb), Vector2(x0, yb)]), PackedColorArray([tone(col, 1.1, 0.95 * al), tone(col, 0.9, 0.95 * al), tone(col, 0.55, 0.95 * al), tone(col, 0.7, 0.95 * al)]))
		for k in range(3):
			for j in range(2):
				E.CI(s, Vector2(lerpf(x0, x1, 0.25 + 0.5 * float(k) / 2.0), yb - h * (0.18 + 0.28 * float(j))), 1.5, K(s, 0.85 * al))
	E.L(s, Vector2(cx, yb - h + w * 0.15), Vector2(cx, yb), K(s, 0.6 * al), 1.4)

## Cờ lượn sóng: cột từ gốc b hướng lên, cờ rộng w cao h.
static func flag(s, b: Vector2, pole: float, w: float, h: float, t: float, al: float, col: Color) -> void:
	E.L(s, b, b + Vector2(0, -pole), Color(0.5, 0.42, 0.3, al), 3.0)
	E.L(s, b + Vector2(-1, 0), b + Vector2(-1, -pole), K(s, 0.5 * al), 1.0)
	E.P(s, PackedVector2Array([b + Vector2(-3, -pole), b + Vector2(0, -pole - 11), b + Vector2(3, -pole)]), K(s, al))
	var top := PackedVector2Array()
	var bot := PackedVector2Array()
	var n := 10
	for i in range(n + 1):
		var u := float(i) / float(n)
		var wv := sin(u * 5.0 - t * 9.0) * 5.0 * u
		top.append(b + Vector2(3.0 + w * u, -pole + 4.0 + wv))
		bot.append(b + Vector2(3.0 + w * u * 0.96, -pole + 4.0 + h * (1.0 - 0.18 * u) + wv))
	for i in range(n):
		var sh := 0.85 + 0.15 * sin(float(i) * 1.7 - t * 9.0)
		E.PG(s, PackedVector2Array([top[i], top[i + 1], bot[i + 1], bot[i]]), PackedColorArray([tone(col, sh, 0.95 * al), tone(col, sh, 0.95 * al), tone(col, sh * 0.8, 0.95 * al), tone(col, sh * 0.8, 0.95 * al)]))
	E.PL(s, top, K(s, 0.8 * al), 1.2)
	E.PL(s, bot, K(s, 0.5 * al), 1.0)

## Sàn đất: gốc dưới chân, trải đúng bán kính.
static func gc() -> Vector2:
	return Vector2(0, GY - 6.0)

# ============================================================ ĐÒN ĐÁNH / ĐẠN
## hv25 Khiên Phi Trảm (lúc tung): vung tay, ném đĩa khiên bay vọt ra trước.
static func _throw(s, t: float, lowq: bool) -> void:
	var fa := E.fadeo(t, 0.6)
	var p := E.eo(E.sg(t, 0.0, 0.4))
	E.swoosh(s, Vector2(-6, -6), 44.0, -1.7, 0.5, p, 0.8, 16.0, fa * 0.9, 0.9)
	var x := 20.0 + 100.0 * p
	mtrail(s, 10.0, x, -8.0, 14.0, (1.0 - E.sg(t, 0.35, 0.6)) * 0.8)
	var lf := 1.0 - E.sg(t, 0.4, 0.6)
	shield(s, Vector2(x, -8.0), 17.0, t * 26.0, lf, 0.55 + 0.45 * absf(cos(t * 30.0)), 0.9, 1)
	E.speedlines(s, 10.0, 140.0, -22.0, 10.0, 6, fa * 0.8, 3)
	E.flare(s, Vector2(14, -8), 12.0 * (1.0 - E.sg(t, 0.0, 0.3)), fa)

## hv27 Thuẫn Kích (2 nhát, nhát cuối mạnh hơn, đẩy lùi) / tk1 Khiên Phá (1 nhát, khiên nứt vỡ, hất văng xa).
static func _bash(s, t: float, lowq: bool, hits: int, brk: bool) -> void:
	var rng := 110.0 if brk else 120.0
	var fa := E.fadeo(t, 0.78)
	for k in range(hits):
		var t0 := 0.08 + 0.34 * float(k)
		var q := E.sg(t, t0, t0 + 0.14)
		if q <= 0.0: continue
		var big := brk or (hits > 1 and k == hits - 1)
		var sz := 26.0 + (10.0 if big else 0.0)
		var back := E.sg(t, t0 + 0.2, t0 + 0.36)
		var x := 24.0 + (rng - 60.0) * E.eo(q) - 36.0 * E.eo(back)
		var life := 1.0 - E.sg(t, t0 + 0.3, t0 + 0.46)
		var hs := E.sg(t, t0 + 0.14, t0 + 0.55)
		if brk:
			life = 1.0 - E.sg(t, t0 + 0.2, t0 + 0.26)
		mtrail(s, x - 56.0, x - 6.0, -6.0, sz * 0.7, (1.0 - E.sg(q, 0.9, 1.0)) * 0.9 * fa)
		var sh_ang := 0.0
		shield(s, Vector2(x, -6.0), sz, sh_ang, life * maxf(fa, 0.0), 0.62, 1.0, 1)
		if brk and q >= 1.0 and life > 0.0:
			var cp := Vector2(x + 2.0, -6.0)
			for j in range(5):
				var a := -1.2 + 0.6 * float(j) + 0.2 * (E.rnd(j, 4) - 0.5)
				var pts := PackedVector2Array([cp])
				var pp := cp
				for m in range(1, 4):
					pp += Vector2(cos(a) * 0.5, sin(a)) * 9.0 + Vector2((E.rnd(j * 4 + m, 5) - 0.5) * 6.0, 0)
					pts.append(pp)
				E.PL(s, pts, K(s, E.sg(t, t0 + 0.14, t0 + 0.18) * fa), 1.6)
		if q >= 1.0:
			var ix := rng * 0.86
			var ia := (1.0 - hs) * fa
			E.star(s, Vector2(ix, -6.0), (28.0 if big else 20.0) * (1.0 - hs * 0.5), ia, 8)
			for j in range(3):
				var rr := 14.0 + (22.0 + 12.0 * float(j)) * E.eo(hs)
				E.AR(s, Vector2(ix - 16.0, -6.0), rr, -0.85, 0.85, 14, A(s, ia * (0.9 - 0.2 * float(j))), 3.0 - 0.7 * float(j))
			E.speedlines(s, ix, ix + (170.0 if brk else (130.0 if big else 80.0)), -34.0, 28.0, 8 if big else 5, ia, k)
			E.dust(s, Vector2(ix, GY - 2.0), 30.0 if big else 20.0, hs, ia, 6, k + 2)
			E.spark(s, Vector2(ix, -6.0), 6 if lowq else (14 if big else 8), 56.0, hs, ia, k + 4)
		if brk and q >= 1.0:
			# mảnh khiên vỡ văng ra
			var sh := E.sg(t, t0 + 0.2, t0 + 0.7)
			if sh > 0.0:
				for i in range(8 if not lowq else 5):
					var a := -1.3 + 2.6 * E.rnd(i, 6)
					var d := 80.0 * E.eo(sh) * (0.5 + E.rnd(i, 7))
					var p := Vector2(x + cos(a) * d, -6.0 + sin(a) * d * 0.7 + 50.0 * sh * sh)
					var r := 5.0 + 6.0 * E.rnd(i, 8)
					var an := sh * 8.0 * (E.rnd(i, 9) - 0.5)
					E.P(s, PackedVector2Array([p + Vector2(cos(an), sin(an)) * r, p + Vector2(cos(an + 2.3), sin(an + 2.3)) * r * 0.8, p + Vector2(cos(an + 4.1), sin(an + 4.1)) * r * 0.6]), C(STEEL, (1.0 - sh) * fa))
					E.L(s, p, p + Vector2(cos(an + 0.8), sin(an + 0.8)) * r * 0.7, A(s, (1.0 - sh) * fa), 1.2)

# ============================================================ HỘ THỂ (guard) / BUFF
## hv30 Thuẫn Trận Phản Chấn (7s): hàng khiên tháp dựng sừng sững phía trước trên trận rune; mỗi lần phản đòn một gợn sóng bật ra, mũi tên tấn công bay lên.
static func _wall(s, t: float, lowq: bool) -> void:
	var up := E.eo(E.sg(t, 0.0, 0.3))
	var al := E.fo(s, t, 0.85)
	var g := gc()
	# trận rune dưới chân
	E.ering(s, g, 68.0 * up, 17.0 * up, A(s, 0.3 * al), 8.0)
	E.ering(s, g, 68.0 * up, 17.0 * up, A(s, 0.9 * al), 2.2)
	E.ering(s, g, 46.0 * up, 11.5 * up, K(s, 0.6 * al), 1.4, 0.0)
	for i in range(6):
		var a := TAU * float(i) / 6.0 + t * 0.9
		var b := TAU * float((i + 2) % 6) / 6.0 + t * 0.9
		E.L(s, g + Vector2(cos(a) * 46.0 * up, sin(a) * 11.5 * up), g + Vector2(cos(b) * 46.0 * up, sin(b) * 11.5 * up), A(s, 0.5 * al), 1.2)
		var pp := g + Vector2(cos(a) * 68.0 * up, sin(a) * 17.0 * up)
		E.P(s, PackedVector2Array([pp + Vector2(-2.6, 0), pp + Vector2(0, -11.0), pp + Vector2(2.6, 0)]), K(s, 0.8 * al))
	# bụi khi khiên trồi lên
	E.dust(s, Vector2(60.0, GY - 2.0), 40.0, E.sg(t, 0.0, 0.5), (1.0 - E.sg(t, 0.15, 0.55)) * 0.9, 7, 1)
	# 4 khiên tháp trồi lên từng cái
	for k in range(4):
		var u := E.eo(E.sg(t, 0.03 + 0.06 * float(k), 0.3 + 0.06 * float(k)))
		var cx := 40.0 + 24.0 * float(k)
		var cy := -8.0 + (1.0 - u) * 80.0 + 1.5 * float(k)
		shield(s, Vector2(cx, cy), 27.0, 0.0, al * u, 0.95, 1.55, 1 if k % 2 == 0 else 2)
	# phản chấn: gợn sóng từ hàng khiên bật ra + tia lửa
	var ph := fmod(t * 1.2, 1.0)
	if t > 0.3 or al >= 1.0:
		for j in range(2):
			var pj := fmod(ph + 0.5 * float(j), 1.0)
			E.AR(s, Vector2(60.0, -8.0), 40.0 + 90.0 * pj, -0.7, 0.7, 16, A(s, (1.0 - pj) * 0.85 * al), 3.0)
			E.AR(s, Vector2(60.0, -8.0), 36.0 + 90.0 * pj, -0.6, 0.6, 16, K(s, (1.0 - pj) * 0.6 * al), 1.2)
		E.spark(s, Vector2(100.0, -8.0), 5, 30.0, ph, (1.0 - ph) * al, 3)
	# mũi tên "tăng tấn công" bay lên bên người
	for k in range(2):
		var pu := fmod(t * 0.9 + 0.5 * float(k), 1.0)
		chev(s, Vector2(-16.0 + 10.0 * float(k), 18.0 - 52.0 * pu), 5.0, sin(pu * PI) * al * 0.9)

## hv32 Ý Chí Hộ Vệ (10s): khiên nhỏ xoay quanh người, dấu cộng xanh lục hồi máu bay lên theo nhịp.
static func _resolve(s, t: float, lowq: bool) -> void:
	var up := E.eo(E.sg(t, 0.0, 0.25))
	var al := E.fo(s, t, 0.85) * up
	var g := gc()
	E.ering(s, g, 44.0 * up, 11.0 * up, C(GREEN, 0.28 * al), 7.0)
	E.ering(s, g, 44.0 * up, 11.0 * up, C(GREEN, 0.85 * al), 2.0)
	E.glow(s, Vector2(0, -6), 40.0 * up, 0.14 * al)
	# khiên nhỏ xoay (vẽ sau lưng trước, trước mặt sau)
	var n := 3
	for pass_i in range(2):
		for k in range(n):
			var a := TAU * float(k) / float(n) + t * 2.6
			var front := sin(a) > 0.0
			if (pass_i == 0) == front: continue
			var p := Vector2(cos(a) * 36.0 * up, -6.0 + sin(a) * 12.0)
			var depth := 0.6 + 0.4 * (sin(a) * 0.5 + 0.5)
			var sx := 0.35 + 0.65 * absf(sin(a))
			# vệt xoay phía sau
			var tl := PackedVector2Array()
			for q in range(8):
				var aa := a - 0.12 * float(q)
				tl.append(Vector2(cos(aa) * 36.0 * up, -6.0 + sin(aa) * 12.0))
			E.PL(s, tl, A(s, 0.3 * al * depth), 4.0)
			shield(s, p, 11.0, 0.0, al * depth, sx, 1.0, 1)
	# dấu cộng hồi máu bay lên theo nhịp
	for k in range(5 if not lowq else 3):
		var ph := fmod(t * 0.8 + 0.2 * float(k), 1.0)
		var px := (E.rnd(k, 1) - 0.5) * 40.0
		plus(s, Vector2(px, 20.0 - 62.0 * ph), 5.0 + 2.0 * E.rnd(k, 2), sin(ph * PI) * al)
	var pulse := fmod(t * 1.0, 1.0)
	E.AR(s, Vector2(0, -6), 14.0 + 44.0 * pulse, 0.0, TAU, 40, C(GREEN, (1.0 - pulse) * 0.5 * al), 2.0)
	# tăng công: mũi tên bay lên ở hai bên
	for k in range(2):
		var pu := fmod(t * 0.7 + 0.5 * float(k), 1.0)
		chev(s, Vector2(-24.0 + 48.0 * float(k), 16.0 - 44.0 * pu), 4.5, sin(pu * PI) * al * 0.8)

# ============================================================ ĐẤT
## hv35 Chấn Địa (r220, làm chậm): dậm đất — gai đá trồi quanh vòng, đất nứt phát sáng, sóng nén lan, đá vụn văng.
static func _stomp(s, t: float, lowq: bool) -> void:
	var R := 220.0
	var fa := E.fadeo(t, 0.72)
	var e := E.eo(E.sg(t, 0.0, 0.4))
	var g := gc()
	# điểm giáng: tia sáng + sóng nén
	E.flare(s, Vector2(0, GY - 4.0), 20.0 * (1.0 - E.sg(t, 0.0, 0.3)), 1.0 - E.sg(t, 0.0, 0.3))
	E.shock(s, g, R * e, R * e * 0.24, fa)
	E.shock(s, g, R * e * 0.55, R * e * 0.13, fa * 0.6)
	E.crack(s, g, R * e, fa * E.sg(t, 0.0, 0.12), 1)
	# gai đá trồi quanh vòng 0.7R
	var n := 7 if lowq else 12
	for i in range(n):
		var a := TAU * (float(i) + 0.4 * E.rnd(i, 2)) / float(n)
		var rr := R * (0.45 + 0.4 * E.rnd(i, 3))
		var p := g + Vector2(cos(a) * rr, sin(a) * rr * 0.26)
		var pop := E.sg(t, 0.1 + 0.012 * float(i), 0.34 + 0.012 * float(i))
		var gone := 1.0 - E.sg(t, 0.62, 0.9)
		spike(s, p, 6.0 + 5.0 * E.rnd(i, 4), (24.0 + 30.0 * E.rnd(i, 5)) * E.eo(pop) * gone, (E.rnd(i, 6) - 0.5) * 8.0, fa + 0.0 if gone > 0.0 else 0.0)
	rocks(s, Vector2(0, GY - 4.0), 5 if lowq else 12, R * 0.8, 90.0, t, 0.08, 0.7, fa, 3)
	E.dust(s, Vector2(0, GY - 2.0), R * 0.7, E.sg(t, 0.0, 0.7), fa * 0.9, 8 if lowq else 14, 5)
	# làm chậm: dấu xích nặng dưới chân quái (vòng ngoài)
	for i in range(0 if lowq else 10):
		var a2 := TAU * E.rnd(i, 8)
		var r2 := R * (0.4 + 0.55 * E.rnd(i, 9)) * e
		var p2 := g + Vector2(cos(a2) * r2, sin(a2) * r2 * 0.26)
		E.AR(s, p2, 4.5, 0.0, TAU, 10, A(s, 0.5 * fa * E.sg(t, 0.3, 0.5)), 1.6)

## tk6 Địa Chấn (r220): mặt sàn rung — các tấm đá lát nền nhấp nhô thành sóng lan ra theo vòng, bụi cuộn.
static func _tremor(s, t: float, lowq: bool) -> void:
	var R := 220.0
	var fa := E.fadeo(t, 0.75)
	var g := gc()
	var e := E.eo(E.sg(t, 0.0, 0.5))
	E.ering(s, g, R * e, R * e * 0.26, A(s, 0.35 * fa), 12.0)
	E.ering(s, g, R * e, R * e * 0.26, A(s, 0.9 * fa), 2.4)
	var rings := 5
	for k in range(rings):
		var rk := 46.0 + (R - 46.0) * float(k) / float(rings - 1)
		var arrive := 0.04 + 0.12 * float(k)
		var wave := E.sg(t, arrive, arrive + 0.34)
		var lift := sin(wave * PI) * (20.0 - 2.5 * float(k))
		var cnt := 5 + 2 * k
		if lowq: cnt = int(float(cnt) * 0.6)
		for i in range(cnt):
			var a := TAU * (float(i) + 0.5 * float(k % 2)) / float(cnt)
			var cx := g.x + cos(a) * rk
			var cy := g.y + sin(a) * rk * 0.26 - lift
			var w := 8.0 + 1.5 * float(k)
			var h := 4.0 + 1.5 * float(k) * 0.4
			var lit := 0.7 + 0.3 * sin(a * 2.0)
			# mặt trên + mặt bên của tấm đá
			E.P(s, PackedVector2Array([Vector2(cx - w, cy), Vector2(cx - w * 0.8, cy - h), Vector2(cx + w * 0.8, cy - h), Vector2(cx + w, cy)]), tone(ROCK, 1.3 * lit, 0.92 * fa))
			E.P(s, PackedVector2Array([Vector2(cx - w, cy), Vector2(cx + w, cy), Vector2(cx + w, cy + 4.0 + lift * 0.4), Vector2(cx - w, cy + 4.0 + lift * 0.4)]), tone(ROCK, 0.6, 0.92 * fa))
			E.L(s, Vector2(cx - w * 0.8, cy - h), Vector2(cx + w * 0.8, cy - h), K(s, 0.6 * fa * sin(wave * PI)), 1.2)
	# vết nứt mảnh giữa các tấm + bụi bốc lên
	E.crack(s, g, R * 0.75 * e, fa * 0.6, 4)
	E.dust(s, Vector2(0, GY - 2.0), R * 0.8, E.sg(t, 0.0, 0.8), fa * 0.85, 8 if lowq else 14, 2)
	rocks(s, Vector2(0, GY - 4.0), 4 if lowq else 9, R * 0.9, 42.0, t, 0.1, 0.6, fa, 7)

## hv42 Phản Chấn Địa Long (r280, làm chậm): địa long đá trồi lên từ đất, ngẩng đầu gầm, sóng chấn lan; thân cuộn ngầm sau lưng.
static func _dragon(s, t: float, lowq: bool) -> void:
	var R := 280.0
	var fa := E.fadeo(t, 0.78)
	var g := gc()
	var u := E.eo(E.sg(t, 0.04, 0.45))
	var down := E.sg(t, 0.72, 1.0)
	var al := fa
	# sóng chấn
	var e := E.eo(E.sg(t, 0.35, 0.85))
	E.shock(s, g, R * e, R * e * 0.24, (1.0 - E.sg(t, 0.35, 0.95)))
	E.crack(s, Vector2(70.0, GY - 4.0), 120.0 * E.eo(E.sg(t, 0.0, 0.3)), al, 3)
	# thân cuộn ngầm: các gò đá chạy trong đất phía sau
	for i in range(4):
		var hx := 10.0 - 62.0 * float(i)
		var ho := E.sg(t, 0.12 + 0.07 * float(i), 0.4 + 0.07 * float(i)) * (1.0 - E.sg(t, 0.7 + 0.04 * float(i), 1.0))
		var hr := 30.0 - 4.0 * float(i)
		if ho > 0.02:
			var pts := PackedVector2Array()
			for k in range(13):
				var a := PI * float(k) / 12.0
				pts.append(Vector2(hx + cos(a) * hr * 1.5, GY - 4.0 - sin(a) * hr * ho))
			E.P(s, pts, tone(ROCK, 0.85, 0.95 * al))
			E.PL(s, pts, K(s, 0.6 * al), 1.4)
			for k in range(4):
				var sx := hx - hr + float(k) * hr * 0.66
				spike(s, Vector2(sx, GY - 4.0 - hr * ho * sin(PI * float(k) / 3.6 + 0.2) * 0.9), 4.0, 11.0 * ho, 0.0, al, STEEL_D)
	if s.nocreature:
		# con rồng do sprite (FxCreature) đảm nhận: chỉ giữ bụi và đá văng
		E.dust(s, Vector2(54.0, GY - 2.0), 40.0, E.sg(t, 0.0, 0.7), al * 0.9, 9, 4)
		rocks(s, Vector2(54.0, GY - 4.0), 5 if lowq else 12, 90.0, 110.0, t, 0.05, 0.6, al, 6)
		return
	# cổ + đầu rồng
	var segs := 11
	var spine: Array = []
	for i in range(segs):
		var v := float(i) / float(segs - 1)
		var x := 52.0 + 54.0 * sin((1.0 - v) * 1.9) * 0.9 + 18.0 * (1.0 - v) * u
		var y := GY - 4.0 - (96.0 * u + 12.0 * sin(t * 6.0)) * pow(1.0 - v, 0.8) + 6.0 * sin(v * 7.0 - t * 8.0) * u
		spine.append(Vector2(x, y))
	for i in range(segs - 1, 0, -1):
		var v := float(i) / float(segs - 1)
		var w := 9.0 + 7.0 * v
		var a: Vector2 = spine[i]
		var b: Vector2 = spine[i - 1]
		var nr := (b - a).orthogonal().normalized()
		E.L(s, a, b, tone(ROCK, 1.3, 0.8 * al), w * 1.8)
		E.L(s, a + nr * w * 0.5, b + nr * w * 0.5, tone(ROCK, 1.7, 0.5 * al), w * 0.6)
		if i % 2 == 0:
			E.PL(s, PackedVector2Array([a - nr * w * 0.9, a, a + nr * w * 0.9]), K(s, 0.5 * al), 1.0)
		if i % 3 == 1:
			spike(s, a - nr * w * 0.95 + Vector2(0, w * 0.8), 3.5, 11.0, -3.0, al, STEEL_D)
	var h: Vector2 = spine[0]
	var open := E.sg(t, 0.4, 0.55) * (1.0 - E.sg(t, 0.7, 0.9))
	if u > 0.1:
		_dhead(s, h + Vector2(4.0, 0), open, al, t)
		# tiếng gầm: sóng cung từ miệng
		for j in range(3):
			var rp := E.sg(t, 0.45 + 0.08 * float(j), 0.9)
			if rp > 0.0 and rp < 1.0:
				E.AR(s, h + Vector2(34.0, 8.0), 20.0 + 150.0 * E.eo(rp), -0.9, 0.9, 18, A(s, (1.0 - rp) * 0.85 * al), 3.0)
	E.dust(s, Vector2(54.0, GY - 2.0), 40.0, E.sg(t, 0.0, 0.7), al * 0.9, 9, 4)
	rocks(s, Vector2(54.0, GY - 4.0), 5 if lowq else 12, 90.0, 110.0, t, 0.05, 0.6, al, 6)

## Đầu địa long (hướng +x): hộp sọ đá, hàm dưới mở theo `open`, sừng, răng, mắt sáng.
static func _dhead(s, h: Vector2, open: float, al: float, t: float) -> void:
	E.glow(s, h + Vector2(8, 0), 30.0, 0.1 * al)
	# hàm dưới (xoay mở)
	var jaw := 0.55 * open
	var jp := h + Vector2(-8.0, 8.0)
	var jv := PackedVector2Array([Vector2(0, 0), Vector2(36, -2), Vector2(44, 6), Vector2(14, 12), Vector2(0, 8)])
	var jr := PackedVector2Array()
	for v in jv:
		jr.append(jp + v.rotated(jaw))
	E.P(s, jr, tone(ROCK, 0.75, 0.95 * al))
	for k in range(4):
		var tp := jp + Vector2(10.0 + 9.0 * float(k), -2.0).rotated(jaw)
		E.P(s, PackedVector2Array([tp, tp + Vector2(2.0, -6.0).rotated(jaw), tp + Vector2(4.0, 0).rotated(jaw)]), K(s, 0.9 * al))
	# sọ trên
	E.P(s, PackedVector2Array([h + Vector2(-18, -10), h + Vector2(6, -14), h + Vector2(34, -6), h + Vector2(46, 2), h + Vector2(40, 8), h + Vector2(-8, 8), h + Vector2(-20, 2)]), tone(ROCK, 1.0, 0.97 * al))
	E.P(s, PackedVector2Array([h + Vector2(-4, -12), h + Vector2(30, -6), h + Vector2(42, 1), h + Vector2(-6, 0)]), tone(ROCK, 1.3, 0.9 * al))
	for k in range(4):
		var tp2 := h + Vector2(14.0 + 8.0 * float(k), 7.0)
		E.P(s, PackedVector2Array([tp2, tp2 + Vector2(2.0, 7.0), tp2 + Vector2(4.0, 0)]), K(s, 0.9 * al))
	# sừng
	for k in range(2):
		var bx := h + Vector2(-10.0 - 9.0 * float(k), -12.0)
		E.PL(s, PackedVector2Array([bx, bx + Vector2(-12, -14), bx + Vector2(-8, -30)]), K(s, al), 3.2)
		E.PL(s, PackedVector2Array([bx, bx + Vector2(-12, -14), bx + Vector2(-8, -30)]), A(s, al), 1.4)
	# mắt + lỗ mũi + râu đá
	E.CI(s, h + Vector2(14, -5), 4.0, A(s, al))
	E.CI(s, h + Vector2(14.5, -5), 2.0, K(s, al))
	E.CI(s, h + Vector2(40, -1), 1.6, Color(0, 0, 0, 0.7 * al))
	E.PL(s, PackedVector2Array([h + Vector2(38, 4), h + Vector2(56, 14 + 3.0 * sin(t * 9.0)), h + Vector2(70, 10)]), K(s, 0.7 * al), 1.5)

## ulTank2 Địa Chấn Thiên Hạ (r300, rung camera): cả chiến trường nứt toạc — vết nứt dài phát sáng, ba đợt sóng nén, đá khổng lồ tung lên, tường bụi.
static func _worldquake(s, t: float, lowq: bool) -> void:
	var R := 300.0
	var fa := E.fadeo(t, 0.78)
	var g := gc()
	var e := E.eo(E.sg(t, 0.0, 0.45))
	# bóng tối phủ nhẹ mặt đất vùng chấn
	for i in range(4):
		E.ering(s, g, R * e * (1.0 - 0.2 * float(i)), R * e * (1.0 - 0.2 * float(i)) * 0.26, Color(0.1, 0.07, 0.05, 0.1 * fa), 24.0)
	# vết nứt khổng lồ: hai lớp
	E.crack(s, g, R * e, fa, 1)
	E.crack(s, g + Vector2(0, 4.0), R * 0.7 * e, fa * 0.85, 8)
	# 3 đợt sóng nén
	for k in range(3):
		var tk := 0.04 + 0.13 * float(k)
		var q := E.sg(t, tk, tk + 0.5)
		if q > 0.0 and q < 1.0:
			E.shock(s, g, R * E.eo(q), R * E.eo(q) * 0.26, (1.0 - q) * fa)
	# vết nứt trung tâm phát sáng
	var core := E.sg(t, 0.0, 0.2)
	E.glow(s, Vector2(0, GY - 6.0), 60.0 * core, 0.5 * fa)
	E.star(s, Vector2(0, GY - 6.0), 40.0 * (1.0 - E.sg(t, 0.1, 0.6)), 1.0 - E.sg(t, 0.1, 0.6), 12)
	# cột đá bật lên dọc vết nứt
	var n := 8 if lowq else 16
	for i in range(n):
		var a := TAU * (float(i) + E.rnd(i, 2)) / float(n)
		var rr := R * (0.25 + 0.7 * E.rnd(i, 3)) * e
		var p := g + Vector2(cos(a) * rr, sin(a) * rr * 0.26)
		var pop := E.sg(t, 0.08 + 0.015 * float(i), 0.34 + 0.015 * float(i))
		var gone := 1.0 - E.sg(t, 0.62, 0.9)
		spike(s, p, 8.0 + 7.0 * E.rnd(i, 4), (36.0 + 52.0 * E.rnd(i, 5)) * E.eo(pop) * gone, (E.rnd(i, 6) - 0.5) * 14.0, fa if gone > 0.0 else 0.0)
	# đá lớn tung lên, rơi
	rocks(s, Vector2(0, GY - 4.0), 8 if lowq else 20, R * 0.9, 150.0, t, 0.05, 0.85, fa, 11)
	# tường bụi ở mép
	for i in range(0 if lowq else 9):
		var a2 := TAU * float(i) / 9.0 + 0.2
		var cp := g + Vector2(cos(a2) * R * 0.85 * e, sin(a2) * R * 0.85 * e * 0.26 - 16.0)
		E.cloud(s, cp, 34.0 + 10.0 * E.rnd(i, 3), 0.55 * fa * E.sg(t, 0.1, 0.4))
	E.dust(s, Vector2(0, GY - 2.0), R * 0.9, E.sg(t, 0.0, 0.8), fa, 10 if lowq else 18, 2)

# ============================================================ TIẾNG GẦM / XOÁY
## tk9 Tiếng Gầm Uy Hiếp (r230, làm chậm): sóng âm răng cưa lan từ miệng thành các vòng, vùng đất rung, vạch uy hiếp.
static func _roar(s, t: float, lowq: bool) -> void:
	var R := 230.0
	var fa := E.fadeo(t, 0.72)
	var mouth := Vector2(10.0, -24.0)
	# miệng há: quầng sáng
	E.glow(s, mouth, 24.0 * (1.0 - E.sg(t, 0.0, 0.4)), 0.8)
	# 4 vòng sóng âm răng cưa
	for k in range(4):
		var tk := 0.0 + 0.1 * float(k)
		var q := E.sg(t, tk, tk + 0.6)
		if q <= 0.0 or q >= 1.0: continue
		var r := 18.0 + (R - 18.0) * E.eo(q)
		var al := (1.0 - q) * fa
		jag(s, mouth, r, r, 18 + 2 * k, 7.0, A(s, 0.35 * al), 9.0, 0.3 * float(k))
		jag(s, mouth, r, r, 18 + 2 * k, 7.0, A(s, 0.9 * al), 3.2, 0.3 * float(k))
		jag(s, mouth, r * 0.97, r * 0.97, 18 + 2 * k, 5.0, K(s, 0.8 * al), 1.4, 0.3 * float(k))
	# nón âm thanh về phía trước (từ miệng)
	var cn := E.eo(E.sg(t, 0.0, 0.3))
	for j in range(4):
		var ph := fmod(t * 2.6 + 0.25 * float(j), 1.0)
		var rr := 30.0 + 170.0 * ph
		E.AR(s, mouth, rr, -0.55, 0.55, 14, K(s, (1.0 - ph) * 0.9 * fa * cn), 2.4)
	# vạch tia xung quanh
	for i in range(14):
		var a := TAU * float(i) / 14.0
		var d := Vector2(cos(a), sin(a))
		var q := E.sg(t, 0.05, 0.5)
		E.L(s, mouth + d * (24.0 + 100.0 * E.eo(q)), mouth + d * (40.0 + 150.0 * E.eo(q)), A(s, (1.0 - q) * 0.8 * fa), 2.4)
	# mặt đất rung + sóng chậm
	E.shock(s, gc(), R * E.eo(E.sg(t, 0.05, 0.6)), R * E.eo(E.sg(t, 0.05, 0.6)) * 0.24, fa * 0.8)
	for i in range(0 if lowq else 9):
		var a2 := TAU * E.rnd(i, 4)
		var r2 := R * (0.3 + 0.65 * E.rnd(i, 5)) * E.eo(E.sg(t, 0.1, 0.5))
		var p2 := gc() + Vector2(cos(a2) * r2, sin(a2) * r2 * 0.26)
		E.AR(s, p2, 4.5, 0.0, TAU, 10, A(s, 0.6 * fa * E.sg(t, 0.3, 0.5)), 1.8)
		E.L(s, p2 + Vector2(-4, -8), p2 + Vector2(4, -8), K(s, 0.5 * fa * E.sg(t, 0.3, 0.5)), 1.4)

## hv37 Khiên Xoáy (r230, đẩy lùi, làm chậm): 6 khiên xoay vòng quanh người, xoáy gió trắng, mở rộng ra rồi đẩy bật quái.
static func _vortex(s, t: float, lowq: bool) -> void:
	var R := 230.0
	var fa := E.fadeo(t, 0.72)
	var e := E.eo(E.sg(t, 0.0, 0.5))
	var g := gc()
	E.glow(s, Vector2(0, -6), 50.0 * e, 0.16 * fa)
	E.ering(s, g, R * e, R * e * 0.28, A(s, 0.25 * fa), 10.0)
	E.ering(s, g, R * e, R * e * 0.28, A(s, 0.8 * fa), 2.4)
	var n := 6
	var rad := 40.0 + (R - 40.0) * 0.82 * e
	var spin := t * 9.0
	# xoáy gió: 3 vệt xoắn
	for k in range(3):
		var a0 := spin * 0.7 + TAU * float(k) / 3.0
		E.swoosh(s, Vector2(0, -4.0), rad * 0.92, a0 - 2.2, a0, 1.0, 1.0, 22.0, fa * 0.85, 0.3)
	for pass_i in range(2):
		for i in range(n):
			var a := spin + TAU * float(i) / float(n)
			var front := sin(a) > 0.0
			if (pass_i == 0) == front: continue
			var p := Vector2(cos(a) * rad, -4.0 + sin(a) * rad * 0.3)
			var depth := 0.55 + 0.45 * (sin(a) * 0.5 + 0.5)
			var tl := PackedVector2Array()
			for q in range(9):
				var aa := a - 0.1 * float(q)
				tl.append(Vector2(cos(aa) * rad, -4.0 + sin(aa) * rad * 0.3))
			E.PL(s, tl, A(s, 0.35 * fa * depth), 6.0)
			E.PL(s, tl, K(s, 0.5 * fa * depth), 1.4)
			shield(s, p, 22.0 * (0.8 + 0.2 * depth), 0.0, fa * depth, 0.3 + 0.7 * absf(sin(a)), 1.0, 1)
	# đẩy lùi: vạch hướng ra ngoài + bụi
	var k2 := E.sg(t, 0.35, 0.9)
	for i in range(12):
		var a2 := TAU * float(i) / 12.0
		var d := Vector2(cos(a2), sin(a2) * 0.3)
		E.cut(s, Vector2(0, -4) + d * (R * 0.7), Vector2(0, -4) + d * (R * 0.7 + 70.0 * E.eo(k2)), 2.6, (1.0 - k2) * fa * E.sg(t, 0.3, 0.45))
	E.dust(s, Vector2(0, GY - 2.0), R * 0.7, e, fa * 0.7, 6 if lowq else 10, 3)

## tk2 Vòng Thép (r160): vòng thép nặng quét một vòng quanh thân — thanh kiếm xoay kéo vệt, vòng đai đinh tán bung ra.
static func _ring(s, t: float, lowq: bool) -> void:
	var R := 160.0
	var fa := E.fadeo(t, 0.7)
	var e := E.eo(E.sg(t, 0.0, 0.45))
	var g := gc()
	# vòng đai thép nặng ở ngang người, bung ra đến R
	var cy := Vector2(0, -2.0)
	for k in range(3):
		var rr := R * e * (1.0 - 0.1 * float(k))
		var yy := cy + Vector2(0, -8.0 * float(k) + 8.0)
		E.ering(s, yy, rr, rr * 0.3, C(STEEL_D, 0.5 * fa), 12.0 - 2.0 * float(k))
		E.ering(s, yy, rr, rr * 0.3, C(STEEL, 0.9 * fa), 4.0 - float(k) * 0.8)
		E.ering(s, yy, rr, rr * 0.3, K(s, 0.8 * fa), 1.2)
	# đinh tán dọc vòng ngoài
	var ng := 20 if not lowq else 12
	for i in range(ng):
		var a := TAU * float(i) / float(ng) + t * 2.0
		var p := cy + Vector2(cos(a) * R * e, sin(a) * R * e * 0.3 + 8.0)
		E.CI(s, p, 2.8, K(s, 0.95 * fa))
		E.CI(s, p, 5.0, A(s, 0.3 * fa))
	# thanh kiếm xoay quét + vệt
	var sw := E.eo(E.sg(t, 0.0, 0.7))
	var ang := -PI * 0.5 + TAU * 1.2 * sw
	E.swoosh(s, Vector2(0, 0), R * 0.85, ang - 3.6, ang, 1.0, 1.0, 34.0, fa * 0.9, 0.3)
	var tip := Vector2(cos(ang) * R * 0.78, sin(ang) * R * 0.78 * 0.3)
	var hp := Vector2(cos(ang) * 22.0, sin(ang) * 22.0 * 0.3)
	E.L(s, hp, tip, A(s, 0.35 * fa), 12.0)
	E.sword(s, hp, atan2(tip.y - hp.y, tip.x - hp.x), hp.distance_to(tip), 9.0, fa)
	E.spark(s, tip, 6, 28.0, fmod(t * 3.0, 1.0), fa, 2)
	E.shock(s, g, R * e, R * e * 0.26, fa * 0.7)
	E.dust(s, Vector2(0, GY - 2.0), R * 0.7, e, fa * 0.6, 5 if lowq else 9, 1)

# ============================================================ THÀNH LŨY / HỘ THỂ
## hv38 Thành Lũy Bất Diệt (3s, giảm 70%): thành luỹ trồi lên trước mặt — tường, hai tháp lỗ châu mai, cổng; tường mờ phía sau.
static func _bastion(s, t: float, lowq: bool) -> void:
	var up := E.eo(E.sg(t, 0.0, 0.3))
	var al := E.fo(s, t, 0.85)
	var g := gc()
	E.ering(s, g, 66.0 * up, 16.0 * up, A(s, 0.3 * al), 8.0)
	E.ering(s, g, 66.0 * up, 16.0 * up, A(s, 0.85 * al), 2.2)
	# tường sau (mờ)
	wall(s, -76.0, -38.0, GY, 54.0 * up, 3, 0.55 * al, STONE)
	# tường chính + hai tháp
	var rise := (1.0 - up) * 100.0
	var yb := GY + rise
	wall(s, 34.0, 112.0, yb, 74.0, 4, al * up, STONE)
	gate(s, 73.0, yb, 15.0, 44.0, al * up, Color(0.45, 0.36, 0.3))
	wall(s, 26.0, 44.0, yb, 104.0, 2, al * up, tone(STONE, 1.08, 1.0))
	wall(s, 104.0, 122.0, yb, 104.0, 2, al * up, tone(STONE, 1.08, 1.0))
	for sd in [0.0, 1.0]:
		var tx: float = 35.0 + 78.0 * sd
		E.L(s, Vector2(tx, yb - 66.0), Vector2(tx, yb - 52.0), Color(0, 0, 0, 0.8 * al * up), 3.0)
		E.glow(s, Vector2(tx, yb - 59.0), 8.0, 0.4 * al * up)
	E.dust(s, Vector2(74.0, GY - 2.0), 50.0, E.sg(t, 0.0, 0.5), (1.0 - E.sg(t, 0.1, 0.6)) * 0.9, 7, 2)
	# hào quang giảm sát thương: sóng chặn vòng cung bị tường hút
	var ph := fmod(t * 1.0, 1.0)
	E.AR(s, Vector2(70.0, -20.0), 70.0 + 50.0 * ph, -0.6, 0.6, 14, A(s, (1.0 - ph) * 0.6 * al * up), 2.0)
	for k in range(2):
		var pu := fmod(t * 0.8 + 0.5 * float(k), 1.0)
		chev(s, Vector2(-16.0 + 10.0 * float(k), 18.0 - 48.0 * pu), 4.5, sin(pu * PI) * al * 0.7)

## tk7 Pháo Đài Bất Khuất (8s, giảm 60%): tháp canh đá có cờ hiệu sau lưng + hàng rào chông phía trước + vòng trận dưới chân.
static func _keep(s, t: float, lowq: bool) -> void:
	var up := E.eo(E.sg(t, 0.0, 0.35))
	var al := E.fo(s, t, 0.85)
	var g := gc()
	E.ering(s, g, 62.0 * up, 15.0 * up, A(s, 0.3 * al), 8.0)
	E.ering(s, g, 62.0 * up, 15.0 * up, A(s, 0.85 * al), 2.2)
	# tháp canh phía sau: thân đá, mái lỗ châu mai, khe tên, cờ
	var yb := GY + (1.0 - up) * 150.0
	var tx := -50.0
	wall(s, tx - 22.0, tx + 22.0, yb, 128.0, 3, al * up, tone(STONE, 0.95, 1.0))
	wall(s, tx - 28.0, tx + 28.0, yb - 104.0, 22.0, 4, al * up, tone(STONE, 1.1, 1.0))
	E.L(s, Vector2(tx, yb - 90.0), Vector2(tx, yb - 66.0), Color(0, 0, 0, 0.85 * al * up), 4.0)
	E.glow(s, Vector2(tx, yb - 78.0), 12.0, 0.45 * al * up)
	gate(s, tx, yb, 11.0, 30.0, al * up, Color(0.45, 0.36, 0.3))
	flag(s, Vector2(tx + 8.0, yb - 126.0), 36.0, 34.0, 20.0, t, al * up, Color(0.85, 0.25, 0.2))
	# hàng rào chông (chevaux-de-frise) phía trước: các cặp cọc bắt chéo
	for k in range(3):
		var cx := 52.0 + 30.0 * float(k)
		var u := E.eo(E.sg(t, 0.08 + 0.07 * float(k), 0.35 + 0.07 * float(k)))
		var h := 38.0 * u
		for sd in [-1.0, 1.0]:
			var tip := Vector2(cx + sd * 16.0, GY - 4.0 - h)
			E.L(s, Vector2(cx - sd * 10.0, GY - 2.0), tip, C(Color(0.5, 0.38, 0.26), 0.95 * al * up), 4.0)
			E.P(s, PackedVector2Array([tip + Vector2(-3, 3), tip + Vector2(sd * 3.0, -11.0), tip + Vector2(3, 3)]), K(s, 0.9 * al * up))
		E.L(s, Vector2(cx - 12.0, GY - 4.0 - h * 0.5), Vector2(cx + 12.0, GY - 4.0 - h * 0.5), C(STEEL_D, 0.9 * al * up), 2.0)
	E.dust(s, Vector2(10.0, GY - 2.0), 80.0, E.sg(t, 0.0, 0.5), (1.0 - E.sg(t, 0.1, 0.6)) * 0.9, 8, 6)
	for k in range(2):
		var pu := fmod(t * 0.8 + 0.5 * float(k), 1.0)
		chev(s, Vector2(-8.0 + 10.0 * float(k), 18.0 - 48.0 * pu), 4.5, sin(pu * PI) * al * 0.7)

## ulTank1 Thành Đồng Bất Hoại (10s, giảm 60%, phản 40%): hóa thành tường thành đồng — vòng tường đồng quanh thân, cổng đồng phía trước, gai phản đòn.
static func _bronze(s, t: float, lowq: bool) -> void:
	var up := E.eo(E.sg(t, 0.0, 0.3))
	var al := E.fo(s, t, 0.85)
	var g := gc()
	var br := BRONZE
	E.glow(s, Vector2(0, -6), 60.0 * up, 0.14 * al)
	E.ering(s, g, 64.0 * up, 16.0 * up, C(br, 0.4 * al), 8.0)
	E.ering(s, g, 64.0 * up, 16.0 * up, K(s, 0.85 * al), 1.6)
	var segs := 14
	var order := []
	for i in range(segs):
		order.append(i)
	for pass_i in range(2):
		for i in range(segs):
			var a := TAU * float(i) / float(segs) + 0.1
			var front := sin(a) > 0.0
			if (pass_i == 0) == front: continue
			var a2 := TAU * float(i + 1) / float(segs) + 0.1
			var rx := 64.0 * up
			var ry := 16.0 * up
			var p0 := g + Vector2(cos(a) * rx, sin(a) * ry)
			var p1 := g + Vector2(cos(a2) * rx, sin(a2) * ry)
			var hgt := (66.0 if not front else 28.0) * up
			var shade := 0.8 + 0.4 * (cos(a) * 0.5 + 0.5)
			var c1 := tone(br, shade, 0.95 * al * (0.7 if not front else 0.92))
			var c2 := tone(br, shade * 0.55, 0.95 * al * (0.7 if not front else 0.92))
			E.PG(s, PackedVector2Array([p0 + Vector2(0, -hgt), p1 + Vector2(0, -hgt), p1, p0]), PackedColorArray([c1, c1, c2, c2]))
			E.L(s, p0 + Vector2(0, -hgt * 0.5), p1 + Vector2(0, -hgt * 0.5), Color(0, 0, 0, 0.25 * al), 1.0)
			E.L(s, p0, p0 + Vector2(0, -hgt), Color(0, 0, 0, 0.3 * al), 1.0)
			E.L(s, p0 + Vector2(0, -hgt), p1 + Vector2(0, -hgt), K(s, 0.7 * al), 1.4)
			if i % 2 == 0:
				# lỗ châu mai
				var m0 := p0.lerp(p1, 0.1) + Vector2(0, -hgt)
				var m1 := p0.lerp(p1, 0.8) + Vector2(0, -hgt)
				E.P(s, PackedVector2Array([m0, m0 + Vector2(0, -8), m1 + Vector2(0, -8), m1]), tone(br, shade * 1.1, 0.9 * al))
	# cổng đồng phía trước
	gate(s, 68.0 * up, GY - 2.0, 15.0 * up, 44.0 * up, al * up, tone(br, 1.0, 1.0))
	E.L(s, Vector2(68.0, GY - 50.0), Vector2(68.0, GY - 70.0), K(s, 0.0), 1.0)
	# gai phản đòn bật ra theo nhịp
	var ph := fmod(t * 0.9, 1.0)
	for i in range(8):
		var a3 := TAU * float(i) / 8.0 + 0.2
		var p := g + Vector2(cos(a3) * 64.0 * up, sin(a3) * 16.0 * up)
		spike(s, p + Vector2(0, -26.0), 3.5, (10.0 + 18.0 * sin(ph * PI)) * up, cos(a3) * 8.0, al * (0.4 + 0.6 * sin(ph * PI)), C(br, 1.0))
	E.AR(s, Vector2(0, -6), 40.0 + 70.0 * ph, 0.0, TAU, 48, C(br, (1.0 - ph) * 0.6 * al), 2.4)

## ulTankSuper Thiết Bích Vĩnh Cửu (70s miễn nhiễm, KHÔNG gây sát thương): vòm lục giác thép xám lạnh trùm quanh người, thanh kiếm bị xích khóa cắm xuống đất.
static func _hexdome(s, t: float, lowq: bool) -> void:
	var up := E.eo(E.sg(t, 0.0, 0.4))
	var al := E.fo(s, t, 0.9)
	var g := gc()
	var rx := 74.0 * up
	var ry := 98.0 * up
	var base := g + Vector2(0, 2.0)
	# nền vòm + viền đáy
	var dome := PackedVector2Array()
	for k in range(25):
		var a := PI * float(k) / 24.0
		dome.append(base + Vector2(-cos(a) * rx, -sin(a) * ry))
	E.P(s, dome, C(COLD, 0.09 * al))
	E.ering(s, base, rx, rx * 0.24, C(COLD, 0.3 * al), 9.0)
	E.ering(s, base, rx, rx * 0.24, C(COLD, 0.95 * al), 2.6)
	E.ering(s, base, rx * 0.97, rx * 0.24 * 0.97, K(s, 0.6 * al), 1.2)
	# lưới lục giác
	var hsz := 0.2
	var dx := hsz * 1.7320508
	var dy := hsz * 1.5
	for r in range(0, 6):
		var cv := -0.16 - float(r) * dy
		for q in range(-5, 6):
			var cu := float(q) * dx + (dx * 0.5 if r % 2 == 1 else 0.0)
			if cu * cu + cv * cv > 0.9 * 0.9: continue
			var pts := PackedVector2Array()
			for k in range(6):
				var a := PI / 6.0 + TAU * float(k) / 6.0
				pts.append(base + Vector2((cu + cos(a) * hsz * 0.92) * rx, (cv + sin(a) * hsz * 0.92) * ry))
			var sh := 0.5 + 0.5 * sin(t * 2.0 + cu * 5.0 + cv * 3.0)
			E.P(s, pts, C(COLD, (0.05 + 0.12 * sh * sh) * al))
			var cl := pts.duplicate()
			cl.append(pts[0])
			E.PL(s, cl, C(COLD, 0.75 * al), 1.4)
	# viền vòm + vệt sáng
	E.PL(s, dome, C(COLD, 0.95 * al), 2.6)
	E.PL(s, dome, K(s, 0.5 * al), 1.0)
	var sp := fmod(t * 0.4, 1.0)
	var sa := PI * (0.15 + 0.7 * sp)
	E.L(s, base + Vector2(-cos(sa) * rx * 0.9, -sin(sa) * ry * 0.9), base + Vector2(-cos(sa + 0.12) * rx * 0.9, -sin(sa + 0.12) * ry * 0.9), Color(1, 1, 1, 0.85 * al * sin(sp * PI)), 3.0)
	# thanh kiếm bị khóa: cắm xuống đất bên cạnh, xích quấn + ổ khóa
	var sx := 34.0
	var ang := PI * 0.5 + 0.08
	E.sword(s, Vector2(sx - 4.0, GY - 78.0), ang, 78.0, 10.0, al * up)
	for k in range(3):
		var cyp := GY - 56.0 + 14.0 * float(k)
		E.ering(s, Vector2(sx - 2.0, cyp), 11.0, 3.2, C(STEEL, 0.95 * al * up), 2.4, 0.15)
		E.ering(s, Vector2(sx - 2.0, cyp + 4.0), 11.0, 3.2, C(STEEL_D, 0.9 * al * up), 2.4, -0.15)
	# xích nối từ chuôi kiếm lên vòm
	for sd in [-1.0, 1.0]:
		var p0 := Vector2(sx - 4.0, GY - 70.0)
		var p1 := base + Vector2(sd * rx * 0.6 + 8.0, -ry * 0.75)
		var n := 9
		for i in range(n + 1):
			var u := float(i) / float(n)
			var p := p0.lerp(p1, u) + Vector2(0, 10.0 * sin(u * PI))
			E.ering(s, p, 3.6, 1.8, C(STEEL, 0.9 * al * up), 1.6, atan2(p1.y - p0.y, p1.x - p0.x) + (0.0 if i % 2 == 0 else 1.5))
	# ổ khóa
	var lk := Vector2(sx - 2.0, GY - 62.0)
	E.AR(s, lk + Vector2(0, -6.0), 6.0, PI, TAU, 12, C(STEEL, al * up), 2.4)
	E.P(s, PackedVector2Array([lk + Vector2(-8, -6), lk + Vector2(8, -6), lk + Vector2(8, 9), lk + Vector2(-8, 9)]), C(Color(0.78, 0.66, 0.34), 0.97 * al * up))
	E.CI(s, lk + Vector2(0, 1.0), 2.2, Color(0.1, 0.07, 0.04, 0.9 * al * up))
	E.L(s, lk + Vector2(0, 1.0), lk + Vector2(0, 5.0), Color(0.1, 0.07, 0.04, 0.9 * al * up), 1.6)
	# huy hiệu "kiếm bị khóa" nổi trên đỉnh vòm
	var bp := base + Vector2(0, -ry - 14.0 - 2.0 * sin(t * 2.0))
	E.CI(s, bp, 12.0, Color(0.1, 0.14, 0.2, 0.55 * al * up))
	E.AR(s, bp, 12.0, 0.0, TAU, 28, C(COLD, 0.95 * al * up), 1.8)
	E.L(s, bp + Vector2(0, -7), bp + Vector2(0, 5), K(s, 0.95 * al * up), 2.0)
	E.L(s, bp + Vector2(-4, -2), bp + Vector2(4, -2), K(s, 0.95 * al * up), 2.0)
	E.L(s, bp + Vector2(-9, -9), bp + Vector2(9, 9), C(RED, 0.9 * al * up), 2.0)

# ============================================================ LAO TỚI
## hv40 Pháo Đài Tiến Quân (lao 160px, đánh bật): giữ khiên tháp trước mặt, tiến lên như pháo đài di động, đẩy bụi và đá.
static func _march(s, t: float, lowq: bool) -> void:
	var D := 160.0
	var run := E.eo(E.sg(t, 0.0, 0.4))
	var fa := E.fadeo(t, 0.65)
	var x := D * run
	# tàn ảnh người + vệt
	mtrail(s, 0.0, x, -2.0, 26.0, fa * 0.8)
	for k in range(1, 4):
		E.man(s, Vector2(x * (1.0 - 0.22 * float(k)), 0), 0.28 * (1.0 - 0.22 * float(k)) * fa)
	# khiên tháp cắm phía trước
	shield(s, Vector2(x + 34.0, -4.0), 30.0, 0.0, fa, 0.8, 1.55, 1)
	E.glow(s, Vector2(x + 50.0, -4.0), 40.0, 0.2 * fa)
	# nón xung kích đẩy trước khiên
	for j in range(3):
		var rr := 12.0 + 24.0 * float(j) + 40.0 * E.sg(t, 0.2, 0.6)
		E.AR(s, Vector2(x + 40.0, -4.0), rr, -0.9, 0.9, 14, A(s, (0.8 - 0.2 * float(j)) * fa * (1.0 - E.sg(t, 0.4, 0.8))), 2.4)
	E.speedlines(s, x + 40.0, x + 140.0, -34.0, 30.0, 7, fa, 3)
	# bụi + đá bị đẩy dọc đường
	E.dust(s, Vector2(x * 0.6, GY - 2.0), 60.0, E.sg(t, 0.0, 0.8), fa * 0.9, 8 if lowq else 13, 2)
	for i in range(3 if lowq else 6):
		var u := E.sg(t, 0.1 + 0.05 * float(i), 0.7)
		rock(s, Vector2(x + 46.0 + 50.0 * u, GY - 6.0 - 40.0 * 4.0 * u * (1.0 - u)), 4.0 + 3.0 * E.rnd(i, 1), u * 6.0, fa * (1.0 - E.sg(u, 0.8, 1.0)))
	# vệt dừng: sóng đất tại điểm dừng
	if run >= 0.99:
		var h := E.sg(t, 0.4, 0.95)
		E.shock(s, Vector2(x + 30.0, GY - 4.0), 20.0 + 80.0 * E.eo(h), 5.0 + 20.0 * E.eo(h), (1.0 - h) * fa)

## tk8 Xung Phong (lao 190px, đẩy lùi): bóng đầu trâu sừng nhọn húc tới, vạch tốc độ, bụi và vết móng.
static func _charge(s, t: float, lowq: bool) -> void:
	var D := 190.0
	var run := E.eo(E.sg(t, 0.0, 0.4))
	var fa := E.fadeo(t, 0.65)
	var x := D * run
	mtrail(s, 0.0, x, -4.0, 26.0, fa * 0.85)
	for k in range(1, 4):
		E.man(s, Vector2(x * (1.0 - 0.2 * float(k)), 0), 0.26 * (1.0 - 0.22 * float(k)) * fa)
	# bóng trâu to phía trước
	var bp := Vector2(x + 38.0, -8.0)
	E.glow(s, bp, 56.0, 0.25 * fa)
	if not s.nocreature: bull(s, bp, 1.6, fa, t)
	E.speedlines(s, -20.0, x + 30.0, -34.0, 30.0, 9, fa, 5)
	# bụi + dấu móng dọc đường
	E.dust(s, Vector2(x * 0.5, GY - 2.0), 60.0, E.sg(t, 0.0, 0.8), fa * 0.95, 9 if lowq else 15, 3)
	for i in range(6):
		var hx := x * float(i) / 6.0
		E.AR(s, Vector2(hx, GY - 1.0), 5.0, PI, TAU, 8, K(s, 0.6 * fa * E.sg(t, 0.1, 0.4)), 1.6)
	if run >= 0.99:
		var h := E.sg(t, 0.4, 0.95)
		E.star(s, Vector2(x + 70.0, -8.0), 30.0 * (1.0 - h), 1.0 - h, 8)
		E.shock(s, Vector2(x + 60.0, GY - 4.0), 20.0 + 90.0 * E.eo(h), 5.0 + 22.0 * E.eo(h), (1.0 - h) * fa)
		E.speedlines(s, x + 70.0, x + 200.0, -30.0, 26.0, 6, (1.0 - h) * fa, 8)

## Đầu trâu nhìn nghiêng (hướng +x): hộp sọ, hai sừng cong, mắt đỏ, mõm + khuyên mũi, hơi thở.
static func bull(s, p: Vector2, k: float, al: float, t: float) -> void:
	if al <= 0.02: return
	var P := func(v: Vector2) -> Vector2: return p + v * k
	# sừng sau (tối) + sừng trước
	for i in range(2):
		var dk := 0.7 if i == 0 else 1.0
		var off := Vector2(-5.0 * float(1 - i), 2.0 * float(1 - i))
		E.P(s, PackedVector2Array([P.call(Vector2(-12, -11) + off), P.call(Vector2(0, -26) + off), P.call(Vector2(22, -36) + off), P.call(Vector2(14, -22) + off), P.call(Vector2(2, -12) + off)]), K(s, 0.95 * al * dk))
		E.L(s, P.call(Vector2(-10, -12) + off), P.call(Vector2(20, -35) + off), A(s, 0.8 * al * dk), 1.2)
	# sọ
	E.P(s, PackedVector2Array([P.call(Vector2(-20, -10)), P.call(Vector2(6, -13)), P.call(Vector2(26, -5)), P.call(Vector2(30, 8)), P.call(Vector2(14, 15)), P.call(Vector2(-14, 12)), P.call(Vector2(-22, 0))]), A(s, 0.95 * al))
	E.P(s, PackedVector2Array([P.call(Vector2(-6, -10)), P.call(Vector2(24, -4)), P.call(Vector2(26, 4)), P.call(Vector2(-4, 2))]), K(s, 0.5 * al))
	# tai
	E.P(s, PackedVector2Array([P.call(Vector2(-18, -6)), P.call(Vector2(-32, -10)), P.call(Vector2(-18, 2))]), A(s, 0.85 * al))
	# mõm + khuyên + mũi + mắt
	E.CI(s, P.call(Vector2(26, 9)), 4.0 * k, K(s, 0.8 * al))
	E.AR(s, P.call(Vector2(28, 14)), 5.0 * k, 0.4, PI + 0.4, 10, K(s, al), 1.6)
	E.CI(s, P.call(Vector2(25, 7)), 1.6, Color(0, 0, 0, 0.8 * al))
	E.CI(s, P.call(Vector2(6, -4)), 3.4, C(RED, al))
	E.CI(s, P.call(Vector2(6.5, -4)), 1.6, K(s, al))
	for i in range(3):
		var u := fmod(t * 3.0 + float(i) * 0.33, 1.0)
		E.CI(s, P.call(Vector2(30.0 + 14.0 * u, 9.0 - 6.0 * u)), (3.5 - 2.5 * u) * k, Color(1, 1, 1, 0.5 * (1.0 - u) * al))

# ============================================================ BUFF
## hv45 Tuyên Chiến (10s, +công +tốc đánh): chiến kỳ đỏ cắm sau lưng, sóng hô vang từ miệng, mũi tên tăng công.
static func _banner(s, t: float, lowq: bool) -> void:
	var up := E.eo(E.sg(t, 0.0, 0.3))
	var al := E.fo(s, t, 0.85)
	var g := gc()
	E.ering(s, g, 52.0 * up, 13.0 * up, C(RED, 0.3 * al), 8.0)
	E.ering(s, g, 52.0 * up, 13.0 * up, C(Color(1.0, 0.75, 0.3), 0.9 * al), 2.0)
	# chiến kỳ cắm xuống đất sau lưng (rơi từ trên xuống)
	var drop := E.eo(E.sg(t, 0.0, 0.22))
	var yb := GY - 2.0 - (1.0 - drop) * 150.0
	flag(s, Vector2(-34.0, yb), 100.0, 56.0, 38.0, t, al * up, Color(0.82, 0.18, 0.16))
	# huy hiệu kiếm trên cờ
	var fp := Vector2(-34.0 + 26.0, yb - 100.0 + 24.0 + 3.0 * sin(t * 9.0 - 2.0))
	E.L(s, fp + Vector2(0, -10), fp + Vector2(0, 11), K(s, 0.95 * al * up), 2.4)
	E.L(s, fp + Vector2(-6, -4), fp + Vector2(6, -4), K(s, 0.95 * al * up), 2.2)
	E.P(s, PackedVector2Array([fp + Vector2(-2, -10), fp + Vector2(0, -15), fp + Vector2(2, -10)]), K(s, al * up))
	E.shock(s, Vector2(-34.0, GY - 4.0), 36.0 * E.eo(E.sg(t, 0.2, 0.6)), 9.0 * E.eo(E.sg(t, 0.2, 0.6)), (1.0 - E.sg(t, 0.2, 0.7)) * up)
	# sóng hô vang từ miệng (hướng trước)
	var mouth := Vector2(10.0, -24.0)
	for j in range(2):
		var ph := fmod(t * 0.9 + 0.5 * float(j), 1.0)
		E.AR(s, mouth, 18.0 + 70.0 * ph, -0.6, 0.6, 14, C(Color(1.0, 0.8, 0.4), (1.0 - ph) * 0.9 * al * up), 2.6)
		E.AR(s, mouth, 14.0 + 70.0 * ph, -0.5, 0.5, 14, K(s, (1.0 - ph) * 0.6 * al * up), 1.2)
	# tăng công + tốc đánh: mũi tên đôi bay lên + vạch tốc độ
	for k in range(3):
		var pu := fmod(t * 0.9 + 0.33 * float(k), 1.0)
		chev(s, Vector2(-8.0 + 14.0 * float(k), 18.0 - 50.0 * pu), 5.0, sin(pu * PI) * al * up)
		chev(s, Vector2(-8.0 + 14.0 * float(k), 28.0 - 50.0 * pu), 5.0, sin(pu * PI) * al * up * 0.6)
	E.glow(s, Vector2(0, -8), 44.0 * up, 0.12 * al)
	E.spark(s, Vector2(0, -6), 4 if lowq else 8, 60.0, fmod(t * 1.3, 1.0), 0.6 * al * up, 3)

## tk3 Thịnh Nộ (8s, +công +tốc): lửa giận đỏ rực quanh thân, gân máu nổi lên, dấu giận trên đầu, hơi nóng phì ra.
static func _rage(s, t: float, lowq: bool) -> void:
	var up := E.eo(E.sg(t, 0.0, 0.25))
	var al := E.fo(s, t, 0.85) * up
	var g := gc()
	var jit := Vector2(sin(t * 55.0), cos(t * 47.0)) * 1.2
	E.glow(s, Vector2(0, -6) + jit, 54.0, 0.2 * al)
	E.ering(s, g, 40.0, 10.0, C(RED, 0.8 * al), 2.4)
	var n := 8 if lowq else 12
	for i in range(n):
		var a := TAU * float(i) / float(n)
		var base := Vector2(cos(a) * 30.0, GY - 4.0 + sin(a) * 8.0)
		E.flame(s, base, (52.0 + 34.0 * E.rnd(i, 2)) * up, 8.0, t, float(i), al * (0.55 if sin(a) < 0.0 else 1.0))
	# gân máu nổi trên thân
	for k in range(5):
		var a2 := -1.0 + 0.5 * float(k)
		var o := Vector2(sin(a2) * 8.0, -12.0 + cos(a2) * 4.0)
		var pts := PackedVector2Array([o])
		var pp := o
		for m in range(1, 5):
			pp += Vector2(sin(a2) * 3.0 + (E.rnd(k * 6 + m, 3) - 0.5) * 6.0, 5.0)
			pts.append(pp)
		var pl := 0.6 + 0.4 * sin(t * 8.0 + float(k))
		E.PL(s, pts, C(RED, 0.55 * al * pl), 3.0)
		E.PL(s, pts, K(s, 0.8 * al * pl), 1.1)
	# dấu giận trên đầu
	var ap := Vector2(10.0, -52.0 - 2.0 * sin(t * 9.0))
	var ps := 1.0 + 0.12 * sin(t * 12.0)
	for sx in [-1.0, 1.0]:
		for sy in [-1.0, 1.0]:
			var q := PackedVector2Array([ap + Vector2(sx * 9.0, sy * 3.0) * ps, ap + Vector2(sx * 6.0, sy * 4.0) * ps, ap + Vector2(sx * 4.5, sy * 6.0) * ps, ap + Vector2(sx * 3.0, sy * 9.0) * ps])
			E.PL(s, q, C(RED, al), 3.2)
			E.PL(s, q, K(s, 0.7 * al), 1.2)
	# hơi nóng phì ra từ đầu
	for i in range(0 if lowq else 4):
		var u := fmod(t * 1.2 + float(i) * 0.25, 1.0)
		E.CI(s, Vector2(-4.0 + 24.0 * u * (1.0 if i % 2 == 0 else -0.4), -30.0 - 34.0 * u), 3.0 + 6.0 * u, Color(1, 0.8, 0.7, 0.25 * (1.0 - u) * al))
	# tăng công + tốc
	for k in range(2):
		var pu := fmod(t * 1.0 + 0.5 * float(k), 1.0)
		chev(s, Vector2(-22.0 + 44.0 * float(k), 18.0 - 46.0 * pu), 4.5, sin(pu * PI) * al)
	E.speedlines(s, -48.0, 46.0, -34.0, 28.0, 5, 0.4 * al, int(t * 3.0))

## tk4 Giáp Sắt (7s, giảm 50%): mũ, giáp vai, giáp ngực lục giác và giáp chân ghép vào người từ bốn phía, thép loé sáng.
static func _armor(s, t: float, lowq: bool) -> void:
	var al := E.fo(s, t, 0.88)
	var g := gc()
	E.ering(s, g, 40.0, 10.0, C(STEEL, 0.5 * al), 6.0)
	E.ering(s, g, 40.0, 10.0, K(s, 0.8 * al), 1.6)
	# mỗi mảnh giáp: đa giác (toạ độ gốc ở thân) + hướng bay đến lúc lắp
	var plates := [
		[PackedVector2Array([Vector2(-9, -24), Vector2(-7, -34), Vector2(0, -38), Vector2(7, -34), Vector2(9, -24), Vector2(4, -26), Vector2(-4, -26)]), Vector2(0, -50)],
		[PackedVector2Array([Vector2(-16, -16), Vector2(-10, -20), Vector2(-5, -14), Vector2(-10, -8), Vector2(-17, -9)]), Vector2(-50, -20)],
		[PackedVector2Array([Vector2(16, -16), Vector2(10, -20), Vector2(5, -14), Vector2(10, -8), Vector2(17, -9)]), Vector2(50, -20)],
		[PackedVector2Array([Vector2(-8, -14), Vector2(8, -14), Vector2(7, 2), Vector2(0, 8), Vector2(-7, 2)]), Vector2(0, -50)],
		[PackedVector2Array([Vector2(-8, 4), Vector2(8, 4), Vector2(9, 10), Vector2(-9, 10)]), Vector2(-40, 20)],
		[PackedVector2Array([Vector2(-8, 12), Vector2(-2, 12), Vector2(-3, 28), Vector2(-9, 28)]), Vector2(-40, 40)],
		[PackedVector2Array([Vector2(2, 12), Vector2(8, 12), Vector2(9, 28), Vector2(3, 28)]), Vector2(40, 40)],
	]
	for i in range(plates.size()):
		var pl: Array = plates[i]
		var q := E.eo(E.sg(t, 0.04 + 0.07 * float(i), 0.34 + 0.07 * float(i)))
		var off: Vector2 = (pl[1] as Vector2) * (1.0 - q)
		var pts := PackedVector2Array()
		for v in (pl[0] as PackedVector2Array):
			pts.append(v + off)
		var ca := q * al
		E.P(s, pts, C(STEEL_D, 0.95 * ca))
		var inner := PackedVector2Array()
		var cen := Vector2.ZERO
		for v in pts:
			cen += v
		cen /= float(pts.size())
		for v in pts:
			inner.append(cen.lerp(v, 0.78))
		E.P(s, inner, A(s, 0.75 * ca))
		E.P(s, PackedVector2Array([inner[0], inner[1], cen]), K(s, 0.3 * ca))
		var oc := pts.duplicate()
		oc.append(pts[0])
		E.PL(s, oc, K(s, 0.9 * ca), 1.3)
		if q < 1.0 and q > 0.0:
			E.flare(s, cen, 7.0 * (1.0 - q), ca)
	# hoa văn lục giác trên giáp ngực
	for k in range(3):
		var hp := Vector2(-4.0 + 4.0 * float(k % 2) * 2.0, -8.0 + 7.0 * float(k))
		var hx := PackedVector2Array()
		for m in range(7):
			var a := PI / 6.0 + TAU * float(m) / 6.0
			hx.append(hp + Vector2(cos(a), sin(a)) * 3.4)
		E.PL(s, hx, K(s, 0.6 * al), 1.0)
	# tia chớp quét qua thép
	var sp := fmod(t * 0.9, 1.0)
	var sx := -22.0 + 46.0 * sp
	E.L(s, Vector2(sx, -34.0), Vector2(sx - 10.0, 26.0), Color(1, 1, 1, 0.55 * sin(sp * PI) * al), 3.0)
	E.glow(s, Vector2(0, -4), 36.0, 0.12 * al)
	for k in range(2):
		var pu := fmod(t * 0.8 + 0.5 * float(k), 1.0)
		chev(s, Vector2(-26.0 + 52.0 * float(k), 18.0 - 44.0 * pu), 4.0, sin(pu * PI) * al * 0.7)

## tk10 Phản Giáp (6s, giảm 45%, phản 30%): gai thép bung ra khắp thân giáp, mỗi nhịp phản đòn gai dài thêm và sóng bật ngược ra ngoài.
static func _thorns(s, t: float, lowq: bool) -> void:
	var up := E.eo(E.sg(t, 0.0, 0.25))
	var al := E.fo(s, t, 0.85) * up
	var g := gc()
	E.ering(s, g, 44.0 * up, 11.0 * up, C(STEEL, 0.45 * al), 7.0)
	E.ering(s, g, 44.0 * up, 11.0 * up, K(s, 0.85 * al), 1.8)
	E.glow(s, Vector2(0, -6), 40.0 * up, 0.12 * al)
	var ph := fmod(t * 1.1, 1.0)
	var ex := sin(ph * PI)
	# gai trên thân: bố trí quanh ellipse thân
	var n := 12 if not lowq else 8
	for pass_i in range(2):
		for i in range(n):
			var a := TAU * float(i) / float(n) + 0.2
			var front := sin(a) > 0.0
			if (pass_i == 0) == front: continue
			var p := Vector2(cos(a) * 17.0, -6.0 + sin(a) * 24.0)
			var dir := Vector2(cos(a), sin(a) * 1.2).normalized()
			var ln := (12.0 + 8.0 * E.rnd(i, 2) + 14.0 * ex) * up
			var nr := dir.orthogonal()
			var depth := 0.55 + 0.45 * (sin(a) * 0.5 + 0.5)
			var tip := p + dir * ln
			E.P(s, PackedVector2Array([p + nr * 3.6, tip, p - nr * 3.6]), C(STEEL, 0.95 * al * depth))
			E.P(s, PackedVector2Array([p, tip, p - nr * 3.6]), Color(0, 0, 0, 0.3 * al * depth))
			E.L(s, p + nr * 1.2, tip, K(s, 0.85 * al * depth), 1.0)
			if ex > 0.3:
				E.CI(s, tip, 2.0, K(s, ex * al * depth))
	# gai dưới đất quanh chân
	for i in range(8):
		var a2 := TAU * float(i) / 8.0 + t * 0.6
		var p2 := g + Vector2(cos(a2) * 50.0 * up, sin(a2) * 12.5 * up)
		spike(s, p2, 3.5, (10.0 + 10.0 * ex) * up, cos(a2) * 4.0, al, STEEL)
	# phản đòn: sóng bật ngược ra ngoài
	E.AR(s, Vector2(0, -6), 30.0 + 80.0 * ph, 0.0, TAU, 48, A(s, (1.0 - ph) * 0.7 * al), 2.4)
	E.AR(s, Vector2(0, -6), 26.0 + 80.0 * ph, 0.0, TAU, 48, K(s, (1.0 - ph) * 0.5 * al), 1.0)
	for k in range(6):
		var a3 := TAU * float(k) / 6.0 + 0.6
		var d := Vector2(cos(a3), sin(a3) * 0.9)
		E.cut(s, Vector2(0, -6) + d * (34.0 + 60.0 * ph), Vector2(0, -6) + d * (46.0 + 80.0 * ph), 2.4, (1.0 - ph) * al * 0.9)

# ============================================================ SÉT / BÚA / KIẾM RƠI
## tk11 Búa Thiên Lôi (r210, hất văng): búa khổng lồ giáng xuống cách 140px, sét đánh theo, sóng nổ r210.
static func _hammer(s, t: float, lowq: bool) -> void:
	var R := 210.0
	var fa := E.fadeo(t, 0.75)
	var cx := 140.0
	var fall := E.ei(E.sg(t, 0.12, 0.42))
	var hit := E.sg(t, 0.42, 1.0)
	var lead := E.sg(t, 0.0, 0.12)
	# điềm báo: vòng trên đất + quầng sét
	E.ering(s, Vector2(cx, GY - 6.0), R * 0.6 * E.eo(E.sg(t, 0.0, 0.3)), R * 0.6 * 0.26 * E.eo(E.sg(t, 0.0, 0.3)), A(s, 0.5 * lead * (1.0 - hit)), 2.0)
	# đám mây giông trên cao
	var cl := E.sg(t, 0.0, 0.15) * (1.0 - E.sg(t, 0.55, 0.9))
	for i in range(3):
		E.cloud(s, Vector2(cx - 40.0 + 40.0 * float(i), -250.0), 44.0, 0.8 * cl)
	# búa: đầu quay xuống, cán ở trên
	var hy := lerpf(-250.0, GY - 28.0, fall)
	var ha := 0.06 * (1.0 - fall)
	var alp := 1.0 - E.sg(t, 0.72, 0.95)
	if t > 0.12 and alp > 0.0:
		var up := Vector2(sin(ha), -cos(ha))
		var c0 := Vector2(cx, hy)
		# vệt rơi
		E.PG(s, PackedVector2Array([c0 + Vector2(-26, 0), c0 + Vector2(26, 0), c0 + Vector2(10, -140), c0 + Vector2(-10, -140)]), PackedColorArray([A(s, 0.5 * alp * (1.0 - hit)), A(s, 0.5 * alp * (1.0 - hit)), A(s, 0.0), A(s, 0.0)]))
		# cán
		E.L(s, c0 + up * 14.0, c0 + up * 150.0, Color(0.45, 0.33, 0.22, alp), 9.0)
		E.L(s, c0 + up * 14.0 + Vector2(-2, 0), c0 + up * 150.0 + Vector2(-2, 0), Color(0.75, 0.6, 0.42, 0.7 * alp), 2.0)
		for k in range(5):
			E.L(s, c0 + up * (30.0 + 22.0 * float(k)) + Vector2(-5, 0), c0 + up * (30.0 + 22.0 * float(k)) + Vector2(5, 0), Color(0.2, 0.14, 0.1, 0.7 * alp), 1.4)
		# đầu búa
		var hh := 24.0
		var hw := 38.0
		E.PG(s, PackedVector2Array([c0 + Vector2(-hw, -hh), c0 + Vector2(hw, -hh), c0 + Vector2(hw, hh), c0 + Vector2(-hw, hh)]), PackedColorArray([C(STEEL, alp), C(STEEL, alp), C(STEEL_D, alp), C(STEEL_D, alp)]))
		E.P(s, PackedVector2Array([c0 + Vector2(-hw - 10, -hh - 4), c0 + Vector2(-hw, -hh), c0 + Vector2(-hw, hh), c0 + Vector2(-hw - 10, hh + 4)]), C(STEEL_D, alp))
		E.P(s, PackedVector2Array([c0 + Vector2(hw + 10, -hh - 4), c0 + Vector2(hw, -hh), c0 + Vector2(hw, hh), c0 + Vector2(hw + 10, hh + 4)]), C(STEEL_D, alp))
		E.PL(s, PackedVector2Array([c0 + Vector2(-hw, hh), c0 + Vector2(-hw, -hh), c0 + Vector2(hw, -hh), c0 + Vector2(hw, hh), c0 + Vector2(-hw, hh)]), K(s, alp), 1.6)
		E.L(s, c0 + Vector2(-hw + 2, -hh + 5), c0 + Vector2(hw - 2, -hh + 5), K(s, 0.7 * alp), 2.0)
		# đai + ký hiệu sét
		E.L(s, c0 + Vector2(-hw, -hh * 0.3), c0 + Vector2(hw, -hh * 0.3), Color(0, 0, 0, 0.35 * alp), 1.2)
		var bz := PackedVector2Array([c0 + Vector2(4, -17), c0 + Vector2(-8, 0), c0 + Vector2(1, 0), c0 + Vector2(-5, 17)])
		E.PL(s, bz, A(s, alp), 4.0)
		E.PL(s, bz, K(s, alp), 1.6)
		E.glow(s, c0, 40.0, 0.1 * alp * (1.0 - hit))
	# sét giáng theo
	var lg := E.sg(t, 0.38, 0.5) * (1.0 - E.sg(t, 0.5, 0.78))
	if lg > 0.0:
		for k in range(3):
			var pts := PackedVector2Array()
			var x0 := cx + (float(k) - 1.0) * 30.0
			for i in range(11):
				var u := float(i) / 10.0
				pts.append(Vector2(lerpf(x0, cx + (float(k) - 1.0) * 14.0, u) + (E.rnd(i + k * 11, int(t * 28.0)) - 0.5) * 18.0 * (1.0 - u * 0.4), lerpf(-260.0, GY - 6.0, u)))
			E.PL(s, pts, A(s, 0.3 * lg), 9.0)
			E.PL(s, pts, A(s, 0.85 * lg), 3.4)
			E.PL(s, pts, K(s, lg), 1.4)
	# va chạm
	if hit > 0.0:
		var e := E.eo(hit)
		E.star(s, Vector2(cx, GY - 14.0), 54.0 * (1.0 - hit * 0.6), (1.0 - hit), 12)
		E.shock(s, Vector2(cx, GY - 4.0), R * e, R * e * 0.26, (1.0 - hit) * fa + 0.0)
		E.shock(s, Vector2(cx, GY - 4.0), R * e * 0.5, R * e * 0.13, (1.0 - hit) * fa * 0.7)
		E.crack(s, Vector2(cx, GY - 4.0), R * 0.7 * e, fa, 2)
		# tia sét lan trên mặt đất
		for k in range(8):
			var a := PI * (0.05 + 0.9 * E.rnd(k, 2)) * (1.0 if k % 2 == 0 else -1.0)
			var pts2 := PackedVector2Array([Vector2(cx, GY - 8.0)])
			var pp := Vector2(cx, GY - 8.0)
			for m in range(1, 6):
				pp += Vector2(cos(a), sin(a) * 0.3) * R * 0.14 * e + Vector2(0, (E.rnd(k * 6 + m, int(t * 22.0)) - 0.5) * 12.0)
				pts2.append(pp)
			E.PL(s, pts2, A(s, 0.8 * (1.0 - hit)), 2.6)
			E.PL(s, pts2, K(s, (1.0 - hit)), 1.0)
		rocks(s, Vector2(cx, GY - 6.0), 4 if lowq else 10, R * 0.7, 70.0, t, 0.42, 0.9, fa, 5)
		E.dust(s, Vector2(cx, GY - 2.0), R * 0.6, hit, (1.0 - hit) * 0.9, 8 if lowq else 12, 6)
		E.speedlines(s, cx + 20.0, cx + 200.0, -30.0, 24.0, 6, (1.0 - hit) * fa * 0.9, 4)

## tk5 Sóng Thép (r220): thanh kiếm thép khổng lồ đâm xuống cách 140px, sóng thép nổ vòng tròn r220 — gai thép bật lên dọc vòng.
static func _steelwave(s, t: float, lowq: bool) -> void:
	var R := 220.0
	var fa := E.fadeo(t, 0.74)
	var cx := 140.0
	var fall := E.ei(E.sg(t, 0.1, 0.38))
	var hit := E.sg(t, 0.38, 1.0)
	var lead := E.sg(t, 0.0, 0.12)
	E.ering(s, Vector2(cx, GY - 6.0), 60.0 * E.eo(E.sg(t, 0.0, 0.3)), 15.6 * E.eo(E.sg(t, 0.0, 0.3)), A(s, 0.5 * lead * (1.0 - hit)), 2.0)
	# kiếm thép khổng lồ cắm xuống (mũi dưới)
	var ty := lerpf(-240.0, GY - 4.0, fall)
	var alp := 1.0 - E.sg(t, 0.8, 1.0)
	if t > 0.1 and alp > 0.0:
		E.PG(s, PackedVector2Array([Vector2(cx - 14.0, ty - 200.0), Vector2(cx + 14.0, ty - 200.0), Vector2(cx + 6.0, ty), Vector2(cx - 6.0, ty)]), PackedColorArray([A(s, 0.0), A(s, 0.0), A(s, 0.5 * alp * (1.0 - hit)), A(s, 0.5 * alp * (1.0 - hit))]))
		E.sword(s, Vector2(cx, ty - 160.0), PI * 0.5, 160.0, 26.0, alp)
		E.glow(s, Vector2(cx, ty - 40.0), 50.0, 0.3 * alp * (1.0 - hit))
	if hit > 0.0:
		var e := E.eo(hit)
		E.star(s, Vector2(cx, GY - 10.0), 40.0 * (1.0 - hit * 0.6), (1.0 - hit), 10)
		E.shock(s, Vector2(cx, GY - 4.0), R * e, R * e * 0.26, (1.0 - hit) * fa)
		E.shock(s, Vector2(cx, GY - 4.0), R * e * 0.6, R * e * 0.16, (1.0 - hit) * fa * 0.7)
		# sóng thép: gai thép nhọn bật lên dọc vòng nổ
		var n := 14 if lowq else 26
		for i in range(n):
			var a := TAU * float(i) / float(n)
			var rr := R * e * (0.92 + 0.08 * E.rnd(i, 3))
			var p := Vector2(cx + cos(a) * rr, GY - 4.0 + sin(a) * rr * 0.26)
			var pop := sin(clampf((hit - 0.05 * E.rnd(i, 4)) * 3.2, 0.0, 1.0) * PI)
			spike(s, p, 5.0, (20.0 + 30.0 * E.rnd(i, 5)) * pop, cos(a) * 6.0, fa, STEEL)
		# vòng đai thép bay lan ra
		for k in range(2):
			var rr2 := R * e * (0.55 + 0.25 * float(k))
			E.ering(s, Vector2(cx, GY - 14.0), rr2, rr2 * 0.26, C(STEEL, 0.7 * (1.0 - hit) * fa), 3.0)
		E.crack(s, Vector2(cx, GY - 4.0), R * 0.55 * e, fa, 6)
		E.spark(s, Vector2(cx, GY - 10.0), 8 if lowq else 18, 120.0, hit, (1.0 - hit) * fa, 7)
		E.dust(s, Vector2(cx, GY - 2.0), R * 0.55, hit, (1.0 - hit) * 0.8, 7 if lowq else 11, 2)
