extends RefCounted
## Hiệu ứng kỹ năng riêng: sát thủ (sat_thu) + cung thủ (cung_thu).
## Vẽ lên node `s` (Node2D đang trong _draw): s.draw_*, s._a(alpha) màu chính, s._k(alpha) màu lõi, s._mix(t, alpha).
## IDS: id kỹ năng -> sig. CFG: sig -> {"place": "front"|"body"|"ground"|"far", "dur", "nopop", "rumble"}.
## Toạ độ: +x = hướng nhìn, y âm = lên trên. Không tạo node; chỉ vẽ.
const IDS := {
	# --- Sát thủ
	"av25": "sx_reaperstep", "st1": "sx_shadowdash", "st6": "sx_slashchain",
	"st7": "sx_bloodchase", "av42": "sx_bloodchain",
	"av27": "sx_smokebomb", "st9": "sx_erasetrace",
	"av30": "sx_ghostdagger", "av37": "sx_daggerrain", "st5": "sx_hundredcuts",
	"st8": "sx_poisonstar", "ulSat1": "sx_bloodblades",
	"av32": "sx_clonesplit", "av35": "sx_substitute", "st4": "sx_fadecloak",
	"av38": "sx_killaura", "st3": "sx_frenzy",
	"av40": "sx_multistab", "st10": "sx_deathpoint", "st2": "sx_crossslash",
	"av45": "sx_shadowstorm", "st11": "sx_darkveil",
	# --- Cung thủ
	"hl1": "ax_piercearrow", "hl10": "ax_heartarrow", "xa25": "ax_sealarrow",
	"hl11": "ax_firevolley", "hl2": "ax_triplearrow", "hl9": "ax_rapidshot", "xa37": "ax_fivearrows",
	"hl3": "ax_eagleeye", "xa35": "ax_divineeye",
	"hl4": "ax_hopback", "xa30": "ax_hopshoot",
	"hl5": "ax_arrowrain", "hl7": "ax_arrowstorm", "xa40": "ax_skynet",
	"ulCung2": "ax_firerain", "xa45": "ax_fireshaft",
	"hl6": "ax_homing", "hl8": "ax_icearrow", "ulCung1": "ax_nebula",
	"xa27": "ax_swiftarrow", "xa32": "ax_armorbreak", "xa38": "ax_spirittrap", "xa42": "ax_starhoming",
}
const CFG := {
	"sx_reaperstep": {"place": "front", "dur": 0.8, "nopop": true},
	"sx_shadowdash": {"place": "front", "dur": 0.7, "nopop": true},
	"sx_slashchain": {"place": "front", "dur": 0.8, "nopop": true},
	"sx_bloodchase": {"place": "front", "dur": 0.75, "nopop": true},
	"sx_bloodchain": {"place": "front", "dur": 0.85, "nopop": true},
	"sx_smokebomb": {"place": "body", "dur": 0.9, "nopop": true},
	"sx_erasetrace": {"place": "ground", "dur": 0.9, "nopop": true},
	"sx_ghostdagger": {"place": "front", "dur": 0.75, "nopop": true},
	"sx_daggerrain": {"place": "far", "dur": 1.0, "nopop": true},
	"sx_hundredcuts": {"place": "front", "dur": 0.9, "nopop": true},
	"sx_poisonstar": {"place": "front", "dur": 0.85, "nopop": true},
	"sx_bloodblades": {"place": "body", "dur": 1.1, "nopop": true},
	"sx_clonesplit": {"place": "body", "dur": 0.9, "nopop": true},
	"sx_substitute": {"place": "body", "dur": 0.9, "nopop": true},
	"sx_fadecloak": {"place": "body", "dur": 1.0, "nopop": true},
	"sx_killaura": {"place": "body", "dur": 1.0, "nopop": true},
	"sx_frenzy": {"place": "body", "dur": 0.9, "nopop": true},
	"sx_multistab": {"place": "front", "dur": 0.7, "nopop": true},
	"sx_deathpoint": {"place": "front", "dur": 0.8, "nopop": true},
	"sx_crossslash": {"place": "front", "dur": 0.6, "nopop": true},
	"sx_shadowstorm": {"place": "body", "dur": 1.0, "nopop": true},
	"sx_darkveil": {"place": "body", "dur": 1.2, "nopop": true},
	"ax_piercearrow": {"place": "front", "dur": 0.7, "nopop": true},
	"ax_heartarrow": {"place": "front", "dur": 0.8, "nopop": true},
	"ax_sealarrow": {"place": "front", "dur": 0.9, "nopop": true},
	"ax_firevolley": {"place": "front", "dur": 0.8, "nopop": true},
	"ax_triplearrow": {"place": "front", "dur": 0.65, "nopop": true},
	"ax_rapidshot": {"place": "front", "dur": 0.8, "nopop": true},
	"ax_fivearrows": {"place": "front", "dur": 0.75, "nopop": true},
	"ax_eagleeye": {"place": "body", "dur": 0.9, "nopop": true},
	"ax_divineeye": {"place": "body", "dur": 1.1, "nopop": true},
	"ax_hopback": {"place": "body", "dur": 0.7, "nopop": true},
	"ax_hopshoot": {"place": "body", "dur": 0.8, "nopop": true},
	"ax_arrowrain": {"place": "far", "dur": 1.3, "nopop": true},
	"ax_arrowstorm": {"place": "far", "dur": 1.3, "nopop": true},
	"ax_skynet": {"place": "far", "dur": 1.2, "nopop": true},
	"ax_firerain": {"place": "far", "dur": 1.3, "nopop": true, "rumble": 3.0},
	"ax_fireshaft": {"place": "far", "dur": 1.0, "nopop": true, "rumble": 4.0},
	"ax_homing": {"place": "front", "dur": 0.85, "nopop": true},
	"ax_icearrow": {"place": "front", "dur": 0.8, "nopop": true},
	"ax_nebula": {"place": "front", "dur": 1.0, "nopop": true},
	"ax_swiftarrow": {"place": "front", "dur": 0.55, "nopop": true},
	"ax_armorbreak": {"place": "front", "dur": 0.8, "nopop": true},
	"ax_spirittrap": {"place": "ground", "dur": 1.0, "nopop": true},
	"ax_starhoming": {"place": "front", "dur": 0.9, "nopop": true},
}

# ----------------------------------------------------------------- tiện ích
static func _rn(i: int, k: int) -> float:
	return fposmod(sin(float(i) * 12.9898 + float(k) * 78.233) * 43758.5453, 1.0)

static func _glow(s, c: Vector2, r: float, al: float) -> void:
	for i in range(4):
		var u := float(i) / 3.0
		s.draw_circle(c, r * (1.0 - u * 0.75), s._mix(u, al * (0.25 + 0.3 * u)))

static func _arrow(s, p: Vector2, ang: float, L: float, al: float) -> void:
	var d := Vector2.from_angle(ang)
	var n := d.orthogonal()
	var tail := p - d * L
	s.draw_line(tail, p - d * 4.0, s._a(al), 2.2)
	s.draw_line(tail, p - d * 4.0, s._k(al), 0.9)
	s.draw_colored_polygon(PackedVector2Array([p + d * 8.0, p - d * 3.0 + n * 4.0, p - d * 3.0 - n * 4.0]), s._k(al))
	s.draw_line(tail, tail - d * 4.0 + n * 4.5, s._a(al), 1.6)
	s.draw_line(tail, tail - d * 4.0 - n * 4.5, s._a(al), 1.6)
	s.draw_line(tail + d * 4.0, tail + d * 0.0 + n * 4.5, s._a(al), 1.4)
	s.draw_line(tail + d * 4.0, tail + d * 0.0 - n * 4.5, s._a(al), 1.4)

static func _trail(s, p: Vector2, ang: float, L: float, w: float, al: float) -> void:
	var d := Vector2.from_angle(ang)
	var n := d.orthogonal()
	s.draw_colored_polygon(PackedVector2Array([p, p - d * L + n * w, p - d * L - n * w]), s._a(al * 0.4))
	s.draw_colored_polygon(PackedVector2Array([p, p - d * L * 0.6 + n * w * 0.4, p - d * L * 0.6 - n * w * 0.4]), s._k(al * 0.55))

static func _dagger(s, p: Vector2, ang: float, sz: float, al: float) -> void:
	var d := Vector2.from_angle(ang)
	var n := d.orthogonal()
	s.draw_colored_polygon(PackedVector2Array([p + d * sz, p + n * sz * 0.2, p - d * sz * 0.35, p - n * sz * 0.2]), s._k(al))
	s.draw_line(p + d * sz, p - d * sz * 0.35, s._a(al), 1.2)
	s.draw_line(p - d * sz * 0.35 + n * sz * 0.3, p - d * sz * 0.35 - n * sz * 0.3, s._a(al), 2.0)
	s.draw_line(p - d * sz * 0.35, p - d * sz * 0.8, s._a(al), 2.4)

static func _fig(s, p: Vector2, al: float, sc: float) -> void:
	s.draw_circle(p + Vector2(0, -22.0 * sc), 5.5 * sc, s._a(al))
	s.draw_colored_polygon(PackedVector2Array([p + Vector2(-7, -16) * sc, p + Vector2(7, -16) * sc, p + Vector2(9, 12) * sc, p + Vector2(-9, 12) * sc]), s._a(al))

static func _cres(s, c: Vector2, r: float, a0: float, a1: float, th: float, al: float) -> void:
	var n := 14
	var pts := PackedVector2Array()
	for i in range(n + 1):
		var a := lerpf(a0, a1, float(i) / float(n))
		pts.append(c + Vector2.from_angle(a) * r)
	for i in range(n, -1, -1):
		var u := float(i) / float(n)
		var a2 := lerpf(a0, a1, u)
		pts.append(c + Vector2.from_angle(a2) * (r - th * sin(u * PI)))
	s.draw_colored_polygon(pts, s._k(al))
	s.draw_arc(c, r, a0, a1, n, s._a(al), 2.0)

static func _star4(s, c: Vector2, r: float, rot: float, al: float) -> void:
	var pts := PackedVector2Array()
	for i in range(8):
		var a := rot + TAU * float(i) / 8.0
		pts.append(c + Vector2.from_angle(a) * (r if i % 2 == 0 else r * 0.3))
	s.draw_colored_polygon(pts, s._k(al))
	s.draw_circle(c, r * 0.28, s._a(al))

static func _flame(s, p: Vector2, h: float, w: float, al: float) -> void:
	s.draw_colored_polygon(PackedVector2Array([p + Vector2(-w, 0), p + Vector2(0, -h), p + Vector2(w, 0)]), s._a(al))
	s.draw_colored_polygon(PackedVector2Array([p + Vector2(-w * 0.5, 0), p + Vector2(0, -h * 0.6), p + Vector2(w * 0.5, 0)]), s._k(al))

static func _ell(s, c: Vector2, r: float, ry: float, al: float, w: float) -> void:
	s.draw_set_transform(c, 0.0, Vector2(1.0, ry))
	s.draw_arc(Vector2.ZERO, r, 0.0, TAU, 32, s._a(al), w)
	s.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

static func _disc(s, c: Vector2, r: float, ry: float, al: float) -> void:
	s.draw_set_transform(c, 0.0, Vector2(1.0, ry))
	s.draw_circle(Vector2.ZERO, r, s._a(al))
	s.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

static func _fade(t: float, from: float) -> float:
	return clampf(1.0 - (t - from) / (1.0 - from), 0.0, 1.0)

## Mưa vật rơi (tên/dao) vào vùng đất: kind 0 tên, 1 dao.
static func _rain(s, t: float, n: int, rad: float, kind: int, fire: bool, fall: float) -> void:
	_disc(s, Vector2.ZERO, rad, 0.3, 0.12 * minf(1.0, t * 3.0))
	_ell(s, Vector2.ZERO, rad, 0.3, 0.6 * minf(1.0, t * 3.0), 2.5)
	for k in range(n):
		var x := -rad + 2.0 * rad * _rn(k, 1)
		var d := _rn(k, 2) * 0.55
		var gy := (_rn(k, 3) - 0.5) * 26.0
		var q := clampf((t - d) / 0.28, 0.0, 1.0)
		if q <= 0.0: continue
		var y := lerpf(-fall, gy, q * q)
		var ang := PI * 0.5 + 0.18
		var px := x + (1.0 - q) * -fall * 0.18
		if q < 1.0:
			_trail(s, Vector2(px, y), ang, 46.0, 3.0, 0.7)
			if fire: _flame(s, Vector2(px, y - 8.0), 12.0, 3.5, 0.7)
		var al := 1.0 if q < 1.0 else maxf(0.0, 1.0 - (t - d - 0.28) * 3.0)
		if kind == 0: _arrow(s, Vector2(px, y), ang, 24.0, al)
		else: _dagger(s, Vector2(px, y), ang, 14.0, al)
		if q >= 1.0:
			var r := minf(1.0, (t - d - 0.28) * 4.0)
			_ell(s, Vector2(px, gy), 6.0 + 20.0 * r, 0.35, 0.9 * (1.0 - r), 2.0)
			if fire and r < 0.8: _flame(s, Vector2(px, gy), 18.0 * (1.0 - r), 5.0, 0.8)

## Chùm tên bay theo quạt.
static func _volley(s, t: float, n: int, spread: float, dist: float, delay: float, fire: bool, trl: float) -> void:
	for i in range(n):
		var u := float(i) - float(n - 1) * 0.5
		var ang := u * spread
		var q := clampf(t * 1.5 - float(i) * delay, 0.0, 1.0)
		if q <= 0.0: continue
		var p := Vector2.from_angle(ang) * (-24.0 + dist * q)
		var al := 1.0 if q < 1.0 else maxf(0.0, 1.0 - (t * 1.5 - float(i) * delay - 1.0) * 4.0)
		_trail(s, p, ang, trl, 4.0, 0.8 * al)
		if fire:
			for j in range(3):
				_flame(s, p - Vector2.from_angle(ang) * (8.0 + 9.0 * j) + Vector2(0, -2), 9.0 - 2.0 * j, 3.0, 0.7 * al)
		_arrow(s, p, ang, 26.0, al)

# ----------------------------------------------------------------- vẽ
static func draw(s, sg: String, t: float, lowq: bool) -> void:
	match sg:
		# ======================= SÁT THỦ =======================
		"sx_reaperstep":
			# nhảy bóng cách quãng để lại các bóng đen, kết thúc bằng nhát X của thần chết
			for i in range(5):
				var vis := clampf(t * 1.7 - float(i) * 0.13, 0.0, 1.0)
				if vis <= 0.0: continue
				_fig(s, Vector2(-70.0 + 32.0 * float(i), 4.0), 0.55 * vis * (0.35 + 0.13 * float(i)) * _fade(t, 0.55), 1.0)
				s.draw_line(Vector2(-84.0 + 32.0 * float(i), -6), Vector2(-60.0 + 32.0 * float(i), -6), s._a(0.4 * vis * _fade(t, 0.5)), 2.0)
			if t > 0.45:
				var c := clampf((t - 0.45) * 2.2, 0.0, 1.0)
				var o := Vector2(78, -10)
				var a := _fade(t, 0.7)
				s.draw_line(o + Vector2(-26, -26) * c, o + Vector2(26, 26) * c, s._k(a), 3.0)
				s.draw_line(o + Vector2(26, -26) * c, o + Vector2(-26, 26) * c, s._k(a), 3.0)
				s.draw_line(o + Vector2(-26, -26) * c, o + Vector2(26, 26) * c, s._a(a * 0.5), 8.0)
				_glow(s, o, 20.0 * c, a * 0.8)
		"sx_shadowdash":
			# vệt mờ ngang + một bóng dẫn đầu
			var hx := -60.0 + 130.0 * minf(1.0, t * 1.5)
			for i in range(7):
				var y := -22.0 + 7.0 * float(i)
				var L := 40.0 + 60.0 * _rn(i, 4)
				s.draw_line(Vector2(hx - L, y), Vector2(hx, y), s._a(0.45 * _fade(t, 0.4)), 2.0 + _rn(i, 5) * 2.0)
			for g in range(3):
				_fig(s, Vector2(hx - 22.0 * float(g + 1), 4), 0.35 * (1.0 - float(g) * 0.28) * _fade(t, 0.5), 1.0)
			_fig(s, Vector2(hx, 4), 0.8 * _fade(t, 0.5), 1.0)
		"sx_slashchain":
			# ba nhát trăng khuyết liên tiếp, đổi hướng
			for i in range(3):
				var q := clampf((t - 0.12 * float(i)) * 3.0, 0.0, 1.0)
				if q <= 0.0: continue
				var sgn := 1.0 if i % 2 == 0 else -1.0
				var c := Vector2(-20.0 + 40.0 * float(i), -8.0 + 4.0 * sgn)
				var a0 := -1.9 if sgn > 0 else -1.2
				var al := _fade(t, 0.3 + 0.12 * float(i))
				_cres(s, c, 46.0, a0, a0 + 2.6 * q * sgn, 14.0, 0.95 * al)
				s.draw_line(c + Vector2(-50, -30 * sgn), c + Vector2(50, 30 * sgn) * q, s._a(0.5 * al), 2.0)
		"sx_bloodchase":
			# vệt máu đỏ lao tới + giọt máu văng, kết thúc bằng vệt toé
			var red := Color(0.85, 0.05, 0.1)
			var hx := -40.0 + 120.0 * minf(1.0, t * 1.6)
			s.draw_line(Vector2(-40, -4), Vector2(hx, -4), Color(red.r, red.g, red.b, 0.5 * _fade(t, 0.5)), 8.0)
			s.draw_line(Vector2(-40, -4), Vector2(hx, -4), s._k(0.9 * _fade(t, 0.5)), 2.0)
			for k in range(10 if not lowq else 5):
				var q := fposmod(t * 1.3 + _rn(k, 6), 1.0)
				var p := Vector2(hx - 60.0 * q - 10.0, -4.0 + (_rn(k, 7) - 0.5) * 30.0 + q * 24.0)
				s.draw_circle(p, 3.0 - 1.5 * q, Color(red.r, red.g, red.b, 0.9 * (1.0 - q)))
			if t > 0.55:
				var c := (t - 0.55) / 0.45
				for k in range(9):
					var a := -PI + PI * float(k) / 8.0 + 0.2 * _rn(k, 8)
					var L := (14.0 + 26.0 * _rn(k, 9)) * c
					s.draw_line(Vector2(78, -4) + Vector2.from_angle(a) * 6.0, Vector2(78, -4) + Vector2.from_angle(a) * (6.0 + L), Color(red.r, red.g, red.b, 1.0 - c), 3.0)
		"sx_bloodchain":
			# chuỗi giọt máu nối nhau, từng khâu bừng sáng lần lượt
			var red := Color(0.8, 0.03, 0.08)
			var n := 5
			for i in range(n):
				var p := Vector2(-50.0 + 36.0 * float(i), -6.0 + sin(float(i) * 1.7) * 14.0)
				if i > 0:
					var pp := Vector2(-50.0 + 36.0 * float(i - 1), -6.0 + sin(float(i - 1) * 1.7) * 14.0)
					var lq := clampf(t * 2.2 - float(i) * 0.3, 0.0, 1.0)
					s.draw_line(pp, pp.lerp(p, lq), Color(red.r, red.g, red.b, 0.8 * _fade(t, 0.6)), 3.0)
				var q := clampf(t * 2.2 - float(i) * 0.3 + 0.3, 0.0, 1.0)
				if q <= 0.0: continue
				var al := _fade(t, 0.65)
				s.draw_circle(p, 9.0 * q, Color(red.r, red.g, red.b, 0.8 * al))
				s.draw_arc(p, 9.0 + 14.0 * q, 0.0, TAU, 20, s._a(0.7 * (1.0 - q * 0.6) * al), 2.0)
				s.draw_circle(p, 3.5 * q, s._k(al))
				s.draw_colored_polygon(PackedVector2Array([p + Vector2(-4, 0), p + Vector2(4, 0), p + Vector2(0, 12.0 * q)]), Color(red.r, red.g, red.b, 0.8 * al))
		"sx_smokebomb":
			# bom khói: nhiều đám khói tròn bung ra, cuộn lên; vệt lùi
			var n := 8 if lowq else 14
			for k in range(n):
				var a := TAU * float(k) / float(n) + _rn(k, 1)
				var R := (14.0 + 34.0 * _rn(k, 2)) * minf(1.0, t * 2.0)
				var c := Vector2(cos(a) * R, sin(a) * R * 0.6 - 4.0 - 14.0 * t)
				var r := 11.0 + 10.0 * _rn(k, 3) + 8.0 * t
				s.draw_circle(c, r, s._a(0.32 * _fade(t, 0.3)))
				s.draw_circle(c + Vector2(-2, -3), r * 0.55, s._mix(0.5, 0.2 * _fade(t, 0.3)))
			s.draw_arc(Vector2(0, -4), 8.0 + 40.0 * t, 0.0, TAU, 28, s._k(0.5 * (1.0 - t)), 2.0)
			for i in range(3):
				s.draw_line(Vector2(-20.0 - 30.0 * t, -14.0 + 12.0 * float(i)), Vector2(10, -14.0 + 12.0 * float(i)), s._a(0.4 * _fade(t, 0.2)), 2.0)
		"sx_erasetrace":
			# dấu chân trên đất lần lượt bị xoá sạch bởi một đường quét + bụi
			for i in range(6):
				var x := -60.0 + 24.0 * float(i)
				var gone := clampf((t * 1.4 - float(i) * 0.1) * 2.0 - 0.5, 0.0, 1.0)
				var al := (1.0 - gone) * 0.8
				var y := 0.0 if i % 2 == 0 else 8.0
				_disc(s, Vector2(x, y), 8.0, 0.45, al)
				_disc(s, Vector2(x + 7.0, y), 4.0, 0.45, al)
			var sx := -70.0 + 140.0 * t
			s.draw_line(Vector2(sx, -14), Vector2(sx - 12, 18), s._k(0.7 * _fade(t, 0.7)), 3.0)
			for k in range(8):
				var q := fposmod(t * 1.6 + _rn(k, 3), 1.0)
				s.draw_circle(Vector2(sx - 40.0 * q, 6.0 - 26.0 * q + _rn(k, 4) * 10.0), 3.0 + 3.0 * q, s._a(0.4 * (1.0 - q)))
		"sx_ghostdagger":
			# một phi đao + 4 bóng mờ phía sau, kèm khói ma
			var hx := -40.0 + 150.0 * minf(1.0, t * 1.6)
			for g in range(4, 0, -1):
				_dagger(s, Vector2(hx - 18.0 * float(g), -4.0 + sin(t * 20.0 + float(g)) * 3.0), 0.0, 12.0, 0.22 * float(5 - g) * _fade(t, 0.6))
			_trail(s, Vector2(hx, -4), 0.0, 60.0, 5.0, 0.8 * _fade(t, 0.6))
			_dagger(s, Vector2(hx, -4), 0.0, 17.0, _fade(t, 0.65))
			for k in range(6):
				var q := fposmod(t * 1.5 + _rn(k, 3), 1.0)
				s.draw_circle(Vector2(hx - 14.0 - 50.0 * q, -4.0 + (_rn(k, 4) - 0.5) * 26.0), 4.0 * (1.0 - q), s._mix(0.5, 0.5 * (1.0 - q)))
		"sx_daggerrain":
			_rain(s, t, 6 if lowq else 11, 80.0, 1, false, 220.0)
		"sx_hundredcuts":
			# hàng chục đường chém ngẫu nhiên loé liên tiếp
			var n := 12 if lowq else 26
			for k in range(n):
				var d := _rn(k, 1) * 0.6
				var q := (t - d) / 0.25
				if q < 0.0 or q > 1.0: continue
				var c := Vector2(20.0 + (_rn(k, 2) - 0.5) * 90.0, -10.0 + (_rn(k, 3) - 0.5) * 60.0)
				var a := _rn(k, 4) * PI
				var v := Vector2.from_angle(a)
				var L := 26.0 + 22.0 * _rn(k, 5)
				var e := minf(1.0, q * 2.5)
				s.draw_line(c - v * L, c - v * L + v * L * 2.0 * e, s._a(0.5 * (1.0 - q)), 6.0)
				s.draw_line(c - v * L, c - v * L + v * L * 2.0 * e, s._k(1.0 - q), 2.0)
			_glow(s, Vector2(20, -10), 40.0 * sin(t * PI), 0.5)
		"sx_poisonstar":
			# ba phi tiêu hình sao xoay, vệt độc xanh, giọt độc nhỏ
			var gc := Color(0.5, 0.9, 0.2)
			for i in range(3):
				var ang := (float(i) - 1.0) * 0.22
				var q := clampf(t * 1.5 - float(i) * 0.08, 0.0, 1.0)
				var p := Vector2.from_angle(ang) * (-20.0 + 130.0 * q)
				var al := _fade(t, 0.65)
				s.draw_line(Vector2.from_angle(ang) * -20.0, p, Color(gc.r, gc.g, gc.b, 0.35 * al), 4.0)
				var pts := PackedVector2Array()
				for j in range(8):
					var a := t * 16.0 + TAU * float(j) / 8.0
					pts.append(p + Vector2.from_angle(a) * (9.0 if j % 2 == 0 else 3.5))
				s.draw_colored_polygon(pts, Color(0.75, 0.95, 0.5, al))
				s.draw_circle(p, 3.0, Color(gc.r, gc.g, gc.b, al))
				for k in range(3):
					var dq := fposmod(t * 1.8 + _rn(i * 5 + k, 2), 1.0)
					s.draw_circle(p - Vector2(10.0 + 24.0 * dq, -16.0 * dq * dq), 2.6 * (1.0 - dq), Color(gc.r, gc.g, gc.b, 0.9 * (1.0 - dq)))
		"sx_bloodblades":
			# vòng dao vây quanh rồi thu về tâm, nổ vệt máu
			var red := Color(0.85, 0.04, 0.08)
			var n := 10 if lowq else 16
			var conv := clampf(t / 0.65, 0.0, 1.0)
			var R := lerpf(110.0, 12.0, conv * conv)
			for k in range(n):
				var a := TAU * float(k) / float(n) + t * 3.0
				var p := Vector2(cos(a) * R, sin(a) * R * 0.55 - 6.0)
				if conv < 1.0:
					_dagger(s, p, a + PI, 14.0, 1.0)
					s.draw_line(p, p + Vector2.from_angle(a + PI * 0.5) * 18.0, Color(red.r, red.g, red.b, 0.5), 3.0)
			s.draw_arc(Vector2(0, -6), R, 0.0, TAU, 40, Color(red.r, red.g, red.b, 0.4), 2.0)
			if t > 0.65:
				var c := (t - 0.65) / 0.35
				for k in range(14):
					var a := TAU * float(k) / 14.0
					var v := Vector2.from_angle(a)
					s.draw_line(Vector2(0, -6) + v * 10.0 * c, Vector2(0, -6) + v * (20.0 + 60.0 * _rn(k, 3)) * c, Color(red.r, red.g, red.b, 1.0 - c), 4.0)
					s.draw_line(Vector2(0, -6) + v * 10.0 * c, Vector2(0, -6) + v * (20.0 + 60.0 * _rn(k, 3)) * c, s._k(1.0 - c), 1.5)
				_glow(s, Vector2(0, -6), 40.0 * (1.0 - c * 0.5), 0.8 * (1.0 - c))
		"sx_clonesplit":
			# bóng phân thân tách khỏi người sang hai bên
			var sp := clampf(t * 2.0, 0.0, 1.0)
			for i in range(4):
				var side := -1.0 if i % 2 == 0 else 1.0
				var off := (28.0 + 26.0 * float(i / 2)) * sp * side
				var al := 0.5 * _fade(t, 0.55) * (1.0 - 0.25 * float(i / 2))
				_fig(s, Vector2(off, 4.0), al, 1.0)
				s.draw_line(Vector2(off * 0.3, -4), Vector2(off, -4), s._k(0.35 * al), 2.0)
			_fig(s, Vector2(0, 4), 0.35, 1.0)
			s.draw_arc(Vector2(0, -6), 20.0 + 50.0 * t, 0.0, TAU, 32, s._k(0.7 * (1.0 - t)), 2.0)
		"sx_substitute":
			# khúc gỗ thế thân + khói, thân thật tan thành bóng
			var q := minf(1.0, t * 2.5)
			_fig(s, Vector2(-34.0 * q, 4), 0.4 * _fade(t, 0.3), 1.0)
			var c := Vector2(10.0, 0.0)
			var tilt := sin(t * 14.0) * 0.12 * (1.0 - t)
			s.draw_set_transform(c, tilt, Vector2.ONE)
			s.draw_rect(Rect2(-9, -26, 18, 44), s._a(0.85))
			s.draw_rect(Rect2(-9, -26, 18, 8), s._k(0.8))
			s.draw_line(Vector2(-9, -6), Vector2(9, -6), s._k(0.9), 2.0)
			s.draw_line(Vector2(-9, 8), Vector2(9, 8), s._k(0.9), 2.0)
			s.draw_line(Vector2(-5, -14), Vector2(5, -2), s._k(0.9), 1.5)
			s.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			for k in range(8 if not lowq else 4):
				var a := TAU * float(k) / 8.0
				var R := 10.0 + 38.0 * minf(1.0, t * 1.8)
				s.draw_circle(c + Vector2(cos(a) * R, sin(a) * R * 0.6), 10.0, s._a(0.3 * _fade(t, 0.3)))
		"sx_fadecloak":
			# viền nhân vật nét đứt mờ dần + vạch quét dọc, lấp lánh
			var pts := PackedVector2Array([Vector2(-8, -17), Vector2(-8, 12), Vector2(8, 12), Vector2(8, -17)])
			var alp := 0.9 * (1.0 - t) + 0.1
			for i in range(8):
				var u := float(i) / 8.0
				if fposmod(u * 4.0 + t * 3.0, 1.0) < 0.55:
					var a0 := TAU * u
					s.draw_arc(Vector2(0, -6), 26.0 + 4.0 * sin(t * 9.0), a0, a0 + TAU / 12.0, 6, s._k(alp), 2.0)
			s.draw_polyline(PackedVector2Array([pts[0], pts[1], pts[2], pts[3], pts[0]]), s._a(alp * 0.7), 1.5)
			s.draw_circle(Vector2(0, -22), 6.0, s._a(0.0 + alp * 0.2))
			var sx := -22.0 + 44.0 * fposmod(t * 2.0, 1.0)
			s.draw_line(Vector2(sx, -34), Vector2(sx, 18), s._k(0.7), 2.0)
			for k in range(8):
				var q := fposmod(t * 1.2 + _rn(k, 3), 1.0)
				s.draw_circle(Vector2((_rn(k, 4) - 0.5) * 40.0, 12.0 - 46.0 * q), 1.8, s._k(0.9 * (1.0 - q)))
		"sx_killaura":
			# lửa sát khí đỏ bốc từ chân lên + đôi mắt đỏ rực
			var n := 9 if lowq else 15
			for k in range(n):
				var x := -30.0 + 60.0 * float(k) / float(n - 1)
				var h := 30.0 + 40.0 * _rn(k, 2) + 8.0 * sin(t * 20.0 + float(k))
				_flame(s, Vector2(x, 14), h * minf(1.0, t * 3.0), 6.0, 0.7 * _fade(t, 0.7))
			_ell(s, Vector2(0, 14), 24.0 + 12.0 * sin(t * 12.0), 0.3, 0.9, 3.0)
			var e := minf(1.0, t * 4.0) * _fade(t, 0.8)
			for sgn: float in [-1.0, 1.0]:
				s.draw_colored_polygon(PackedVector2Array([Vector2(sgn * 3.0, -26), Vector2(sgn * 12.0, -30), Vector2(sgn * 10.0, -24)]), s._k(e))
				_glow(s, Vector2(sgn * 8.0, -27), 9.0, 0.7 * e)
		"sx_frenzy":
			# vuốt cào ba vệt + tia răng cưa rung loạn quanh người
			for i in range(3):
				var q := clampf(t * 3.0 - float(i) * 0.15, 0.0, 1.0)
				var o := Vector2(-16.0 + 16.0 * float(i), 0.0)
				s.draw_line(o + Vector2(-8, -34), o + Vector2(14.0 * q - 8.0, -34.0 + 68.0 * q), s._a(0.6 * _fade(t, 0.55)), 7.0)
				s.draw_line(o + Vector2(-8, -34), o + Vector2(14.0 * q - 8.0, -34.0 + 68.0 * q), s._k(_fade(t, 0.55)), 2.5)
			for k in range(10 if not lowq else 5):
				var a := TAU * float(k) / 10.0 + t * 2.0
				var pts := PackedVector2Array([Vector2(cos(a), sin(a)) * 22.0])
				for j in range(1, 4):
					pts.append(Vector2(cos(a), sin(a)) * (22.0 + 12.0 * float(j)) + Vector2(sin(t * 40.0 + float(k + j)) * 5.0, cos(t * 37.0 + float(k * j)) * 5.0))
				s.draw_polyline(pts, s._a(0.8 * _fade(t, 0.5)), 2.5)
			_glow(s, Vector2(0, -6), 30.0 + 6.0 * sin(t * 30.0), 0.5 * _fade(t, 0.5))
		"sx_multistab":
			# nhiều mũi đâm từ mọi hướng dồn vào một điểm
			var P := Vector2(56, -6)
			var n := 8 if lowq else 14
			for k in range(n):
				var a := -1.2 + 2.4 * _rn(k, 1) + (PI if k % 3 == 0 else 0.0) * 0.0
				var v := Vector2.from_angle(a + PI)
				var d := _rn(k, 2) * 0.5
				var q := clampf((t - d) / 0.2, 0.0, 1.0)
				if q <= 0.0: continue
				var from := P + v * -60.0
				var tip := from.lerp(P, q)
				var al := 1.0 - clampf((t - d - 0.2) * 3.0, 0.0, 1.0)
				s.draw_line(from.lerp(P, q * 0.4), tip, s._a(0.6 * al), 4.0)
				s.draw_line(from.lerp(P, q * 0.4), tip, s._k(al), 1.5)
				_dagger(s, tip, (P - from).angle(), 7.0, al)
			_star4(s, P, 14.0 * sin(clampf(t * 1.4, 0.0, 1.0) * PI), t * 3.0, 0.9)
		"sx_deathpoint":
			# ngắm điểm tử huyệt: vòng ngắm thu nhỏ rồi một nhát xuyên
			var P := Vector2(64, -8)
			var aim := clampf(t / 0.5, 0.0, 1.0)
			var R := lerpf(40.0, 9.0, aim)
			s.draw_arc(P, R, 0.0, TAU, 28, s._a(0.9 * _fade(t, 0.7)), 2.0)
			for i in range(4):
				var a := PI * 0.5 * float(i)
				var v := Vector2.from_angle(a)
				s.draw_line(P + v * (R + 6.0), P + v * (R - 8.0), s._k(0.95 * _fade(t, 0.7)), 2.0)
			if t > 0.5:
				var q := clampf((t - 0.5) / 0.15, 0.0, 1.0)
				var a2 := _fade(t, 0.7)
				s.draw_line(Vector2(-10, -8), Vector2(-10, -8).lerp(P + Vector2(10, 0), q), s._a(0.5 * a2), 7.0)
				s.draw_line(Vector2(-10, -8), Vector2(-10, -8).lerp(P + Vector2(10, 0), q), s._k(a2), 2.2)
				if q >= 1.0:
					var c := (t - 0.65) / 0.35
					s.draw_circle(P, 5.0 + 6.0 * c, Color(0.85, 0.05, 0.1, 0.9 * (1.0 - c)))
					s.draw_arc(P, 12.0 + 22.0 * c, 0.0, TAU, 24, s._k(0.9 * (1.0 - c)), 2.0)
		"sx_crossslash":
			# hai nhát chéo thành chữ X
			for i in range(2):
				var q := clampf((t - 0.22 * float(i)) * 3.4, 0.0, 1.0)
				if q <= 0.0: continue
				var sgn := 1.0 - 2.0 * float(i)
				var al := _fade(t, 0.35 + 0.2 * float(i))
				var o := Vector2(50, -6)
				var a := Vector2(-34, -34 * sgn)
				var b := Vector2(34, 34 * sgn)
				var e := o + a.lerp(b, q)
				s.draw_line(o + a, e, s._a(0.45 * al), 10.0)
				s.draw_line(o + a, e, s._k(al), 3.0)
			if t > 0.3:
				_star4(s, Vector2(50, -6), 18.0 * sin(clampf((t - 0.3) * 3.0, 0.0, 1.0) * PI), 0.6, 0.9)
		"sx_shadowstorm":
			# các bóng xoay quanh vòng đất, chém vào trong, rồi bùng nổ
			_disc(s, Vector2(0, 14), 90.0 * minf(1.0, t * 2.0), 0.3, 0.16)
			_ell(s, Vector2(0, 14), 90.0 * minf(1.0, t * 2.0), 0.3, 0.7, 2.5)
			var n := 6 if lowq else 9
			for k in range(n):
				var a := TAU * float(k) / float(n) + t * 5.0
				var R := lerpf(80.0, 14.0, clampf((t - 0.3) / 0.5, 0.0, 1.0))
				var p := Vector2(cos(a) * R, 14.0 + sin(a) * R * 0.3)
				_fig(s, p, 0.55 * _fade(t, 0.8), 0.75)
				s.draw_line(p + Vector2(0, -12), p + Vector2(-cos(a), -sin(a) * 0.3) * 22.0 + Vector2(0, -12), s._k(0.7 * _fade(t, 0.8)), 2.0)
			if t > 0.7:
				var c := (t - 0.7) / 0.3
				for k in range(10):
					var a := TAU * float(k) / 10.0
					s.draw_line(Vector2(0, 0) + Vector2.from_angle(a) * 8.0 * Vector2(1, 0.6), Vector2.from_angle(a) * (20.0 + 70.0 * c) * Vector2(1, 0.6), s._k(1.0 - c), 3.0)
		"sx_darkveil":
			# tấm màn đêm: vòm tối, trăng lưỡi liềm, màn rủ xuống, sao lấp lánh
			var g := minf(1.0, t * 2.0)
			for i in range(5):
				var u := float(i) / 4.0
				s.draw_circle(Vector2(0, 0), 100.0 * g * (1.0 - u * 0.6), s._mix(u * 0.5, 0.09 + 0.05 * u))
			s.draw_arc(Vector2(0, 0), 100.0 * g, 0.0, TAU, 48, s._a(0.7), 2.5)
			var n := 10 if lowq else 18
			for k in range(n):
				var x := -90.0 + 180.0 * float(k) / float(n - 1)
				var h := clampf(t * 2.0 - _rn(k, 1) * 0.4, 0.0, 1.0) * (50.0 + 40.0 * _rn(k, 2))
				var top := -sqrt(maxf(0.0, 100.0 * 100.0 - x * x)) * 0.9
				s.draw_line(Vector2(x, top), Vector2(x, top + h), s._a(0.45 * _fade(t, 0.7)), 3.0)
			_cres(s, Vector2(0, -78), 16.0 * g, -2.4, 2.4, 9.0 * g, 0.95 * _fade(t, 0.85))
			for k in range(6):
				var p := Vector2((_rn(k, 5) - 0.5) * 140.0, -20.0 - 60.0 * _rn(k, 6))
				var tw := 0.5 + 0.5 * sin(t * 16.0 + float(k) * 2.0)
				s.draw_line(p + Vector2(-3, 0), p + Vector2(3, 0), s._k(tw), 1.5)
				s.draw_line(p + Vector2(0, -3), p + Vector2(0, 3), s._k(tw), 1.5)

		# ======================= CUNG THỦ =======================
		"ax_piercearrow":
			# mũi tên nhanh xuyên qua ba vòng xung kích
			var hx := -30.0 + 170.0 * minf(1.0, t * 1.5)
			for i in range(3):
				var x := 20.0 + 38.0 * float(i)
				if hx > x:
					var r := minf(1.0, (hx - x) / 60.0)
					s.draw_arc(Vector2(x, -4), 6.0 + 22.0 * r, -1.2, 1.2, 12, s._a(0.9 * (1.0 - r)), 3.0)
					s.draw_arc(Vector2(x, -4), 6.0 + 22.0 * r, PI - 1.2, PI + 1.2, 12, s._a(0.9 * (1.0 - r)), 3.0)
			_trail(s, Vector2(hx, -4), 0.0, 90.0, 6.0, _fade(t, 0.6))
			_arrow(s, Vector2(hx, -4), 0.0, 30.0, _fade(t, 0.65))
		"ax_heartarrow":
			# tên vàng đâm xuyên bia tâm đồng tâm, toả tia sáng
			var P := Vector2(78, -6)
			for i in range(3):
				s.draw_arc(P, 10.0 + 9.0 * float(i), 0.0, TAU, 20, s._a(0.8 * minf(1.0, t * 3.0) * _fade(t, 0.8)), 2.0)
			var hx := -30.0 + 130.0 * minf(1.0, t * 1.7)
			_trail(s, Vector2(hx, -6), 0.0, 70.0, 5.0, _fade(t, 0.7))
			_arrow(s, Vector2(hx, -6), 0.0, 30.0, _fade(t, 0.75))
			if hx >= P.x:
				var c := minf(1.0, (t - 0.55) * 3.0)
				for k in range(12):
					var a := TAU * float(k) / 12.0
					s.draw_line(P + Vector2.from_angle(a) * 8.0, P + Vector2.from_angle(a) * (14.0 + 30.0 * c), s._k(0.9 * (1.0 - c)), 2.0)
				_glow(s, P, 24.0, 0.8 * (1.0 - c))
		"ax_sealarrow":
			# tên bay tới rồi in ấn pháp trận hình sao sáu cánh
			var hx := -30.0 + 120.0 * minf(1.0, t * 2.0)
			if t < 0.5:
				_trail(s, Vector2(hx, -6), 0.0, 60.0, 4.0, 1.0)
				_arrow(s, Vector2(hx, -6), 0.0, 28.0, 1.0)
			else:
				var c := minf(1.0, (t - 0.5) * 3.0)
				var P := Vector2(90, -6)
				var al := _fade(t, 0.75)
				s.draw_arc(P, 28.0 * c, 0.0, TAU, 32, s._a(0.95 * al), 3.0)
				s.draw_arc(P, 20.0 * c, 0.0, TAU, 28, s._k(0.8 * al), 1.5)
				for j in range(2):
					var pts := PackedVector2Array()
					for i in range(3):
						pts.append(P + Vector2.from_angle(float(j) * PI / 3.0 + TAU * float(i) / 3.0 - PI * 0.5 + t * 2.0) * 26.0 * c)
					pts.append(pts[0])
					s.draw_polyline(pts, s._k(al), 2.0)
				s.draw_circle(P, 4.0 * c, s._k(al))
		"ax_firevolley":
			_volley(s, t, 7, 0.14, 150.0, 0.03, true, 50.0)
		"ax_triplearrow":
			_volley(s, t, 3, 0.1, 140.0, 0.06, false, 60.0)
		"ax_rapidshot":
			# tên bắn liên tiếp thành hàng, chớp lửa đầu nòng
			var n := 6 if lowq else 9
			for i in range(n):
				var q := clampf(t * 1.9 - float(i) * 0.1, 0.0, 1.0)
				if q <= 0.0: continue
				var y := -6.0 + (float(i % 3) - 1.0) * 5.0
				var x := -24.0 + 150.0 * q
				var al := 1.0 if q < 1.0 else maxf(0.0, 1.0 - (t * 1.9 - float(i) * 0.1 - 1.0) * 5.0)
				_trail(s, Vector2(x, y), 0.0, 40.0, 3.0, 0.7 * al)
				_arrow(s, Vector2(x, y), 0.0, 22.0, al)
				if q < 0.2:
					_star4(s, Vector2(-24.0, y), 10.0 * (1.0 - q * 5.0), 0.0, 0.9)
		"ax_fivearrows":
			# năm mũi tên quạt rộng, dây nối đuôi như chuỗi châu
			var n := 5
			var tails := PackedVector2Array()
			for i in range(n):
				var ang := (float(i) - 2.0) * 0.2
				var q := clampf(t * 1.5 - float(i) * 0.02, 0.0, 1.0)
				var p := Vector2.from_angle(ang) * (-20.0 + 140.0 * q)
				var al := _fade(t, 0.7)
				_arrow(s, p, ang, 24.0, al)
				tails.append(p - Vector2.from_angle(ang) * 24.0)
				s.draw_circle(p - Vector2.from_angle(ang) * 30.0, 3.0, s._k(0.8 * al))
			s.draw_polyline(tails, s._a(0.6 * _fade(t, 0.6)), 2.0)
		"ax_eagleeye":
			# mắt ưng: hình mắt, đồng tử, tâm ngắm và lông vũ
			var o := Vector2(0, -44)
			var g := minf(1.0, t * 3.0)
			var al := _fade(t, 0.75)
			var w := 24.0 * g
			var h := 11.0 * g * (1.0 - 0.8 * maxf(0.0, sin(t * 14.0)) * 0.3)
			s.draw_colored_polygon(PackedVector2Array([o + Vector2(-w, 0), o + Vector2(0, -h), o + Vector2(w, 0), o + Vector2(0, h)]), s._a(0.4 * al))
			s.draw_polyline(PackedVector2Array([o + Vector2(-w, 0), o + Vector2(0, -h), o + Vector2(w, 0), o + Vector2(0, h), o + Vector2(-w, 0)]), s._k(al), 2.0)
			s.draw_circle(o, 7.0 * g, s._k(al))
			s.draw_circle(o, 3.0 * g, Color(0.05, 0.05, 0.05, al))
			var sw := clampf((t - 0.3) * 2.0, 0.0, 1.0)
			for i in range(4):
				var a := PI * 0.5 * float(i)
				s.draw_line(o + Vector2.from_angle(a) * (14.0 + 10.0 * (1.0 - sw)), o + Vector2.from_angle(a) * 26.0, s._a(0.9 * al), 2.0)
			for i in range(5):
				var fx := -24.0 + 12.0 * float(i)
				var q := fposmod(t * 1.1 + float(i) * 0.2, 1.0)
				s.draw_line(Vector2(fx, -10.0 + 60.0 * q * 0.0 + 30.0 * q), Vector2(fx + 4.0, -2.0 + 30.0 * q), s._k(0.5 * (1.0 - q)), 1.5)
		"ax_divineeye":
			# thần nhãn: mắt lớn, các tia thần quang quay, cột sáng thẳng đứng
			var o := Vector2(0, -50)
			var g := minf(1.0, t * 2.5)
			var al := _fade(t, 0.8)
			s.draw_line(Vector2(0, -150), Vector2(0, 20), s._a(0.25 * g * al), 14.0)
			s.draw_line(Vector2(0, -150), Vector2(0, 20), s._k(0.6 * g * al), 3.0)
			for k in range(12 if not lowq else 8):
				var a := t * 1.5 + TAU * float(k) / 12.0
				s.draw_line(o + Vector2.from_angle(a) * 22.0, o + Vector2.from_angle(a) * (36.0 + 22.0 * (k % 2)) * g, s._a(0.75 * al), 3.0)
			var w := 26.0 * g
			var h := 12.0 * g
			s.draw_colored_polygon(PackedVector2Array([o + Vector2(-w, 0), o + Vector2(0, -h), o + Vector2(w, 0), o + Vector2(0, h)]), s._a(0.55 * al))
			s.draw_arc(o, 8.0 * g, 0.0, TAU, 16, s._k(al), 3.0)
			s.draw_circle(o, 4.0 * g, s._k(al))
			s.draw_arc(o, 34.0 + 18.0 * t, 0.0, TAU, 32, s._k(0.7 * (1.0 - t)), 2.0)
			_glow(s, o, 30.0 * g, 0.6 * al)
		"ax_hopback":
			# nhảy lùi theo vòng cung, vệt gió cuộn và lông vũ
			var q := minf(1.0, t * 1.6)
			var p := Vector2(-70.0 * q, -sin(q * PI) * 36.0 + 4.0)
			for i in range(10):
				var u := float(i) / 10.0
				if u > q: break
				s.draw_circle(Vector2(-70.0 * u, -sin(u * PI) * 36.0 + 4.0), 2.5, s._k(0.6 * (1.0 - (q - u) * 1.5)))
			for k in range(4):
				var w := fposmod(t * 1.5 + float(k) * 0.25, 1.0)
				s.draw_arc(p + Vector2(18.0 + 14.0 * w, -10.0 + 8.0 * float(k)), 9.0, -1.0, 1.4, 8, s._a(0.7 * (1.0 - w)), 2.0)
			_fig(s, p, 0.35 * _fade(t, 0.5), 1.0)
			_ell(s, Vector2(0, 14), 14.0 + 20.0 * t, 0.3, 0.7 * (1.0 - t), 2.5)
		"ax_hopshoot":
			# lùi bước và bắn ba mũi tên về phía trước
			var q := minf(1.0, t * 1.5)
			var p := Vector2(-50.0 * q, -sin(q * PI) * 24.0 + 4.0)
			_fig(s, p, 0.3 * _fade(t, 0.5), 1.0)
			s.draw_line(Vector2.ZERO, p, s._a(0.35 * _fade(t, 0.4)), 4.0)
			for i in range(3):
				var d := 0.12 * float(i)
				var k := clampf((t - d) * 1.8, 0.0, 1.0)
				if k <= 0.0: continue
				var y := -8.0 + 9.0 * float(i - 1)
				var x := 10.0 + 140.0 * k
				var al := 1.0 if k < 1.0 else maxf(0.0, 1.0 - (t - d - 0.55) * 5.0)
				_trail(s, Vector2(x, y), 0.0, 44.0, 3.0, 0.7 * al)
				_arrow(s, Vector2(x, y), 0.0, 22.0, al)
		"ax_arrowrain":
			_rain(s, t, 9 if lowq else 18, 90.0, 0, false, 230.0)
		"ax_arrowstorm":
			# lốc xoáy tên xoay quanh một điểm, thu hẹp dần
			var c := Vector2(0, -40)
			var n := 10 if lowq else 18
			for k in range(n):
				var u := float(k) / float(n)
				var a := t * 6.0 + TAU * u * 2.0
				var R := (30.0 + 60.0 * u) * (0.6 + 0.4 * sin(t * PI))
				var p := c + Vector2(cos(a) * R, sin(a) * R * 0.35 - 70.0 * (u - 0.5))
				var tang := a + PI * 0.5
				var v := Vector2(-sin(a) * R, cos(a) * R * 0.35)
				_arrow(s, p, v.angle(), 18.0, 0.85 * _fade(t, 0.75))
			_ell(s, Vector2(0, 14), 74.0, 0.3, 0.5, 2.0)
			_glow(s, c, 26.0, 0.5 * sin(t * PI))
		"ax_skynet":
			# lưới thiên la phủ xuống, nút sáng, vài mũi tên ghim lưới
			var drop := clampf(t * 1.8, 0.0, 1.0)
			var yy := lerpf(-170.0, 4.0, drop * drop)
			var al := _fade(t, 0.65)
			var R := 84.0
			for i in range(-4, 5):
				var x := float(i) * R / 4.0
				s.draw_line(Vector2(x, yy - 24.0), Vector2(x, yy + 24.0), s._a(0.65 * al), 2.0)
			for j in range(-1, 2):
				var y := yy + float(j) * 12.0
				s.draw_line(Vector2(-R, y), Vector2(R, y), s._a(0.65 * al), 2.0)
			for i in range(-4, 5):
				for j in range(-1, 2):
					s.draw_circle(Vector2(float(i) * R / 4.0, yy + float(j) * 12.0), 2.6, s._k(al))
			s.draw_line(Vector2(-R, yy - 12.0), Vector2(R, yy + 12.0), s._k(0.5 * al), 1.5)
			_ell(s, Vector2(0, 8), R, 0.3, 0.5 * drop * al, 2.0)
			for k in range(5):
				var q := clampf(t * 2.0 - 0.2 - float(k) * 0.08, 0.0, 1.0)
				if q > 0.0:
					_arrow(s, Vector2(-60.0 + 30.0 * float(k), lerpf(-120.0, 4.0, q)), PI * 0.5, 22.0, al)
		"ax_firerain":
			_rain(s, t, 10 if lowq else 20, 100.0, 0, true, 250.0)
		"ax_fireshaft":
			# một mũi tên lửa thần khổng lồ giáng từ trời, nổ bùng
			var q := clampf(t * 2.2, 0.0, 1.0)
			var y := lerpf(-230.0, 0.0, q * q)
			if q < 1.0:
				s.draw_line(Vector2(0, y - 100.0), Vector2(0, y), s._a(0.35), 22.0)
				s.draw_line(Vector2(0, y - 100.0), Vector2(0, y), s._k(0.8), 6.0)
				for j in range(5):
					_flame(s, Vector2((float(j) - 2.0) * 5.0, y - 20.0 - 14.0 * float(j)), 26.0, 6.0, 0.7)
				s.draw_colored_polygon(PackedVector2Array([Vector2(0, y + 22.0), Vector2(-10, y), Vector2(10, y)]), s._k(1.0))
			else:
				var c := (t - 0.45) / 0.55
				_ell(s, Vector2.ZERO, 20.0 + 110.0 * c, 0.3, 0.95 * (1.0 - c), 4.0)
				_ell(s, Vector2.ZERO, 12.0 + 70.0 * c, 0.3, 0.9 * (1.0 - c), 3.0)
				s.draw_line(Vector2(0, 0), Vector2(0, -150.0 * (1.0 - c * 0.5)), s._a(0.5 * (1.0 - c)), 30.0 * (1.0 - c))
				s.draw_line(Vector2(0, 0), Vector2(0, -150.0 * (1.0 - c * 0.5)), s._k(0.9 * (1.0 - c)), 8.0 * (1.0 - c))
				for k in range(9):
					var x := -50.0 + 12.5 * float(k)
					_flame(s, Vector2(x, 4), (30.0 + 40.0 * _rn(k, 2)) * (1.0 - c), 7.0, 0.85 * (1.0 - c))
		"ax_homing":
			# ba mũi tên bay đường cong, uốn về mục tiêu
			for i in range(3):
				var sgn := float(i - 1)
				var q := clampf(t * 1.5 - float(i) * 0.05, 0.0, 1.0)
				var p0 := Vector2(-20, -6)
				var p1 := Vector2(50, -6 + sgn * 70.0)
				var p2 := Vector2(120, -6)
				var al := _fade(t, 0.7)
				var prev := p0
				for j in range(1, 9):
					var u := q * float(j) / 8.0
					var pt := p0.lerp(p1, u).lerp(p1.lerp(p2, u), u)
					s.draw_line(prev, pt, s._a(0.55 * al * float(j) / 8.0), 3.0)
					prev = pt
				var u2 := q
				var pa := p0.lerp(p1, u2).lerp(p1.lerp(p2, u2), u2)
				var u3 := minf(1.0, q + 0.02)
				var pb := p0.lerp(p1, u3).lerp(p1.lerp(p2, u3), u3)
				_arrow(s, pa, (pb - pa).angle(), 22.0, al)
		"ax_icearrow":
			# tên băng pha lê, vệt giá lạnh, vỡ thành mảnh băng
			var hx := -30.0 + 130.0 * minf(1.0, t * 1.5)
			var al := _fade(t, 0.65)
			s.draw_colored_polygon(PackedVector2Array([Vector2(hx + 14.0, -4), Vector2(hx, -9), Vector2(hx - 34.0, -4), Vector2(hx, 1)]), s._k(al))
			s.draw_polyline(PackedVector2Array([Vector2(hx + 14.0, -4), Vector2(hx, -9), Vector2(hx - 34.0, -4), Vector2(hx, 1), Vector2(hx + 14.0, -4)]), s._a(al), 1.5)
			_trail(s, Vector2(hx - 30.0, -4), 0.0, 60.0, 6.0, 0.8 * al)
			for k in range(8 if not lowq else 4):
				var q := fposmod(t * 1.5 + _rn(k, 1), 1.0)
				var p := Vector2(hx - 20.0 - 50.0 * q, -4.0 + (_rn(k, 2) - 0.5) * 30.0)
				_star4(s, p, 4.5 * (1.0 - q), q * 3.0, 0.9 * (1.0 - q))
			if t > 0.65:
				var c := (t - 0.65) / 0.35
				for k in range(7):
					var a := TAU * float(k) / 7.0
					var p := Vector2(110.0, -4) + Vector2.from_angle(a) * 36.0 * c
					s.draw_colored_polygon(PackedVector2Array([p + Vector2.from_angle(a) * 9.0, p + Vector2.from_angle(a + 2.0) * 4.0, p + Vector2.from_angle(a - 2.0) * 4.0]), s._k(1.0 - c))
		"ax_nebula":
			# tinh vân: xoáy thiên hà ở đích, mũi tên sao vệt ánh sáng
			var P := Vector2(88, -6)
			var g := minf(1.0, t * 2.0)
			var al := _fade(t, 0.75)
			for arm in range(3):
				var pts := PackedVector2Array()
				for j in range(14):
					var u := float(j) / 13.0
					var a := t * 4.0 + arm * TAU / 3.0 + u * 3.5
					pts.append(P + Vector2.from_angle(a) * (6.0 + 46.0 * u) * g)
				s.draw_polyline(pts, s._a(0.65 * al), 3.0)
				s.draw_polyline(pts, s._k(0.5 * al), 1.2)
			_glow(s, P, 20.0 * g, 0.8 * al)
			var hx := -30.0 + 110.0 * minf(1.0, t * 2.0)
			if t < 0.6:
				_trail(s, Vector2(hx, -6), 0.0, 100.0, 7.0, 0.9)
				_arrow(s, Vector2(hx, -6), 0.0, 30.0, 1.0)
				for k in range(6):
					_star4(s, Vector2(hx - 14.0 - 16.0 * float(k), -6.0 + sin(float(k) * 2.0 + t * 12.0) * 10.0), 5.0, 0.0, 0.8)
			for k in range(10 if not lowq else 5):
				var a := _rn(k, 3) * TAU
				var R := 30.0 + 50.0 * _rn(k, 4)
				var tw := 0.5 + 0.5 * sin(t * 14.0 + float(k))
				_star4(s, P + Vector2.from_angle(a) * R, 4.0, 0.0, tw * al)
		"ax_swiftarrow":
			# tên mảnh cực nhanh, vạch tốc độ và tia điện nhỏ
			var hx := -40.0 + 190.0 * minf(1.0, t * 1.9)
			for i in range(9):
				var y := -26.0 + 6.5 * float(i)
				var L := 30.0 + 70.0 * _rn(i, 3)
				s.draw_line(Vector2(hx - 10.0 - L, y), Vector2(hx - 10.0, y), s._a(0.4 * _fade(t, 0.5)), 1.5)
			var pts := PackedVector2Array()
			for j in range(7):
				pts.append(Vector2(hx - 70.0 + 12.0 * float(j), -5.0 + (_rn(j, int(t * 20.0)) - 0.5) * 8.0))
			s.draw_polyline(pts, s._k(0.8 * _fade(t, 0.6)), 1.5)
			_arrow(s, Vector2(hx, -5), 0.0, 40.0, _fade(t, 0.7))
		"ax_armorbreak":
			# tên đâm vỡ khiên lục giác, mảnh giáp văng ra
			var P := Vector2(86, -8)
			var hit := clampf((t - 0.4) / 0.6, 0.0, 1.0)
			var hx := -30.0 + 118.0 * minf(1.0, t * 2.4)
			if hit <= 0.0:
				var pts := PackedVector2Array()
				for i in range(6):
					pts.append(P + Vector2.from_angle(TAU * float(i) / 6.0) * 26.0)
				s.draw_colored_polygon(pts, s._a(0.3))
				pts.append(pts[0])
				s.draw_polyline(pts, s._k(0.95), 3.0)
			else:
				for i in range(6):
					var a := TAU * (float(i) + 0.5) / 6.0
					var v := Vector2.from_angle(a)
					var c := P + v * (10.0 + 50.0 * hit)
					var a1 := a - 0.5
					var a2 := a + 0.5
					s.draw_colored_polygon(PackedVector2Array([c, c + Vector2.from_angle(a1) * 14.0, c + Vector2.from_angle(a2) * 14.0]), s._a(0.9 * (1.0 - hit)))
					s.draw_line(P, P + v * 30.0 * hit, s._k(0.9 * (1.0 - hit)), 2.0)
			if t < 0.75:
				_trail(s, Vector2(hx, -8), 0.0, 60.0, 4.0, 0.9)
				_arrow(s, Vector2(hx, -8), 0.0, 30.0, 1.0)
			if hit > 0.0: _star4(s, P, 20.0 * (1.0 - hit), 0.4, 0.95)
		"ax_spirittrap":
			# bẫy linh quang: vòng đất, hai hàm gai khép lại, cột sáng
			var g := minf(1.0, t * 3.0)
			var close := clampf((t - 0.35) / 0.3, 0.0, 1.0)
			var al := _fade(t, 0.8)
			_disc(s, Vector2.ZERO, 54.0 * g, 0.3, 0.18 * al)
			_ell(s, Vector2.ZERO, 54.0 * g, 0.3, 0.9 * al, 3.0)
			_ell(s, Vector2.ZERO, 38.0 * g, 0.3, 0.6 * al, 2.0)
			for side: float in [-1.0, 1.0]:
				var n := 7
				for i in range(n):
					var u := float(i) / float(n - 1)
					var x := lerpf(-44.0, 44.0, u)
					var h := (22.0 + 6.0 * sin(u * PI)) * (0.2 + 0.8 * close)
					var yb := side * 8.0 * (1.0 - close * 0.6)
					s.draw_colored_polygon(PackedVector2Array([Vector2(x - 4.0, yb), Vector2(x + 4.0, yb), Vector2(x, yb - h * 0.8)]), s._k(0.85 * al * g))
			if close > 0.0:
				s.draw_line(Vector2(0, 0), Vector2(0, -90.0 * close), s._a(0.3 * al), 24.0 * (1.0 - close * 0.4))
				s.draw_line(Vector2(0, 0), Vector2(0, -90.0 * close), s._k(0.8 * al), 4.0)
				_glow(s, Vector2(0, -6), 26.0 * close, 0.6 * al)
		"ax_starhoming":
			# bốn ngôi sao bay xoáy rồi lao về mục tiêu, vệt sao
			var n := 4
			for i in range(n):
				var ph := TAU * float(i) / float(n)
				var q := clampf(t * 1.4, 0.0, 1.0)
				var R := (34.0 * (1.0 - q)) + 6.0
				var cx := -10.0 + 110.0 * q * q
				var p := Vector2(cx, -6.0) + Vector2(cos(ph + t * 9.0), sin(ph + t * 9.0) * 0.8) * R
				var al := _fade(t, 0.75)
				for j in range(1, 5):
					var tq := maxf(0.0, t - 0.025 * float(j))
					var qq := clampf(tq * 1.4, 0.0, 1.0)
					var RR := (34.0 * (1.0 - qq)) + 6.0
					var cc := -10.0 + 110.0 * qq * qq
					var pp := Vector2(cc, -6.0) + Vector2(cos(ph + tq * 9.0), sin(ph + tq * 9.0) * 0.8) * RR
					s.draw_circle(pp, 3.5 - 0.6 * float(j), s._a(0.5 * al * (1.0 - float(j) * 0.2)))
				_star4(s, p, 9.0, t * 6.0, al)
			if t > 0.7:
				var c := (t - 0.7) / 0.3
				_star4(s, Vector2(100, -6), 26.0 * (1.0 - c), 0.0, 0.9 * (1.0 - c))
		_: pass
