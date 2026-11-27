extends RefCounted
## Hiệu ứng kỹ năng VẼ LẠI RIÊNG — cung thủ (các kỹ năng không phải đạn bay; đạn bay xem FxProj.gd).
## Quy ước như FxSkill_Swordsman: place "bodyf", gốc = thân nhân vật, +x = hướng nhìn, y âm = lên, mặt đất y~+32.
const E := preload("res://src/world/fx/FxSkill_Swordsman.gd")
const P := preload("res://src/world/fx/FxProj.gd")

const IDS := {
	"hl5": "af_arrowrain", "hl7": "af_stormarrow", "xa40": "af_skynet", "ulCung2": "af_firerain", "xa45": "af_divinefire",
	"xa38": "af_spirittrap", "hl3": "af_eagleeye", "xa35": "af_divineeye", "hl4": "af_hopback", "xa30": "af_hopshoot",
}
const CFG := {
	"af_arrowrain": {"place": "bodyf", "dur": 2.0, "nopop": true, "nobig": true},
	"af_stormarrow": {"place": "bodyf", "dur": 2.1, "nopop": true, "nobig": true},
	"af_skynet": {"place": "bodyf", "dur": 2.2, "nopop": true, "nobig": true},
	"af_firerain": {"place": "bodyf", "dur": 2.4, "nopop": true, "nobig": true},
	"af_divinefire": {"place": "bodyf", "dur": 2.4, "nopop": true, "nobig": true, "rumble": 6.0},
	"af_spirittrap": {"place": "bodyf", "dur": 1.5, "nopop": true, "nobig": true},
	"af_eagleeye": {"place": "bodyf", "dur": 1.5, "nopop": true, "nobig": true},
	"af_divineeye": {"place": "bodyf", "dur": 1.6, "nopop": true, "nobig": true},
	"af_hopback": {"place": "bodyf", "dur": 0.8, "nopop": true, "nobig": true},
	"af_hopshoot": {"place": "bodyf", "dur": 1.0, "nopop": true, "nobig": true},
}
## Hào quang buff kéo dài (s.steady): chỉ hai kỹ năng buff.
const AURA_IDS := ["af_eagleeye", "af_divineeye"]

static func draw(s, sg: String, t: float, lowq: bool) -> void:
	match sg:
		"af_arrowrain": _rain(s, t, lowq, "plain", 12, 360.0, 2.0, false)
		"af_stormarrow": _storm(s, t, lowq)
		"af_skynet": _skynet(s, t, lowq)
		"af_firerain": _rain(s, t, lowq, "fire", 24, 600.0, 2.4, true)
		"af_divinefire": _divinefire(s, t, lowq)
		"af_spirittrap": _spirittrap(s, t, lowq)
		"af_eagleeye": _eagleeye(s, t, lowq)
		"af_divineeye": _divineeye(s, t, lowq)
		"af_hopback": _hop(s, t, lowq, 0)
		"af_hopshoot": _hop(s, t, lowq, 4)

static func draw_aura(s, sg: String, t: float, lowq: bool) -> void:
	match sg:
		"af_eagleeye": _eagleeye(s, 1.0 + t, lowq)
		"af_divineeye": _divineeye(s, 1.0 + t, lowq)

# ============================================================ tiện ích
const GY := 32.0

## Một mũi tên rơi từ trời: bay chéo từ (x-90, -300) xuống (x, gy) trong ft giây, rồi cắm lại. tl = giây đã trôi, land = giây chạm đất.
static func _fall_arrow(s, x: float, gy: float, tl: float, land: float, style: String, ln: float, fade_after: float) -> float:
	var ft := 0.36
	var p := (tl - (land - ft)) / ft
	if p <= 0.0: return -1.0
	var a_start := Vector2(x - 90.0, -300.0)
	var a_end := Vector2(x, gy)
	if p < 1.0:
		var q := E.ei(p) * 0.85 + p * 0.15
		var pos := a_start.lerp(a_end, q)
		var dv := (a_end - a_start).normalized()
		s.draw_set_transform(pos, atan2(dv.y, dv.x), Vector2.ONE)
		P._arrow(s, "", tl, style, ln)
		E.rst(s)
		return p
	# đã cắm xuống: mũi tên nghiêng cắm trong đất
	var age := tl - land
	var al := clampf(1.0 - age / fade_after, 0.0, 1.0)
	var dv2 := (a_end - a_start).normalized()
	var ang := atan2(dv2.y, dv2.x)
	s.draw_set_transform(a_end - dv2 * ln * 0.55 + Vector2(0, 2), ang, Vector2.ONE)
	P._arrow(s, "", 0.0, "plain", ln)
	E.rst(s)
	return 1.0 + age

static func _impact(s, x: float, gy: float, age: float, style: String, lowq: bool) -> void:
	var e := E.eo(E.sg(age, 0.0, 0.35))
	var fa := 1.0 - E.sg(age, 0.15, 0.55)
	if fa <= 0.0: return
	E.ering(s, Vector2(x, gy), 6.0 + 26.0 * e, 2.0 + 8.0 * e, E.A(s, fa * 0.85), 2.0)
	if style == "fire":
		E.flame(s, Vector2(x, gy), 34.0 * e, 8.0, age * 3.0, x * 0.3, fa)
		E.flame(s, Vector2(x + 7.0, gy), 22.0 * e, 6.0, age * 3.0, x * 0.3 + 2.0, fa * 0.8)
	elif style == "spirit":
		for i in range(3):
			var u := E.sg(age, 0.0, 0.6)
			E.CI(s, Vector2(x + (float(i) - 1.0) * 6.0, gy - 36.0 * u * (0.6 + 0.4 * float(i % 2))), 4.0 * (1.0 - u) + 1.0, E.A(s, fa))
	else:
		E.dust(s, Vector2(x, gy), 14.0, age * 1.5, fa, 3 if lowq else 5, int(x))
	E.spark(s, Vector2(x, gy - 4.0), 5, 22.0, age * 1.5, fa, int(x))

## Vùng mưa: elip mờ trên đất đúng bề rộng + vạch chia.
static func _zone(s, cx: float, W: float, al: float) -> void:
	E.ering(s, Vector2(cx, GY - 2.0), W * 0.5, 13.0, E.A(s, 0.18 * al), 8.0)
	E.ering(s, Vector2(cx, GY - 2.0), W * 0.5, 13.0, E.A(s, 0.55 * al), 1.6)

# ============================================================ MƯA TÊN / MƯA TÊN LỬA
## hl5 Mưa Tên & ulCung2 Thiên Hỏa Mưa Tên: n mũi tên rơi xuống vùng rộng W phía trước (đúng nhịp tính sát thương), cắm đất.
static func _rain(s, t: float, lowq: bool, style: String, n: int, W: float, dur: float, fire: bool) -> void:
	var tl := t * dur
	var cx := W * 0.5 + 30.0
	var zone_a := E.eo(E.sg(t, 0.0, 0.1)) * (1.0 - E.sg(t, 0.85, 1.0))
	_zone(s, cx, W, zone_a)
	if fire:
		# bầu trời đỏ rực phía trên vùng
		for i in range(6):
			E.CI(s, Vector2(cx, -250.0), (W * 0.45) * (1.0 - float(i) * 0.14), Color(1.0, 0.3, 0.1, 0.035 * zone_a))
	# xạ thủ giương cung bắn lên trời rồi buông
	var bpull := 16.0 * E.eo(E.sg(tl, 0.0, 0.16)) * (1.0 - E.sg(tl, 0.16, 0.2))
	E.bow(s, Vector2(14.0, -12.0), -1.15, 26.0, bpull, sin(tl * 90.0) * 2.0 * E.sg(tl, 0.2, 0.3) * (1.0 - E.sg(tl, 0.3, 0.5)), 1.0 - E.sg(tl, 0.35, 0.5), tl < 0.18)
	# loạt tên bắn lên trời lúc đầu
	var up := E.sg(tl, 0.0, 0.3)
	if up > 0.0 and up < 1.0:
		for k in range(3):
			var yy := -10.0 - 280.0 * E.eo(up) - 20.0 * float(k)
			E.L(s, Vector2(24.0 + 14.0 * float(k), yy + 70.0), Vector2(30.0 + 22.0 * float(k), yy), E.A(s, 0.8 * (1.0 - up)), 2.4)
			E.glow(s, Vector2(30.0 + 22.0 * float(k), yy), 8.0, 0.4 * (1.0 - up))
	var nn := n if not lowq else int(n * 0.6)
	for i in range(nn):
		var x := cx + (E.rnd(i, 1) - 0.5) * W * 0.92
		var gy := GY - 2.0 + (E.rnd(i, 2) - 0.5) * 14.0
		var land := 0.15 + float(i) * (1.2 / float(n)) + 0.26
		var r := _fall_arrow(s, x, gy, tl, land, style, 48.0, 0.9)
		if r >= 1.0:
			_impact(s, x, gy, r - 1.0, style, lowq)
			if fire:
				# lửa cháy nán trên mặt đất nơi tên rơi
				var age := r - 1.0
				var la := 1.0 - E.sg(age, 0.3, 1.0)
				if la > 0.0: E.flame(s, Vector2(x, gy), 22.0, 6.0, tl * 2.0, float(i), la * 0.8)

## hl7 Bão Tên Định Mệnh: bão linh hồn trên trời (mây tối, sét, vòng tên ma xoáy) trút 16 mũi tên ma xuống vùng 430px.
static func _storm(s, t: float, lowq: bool) -> void:
	var dur := 2.1
	var tl := t * dur
	var W := 430.0
	var cx := W * 0.5 + 30.0
	var za := E.eo(E.sg(t, 0.0, 0.1)) * (1.0 - E.sg(t, 0.85, 1.0))
	_zone(s, cx, W, za)
	# mây bão và sét
	var ca := za
	for i in range(8):
		var cc := Vector2(cx + (float(i) - 3.5) * 58.0, -200.0 + sin(tl * 1.4 + float(i)) * 6.0)
		for j in range(4):
			E.CI(s, cc + Vector2((float(j) - 1.5) * 22.0, (E.rnd(i + j, 3) - 0.5) * 14.0), 24.0 + 8.0 * E.rnd(i, j), Color(0.28, 0.34, 0.55, 0.12 * ca))
		E.CI(s, cc + Vector2(0, -8.0), 22.0, Color(0.5, 0.6, 0.9, 0.06 * ca))
	var fl := E.rnd(int(tl * 9.0), 3)
	if fl > 0.7:
		var bx := cx + (E.rnd(int(tl * 9.0), 4) - 0.5) * W * 0.6
		var pts := PackedVector2Array([Vector2(bx, -190.0)])
		for k in range(1, 5):
			pts.append(Vector2(bx + (E.rnd(k, int(tl * 9.0)) - 0.5) * 30.0, -190.0 + 46.0 * float(k)))
		E.PL(s, pts, E.K(s, 0.9 * ca), 2.0)
	# vòng tên ma xoáy trên đầu vùng
	for i in range(10):
		var a := TAU * float(i) / 10.0 + tl * 3.0
		var p := Vector2(cx + cos(a) * W * 0.35, -170.0 + sin(a) * 26.0)
		var tang := a + PI * 0.5
		s.draw_set_transform(p, atan2(sin(tang) * 0.3, cos(tang)), Vector2(0.55, 0.55))
		P._arrow(s, "", tl, "spirit", 40.0)
		E.rst(s)
	var nn := 16 if not lowq else 10
	for i in range(nn):
		var x := cx + (E.rnd(i, 1) - 0.5) * W * 0.92
		var gy := GY - 2.0 + (E.rnd(i, 2) - 0.5) * 14.0
		var land := 0.15 + float(i) * (1.2 / 16.0) + 0.26
		var r := _fall_arrow(s, x, gy, tl, land, "spirit", 46.0, 0.8)
		if r >= 1.0: _impact(s, x, gy, r - 1.0, "spirit", lowq)

## xa40 Thiên Võng Xạ Kích: mưa tên cắm xuống, giữa các mũi tên giăng lưới ánh sáng, cuối cùng lưới chớp sáng.
static func _skynet(s, t: float, lowq: bool) -> void:
	var dur := 2.2
	var tl := t * dur
	var W := 420.0
	var cx := W * 0.5 + 30.0
	var za := E.eo(E.sg(t, 0.0, 0.1)) * (1.0 - E.sg(t, 0.88, 1.0))
	_zone(s, cx, W, za)
	var n := 18
	var landed: Array = []
	for i in range(n):
		var x := cx - W * 0.46 + W * 0.92 * (float(i) + E.rnd(i, 1) * 0.6) / float(n)
		var gy := GY - 2.0 + (E.rnd(i, 2) - 0.5) * 10.0
		var land := 0.15 + float(i) * (1.2 / float(n)) + 0.26
		var r := _fall_arrow(s, x, gy, tl, land, "seal", 46.0, 1.6)
		if r >= 1.0:
			landed.append(Vector2(x, gy - 52.0 - 18.0 * E.rnd(i, 7)))
			_impact(s, x, gy, r - 1.0, "plain", lowq)
	# lưới nối đầu các mũi tên (mỗi mũi nối với 2 mũi kế)
	var glowk := 1.0 - E.sg(t, 0.9, 1.0)
	# dây lưới võng xuống giữa các mũi tên (mỗi mũi nối với 3 mũi kế, có độ chùng) + sợi dọc xuống đất
	for i in range(landed.size()):
		var a: Vector2 = landed[i]
		for j in range(i + 1, mini(i + 4, landed.size())):
			var b: Vector2 = landed[j]
			var pts := PackedVector2Array()
			for k in range(9):
				var u := float(k) / 8.0
				pts.append(a.lerp(b, u) + Vector2(0, 14.0 * sin(u * PI) * (1.0 + 0.3 * float(j - i))))
			E.PL(s, pts, E.A(s, 0.35 * za * glowk), 3.0)
			E.PL(s, pts, E.K(s, 0.85 * za * glowk), 1.1)
		E.L(s, a, a + Vector2(0, 36.0), E.A(s, 0.5 * za * glowk), 1.2)
	for p in landed:
		E.CI(s, p as Vector2, 2.8, E.K(s, za))
		E.glow(s, p as Vector2, 8.0, 0.3 * za * glowk)
	# chớp lưới lúc cuối
	var fl := E.sg(t, 0.7, 0.8) * (1.0 - E.sg(t, 0.8, 0.95))
	if fl > 0.0 and landed.size() > 2:
		E.glow(s, Vector2(cx, -10.0), W * 0.5, 0.35 * fl)

## xa45 Thiên Hỏa Thần Tiễn: mưa tên lửa 520px và một mũi thần tiễn lửa khổng lồ giáng giữa vùng, nổ.
static func _divinefire(s, t: float, lowq: bool) -> void:
	var dur := 2.4
	var tl := t * dur
	var W := 520.0
	var cx := W * 0.5 + 30.0
	_rain(s, t, lowq, "fire", 24, W, dur, true)
	var land := 0.62 + 0.28
	var p := (tl - (land - 0.45)) / 0.45
	var gp := Vector2(cx, GY - 2.0)
	if p > 0.0 and p < 1.0:
		var pos := Vector2(cx - 30.0, -330.0).lerp(gp + Vector2(0, -90.0), E.ei(p))
		var dv := (gp - Vector2(cx - 30.0, -330.0)).normalized()
		s.draw_set_transform(pos, atan2(dv.y, dv.x), Vector2(2.6, 2.6))
		P._arrow(s, "", tl, "fire", 90.0)
		E.rst(s)
		E.glow(s, pos, 50.0, 0.6)
	if p >= 1.0:
		var age := tl - land
		var e := E.eo(E.sg(age, 0.0, 0.5))
		var fa := 1.0 - E.sg(age, 0.3, 1.2)
		E.shock(s, gp, 170.0 * e, 170.0 * e * 0.24, fa)
		E.star(s, gp + Vector2(0, -20.0), 56.0 * (1.0 - age * 0.5), fa, 10)
		for k in range(7):
			E.flame(s, gp + Vector2((float(k) - 3.0) * 20.0, 0), (60.0 + 40.0 * E.rnd(k, 1)) * e, 12.0, tl * 3.0, float(k), fa)
		E.spark(s, gp + Vector2(0, -20.0), 18, 120.0, age, fa, 3)
		E.dust(s, gp, 120.0 * e, age, fa, 8, 2)

# ============================================================ BẪY LINH QUANG
## xa38: bẫy sáng nổ quanh người (r=220), làm chậm quái: trận bẫy trên đất, các cột sáng + dây ánh sáng trói.
static func _spirittrap(s, t: float, lowq: bool) -> void:
	var R := 220.0
	var up := E.eo(E.sg(t, 0.0, 0.25))
	var boom := E.sg(t, 0.35, 1.0)
	var fa := E.fadeo(t, 0.8)
	var gc := Vector2(0, GY - 6.0)
	# trận bẫy: hai vòng + hình sao 6 cánh + 6 nút sáng
	E.ering(s, gc, R * up, R * up * 0.24, E.A(s, 0.35 * fa), 8.0)
	E.ering(s, gc, R * up, R * up * 0.24, E.A(s, 0.95 * fa), 2.4)
	E.ering(s, gc, R * 0.62 * up, R * 0.62 * up * 0.24, E.K(s, 0.7 * fa), 1.6)
	for i in range(6):
		var a := TAU * float(i) / 6.0 + t * 0.8
		var b := TAU * float((i + 2) % 6) / 6.0 + t * 0.8
		var pa := gc + Vector2(cos(a), sin(a) * 0.24) * R * 0.62 * up
		var pb := gc + Vector2(cos(b), sin(b) * 0.24) * R * 0.62 * up
		E.L(s, pa, pb, E.A(s, 0.7 * fa), 1.6)
	# cột sáng bắn lên từ 6 nút rồi cụp vào thành dây trói
	for i in range(6):
		var a2 := TAU * float(i) / 6.0 + t * 0.8
		var pn := gc + Vector2(cos(a2), sin(a2) * 0.24) * R * 0.62 * up
		var h := 90.0 * E.sg(t, 0.2 + 0.03 * float(i), 0.5) * (1.0 - 0.6 * boom)
		if h > 2.0:
			E.beam(s, pn.x, pn.y - h, pn.y, 5.0, 9.0, fa)
			E.flare(s, pn + Vector2(0, -h), 6.0, fa * 0.8)
	# nổ ra: sóng ánh sáng + xích sáng lan khắp vùng
	if boom > 0.0:
		var e := E.eo(boom)
		E.shock(s, gc, R * e, R * e * 0.24, fa)
		for i in range(8):
			var a3 := TAU * float(i) / 8.0 + 0.2
			var d := Vector2(cos(a3), sin(a3) * 0.3)
			E.cut(s, gc + d * R * 0.1, gc + d * R * e, 4.0, fa * 0.8)
		for i in range(0 if lowq else 14):
			var a4 := TAU * E.rnd(i, 1)
			var rr := R * e * E.rnd(i, 2)
			var p := gc + Vector2(cos(a4) * rr, sin(a4) * rr * 0.24 - 20.0 * boom)
			E.star(s, p, 4.0, fa * (1.0 - boom * 0.5), 4)
		E.glow(s, gc, 60.0 * (1.0 - boom), 0.6)

# ============================================================ BUFF
## hl3 Mắt Ưng: mắt ưng lớn trên đầu + tâm ngắm quay, đôi cánh ưng mờ sau lưng, tia khoá mục tiêu.
static func _eagleeye(s, t: float, lowq: bool) -> void:
	var up := E.eo(E.sg(t, 0.0, 0.25))
	var fa := E.fo(s, t, 0.8)
	var al := up * fa
	var c := Vector2(2.0, -62.0)
	# đôi cánh ưng xoè sau lưng (lông vũ)
	for sd in [-1.0, 1.0]:
		for k in range(6):
			var u := float(k) / 5.0
			var tip := Vector2(-6.0 + float(sd) * 8.0, -30.0) + Vector2(float(sd) * (24.0 + 36.0 * u), -18.0 + 34.0 * u + 4.0 * sin(t * 7.0 + float(k)))
			E.cut(s, Vector2(-6.0, -30.0), tip, 3.4 - u * 1.2, al * 0.35)
	# mắt ưng: hình hạnh nhân + tròng + đồng tử dọc + ánh phản chiếu
	var ew := 26.0 * up
	var top := PackedVector2Array()
	var bot := PackedVector2Array()
	for i in range(13):
		var u := float(i) / 12.0
		var x := lerpf(-ew, ew, u)
		var hh := 11.0 * sin(u * PI) * up
		top.append(c + Vector2(x, -hh))
		bot.append(c + Vector2(x, hh * 0.85))
	E.PL(s, top, E.K(s, al), 2.2)
	E.PL(s, bot, E.K(s, al), 2.2)
	E.glow(s, c, 22.0, 0.35 * al)
	E.CI(s, c, 8.5 * up, E.A(s, 0.95 * al))
	E.CI(s, c, 5.8 * up, E.M(s, 0.5, 0.95 * al))
	E.P(s, PackedVector2Array([c + Vector2(0, -6.0 * up), c + Vector2(2.2, 0), c + Vector2(0, 6.0 * up), c + Vector2(-2.2, 0)]), Color(0.04, 0.03, 0.02, 0.9 * al))
	E.CI(s, c + Vector2(-2.6, -2.8), 1.7, E.K(s, al))
	# tâm ngắm quay quanh mắt
	var ra := t * 1.4
	E.AR(s, c, 34.0 * up, ra, ra + 1.2, 12, E.K(s, al), 2.0)
	E.AR(s, c, 34.0 * up, ra + PI, ra + PI + 1.2, 12, E.K(s, al), 2.0)
	E.AR(s, c, 34.0 * up, 0.0, TAU, 48, E.A(s, 0.3 * al), 1.2)
	for k in range(4):
		var a := PI * 0.5 * float(k) + PI * 0.25
		E.L(s, c + Vector2(cos(a), sin(a)) * 30.0, c + Vector2(cos(a), sin(a)) * 40.0, E.K(s, al), 1.6)
	# tia khoá mục tiêu hướng ra phía trước
	for k in range(3):
		var y := -2.0 * float(k)
		E.L(s, c + Vector2(40.0, 0), c + Vector2(40.0 + 70.0 * up, y), E.A(s, 0.25 * al * (1.0 - float(k) * 0.3)), 1.4)

## xa35 Thần Nhãn: con mắt thần vàng toả tia, khung khoá mục tiêu, ba vòng ngắm quay ngược chiều.
static func _divineeye(s, t: float, lowq: bool) -> void:
	var up := E.eo(E.sg(t, 0.0, 0.25))
	var fa := E.fo(s, t, 0.82)
	var al := up * fa
	var c := Vector2(2.0, -68.0)
	E.glow(s, c, 50.0 * up, 0.35 * al)
	# tia toả quanh mắt
	for i in range(16):
		var a := TAU * float(i) / 16.0 + t * 0.5
		var ln := (30.0 if i % 2 == 0 else 22.0) * up
		E.L(s, c + Vector2(cos(a), sin(a)) * 32.0, c + Vector2(cos(a), sin(a)) * (32.0 + ln), E.K(s, 0.8 * al), 1.6 if i % 2 == 0 else 1.0)
	# ba vòng ngắm quay
	E.AR(s, c, 30.0 * up, t * 1.6, t * 1.6 + 4.2, 24, E.A(s, 0.9 * al), 2.2)
	E.AR(s, c, 38.0 * up, -t * 1.2, -t * 1.2 + 3.6, 24, E.K(s, 0.7 * al), 1.6)
	E.AR(s, c, 46.0 * up, t * 0.8, t * 0.8 + 2.6, 24, E.A(s, 0.5 * al), 1.4)
	# mắt thần: hạnh nhân lớn + tròng + đồng tử sao
	var ew := 24.0 * up
	var top := PackedVector2Array()
	var bot := PackedVector2Array()
	for i in range(13):
		var u := float(i) / 12.0
		var x := lerpf(-ew, ew, u)
		var hh := 12.0 * sin(u * PI) * up
		top.append(c + Vector2(x, -hh))
		bot.append(c + Vector2(x, hh))
	E.PL(s, top, E.K(s, al), 2.4)
	E.PL(s, bot, E.K(s, al), 2.4)
	E.CI(s, c, 9.0 * up, E.A(s, 0.95 * al))
	E.CI(s, c, 6.0 * up, E.K(s, 0.95 * al))
	E.star(s, c, 5.0 * up, al, 4)
	# khung khoá mục tiêu ở bốn góc phía trước
	var bx := Vector2(78.0 * up, -6.0)
	for sx in [-1.0, 1.0]:
		for sy in [-1.0, 1.0]:
			var q := bx + Vector2(float(sx) * 18.0, float(sy) * 18.0)
			E.L(s, q, q - Vector2(float(sx) * 8.0, 0), E.K(s, 0.9 * al), 2.0)
			E.L(s, q, q - Vector2(0, float(sy) * 8.0), E.K(s, 0.9 * al), 2.0)
	E.flare(s, bx, 8.0 + 2.0 * sin(t * 6.0), 0.7 * al)

# ============================================================ LÙI NÉ / BƯỚC LÙI LIÊN XẠ
## hl4, xa30: nhảy lùi 160px (đường parabol), tàn ảnh, gió/lông vũ, bụi hai đầu; xa30 loé nòng 4 lần phía trước.
static func _hop(s, t: float, lowq: bool, shots: int) -> void:
	var D := 160.0
	var p := E.eo(E.sg(t, 0.0, 0.45))
	var fa := E.fadeo(t, 0.6)
	# đường nhảy
	var pts := PackedVector2Array()
	for i in range(21):
		var u := float(i) / 20.0 * p
		pts.append(Vector2(-D * u, -58.0 * 4.0 * u * (1.0 - u)))
	E.PL(s, pts, E.A(s, 0.28 * fa), 9.0)
	E.PL(s, pts, E.K(s, 0.75 * fa), 1.6)
	# tàn ảnh dọc đường
	for k in range(1, 5):
		var u2 := maxf(0.0, p - 0.12 * float(k))
		E.man(s, Vector2(-D * u2, -58.0 * 4.0 * u2 * (1.0 - u2)), 0.34 * (1.0 - 0.2 * float(k)) * fa)
	# vạch gió + lông vũ
	E.speedlines(s, -D, 30.0, -34.0, 30.0, 8, fa * (1.0 - E.sg(t, 0.4, 0.7)), 3)
	for i in range(0 if lowq else 6):
		var ph := E.sg(t, 0.05 + 0.05 * float(i), 0.7)
		var fx := -D * p * E.rnd(i, 1) + 10.0
		var fy := -10.0 + 40.0 * ph * ph - 30.0 * E.rnd(i, 2)
		E.P(s, PackedVector2Array([Vector2(fx, fy), Vector2(fx - 9.0, fy + 3.0), Vector2(fx - 3.0, fy + 7.0)]), E.A(s, 0.7 * fa * (1.0 - ph)))
	# bụi lúc bật và lúc chạm đất
	E.dust(s, Vector2(4.0, GY), 22.0, E.sg(t, 0.0, 0.6), E.fadeo(t, 0.15) * 0.9, 6, 1)
	if p >= 1.0:
		var q := E.sg(t, 0.45, 1.0)
		E.dust(s, Vector2(-D, GY), 26.0, q, 1.0 - q, 7, 2)
		E.shock(s, Vector2(-D, GY - 2.0), 40.0 * E.eo(q), 8.0 * E.eo(q), 1.0 - q)
	# cung trong tay: giương, bắn rồi thu lại theo từng lần bắn
	var bs := 1.0 - E.sg(t, 0.75, 0.95)
	var bp := pingpong(t * float(maxi(shots, 1)) * 3.0, 1.0) * 12.0
	E.bow(s, Vector2(14.0, -8.0) + Vector2(-D * p, -58.0 * 4.0 * p * (1.0 - p)), -0.1, 24.0, bp, 0.0, bs, true)
	# loé nòng liên xạ
	for k in range(shots):
		var tk := 0.14 + 0.15 * float(k)
		var qk := E.sg(t, tk, tk + 0.22)
		if qk > 0.0 and qk < 1.0:
			var c := Vector2(-D * E.eo(E.sg(tk, 0.0, 0.45)) + 26.0, -2.0 - 20.0 * 4.0 * E.eo(E.sg(tk, 0.0, 0.45)) * (1.0 - E.eo(E.sg(tk, 0.0, 0.45))))
			E.flare(s, c, 11.0 * (1.0 - qk), 1.0 - qk)
			E.ering(s, c, 5.0 + 14.0 * qk, 8.0 + 18.0 * qk, E.A(s, 0.8 * (1.0 - qk)), 2.0)
	if shots == 0:
		var c1 := Vector2(-D * 0.3 + 26.0, -20.0)
		var q1 := E.sg(t, 0.12, 0.4)
		if q1 > 0.0 and q1 < 1.0:
			E.flare(s, c1, 11.0 * (1.0 - q1), 1.0 - q1)
