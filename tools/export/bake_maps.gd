extends SceneTree
## Bake sẵn ảnh nền (đất/đá/gỗ/cỏ) của từng map thành PNG trong assets/mapcache/ để game không phải dựng bằng CPU mỗi lần vào map.
##   godot --headless --path . --script res://tools/export/bake_maps.gd -- [map_id ...]
## (không tham số = bake mọi map). Sau đó nhập ảnh vào project:  godot --headless --path . --import
## Hoặc chạy gộp cả hai: tools/export/bake_maps.ps1. Chạy lại mỗi khi đổi data/maps, data/map_looks.json, assets/art hoặc MapTileArt/MapView
## (đổi ảnh ô mẫu / thuật toán thì tăng MapView.CACHE_VER).
const MapGrid := preload("res://src/world/MapGrid.gd")


func _initialize() -> void:
	var data = root.get_node("Data")
	data.load_local()
	var want: PackedStringArray = OS.get_cmdline_user_args()
	var ids: Array = []
	var da := DirAccess.open("res://data/maps")
	for f in da.get_files():
		if f.ends_with(".txt"): ids.append(f.get_basename())
	ids.sort()
	var total := 0
	var maps := 0
	for id in ids:
		if want.size() > 0 and not (id in want): continue
		var meta: Dictionary = data.map_def(id)
		var th := str(meta.get("theme", "city"))
		var grid := MapGrid.build(data.map_text(id), meta)
		var view = load("res://src/world/MapView.gd").new()
		var n: int = view.export_bake(grid, th, id)
		view.free()
		print("%-24s %d file" % [id, n])
		total += n
		maps += 1
	print("Xong: %d map, %d file PNG trong assets/mapcache/ — chạy tiếp: godot --headless --path . --import" % [maps, total])
	quit(0)
