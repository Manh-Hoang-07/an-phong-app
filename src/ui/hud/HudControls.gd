extends "res://src/ui/hud/HudPart.gd"
## Điều khiển: joystick, nút Đánh/Nhảy, vòng kỹ năng, bình nhanh, biến hình, đổi Ấn.
## Thành phần của MobileHUD (hud = MobileHUD): tự dựng node, tự giữ trạng thái; API công khai được MobileHUD chuyển tiếp.

# joystick
var _joy_zone: Control = null

var _joy_ring: Panel = null

var _joy_knob: Panel = null

var _joy_touch := -1

var _joy_center := Vector2.ZERO

var _joy_idle := Vector2.ZERO

# nút hành động
var _skill_buttons: Array = []

var _attack_btn: ActionButton = null

var _jump_btn: ActionButton = null

var _form_btn: ActionButton = null

var _seal_btn: ActionButton = null

var _potion_hp: ActionButton = null

var _potion_mp: ActionButton = null

func _build_joystick() -> void:
	_joy_zone = Control.new()
	_joy_zone.name = "JoyZone"
	_joy_zone.set_anchors_preset(Control.PRESET_FULL_RECT)
	_joy_zone.anchor_right = 0.46
	_joy_zone.anchor_top = 0.22
	_joy_zone.offset_left = 0; _joy_zone.offset_top = 0; _joy_zone.offset_right = 0; _joy_zone.offset_bottom = 0
	_joy_zone.mouse_filter = Control.MOUSE_FILTER_STOP
	_joy_zone.gui_input.connect(_on_joy_input)
	_joy_zone.resized.connect(_layout_joy)
	_root.add_child(_joy_zone)
	_joy_ring = Panel.new()
	_joy_ring.size = Vector2(JOY_R * 2.0, JOY_R * 2.0)
	_joy_ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_joy_ring.add_theme_stylebox_override("panel", T.sb(Color(0.08, 0.10, 0.17, 0.35), Color(0.62, 0.74, 0.96, 0.7), 2, int(JOY_R), 0))
	_joy_zone.add_child(_joy_ring)
	_joy_knob = Panel.new()
	_joy_knob.size = Vector2(46, 46)
	_joy_knob.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_joy_knob.add_theme_stylebox_override("panel", T.sb(Color(0.62, 0.76, 0.98, 0.9), T.C_GOLD, 2, 23, 0))
	_joy_zone.add_child(_joy_knob)

func _layout_joy() -> void:
	if _joy_zone == null or _joy_knob == null or _joy_touch != -1: return
	var zs := _joy_zone.size
	_joy_idle = Vector2(_inset.x + 18.0 + JOY_R, zs.y - _inset.w - 18.0 - JOY_R)
	_set_joy_visual(_joy_idle, Vector2.ZERO, 0.45)

func _set_joy_visual(center: Vector2, d: Vector2, alpha: float) -> void:
	_joy_ring.position = center - Vector2(JOY_R, JOY_R)
	_joy_knob.position = center + d - _joy_knob.size * 0.5
	_joy_ring.modulate.a = alpha
	_joy_knob.modulate.a = clampf(alpha + 0.2, 0.0, 1.0)

func _on_joy_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and _joy_touch == -1:
			_joy_touch = event.index
			_joy_center = event.position
			_set_joy_visual(_joy_center, Vector2.ZERO, 1.0)
			accept_event_safe()
		elif not event.pressed and event.index == _joy_touch:
			_joy_touch = -1
			_set_joy_visual(_joy_idle, Vector2.ZERO, 0.45)
			hud.move_vector.emit(Vector2.ZERO)
	elif event is InputEventScreenDrag and event.index == _joy_touch:
		var d: Vector2 = event.position - _joy_center
		if d.length() > JOY_R: d = d.normalized() * JOY_R
		_set_joy_visual(_joy_center, d, 1.0)
		var v := d / JOY_R
		if v.length() < 0.18: v = Vector2.ZERO   # vùng chết nhỏ, tránh trôi
		hud.move_vector.emit(v)

func accept_event_safe() -> void:
	if _joy_zone: _joy_zone.accept_event()

func _build_actions() -> void:
	# Bố cục góc phải-dưới, tâm nút Đánh (A) sát góc; các nút còn lại xếp cung tròn quanh A, không chồng nhau.
	var cx := -(_inset.z + ATTACK_R + 2.0)
	var cy := -(_inset.w + ATTACK_R + 2.0)
	_attack_btn = ActionButton.new()
	_attack_btn.setup(ATTACK_R, Color(1.0, 0.82, 0.36))
	_attack_btn.big = true
	_attack_btn.fill = Color(0.62, 0.15, 0.10, 1.0)
	_attack_btn.icon.texture = T.icon("sword")
	_attack_btn.icon.modulate = Color(1.0, 0.95, 0.8)
	_attack_btn.icon.offset_left = ATTACK_R * 0.4; _attack_btn.icon.offset_top = ATTACK_R * 0.4
	_attack_btn.icon.offset_right = -ATTACK_R * 0.4; _attack_btn.icon.offset_bottom = -ATTACK_R * 0.4
	_attack_btn.pressed.connect(func(): hud.attack_pressed.emit())
	_place_br(_attack_btn, cx, cy, ATTACK_R)
	_root.add_child(_attack_btn)

	# Nhảy: dùng cần di chuyển (kéo lên), không còn nút riêng. Giữ biến để tương thích.
	_jump_btn = null

	# 5 kỹ năng thường (ô 0-4 của server): hàng ngang giữa-dưới, sát đáy màn hình
	var row_y := -(_inset.w + SKILL_R + 1.0)
	for i in range(5):
		var b := _make_skill_button(i, SKILL_R, false)
		_place_bc(b, (float(i) - 2.0) * (SKILL_R * 2.0 + 10.0), row_y, SKILL_R)
		_root.add_child(b)
		_skill_buttons.append(b)
	# 3 ô tuyệt kỹ / tuyệt phẩm (ô 5, 6, 7 của server) xếp cung quanh nút Đánh
	var ult_pos := [Vector2(-80.0, 8.0), Vector2(-58.0, -52.0), Vector2(0.0, -80.0)]
	for k in range(3):
		var u := _make_skill_button(5 + k, ULT_R, true)
		_place_br(u, cx + (ult_pos[k] as Vector2).x, cy + (ult_pos[k] as Vector2).y, ULT_R)
		_root.add_child(u)
		_skill_buttons.append(u)
	# Kỹ năng do trang bị cấp (ô 8): nối tiếp hàng kỹ năng thường, chỉ hiện khi đang mặc món có kỹ năng
	var gear := _make_skill_button(8, SKILL_R, false)
	gear.ring = Color(0.45, 0.92, 0.7)
	_place_bc(gear, 3.0 * (SKILL_R * 2.0 + 10.0), row_y, SKILL_R)
	gear.visible = false
	_root.add_child(gear)
	_skill_buttons.append(gear)
	# Biến hình (chỉ hiện khi đã mở khóa Ấn) và nút đổi ấn nhỏ phía trên
	_form_btn = ActionButton.new()
	_form_btn.setup(26.0, Color(1.0, 0.62, 0.25))
	_form_btn.fill = Color(0.30, 0.12, 0.06, 1.0)
	_form_btn.icon.texture = T.icon("flame")
	_form_btn.icon.modulate = Color(1.0, 0.85, 0.5)
	_form_btn.visible = false
	_form_btn.pressed.connect(func(): hud.form_pressed.emit())
	_place_br(_form_btn, cx - 112.0, cy - 72.0, 26.0)
	_root.add_child(_form_btn)
	_seal_btn = ActionButton.new()
	_seal_btn.setup(14.0, Color(0.8, 0.7, 1.0))
	_seal_btn.fill = Color(0.16, 0.10, 0.26, 1.0)
	_seal_btn.icon.visible = false
	_seal_btn.set_glyph("I")
	_seal_btn.glyph.add_theme_font_size_override("font_size", 12)
	_seal_btn.visible = false
	_seal_btn.pressed.connect(func(): hud.seal_pressed.emit())
	_place_br(_seal_btn, cx - 118.0, cy - 116.0, 14.0)
	_root.add_child(_seal_btn)
	# Bình máu / MP nhanh: hàng dưới, bên trái các nút tuyệt kỹ
	_potion_hp = _make_potion_button("hp", Color(0.94, 0.34, 0.38), cx - 140.0, cy + 22.0)
	_potion_mp = _make_potion_button("mp", Color(0.38, 0.66, 1.0), cx - 186.0, cy + 22.0)

func _make_skill_button(i: int, r: float, special: bool) -> ActionButton:
	var b := ActionButton.new()
	b.setup(r, Color(1.0, 0.82, 0.36) if special else Color(0.55, 0.68, 0.92))
	b.big = special
	b.fill = Color(0.18, 0.12, 0.26, 1.0) if special else Color(0.09, 0.14, 0.26, 1.0)
	b.icon.visible = false
	b.set_glyph("·")
	var idx := i
	b.pressed.connect(func(): hud.skill_pressed.emit(idx))
	return b

## Màu viền + trạng thái dùng được của từng ô kỹ năng (đủ MP hay chưa).
func set_skill_styles(colors: Array, usable: Array) -> void:
	for i in range(_skill_buttons.size()):
		var b := _skill_buttons[i] as ActionButton
		if i < colors.size() and colors[i] is Color and b.ring != colors[i]:
			b.ring = colors[i]
			b.queue_redraw()
		if i < usable.size(): b.set_usable(bool(usable[i]))

## labels[i] = "glyph|tên kỹ năng" (glyph thường là emoji từ data).
func set_skill_labels(labels: Array) -> void:
	for i in range(_skill_buttons.size()):
		if i < labels.size():
			var parts := str(labels[i]).split("|", true, 1)
			var b := _skill_buttons[i] as ActionButton
			b.set_glyph(parts[0])
			b.tooltip_text = parts[1] if parts.size() > 1 else ""

## Ẩn/hiện ô kỹ năng (ô trang bị chỉ hiện khi có kỹ năng mượn).
func set_skill_visible(index: int, v: bool) -> void:
	if index >= 0 and index < _skill_buttons.size(): (_skill_buttons[index] as ActionButton).visible = v

## Bắt đầu vòng hồi chiêu cho ô kỹ năng `index` (0..4) trong `seconds` giây.
func start_cooldown(index: int, seconds: float) -> void:
	if index >= 0 and index < _skill_buttons.size():
		(_skill_buttons[index] as ActionButton).start_cooldown(seconds)

func _make_potion_button(kind: String, color: Color, cx: float, cy: float) -> ActionButton:
	var b := ActionButton.new()
	b.setup(21.0, color)
	b.icon.visible = true
	b.icon.modulate = Color.WHITE
	b.visible = false
	b.pressed.connect(func(): hud.potion_pressed.emit(kind))
	_place_br(b, cx, cy, 21.0)
	_root.add_child(b)
	return b

## Cập nhật nút bình nhanh: item id + số lượng (0 = ẩn).
func set_potions(hp_id: String, hp_n: int, mp_id: String, mp_n: int) -> void:
	_set_potion(_potion_hp, hp_id, hp_n)
	_set_potion(_potion_mp, mp_id, mp_n)

func _set_potion(b: ActionButton, iid: String, n: int) -> void:
	if b == null: return
	b.visible = n > 0
	if n > 0:
		b.icon.texture = T.icon("bag") if not ResourceLoader.exists("res://assets/items/%s.svg" % iid) else load("res://assets/items/%s.svg" % iid)
		b.set_badge(str(n))
		b.tooltip_text = str(Data.item(iid).get("name", iid))

func potion_cooldown(kind: String, seconds: float) -> void:
	var b := _potion_hp if kind == "hp" else _potion_mp
	if b: b.start_cooldown(seconds)

## Cập nhật nút biến hình: số Ấn đã mở, Ấn đang chọn (1..5), đang biến hình hay không.
func set_form_state(unlocked: int, tier: int, active: bool) -> void:
	if _form_btn == null: return
	_form_btn.visible = unlocked >= 1
	_seal_btn.visible = unlocked >= 2
	if unlocked < 1: return
	var aw: Dictionary = Data.awaken(tier)
	var aura := Color.from_rgba8((int(aw.get("aura", 0xff9a40)) >> 16) & 255, (int(aw.get("aura", 0xff9a40)) >> 8) & 255, int(aw.get("aura", 0xff9a40)) & 255)
	_form_btn.ring = aura if active else Color(1.0, 0.62, 0.25)
	_form_btn.fill = Color(0.42, 0.16, 0.06, 1.0) if active else Color(0.30, 0.12, 0.06, 1.0)
	_form_btn.set_glow(active)
	_form_btn.tooltip_text = ("Trở lại dạng thường" if active else "Biến hình · Ấn %s" % str(Data.ROMAN[clampi(tier - 1, 0, 4)]))
	_form_btn.queue_redraw()
	_seal_btn.set_glyph(str(Data.ROMAN[clampi(tier - 1, 0, 4)]))
	_seal_btn.set_usable(not active)
