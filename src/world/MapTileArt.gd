extends RefCounted
## Bộ sinh ảnh ô đất cho MapView (thuần: nhận tham số, trả Image — không đụng trạng thái bản đồ): mặt đá/cỏ, thân đất, vết nứt, rễ, nhỏ giọt, gỗ...

const TILE := 32
const CHUNK := 1024

static func _hash2(a: int, b: int) -> int:
	var h := (a * 73856093) ^ (b * 19349663)
	h = (h ^ (h >> 13)) * 1274126177
	return absi(h ^ (h >> 16))

## Lớp phủ mặt đất (cỏ/rêu/tuyết/bụi): viền dưới gợn sóng, ngọn nhô lên; mép trái/phải trùng nhau giữa các biến thể.
static func _make_cap(seed_i: int, pal: Dictionary) -> Image:
	var W := 32
	var H := 22
	var TOP := 8
	var rng := RandomNumberGenerator.new()
	rng.seed = 9000 + seed_i
	var im := Image.create(W, H, false, Image.FORMAT_RGBA8)
	im.fill(Color(0, 0, 0, 0))
	var a1 := rng.randf_range(0.8, 2.2)
	var a2 := rng.randf_range(0.5, 1.6)
	var k1 := rng.randi_range(1, 2)
	var k2 := rng.randi_range(3, 5)
	var base_d: float = float(pal["depth"])
	var light: Color = pal["light"]
	var mid: Color = pal["mid"]
	var dark: Color = pal["dark"]
	for x in range(W):
		var u := float(x) / float(W)
		var depth := base_d + a1 * sin(TAU * k1 * u) + a2 * sin(TAU * k2 * u)
		var hb := rng.randi_range(2, 5) if rng.randf() < 0.32 else rng.randi_range(0, 1)
		if x == 0 or x == W - 1: hb = 0
		for y in range(H):
			var ty := float(y - TOP)
			if ty < -float(hb) or ty >= depth + 1.0: continue
			var al := clampf(depth - ty, 0.0, 1.0)
			var t := (ty + float(hb)) / (depth + float(hb))
			var col := light.lerp(mid, clampf(t * 1.6, 0.0, 1.0)).lerp(dark, clampf((t - 0.55) * 2.2, 0.0, 1.0))
			if ty < 0.0:
				col = light.lerp(mid, 0.35 + 0.15 * float((x + y) % 3))
			var n := float(_hash2(x + seed_i * 31, y) % 100) / 100.0
			if n < 0.12: col = col.lightened(0.07)
			elif n > 0.9: col = col.darkened(0.1)
			col.a = al
			im.set_pixel(x, y, col)
	return im

## Dải rêu/tuyết bám mép bên của ô mặt đất (left=true: mép trái).
static func _make_side(seed_i: int, left: bool, pal: Dictionary) -> Image:
	var W := 6
	var H := 20
	var rng := RandomNumberGenerator.new()
	rng.seed = 7000 + seed_i
	var im := Image.create(W, H, false, Image.FORMAT_RGBA8)
	im.fill(Color(0, 0, 0, 0))
	var light: Color = pal["light"]
	var mid: Color = pal["mid"]
	var dark: Color = pal["dark"]
	for y in range(H):
		var wd := clampf(float(W) - 1.0 - float(y) * 0.16 + float(rng.randi_range(-1, 1)), 0.0, float(W))
		for x in range(W):
			if float(x) >= wd: continue
			var edge := (wd - float(x)) < 1.5
			var c := mid.lerp(dark, float(y) / float(H)) if edge else light.lerp(mid, float(x) / float(W) + float(y) / float(H))
			var px := x if left else (W - 1 - x)
			im.set_pixel(px, y, c)
	return im

static func _make_blotch(seed_i: int, light_blob: bool) -> Image:
	var rng := RandomNumberGenerator.new()
	rng.seed = 5000 + seed_i + (500 if light_blob else 0)
	var im := Image.create(TILE, TILE, false, Image.FORMAT_RGBA8)
	im.fill(Color(0, 0, 0, 0))
	for _b in range(3):
		var cx := rng.randf_range(10.0, 22.0)
		var cy := rng.randf_range(10.0, 22.0)
		var rx := rng.randf_range(3.0, 7.0)
		var ry := rng.randf_range(2.5, 6.0)
		for y in range(int(cy - ry) - 1, int(cy + ry) + 2):
			for x in range(int(cx - rx) - 1, int(cx + rx) + 2):
				if x < 2 or y < 2 or x > TILE - 3 or y > TILE - 3: continue
				var d := sqrt(pow((float(x) - cx) / rx, 2.0) + pow((float(y) - cy) / ry, 2.0))
				if d >= 1.0: continue
				var al := (1.0 - d) * (0.10 if light_blob else 0.16)
				var o := im.get_pixel(x, y)
				var na := minf(0.3, o.a + al)
				im.set_pixel(x, y, Color(1, 1, 1, na) if light_blob else Color(0.04, 0.02, 0.0, na))
	return im

static func _make_crack(seed_i: int) -> Image:
	var rng := RandomNumberGenerator.new()
	rng.seed = 3000 + seed_i
	var im := Image.create(TILE, TILE, false, Image.FORMAT_RGBA8)
	im.fill(Color(0, 0, 0, 0))
	var x := rng.randi_range(8, 24)
	var y := rng.randi_range(5, 10)
	var dx := rng.randi_range(-1, 1)
	var n := rng.randi_range(9, 16)
	for i in range(n):
		if x < 3 or x > TILE - 4 or y < 3 or y > TILE - 4: break
		im.set_pixel(x, y, Color(0.03, 0.02, 0.01, 0.55))
		im.set_pixel(x + 1, y, Color(1, 1, 1, 0.1))
		y += 1
		if rng.randf() < 0.55: dx = rng.randi_range(-1, 1)
		x += dx
		if i == 6:   # nhánh phụ
			var bx := x
			var by := y
			for _j in range(4):
				bx += 1 if dx >= 0 else -1
				by += 1
				if bx < 3 or bx > TILE - 4 or by > TILE - 4: break
				im.set_pixel(bx, by, Color(0.03, 0.02, 0.01, 0.4))
	return im

static func _make_shadow(h: int, strength: float) -> Image:
	var im := Image.create(TILE, h, false, Image.FORMAT_RGBA8)
	for y in range(h):
		var k := 1.0 - float(y) / float(h)
		var c := Color(0.02, 0.01, 0.0, strength * k * k)
		for x in range(TILE): im.set_pixel(x, y, c)
	return im

static func _avg_color(im: Image) -> Color:
	if im == null: return Color(0.4, 0.28, 0.16)
	var r := 0.0
	var g := 0.0
	var b := 0.0
	var n := 0
	for y in range(0, im.get_height(), 2):
		for x in range(0, im.get_width(), 2):
			var p := im.get_pixel(x, y)
			if p.a < 0.5: continue
			r += p.r
			g += p.g
			b += p.b
			n += 1
	if n == 0: return Color(0.4, 0.28, 0.16)
	return Color(r / n, g / n, b / n)

## Một viên đá có khối: mặt sáng phía trên-trái, tối phía dưới-phải, viền tối, vết nứt, rêu bám phía trên.
static func _stone_into(im: Image, cx: float, cy: float, rx: float, ry: float, sd: int, moss: bool, crack: bool, pal: Dictionary) -> void:
	var lit_c := Color(0.76, 0.72, 0.64)
	var dark_c := Color(0.2, 0.18, 0.2)
	var W := im.get_width()
	var H := im.get_height()
	var mid: Color = pal["mid"]
	var light: Color = pal["light"]
	# quầng tối quanh viên đá (đất bị ép)
	for y in range(int(cy - ry) - 2, int(cy + ry) + 3):
		for x in range(int(cx - rx) - 2, int(cx + rx) + 3):
			if x < 0 or y < 0 or x >= W or y >= H: continue
			var hx := (float(x) + 0.5 - cx) / (rx + 1.6)
			var hy := (float(y) + 0.5 - cy - 1.0) / (ry + 1.6)
			if hx * hx + hy * hy < 1.0 and im.get_pixel(x, y).a < 0.01:
				im.set_pixel(x, y, Color(0.03, 0.02, 0.01, 0.32))
	for y in range(int(cy - ry) - 1, int(cy + ry) + 2):
		for x in range(int(cx - rx) - 1, int(cx + rx) + 2):
			if x < 0 or y < 0 or x >= W or y >= H: continue
			var nx := (float(x) + 0.5 - cx) / rx
			var ny := (float(y) + 0.5 - cy) / ry
			var d := pow(pow(absf(nx), 2.6) + pow(absf(ny), 2.6), 1.0 / 2.6)
			if d >= 1.0: continue
			var n := float(_hash2(x * 3 + sd, y * 5 + sd) % 100) / 100.0
			var lit := clampf(0.55 - ny * 0.5 - nx * 0.25 + (n - 0.5) * 0.16, 0.0, 1.0)
			var col := dark_c.lerp(lit_c, lit)
			if d > 0.72 and ny < -0.25 and nx < 0.5: col = col.lightened(0.18)
			if moss and ny < -0.2 + (n - 0.5) * 0.7:
				col = mid.lerp(light, n)
				if d > 0.85: col = col.darkened(0.3)
			if d > 0.88: col = Color(0.08, 0.07, 0.08)
			im.set_pixel(x, y, col)
	if crack:
		var x := int(cx) + 1
		var y := int(cy - ry * 0.5)
		for _i in range(int(ry * 1.2)):
			if x < 0 or y < 0 or x >= W or y >= H: break
			if im.get_pixel(x, y).a > 0.9: im.set_pixel(x, y, Color(0.07, 0.06, 0.07))
			y += 1
			x += (_hash2(x + sd, y) % 3) - 1

static func _make_stone_tile(seed_i: int, pal: Dictionary) -> Image:
	var rng := RandomNumberGenerator.new()
	rng.seed = 11000 + seed_i
	var im := Image.create(TILE, TILE, false, Image.FORMAT_RGBA8)
	im.fill(Color(0, 0, 0, 0))
	var moss := float(pal["cover"]) >= 0.7 and seed_i % 3 == 0
	_stone_into(im, rng.randf_range(11.0, 21.0), rng.randf_range(13.0, 20.0), rng.randf_range(4.5, 7.5), rng.randf_range(3.5, 5.5), seed_i, moss, true, pal)
	if seed_i % 3 == 0:
		_stone_into(im, rng.randf_range(4.0, 8.0), rng.randf_range(22.0, 27.0), 2.6, 2.0, seed_i + 7, false, false, pal)
	return im

## Sỏi/đá cuội nhỏ lẫn trong đất.
static func _make_gravel(seed_i: int, pal: Dictionary) -> Image:
	var rng := RandomNumberGenerator.new()
	rng.seed = 12000 + seed_i
	var im := Image.create(TILE, TILE, false, Image.FORMAT_RGBA8)
	im.fill(Color(0, 0, 0, 0))
	for _i in range(rng.randi_range(4, 6)):
		_stone_into(im, rng.randf_range(3.0, 29.0), rng.randf_range(3.0, 29.0), rng.randf_range(1.5, 2.6), rng.randf_range(1.2, 2.0), rng.randi(), false, false, pal)
	return im

static func _make_grain(seed_i: int) -> Image:
	var rng := RandomNumberGenerator.new()
	rng.seed = 13000 + seed_i
	var im := Image.create(TILE, TILE, false, Image.FORMAT_RGBA8)
	im.fill(Color(0, 0, 0, 0))
	for _i in range(46):
		var x := rng.randi_range(0, TILE - 1)
		var y := rng.randi_range(0, TILE - 1)
		if rng.randf() < 0.5: im.set_pixel(x, y, Color(1.0, 0.92, 0.75, 0.13))
		else: im.set_pixel(x, y, Color(0.04, 0.02, 0.0, 0.2))
	return im

## Mảng màu loang lớn (ấm/lạnh/sáng) làm đất có nhiều tông.
static func _make_patch(seed_i: int, col: Color, amax: float) -> Image:
	var rng := RandomNumberGenerator.new()
	rng.seed = 14000 + seed_i
	var im := Image.create(TILE, TILE, false, Image.FORMAT_RGBA8)
	im.fill(Color(0, 0, 0, 0))
	for _b in range(2):
		var cx := rng.randf_range(6.0, 26.0)
		var cy := rng.randf_range(6.0, 26.0)
		var rx := rng.randf_range(6.0, 12.0)
		var ry := rng.randf_range(4.0, 9.0)
		for y in range(maxi(0, int(cy - ry)), mini(TILE, int(cy + ry) + 1)):
			for x in range(maxi(0, int(cx - rx)), mini(TILE, int(cx + rx) + 1)):
				var d := sqrt(pow((float(x) - cx) / rx, 2.0) + pow((float(y) - cy) / ry, 2.0))
				if d >= 1.0: continue
				var n := float(_hash2(x + seed_i * 17, y * 3) % 100) / 100.0
				var al := (1.0 - d) * amax * (0.7 + 0.5 * n)
				var o := im.get_pixel(x, y)
				im.set_pixel(x, y, Color(col.r, col.g, col.b, minf(amax, o.a + al)))
	return im

## Địa tầng ngang (lượn sóng, tuần hoàn theo x để nối liền giữa các ô).
static func _make_strata(seed_i: int) -> Image:
	var rng := RandomNumberGenerator.new()
	rng.seed = 15000 + seed_i
	var im := Image.create(TILE, TILE, false, Image.FORMAT_RGBA8)
	im.fill(Color(0, 0, 0, 0))
	var y0 := rng.randi_range(5, 24)
	var amp := rng.randf_range(0.8, 2.2)
	var kk := rng.randi_range(1, 2)
	var ph := rng.randf_range(0.0, TAU)
	for x in range(TILE):
		var yy := int(round(float(y0) + amp * sin(TAU * kk * float(x) / float(TILE) + ph)))
		for t in range(1, 5):
			if yy + t < TILE: im.set_pixel(x, yy + t, Color(0.5, 0.32, 0.14, 0.07))
		if yy >= 0 and yy < TILE: im.set_pixel(x, yy, Color(0.04, 0.02, 0.0, 0.34))
		if yy + 1 < TILE: im.set_pixel(x, yy + 1, Color(1.0, 0.9, 0.7, 0.1))
	return im

## Độ tối dần theo độ sâu: gradient dọc từ độ sâu d tới d+1.
static func _make_depth(d: int) -> Image:
	var im := Image.create(TILE, TILE, false, Image.FORMAT_RGBA8)
	var a0 := clampf(float(d - 1) * 0.085, 0.0, 0.58)
	var a1 := clampf(float(d) * 0.085, 0.0, 0.58)
	for y in range(TILE):
		var a := lerpf(a0, a1, float(y) / float(TILE))
		var c := Color(0.05, 0.035, 0.08, a)
		for x in range(TILE): im.set_pixel(x, y, c)
	return im

static func _make_root(seed_i: int) -> Image:
	var rng := RandomNumberGenerator.new()
	rng.seed = 16000 + seed_i
	var im := Image.create(TILE, 48, false, Image.FORMAT_RGBA8)
	im.fill(Color(0, 0, 0, 0))
	var rc := Color(0.36, 0.24, 0.12)
	var x := rng.randi_range(6, 25)
	var y := 0
	var len := rng.randi_range(16, 40)
	var dx := 0
	for i in range(len):
		if x < 2 or x > TILE - 3 or y >= 48: break
		var fade := 1.0 - maxf(0.0, float(i) / float(len) - 0.6) * 2.0
		var c := rc.lerp(Color(0.2, 0.13, 0.07), float(i) / float(len))
		c.a = clampf(fade, 0.2, 1.0)
		im.set_pixel(x, y, c)
		if i < len * 3 / 5:
			im.set_pixel(x + 1, y, Color(0.04, 0.02, 0.0, 0.5 * c.a))
			im.set_pixel(x - 1, y, Color(0.6, 0.45, 0.25, 0.45 * c.a))
		y += 1
		if rng.randf() < 0.4: dx = rng.randi_range(-1, 1)
		x += dx
		if i == len / 2:
			var bx := x
			var by := y
			var bd := 1 if rng.randf() < 0.5 else -1
			for j in range(rng.randi_range(4, 8)):
				bx += bd if j % 2 == 0 else 0
				by += 1
				if bx < 1 or bx > TILE - 2 or by >= 48: break
				im.set_pixel(bx, by, Color(rc.r, rc.g, rc.b, 0.8 - float(j) * 0.08))
	return im

## Cỏ/rêu rủ xuống dưới lớp phủ mặt đất.
static func _make_drip(seed_i: int, pal: Dictionary) -> Image:
	var rng := RandomNumberGenerator.new()
	rng.seed = 17000 + seed_i
	var im := Image.create(TILE, 14, false, Image.FORMAT_RGBA8)
	im.fill(Color(0, 0, 0, 0))
	var cols: Array = [pal["light"], pal["mid"], pal["mid"], pal["dark"]]
	var x := 1
	while x < TILE - 1:
		var ln := rng.randi_range(2, 9)
		var c: Color = cols[rng.randi() % cols.size()]
		var px := x
		for y in range(ln):
			if y < 14:
				var cc := c.darkened(0.12 * float(y) / float(ln)) if y < ln - 1 else c.darkened(0.35)
				im.set_pixel(px, y, cc)
			if rng.randf() < 0.25: px = clampi(px + rng.randi_range(-1, 1), 0, TILE - 1)
		x += rng.randi_range(2, 4)
	return im

static func _make_lip() -> Image:
	var im := Image.create(TILE, 8, false, Image.FORMAT_RGBA8)
	for y in range(8):
		var k := 1.0 - float(y) / 8.0
		var c := Color(0.03, 0.02, 0.0, 0.4 * k * k)
		for x in range(TILE): im.set_pixel(x, y, c)
	return im

static func _make_bevel() -> Image:
	var im := Image.create(TILE, 4, false, Image.FORMAT_RGBA8)
	im.fill(Color(0, 0, 0, 0))
	for x in range(TILE):
		im.set_pixel(x, 0, Color(1.0, 0.95, 0.8, 0.34))
		im.set_pixel(x, 1, Color(1.0, 0.95, 0.8, 0.16))
		im.set_pixel(x, 3, Color(0.03, 0.02, 0.0, 0.18))
	return im

## Vách đứng: viền sáng + bóng tối phía trong + vụn đất sụt ra ngoài (dạng cho vách TRÁI, vách phải lật ngang). Rộng 12: 4 ngoài + 8 trong.
static func _make_wall(seed_i: int, earth: Color) -> Image:
	var rng := RandomNumberGenerator.new()
	rng.seed = 18000 + seed_i
	var im := Image.create(12, TILE, false, Image.FORMAT_RGBA8)
	im.fill(Color(0, 0, 0, 0))
	for y in range(TILE):
		for e in range(8):
			var a := 0.3 * (1.0 - float(e) / 8.0)
			im.set_pixel(4 + e, y, Color(0.04, 0.02, 0.0, a))
		im.set_pixel(5, y, Color(1.0, 0.9, 0.7, 0.16))
	var y := 0
	while y < TILE:
		if rng.randf() < 0.3:
			var w := rng.randi_range(1, 3)
			var h := rng.randi_range(2, 4)
			for yy in range(h):
				for xx in range(w):
					if y + yy >= TILE: continue
					var px := 3 - xx
					var c := earth.darkened(0.1 + 0.1 * float(yy) / float(h))
					if yy == 0: c = earth.lightened(0.12)
					im.set_pixel(px, y + yy, c)
			y += h + 1
		else:
			y += 1
	return im

## Mép dưới lởm chởm của khối đất hẫng (không có đất bên dưới).
static func _make_under(seed_i: int, earth: Color) -> Image:
	var rng := RandomNumberGenerator.new()
	rng.seed = 19000 + seed_i
	var im := Image.create(TILE, 8, false, Image.FORMAT_RGBA8)
	im.fill(Color(0, 0, 0, 0))
	var ln := 2
	for x in range(TILE):
		ln = clampi(ln + rng.randi_range(-1, 1), 1, 6)
		if x == 0 or x == TILE - 1: ln = 1
		for y in range(ln):
			im.set_pixel(x, y, earth.darkened(0.18 + 0.12 * float(y) / float(ln)))
		im.set_pixel(x, ln, Color(0.06, 0.04, 0.03, 0.85))
	return im

## Mặt bục gỗ/đá: mép sáng trên, mặt trước tối dưới, khe ván + đinh.
static func _make_plank_face(h: int, seed_i: int) -> Image:
	var im := Image.create(TILE, h, false, Image.FORMAT_RGBA8)
	im.fill(Color(0, 0, 0, 0))
	for x in range(TILE):
		im.set_pixel(x, 1, Color(1.0, 0.95, 0.8, 0.4))
		if h > 3: im.set_pixel(x, 2, Color(1.0, 0.95, 0.8, 0.14))
		for t in range(4):
			var yy := h - 4 + t
			if yy > 3: im.set_pixel(x, yy, Color(0.04, 0.02, 0.0, 0.1 + 0.1 * float(t)))
	var sx := 15 + (seed_i % 2)
	for y in range(3, h - 2):
		im.set_pixel(sx, y, Color(0.04, 0.02, 0.0, 0.4))
		im.set_pixel(sx + 1, y, Color(1.0, 0.95, 0.8, 0.12))
	if h > 6:
		im.set_pixel(5, h / 2, Color(0.04, 0.02, 0.0, 0.5))
		im.set_pixel(26, h / 2, Color(0.04, 0.02, 0.0, 0.5))
	return im

## Dán ảnh vào các mảnh 1024px tương ứng.
static func _blit(chunks: Array[Image], src: Image, x: int, y: int) -> void:
	if src == null: return
	var w := src.get_width()
	var i0 := maxi(0, int(floor(float(x) / CHUNK)))
	var i1 := mini(chunks.size() - 1, int(floor(float(x + w - 1) / CHUNK)))
	for i in range(i0, i1 + 1):
		var dst: Image = chunks[i]
		var dx := x - i * CHUNK
		# blend_rect cần vùng nguồn nằm trong ảnh; cắt phần ngoài chunk
		var sx := maxi(0, -dx)
		var ex := mini(w, dst.get_width() - dx)
		var sy := maxi(0, -y)
		var ey := mini(src.get_height(), dst.get_height() - y)
		if ex <= sx or ey <= sy: continue
		dst.blend_rect(src, Rect2i(sx, sy, ex - sx, ey - sy), Vector2i(dx + sx, y + sy))
