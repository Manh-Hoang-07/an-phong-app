extends SceneTree

func _initialize() -> void:
	var hud = load("res://src/ui/MobileHUD.gd").new()
	root.add_child(hud)
	await process_frame
	root.get_node("Game").player["mounts"] = {"owned": ["soi_xam", "ky_lan"], "summoned": ["soi_xam"]}
	hud.open_panel("companion")
	for i in range(8): await process_frame
	_dump(hud._panel_body, 0)
	quit()

func _dump(n: Node, d: int) -> void:
	if d > 7: return
	var sz := ""
	if n is Control: sz = " size=%s min=%s" % [str(n.size), str(n.get_combined_minimum_size())]
	print("  ".repeat(d), n.get_class(), sz)
	for c in n.get_children(): _dump(c, d + 1)