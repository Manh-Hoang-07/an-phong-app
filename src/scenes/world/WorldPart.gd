extends RefCounted
## Lớp nền cho các hệ thống của World (w = World, node gốc): hằng dùng chung + chuyển tiếp node API.
## Mỗi hệ thống `extends` file này, giữ trạng thái riêng, đọc/ghi trạng thái dùng chung qua các thuộc tính chuyển tiếp ở đầu file.

const T := preload("res://src/ui/UITheme.gd")
const GlyphArt := preload("res://src/ui/GlyphArt.gd")
const FloatText := preload("res://src/world/FloatText.gd")
const LootNode := preload("res://src/world/LootNode.gd")
const RemotePlayer := preload("res://src/world/RemotePlayer.gd")
const TILE := 32.0

const _TargetMark := preload("res://src/scenes/world/TargetMark.gd")   # mũi tên đánh dấu mục tiêu / điểm tương tác

var w   # World (Node2D)

func _init(world) -> void:
	w = world

# Chuyển tiếp hàm của node World (hệ thống là RefCounted nên không có sẵn)
func create_tween() -> Tween:
	return w.create_tween()

func get_tree() -> SceneTree:
	return w.get_tree()

func get_viewport() -> Viewport:
	return w.get_viewport()

func add_child(n: Node) -> void:
	w.add_child(n)

func is_inside_tree() -> bool:
	return w.is_inside_tree()

func queue_redraw() -> void:
	w.queue_redraw()
