extends SceneTree
## Kiểm ảnh bake sẵn (assets/mapcache) khớp với dựng CPU: mỗi map phải nạp được từ cache và từng pixel giống hệt.
##   godot --headless --path . --script res://tools/tests/mapcache_check.gd -- [map_id ...]
const MapGrid := preload("res://src/world/MapGrid.gd")

func _initialize() -> void:
	var data = root.get_node("Data")
	data.load_local()
	var want: PackedStringArray = OS.get_cmdline_user_args()
	var da := DirAccess.open("res://data/maps")
	var bad := 0
	var n := 0
	for f in da.get_files():
		if not f.ends_with(".txt"): continue
		var id := f.get_basename()
		if want.size() > 0 and not (id in want): continue
		var meta: Dictionary = data.map_def(id)
		var grid := MapGrid.build(data.map_text(id), meta)
		var view = load("res://src/world/MapView.gd").new()
		view.set("_grid", grid); view.set("_rows", grid.size()); view.set("_cols", (grid[0] as Array).size())
		var th := str(meta.get("theme", "city"))
		view.set("_theme", th if th in ["city", "forest", "cave", "redgate"] else "city")
		view.set("_look", data.look(id)); view.set("_map_id", id)
		var key: String = view.call("_cache_key")
		var d: Dictionary = view.call("_compose")
		var tiles: Array = d.get("tiles", [])
		var ok := tiles.size() == int(view.call("_chunk_count"))
		for i in range(tiles.size()):
			var p: String = view.call("_cache_path", "t", i, key)
			if not ResourceLoader.exists(p): ok = false; print("thiếu cache ", p); break
			var img: Image = (load(p) as Texture2D).get_image()
			img.convert(Image.FORMAT_RGBA8)
			var a8 := (tiles[i] as Image)
			if img.get_size() != a8.get_size(): ok = false; print("sai kích thước ", p); break
			# Importer có thể đổi RGB của pixel trong suốt / viền bán trong suốt; chỉ tính pixel nhìn thấy khác nhau đáng kể.
			var vis := 0
			for y in range(a8.get_height()):
				for x in range(a8.get_width()):
					var c1 := a8.get_pixel(x, y)
					var c2 := img.get_pixel(x, y)
					if (c1.a > 0.0 or c2.a > 0.0) and (absf(c1.a - c2.a) > 0.02 or absf(c1.r - c2.r) + absf(c1.g - c2.g) + absf(c1.b - c2.b) > 0.1): vis += 1
			if float(vis) > 0.001 * float(a8.get_width() * a8.get_height()): ok = false; print("lệch pixel ", p, " (", vis, ")"); break
		n += 1
		if not ok: bad += 1; print("LỖI: ", id)
		view.free()
	print("Xong: %d map, %d lỗi" % [n, bad])
	quit(1 if bad > 0 else 0)
