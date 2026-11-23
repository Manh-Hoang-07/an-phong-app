extends Node2D
## Dựng bản đồ như web: ô đất ĐẶC (mặt cỏ/đá, thân đất có vân, lõi sâu tối hơn) có viền + bo góc theo hàng xóm,
## bục gỗ, cỏ/hoa/sỏi rải trên mặt đất, nhà/đèn/cây/pha lê/nhũ đá, thác và hồ nước.
## Ô đất được "nướng" thành các ảnh 1024px một lần khi vào map (không vẽ từng ô mỗi khung hình).
## Hình ô đất / cảnh trí xuất từ web bằng tools/export_art.js; diện mạo từng map từ tools/export_looks.js.

const ART := "res://assets/art/"
const PROPS := "res://assets/props/"
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
	# cỏ / hoa / sỏi trên mặt đất
	var bits := {"city": ["d_rubble", "d_pebble", "d_pebble"], "forest": ["d_grass", "d_flower", "d_grass"], "cave": ["d_pebble", "d_rubble"], "redgate": ["d_pebble", "d_rubble"]}
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
		if ex <= sx: continue
		dst.blend_rect(src, Rect2i(sx, 0, ex - sx, src.get_height()), Vector2i(dx + sx, y))

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
	var sc := 0.5 * (0.85 + float((c * 13) % 30) / 100.0)
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
				var sc := 0.5 * (0.8 + float(h % 5) / 10.0)
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
		_fx.z_index = 4
		add_child(_fx)

class _WaterFx extends Node2D:
	var fall_tex: Texture2D
	var pool_tex: Texture2D
	var falls: Array = []
	var pools: Array = []
	var _t := 0.0
	func _process(d: float) -> void:
		_t += d
		queue_redraw()
	func _draw() -> void:
		if fall_tex != null:
			var th := float(fall_tex.get_height())
			for rc in falls:
				var rect: Rect2 = rc
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
				var off2 := fmod(_t * 15.0, tw)
				var x := rect2.position.x - off2
				while x < rect2.end.x:
					var x0 := maxf(x, rect2.position.x)
					var x1 := minf(x + tw, rect2.end.x)
					if x1 > x0:
						draw_texture_rect_region(pool_tex, Rect2(x0, rect2.position.y, x1 - x0, rect2.size.y), Rect2(x0 - x, 0, x1 - x0, pool_tex.get_height()), Color(1, 1, 1, float(p[1])))
					x += tw
