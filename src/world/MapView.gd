extends Node2D
## Dựng bản đồ như web: ô đất ĐẶC (mặt cỏ/đá, thân đất có vân, lõi sâu tối hơn) có viền + bo góc theo hàng xóm,
## bục gỗ, cỏ/hoa/sỏi rải trên mặt đất, nhà/đèn/cây/pha lê/nhũ đá, thác và hồ nước.
## Ô đất được "nướng" thành các ảnh 1024px một lần khi vào map (không vẽ từng ô mỗi khung hình).
## Hình ô đất / cảnh trí xuất từ web bằng tools/export/export_art.js; diện mạo từng map từ tools/export/export_looks.js.

const ART := "res://assets/art/"
const PROPS := "res://assets/props/"
const ROCK_SCALE := 0.6   # đá nền thu nhỏ còn 60% kích thước cũ
const TILE := 32
const CHUNK := 1024
const MapTileArt := preload("res://src/world/MapTileArt.gd")

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
	_map_id = map_id
	_tile_cache = _tile_cache.duplicate()
	_edge_cache.clear()
	_bake_tiles()
	_build_decor()
	_build_water()

const CACHE_DIR := "res://assets/mapcache/"
## Tăng số này khi đổi ảnh ô mẫu (assets/art), MapTileArt.gd hoặc thuật toán dựng nền: ảnh bake cũ sẽ bị bỏ qua
## (game tự dựng lại như trước) cho tới khi chạy lại tools/export/bake_maps.ps1.
const CACHE_VER := 1

var _map_id := ""

func _cache_key() -> String:
	var rows := PackedStringArray()
	for r in _grid: rows.append("".join(PackedStringArray(r)))
	var sig := "%d|%s|%s|%s" % [CACHE_VER, _theme, JSON.stringify(_look), "\n".join(rows)]
	return "%08x" % (sig.hash() & 0xffffffff)

func _cache_path(kind: String, i: int, key: String) -> String:
	return CACHE_DIR + "%s_%s_%s%d.png" % [_map_id, key, kind, i]

func _chunk_count() -> int:
	return int(ceil(float(_cols * TILE) / float(CHUNK)))

## Nền đất: ưu tiên ảnh đã bake sẵn trong assets/mapcache (chỉ nạp PNG, gần như tức thì);
## không có (hoặc map/theme/look/CACHE_VER đã đổi nên khoá không khớp) thì dựng bằng CPU như cũ.
func _bake_tiles() -> void:
	var n_chunks := _chunk_count()
	var t_tex: Array[Texture2D] = []
	var b_tex: Array[Texture2D] = []
	if _map_id != "" and n_chunks > 0:
		var key := _cache_key()
		for i in range(n_chunks):
			var tp := _cache_path("t", i, key)
			var tt: Texture2D = load(tp) as Texture2D if ResourceLoader.exists(tp) else null
			if tt == null:
				t_tex.clear()
				b_tex.clear()
				break
			t_tex.append(tt)
			var bp := _cache_path("b", i, key)
			b_tex.append(load(bp) as Texture2D if ResourceLoader.exists(bp) else null)
	if t_tex.size() != n_chunks or n_chunks == 0:
		t_tex.clear()
		b_tex.clear()
		var d := _compose()
		if d.is_empty(): return
		var tiles_img: Array = d["tiles"]
		var bits_img: Array = d["bits"]
		for i in range(tiles_img.size()):
			t_tex.append(ImageTexture.create_from_image(tiles_img[i]))
			b_tex.append(ImageTexture.create_from_image(bits_img[i]))
	for i in range(t_tex.size()):
		var spr := Sprite2D.new()
		spr.texture = t_tex[i]
		spr.centered = false
		spr.position = Vector2(i * CHUNK, 0)
		spr.z_index = -2
		spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		add_child(spr)
		if b_tex[i] != null:
			var spb := Sprite2D.new()
			spb.texture = b_tex[i]
			spb.centered = false
			spb.position = Vector2(i * CHUNK, 0)
			spb.z_index = -1
			spb.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			add_child(spb)

## Dành cho tool bake (tools/export/bake_maps.gd): dựng ảnh nền map rồi ghi PNG vào CACHE_DIR, xoá bản bake cũ của map này.
## Trả số file PNG đã ghi (0 nếu không dựng được).
func export_bake(grid: Array, theme: String, map_id: String) -> int:
	_grid = grid
	_rows = grid.size()
	_cols = (grid[0] as Array).size() if _rows > 0 else 0
	_theme = theme if theme in ["city", "forest", "cave", "redgate"] else "city"
	_look = Data.look(map_id)
	_map_id = map_id
	_edge_cache.clear()
	var d := _compose()
	if d.is_empty(): return 0
	var abs_dir := ProjectSettings.globalize_path(CACHE_DIR)
	DirAccess.make_dir_recursive_absolute(abs_dir)
	var rx := RegEx.new()
	rx.compile("^[0-9a-f]{8}_[tb][0-9]+[.]png([.]import)?$")   # phần đuôi sau "<map_id>_"
	var da := DirAccess.open(abs_dir)
	for fn in da.get_files():
		if fn.begins_with(map_id + "_") and rx.search(fn.substr(map_id.length() + 1)) != null: da.remove(fn)
	var key := _cache_key()
	var n := 0
	var tiles_img: Array = d["tiles"]
	var bits_img: Array = d["bits"]
	for i in range(tiles_img.size()):
		if (tiles_img[i] as Image).save_png(ProjectSettings.globalize_path(_cache_path("t", i, key))) == OK: n += 1
		if not (bits_img[i] as Image).is_invisible():
			if (bits_img[i] as Image).save_png(ProjectSettings.globalize_path(_cache_path("b", i, key))) == OK: n += 1
	return n

## Dựng ảnh nền bằng CPU: {tiles: Array[Image], bits: Array[Image]} mỗi phần tử một mảnh CHUNK px (rỗng nếu thiếu ảnh ô mẫu).
func _compose() -> Dictionary:
	var ts := _tile_set()
	var top: Image = ts["top"]
	var fills: Array = ts["fills"]
	var deeps: Array = ts["deeps"]
	var plank: Image = ts["plank"]
	if top == null: return {}
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
				MapTileArt._blit(tiles_img, src, x, y)
				if tall and not deeps.is_empty() and _is_deep(r, c):
					var dm := (0 if _is_deep(r - 1, c) else 1) | (0 if _is_deep(r, c + 1) else 2) | (0 if _is_deep(r + 1, c) else 4) | (0 if _is_deep(r, c - 1) else 8)
					var di := (c * 5 + r * 3) % deeps.size()
					MapTileArt._blit(tiles_img, _edge(deeps[di] as Image, "deep%d" % di, dm, 12, true), x, y)
			elif ch == "=" and plank != null:
				var mask2 := 1 | 4 | (0 if _cell(r, c + 1) == "=" else 2) | (0 if _cell(r, c - 1) == "=" else 8)
				MapTileArt._blit(tiles_img, _edge(plank, "plank", mask2, 4), x, y)
	_decorate(tiles_img, MapTileArt._avg_color(fills[0] as Image) if not fills.is_empty() else Color(0.4, 0.28, 0.16), plank.get_height() if plank != null else 12)
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
			if bi != null: MapTileArt._blit(bits_img, bi, gx - bi.get_width() / 2, gy - bi.get_height())
	return {"tiles": tiles_img, "bits": bits_img}

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
	for i in range(6): caps.append(MapTileArt._make_cap(i, pal))
	for i in range(3):
		sides_l.append(MapTileArt._make_side(i, true, pal))
		sides_r.append(MapTileArt._make_side(i, false, pal))
	for i in range(5):
		dark_b.append(MapTileArt._make_blotch(i, false))
		light_b.append(MapTileArt._make_blotch(i, true))
	for i in range(4): cracks.append(MapTileArt._make_crack(i))
	for i in range(4):
		warm.append(MapTileArt._make_patch(i, earth.lightened(0.25).lerp(Color(0.85, 0.55, 0.25), 0.4), 0.2))
		cool.append(MapTileArt._make_patch(i + 10, Color(0.1, 0.07, 0.13), 0.26))
		grains.append(MapTileArt._make_grain(i))
	for i in range(5): gravels.append(MapTileArt._make_gravel(i, pal))
	for i in range(5): stones.append(MapTileArt._make_stone_tile(i, pal))
	for i in range(6): stratas.append(MapTileArt._make_strata(i))
	for i in range(13): depths.append(MapTileArt._make_depth(i))
	for i in range(5): roots.append(MapTileArt._make_root(i))
	for i in range(4): drips.append(MapTileArt._make_drip(i, pal))
	for i in range(3):
		var wl := MapTileArt._make_wall(i, earth)
		var wr := wl.duplicate() as Image
		wr.flip_x()
		walls_l.append(wl)
		walls_r.append(wr)
		unders.append(MapTileArt._make_under(i, earth))
	for i in range(2): plank_faces.append(MapTileArt._make_plank_face(plank_h, i))
	var sh_solid := MapTileArt._make_shadow(14, 0.5)
	var lip := MapTileArt._make_lip()
	var bevel := MapTileArt._make_bevel()
	var cover: float = float(pal["cover"])
	for r in range(_rows):
		for c in range(_cols):
			var ch := _cell(r, c)
			var x := c * TILE
			var y := r * TILE
			var h := MapTileArt._hash2(c, r)
			if ch == "#":
				var is_top := not _solid(r - 1, c)
				var d := 0 if is_top else _depth_near(r, c)
				# tông màu loang + hạt
				if (h >> 1) % 3 == 0: MapTileArt._blit(chunks, warm[(h >> 3) % warm.size()], x, y)
				if (h >> 2) % 3 == 0: MapTileArt._blit(chunks, cool[(h >> 5) % cool.size()], x, y)
				if h % 3 == 0: MapTileArt._blit(chunks, dark_b[(h >> 3) % dark_b.size()], x, y)
				if (h >> 5) % 4 == 0: MapTileArt._blit(chunks, light_b[(h >> 7) % light_b.size()], x, y)
				MapTileArt._blit(chunks, grains[(h >> 6) % grains.size()], x, y)
				# địa tầng ngang: cùng hàng dùng cùng kiểu để vạch nối liền
				if not is_top and d >= 1 and MapTileArt._hash2(r, 77) % 5 < 3:
					MapTileArt._blit(chunks, stratas[MapTileArt._hash2(r, 31) % stratas.size()], x, y)
				# sỏi + đá nhỏ có khối
				if not is_top and (h >> 8) % 100 < 26: MapTileArt._blit(chunks, gravels[(h >> 12) % gravels.size()], x, y)
				if not is_top and d >= 1 and (h >> 10) % 100 < 11: MapTileArt._blit(chunks, stones[(h >> 14) % stones.size()], x, y)
				if not is_top and (h >> 9) % 9 == 0: MapTileArt._blit(chunks, cracks[(h >> 11) % cracks.size()], x, y)
				# rễ cây thò từ dưới lớp cỏ
				if is_top and (h >> 12) % 100 < 28:
					MapTileArt._blit(chunks, roots[(h >> 14) % roots.size()], x, y + 8)
				# tối dần theo độ sâu (hoà vào nền ở đáy)
				if d >= 1: MapTileArt._blit(chunks, depths[mini(d, 12)], x, y)
				if is_top:
					MapTileArt._blit(chunks, bevel, x, y)
				# vách đứng sụt lở
				if not _solid(r, c - 1): MapTileArt._blit(chunks, walls_l[(h >> 4) % walls_l.size()], x - 4, y)
				if not _solid(r, c + 1): MapTileArt._blit(chunks, walls_r[(h >> 6) % walls_r.size()], x + TILE - 8, y)
				if is_top and float((h >> 4) % 100) / 100.0 < cover:
					MapTileArt._blit(chunks, lip, x, y + 6)
					MapTileArt._blit(chunks, caps[(h >> 2) % caps.size()], x, y - 8)
					if (h >> 7) % 100 < 70: MapTileArt._blit(chunks, drips[(h >> 9) % drips.size()], x, y + 5)
					if not _solid(r, c - 1): MapTileArt._blit(chunks, sides_l[h % sides_l.size()], x, y + 4)
					if not _solid(r, c + 1): MapTileArt._blit(chunks, sides_r[h % sides_r.size()], x + TILE - 6, y + 4)
				if not _stand(r + 1, c):
					MapTileArt._blit(chunks, unders[(h >> 3) % unders.size()], x, y + TILE - 1)
					MapTileArt._blit(chunks, sh_solid, x, y + TILE)
			elif ch == "=":
				if h % 4 == 0: MapTileArt._blit(chunks, dark_b[(h >> 3) % dark_b.size()], x, y)
				MapTileArt._blit(chunks, plank_faces[(h >> 2) % plank_faces.size()], x, y)
				# Bậc gỗ lơ lửng không đổ bóng xuống bên dưới (nhìn vô lý).

func _is_deep(r: int, c: int) -> bool:
	for dr in range(-2, 3):
		for dc in range(-2, 3):
			if _cell(r + dr, c + dc) != "#": return false
	return true

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
	var bit_tex: Dictionary = {}   # đường dẫn -> Texture2D: mỗi ảnh chỉ tra/nạp một lần, không mỗi viên đá
	if not bit_set.is_empty() and prop_sets.has(bit_set):
		var n := int((prop_sets[bit_set] as Dictionary).get("n", 1))
		for r in range(_rows):
			for c in range(_cols):
				if not _solid(r, c) or _solid(r - 1, c): continue
				var h := (r * 71 + c * 137) % 100
				if h > 44: continue
				var path := "%s%s/%d.png" % [PROPS, bit_set, 1 + (h % n)]
				if not bit_tex.has(path):
					bit_tex[path] = load(path) as Texture2D if ResourceLoader.exists(path) else null
				var tex: Texture2D = bit_tex[path]
				if tex == null: continue
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
			_fx.pools.append([Rect2(c * TILE, r * TILE, (e2 - c + 1) * TILE, TILE), 0.4 if _cell(r - 1, c) == "\"" else 0.6, _cell(r + 1, c) != "\""])   # [vùng, độ đậm, là hàng nước dưới cùng (chỗ nhân vật đứng)]
			c = e2 + 1
	if not _fx.falls.is_empty() or not _fx.pools.is_empty():
		_fx.z_index = -1   # sau nhân vật/quái (trước đây z=4 che mất người đứng trước thác)
		add_child(_fx)
		if not _fx.pools.is_empty():
			# Lớp nước PHÍA TRƯỚC nhân vật: phủ phần chân để nhân vật trông như đang lội trong nước thay vì đứng đè lên mặt nước.
			var front := _WaterFront.new()
			front.fx = _fx
			front.z_index = 4   # trên nhân vật/quái/thú (0..3), dưới đạn và hiệu ứng kỹ năng (7+)
			add_child(front)
			_fx.front = front

class _WaterFx extends Node2D:
	var fall_tex: Texture2D
	var pool_tex: Texture2D
	var falls: Array = []
	var pools: Array = []
	var front: Node2D = null   # _WaterFront: lớp nước phủ chân nhân vật, vẽ lại cùng nhịp
	var _t := 0.0
	var _redraw_acc := 0.0
	func _process(d: float) -> void:
		_t += d
		_redraw_acc += d
		if _redraw_acc >= 1.0 / 30.0:
			_redraw_acc = 0.0
			queue_redraw()
			if front != null: front.queue_redraw()
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
		# Hồ/ao: nước dựng bằng code (không dùng ảnh cuộn ngang): màu chuyển sắc theo độ sâu, mặt gợn sóng, ánh lấp lánh trôi chậm.
		for p in pools:
			var rect2: Rect2 = p[0]
			if not rect2.intersects(vis): continue
			var k := float(p[1]) / 0.6   # hàng nước trên cùng = 1.0, hàng dưới = đậm/đục hơn
			var top_c := Color(0.6, 0.88, 0.96, 0.34 * k)
			var bot_c := Color(0.1, 0.36, 0.52, 0.82 * k)
			var step := 8.0
			var nseg := int(ceil(rect2.size.x / step))
			var prev_x := rect2.position.x
			var prev_y := rect2.position.y + wave(prev_x, _t)
			var surf := PackedVector2Array([Vector2(prev_x, prev_y)])
			for i in range(1, nseg + 1):
				var px := minf(rect2.position.x + float(i) * step, rect2.end.x)
				var py := rect2.position.y + wave(px, _t)
				draw_polygon(PackedVector2Array([Vector2(prev_x, prev_y), Vector2(px, py), Vector2(px, rect2.end.y), Vector2(prev_x, rect2.end.y)]),
					PackedColorArray([top_c, top_c, bot_c, bot_c]))
				surf.append(Vector2(px, py))
				prev_x = px
				prev_y = py
			draw_polyline(surf, Color(0.9, 0.98, 1.0, 0.55 * k), 1.5)
			# Vệt sáng lấp lánh trôi ngang, nhấp nháy theo sin
			var nsh := int(rect2.size.x / 90.0) + 1
			for s in range(nsh):
				var sx := rect2.position.x + fposmod(float(s) * 97.0 + _t * (9.0 + float(s % 3) * 4.0), rect2.size.x)
				var sy := rect2.position.y + 6.0 + fposmod(float(s) * 53.0, maxf(1.0, rect2.size.y - 12.0))
				var sa := 0.22 * k * (0.5 + 0.5 * sin(_t * 2.3 + float(s) * 1.7))
				draw_line(Vector2(sx, sy), Vector2(minf(sx + 12.0, rect2.end.x), sy), Color(1, 1, 1, sa), 1.0)

	## Độ cao mặt sóng tại hoành độ px (px) ở thời điểm t: hai sóng sin chồng nhau; lớp trước và lớp sau dùng chung để khớp nhau.
	static func wave(px: float, t: float) -> float:
		return sin(px * 0.11 + t * 3.1) * 1.3 + sin(px * 0.27 - t * 2.2) * 0.6

## Lớp nước phủ phía TRƯỚC nhân vật (z cao hơn nhân vật): một dải nước hơi đục ở sát mặt đất + gợn sóng sáng trên mặt,
## nên chân nhân vật chìm trong nước thay vì đứng đè lên mặt hồ. Chỉ vẽ ở hàng nước dưới cùng và trong khung nhìn.
class _WaterFront extends Node2D:
	const DEPTH := 15.0       # bề dày dải nước phủ chân (px)
	var fx: Node2D = null     # _WaterFx: lấy danh sách hồ và đồng hồ chung
	func _draw() -> void:
		if fx == null: return
		var vis := get_canvas_transform().affine_inverse() * get_viewport_rect()
		vis = vis.grow(64.0)
		var t: float = fx._t
		for p in fx.pools:
			if not bool(p[2]): continue
			var rect: Rect2 = p[0]
			if not rect.intersects(vis): continue
			var h := minf(rect.size.y, DEPTH)
			var y0 := rect.end.y - h
			# Thân nước phủ chân: trong ở mặt, đậm dần xuống đáy (không ảnh cuộn)
			var top_c := Color(0.55, 0.85, 0.95, 0.0)   # mép trên trong suốt: dải phủ chân hoà vào mặt hồ, không tạo thêm đường sóng thứ hai
			var bot_c := Color(0.06, 0.28, 0.42, 0.55)
			var step := 8.0
			var nseg := int(ceil(rect.size.x / step))
			var prev_x := rect.position.x
			var prev_y := y0 + _WaterFx.wave(prev_x, t)
			for i in range(1, nseg + 1):
				var px := minf(rect.position.x + float(i) * step, rect.end.x)
				var py := y0 + _WaterFx.wave(px, t)
				draw_polygon(PackedVector2Array([Vector2(prev_x, prev_y), Vector2(px, py), Vector2(px, rect.end.y), Vector2(prev_x, rect.end.y)]),
					PackedColorArray([top_c, top_c, bot_c, bot_c]))
				prev_x = px
				prev_y = py

## Độ sâu làm mượt theo 5 cột lân cận (tránh vệt tối gãy ở chân cột đất cao); cột không phải đất dùng độ sâu của chính ô.
func _depth_near(r: int, c: int) -> int:
	var own := _depth_of(r, c)
	var sum := 0
	for dc in range(-2, 3):
		sum += _depth_of(r, c + dc) if _solid(r, c + dc) else own
	return int(round(float(sum) / 5.0))
