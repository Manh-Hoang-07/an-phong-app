extends RefCounted
## "Skin" game: khung / nút / ô đồ / ribbon / thanh máu vẽ procedural bằng code (không cần file ảnh).
## Mỗi kiểu là một ảnh nhỏ có viền đồng nổi khối, nền slate-gradient sâu, khử răng cưa; dùng như StyleBoxTexture 9-slice.
## Control dùng skin nên đặt texture_filter = LINEAR (HUD/Login/Boot đã đặt ở root).
## Hướng nghệ thuật: dark slate + warm brass — viền đồng đa lớp, rãnh tối, rim-light phía trên.

static var _cache: Dictionary = {}

# ------------------------------------------------------------------ Bảng màu skin
const GOLD_HI   := Color(1.00, 0.88, 0.56)   # đồng sáng (đỉnh bevel)
const GOLD_MID  := Color(0.82, 0.62, 0.24)   # đồng giữa
const GOLD_LO   := Color(0.45, 0.30, 0.09)   # đồng tối (đáy bevel)
const BRASS_HI  := Color(0.72, 0.55, 0.28)
const BRASS_LO  := Color(0.24, 0.16, 0.06)
const INK       := Color(0.02, 0.03, 0.06)
const SLATE_TOP := Color(0.10, 0.14, 0.23, 1)
const SLATE_BOT := Color(0.035, 0.052, 0.10, 1)

# Độ hiếm: bạc → xanh lá → xanh dương → tím → cam huyền thoại.
const QUALITY := [
	Color(0.56, 0.61, 0.69), Color(0.62, 0.74, 0.55), Color(0.30, 0.85, 0.52),
	Color(0.30, 0.62, 1.00), Color(0.72, 0.42, 1.00), Color(1.00, 0.66, 0.20),
]

# ------------------------------------------------------------------ Lõi vẽ
## Khoảng cách có dấu tới hình chữ nhật bo góc (âm = bên trong).
static func _sd(px: float, py: float, w: float, h: float, r: float) -> float:
	var qx := absf(px - w * 0.5) - (w * 0.5 - r)
	var qy := absf(py - h * 0.5) - (h * 0.5 - r)
	return minf(maxf(qx, qy), 0.0) + Vector2(maxf(qx, 0.0), maxf(qy, 0.0)).length() - r

static func _over(dst: Color, src: Color) -> Color:
	var a := src.a + dst.a * (1.0 - src.a)
	if a <= 0.0001: return Color(0, 0, 0, 0)
	var rgb := (Vector3(src.r, src.g, src.b) * src.a + Vector3(dst.r, dst.g, dst.b) * dst.a * (1.0 - src.a)) / a
	return Color(rgb.x, rgb.y, rgb.z, a)

## layers: [[inset, width, top, bottom], ...]  width < 0 = tô kín từ inset trở vào.
## gloss: phần trăm chiều cao phía trên được sáng thêm (độ bóng) cho lớp tô kín cuối.
static func _paint(w: int, h: int, r: float, layers: Array, studs: Color = Color(0, 0, 0, 0), gloss: float = 0.0) -> Image:
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for y in range(h):
		var ty := (float(y) + 0.5) / float(h)
		for x in range(w):
			var d := _sd(float(x) + 0.5, float(y) + 0.5, float(w), float(h), r)
			var outer := clampf(0.5 - d, 0.0, 1.0)
			if outer <= 0.0: continue
			var depth := -d
			var col := Color(0, 0, 0, 0)
			var last_fill := -1
			for i in range(layers.size()):
				var L: Array = layers[i]
				var inset := float(L[0]); var wd := float(L[1])
				var cov := clampf(depth - inset + 0.5, 0.0, 1.0)
				if wd >= 0.0: cov *= clampf(inset + wd - depth + 0.5, 0.0, 1.0)
				else: last_fill = i
				if cov <= 0.0: continue
				var c: Color = (L[2] as Color).lerp(L[3] as Color, ty)
				c.a *= cov
				col = _over(col, c)
			if gloss > 0.0 and ty < gloss and last_fill >= 0:
				var gi := float((layers[last_fill] as Array)[0])
				var gcov := clampf(depth - gi + 0.5, 0.0, 1.0)
				col = _over(col, Color(1, 1, 1, 0.13 * (1.0 - ty / gloss) * gcov))
			col.a *= outer
			img.set_pixel(x, y, col)
	if studs.a > 0.0:
		for p in [Vector2(7, 7), Vector2(w - 7, 7), Vector2(7, h - 7), Vector2(w - 7, h - 7)]:
			for y in range(int(p.y) - 3, int(p.y) + 4):
				for x in range(int(p.x) - 3, int(p.x) + 4):
					if x < 0 or y < 0 or x >= w or y >= h: continue
					var dd := Vector2(float(x) + 0.5, float(y) + 0.5).distance_to(p)
					var c2 := Color(studs, clampf(2.4 - dd, 0.0, 1.0))
					if c2.a > 0.0: img.set_pixel(x, y, _over(img.get_pixel(x, y), c2))
	return img

static func _box(key: String, w: int, h: int, r: float, layers: Array, margin: int, content: int = 8, studs: Color = Color(0, 0, 0, 0), gloss: float = 0.0) -> StyleBoxTexture:
	var ck := "%s|%d" % [key, content]   # content_margin khác nhau thì không dùng chung bản cache
	if _cache.has(ck): return (_cache[ck] as StyleBoxTexture).duplicate() as StyleBoxTexture
	var sb := StyleBoxTexture.new()
	sb.texture = ImageTexture.create_from_image(_paint(w, h, r, layers, studs, gloss))
	sb.texture_margin_left = margin; sb.texture_margin_right = margin
	sb.texture_margin_top = margin; sb.texture_margin_bottom = margin
	sb.content_margin_left = content; sb.content_margin_right = content
	sb.content_margin_top = content; sb.content_margin_bottom = content
	_cache[ck] = sb
	return sb.duplicate() as StyleBoxTexture

# ------------------------------------------------------------------ Khung lớn
## Khung panel: viền đồng nổi khối nhiều tầng, rãnh tối, nền slate gradient, đinh tán 4 góc, rim-light.
static func panel(content: int = 12) -> StyleBoxTexture:
	var L := [
		[0.0, 1.6, Color(0.0, 0.0, 0.01, 1), Color(0.0, 0.0, 0.01, 1)],
		[1.6, 0.9, BRASS_LO, Color(0.10, 0.07, 0.02, 1)],
		[2.5, 2.2, GOLD_HI, GOLD_MID],
		[4.7, 0.9, Color(0.95, 0.80, 0.45, 1), Color(0.35, 0.24, 0.08, 1)],
		[5.6, 1.3, INK, INK],
		[6.9, -1.0, SLATE_TOP, SLATE_BOT],
		[6.9, 1.6, Color(1, 1, 1, 0.18), Color(1, 1, 1, 0.0)],
	]
	return _box("panel", 56, 56, 15.0, L, 20, content, Color(0.55, 0.42, 0.20, 0.9))

## Thẻ con bên trong panel: nền slate tối hơn, viền xanh thép mảnh, rim-light nhẹ.
static func card(content: int = 8) -> StyleBoxTexture:
	var L := [
		[0.0, 1.0, Color(0.46, 0.56, 0.74, 0.60), Color(0.26, 0.33, 0.50, 0.60)],
		[1.0, -1.0, Color(0.11, 0.15, 0.24, 0.97), Color(0.06, 0.09, 0.16, 0.97)],
		[1.0, 1.2, Color(1, 1, 1, 0.11), Color(1, 1, 1, 0.0)],
	]
	return _box("card", 36, 36, 10.0, L, 12, content)

## Khung "lõm" tối (nền danh sách, khung chi tiết).
static func inset(content: int = 8) -> StyleBoxTexture:
	var L := [
		[0.0, 1.2, Color(0.0, 0.0, 0.0, 0.9), Color(0.0, 0.0, 0.0, 0.9)],
		[1.2, -1.0, Color(0.025, 0.04, 0.075, 0.95), Color(0.05, 0.07, 0.13, 0.95)],
		[1.2, 1.0, Color(0.36, 0.46, 0.64, 0.30), Color(0.36, 0.46, 0.64, 0.06)],
	]
	return _box("inset", 36, 36, 10.0, L, 12, content)

## Thanh tiêu đề (ribbon) đồng đánh bóng — dùng cho header panel.
static func ribbon() -> StyleBoxTexture:
	var L := [
		[0.0, 1.0, Color(0.02, 0.01, 0.0, 1), Color(0.02, 0.01, 0.0, 1)],
		[1.0, 1.8, GOLD_HI, GOLD_MID],
		[2.8, 1.0, Color(0.55, 0.38, 0.12, 1), Color(0.28, 0.18, 0.05, 1)],
		[3.8, -1.0, Color(0.26, 0.18, 0.06, 1), Color(0.10, 0.06, 0.02, 1)],
		[3.8, 1.0, Color(1, 0.88, 0.55, 0.32), Color(1, 0.88, 0.55, 0.0)],
	]
	return _box("ribbon", 40, 32, 7.0, L, 12, 8, Color(0, 0, 0, 0), 0.6)

# ------------------------------------------------------------------ Nút
## kind: "default" | "primary" | "danger" | "ghost"; state: "normal" | "hover" | "pressed" | "disabled"
static func button(kind: String = "default", state: String = "normal", content: int = 8) -> StyleBoxTexture:
	var key := "btn_%s_%s" % [kind, state]
	var top: Color; var bot: Color; var edge: Color; var hi := Color(1, 1, 1, 0.30)
	match kind:
		"primary":
			top = Color(1.0, 0.91, 0.62); bot = Color(0.88, 0.62, 0.18); edge = Color(0.38, 0.24, 0.04)
		"danger":
			top = Color(0.86, 0.36, 0.38); bot = Color(0.50, 0.14, 0.18); edge = Color(0.20, 0.04, 0.06)
		"ghost":
			top = Color(0.16, 0.22, 0.34, 0.9); bot = Color(0.09, 0.13, 0.22, 0.9); edge = Color(0.42, 0.52, 0.70, 0.75); hi = Color(1, 1, 1, 0.12)
		_:
			top = Color(0.30, 0.40, 0.60); bot = Color(0.14, 0.21, 0.36); edge = Color(0.04, 0.06, 0.12)
	match state:
		"hover":
			top = top.lightened(0.13); bot = bot.lightened(0.11)
		"pressed":
			var t := top; top = bot.darkened(0.08); bot = t.darkened(0.12); hi = Color(1, 1, 1, 0.0)
			edge = GOLD_MID if kind != "primary" else Color(0.5, 0.3, 0.05)
		"disabled":
			top = Color(0.14, 0.16, 0.22, 0.9); bot = Color(0.09, 0.10, 0.15, 0.9); edge = Color(0.05, 0.06, 0.1); hi = Color(1, 1, 1, 0.03)
	var L := [
		[0.0, 1.0, edge, edge],
		[1.0, -1.0, top, bot],
		[1.0, 2.5, Color(0, 0, 0, 0.0), Color(0, 0, 0, 0.22)],
		[1.0, 1.0, hi, Color(hi, 0.0)],
	]
	return _box(key, 36, 36, 10.0, L, 12, content, Color(0, 0, 0, 0), 0.0 if state == "pressed" else 0.45)

## Nút tròn (menu, chat, đóng). size = đường kính.
static func round_button(size: int, state: String = "normal", gold: bool = false) -> StyleBoxTexture:
	var key := "rb_%d_%s_%s" % [size, state, str(gold)]
	var top := Color(0.24, 0.33, 0.52, 0.96); var bot := Color(0.09, 0.13, 0.25, 0.96)
	var rim := GOLD_HI if gold else Color(0.68, 0.78, 0.95)
	var rim2 := GOLD_LO if gold else Color(0.28, 0.37, 0.56)
	if state == "pressed": top = bot; bot = Color(0.27, 0.36, 0.55, 0.96); rim = GOLD_HI
	if state == "hover": top = top.lightened(0.11)
	var L := [
		[0.0, 1.0, Color(0.0, 0.0, 0.02, 0.95), Color(0.0, 0.0, 0.02, 0.95)],
		[1.0, 1.8, rim, rim2],
		[2.8, -1.0, top, bot],
		[2.8, 1.0, Color(1, 1, 1, 0.24), Color(1, 1, 1, 0.0)],
	]
	var m := size / 2
	return _box(key, size, size, float(size) * 0.5, L, m, 0, Color(0, 0, 0, 0), 0.4)

# ------------------------------------------------------------------ Ô đồ
## q: độ hiếm 0..5. selected: viền vàng + inner glow. Nền lõm tối + viền màu theo độ hiếm.
static func slot(q: int = 0, selected: bool = false, empty: bool = false) -> StyleBoxTexture:
	var key := "slot_%d_%s_%s" % [q, str(selected), str(empty)]
	var qc: Color = QUALITY[clampi(q, 0, 5)]
	var edge: Color = GOLD_HI if selected else (Color(qc, 0.4) if empty else qc)
	var bg_top := Color(0.03, 0.04, 0.08, 1) if not selected else Color(0.14, 0.18, 0.29, 1)
	var bg_bot := Color(0.10, 0.13, 0.22, 1) if not selected else Color(0.22, 0.28, 0.44, 1)
	if empty:
		bg_top = Color(0.03, 0.04, 0.07, 0.85); bg_bot = Color(0.06, 0.08, 0.13, 0.85)
	var L := [
		[0.0, 1.0, Color(0, 0, 0, 0.95), Color(0, 0, 0, 0.95)],
		[1.0, 1.8 if selected else 1.4, edge, Color(edge, 0.5)],
		[2.4, -1.0, bg_top, bg_bot],
		[2.4, 2.0, Color(0, 0, 0, 0.5), Color(0, 0, 0, 0.0)],
	]
	if q >= 3 and not empty:
		L.append([2.4, 7.0, Color(qc, 0.0), Color(qc, 0.28)])
	if selected:
		L.append([2.4, 5.0, Color(GOLD_HI, 0.22), Color(GOLD_HI, 0.0)])
	return _box(key, 40, 40, 8.0, L, 12, 0)

## Ô kỹ năng/tròn dùng cho emoji: dùng round_button thay thế.

# ------------------------------------------------------------------ Thanh
static func bar_frame(content: int = 0) -> StyleBoxTexture:
	var L := [
		[0.0, 1.0, Color(0, 0, 0, 0.95), Color(0, 0, 0, 0.95)],
		[1.0, 1.6, Color(0.90, 0.74, 0.34), Color(0.42, 0.30, 0.10)],
		[2.6, -1.0, Color(0.01, 0.02, 0.04, 0.96), Color(0.05, 0.07, 0.13, 0.96)],
	]
	return _box("bar_frame", 24, 18, 9.0, L, 9, content)

static func bar_fill(color: Color) -> StyleBoxTexture:
	var key := "bar_fill_" + color.to_html()
	var L := [
		[0.0, -1.0, color.lightened(0.30), color.darkened(0.32)],
		[0.0, 1.0, Color(1, 1, 1, 0.38), Color(1, 1, 1, 0.0)],
	]
	return _box(key, 24, 14, 7.0, L, 7, 0, Color(0, 0, 0, 0), 0.5)

# ------------------------------------------------------------------ Tab / pill
static func tab(active: bool) -> StyleBoxTexture:
	var key := "tab_" + str(active)
	var L: Array
	if active:
		L = [
			[0.0, 1.0, Color(0, 0, 0, 0.9), Color(0, 0, 0, 0.9)],
			[1.0, 1.8, GOLD_HI, GOLD_MID],
			[2.8, -1.0, Color(0.22, 0.30, 0.46, 1), Color(0.12, 0.17, 0.29, 1)],
			[2.8, 1.2, Color(1, 1, 1, 0.22), Color(1, 1, 1, 0)],
		]
	else:
		L = [
			[0.0, 1.0, Color(0.38, 0.47, 0.62, 0.5), Color(0.24, 0.30, 0.44, 0.5)],
			[1.0, -1.0, Color(0.09, 0.12, 0.20, 0.92), Color(0.05, 0.07, 0.13, 0.92)],
		]
	return _box(key, 32, 32, 9.0, L, 11, 6, Color(0, 0, 0, 0), 0.4 if active else 0.0)

## Viên thuốc HUD (nhiệm vụ, tên map): nền tối mờ, viền vàng mảnh.
static func pill() -> StyleBoxTexture:
	var L := [
		[0.0, 1.0, Color(GOLD_MID, 0.9), Color(GOLD_LO, 0.9)],
		[1.0, -1.0, Color(0.05, 0.08, 0.15, 0.82), Color(0.03, 0.045, 0.09, 0.82)],
		[1.0, 1.0, Color(1, 1, 1, 0.12), Color(1, 1, 1, 0.0)],
	]
	return _box("pill", 36, 36, 17.0, L, 17, 8)

## Khung thông tin trạng thái (HP/MP/thể lực) góc trái-trên: nền tối mờ, viền vàng mảnh, góc bo vừa.
static func plate(content: int = 6) -> StyleBoxTexture:
	var L := [
		[0.0, 1.0, Color(GOLD_MID, 0.92), Color(GOLD_LO, 0.92)],
		[1.0, -1.0, Color(0.06, 0.09, 0.16, 0.80), Color(0.03, 0.045, 0.09, 0.80)],
		[1.0, 1.0, Color(1, 1, 1, 0.12), Color(1, 1, 1, 0.0)],
	]
	return _box("plate", 36, 36, 12.0, L, 13, content)
