extends Node2D
## Dựng bản đồ như web: ô đất ĐẶC (mặt cỏ/đá, thân đất có vân, lõi sâu tối hơn) có viền + bo góc theo hàng xóm,
## bục gỗ, cỏ/hoa/sỏi rải trên mặt đất, nhà/đèn/cây/pha lê/nhũ đá, thác và hồ nước.
## Ô đất được "nướng" thành các ảnh 1024px một lần khi vào map (không vẽ từng ô mỗi khung hình).
## Hình ô đất / cảnh trí xuất từ web bằng tools/export_art.js; diện mạo từng map từ tools/export_looks.js.

const ART := "res://assets/art/"
const PROPS := "res://assets/props/"
const ROCK_SCALE := 0.6   # đá nền thu nhỏ còn 60% kích thước cũ
const TILE := 32
const CHUNK := 1024

var _grid: Array = []
var _rows := 0
var _cols := 0
var _theme := "city"
var _look: Dictionary = {}
var _tile_cache: Dictionary = {}     # key -> Image
var _edge_cache: Dictionary = {}     # "key~mask~R" -> Image
var _fx: _WaterFx = null

# ------------------------------------------------------------------ Ảnh
func _img(key: String) -> Image:
	if _tile_cache.has(key): return _tile_cache[key]
	var path := ART + key + ".png"
	var im: Image = null
	if ResourceLoader.exists(path):
		var tex := load(path) as Texture2D
		if tex: im = tex.get_image()
	if im != null:
		if im.is_compressed(): im.decompress()
		im.convert(Image.FORMAT_RGBA8)
	_tile_cache[key] = im
	return im

func _tex(key: String) -> Texture2D:
	var path := ART + key + ".png"
	return load(path) as Texture2D if ResourceLoader.exists(path) else null

func _meta_scale(key: String) -> float:
	var m: Dictionary = Data.art_meta.get(key, {})
	return float(m.get("scale", 1.0))

## Chỉnh màu ảnh (hue/sat/lum/mix) — dùng cho biến thể ô đất (tuyết, cát, đá tím...).
func _grade(src: Image, d: Dictionary) -> Image:
	var im := src.duplicate() as Image
	var hue := deg_to_rad(float(d.get("hue", 0.0)))
	var sat := float(d.get("sat", 1.0))
	var lum := float(d.get("lum", 1.0))
	var c := cos(hue); var s := sin(hue)
	var S := [0.213 + 0.787 * sat, 0.715 - 0.715 * sat, 0.072 - 0.072 * sat, 0.213 - 0.213 * sat, 0.715 + 0.285 * sat, 0.072 - 0.072 * sat, 0.213 - 0.213 * sat, 0.715 - 0.715 * sat, 0.072 + 0.928 * sat]
	var H := [0.213 + c * 0.787 - s * 0.213, 0.715 - c * 0.715 - s * 0.715, 0.072 - c * 0.072 + s * 0.928,
		0.213 - c * 0.213 + s * 0.143, 0.715 + c * 0.285 + s * 0.140, 0.072 - c * 0.072 - s * 0.283,
		0.213 - c * 0.213 - s * 0.787, 0.715 - c * 0.715 + s * 0.715, 0.072 + c * 0.928 + s * 0.072]
	var m := []
	m.resize(9)
	for r in range(3):
		for q in range(3):
			m[r * 3 + q] = H[r * 3] * S[q] + H[r * 3 + 1] * S[3 + q] + H[r * 3 + 2] * S[6 + q]
	var mix: Array = d.get("mix", [])
	var ma := float(mix[1]) if mix.size() == 2 else 0.0
	var mc := Color.from_rgba8((int(mix[0]) >> 16) & 255, (int(mix[0]) >> 8) & 255, int(mix[0]) & 255) if mix.size() == 2 else Color.BLACK
	for y in range(im.get_height()):
		for x in range(im.get_width()):
			var p := im.get_pixel(x, y)
			if p.a <= 0.0: continue
			var r2: float = (m[0] * p.r + m[1] * p.g + m[2] * p.b) * lum
			var g2: float = (m[3] * p.r + m[4] * p.g + m[5] * p.b) * lum
			var b2: float = (m[6] * p.r + m[7] * p.g + m[8] * p.b) * lum
			im.set_pixel(x, y, Color(clampf(r2 * (1.0 - ma) + mc.r * ma, 0, 1), clampf(g2 * (1.0 - ma) + mc.g * ma, 0, 1), clampf(b2 * (1.0 - ma) + mc.b * ma, 0, 1), p.a))
	return im

## Bộ ô đất của map: {top, fills[], deeps[], plank}.
func _tile_set() -> Dictionary:
	var decor: Dictionary = _look.get("decor", {})
	var v := str(decor.get("tile", ""))
	if v == "earth" and _img("tile_earth_top") != null:
		return {"top": _img("tile_earth_top"), "fills": [_img("tile_earth_fill0"), _img("tile_earth_fill1"), _img("tile_earth_fill2")],
			"deeps": [_img("tile_earth_deep0"), _img("tile_earth_deep1")], "plank": _img("plank_earth")}
	var variants: Dictionary = Data.looks.get("tile_variants", {})
	if variants.has(v):
		var def: Dictionary = variants[v]
		var from := str(def.get("from", _theme))
		var key := "var_" + v
		if not _tile_cache.has(key + "_top"):
			_tile_cache[key + "_top"] = _grade(_img("tile_%s_top" % from), def)
			_tile_cache[key + "_fill"] = _grade(_img("tile_%s_fill" % from), def)
			_tile_cache[key + "_plank"] = _grade(_img("plank_%s" % from), def)
		return {"top": _tile_cache[key + "_top"], "fills": [_tile_cache[key + "_fill"]], "deeps": [], "plank": _tile_cache[key + "_plank"]}
	var th := _theme if _img("tile_%s_top" % _theme) != null else "city"
	return {"top": _img("tile_%s_top" % th), "fills": [_img("tile_%s_fill" % th)], "deeps": [], "plank": _img("plank_%s" % th)}

## Ô có viền tối + bo góc theo mặt lộ ra ngoài (mask: 1 trên, 2 phải, 4 dưới, 8 trái).
func _edge(base: Image, key: String, mask: int, R: int, soft: bool = false) -> Image:
	if mask == 0 or base == null: return base
	var ck := "%s~%d~%d~%s" % [key, mask, R, str(soft)]
	if _edge_cache.has(ck): return _edge_cache[ck]
	var w := base.get_width(); var h := base.get_height()
	var im := base.duplicate() as Image
	var N := (mask & 1) != 0; var E := (mask & 2) != 0; var Sb := (mask & 4) != 0; var Wm := (mask & 8) != 0
	var cTL := N and Wm; var cTR := N and E; var cBR := Sb and E; var cBL := Sb and Wm
	var ol := 3.0 if not soft else 4.0
	var oc := Color(28.0 / 255.0, 18.0 / 255.0, 10.0 / 255.0, 0.85 if not soft else 0.6)
	for y in range(h):
		for x in range(w):
			var px := float(x) + 0.5; var py := float(y) + 0.5
			var p := im.get_pixel(x, y)
			# cắt góc
			var cut := false
			var cd := -1.0
			if cTL and px < R and py < R: cd = Vector2(px, py).distance_to(Vector2(R, R))
			elif cTR and px > w - R and py < R: cd = Vector2(px, py).distance_to(Vector2(w - R, R))
			elif cBR and px > w - R and py > h - R: cd = Vector2(px, py).distance_to(Vector2(w - R, h - R))
			elif cBL and px < R and py > h - R: cd = Vector2(px, py).distance_to(Vector2(R, h - R))
			if cd > R: cut = true
			if cut:
				im.set_pixel(x, y, Color(0, 0, 0, 0))
				continue
			# đổ bóng / sáng
			if Sb and not soft and py > h - 9.0: p = p.lerp(Color(10.0 / 255.0, 6.0 / 255.0, 2.0 / 255.0), 0.35 * (py - (h - 9.0)) / 9.0)
			if Wm and not soft and px > 2.0 and px < 4.0: p = p.lerp(Color.WHITE, 0.14)
			if Ee(E, soft) and px > w - 5.0 and px < w - 2.0: p = p.lerp(Color.BLACK, 0.22)
			# viền
			var on_ol := false
			if cd >= 0.0 and cd > R - ol: on_ol = true
			if N and py < ol and not (cTL and px < R) and not (cTR and px > w - R): on_ol = true
			if Sb and py > h - ol and not (cBL and px < R) and not (cBR and px > w - R): on_ol = true
			if Wm and px < ol and not (cTL and py < R) and not (cBL and py > h - R): on_ol = true
			if E and px > w - ol and not (cTR and py < R) and not (cBR and py > h - R): on_ol = true
			if on_ol: p = p.lerp(Color(oc.r, oc.g, oc.b), oc.a)
			im.set_pixel(x, y, p)
	_edge_cache[ck] = im
	return im

func Ee(e: bool, soft: bool) -> bool:
	return e and not soft

# ------------------------------------------------------------------ Dựng
func _cell(r: int, c: int) -> String:
	if r < 0 or r >= _rows or c < 0 or c >= _cols: return "#"
	return str((_grid[r] as Array)[c])

func _solid(r: int, c: int) -> bool:
	return _cell(r, c) == "#"

func _stand(r: int, c: int) -> bool:
	var ch := _cell(r, c)
	return ch == "#" or ch == "="

func _ground_y(r: int, c: int) -> float:
	for rr in range(r + 1, _rows):
		if _stand(rr, c): return float(rr * TILE)
	return float(_rows * TILE)

func build_grid(grid: Array, theme: String, tile_size: float, map_id: String = "") -> void:
	for ch in get_children(): ch.queue_free()
	_grid = grid
	_rows = grid.size()
	_cols = (grid[0] as Array).size() if _rows > 0 else 0
	_theme = theme if theme in ["city", "forest", "cave", "redgate"] else "city"
	_look = Data.look(map_id)
	_tile_cache = _tile_cache.duplicate()
	_edge_cache.clear()
	_bake_tiles()
	_build_decor()
	_build_water()

func _bake_tiles() -> void:
	var ts := _tile_set()
	var top: Image = ts["top"]
	var fills: Array = ts["fills"]
	var deeps: Array = ts["deeps"]
	var plank: Image = ts["plank"]
	if top == null: return
	var W := _cols * TILE
	var H := _rows * TILE
	var n_chunks := int(ceil(float(W) / float(CHUNK)))
	var tiles_img: Array[Image] = []
	var bits_img: Array[Image] = []
	for i in range(n_chunks):
		var cw := mini(CHUNK, W - i * CHUNK)
		var a := Image.create(cw, H, false, Image.FORMAT_RGBA8)
		a.fill(Color(0, 0, 0, 0))
		tiles_img.append(a)
		var b := Image.create(cw, H, false, Image.FORMAT_RGBA8)
		b.fill(Color(0, 0, 0, 0))
		bits_img.append(b)
	var tall := _rows > 20
	for r in range(_rows):
		for c in range(_cols):
			var ch := _cell(r, c)
			var src: Image = null
			var x := c * TILE
			var y := r * TILE
			if ch == "#":
				var is_top := not _solid(r - 1, c)
				var mask := (1 if is_top else 0) | (0 if _solid(r, c + 1) else 2) | (0 if _solid(r + 1, c) else 4) | (0 if _solid(r, c - 1) else 8)
				var base: Image = top if is_top else (fills[(c * 7 + r * 13) % fills.size()] as Image)
				var bkey := "top" if is_top else "fill%d" % ((c * 7 + r * 13) % fills.size())
				src = _edge(base, bkey, mask, 10)
				_blit(tiles_img, src, x, y)
				if tall and not deeps.is_empty() and _is_deep(r, c):
					var dm := (0 if _is_deep(r - 1, c) else 1) | (0 if _is_deep(r, c + 1) else 2) | (0 if _is_deep(r + 1, c) else 4) | (0 if _is_deep(r, c - 1) else 8)
					var di := (c * 5 + r * 3) % deeps.size()
					_blit(tiles_img, _edge(deeps[di] as Image, "deep%d" % di, dm, 12, true), x, y)
			elif ch == "=" and plank != null:
				var mask2 := 1 | 4 | (0 if _cell(r, c + 1) == "=" else 2) | (0 if _cell(r, c - 1) == "=" else 8)
				_blit(tiles_img, _edge(plank, "plank", mask2, 4), x, y)
	_decorate(tiles_img, _avg_color(fills[0] as Image) if not fills.is_empty() else Color(0.4, 0.28, 0.16), plank.get_height() if plank != null else 12)
	# cỏ / hoa / sỏi trên mặt đất
	var bits :={"city": ["d_rubble", "d_pebble", "d_pebble"], "forest": ["d_grass", "d_flower", "d_grass"], "cave": ["d_pebble", "d_rubble"], "redgate": ["d_pebble", "d_rubble"]}
	var list: Array = bits.get(_theme, bits["forest"])
	var decor: Dictionary = _look.get("decor", {})
	var bit_set := str(decor.get("bits", ""))
	var prop_sets: Dictionary = Data.looks.get("prop_sets", {})
	for r in range(_rows):
		for c in range(_cols):
			if not _solid(r, c) or _solid(r - 1, c): continue
			var h := (r * 71 + c * 137) % 100
			if h > 44: continue
			var gx := c * TILE + 4 + (h * 13) % 21
			var gy := r * TILE + 2
			if not bit_set.is_empty() and prop_sets.has(bit_set):
				continue   # bộ 'bits' ảnh được dựng bằng sprite ở _build_decor
			var bi := _img(str(list[h % list.size()]))
			if bi != null: _blit(bits_img, bi, gx - bi.get_width() / 2, gy - bi.get_height())
	for i in range(n_chunks):
		var spr := Sprite2D.new()
		spr.texture = ImageTexture.create_from_image(tiles_img[i])
		spr.centered = false
		spr.position = Vector2(i * CHUNK, 0)
		spr.z_index = -2
		spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		add_child(spr)
		var spb := Sprite2D.new()
		spb.texture = ImageTexture.create_from_image(bits_img[i])
		spb.centered = false
		spb.position = Vector2(i * CHUNK, 0)
		spb.z_index = -1
		spb.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		add_child(spb)

# ------------------------------------------------------------------ Hoàn thiện mặt đất (procedural, nướng 1 lần)
## Bảng màu lớp phủ mặt đất theo chủ đề map: light/mid/dark, cover = tỉ lệ ô được phủ, depth = độ dày (px).
func _cap_palette() -> Dictionary:
	var decor: Dictionary = _look.get("decor", {})
	var t := str(decor.get("tile", ""))
	var P := {
		"earth": [Color(0.58, 0.8, 0.3), Color(0.34, 0.6, 0.2), Color(0.16, 0.34, 0.14), 1.0, 6.0],
		"swamp": [Color(0.5, 0.65, 0.3), Color(0.3, 0.45, 0.2), Color(0.14, 0.26, 0.14), 0.9, 6.0],
		"wet": [Color(0.4, 0.7, 0.62), Color(0.22, 0.46, 0.46), Color(0.1, 0.26, 0.3), 0.75, 4.0],
		"teal": [Color(0.4, 0.75, 0.7), Color(0.2, 0.5, 0.5), Color(0.08, 0.28, 0.32), 0.7, 4.0],
		"snow": [Color(0.97, 0.99, 1.0), Color(0.82, 0.9, 0.97), Color(0.6, 0.72, 0.85), 0.95, 6.0],
		"sand": [Color(0.96, 0.85, 0.55), Color(0.85, 0.7, 0.4), Color(0.62, 0.48, 0.28), 0.8, 4.0],
		"redsand": [Color(0.85, 0.5, 0.3), Color(0.68, 0.36, 0.22), Color(0.4, 0.2, 0.14), 0.8, 4.0],
		"gold": [Color(1.0, 0.88, 0.45), Color(0.82, 0.62, 0.22), Color(0.5, 0.35, 0.12), 0.5, 3.0],
		"stone": [Color(0.7, 0.7, 0.66), Color(0.52, 0.52, 0.5), Color(0.32, 0.32, 0.34), 0.35, 3.0],
		"ash": [Color(0.5, 0.48, 0.48), Color(0.33, 0.31, 0.32), Color(0.18, 0.17, 0.18), 0.8, 4.0],
		"purple": [Color(0.62, 0.45, 0.8), Color(0.4, 0.28, 0.58), Color(0.2, 0.14, 0.34), 0.6, 4.0],
		"pink": [Color(0.95, 0.65, 0.78), Color(0.78, 0.45, 0.6), Color(0.45, 0.24, 0.36), 0.7, 4.0],
		"void": [Color(0.5, 0.4, 0.75), Color(0.3, 0.22, 0.5), Color(0.14, 0.1, 0.28), 0.6, 4.0],
		"voidg": [Color(0.4, 0.7, 0.55), Color(0.22, 0.45, 0.38), Color(0.1, 0.24, 0.22), 0.6, 4.0],
	}
	var by_theme := {"forest": "earth", "cave": "wet", "redgate": "ash", "city": "stone"}
	var k := t if P.has(t) else str(by_theme.get(_theme, "stone"))
	var a: Array = P[k]
	return {"light": a[0], "mid": a[1], "dark": a[2], "cover": a[3], "depth": a[4]}

func _hash2(a: int, b: int) -> int:
	var h := (a * 73856093) ^ (b * 19349663)
	h = (h ^ (h >> 13)) * 1274126177
	return absi(h ^ (h >> 16))

## Lớp phủ mặt đất (cỏ/rêu/tuyết/bụi): viền dưới gợn sóng, ngọn nhô lên; mép trái/phải trùng nhau giữa các biến thể.
func _make_cap(seed_i: int, pal: Dictionary) -> Image:
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
func _make_side(seed_i: int, left: bool, pal: Dictionary) -> Image:
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

func _make_blotch(seed_i: int, light_blob: bool) -> Image:
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

func _make_crack(seed_i: int) -> Image:
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

func _make_shadow(h: int, strength: float) -> Image:
	var im := Image.create(TILE, h, false, Image.FORMAT_RGBA8)
	for y in range(h):
		var k := 1.0 - float(y) / float(h)
		var c := Color(0.02, 0.01, 0.0, strength * k * k)
		for x in range(TILE): im.set_pixel(x, y, c)
	return im

func _avg_color(im: Image) -> Color:
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
func _stone_into(im: Image, cx: float, cy: float, rx: float, ry: float, sd: int, moss: bool, crack: bool, pal: Dictionary) -> void:
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

func _make_stone_tile(seed_i: int, pal: Dictionary) -> Image:
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
func _make_gravel(seed_i: int, pal: Dictionary) -> Image:
	var rng := RandomNumberGenerator.new()
	rng.seed = 12000 + seed_i
	var im := Image.create(TILE, TILE, false, Image.FORMAT_RGBA8)
	im.fill(Color(0, 0, 0, 0))
	for _i in range(rng.randi_range(4, 6)):
		_stone_into(im, rng.randf_range(3.0, 29.0), rng.randf_range(3.0, 29.0), rng.randf_range(1.5, 2.6), rng.randf_range(1.2, 2.0), rng.randi(), false, false, pal)
	return im

func _make_grain(seed_i: int) -> Image:
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
func _make_patch(seed_i: int, col: Color, amax: float) -> Image:
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
func _make_strata(seed_i: int) -> Image:
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
func _make_depth(d: int) -> Image:
	var im := Image.create(TILE, TILE, false, Image.FORMAT_RGBA8)
	var a0 := clampf(float(d - 1) * 0.085, 0.0, 0.58)
	var a1 := clampf(float(d) * 0.085, 0.0, 0.58)
	for y in range(TILE):
		var a := lerpf(a0, a1, float(y) / float(TILE))
		var c := Color(0.05, 0.035, 0.08, a)
		for x in range(TILE): im.set_pixel(x, y, c)
	return im

func _make_root(seed_i: int) -> Image:
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
func _make_drip(seed_i: int, pal: Dictionary) -> Image:
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

func _make_lip() -> Image:
	var im := Image.create(TILE, 8, false, Image.FORMAT_RGBA8)
	for y in range(8):
		var k := 1.0 - float(y) / 8.0
		var c := Color(0.03, 0.02, 0.0, 0.4 * k * k)
		for x in range(TILE): im.set_pixel(x, y, c)
	return im

func _make_bevel() -> Image:
	var im := Image.create(TILE, 4, false, Image.FORMAT_RGBA8)
	im.fill(Color(0, 0, 0, 0))
	for x in range(TILE):
		im.set_pixel(x, 0, Color(1.0, 0.95, 0.8, 0.34))
		im.set_pixel(x, 1, Color(1.0, 0.95, 0.8, 0.16))
		im.set_pixel(x, 3, Color(0.03, 0.02, 0.0, 0.18))
	return im

## Vách đứng: viền sáng + bóng tối phía trong + vụn đất sụt ra ngoài (dạng cho vách TRÁI, vách phải lật ngang). Rộng 12: 4 ngoài + 8 trong.
func _make_wall(seed_i: int, earth: Color) -> Image:
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
func _make_under(seed_i: int, earth: Color) -> Image:
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
func _make_plank_face(h: int, seed_i: int) -> Image:
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

## Số ô đất liên tiếp phía trên (độ sâu tính từ mặt đất).
func _depth_of(r: int, c: int) -> int:
	var d := 0
	while d < 12 and _solid(r - 1 - d, c): d += 1
	return d

## Thêm chi tiết lên ảnh ô đất (nướng 1 lần khi vào map, chỉ blend các ảnh nhỏ dựng sẵn):
## tông loang, hạt/sỏi/đá, địa tầng, rễ cây, tối dần theo độ sâu, lớp phủ + cỏ rủ, vách sụt lở, mép hẫng, bục có mặt bậc.
func _decorate(chunks: Array[Image], earth: Color = Color(0.4, 0.28, 0.16), plank_h: int = 12) -> void:
	var pal := _cap_palette()
	var caps: Array[Image] = []
	var sides_l: Array[Image] = []
	var sides_r: Array[Image] = []
	var dark_b: Array[Image] = []
	var light_b: Array[Image] = []
	var cracks: Array[Image] = []
	var warm: Array[Image] = []
	var cool: Array[Image] = []
	var grains: Array[Image] = []
	var gravels: Array[Image] = []
	var stones: Array[Image] = []
	var stratas: Array[Image] = []
	var depths: Array[Image] = []
	var roots: Array[Image] = []
	var drips: Array[Image] = []
	var walls_l: Array[Image] = []
	var walls_r: Array[Image] = []
	var unders: Array[Image] = []
	var plank_faces: Array[Image] = []
	for i in range(6): caps.append(_make_cap(i, pal))
	for i in range(3):
		sides_l.append(_make_side(i, true, pal))
		sides_r.append(_make_side(i, false, pal))
	for i in range(5):
		dark_b.append(_make_blotch(i, false))
		light_b.append(_make_blotch(i, true))
	for i in range(4): cracks.append(_make_crack(i))
	for i in range(4):
		warm.append(_make_patch(i, earth.lightened(0.25).lerp(Color(0.85, 0.55, 0.25), 0.4), 0.2))
		cool.append(_make_patch(i + 10, Color(0.1, 0.07, 0.13), 0.26))
		grains.append(_make_grain(i))
	for i in range(5): gravels.append(_make_gravel(i, pal))
	for i in range(5): stones.append(_make_stone_tile(i, pal))
	for i in range(6): stratas.append(_make_strata(i))
	for i in range(13): depths.append(_make_depth(i))
	for i in range(5): roots.append(_make_root(i))
	for i in range(4): drips.append(_make_drip(i, pal))
	for i in range(3):
		var wl := _make_wall(i, earth)
		var wr := wl.duplicate() as Image
		wr.flip_x()
		walls_l.append(wl)
		walls_r.append(wr)
		unders.append(_make_under(i, earth))
	for i in range(2): plank_faces.append(_make_plank_face(plank_h, i))
	var sh_solid := _make_shadow(14, 0.5)
	var lip := _make_lip()
	var bevel := _make_bevel()
	var cover: float = float(pal["cover"])
	for r in range(_rows):
		for c in range(_cols):
			var ch := _cell(r, c)
			var x := c * TILE
			var y := r * TILE
			var h := _hash2(c, r)
			if ch == "#":
				var is_top := not _solid(r - 1, c)
				var d := 0 if is_top else _depth_near(r, c)
				# tông màu loang + hạt
				if (h >> 1) % 3 == 0: _blit(chunks, warm[(h >> 3) % warm.size()], x, y)
				if (h >> 2) % 3 == 0: _blit(chunks, cool[(h >> 5) % cool.size()], x, y)
				if h % 3 == 0: _blit(chunks, dark_b[(h >> 3) % dark_b.size()], x, y)
				if (h >> 5) % 4 == 0: _blit(chunks, light_b[(h >> 7) % light_b.size()], x, y)
				_blit(chunks, grains[(h >> 6) % grains.size()], x, y)
				# địa tầng ngang: cùng hàng dùng cùng kiểu để vạch nối liền
				if not is_top and d >= 1 and _hash2(r, 77) % 5 < 3:
					_blit(chunks, stratas[_hash2(r, 31) % stratas.size()], x, y)
				# sỏi + đá nhỏ có khối
				if not is_top and (h >> 8) % 100 < 26: _blit(chunks, gravels[(h >> 12) % gravels.size()], x, y)
				if not is_top and d >= 1 and (h >> 10) % 100 < 11: _blit(chunks, stones[(h >> 14) % stones.size()], x, y)
				if not is_top and (h >> 9) % 9 == 0: _blit(chunks, cracks[(h >> 11) % cracks.size()], x, y)
				# rễ cây thò từ dưới lớp cỏ
				if is_top and (h >> 12) % 100 < 28:
					_blit(chunks, roots[(h >> 14) % roots.size()], x, y + 8)
				# tối dần theo độ sâu (hoà vào nền ở đáy)
				if d >= 1: _blit(chunks, depths[mini(d, 12)], x, y)
				if is_top:
					_blit(chunks, bevel, x, y)
				# vách đứng sụt lở
				if not _solid(r, c - 1): _blit(chunks, walls_l[(h >> 4) % walls_l.size()], x - 4, y)
				if not _solid(r, c + 1): _blit(chunks, walls_r[(h >> 6) % walls_r.size()], x + TILE - 8, y)
				if is_top and float((h >> 4) % 100) / 100.0 < cover:
					_blit(chunks, lip, x, y + 6)
					_blit(chunks, caps[(h >> 2) % caps.size()], x, y - 8)
					if (h >> 7) % 100 < 70: _blit(chunks, drips[(h >> 9) % drips.size()], x, y + 5)
					if not _solid(r, c - 1): _blit(chunks, sides_l[h % sides_l.size()], x, y + 4)
					if not _solid(r, c + 1): _blit(chunks, sides_r[h % sides_r.size()], x + TILE - 6, y + 4)
				if not _stand(r + 1, c):
					_blit(chunks, unders[(h >> 3) % unders.size()], x, y + TILE - 1)
					_blit(chunks, sh_solid, x, y + TILE)
			elif ch == "=":
				if h % 4 == 0: _blit(chunks, dark_b[(h >> 3) % dark_b.size()], x, y)
				_blit(chunks, plank_faces[(h >> 2) % plank_faces.size()], x, y)
				# Bậc gỗ lơ lửng không đổ bóng xuống bên dưới (nhìn vô lý).

func _is_deep(r: int, c: int) -> bool:
	for dr in range(-2, 3):
		for dc in range(-2, 3):
			if _cell(r + dr, c + dc) != "#": return false
	return true

## Dán ảnh vào các mảnh 1024px tương ứng.
func _blit(chunks: Array[Image], src: Image, x: int, y: int) -> void:
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

# ------------------------------------------------------------------ Cảnh trí
func _tint() -> Color:
	var decor: Dictionary = _look.get("decor", {})
	if decor.has("tint"):
		var t := int(decor["tint"])
		return Color.from_rgba8((t >> 16) & 255, (t >> 8) & 255, t & 255)
	return Color.WHITE

func _art_sprite(key: String, x: float, y: float, origin_y: float, z: int, tint: Color) -> Sprite2D:
	var tex := _tex(key)
	if tex == null: return null
	var sc := 1.0 / _meta_scale(key)
	var spr := Sprite2D.new()
	spr.texture = tex
	spr.centered = false
	spr.scale = Vector2(sc, sc)
	spr.position = Vector2(x - float(tex.get_width()) * sc * 0.5, y - float(tex.get_height()) * sc * origin_y)
	spr.z_index = z
	spr.modulate = tint
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(spr)
	return spr

func _prop_sprite(set_name: String, c: int, x: float, y: float, origin_y: float, z: int, tint: Color) -> bool:
	var sets: Dictionary = Data.looks.get("prop_sets", {})
	if not sets.has(set_name): return false
	var n := int((sets[set_name] as Dictionary).get("n", 1))
	var path := "%s%s/%d.png" % [PROPS, set_name, 1 + ((c * 7 + int(origin_y) * 3) % n)]
	if not ResourceLoader.exists(path): return false
	var tex := load(path) as Texture2D
	var sc := (ROCK_SCALE if set_name == "rock" else 1.0) * 0.5 * (0.85 + float((c * 13) % 30) / 100.0)
	var spr := Sprite2D.new()
	spr.texture = tex
	spr.centered = false
	spr.scale = Vector2(sc, sc)
	spr.position = Vector2(x - float(tex.get_width()) * sc * 0.5, y - float(tex.get_height()) * sc * origin_y)
	spr.z_index = z
	spr.modulate = tint
	add_child(spr)
	return true

func _build_decor() -> void:
	var D: Dictionary = _look.get("decor", {})
	var tint := _tint()
	var prop_sets: Dictionary = Data.looks.get("prop_sets", {})
	for r in range(_rows):
		for c in range(_cols):
			var ch := _cell(r, c)
			if not (ch in ["$", "!", "&", "^"]): continue
			var x := float(c * TILE + TILE / 2)
			var gy := _ground_y(r, c)
			if ch == "$":
				_art_sprite("d_shop_%d" % (c % 3), x, gy, 1.0, -5, Color.WHITE)
			elif ch == "!":
				var key := "d_lamp" if _theme == "city" else ("d_redcrystal" if _theme == "redgate" else "d_crystal")
				if _tex(key) == null: key = "d_crystal"
				var s := _art_sprite(key, x, gy, 1.0, -4, tint if _theme != "city" else Color.WHITE)
				if s and _theme == "redgate" and key == "d_crystal": s.modulate = Color(1.0, 0.55, 0.6)
			elif ch == "&":
				if str(D.get("tree", "")) == "none": continue
				var tset := str(D.get("tree", ""))
				if not tset.is_empty() and prop_sets.has(tset) and _prop_sprite(tset, c, x, gy, 1.0, -6, tint): continue
				var v := (c * 7) % 3
				var key2 := "d_tree"
				match _theme:
					"forest": key2 = "d_dtree" if v == 1 else "d_shroom"
					"cave": key2 = "d_crystal"
					"redgate": key2 = "d_redcrystal"
				if _tex(key2) == null: key2 = "d_crystal"
				var s2 := _art_sprite(key2, x, gy, 1.0, -6, tint)
				if s2 and _theme == "redgate" and key2 == "d_crystal": s2.modulate = Color(1.0, 0.55, 0.6)
			elif ch == "^":
				if _solid(r - 1, c):
					if str(D.get("ceil", "")) == "none": continue
					var cset := str(D.get("ceil", ""))
					if not cset.is_empty() and prop_sets.has(cset) and _prop_sprite(cset, c, x, float(r * TILE), 0.0, -4, tint): continue
					var st := _art_sprite("d_stalactite", x, float(r * TILE), 0.0, -4, Color(1.0, 0.54, 0.59) if _theme == "redgate" else tint)
					if st == null: pass
				else:
					if str(D.get("floor", "")) == "none": continue
					var fset := str(D.get("floor", ""))
					if not fset.is_empty() and prop_sets.has(fset) and _prop_sprite(fset, c, x, gy, 1.0, -4, tint): continue
					var cr := _art_sprite("d_crystal", x, gy, 1.0, -4, tint)
					if cr and _theme == "redgate": cr.modulate = Color(1.0, 0.55, 0.6)
	# bộ 'bits' ảnh của map (đá nhỏ...) thay cho cỏ/sỏi vẽ code
	var bit_set := str(D.get("bits", ""))
	if not bit_set.is_empty() and prop_sets.has(bit_set):
		var n := int((prop_sets[bit_set] as Dictionary).get("n", 1))
		for r in range(_rows):
			for c in range(_cols):
				if not _solid(r, c) or _solid(r - 1, c): continue
				var h := (r * 71 + c * 137) % 100
				if h > 44: continue
				var path := "%s%s/%d.png" % [PROPS, bit_set, 1 + (h % n)]
				if not ResourceLoader.exists(path): continue
				var tex := load(path) as Texture2D
				var sc := ROCK_SCALE * 0.5 * (0.8 + float(h % 5) / 10.0)
				var spr := Sprite2D.new()
				spr.texture = tex
				spr.centered = false
				spr.scale = Vector2(sc, sc)
				spr.position = Vector2(float(c * TILE + 4 + (h * 13) % 21) - float(tex.get_width()) * sc * 0.5, float(r * TILE + 2) - float(tex.get_height()) * sc)
				spr.z_index = -1
				spr.modulate = tint
				add_child(spr)

# ------------------------------------------------------------------ Nước
func _build_water() -> void:
	var fall_tex := _tex("fx_fall")
	var pool_tex := _tex("fx_water")
	_fx = _WaterFx.new()
	_fx.fall_tex = fall_tex
	_fx.pool_tex = pool_tex
	var isf := func(r: int, c: int) -> bool:
		var ch := _cell(r, c)
		return ch == "%" or (ch == "=" and _cell(r - 1, c) == "%" and _cell(r + 1, c) == "%")
	for c in range(_cols):
		var r := 0
		while r < _rows:
			if not isf.call(r, c):
				r += 1
				continue
			var e := r
			while e + 1 < _rows and isf.call(e + 1, c): e += 1
			var land := e + 1
			while land < _rows and not (_cell(land, c) in ["#", "=", "\""]): land += 1
			var bottom := land * TILE if land < _rows else (e + 1) * TILE
			_fx.falls.append(Rect2(c * TILE, r * TILE, TILE, bottom - r * TILE))
			r = e + 1
	for r in range(_rows):
		var c := 0
		while c < _cols:
			if _cell(r, c) != "\"":
				c += 1
				continue
			var e2 := c
			while e2 + 1 < _cols and _cell(r, e2 + 1) == "\"": e2 += 1
			_fx.pools.append([Rect2(c * TILE, r * TILE, (e2 - c + 1) * TILE, TILE), 0.4 if _cell(r - 1, c) == "\"" else 0.6])
			c = e2 + 1
	if not _fx.falls.is_empty() or not _fx.pools.is_empty():
		_fx.z_index = -1   # sau nhân vật/quái (trước đây z=4 che mất người đứng trước thác)
		add_child(_fx)

class _WaterFx extends Node2D:
	var fall_tex: Texture2D
	var pool_tex: Texture2D
	var falls: Array = []
	var pools: Array = []
	var _t := 0.0
	var _redraw_acc := 0.0
	func _process(d: float) -> void:
		_t += d
		_redraw_acc += d
		if _redraw_acc >= 1.0 / 30.0:
			_redraw_acc = 0.0
			queue_redraw()
	func _draw() -> void:
		# Chỉ vẽ phần nằm trong khung nhìn camera (map rộng có rất nhiều thác/hồ ngoài màn hình).
		var vis := get_canvas_transform().affine_inverse() * get_viewport_rect()
		vis = vis.grow(64.0)
		if fall_tex != null:
			var th := float(fall_tex.get_height())
			for rc in falls:
				var rect: Rect2 = rc
				if not rect.intersects(vis): continue
				# cuộn dọc: vẽ lặp theo chiều cao ảnh
				var off := fmod(_t * 60.0, th)
				var y := rect.position.y - off
				while y < rect.end.y:
					var y0 := maxf(y, rect.position.y)
					var y1 := minf(y + th, rect.end.y)
					if y1 > y0:
						var src_y := y0 - y
						draw_texture_rect_region(fall_tex, Rect2(rect.position.x, y0, rect.size.x, y1 - y0), Rect2(0, src_y, fall_tex.get_width(), y1 - y0), Color(1, 1, 1, 0.88))
					y += th
		if pool_tex != null:
			var tw := float(pool_tex.get_width())
			for p in pools:
				var rect2: Rect2 = p[0]
				if not rect2.intersects(vis): continue
				var off2 := fmod(_t * 15.0, tw)
				var x := rect2.position.x - off2
				while x < rect2.end.x:
					var x0 := maxf(x, rect2.position.x)
					var x1 := minf(x + tw, rect2.end.x)
					if x1 > x0:
						draw_texture_rect_region(pool_tex, Rect2(x0, rect2.position.y, x1 - x0, rect2.size.y), Rect2(x0 - x, 0, x1 - x0, pool_tex.get_height()), Color(1, 1, 1, float(p[1])))
					x += tw

## Độ sâu làm mượt theo 5 cột lân cận (tránh vệt tối gãy ở chân cột đất cao); cột không phải đất dùng độ sâu của chính ô.
func _depth_near(r: int, c: int) -> int:
	var own := _depth_of(r, c)
	var sum := 0
	for dc in range(-2, 3):
		sum += _depth_of(r, c + dc) if _solid(r, c + dc) else own
	return int(round(float(sum) / 5.0))
