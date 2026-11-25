extends ScrollContainer
## ScrollContainer vuốt bằng ngón tay mượt, kể cả khi ngón chạm bắt đầu TRÊN một nút.
## Vấn đề của ScrollContainer gốc: Button (mouse_filter STOP) nuốt luôn sự kiện kéo nên chỉ vuốt được ở khoảng trống -> "lì".
## Ở đây bắt chuột/chạm ở mức _input (trước GUI): kéo quá ngưỡng thì cuộn, huỷ lần bấm nút đang giữ, có quán tính.

const DRAG_START := 9.0         # px, quá ngưỡng này mới coi là vuốt (dưới ngưỡng vẫn là chạm bấm nút)
const FRICTION := 4.2           # quán tính: v *= exp(-FRICTION * dt)

var _tracking := false
var _dragging := false
var _press_pos := Vector2.ZERO
var _last_pos := Vector2.ZERO
var _vel := 0.0
var _last_t := 0
var _pressed_ctrl: Control = null
var horizontal := false        # true: vuốt ngang (thanh menu), không hiện thanh cuộn

func _ready() -> void:
	scroll_deadzone = 100000      # tắt vuốt gốc, dùng bộ xử lý bên dưới
	follow_focus = false
	set_process(true)

func _inside(p: Vector2) -> bool:
	var r: Rect2 = get_global_transform_with_canvas() * Rect2(Vector2.ZERO, size)
	return r.has_point(p)

func _is_scrollable() -> bool:
	if not is_visible_in_tree(): return false
	var sb: ScrollBar = get_h_scroll_bar() if horizontal else get_v_scroll_bar()
	return sb != null and sb.max_value > sb.page + 1.0

func _no_drag_target(c: Control) -> bool:
	while c != null and c != self:
		if c is Slider or c is LineEdit or c is TextEdit or c is ScrollBar or c is SpinBox: return true
		c = c.get_parent() as Control
	return false

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		var mb := event as InputEventMouseButton
		if mb.pressed:
			_tracking = false; _dragging = false
			if not _is_scrollable() or not _inside(mb.position): return
			var hov := _control_at(self, mb.position)
			if hov != null and _no_drag_target(hov): return
			# chỉ nhận nếu cuộn này là cuộn gần nhất của điều khiển bị chạm (tránh cuộn lồng nhau)
			var p: Node = hov
			while p != null and not (p is ScrollContainer): p = p.get_parent()
			if p != self and p != null: return
			_tracking = true
			_press_pos = mb.position
			_last_pos = mb.position
			_vel = 0.0
			_last_t = Time.get_ticks_msec()
			_pressed_ctrl = hov
		else:
			if _dragging:
				get_viewport().set_input_as_handled()
			_tracking = false
			_dragging = false
	elif event is InputEventMouseMotion and _tracking:
		var mm := event as InputEventMouseMotion
		if (mm.button_mask & MOUSE_BUTTON_MASK_LEFT) == 0:
			_tracking = false; _dragging = false
			return
		if not _dragging:
			if absf((mm.position.x - _press_pos.x) if horizontal else (mm.position.y - _press_pos.y)) < DRAG_START: return
			_dragging = true
			_cancel_press()
			_last_pos = mm.position
			_last_t = Time.get_ticks_msec()
		var dy := (mm.position.x - _last_pos.x) if horizontal else (mm.position.y - _last_pos.y)
		_last_pos = mm.position
		var now := Time.get_ticks_msec()
		var dt := maxf(0.001, float(now - _last_t) / 1000.0)
		_last_t = now
		_vel = lerpf(_vel, dy / dt, 0.6)
		_scroll_by(-dy)
		get_viewport().set_input_as_handled()

## Điều khiển sâu nhất dưới điểm chạm (không dựa vào hover vì cảm ứng không có hover).
func _control_at(node: Node, p: Vector2) -> Control:
	var kids := node.get_children()
	kids.reverse()
	for k in kids:
		if k is Control:
			var c := k as Control
			if not c.visible: continue
			var r: Rect2 = c.get_global_transform_with_canvas() * Rect2(Vector2.ZERO, c.size)
			if not r.has_point(p): continue
			var deeper := _control_at(c, p)
			if deeper != null: return deeper
			if c.mouse_filter != Control.MOUSE_FILTER_IGNORE: return c
		elif k is CanvasLayer:
			continue
	return null

## Huỷ trạng thái "đang giữ" của nút đã nhận lần chạm đầu, để thả tay không kích hoạt nút.
func _cancel_press() -> void:
	var c: Control = _pressed_ctrl
	while c != null and c != self:
		if c is BaseButton:
			var was := (c as BaseButton).disabled
			(c as BaseButton).disabled = true
			(c as BaseButton).disabled = was
			break
		c = c.get_parent() as Control
	_pressed_ctrl = null

func _process(delta: float) -> void:
	if _tracking or absf(_vel) < 25.0:
		return
	_scroll_by(-_vel * delta)
	_vel *= exp(-FRICTION * delta)
	var sb: ScrollBar = get_h_scroll_bar() if horizontal else get_v_scroll_bar()
	var cur := scroll_horizontal if horizontal else scroll_vertical
	if cur <= 0 or cur >= int(sb.max_value - sb.page): _vel = 0.0

func _scroll_by(d: float) -> void:
	if horizontal: scroll_horizontal = int(scroll_horizontal + d)
	else: scroll_vertical = int(scroll_vertical + d)
