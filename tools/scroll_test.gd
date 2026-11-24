extends SceneTree
## Kiểm TouchScroll: vuốt bắt đầu trên nút phải cuộn được và không kích hoạt nút; chạm nhanh vẫn bấm được nút.
var _sc: ScrollContainer
var _presses := 0
var _f := 0

func _initialize() -> void:
	root.size = Vector2i(400, 300)
	var ctl := Control.new()
	ctl.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(ctl)
	_sc = load("res://src/ui/TouchScroll.gd").new()
	_sc.position = Vector2(20, 20); _sc.size = Vector2(300, 200)
	ctl.add_child(_sc)
	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_sc.add_child(vb)
	for i in 40:
		var b := Button.new(); b.text = "Nút %d" % i; b.custom_minimum_size = Vector2(0, 40)
		b.pressed.connect(func(): _presses += 1)
		vb.add_child(b)

func _mouse(pos: Vector2, pressed: bool, motion: bool = false) -> void:
	var e: InputEvent
	if motion:
		var m := InputEventMouseMotion.new(); m.position = pos; m.global_position = pos; m.button_mask = MOUSE_BUTTON_MASK_LEFT; e = m
	else:
		var b := InputEventMouseButton.new(); b.position = pos; b.global_position = pos; b.button_index = MOUSE_BUTTON_LEFT; b.pressed = pressed; e = b
	Input.parse_input_event(e)

func _process(_d: float) -> bool:
	_f += 1
	if _f == 5: _mouse(Vector2(100, 150), true)
	if _f >= 6 and _f <= 12: _mouse(Vector2(100, 150 - (_f - 5) * 12), false, true)
	if _f == 13: _mouse(Vector2(100, 66), false)
	if _f == 20:
		print("sau vuot: scroll=", _sc.scroll_vertical, " presses=", _presses)
		_mouse(Vector2(100, 100), true)
	if _f == 22:
		_mouse(Vector2(100, 100), false)
	if _f == 40:
		print("sau cham: presses=", _presses, "  (ky vong scroll>0, vuot khong bam, cham bam 1)")
		quit()
	return false
