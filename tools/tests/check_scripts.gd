extends SceneTree
## Nạp mọi script trong src/ để bắt lỗi parse:  godot --headless --path . --script res://tools/tests/check_scripts.gd
func _initialize() -> void:
	var bad := 0
	for f in _scan("res://src"):
		var s = load(f)
		if s == null:
			bad += 1
			print("LỖI: ", f)
	print("Xong, %d lỗi" % bad)
	quit(1 if bad > 0 else 0)

func _scan(dir: String) -> Array:
	var out: Array = []
	var d := DirAccess.open(dir)
	if d == null: return out
	for e in d.get_directories(): out.append_array(_scan(dir + "/" + e))
	for f in d.get_files():
		if f.ends_with(".gd"): out.append(dir + "/" + f)
	return out
