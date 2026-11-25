extends RefCounted
## Họa tiết icon kỹ năng VẼ BẰNG CODE (không emoji / font hệ thống - xem GlyphArt.gd).
## MAP: id kỹ năng -> "họ" hoặc "họ:màuhex". Họ không có trong COLORS (bolt, paw...) do GlyphArt vẽ.
## Tọa độ đơn vị [-1,1], y hướng xuống; c = tâm, s = bán kính điểm ảnh.

const GOLD := Color("e0b34a")
const STEEL := Color("e8edf5")
const FLAME_PTS := [Vector2(0.05, -0.92), Vector2(0.5, -0.25), Vector2(0.58, 0.3), Vector2(0.3, 0.78), Vector2(-0.3, 0.78), Vector2(-0.58, 0.3), Vector2(-0.42, -0.12), Vector2(-0.12, -0.3)]

const COLORS := {
	"sword_rain": Color("e8edf5"), "sword_fall": Color("ffe9a0"), "sword_slash": Color("e8edf5"), "sword_thrust": Color("e8edf5"),
	"sword_triple": Color("e8edf5"), "sword_cross": Color("e8edf5"), "sword_wave": Color("bfe3ff"), "whirl": Color("cfe0f5"),
	"fist": Color("ff9a4d"), "aegis": Color("6fb4ff"), "shield_bash": Color("8fc4ff"), "thorns": Color("c8d0dc"),
	"fortress": Color("b8c4d6"), "armor": Color("c8d0dc"), "hammer": Color("c8d0dc"), "quake": Color("d9a066"),
	"roar": Color("ffb36b"), "charge": Color("8fc4ff"), "banner": Color("ff7a5a"), "aura": Color("ffe08a"),
	"dagger": Color("dfe6f0"), "dagger_rain": Color("dfe6f0"), "shuriken": Color("c9d3e0"), "clones": Color("b79cff"),
	"shadow": Color("9a86d8"), "vanish": Color("b79cff"), "claw": Color("e8edf5"), "bloodslash": Color("e8384a"),
	"dash": Color("b8d8ff"), "backstep": Color("e3c07a"), "blink": Color("9fb8ff"), "crosshair": Color("ff6a5a"),
	"eye": Color("ffd96b"), "eye2": Color("7fe0ff"), "arrow": Color("e3c07a"), "arrow_fast": Color("e3c07a"),
	"arrow_fan": Color("e3c07a"), "arrow_rain": Color("e3c07a"), "arrow_fire": Color("ff8a3d"), "arrow_ice": Color("8ee6ff"),
	"arrow_star": Color("ffd96b"), "arrow_pierce": Color("7fa6ff"), "trap": Color("c9a066"), "web": Color("dfe6f0"),
	"fireball": Color("ff8a3d"), "firewall": Color("ff8a3d"), "meteor": Color("ff8a3d"), "inferno": Color("ff5a2d"),
	"firestar": Color("ff9a3d"), "serpent": Color("ffe14d"), "lightorb": Color("ffe14d"), "thundercloud": Color("ffe14d"),
	"snow": Color("8ee6ff"), "shards": Color("8ee6ff"), "icecage": Color("8ee6ff"), "elements": Color("ffd96b"),
	"bubble": Color("7fc8ff"), "crystal": Color("7fa6ff"), "rune": Color("b79cff"), "heal_plus": Color("6fe39a"),
	"heart": Color("ff6a88"), "holyray": Color("ffe08a"), "holycross": Color("fff0a8"), "holydrop": Color("ffe08a"),
	"holywave": Color("ffe08a"), "wings": Color("fff0c8"), "halo": Color("ffe08a"), "sunrise": Color("ffb347"),
	"phoenix": Color("ff9a3d"), "dome": Color("9fe8d0"), "dove": Color("f4f4ff"), "ghost": Color("c9b8ff"),
	"ghosts": Color("c9b8ff"), "gate": Color("9a6cff"), "soulwisp": Color("8ee6d0"), "hex": Color("b05cff"),
	"burst": Color("b79cff"), "miasma": Color("8a6cc8"), "chains": Color("b8c0cc"), "dragon": Color("5fd6a0"),
	"bird": Color("9fe8d0"), "yinyang": Color("e8e8f5"), "waves": Color("5fb0ff"), "palm": Color("ffd0a0"),
}

const MAP := {
	# Sát thủ
	"av25": "dash:b79cff", "av27": "vanish", "av30": "dagger", "av32": "clones", "av35": "shadow", "av37": "dagger_rain",
	"av38": "fist:ff5a5a", "av40": "claw:c58bff", "av42": "bloodslash", "av45": "whirl:c58bff",
	"st1": "dash:b79cff", "st2": "claw", "st3": "fist:ff5a5a", "st4": "vanish:9a86d8", "st5": "dagger_rain:9fe8d0",
	"st6": "sword_slash:b79cff", "st7": "bloodslash:ff5a7a", "st8": "shuriken:6fe39a", "st9": "backstep:b79cff",
	"st10": "crosshair", "st11": "miasma:6a4cc8", "ulSat1": "dagger_rain:ff5a5a",
	# Cung thủ
	"hl1": "arrow", "hl2": "arrow_fan", "hl3": "eye", "hl4": "backstep", "hl5": "arrow_rain", "hl6": "arrow_fan:9fe8d0",
	"hl7": "arrow_rain:ffd96b", "hl8": "arrow_ice", "hl9": "arrow_fan:ffd96b", "hl10": "crosshair:ffd96b", "hl11": "arrow_fire",
	"xa25": "crosshair:ff3a4a", "xa27": "arrow_fast", "xa30": "backstep:e3c07a", "xa32": "arrow_pierce", "xa35": "eye2",
	"xa37": "arrow_fan:ff8a3d", "xa38": "trap", "xa40": "web", "xa42": "arrow_star", "xa45": "arrow_rain:ff6a2d",
	"ulCung1": "arrow_star:c58bff", "ulCung2": "arrow_rain:ff6a2d",
	# Tanker
	"tk1": "shield_bash:ffb03d", "tk2": "whirl:c8d0dc", "tk3": "fist", "tk4": "armor", "tk5": "sword_wave:c8d0dc", "tk6": "quake",
	"tk7": "fortress:6fb4ff", "tk8": "charge", "tk9": "roar", "tk10": "thorns", "tk11": "hammer",
	"hv25": "shield_bash", "hv27": "shield_bash:ff8a3d", "hv30": "thorns:6fb4ff", "hv32": "aura:6fb4ff", "hv35": "quake:ffb03d",
	"hv37": "whirl:6fb4ff", "hv38": "fortress", "hv40": "charge:ffb03d", "hv42": "dragon:c9a066", "hv45": "banner",
	"ulTank1": "fortress:e0b34a", "ulTank2": "quake:ff8a3d", "ulTankSuper": "aegis:ffd96b",
	# Kiếm sĩ
	"pa1": "dash:e8edf5", "pa2": "sword_cross", "pa3": "fist", "pa4": "aegis", "pa5": "sword_fall", "pa6": "sword_cross:ffd96b",
	"pa7": "sword_slash:ff8a3d", "pa8": "sword_thrust:8ee6ff", "pa9": "sword_cross:6fb4ff", "pa10": "whirl:9fe8d0",
	"pa11": "sword_wave:ffd96b",
	"ks25": "sword_slash", "ks27": "sword_thrust", "ks30": "sword_cross:b79cff", "ks32": "aegis:e8edf5", "ks35": "dragon:8ee6ff",
	"ks37": "sword_triple", "ks38": "sword_wave", "ks40": "sword_rain", "ks42": "whirl", "ks45": "aura",
	"ulKiem1": "sword_rain:ffd96b", "ulKiem2": "whirl:ffd96b", "ulChung3": "sword_slash:b79cff",
	# Pháp sư
	"ps25": "serpent", "ps27": "fireball:ff5a2d", "ps30": "firewall", "ps32": "snow", "ps35": "crystal", "ps37": "lightorb",
	"ps38": "heal_plus:6fb4ff", "ps40": "elements", "ps42": "blink", "ps45": "rune:ffd96b",
	"tn1": "shards", "tn2": "heal_plus", "tn3": "icecage", "tn4": "bubble", "tn5": "meteor", "tn6": "snow:5fb0ff",
	"tn7": "firestar", "tn8": "fireball", "tn9": "bolt", "tn10": "blink:8ee6ff", "tn11": "inferno",
	"ulPhap1": "thundercloud", "ulPhap2": "shards:5fb0ff", "ulPhapSuper": "rune:ff5a5a",
	# Trị liệu
	"tl1": "heal_plus", "tl2": "holywave", "tl3": "dove", "tl4": "bubble:ffe08a", "tl5": "holycross:6fe39a", "tl6": "halo",
	"tl7": "dome:6fe39a", "tl8": "holydrop", "tl9": "rune:ffe08a", "tl10": "holydrop:8ee6ff", "tl11": "phoenix:ffd96b",
	"tl25": "dome", "tl30": "arrow_fast:ffe08a", "tl35": "dome:ffe08a", "tl40": "sunrise",
	"tg27": "holyray", "tg32": "holycross", "tg37": "wings", "tg38": "holycross:ffd96b", "tg42": "holyray:fff0a8",
	"tg45": "phoenix", "ulTri1": "phoenix:fff0a8",
	# Triệu hồi
	"th1": "soulwisp", "th2": "ghost:9fe8d0", "th3": "burst:9fe8d0", "th4": "banner:9fe8d0", "th5": "paw:f0b27a",
	"th6": "soulwisp:6fe39a", "th7": "bubble:9fe8d0", "th8": "bird", "th9": "paw:9fe8d0", "th10": "dragon",
	"th11": "rune:9fe8d0", "ulLinh1": "burst:6fe39a",
	# Tử linh
	"nl1": "hex", "nl2": "ghost", "nl3": "soulwisp:c58bff", "nl4": "ghosts", "nl5": "gate", "nl6": "clones:c58bff",
	"nl7": "claw:c58bff", "nl8": "chains", "nl9": "bubble:c58bff", "nl10": "burst:ff6aa0", "nl11": "miasma",
	"ulLinh2": "miasma:6a8cff", "ulTuLinhDungHop": "ghost:ff6a8a",
	# Chung / toàn năng
	"ulChung1": "quake:ffd96b", "ulChung2": "aura:ff9a6a", "ulSinhTu": "yinyang",
	"ulToanNangSuper": "elements", "vn1": "aura", "vn2": "elements", "vn3": "waves", "vn4": "yinyang",
	"vn5": "heart", "vn6": "palm", "vn7": "sword_slash:ffd96b",
}

## Token "@họ:0[:màu]" cho kỹ năng có trong bảng; "" nếu chưa ánh xạ.
static func token_of_skill(sid: String) -> String:
	if not MAP.has(sid): return ""
	var parts: PackedStringArray = str(MAP[sid]).split(":")
	var t := "@%s:0" % parts[0]
	if parts.size() > 1: t += ":" + parts[1]
	return t

# ---------- helpers ----------
static func _q(c: Vector2, s: float, x: float, y: float) -> Vector2:
	return c + Vector2(x, y) * s

static func _poly(n: Control, c: Vector2, s: float, pts: Array, col: Color) -> void:
	var out := PackedVector2Array()
	for v in pts: out.append(c + (v as Vector2) * s)
	n.draw_colored_polygon(out, col)

static func _line(n: Control, c: Vector2, s: float, a: Vector2, b: Vector2, col: Color, w: float) -> void:
	n.draw_line(c + a * s, c + b * s, col, w, true)

static func _pline(n: Control, c: Vector2, s: float, pts: Array, col: Color, w: float) -> void:
	var out := PackedVector2Array()
	for v in pts: out.append(c + (v as Vector2) * s)
	n.draw_polyline(out, col, w, true)

static func _dot(n: Control, c: Vector2, s: float, p: Vector2, r: float, col: Color) -> void:
	n.draw_circle(c + p * s, r * s, col)

static func _sword(n: Control, c: Vector2, s: float, a: Vector2, b: Vector2, col: Color, lw: float) -> void:
	var u := (b - a).normalized()
	var p := Vector2(-u.y, u.x)
	var g := a + u * 0.2
	_line(n, c, s, a, g, GOLD, lw * 0.7)
	_dot(n, c, s, a, 0.07, GOLD)
	_line(n, c, s, g - p * 0.2, g + p * 0.2, GOLD, lw * 0.7)
	_poly(n, c, s, [g + p * 0.075, b, g - p * 0.075], col)
	_line(n, c, s, g + u * 0.05, b - u * 0.08, Color(1, 1, 1, 0.6), maxf(1.0, lw * 0.2))

static func _arrow(n: Control, c: Vector2, s: float, a: Vector2, b: Vector2, shaft: Color, head: Color, lw: float) -> void:
	var u := (b - a).normalized()
	var p := Vector2(-u.y, u.x)
	_line(n, c, s, a, b - u * 0.15, shaft, lw * 0.55)
	_poly(n, c, s, [b, b - u * 0.3 + p * 0.14, b - u * 0.3 - p * 0.14], head)
	_line(n, c, s, a, a - u * 0.0 + p * 0.14 + u * 0.18, Color("f0f0f0"), lw * 0.4)
	_line(n, c, s, a, a - p * 0.14 + u * 0.18, Color("f0f0f0"), lw * 0.4)

static func _crescent(n: Control, c: Vector2, s: float, o: Vector2, r: float, a0: float, a1: float, th: float, col: Color) -> void:
	var outer: Array = []
	var inner: Array = []
	for i in range(15):
		var t := float(i) / 14.0
		var ang := a0 + (a1 - a0) * t
		var d := Vector2(cos(ang), sin(ang))
		outer.append(o + d * r)
		inner.append(o + d * r * (1.0 - th * sin(PI * t)))
	inner.reverse()
	_poly(n, c, s, outer + inner, col)

static func _flame(n: Control, c: Vector2, s: float, cx: float, cy: float, w: float, h: float, col: Color, inner: Color) -> void:
	var pts: Array = []
	for v in FLAME_PTS: pts.append(Vector2(cx + v.x * w, cy + v.y * h))
	_poly(n, c, s, pts, col)
	var p2: Array = []
	for v in FLAME_PTS: p2.append(Vector2(cx + v.x * w * 0.5, cy + 0.25 * h + v.y * h * 0.5))
	_poly(n, c, s, p2, inner)

static func _star4(n: Control, c: Vector2, s: float, p: Vector2, r: float, col: Color) -> void:
	_poly(n, c, s, [p + Vector2(0, -r), p + Vector2(r * 0.25, -r * 0.25), p + Vector2(r, 0), p + Vector2(r * 0.25, r * 0.25), p + Vector2(0, r), p + Vector2(-r * 0.25, r * 0.25), p + Vector2(-r, 0), p + Vector2(-r * 0.25, -r * 0.25)], col)

static func _person(n: Control, c: Vector2, s: float, x: float, y: float, k: float, col: Color) -> void:
	_dot(n, c, s, Vector2(x, y - 0.5 * k), 0.2 * k, col)
	_poly(n, c, s, [Vector2(x - 0.32 * k, y - 0.22 * k), Vector2(x + 0.32 * k, y - 0.22 * k), Vector2(x + 0.42 * k, y + 0.7 * k), Vector2(x - 0.42 * k, y + 0.7 * k)], col)

static func _ghost(n: Control, c: Vector2, s: float, x: float, y: float, k: float, col: Color, eye: Color) -> void:
	_dot(n, c, s, Vector2(x, y - 0.1 * k), 0.45 * k, col)
	_poly(n, c, s, [Vector2(x - 0.45 * k, y - 0.1 * k), Vector2(x + 0.45 * k, y - 0.1 * k), Vector2(x + 0.45 * k, y + 0.55 * k), Vector2(x + 0.3 * k, y + 0.4 * k), Vector2(x + 0.15 * k, y + 0.6 * k), Vector2(x, y + 0.4 * k), Vector2(x - 0.15 * k, y + 0.6 * k), Vector2(x - 0.3 * k, y + 0.4 * k), Vector2(x - 0.45 * k, y + 0.55 * k)], col)
	_dot(n, c, s, Vector2(x - 0.17 * k, y - 0.15 * k), 0.09 * k, eye)
	_dot(n, c, s, Vector2(x + 0.17 * k, y - 0.15 * k), 0.09 * k, eye)

static func _capsule(n: Control, c: Vector2, s: float, a: Vector2, b: Vector2, w: float, col: Color) -> void:
	n.draw_line(c + a * s, c + b * s, col, w, true)
	n.draw_circle(c + a * s, w * 0.5, col)
	n.draw_circle(c + b * s, w * 0.5, col)

static func _shield_pts(k: float, dx: float, dy: float) -> Array:
	var base := [Vector2(-0.62, -0.68), Vector2(0.62, -0.68), Vector2(0.62, 0.1), Vector2(0, 0.86), Vector2(-0.62, 0.1)]
	var out: Array = []
	for v in base: out.append(v * k + Vector2(dx, dy))
	return out

static func _cloud(n: Control, c: Vector2, s: float, y: float, col: Color) -> void:
	_dot(n, c, s, Vector2(-0.4, y), 0.3, col)
	_dot(n, c, s, Vector2(0.0, y - 0.2), 0.4, col)
	_dot(n, c, s, Vector2(0.42, y), 0.3, col)
	_poly(n, c, s, [Vector2(-0.4, y - 0.05), Vector2(0.42, y - 0.05), Vector2(0.42, y + 0.3), Vector2(-0.4, y + 0.3)], col)

# ---------- vẽ ----------
static func draw(n: Control, fam: String, c: Vector2, s: float, col: Color, lw: float) -> void:
	var dark := Color(col.r * 0.35, col.g * 0.35, col.b * 0.4, 0.95)
	var pale := col.lerp(Color.WHITE, 0.55)
	match fam:
		"sword_rain":
			for x in [-0.6, 0.6, 0.0]:
				var off := 0.0 if x == 0.0 else -0.2
				_sword(n, c, s, Vector2(x, -0.95 + off), Vector2(x, 0.05 + off + (0.3 if x == 0.0 else 0.0)), col, lw)
			for x2 in [-0.7, 0.0, 0.7]:
				_dot(n, c, s, Vector2(x2, 0.92), 0.07, GOLD)
		"sword_fall":
			_dot(n, c, s, Vector2(0, 0.35), 0.5, Color(col.r, col.g, col.b, 0.25))
			_sword(n, c, s, Vector2(0, -1.0), Vector2(0, 0.6), col, lw * 1.35)
			for a in [-0.9, 0.0, 0.9]:
				_line(n, c, s, Vector2(0, 0.7), Vector2(sin(a) * 0.8, 0.7 + cos(a) * 0.25), GOLD, lw * 0.5)
		"sword_slash":
			_crescent(n, c, s, Vector2(0.0, 0.15), 1.0, -2.75, 0.15, 0.42, col)
			_star4(n, c, s, Vector2(0.55, -0.6), 0.2, Color.WHITE)
		"sword_wave":
			_crescent(n, c, s, Vector2(-0.55, 0), 1.4, -0.95, 0.95, 0.4, col)
			_line(n, c, s, Vector2(-0.9, -0.28), Vector2(-0.4, -0.28), Color(col.r, col.g, col.b, 0.6), lw * 0.6)
			_line(n, c, s, Vector2(-0.95, 0.0), Vector2(-0.3, 0.0), Color(col.r, col.g, col.b, 0.8), lw * 0.6)
			_line(n, c, s, Vector2(-0.9, 0.28), Vector2(-0.4, 0.28), Color(col.r, col.g, col.b, 0.6), lw * 0.6)
		"sword_thrust":
			for x in [-0.55, 0.55]:
				_line(n, c, s, Vector2(x, 0.25), Vector2(x, 0.8), Color(col.r, col.g, col.b, 0.5), lw * 0.6)
			_sword(n, c, s, Vector2(0, 0.95), Vector2(0, -0.8), col, lw * 1.2)
			_star4(n, c, s, Vector2(0, -0.9), 0.2, Color.WHITE)
		"sword_triple":
			for a in [-0.55, 0.55, 0.0]:
				_sword(n, c, s, Vector2(0, 0.95), Vector2(sin(a) * 1.9, 0.95 - cos(a) * 1.9), col, lw)
		"sword_cross":
			_sword(n, c, s, Vector2(0.78, 0.85), Vector2(-0.78, -0.85), col, lw)
			_sword(n, c, s, Vector2(-0.78, 0.85), Vector2(0.78, -0.85), pale, lw)
		"whirl":
			for k in range(4):
				var a0 := float(k) * PI * 0.5 + 0.2
				var a1 := a0 + 1.2
				n.draw_arc(c, 0.7 * s, a0, a1, 8, col, lw * 1.1, true)
				var pe := Vector2(cos(a1), sin(a1)) * 0.7
				var t := Vector2(-sin(a1), cos(a1))
				var rad := Vector2(cos(a1), sin(a1))
				_poly(n, c, s, [pe + rad * 0.16, pe - rad * 0.16, pe + t * 0.3], col)
			_dot(n, c, s, Vector2.ZERO, 0.14, pale)
		"fist":
			_dot(n, c, s, Vector2(0, 0.05), 0.0, col)
			n.draw_rect(Rect2(_q(c, s, -0.55, -0.1), Vector2(1.1, 0.88) * s), col)
			for x in [-0.41, -0.14, 0.14, 0.41]:
				_dot(n, c, s, Vector2(x, -0.12), 0.2, col)
			for x in [-0.275, 0.0, 0.275]:
				_line(n, c, s, Vector2(x, -0.3), Vector2(x, 0.08), dark, maxf(1.0, lw * 0.3))
			_poly(n, c, s, [Vector2(-0.55, 0.15), Vector2(-0.85, 0.3), Vector2(-0.7, 0.6), Vector2(-0.55, 0.55)], col.darkened(0.15))
			for a in [-0.5, 0.0, 0.5]:
				_line(n, c, s, Vector2(sin(a) * 0.7, -0.65 - cos(a) * 0.05), Vector2(sin(a) * 1.0, -0.85), pale, lw * 0.45)
		"aegis":
			var sp := _shield_pts(1.0, 0, 0)
			_poly(n, c, s, sp, dark)
			_pline(n, c, s, sp + [sp[0]], col, lw * 0.9)
			_star4(n, c, s, Vector2(0, -0.05), 0.4, GOLD)
			_dot(n, c, s, Vector2(0, -0.05), 0.08, Color.WHITE)
		"shield_bash":
			var sb := _shield_pts(0.8, -0.28, 0.0)
			_poly(n, c, s, sb, dark)
			_pline(n, c, s, sb + [sb[0]], col, lw * 0.8)
			for a in [-0.8, -0.3, 0.2, 0.7]:
				_line(n, c, s, Vector2(0.45 + cos(a) * 0.15, sin(a) * 0.15), Vector2(0.45 + cos(a) * 0.5, sin(a) * 0.5), GOLD, lw * 0.6)
			_star4(n, c, s, Vector2(0.55, -0.1), 0.17, Color.WHITE)
		"thorns":
			for sx in [-1.0, 1.0]:
				for yy in [-0.5, -0.1]:
					_poly(n, c, s, [Vector2(sx * 0.6, yy - 0.12), Vector2(sx * 0.6, yy + 0.12), Vector2(sx * 0.95, yy)], pale)
			_poly(n, c, s, [Vector2(-0.14, 0.8), Vector2(0.14, 0.8), Vector2(0, 1.05)], pale)
			var st := _shield_pts(0.95, 0, -0.03)
			_poly(n, c, s, st, dark)
			_pline(n, c, s, st + [st[0]], col, lw * 0.8)
			_star4(n, c, s, Vector2(0, -0.1), 0.3, col)
		"fortress":
			n.draw_rect(Rect2(_q(c, s, -0.7, -0.2), Vector2(1.4, 1.05) * s), dark)
			for x in [-0.7, -0.15, 0.4]:
				n.draw_rect(Rect2(_q(c, s, x, -0.58), Vector2(0.3, 0.4) * s), col)
			n.draw_rect(Rect2(_q(c, s, -0.7, -0.22), Vector2(1.4, 0.1) * s), col)
			n.draw_rect(Rect2(_q(c, s, -0.7, -0.2), Vector2(1.4, 1.05) * s), col, false, maxf(1.0, lw * 0.5))
			_dot(n, c, s, Vector2(0, 0.35), 0.2, col)
			n.draw_rect(Rect2(_q(c, s, -0.2, 0.35), Vector2(0.4, 0.5) * s), col)
			_line(n, c, s, Vector2(-0.45, 0.1), Vector2(-0.45, 0.3), col, lw * 0.5)
			_line(n, c, s, Vector2(0.45, 0.1), Vector2(0.45, 0.3), col, lw * 0.5)
		"armor":
			_dot(n, c, s, Vector2(0, -0.1), 0.65, col)
			n.draw_rect(Rect2(_q(c, s, -0.65, -0.1), Vector2(1.3, 0.7) * s), col)
			_poly(n, c, s, [Vector2(-0.65, 0.6), Vector2(-0.35, 0.6), Vector2(-0.2, 0.9), Vector2(-0.5, 0.85)], col.darkened(0.2))
			_poly(n, c, s, [Vector2(0.65, 0.6), Vector2(0.35, 0.6), Vector2(0.2, 0.9), Vector2(0.5, 0.85)], col.darkened(0.2))
			n.draw_rect(Rect2(_q(c, s, -0.48, 0.0), Vector2(0.96, 0.16) * s), dark)
			_line(n, c, s, Vector2(0, -0.75), Vector2(0, 0.6), pale, lw * 0.35)
			_poly(n, c, s, [Vector2(-0.12, -0.78), Vector2(0.12, -0.78), Vector2(0.0, -1.0)], Color("e8384a"))
		"hammer":
			_line(n, c, s, Vector2(-0.7, 0.9), Vector2(0.3, -0.35), Color("a67c52"), lw * 1.1)
			var u := Vector2(0.62, -0.78).normalized()
			var p := Vector2(-u.y, u.x)
			var hc := Vector2(0.4, -0.45)
			_poly(n, c, s, [hc - u * 0.28 - p * 0.55, hc + u * 0.28 - p * 0.55, hc + u * 0.28 + p * 0.55, hc - u * 0.28 + p * 0.55], col)
			_line(n, c, s, hc - p * 0.45, hc + p * 0.45, Color(1, 1, 1, 0.5), maxf(1.0, lw * 0.3))
			_poly(n, c, s, [Vector2(0.75, 0.35), Vector2(0.45, 0.8), Vector2(0.62, 0.8), Vector2(0.5, 1.05), Vector2(0.95, 0.55), Vector2(0.75, 0.55)], Color("ffe14d"))
		"quake":
			for i in range(3):
				var x: float = -0.5 + 0.5 * i
				var h: float = [0.55, 0.85, 0.6][i]
				_poly(n, c, s, [Vector2(x - 0.2, 0.4), Vector2(x - 0.05, 0.4 - h), Vector2(x + 0.2, 0.4)], col)
			_pline(n, c, s, [Vector2(-0.95, 0.4), Vector2(-0.5, 0.52), Vector2(-0.15, 0.36), Vector2(0.15, 0.56), Vector2(0.5, 0.4), Vector2(0.95, 0.5)], pale, lw * 0.9)
			_pline(n, c, s, [Vector2(0.0, 0.56), Vector2(-0.1, 0.78), Vector2(0.08, 0.9)], pale, lw * 0.6)
			_dot(n, c, s, Vector2(-0.8, -0.2), 0.07, col)
			_dot(n, c, s, Vector2(0.85, -0.35), 0.06, col)
		"roar":
			_dot(n, c, s, Vector2(-0.4, 0.0), 0.5, col)
			_poly(n, c, s, [Vector2(-0.2, -0.25), Vector2(0.15, -0.05), Vector2(0.15, 0.15), Vector2(-0.2, 0.3)], dark)
			_dot(n, c, s, Vector2(-0.55, -0.2), 0.08, dark)
			for r in [0.45, 0.75, 1.05]:
				n.draw_arc(_q(c, s, 0.0, 0.0), r * s, -0.7, 0.7, 8, Color(col.r, col.g, col.b, 1.0 - r * 0.5), lw * 0.7, true)
		"charge":
			for i in range(3):
				var x2 := -0.75 + 0.5 * i
				_pline(n, c, s, [Vector2(x2, -0.55), Vector2(x2 + 0.45, 0.0), Vector2(x2, 0.55)], Color(col.r, col.g, col.b, 0.45 + 0.27 * i), lw * 1.2)
			_line(n, c, s, Vector2(-0.95, -0.25), Vector2(-0.6, -0.25), Color(col.r, col.g, col.b, 0.5), lw * 0.5)
			_line(n, c, s, Vector2(-0.95, 0.25), Vector2(-0.6, 0.25), Color(col.r, col.g, col.b, 0.5), lw * 0.5)
		"banner":
			_line(n, c, s, Vector2(-0.55, -0.95), Vector2(-0.55, 0.95), Color("d9cba8"), lw * 0.7)
			_poly(n, c, s, [Vector2(-0.55, -0.85), Vector2(0.85, -0.85), Vector2(0.5, -0.5), Vector2(0.85, -0.15), Vector2(-0.55, -0.15)], col)
			_star4(n, c, s, Vector2(0.0, -0.5), 0.2, Color.WHITE)
			_dot(n, c, s, Vector2(-0.55, -0.95), 0.07, GOLD)
		"aura":
			_dot(n, c, s, Vector2(0, 0.05), 0.85, Color(col.r, col.g, col.b, 0.2))
			for k in range(8):
				var a := float(k) * PI / 4.0
				_line(n, c, s, Vector2(cos(a), sin(a)) * 0.8, Vector2(cos(a), sin(a)) * 1.0, col, lw * 0.6)
			_person(n, c, s, 0.0, 0.05, 0.85, col)
			_dot(n, c, s, Vector2(0, -0.42), 0.08, Color.WHITE)
		"dagger":
			for o in [-0.2, 0.2]:
				_line(n, c, s, Vector2(-0.95 + o, 0.75 - o) , Vector2(-0.45 + o, 0.3 - o), Color(col.r, col.g, col.b, 0.35), lw * 0.5)
			_sword(n, c, s, Vector2(-0.45, 0.45), Vector2(0.8, -0.8), col, lw)
		"dagger_rain":
			for x in [-0.6, 0.6, 0.0]:
				var off := 0.0 if x != 0.0 else 0.15
				var a := Vector2(x - 0.25, -0.95 + off)
				_sword(n, c, s, a, a + Vector2(0.3, 0.95).normalized() * 1.0, col, lw * 0.9)
			_line(n, c, s, Vector2(-0.9, 0.9), Vector2(0.9, 0.9), Color(col.r, col.g, col.b, 0.4), lw * 0.4)
		"shuriken":
			var pts: Array = []
			for k in range(8):
				var a := float(k) * PI / 4.0 + PI / 8.0
				var r := 1.0 if k % 2 == 0 else 0.3
				pts.append(Vector2(cos(a), sin(a)) * r)
			_poly(n, c, s, pts, col)
			_dot(n, c, s, Vector2.ZERO, 0.17, dark)
		"clones":
			_person(n, c, s, -0.55, 0.1, 0.75, Color(col.r, col.g, col.b, 0.35))
			_person(n, c, s, 0.55, 0.1, 0.75, Color(col.r, col.g, col.b, 0.35))
			_person(n, c, s, 0.0, 0.1, 0.95, col)
		"shadow":
			_person(n, c, s, 0.0, 0.1, 1.0, dark)
			n.draw_arc(_q(c, s, 0.0, -0.4), 0.2 * s, 0, TAU, 14, col, lw * 0.5, true)
			_pline(n, c, s, [Vector2(-0.32, -0.12), Vector2(0.32, -0.12), Vector2(0.42, 0.8), Vector2(-0.42, 0.8), Vector2(-0.32, -0.12)], col, lw * 0.55)
			_dot(n, c, s, Vector2(-0.08, -0.42), 0.05, Color.WHITE)
			_dot(n, c, s, Vector2(0.08, -0.42), 0.05, Color.WHITE)
		"vanish":
			_dot(n, c, s, Vector2(0, -0.6), 0.22, col)
			for i in range(6):
				var y := -0.3 + 0.17 * i
				n.draw_rect(Rect2(_q(c, s, -0.32 - i * 0.02, y), Vector2(0.64 + i * 0.04, 0.13) * s), Color(col.r, col.g, col.b, 1.0 - float(i) / 6.5))
			for i2 in range(5):
				_dot(n, c, s, Vector2(-0.5 + 0.25 * i2, 0.75 + 0.1 * float(i2 % 2)), 0.05, Color(col.r, col.g, col.b, 0.5))
		"claw":
			for k in range(3):
				var x := -0.55 + 0.5 * k
				_poly(n, c, s, [Vector2(x - 0.1, -0.9), Vector2(x + 0.1, -0.9), Vector2(x + 0.45, 0.9)], col)
		"bloodslash":
			_dot(n, c, s, Vector2(0, 0.25), 0.5, col)
			_poly(n, c, s, [Vector2(0, -0.92), Vector2(0.48, 0.12), Vector2(-0.48, 0.12)], col)
			_line(n, c, s, Vector2(-0.85, 0.7), Vector2(0.85, -0.55), Color.WHITE, lw * 0.9)
			_dot(n, c, s, Vector2(0.65, 0.8), 0.07, col)
			_dot(n, c, s, Vector2(-0.7, -0.6), 0.06, col)
		"dash":
			_poly(n, c, s, [Vector2(0.95, 0.0), Vector2(0.25, -0.6), Vector2(0.25, -0.2), Vector2(-0.25, -0.2), Vector2(-0.25, 0.2), Vector2(0.25, 0.2), Vector2(0.25, 0.6)], col)
			for i in range(3):
				var y2 := -0.45 + 0.45 * i
				_line(n, c, s, Vector2(-0.95, y2), Vector2(-0.45 + 0.1 * (i % 2), y2), Color(col.r, col.g, col.b, 0.55), lw * 0.55)
		"backstep":
			var pts2: Array = []
			for i in range(11):
				var a := -0.15 - (PI - 0.4) * float(i) / 10.0
				pts2.append(Vector2(cos(a), sin(a) * 0.9 - 0.1) * 0.72)
			_pline(n, c, s, pts2, col, lw * 1.1)
			_poly(n, c, s, [Vector2(-0.72, 0.6), Vector2(-0.98, 0.05), Vector2(-0.46, 0.05)], col)
			_person(n, c, s, 0.45, 0.35, 0.4, Color(col.r, col.g, col.b, 0.5))
		"blink":
			for x in [-0.6, 0.6]:
				n.draw_arc(_q(c, s, x, 0.0), 0.34 * s, 0, TAU, 18, col, lw * 0.9, true)
				_dot(n, c, s, Vector2(x, 0.0), 0.14, Color(col.r, col.g, col.b, 0.5))
			_poly(n, c, s, [Vector2(0.15, 0.0), Vector2(-0.1, -0.2), Vector2(-0.1, 0.2)], pale)
			_star4(n, c, s, Vector2(0.0, -0.65), 0.15, Color.WHITE)
			_star4(n, c, s, Vector2(0.1, 0.7), 0.12, pale)
		"crosshair":
			n.draw_arc(c, 0.65 * s, 0, TAU, 28, col, lw * 0.8, true)
			for a in [0.0, PI * 0.5, PI, PI * 1.5]:
				_line(n, c, s, Vector2(cos(a), sin(a)) * 0.45, Vector2(cos(a), sin(a)) * 1.0, col, lw * 0.7)
			_dot(n, c, s, Vector2.ZERO, 0.14, Color.WHITE)
		"eye", "eye2":
			var top: Array = []
			var bot: Array = []
			for i in range(13):
				var t := float(i) / 12.0
				var x := -0.95 + 1.9 * t
				top.append(Vector2(x, -0.5 * sin(PI * t)))
				bot.append(Vector2(x, 0.5 * sin(PI * t)))
			bot.reverse()
			_poly(n, c, s, top + bot, dark)
			_pline(n, c, s, top, col, lw * 0.8)
			_pline(n, c, s, bot, col, lw * 0.8)
			_dot(n, c, s, Vector2.ZERO, 0.3, col)
			_dot(n, c, s, Vector2.ZERO, 0.13, Color(0.05, 0.05, 0.1))
			_dot(n, c, s, Vector2(-0.08, -0.08), 0.06, Color.WHITE)
			if fam == "eye2":
				for a in [-0.6, 0.0, 0.6]:
					_line(n, c, s, Vector2(sin(a) * 0.7, -0.62 - cos(a) * 0.05), Vector2(sin(a) * 0.95, -0.92), col, lw * 0.5)
				_star4(n, c, s, Vector2.ZERO, 0.2, Color(1, 1, 1, 0.7))
		"arrow":
			_arrow(n, c, s, Vector2(-0.8, 0.8), Vector2(0.9, -0.9), Color("d9c7a0"), Color.WHITE, lw)
		"arrow_fast":
			for y3 in [-0.3, 0.3]:
				_line(n, c, s, Vector2(-0.95, y3), Vector2(-0.4, y3), Color(col.r, col.g, col.b, 0.5), lw * 0.5)
			_arrow(n, c, s, Vector2(-0.65, 0.0), Vector2(0.95, 0.0), col, Color.WHITE, lw * 1.1)
		"arrow_fan":
			for ang in [20.0, 45.0, 70.0]:
				var ar := deg_to_rad(ang)
				_arrow(n, c, s, Vector2(-0.7, 0.7), Vector2(-0.7 + cos(ar) * 1.7, 0.7 - sin(ar) * 1.7), Color("d9c7a0"), Color.WHITE, lw * 0.9)
		"arrow_rain", "arrow_fire", "arrow_ice", "arrow_star":
			if fam == "arrow_rain":
				for i in range(4):
					var x3 := -0.7 + 0.45 * i
					var off2 := 0.0 if i % 2 == 0 else 0.25
					_arrow(n, c, s, Vector2(x3 - 0.3, -0.95 + off2), Vector2(x3 + 0.1, 0.1 + off2), Color("d9c7a0"), col if col != COLORS["arrow_rain"] else Color.WHITE, lw * 0.8)
				_line(n, c, s, Vector2(-0.9, 0.9), Vector2(0.9, 0.9), Color(col.r, col.g, col.b, 0.5), lw * 0.4)
			else:
				_arrow(n, c, s, Vector2(-0.45, 0.45), Vector2(0.9, -0.9), Color("d9c7a0"), Color.WHITE, lw)
				if fam == "arrow_fire":
					_flame(n, c, s, -0.6, 0.55, 0.45, 0.55, col, Color("fff0a8"))
				elif fam == "arrow_ice":
					for k in range(3):
						var a := PI * float(k) / 3.0
						_line(n, c, s, Vector2(-0.6, 0.6) - Vector2(cos(a), sin(a)) * 0.35, Vector2(-0.6, 0.6) + Vector2(cos(a), sin(a)) * 0.35, col, lw * 0.6)
				else:
					_star4(n, c, s, Vector2(-0.6, 0.6), 0.38, col)
					_star4(n, c, s, Vector2(0.55, 0.55), 0.18, Color.WHITE)
		"arrow_pierce":
			var sp2 := _shield_pts(0.9, 0.0, 0.0)
			_poly(n, c, s, sp2, dark)
			_pline(n, c, s, sp2 + [sp2[0]], col, lw * 0.8)
			_arrow(n, c, s, Vector2(-0.95, 0.25), Vector2(0.95, -0.25), Color("d9c7a0"), Color.WHITE, lw)
		"trap":
			n.draw_arc(c, 0.7 * s, 0, TAU, 28, col, lw * 0.8, true)
			for k in range(8):
				var a := float(k) * PI / 4.0
				var d := Vector2(cos(a), sin(a))
				var t2 := Vector2(-d.y, d.x)
				_poly(n, c, s, [d * 0.7 + t2 * 0.14, d * 0.7 - t2 * 0.14, d * 0.28], col)
			_dot(n, c, s, Vector2.ZERO, 0.14, Color("e8384a"))
		"web":
			for k in range(6):
				var a := float(k) * PI / 3.0
				_line(n, c, s, Vector2.ZERO, Vector2(cos(a), sin(a)) * 0.95, col, lw * 0.5)
			for r in [0.35, 0.65, 0.95]:
				var pts3: Array = []
				for k in range(7):
					var a := float(k) * PI / 3.0
					pts3.append(Vector2(cos(a), sin(a)) * r)
				_pline(n, c, s, pts3, col, lw * 0.45)
			_dot(n, c, s, Vector2.ZERO, 0.08, Color.WHITE)
		"fireball":
			_poly(n, c, s, [Vector2(-0.95, -0.95), Vector2(0.6, -0.05), Vector2(-0.05, 0.6)], Color(col.r, col.g, col.b, 0.8))
			_dot(n, c, s, Vector2(0.3, 0.25), 0.48, col)
			_dot(n, c, s, Vector2(0.3, 0.25), 0.27, Color("fff0a8"))
			_dot(n, c, s, Vector2(-0.6, -0.1), 0.06, col)
			_dot(n, c, s, Vector2(-0.1, -0.65), 0.06, col)
		"firewall":
			for i in range(3):
				var x4 := -0.6 + 0.6 * i
				var h2: float = [0.95, 1.25, 0.95][i]
				_flame(n, c, s, x4, 0.85 - h2 * 0.78 * 0.5 - 0.0, 0.34, h2 * 0.5, col, Color("fff0a8"))
			n.draw_rect(Rect2(_q(c, s, -0.95, 0.85), Vector2(1.9, 0.09) * s), dark.lightened(0.2))
		"meteor":
			_poly(n, c, s, [Vector2(-0.95, -0.95), Vector2(0.65, -0.05), Vector2(-0.05, 0.65)], Color(col.r, col.g, col.b, 0.85))
			_dot(n, c, s, Vector2(0.28, 0.28), 0.5, Color(col.r, col.g, col.b, 0.6))
			_dot(n, c, s, Vector2(0.28, 0.28), 0.38, Color("6b5a52"))
			_dot(n, c, s, Vector2(0.18, 0.2), 0.09, Color("4a3d38"))
			_dot(n, c, s, Vector2(0.4, 0.4), 0.06, Color("4a3d38"))
		"inferno":
			_flame(n, c, s, -0.62, 0.45, 0.4, 0.55, col, Color("ffb03d"))
			_flame(n, c, s, 0.62, 0.45, 0.4, 0.55, col, Color("ffb03d"))
			_flame(n, c, s, 0.0, 0.1, 0.85, 0.95, col, Color("fff0a8"))
			n.draw_rect(Rect2(_q(c, s, -0.95, 0.82), Vector2(1.9, 0.12) * s), Color("8a1d12"))
		"firestar":
			var pts4: Array = []
			var pts5: Array = []
			for k in range(16):
				var a := float(k) * PI / 8.0
				pts4.append(Vector2(cos(a), sin(a)) * (1.0 if k % 2 == 0 else 0.5))
				pts5.append(Vector2(cos(a), sin(a)) * (0.6 if k % 2 == 0 else 0.3))
			_poly(n, c, s, pts4, col)
			_poly(n, c, s, pts5, Color("ffe14d"))
			_dot(n, c, s, Vector2.ZERO, 0.17, Color.WHITE)
		"serpent":
			var pts6: Array = []
			for i in range(13):
				var x5 := -0.9 + 1.5 * float(i) / 12.0
				pts6.append(Vector2(x5, 0.4 * sin(x5 * 5.0)))
			_pline(n, c, s, pts6, col, lw * 1.4)
			_poly(n, c, s, [Vector2(0.55, -0.2), Vector2(0.95, 0.0), Vector2(0.55, 0.22)], col)
			_dot(n, c, s, Vector2(0.65, -0.05), 0.05, Color(0.1, 0.1, 0.2))
			_poly(n, c, s, [Vector2(-0.2, -0.95), Vector2(-0.65, -0.35), Vector2(-0.38, -0.35), Vector2(-0.5, 0.05), Vector2(-0.05, -0.5), Vector2(-0.32, -0.5)], Color.WHITE)
		"lightorb":
			_dot(n, c, s, Vector2.ZERO, 0.45, dark)
			_dot(n, c, s, Vector2.ZERO, 0.34, col)
			_dot(n, c, s, Vector2.ZERO, 0.17, Color.WHITE)
			for k in range(4):
				var a := float(k) * PI * 0.5 + 0.4
				var d2 := Vector2(cos(a), sin(a))
				var t3 := Vector2(-d2.y, d2.x)
				_pline(n, c, s, [d2 * 0.5, d2 * 0.7 + t3 * 0.12, d2 * 0.82 - t3 * 0.1, d2 * 1.0], col, lw * 0.6)
		"thundercloud":
			_cloud(n, c, s, -0.35, Color("8d99b5"))
			_poly(n, c, s, [Vector2(0.2, -0.2), Vector2(-0.3, 0.3), Vector2(0.0, 0.3), Vector2(-0.2, 0.95), Vector2(0.4, 0.15), Vector2(0.08, 0.15)], col)
		"snow":
			for k in range(6):
				var a := float(k) * PI / 3.0
				var d3 := Vector2(cos(a), sin(a))
				_line(n, c, s, Vector2.ZERO, d3 * 0.92, col, lw * 0.6)
				for sg in [-0.5, 0.5]:
					var b := Vector2(cos(a + sg), sin(a + sg))
					_line(n, c, s, d3 * 0.55, d3 * 0.55 + b * 0.28, col, lw * 0.5)
			_dot(n, c, s, Vector2.ZERO, 0.14, Color.WHITE)
		"shards":
			var specs := [[Vector2(-0.45, 0.8), -0.45, 1.0, 0.2], [Vector2(0.5, 0.8), 0.45, 0.95, 0.2], [Vector2(0.0, 0.85), 0.0, 1.7, 0.27]]
			for sp3 in specs:
				var base: Vector2 = sp3[0]
				var ang2: float = sp3[1]
				var ln: float = sp3[2]
				var w: float = sp3[3]
				var dir := Vector2(sin(ang2), -cos(ang2))
				var pp := Vector2(-dir.y, dir.x)
				_poly(n, c, s, [base, base + dir * ln * 0.35 + pp * w, base + dir * ln, base + dir * ln * 0.35 - pp * w], col)
				_line(n, c, s, base, base + dir * ln * 0.92, Color(1, 1, 1, 0.55), maxf(1.0, lw * 0.25))
		"icecage":
			for x in [-0.55, -0.18, 0.18, 0.55]:
				_line(n, c, s, Vector2(x, -0.75), Vector2(x, 0.75), col, lw * 0.7)
			_line(n, c, s, Vector2(-0.7, -0.75), Vector2(0.7, -0.75), pale, lw * 0.9)
			_line(n, c, s, Vector2(-0.7, 0.75), Vector2(0.7, 0.75), pale, lw * 0.9)
			for x2 in [-0.5, 0.0, 0.5]:
				_poly(n, c, s, [Vector2(x2 - 0.15, 0.75), Vector2(x2 + 0.15, 0.75), Vector2(x2, 1.0)], col)
			_star4(n, c, s, Vector2.ZERO, 0.25, Color.WHITE)
		"elements":
			_pline(n, c, s, [Vector2(0, -0.55), Vector2(-0.55, 0.4), Vector2(0.55, 0.4), Vector2(0, -0.55)], Color(1, 1, 1, 0.5), lw * 0.5)
			_dot(n, c, s, Vector2(0, -0.55), 0.3, Color("ff6a2d"))
			_dot(n, c, s, Vector2(-0.55, 0.4), 0.3, Color("4aa8ff"))
			_dot(n, c, s, Vector2(0.55, 0.4), 0.3, Color("ffe14d"))
			_dot(n, c, s, Vector2(0, -0.55), 0.12, Color("fff0a8"))
			_dot(n, c, s, Vector2(-0.55, 0.4), 0.12, Color("bfe8ff"))
			_dot(n, c, s, Vector2(0.55, 0.4), 0.12, Color.WHITE)
			_dot(n, c, s, Vector2(0, 0.1), 0.1, Color.WHITE)
		"bubble":
			_dot(n, c, s, Vector2.ZERO, 0.85, Color(col.r, col.g, col.b, 0.2))
			n.draw_arc(c, 0.85 * s, 0, TAU, 28, col, lw * 0.8, true)
			n.draw_arc(c, 0.62 * s, PI * 1.05, PI * 1.5, 8, Color(1, 1, 1, 0.7), lw * 0.7, true)
			_star4(n, c, s, Vector2(0.1, 0.1), 0.25, pale)
		"crystal":
			var gem := [Vector2(-0.6, -0.25), Vector2(-0.32, -0.75), Vector2(0.32, -0.75), Vector2(0.6, -0.25), Vector2(0.0, 0.88)]
			_poly(n, c, s, gem, col)
			_poly(n, c, s, [Vector2(-0.6, -0.25), Vector2(0.6, -0.25), Vector2(0.0, 0.88)], col.darkened(0.25))
			_pline(n, c, s, gem + [gem[0]], pale, lw * 0.5)
			_line(n, c, s, Vector2(-0.6, -0.25), Vector2(0.6, -0.25), pale, lw * 0.4)
			_line(n, c, s, Vector2(-0.15, -0.75), Vector2(-0.3, -0.25), pale, lw * 0.4)
			_line(n, c, s, Vector2(0.15, -0.75), Vector2(0.3, -0.25), pale, lw * 0.4)
		"rune":
			n.draw_arc(c, 0.92 * s, 0, TAU, 32, col, lw * 0.7, true)
			n.draw_arc(c, 0.74 * s, 0, TAU, 28, Color(col.r, col.g, col.b, 0.6), lw * 0.4, true)
			for off3 in [-PI * 0.5, PI * 0.5]:
				var tp: Array = []
				for k in range(4):
					var a: float = off3 + float(k) * TAU / 3.0
					tp.append(Vector2(cos(a), sin(a)) * 0.72)
				_pline(n, c, s, tp, col, lw * 0.6)
			_dot(n, c, s, Vector2.ZERO, 0.1, Color.WHITE)
		"heal_plus":
			n.draw_arc(c, 0.88 * s, 0, TAU, 28, Color(col.r, col.g, col.b, 0.6), lw * 0.5, true)
			n.draw_rect(Rect2(_q(c, s, -0.17, -0.58), Vector2(0.34, 1.16) * s), col)
			n.draw_rect(Rect2(_q(c, s, -0.58, -0.17), Vector2(1.16, 0.34) * s), col)
			_star4(n, c, s, Vector2(0.62, -0.62), 0.16, Color.WHITE)
			_star4(n, c, s, Vector2(-0.65, 0.6), 0.12, pale)
		"heart":
			_dot(n, c, s, Vector2(-0.3, -0.25), 0.38, col)
			_dot(n, c, s, Vector2(0.3, -0.25), 0.38, col)
			_poly(n, c, s, [Vector2(-0.66, -0.12), Vector2(0.66, -0.12), Vector2(0, 0.85)], col)
			_dot(n, c, s, Vector2(-0.4, -0.35), 0.1, Color(1, 1, 1, 0.65))
		"holyray":
			for a in [-0.75, -0.38, 0.0, 0.38, 0.75]:
				_line(n, c, s, Vector2(0, -0.55), Vector2(sin(a) * 1.4, -0.55 + cos(a) * 1.5), Color(col.r, col.g, col.b, 0.85 if a == 0.0 else 0.55), lw * (1.6 if a == 0.0 else 1.0))
			_dot(n, c, s, Vector2(0, -0.6), 0.3, col)
			_dot(n, c, s, Vector2(0, -0.6), 0.16, Color.WHITE)
		"holycross":
			_dot(n, c, s, Vector2.ZERO, 0.8, Color(col.r, col.g, col.b, 0.18))
			n.draw_rect(Rect2(_q(c, s, -0.14, -0.88), Vector2(0.28, 1.76) * s), col)
			n.draw_rect(Rect2(_q(c, s, -0.52, -0.4), Vector2(1.04, 0.28) * s), col)
			_star4(n, c, s, Vector2(0.0, -0.26), 0.17, Color.WHITE)
			_star4(n, c, s, Vector2(0.72, 0.55), 0.14, pale)
			_star4(n, c, s, Vector2(-0.72, 0.5), 0.12, pale)
		"holydrop":
			_dot(n, c, s, Vector2(0, 0.25), 0.52, col)
			_poly(n, c, s, [Vector2(0, -0.92), Vector2(0.5, 0.12), Vector2(-0.5, 0.12)], col)
			_dot(n, c, s, Vector2(-0.17, 0.2), 0.12, Color(1, 1, 1, 0.75))
			_star4(n, c, s, Vector2(0.65, -0.5), 0.2, Color.WHITE)
			_star4(n, c, s, Vector2(-0.7, -0.3), 0.13, pale)
		"holywave":
			_dot(n, c, s, Vector2(-0.8, 0.0), 0.14, col)
			for r in [0.5, 0.85, 1.2]:
				n.draw_arc(_q(c, s, -0.8, 0.0), r * s, -0.75, 0.75, 8, Color(col.r, col.g, col.b, 1.0 - r * 0.4), lw * 0.9, true)
			_star4(n, c, s, Vector2(0.55, 0.0), 0.2, Color.WHITE)
		"wings":
			for sx in [-1.0, 1.0]:
				_line(n, c, s, Vector2(sx * 0.12, 0.3), Vector2(sx * 0.98, -0.55), col, lw * 1.2)
				_line(n, c, s, Vector2(sx * 0.12, 0.35), Vector2(sx * 0.98, -0.05), col, lw * 1.2)
				_line(n, c, s, Vector2(sx * 0.12, 0.4), Vector2(sx * 0.8, 0.4), col, lw * 1.2)
				_line(n, c, s, Vector2(sx * 0.12, 0.45), Vector2(sx * 0.55, 0.75), col, lw * 1.0)
			n.draw_arc(_q(c, s, 0, -0.62), 0.24 * s, 0, TAU, 14, GOLD, lw * 0.6, true)
			_dot(n, c, s, Vector2(0, 0.2), 0.16, pale)
		"halo":
			n.draw_arc(_q(c, s, 0, -0.82), 0.3 * s, 0, TAU, 16, col, lw * 0.7, true)
			_person(n, c, s, 0.0, 0.3, 0.85, pale)
			_dot(n, c, s, Vector2(0, 0.3), 0.0, col)
		"sunrise":
			var half: Array = []
			for i in range(13):
				var a := PI + PI * float(i) / 12.0
				half.append(Vector2(cos(a), sin(a)) * 0.5 + Vector2(0, 0.35))
			_poly(n, c, s, half, col)
			_line(n, c, s, Vector2(-0.95, 0.35), Vector2(0.95, 0.35), Color.WHITE, lw * 0.6)
			for k in range(5):
				var a2 := PI + 0.25 + (PI - 0.5) * float(k) / 4.0
				_line(n, c, s, Vector2(cos(a2), sin(a2)) * 0.68 + Vector2(0, 0.35), Vector2(cos(a2), sin(a2)) * 0.95 + Vector2(0, 0.35), col, lw * 0.6)
			_line(n, c, s, Vector2(-0.6, 0.65), Vector2(0.6, 0.65), Color(col.r, col.g, col.b, 0.5), lw * 0.5)
		"phoenix":
			for sx in [-1.0, 1.0]:
				_poly(n, c, s, [Vector2(sx * 0.15, 0.25), Vector2(sx * 0.95, -0.8), Vector2(sx * 0.75, -0.05), Vector2(sx * 0.4, 0.05)], col)
				_poly(n, c, s, [Vector2(sx * 0.15, 0.4), Vector2(sx * 1.0, -0.15), Vector2(sx * 0.55, 0.45)], col.darkened(0.15))
			_flame(n, c, s, 0.0, 0.2, 0.3, 0.7, Color("ffd96b"), Color("fff0a8"))
			_poly(n, c, s, [Vector2(-0.22, 0.65), Vector2(0.0, 1.0), Vector2(0.22, 0.65)], col)
			_dot(n, c, s, Vector2(0, -0.5), 0.14, Color("ffd96b"))
		"dome":
			var arc: Array = []
			for i in range(15):
				var a := PI + PI * float(i) / 14.0
				arc.append(Vector2(cos(a), sin(a)) * 0.92 + Vector2(0, 0.6))
			_poly(n, c, s, arc, Color(col.r, col.g, col.b, 0.22))
			_pline(n, c, s, arc, col, lw * 0.9)
			_line(n, c, s, Vector2(-1.0, 0.6), Vector2(1.0, 0.6), col, lw * 0.9)
			n.draw_rect(Rect2(_q(c, s, -0.06, -0.1), Vector2(0.12, 0.5) * s), Color.WHITE)
			n.draw_rect(Rect2(_q(c, s, -0.25, 0.09), Vector2(0.5, 0.12) * s), Color.WHITE)
		"dove":
			_poly(n, c, s, [Vector2(-0.8, 0.4), Vector2(-0.1, 0.0), Vector2(0.45, 0.0), Vector2(0.75, -0.2), Vector2(0.55, 0.2), Vector2(0.0, 0.5)], col)
			_poly(n, c, s, [Vector2(-0.25, 0.05), Vector2(0.05, -0.95), Vector2(0.4, 0.0)], col)
			_poly(n, c, s, [Vector2(-0.15, 0.1), Vector2(-0.35, -0.6), Vector2(-0.02, 0.0)], Color(col.r, col.g, col.b, 0.7))
			_dot(n, c, s, Vector2(0.62, -0.15), 0.13, col)
			_poly(n, c, s, [Vector2(0.72, -0.2), Vector2(0.95, -0.12), Vector2(0.72, -0.08)], Color("ffb03d"))
			_star4(n, c, s, Vector2(-0.6, -0.55), 0.17, Color("ffe08a"))
		"bird":
			for sx in [-1.0, 1.0]:
				_poly(n, c, s, [Vector2(sx * 0.1, 0.0), Vector2(sx * 0.98, -0.6), Vector2(sx * 0.8, 0.05), Vector2(sx * 0.4, 0.25)], col)
				_poly(n, c, s, [Vector2(sx * 0.1, 0.1), Vector2(sx * 0.8, 0.2), Vector2(sx * 0.4, 0.4)], col.darkened(0.2))
			_dot(n, c, s, Vector2(0, 0.1), 0.24, col)
			_dot(n, c, s, Vector2(0, -0.28), 0.16, col)
			_poly(n, c, s, [Vector2(-0.07, -0.3), Vector2(0.07, -0.3), Vector2(0, -0.5)], Color("ffb03d"))
			_poly(n, c, s, [Vector2(-0.14, 0.3), Vector2(0.14, 0.3), Vector2(0.0, 0.9)], col.darkened(0.2))
		"ghost":
			_ghost(n, c, s, 0.0, 0.05, 1.5, col, dark)
		"ghosts":
			_ghost(n, c, s, -0.6, 0.35, 0.8, Color(col.r, col.g, col.b, 0.6), dark)
			_ghost(n, c, s, 0.6, 0.35, 0.8, Color(col.r, col.g, col.b, 0.6), dark)
			_ghost(n, c, s, 0.0, 0.0, 1.15, col, dark)
		"gate":
			_dot(n, c, s, Vector2(0, -0.1), 0.65, col)
			n.draw_rect(Rect2(_q(c, s, -0.65, -0.1), Vector2(1.3, 1.0) * s), col)
			_dot(n, c, s, Vector2(0, -0.1), 0.45, Color(0.06, 0.03, 0.14))
			n.draw_rect(Rect2(_q(c, s, -0.45, -0.1), Vector2(0.9, 0.9) * s), Color(0.06, 0.03, 0.14))
			n.draw_arc(_q(c, s, 0, 0.2), 0.25 * s, 0.5, 4.8, 12, pale, lw * 0.6, true)
			n.draw_arc(_q(c, s, 0, 0.2), 0.12 * s, 3.6, 8.0, 10, pale, lw * 0.5, true)
		"soulwisp":
			_poly(n, c, s, [Vector2(-0.95, 0.95), Vector2(0.0, -0.45), Vector2(0.55, 0.15)], Color(col.r, col.g, col.b, 0.7))
			_dot(n, c, s, Vector2(0.25, -0.1), 0.38, col)
			_dot(n, c, s, Vector2(0.25, -0.1), 0.2, Color.WHITE)
			_dot(n, c, s, Vector2(-0.35, 0.2), 0.06, col)
			_dot(n, c, s, Vector2(0.0, 0.6), 0.05, col)
		"hex":
			n.draw_arc(c, 0.92 * s, 0, TAU, 30, Color(col.r, col.g, col.b, 0.7), lw * 0.6, true)
			var pts7: Array = []
			for k in range(6):
				var a := PI * 0.5 + float(k) * 2.0 * TAU / 5.0
				pts7.append(Vector2(cos(a), sin(a)) * 0.9)
			_pline(n, c, s, pts7, col, lw * 0.8)
			_dot(n, c, s, Vector2.ZERO, 0.1, Color("ff6aa0"))
		"burst":
			for k in range(8):
				var a := float(k) * PI / 4.0
				var d4 := Vector2(cos(a), sin(a))
				_line(n, c, s, d4 * 0.4, d4 * 0.82, col, lw * 0.8)
				_dot(n, c, s, d4 * 0.92, 0.1, col)
			_dot(n, c, s, Vector2.ZERO, 0.38, col)
			_dot(n, c, s, Vector2.ZERO, 0.2, Color.WHITE)
		"miasma":
			for sp4 in [[-0.45, 0.15, 0.45], [0.4, 0.1, 0.5], [0.0, -0.35, 0.45], [0.0, 0.4, 0.45]]:
				_dot(n, c, s, Vector2(sp4[0], sp4[1]), sp4[2], Color(col.r, col.g, col.b, 0.75))
			_dot(n, c, s, Vector2(-0.15, -0.05), 0.07, pale)
			_dot(n, c, s, Vector2(0.15, -0.05), 0.07, pale)
			_dot(n, c, s, Vector2(-0.75, -0.55), 0.06, col)
			_dot(n, c, s, Vector2(0.8, -0.5), 0.05, col)
		"chains":
			_capsule(n, c, s, Vector2(-0.85, -0.55), Vector2(-0.15, -0.55), s * 0.34, col)
			_capsule(n, c, s, Vector2(-0.85, -0.55), Vector2(-0.15, -0.55), s * 0.16, Color(0.05, 0.04, 0.1))
			_capsule(n, c, s, Vector2(-0.05, -0.5), Vector2(-0.05, 0.2), s * 0.34, pale)
			_capsule(n, c, s, Vector2(-0.05, -0.5), Vector2(-0.05, 0.2), s * 0.16, Color(0.05, 0.04, 0.1))
			_capsule(n, c, s, Vector2(0.05, 0.4), Vector2(0.8, 0.4), s * 0.34, col)
			_capsule(n, c, s, Vector2(0.05, 0.4), Vector2(0.8, 0.4), s * 0.16, Color(0.05, 0.04, 0.1))
		"dragon":
			var prev := Vector2(-0.9, 0.65)
			for i in range(1, 13):
				var t4 := float(i) / 12.0
				var cur := Vector2(-0.9 + 1.5 * t4, 0.65 - 1.1 * t4 + 0.28 * sin(t4 * 9.0))
				_line(n, c, s, prev, cur, col, lw * (0.5 + 1.1 * t4))
				prev = cur
			_poly(n, c, s, [prev + Vector2(-0.15, -0.2), prev + Vector2(0.45, -0.05), prev + Vector2(0.1, 0.25), prev + Vector2(-0.2, 0.15)], col)
			_poly(n, c, s, [prev + Vector2(-0.12, -0.18), prev + Vector2(-0.3, -0.5), prev + Vector2(0.05, -0.2)], pale)
			_dot(n, c, s, prev + Vector2(0.05, -0.03), 0.05, Color(0.1, 0.05, 0.05))
			_flame(n, c, s, prev.x + 0.55, prev.y + 0.05, 0.14, 0.18, Color("ff8a3d"), Color("fff0a8"))
		"yinyang":
			_dot(n, c, s, Vector2.ZERO, 0.88, Color("e8e8f5"))
			var half2: Array = []
			for i in range(17):
				var a := -PI * 0.5 + PI * float(i) / 16.0
				half2.append(Vector2(cos(a), sin(a)) * 0.88)
			_poly(n, c, s, half2, Color("22223a"))
			_dot(n, c, s, Vector2(0, -0.44), 0.44, Color("e8e8f5"))
			_dot(n, c, s, Vector2(0, 0.44), 0.44, Color("22223a"))
			_dot(n, c, s, Vector2(0, -0.44), 0.12, Color("22223a"))
			_dot(n, c, s, Vector2(0, 0.44), 0.12, Color("e8e8f5"))
			n.draw_arc(c, 0.88 * s, 0, TAU, 30, Color("ffd96b"), lw * 0.5, true)
		"waves":
			for i in range(3):
				var wp: Array = []
				var y4 := -0.55 + 0.55 * i
				for k in range(13):
					var x6 := -0.95 + 1.9 * float(k) / 12.0
					wp.append(Vector2(x6, y4 + 0.18 * sin(x6 * 5.0 + float(i))))
				_pline(n, c, s, wp, Color(col.r, col.g, col.b, 1.0 - 0.2 * i), lw * 0.95)
		"palm":
			n.draw_rect(Rect2(_q(c, s, -0.4, -0.05), Vector2(0.8, 0.85) * s), col)
			_dot(n, c, s, Vector2(0, 0.8), 0.4, col)
			for i in range(4):
				var fx := -0.3 + 0.2 * i
				var ft: float = [-0.65, -0.85, -0.78, -0.55][i]
				_line(n, c, s, Vector2(fx, -0.02), Vector2(fx, ft), col, lw * 0.95)
				_dot(n, c, s, Vector2(fx, ft), 0.075, col)
			_line(n, c, s, Vector2(-0.38, 0.3), Vector2(-0.78, -0.1), col, lw * 0.95)
			n.draw_arc(_q(c, s, 0.0, 0.3), 0.22 * s, 0, TAU, 14, dark, lw * 0.6, true)
			_star4(n, c, s, Vector2(0.0, 0.3), 0.14, Color.WHITE)
		_:
			_poly(n, c, s, [Vector2(0, -0.9), Vector2(0.6, 0), Vector2(0, 0.9), Vector2(-0.6, 0)], col)
