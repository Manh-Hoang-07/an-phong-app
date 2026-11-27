extends RefCounted
## Hiệu ứng kỹ năng VẼ LẠI RIÊNG — sát thủ (các kỹ năng không phải đạn bay; đạn bay xem FxProj.gd).
## Quy ước như FxSkill_Swordsman: place "bodyf", gốc = thân nhân vật, +x = hướng nhìn, y âm = lên, mặt đất y~+32.
const E := preload("res://src/world/fx/FxSkill_Swordsman.gd")

const IDS := {
	"av25": "sg_reaperstep", "st1": "sg_shadowdash", "st6": "sg_slashchain", "st7": "sg_bloodstreak", "av42": "sg_bloodchain",
	"av27": "sg_clonehop", "st9": "sg_erasehop", "av32": "sg_clones", "av35": "sg_decoy", "st4": "sg_cloak",
	"av38": "sg_killintent", "st3": "sg_frenzy", "av40": "sg_hundredstab", "st10": "sg_deathpoint", "st2": "sg_twinslash",
	"av45": "sg_shadowstorm", "st11": "sg_nightveil",
}
const CFG := {
	"sg_reaperstep": {"place": "bodyf", "dur": 0.9, "nopop": true, "nobig": true},
	"sg_shadowdash": {"place": "bodyf", "dur": 0.7, "nopop": true, "nobig": true},
	"sg_slashchain": {"place": "bodyf", "dur": 0.9, "nopop": true, "nobig": true},
	"sg_bloodstreak": {"place": "bodyf", "dur": 0.8, "nopop": true, "nobig": true},
	"sg_bloodchain": {"place": "bodyf", "dur": 1.0, "nopop": true, "nobig": true},
	"sg_clonehop": {"place": "bodyf", "dur": 1.0, "nopop": true, "nobig": true},
	"sg_erasehop": {"place": "bodyf", "dur": 1.0, "nopop": true, "nobig": true},
	"sg_clones": {"place": "bodyf", "dur": 1.4, "nopop": true, "nobig": true},
	"sg_decoy": {"place": "bodyf", "dur": 1.4, "nopop": true, "nobig": true},
	"sg_cloak": {"place": "bodyf", "dur": 1.4, "nopop": true, "nobig": true},
	"sg_killintent": {"place": "bodyf", "dur": 1.4, "nopop": true, "nobig": true},
	"sg_frenzy": {"place": "bodyf", "dur": 1.4, "nopop": true, "nobig": true},
	"sg_hundredstab": {"place": "bodyf", "dur": 1.0, "nopop": true, "nobig": true},
	"sg_deathpoint": {"place": "bodyf", "dur": 0.9, "nopop": true, "nobig": true},
	"sg_twinslash": {"place": "bodyf", "dur": 0.7, "nopop": true, "nobig": true},
	"sg_shadowstorm": {"place": "bodyf", "dur": 1.3, "nopop": true, "nobig": true, "rumble": 4.0},
	"sg_nightveil": {"place": "bodyf", "dur": 1.5, "nopop": true, "nobig": true},
}
## Buff / hộ thể kéo dài: hào quang giữ nguyên suốt thời gian hiệu lực.
const AURA_IDS := ["sg_clones", "sg_decoy", "sg_cloak", "sg_killintent", "sg_frenzy"]

static func draw(s, sg: String, t: float, lowq: bool) -> void:
	match sg:
		"sg_reaperstep": _reaperstep(s, t, lowq)
		"sg_shadowdash": _shadowdash(s, t, lowq)
		"sg_slashchain": _slashchain(s, t, lowq)
		"sg_bloodstreak": _bloodstreak(s, t, lowq)
		"sg_bloodchain": _bloodchain(s, t, lowq)
		"sg_clonehop": _clonehop(s, t, lowq, 3)
		"sg_erasehop": _clonehop(s, t, lowq, 2)
		"sg_clones": _clones(s, t, lowq)
		"sg_decoy": _decoy(s, t, lowq)
		"sg_cloak": _cloak(s, t, lowq)
		"sg_killintent": _killintent(s, t, lowq)
		"sg_frenzy": _frenzy(s, t, lowq)
		"sg_hundredstab": _hundredstab(s, t, lowq)
		"sg_deathpoint": _deathpoint(s, t, lowq)
		"sg_twinslash": _twinslash(s, t, lowq)
		"sg_shadowstorm": _shadowstorm(s, t, lowq)
		"sg_nightveil": _nightveil(s, t, lowq)

static func draw_aura(s, sg: String, t: float, lowq: bool) -> void:
	var tt := 1.0 + t
	match sg:
		"sg_clones": _clones(s, tt, lowq)
		"sg_decoy": _decoy(s, tt, lowq)
		"sg_cloak": _cloak(s, tt, lowq)
		"sg_killintent": _killintent(s, tt, lowq)
		"sg_frenzy": _frenzy(s, tt, lowq)

# ============================================================ tiện ích
const GY := 32.0
const DK := Color(0.05, 0.03, 0.09)

## Khói bom: cụm vòng tròn xám tím nở dần và bay lên.
static func smoke(s, c: Vector2, r: float, t: float, al: float, n: int = 9, seed: int = 0) -> void:
	if al <= 0.01: return
	for i in range(n):
		var a := TAU * E.rnd(i, seed)
		var d := r * (0.2 + 0.8 * E.rnd(i, seed + 3)) * E.eo(t)
		var p := c + Vector2(cos(a) * d, sin(a) * d * 0.5 - 22.0 * t * (0.4 + E.rnd(i, seed + 5)))
		var rr := (9.0 + 12.0 * E.rnd(i, seed + 7)) * (0.5 + t)
		E.CI(s, p, rr, Color(0.14, 0.1, 0.22, 0.4 * al))
		E.CI(s, p + Vector2(-rr * 0.2, -rr * 0.25), rr * 0.6, Color(0.36, 0.28, 0.5, 0.22 * al))

## Dao găm ngắn (dùng thanh kiếm thu nhỏ).
static func dagger(s, hilt: Vector2, ang: float, ln: float, al: float) -> void:
	E.sword(s, hilt, ang, ln, 6.0, al)

## Đường lướt: dải bóng mờ dần từ x0 đến x1 + vạch chém ngang.
static func smear(s, x0: float, x1: float, w: float, al: float, seed: int = 0) -> void:
	if al <= 0.01 or x1 - x0 < 4.0: return
	E.PG(s, PackedVector2Array([Vector2(x0, -w), Vector2(x1, -w * 0.5), Vector2(x1, w * 0.5), Vector2(x0, w)]), PackedColorArray([E.A(s, 0.0), E.A(s, al * 0.5), E.A(s, al * 0.5), E.A(s, 0.0)]))
	E.PG(s, PackedVector2Array([Vector2(x0, -w * 0.4), Vector2(x1, -w * 0.18), Vector2(x1, w * 0.18), Vector2(x0, w * 0.4)]), PackedColorArray([E.K(s, 0.0), E.K(s, al * 0.8), E.K(s, al * 0.8), E.K(s, 0.0)]))
	E.speedlines(s, x0, x1, -w, w, 6, al, seed)

## Một nhát chém cong ngắn (lưỡi hái bóng) ở điểm p.
static func crescent_at(s, p: Vector2, r: float, a0: float, a1: float, head: float, th: float, al: float) -> void:
	E.swoosh(s, p, r, a0, a1, head, 0.8, th, al, 1.0)

# ============================================================ LƯỚT / DASH
## av25 Ảnh Bộ Đoạt Mệnh: lướt 220px xuyên mục tiêu, tử thần chém thêm nhát hái ở điểm kết thúc.
static func _reaperstep(s, t: float, lowq: bool) -> void:
	var D := 220.0
	var run := E.eo(E.sg(t, 0.0, 0.3))
	var fa := E.fadeo(t, 0.7)
	smear(s, 0.0, D * run, 20.0, fa, 3)
	for k in range(1, 5):
		E.man(s, Vector2(D * run * (1.0 - 0.2 * float(k)), 0), 0.34 * (1.0 - 0.18 * float(k)) * fa)
	E.dust(s, Vector2(0, GY), 20.0, E.sg(t, 0.0, 0.5), (1.0 - E.sg(t, 0.2, 0.6)) * 0.8, 5, 1)
	# nhát hái tử thần ở điểm kết thúc: lưỡi liềm lớn + dấu sọ mờ
	var p := E.sg(t, 0.28, 0.5)
	crescent_at(s, Vector2(D - 70.0, 4.0), 130.0, -1.35, 1.05, E.eo(p), 56.0, fa)
	if p >= 1.0:
		var h := E.sg(t, 0.5, 1.0)
		E.cut(s, Vector2(D + 36.0, -80.0), Vector2(D - 20.0, 70.0), 7.0 * (1.0 - h), 1.0 - h)
		E.star(s, Vector2(D, -4.0), 24.0 * (1.0 - h * 0.5), 1.0 - h, 8)
		# dấu sọ tử thần
		var sk := Vector2(D + 4.0, -52.0 - 14.0 * h)
		E.CI(s, sk, 9.0, E.A(s, 0.5 * (1.0 - h)))
		E.CI(s, sk + Vector2(-3, -1), 2.0, Color(0.03, 0.02, 0.05, 0.8 * (1.0 - h)))
		E.CI(s, sk + Vector2(3, -1), 2.0, Color(0.03, 0.02, 0.05, 0.8 * (1.0 - h)))
		E.spark(s, Vector2(D, 0), 10, 60.0, h, 1.0 - h, 2)

## st1 Lướt Bóng: lướt nhanh 160px chém mọi kẻ trên đường, miễn thương: vệt bóng, vạch chém ngang, khói đầu và cuối.
static func _shadowdash(s, t: float, lowq: bool) -> void:
	var D := 160.0
	var run := E.eo(E.sg(t, 0.0, 0.28))
	var fa := E.fadeo(t, 0.6)
	smear(s, -10.0, D * run, 24.0, fa, 5)
	for k in range(5):
		var x := D * run * (0.12 + 0.2 * float(k))
		E.cut(s, Vector2(x - 26.0, -22.0 + 6.0 * float(k)), Vector2(x + 18.0, 18.0 - 4.0 * float(k)), 3.0, fa * 0.8)
	for k in range(1, 4):
		E.man(s, Vector2(D * run * (1.0 - 0.25 * float(k)), 0), 0.3 * (1.0 - 0.25 * float(k)) * fa)
	smoke(s, Vector2(0, 14.0), 26.0, E.sg(t, 0.0, 0.6), E.fadeo(t, 0.2) * 0.9, 6, 1)
	if run >= 1.0:
		smoke(s, Vector2(D, 14.0), 30.0, E.sg(t, 0.28, 0.9), E.fadeo(t, 0.5), 7, 2)
		E.shock(s, Vector2(D, GY - 2.0), 40.0 * E.eo(E.sg(t, 0.28, 0.8)), 8.0, 1.0 - E.sg(t, 0.28, 0.8))

## st6 Ảnh Trảm Liên Kích: lướt 230px, để lại chuỗi nhát chém bóng nối tiếp rồi một nhát chữ X ở cuối.
static func _slashchain(s, t: float, lowq: bool) -> void:
	var D := 230.0
	var run := E.eo(E.sg(t, 0.0, 0.3))
	var fa := E.fadeo(t, 0.75)
	smear(s, 0.0, D * run, 18.0, fa, 7)
	for k in range(1, 4):
		E.man(s, Vector2(D * run * (1.0 - 0.22 * float(k)), 0), 0.3 * (1.0 - 0.22 * float(k)) * fa)
	for k in range(4):
		var tk := 0.18 + 0.1 * float(k)
		var q := E.sg(t, tk, tk + 0.12)
		var x := D * (0.2 + 0.25 * float(k))
		var flip := 1.0 if k % 2 == 0 else -1.0
		if q > 0.0:
			E.cut(s, Vector2(x - 30.0, -34.0 * flip) * Vector2(1, E.eo(q)), Vector2(x + 30.0, 34.0 * flip) * Vector2(1, E.eo(q)), 4.5, fa * (1.0 - 0.2 * float(k)))
			E.flare(s, Vector2(x, 0), 8.0 * (1.0 - E.sg(t, tk + 0.1, tk + 0.35)), fa)
	var xq := E.sg(t, 0.55, 0.75)
	if xq > 0.0:
		var fe := E.fadeo(t, 0.78)
		E.cut(s, Vector2(D - 40.0, -70.0 * E.eo(xq)), Vector2(D + 40.0, 70.0 * E.eo(xq)), 7.0, fe)
		E.cut(s, Vector2(D - 40.0, 70.0 * E.eo(xq)), Vector2(D + 40.0, -70.0 * E.eo(xq)), 7.0, fe)
		E.star(s, Vector2(D, 0), 26.0 * (1.0 - E.sg(t, 0.75, 1.0)), fe, 8)

## st7 Huyết Ảnh Truy Sát: lướt chớp nhoáng 280px như tia máu zigzag, bóng ảnh chém bồi ở cuối.
static func _bloodstreak(s, t: float, lowq: bool) -> void:
	var D := 280.0
	var run := E.eo(E.sg(t, 0.0, 0.22))
	var fa := E.fadeo(t, 0.65)
	var pts := PackedVector2Array()
	for i in range(24):
		var u := float(i) / 23.0 * run
		pts.append(Vector2(D * u, (E.rnd(i, int(t * 20.0)) - 0.5) * 18.0 * (1.0 - u * 0.5)))
	E.PL(s, pts, E.A(s, 0.28 * fa), 14.0)
	E.PL(s, pts, E.A(s, 0.85 * fa), 4.5)
	E.PL(s, pts, E.K(s, fa), 1.6)
	for k in range(1, 4):
		E.man(s, Vector2(D * run * (1.0 - 0.2 * float(k)), 0), 0.3 * (1.0 - 0.22 * float(k)) * fa)
	for i in range(0 if lowq else 14):
		var u2 := E.rnd(i, 1) * run
		var ph := E.sg(t, 0.05, 0.7)
		E.CI(s, Vector2(D * u2, (E.rnd(i, 2) - 0.5) * 20.0 + 40.0 * ph * ph * E.rnd(i, 3)), 2.4 * (1.0 - ph) + 0.6, E.A(s, fa))
	# bóng ảnh chém bồi ở cuối
	var p := E.sg(t, 0.3, 0.5)
	E.man(s, Vector2(D, 0), 0.5 * E.sg(t, 0.25, 0.4) * E.fadeo(t, 0.7))
	crescent_at(s, Vector2(D - 60.0, 4.0), 110.0, -1.3, 1.0, E.eo(p), 46.0, E.fadeo(t, 0.75))
	if p >= 1.0:
		E.star(s, Vector2(D + 30.0, 0), 22.0 * (1.0 - E.sg(t, 0.5, 1.0)), 1.0 - E.sg(t, 0.5, 1.0), 8)

## av42 Huyết Ảnh Liên Hoàn: chuỗi 4 điểm lướt 300px nối bằng sợi máu, mỗi nút một nhát chém.
static func _bloodchain(s, t: float, lowq: bool) -> void:
	var D := 300.0
	var fa := E.fadeo(t, 0.78)
	var nodes := 4
	for k in range(nodes):
		var tk := 0.05 + 0.14 * float(k)
		var q := E.sg(t, tk, tk + 0.12)
		var x := D * float(k + 1) / float(nodes)
		var prev := D * float(k) / float(nodes)
		if q > 0.0:
			# sợi máu nối từ nút trước
			var pts := PackedVector2Array()
			for i in range(13):
				var u := float(i) / 12.0
				pts.append(Vector2(lerpf(prev, x, u * E.eo(q)), sin(u * 9.0 + t * 18.0) * 7.0 * (1.0 - u)))
			E.PL(s, pts, E.A(s, 0.35 * fa), 8.0)
			E.PL(s, pts, E.K(s, 0.9 * fa), 1.6)
			E.man(s, Vector2(x, 0), 0.4 * E.sg(t, tk, tk + 0.1) * fa)
			var flip := 1.0 if k % 2 == 0 else -1.0
			E.cut(s, Vector2(x - 22.0, -30.0 * flip), Vector2(x + 22.0, 30.0 * flip), 4.0, fa * E.sg(t, tk + 0.04, tk + 0.12))
			E.CI(s, Vector2(x, 0), 3.0, E.K(s, fa))
			E.flare(s, Vector2(x, 0), 9.0 * (1.0 - E.sg(t, tk + 0.1, tk + 0.3)), fa)
	E.speedlines(s, 0.0, D * E.eo(E.sg(t, 0.0, 0.6)), -26.0, 26.0, 7, fa * 0.7, 4)

# ============================================================ LÙI / ẢNH PHÂN THÂN BẮN TRẢ
## av27 Ảnh Độn (3 ảnh bắn trả) / st9 Xóa Dấu (2 phi tiêu): bom khói, người nhảy lùi, ảnh để lại bắn trả, dấu chân bị xoá.
static func _clonehop(s, t: float, lowq: bool, n: int) -> void:
	var D := 230.0 if n == 3 else 200.0
	var p := E.eo(E.sg(t, 0.0, 0.4))
	var fa := E.fadeo(t, 0.7)
	smoke(s, Vector2(0, 8.0), 36.0, E.sg(t, 0.0, 0.7), E.fadeo(t, 0.55), 12, 3)
	# đường lùi + tàn ảnh
	var pts := PackedVector2Array()
	for i in range(21):
		var u := float(i) / 20.0 * p
		pts.append(Vector2(-D * u, -34.0 * 4.0 * u * (1.0 - u)))
	E.PL(s, pts, E.A(s, 0.25 * fa), 8.0)
	E.PL(s, pts, E.K(s, 0.6 * fa), 1.4)
	for k in range(1, 4):
		var u2 := maxf(0.0, p - 0.12 * float(k))
		E.man(s, Vector2(-D * u2, -34.0 * 4.0 * u2 * (1.0 - u2)), 0.3 * (1.0 - 0.22 * float(k)) * fa)
	# các ảnh phân thân ở lại bắn trả
	for k in range(n):
		var tk := 0.12 + 0.14 * float(k)
		var ap := E.sg(t, 0.05, 0.15) * (1.0 - E.sg(t, tk + 0.35, tk + 0.6))
		var bp := Vector2(-8.0 + 8.0 * float(k), 0.0) + Vector2(0, (float(k) - float(n - 1) * 0.5) * 12.0)
		E.man(s, bp, 0.55 * ap)
		var q := E.sg(t, tk, tk + 0.2)
		if q > 0.0 and q < 1.0:
			E.flare(s, bp + Vector2(22.0, -6.0), 10.0 * (1.0 - q), 1.0 - q)
			dagger(s, bp + Vector2(18.0 + 26.0 * q, -6.0), 0.0, 26.0, 1.0 - q)
	# dấu chân bị xoá dọc đường lùi
	for i in range(6):
		var fx := -D * float(i) / 6.0 * p
		var fl := E.sg(t, 0.1, 0.9)
		E.AR(s, Vector2(fx, GY - 2.0), 5.0, 0.0, TAU, 10, E.A(s, 0.55 * (1.0 - fl) * fa), 2.0)
	if p >= 1.0:
		smoke(s, Vector2(-D, 10.0), 26.0, E.sg(t, 0.4, 1.0), 1.0 - E.sg(t, 0.4, 1.0), 6, 4)

# ============================================================ BUFF / HỘ THỂ
## av32 Ảnh Phân Thân: hai phân thân bóng đứng hai bên, cùng ra đòn.
static func _clones(s, t: float, lowq: bool) -> void:
	var up := E.eo(E.sg(t, 0.0, 0.25))
	var fa := E.fo(s, t, 0.85)
	var al := up * fa
	E.ering(s, Vector2(0, GY - 4.0), 46.0 * up, 11.0 * up, E.A(s, 0.5 * al), 2.0)
	for k in range(2):
		var sd := -1.0 if k == 0 else 1.0
		var off := Vector2(sd * 38.0 * up, 4.0 * sin(t * 4.0 + float(k) * 2.0))
		var flick := 0.55 + 0.25 * sin(t * 11.0 + float(k) * 1.7)
		# vệt bóng đuôi
		for j in range(1, 4):
			E.man(s, off + Vector2(-sd * 7.0 * float(j) - 6.0, 0), 0.22 * al * (1.0 - 0.25 * float(j)))
		E.man(s, off, flick * al)
		E.glow(s, off + Vector2(0, -8), 22.0, 0.1 * al)
		# phân thân vung dao theo nhịp
		var sw := E.sg(fmod(t * 1.3 + 0.5 * float(k), 1.0), 0.0, 0.3)
		if sw > 0.0 and sw < 1.0:
			E.cut(s, off + Vector2(8.0, -24.0), off + Vector2(46.0, 16.0), 3.0, (1.0 - sw) * al)

## av35 Thế Thân Bóng Tối: bóng thế thân (hình nhân) đứng chịu đòn bên cạnh, thân thật mờ trong màn bóng.
static func _decoy(s, t: float, lowq: bool) -> void:
	var up := E.eo(E.sg(t, 0.0, 0.25))
	var fa := E.fo(s, t, 0.85)
	var al := up * fa
	var c := Vector2(-52.0 * up, 0)
	# hình nhân thế thân: thân gỗ bóng, vết nứt X, nhiễu khói
	E.man(s, c, 0.55 * al)
	E.L(s, c + Vector2(-8, -16), c + Vector2(8, 10), E.K(s, 0.8 * al), 1.6)
	E.L(s, c + Vector2(8, -16), c + Vector2(-8, 10), E.K(s, 0.8 * al), 1.6)
	E.glow(s, c + Vector2(0, -6), 26.0, 0.14 * al)
	smoke(s, c + Vector2(0, 20.0), 20.0, fmod(t * 0.6, 1.0), 0.6 * al, 5, 5)
	# màn bóng che thân thật + vòng đất
	E.ering(s, Vector2(0, GY - 4.0), 44.0 * up, 11.0 * up, E.A(s, 0.55 * al), 2.2)
	for i in range(7):
		var a := TAU * float(i) / 7.0 + t * 1.2
		var pp := Vector2(cos(a) * 26.0, -8.0 + sin(a) * 30.0)
		E.CI(s, pp, 6.0, Color(0.14, 0.1, 0.22, 0.3 * al))
	# lá bùa dấu hiệu thay thân
	for k in range(3):
		var ph := fmod(t * 0.7 + 0.33 * float(k), 1.0)
		var a2 := TAU * float(k) / 3.0 + t
		E.P(s, PackedVector2Array([Vector2(cos(a2) * 22.0, -30.0 + 10.0 * ph - sin(a2) * 8.0), Vector2(cos(a2) * 22.0 + 4.0, -22.0 + 10.0 * ph), Vector2(cos(a2) * 22.0 - 4.0, -22.0 + 10.0 * ph)]), E.K(s, 0.7 * al * (1.0 - ph)))

## st4 Ẩn Thân: áo choàng bóng quấn quanh thân (dải xoắn tối), đôi mắt sáng, giảm 50% sát thương.
static func _cloak(s, t: float, lowq: bool) -> void:
	var up := E.eo(E.sg(t, 0.0, 0.25))
	var fa := E.fo(s, t, 0.85)
	var al := up * fa
	var cy := Vector2(0, -4)
	# dải bóng xoắn quanh thân (3 dải)
	for k in range(3):
		var pts := PackedVector2Array()
		for i in range(32):
			var u := float(i) / 31.0
			var a := u * TAU * 1.7 + t * 3.0 + float(k) * 2.1
			pts.append(cy + Vector2(cos(a) * (24.0 + 6.0 * sin(u * 6.0)) * up, 34.0 - u * 74.0 + sin(a) * 5.0))
		E.PL(s, pts, E.A(s, 0.28 * al), 9.0)
		E.PL(s, pts, E.A(s, 0.65 * al), 3.0)
	# tấm áo choàng phủ sau lưng + mũ trùm
	E.P(s, PackedVector2Array([cy + Vector2(-6, -26), cy + Vector2(-30, 8), cy + Vector2(-22, 38), cy + Vector2(0, 30), cy + Vector2(6, -22)]), Color(0.1, 0.07, 0.17, 0.5 * al))
	smoke(s, Vector2(0, 28.0), 30.0, fmod(t * 0.5, 1.0), 0.7 * al, 7, 6)
	# đôi mắt sáng dưới mũ
	var ey := Vector2(5.0, -26.0)
	E.L(s, ey + Vector2(-5, 0), ey + Vector2(-1, -1.5), E.K(s, al), 2.2)
	E.L(s, ey + Vector2(2, -1.5), ey + Vector2(6, 0), E.K(s, al), 2.2)
	E.glow(s, ey, 8.0, 0.4 * al)

## av38 Sát Ý Dâng Trào: sát ý đỏ ngùn ngụt (lưỡi lửa máu), đôi mắt đỏ, dấu sọ mờ trên đầu.
static func _killintent(s, t: float, lowq: bool) -> void:
	var up := E.eo(E.sg(t, 0.0, 0.25))
	var fa := E.fo(s, t, 0.85)
	var al := up * fa
	E.glow(s, Vector2(0, -6), 52.0 * up, 0.16 * al)
	E.ering(s, Vector2(0, GY - 4.0), 44.0 * up, 11.0 * up, E.A(s, 0.8 * al), 2.2)
	var n := 7 if lowq else 11
	for i in range(n):
		var a := TAU * float(i) / float(n)
		var base := Vector2(cos(a) * 36.0, GY - 4.0 + sin(a) * 9.0)
		E.flame(s, base, (44.0 + 30.0 * E.rnd(i, 2)) * up, 7.0, t, float(i), al * (0.6 if sin(a) < 0.0 else 1.0))
	for k in range(2):
		var ex := Vector2(-2.0 + 11.0 * float(k), -26.0)
		E.L(s, ex + Vector2(-4, 1), ex + Vector2(4, -1.5), E.K(s, al), 2.8)
		E.glow(s, ex, 9.0, 0.6 * al)
	# dấu sọ sát ý trên đầu
	var sk := Vector2(2.0, -58.0 - 3.0 * sin(t * 6.0))
	E.CI(s, sk, 9.0 * up, E.A(s, 0.55 * al))
	E.CI(s, sk + Vector2(-3, -1), 2.2, Color(0.03, 0.02, 0.05, 0.85 * al))
	E.CI(s, sk + Vector2(3, -1), 2.2, Color(0.03, 0.02, 0.05, 0.85 * al))
	E.L(s, sk + Vector2(-4, 6), sk + Vector2(4, 6), E.K(s, 0.7 * al), 1.4)

## st3 Cuồng Sát: cuồng loạn — vết cào đỏ quanh thân, tia chớp giật, vạch tốc độ, rung lắc.
static func _frenzy(s, t: float, lowq: bool) -> void:
	var up := E.eo(E.sg(t, 0.0, 0.2))
	var fa := E.fo(s, t, 0.85)
	var al := up * fa
	var jit := Vector2(sin(t * 60.0), cos(t * 53.0)) * 1.6
	E.glow(s, Vector2(0, -6) + jit, 46.0 * up, 0.2 * al)
	E.ering(s, Vector2(0, GY - 4.0), 40.0 * up, 10.0 * up, E.A(s, 0.8 * al), 2.2)
	# vết cào: 3 vệt song song xoay quanh theo nhịp
	for k in range(3):
		var ph := fmod(t * 1.8 + 0.33 * float(k), 1.0)
		var ang := TAU * float(k) / 3.0 + 0.6
		var c := Vector2(cos(ang) * 30.0, -8.0 + sin(ang) * 26.0)
		var fa2 := sin(ph * PI) * al
		for j in range(3):
			var o := (float(j) - 1.0) * 6.0
			E.cut(s, c + Vector2(-10.0 + o, -14.0), c + Vector2(10.0 + o, 14.0), 2.4, fa2)
	# tia giật quanh người
	for k in range(4):
		var a := TAU * float(k) / 4.0 + 0.4 + 0.5 * E.rnd(int(t * 10.0), k)
		var pts := PackedVector2Array([Vector2(cos(a) * 20.0, -6.0 + sin(a) * 28.0)])
		var p := pts[0]
		for q in range(1, 4):
			p += Vector2(cos(a), sin(a) * 1.3) * 8.0 + Vector2((E.rnd(k * 5 + q, int(t * 14.0)) - 0.5) * 8.0, (E.rnd(k * 3 + q, int(t * 14.0) + 2) - 0.5) * 8.0)
			pts.append(p)
		E.PL(s, pts, E.K(s, 0.85 * al), 1.6)
	E.speedlines(s, -50.0, 50.0, -34.0, 30.0, 6, 0.6 * al, int(t * 3.0))
	for k in range(2):
		E.man(s, Vector2((float(k) * 2.0 - 1.0) * 6.0, 0) + jit * float(k + 1), 0.22 * al)

# ============================================================ CẬN CHIẾN
## av40 Bách Ảnh Sát: 7 nhát đâm dồn dập từ nhiều hướng vào một điểm (cánh tay bóng cầm dao), nhát cuối chí mạng.
static func _hundredstab(s, t: float, lowq: bool) -> void:
	var T := Vector2(110.0, -6.0)
	var fa := E.fadeo(t, 0.85)
	E.ering(s, Vector2(T.x, GY - 4.0), 56.0, 13.0, E.A(s, 0.4 * fa * E.sg(t, 0.0, 0.1)), 2.0)
	for k in range(7):
		var tk := 0.04 + 0.085 * float(k)
		var q := E.sg(t, tk, tk + 0.1)
		if q <= 0.0: continue
		var ang := -1.4 + 0.5 * float(k) + 0.2 * (E.rnd(k, 1) - 0.5)
		var d := Vector2(cos(ang), sin(ang))
		var from := T - d * (70.0 - 48.0 * E.eo(q))
		var life := E.fadeo(t, tk + 0.12)
		# cánh tay bóng + dao đâm vào điểm T
		E.L(s, from - d * 28.0, from, E.A(s, 0.5 * life), 6.0)
		dagger(s, from - d * 8.0, ang, 34.0, life)
		E.cut(s, T - d * 40.0, T + d * 16.0, 2.2, life * 0.8)
		E.flare(s, T + Vector2((E.rnd(k, 4) - 0.5) * 16.0, (E.rnd(k, 5) - 0.5) * 16.0), 7.0 * (1.0 - E.sg(t, tk + 0.1, tk + 0.25)), life)
	# nhát chí mạng cuối
	var cq := E.sg(t, 0.64, 0.8)
	if cq > 0.0:
		var fc := E.fadeo(t, 0.82)
		E.cut(s, T + Vector2(-46.0, -50.0) * E.eo(cq), T + Vector2(46.0, 50.0) * E.eo(cq), 8.0, fc)
		E.cut(s, T + Vector2(-46.0, 50.0) * E.eo(cq), T + Vector2(46.0, -50.0) * E.eo(cq), 8.0, fc)
		E.star(s, T, 38.0 * (1.0 - E.sg(t, 0.8, 1.0)), fc, 10)
		E.spark(s, T, 16, 80.0, cq, fc, 3)

## st10 Tử Huyệt: khoá điểm tử huyệt (chấm đỏ + tâm ngắm), một nhát đâm cực mạnh xuyên qua, vòng sóng.
static func _deathpoint(s, t: float, lowq: bool) -> void:
	var T := Vector2(100.0, -10.0)
	var fa := E.fadeo(t, 0.85)
	# khoá mục tiêu
	var lk := E.eo(E.sg(t, 0.0, 0.3))
	var rr := 24.0 * (1.6 - 0.6 * lk)
	E.AR(s, T, rr, 0.0, TAU, 32, E.A(s, 0.8 * lk * fa), 1.8)
	for k in range(4):
		var a := PI * 0.5 * float(k) + t * 2.0
		E.L(s, T + Vector2(cos(a), sin(a)) * (rr - 4.0), T + Vector2(cos(a), sin(a)) * (rr + 8.0), E.K(s, lk * fa), 1.6)
	E.CI(s, T, 3.0 + 1.5 * sin(t * 30.0), E.K(s, lk * fa))
	E.glow(s, T, 16.0, 0.4 * lk * fa)
	# nhát đâm
	var q := E.eo(E.sg(t, 0.34, 0.5))
	if q > 0.0:
		var from := Vector2(10.0, -10.0).lerp(T - Vector2(8.0, 0), q)
		E.PG(s, PackedVector2Array([Vector2(10, -10), from + Vector2(0, -6), from + Vector2(14, -10), from + Vector2(0, 6)]), PackedColorArray([E.A(s, 0.0), E.A(s, 0.5 * fa), E.A(s, 0.0), E.A(s, 0.5 * fa)]))
		dagger(s, from - Vector2(34.0, 0), 0.0, 44.0, fa)
	if q >= 1.0:
		var h := E.sg(t, 0.5, 1.0)
		E.star(s, T, 30.0 * (1.0 - h * 0.6), 1.0 - h, 8)
		E.shock(s, T + Vector2(0, 6), 10.0 + 60.0 * E.eo(h), 10.0 + 60.0 * E.eo(h), 1.0 - h)
		for k in range(8):
			var a2 := TAU * float(k) / 8.0
			E.L(s, T + Vector2(cos(a2), sin(a2)) * 12.0, T + Vector2(cos(a2), sin(a2)) * (20.0 + 50.0 * E.eo(h)), E.A(s, 1.0 - h), 2.0)
		E.spark(s, T, 12, 70.0, h, 1.0 - h, 4)

## st2 Nhát Kép: hai nhát liên tiếp từ hai hướng cắt nhau thành chữ X (hai con dao).
static func _twinslash(s, t: float, lowq: bool) -> void:
	var c := Vector2(54.0, -2.0)
	var fa := E.fadeo(t, 0.8)
	for k in range(2):
		var tk := 0.08 + 0.22 * float(k)
		var q := E.sg(t, tk, tk + 0.18)
		if q <= 0.0: continue
		var flip := 1.0 if k == 0 else -1.0
		var life := E.fadeo(t, tk + 0.25)
		var a0 := -0.9 * flip - 0.35
		var a1 := 0.9 * flip - 0.35
		E.swoosh(s, c - Vector2(18.0, 0), 64.0, a0, a1, E.eo(q), 0.8, 24.0, life)
		E.swing(s, c - Vector2(18.0, 0), 64.0, a0, a1, E.eo(q), life)
	if t > 0.36:
		var e := E.sg(t, 0.36, 0.55)
		E.star(s, c + Vector2(10.0, 0), 22.0 * (1.0 - E.sg(t, 0.55, 1.0)), fa * e, 8)
		E.spark(s, c + Vector2(10.0, 0), 8, 50.0, E.sg(t, 0.36, 0.9), fa, 6)

# ============================================================ DIỆN RỘNG
## av45 Vạn Ảnh Tuyệt Sát (r=270): bóng tối nổ quanh người, nhiều bóng ảnh vây quanh cùng chém chí mạng vào tâm.
static func _shadowstorm(s, t: float, lowq: bool) -> void:
	var R := 270.0
	var fa := E.fadeo(t, 0.82)
	var gc := Vector2(0, GY - 6.0)
	var e := E.eo(E.sg(t, 0.0, 0.4))
	# bóng tối nổ lan ra
	for i in range(6):
		E.CI(s, Vector2(0, -6), R * 0.6 * e * (1.0 - float(i) * 0.14), Color(0.1, 0.06, 0.16, 0.05 * fa))
	E.shock(s, gc, R * e, R * e * 0.24, fa)
	# 8 bóng ảnh vây quanh chém vào tâm theo thứ tự
	var n := 8 if not lowq else 5
	for i in range(n):
		var a := TAU * float(i) / float(n) + 0.3
		var rr := R * 0.7 * e
		var pos := Vector2(cos(a) * rr, sin(a) * rr * 0.28 - 4.0)
		var tk := 0.25 + 0.06 * float(i)
		E.man(s, pos, 0.5 * E.sg(t, 0.1, 0.25) * fa)
		var q := E.sg(t, tk, tk + 0.12)
		if q > 0.0:
			var d := (Vector2(0, -6) - pos).normalized()
			E.cut(s, pos, pos + d * (rr * 0.9) * E.eo(q), 4.0, fa * (1.0 - 0.3 * q))
			E.flare(s, pos + d * (rr * 0.9) * E.eo(q), 10.0 * (1.0 - q * 0.6), fa)
	# chớp chí mạng ở tâm
	var cq := E.sg(t, 0.62, 0.85)
	if cq > 0.0:
		var fc := E.fadeo(t, 0.88)
		E.star(s, Vector2(0, -6), 46.0 * (1.0 - cq * 0.3), fc, 12)
		for k in range(10):
			var a2 := TAU * float(k) / 10.0
			E.cut(s, Vector2(0, -6) + Vector2(cos(a2), sin(a2) * 0.5) * 14.0, Vector2(0, -6) + Vector2(cos(a2), sin(a2) * 0.5) * (30.0 + 200.0 * E.eo(cq)), 3.0, fc * 0.8)
	E.spark(s, Vector2(0, -6), 22, R * 0.8, E.sg(t, 0.3, 1.0), fa, 4)

## st11 Bóng Đêm Bao Phủ (r=250, làm chậm mạnh): màn đêm trùm xuống — vòm tối nở ra, hồ bóng dưới đất, xúc tu bóng trói chậm.
static func _nightveil(s, t: float, lowq: bool) -> void:
	var R := 250.0
	var fa := E.fadeo(t, 0.78)
	var e := E.eo(E.sg(t, 0.0, 0.45))
	var gc := Vector2(0, GY - 6.0)
	# vòm bóng đêm: các lớp elip chồng tối dần ra mép
	for i in range(8):
		var u := float(i) / 7.0
		var k := (1.0 - u * 0.75)
		E.CI(s, Vector2(0, -50.0 * u), R * 0.5 * e * k, Color(0.07, 0.04, 0.13, 0.04 * fa))
	# hồ bóng dưới đất
	for i in range(5):
		var u2 := float(i) / 4.0
		E.ering(s, gc, R * e * (1.0 - u2 * 0.5), R * e * (1.0 - u2 * 0.5) * 0.24, Color(0.2, 0.12, 0.35, 0.2 * fa), 10.0 - 2.0 * float(i))
	E.ering(s, gc, R * e, R * e * 0.24, E.A(s, 0.9 * fa), 2.4)
	# xúc tu bóng trồi lên từ mặt đất
	var n := 9 if not lowq else 5
	for i in range(n):
		var x := (E.rnd(i, 1) - 0.5) * R * 2.0 * 0.85 * e
		var h := (46.0 + 40.0 * E.rnd(i, 2)) * E.sg(t, 0.1 + 0.04 * float(i), 0.5)
		var pts := PackedVector2Array()
		for k in range(10):
			var u3 := float(k) / 9.0
			pts.append(Vector2(x + sin(u3 * 6.0 + t * 5.0 + float(i)) * 8.0 * u3, GY - 8.0 - h * u3))
		E.PL(s, pts, E.A(s, 0.3 * fa), 9.0)
		E.PL(s, pts, E.A(s, 0.8 * fa), 3.5 - 2.0 * E.rnd(i, 3))
		E.CI(s, pts[pts.size() - 1], 2.4, E.K(s, fa))
	# sợi xích bóng làm chậm: các vòng mờ dưới chân
	for i in range(0 if lowq else 12):
		var a := TAU * E.rnd(i, 8)
		var rr := R * e * E.rnd(i, 9)
		var p := gc + Vector2(cos(a) * rr, sin(a) * rr * 0.24)
		E.AR(s, p + Vector2(0, -2), 5.0, 0.0, TAU, 10, E.K(s, 0.5 * fa), 1.6)
	E.spark(s, Vector2(0, -10), 12, R * 0.8, E.sg(t, 0.2, 1.0), fa * 0.7, 6)
