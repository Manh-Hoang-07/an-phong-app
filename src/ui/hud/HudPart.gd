extends RefCounted
## Lớp nền cho các thành phần HUD: hằng dùng chung, truy cập _root/_inset của MobileHUD, hàm đặt vị trí control.

const T := preload("res://src/ui/UITheme.gd")

const TouchScroll := preload("res://src/ui/TouchScroll.gd")

const GP := preload("res://src/ui/GamePanels.gd")

const W := preload("res://src/ui/PanelWidgets.gd")

const NpcDialog := preload("res://src/ui/NpcDialog.gd")

# Panel chính (hiện trong ngăn kéo bên phải)
const TABS := ["bag", "equip", "char", "skills", "quest", "mount", "companion", "shadows",
	"map", "shop", "smith", "storage", "teleport", "daily", "npc", "code", "school", "gate", "config", "social", "trade", "kynguyen", "form"]

const TAB_LABELS := {
	"bag": "Túi", "equip": "Trang bị", "char": "Nhân vật", "skills": "Kỹ năng", "quest": "Nhiệm vụ",
	"mount": "Linh thú", "companion": "Thú cưng", "shadows": "Bóng ma", "map": "Bản đồ",
	"shop": "Cửa hàng", "smith": "Lò rèn", "storage": "Kho", "teleport": "Dịch chuyển",
	"daily": "Nhiệm vụ ngày", "npc": "NPC", "code": "Mật mã", "school": "Class", "gate": "Cổng", "config": "Cài đặt",
	"social": "Xã hội", "trade": "Giao dịch", "kynguyen": "Kỳ Nguyên", "form": "Biến hình"
}

const TAB_ICONS := {
	"bag": "bag", "equip": "equip", "char": "char", "skills": "skills", "quest": "quest",
	"mount": "pet", "companion": "pet", "shadows": "social", "map": "map",
	"shop": "shop", "smith": "anvil", "storage": "storage", "teleport": "portal",
	"daily": "quest", "npc": "chat", "code": "quest", "school": "char", "gate": "portal", "config": "gear",
	"social": "social", "trade": "bag", "kynguyen": "star", "form": "flame"
}

# Lưới menu chính (8 mục) + hàng dịch vụ (tạm thời cho tới khi chạm NPC trên bản đồ).
const RAIL_SHORT := {"bag": "Túi", "equip": "Trang bị", "char": "Nhân vật", "skills": "Kỹ năng", "quest": "Nhiệm vụ", "map": "Bản đồ", "social": "Xã hội", "kynguyen": "Kỳ Nguyên", "companion": "Thú cưng", "config": "Cài đặt"}

const RAIL_TABS := ["bag", "equip", "char", "skills", "quest", "map", "social", "companion", "config"]

const MENU_MAIN := ["bag", "equip", "char", "skills", "quest", "map", "social", "companion", "config"]

const MENU_MORE := []

const MENU_SERVICES := ["shop", "smith", "storage", "teleport", "npc", "code", "gate"]

const MENU_TILE_H := 76.0   # chiều cao ô menu dưới đáy

const MENU_TILE_W := 100.0

const JOY_R := 54.0

const SKILL_R := 25.0      # 4 kỹ năng thường (hàng ngang dưới màn)

const ULT_R := 29.0        # kỹ năng đặc biệt (cạnh nút Đánh)

const ATTACK_R := 40.0

const JUMP_R := 23.0
const ActionButton := preload("res://src/ui/hud/ActionButton.gd")

var hud   # MobileHUD (CanvasLayer)

var _root: Control:
	get: return hud._root
var _inset: Vector4:
	get: return hud._inset

func _init(h) -> void:
	hud = h

# Chuyển tiếp hàm của node MobileHUD (thành phần là RefCounted nên không có sẵn)
func create_tween() -> Tween:
	return hud.create_tween()

func get_tree() -> SceneTree:
	return hud.get_tree()

func get_viewport() -> Viewport:
	return hud.get_viewport()

func _anchor_rect(c: Control, preset: int, x: float, y: float, w: float, h: float) -> void:
	## Đặt control theo góc (preset) với vị trí x,y tính từ góc đó (x,y dương = vào trong).
	c.set_anchors_preset(preset)
	match preset:
		Control.PRESET_TOP_LEFT:
			c.offset_left = x; c.offset_top = y; c.offset_right = x + w; c.offset_bottom = y + h
		Control.PRESET_TOP_RIGHT:
			c.offset_right = -x; c.offset_top = y; c.offset_left = -x - w; c.offset_bottom = y + h
		Control.PRESET_BOTTOM_LEFT:
			c.offset_left = x; c.offset_bottom = -y; c.offset_right = x + w; c.offset_top = -y - h
		Control.PRESET_BOTTOM_RIGHT:
			c.offset_right = -x; c.offset_bottom = -y; c.offset_left = -x - w; c.offset_top = -y - h
		Control.PRESET_CENTER_TOP:
			c.offset_left = -w * 0.5; c.offset_right = w * 0.5; c.offset_top = y; c.offset_bottom = y + h

## Một hàng chỉ số: icon nhỏ + thanh (có số trong thanh nếu đủ cao). Trả [bar, text_label, row].
func _stat_row(icon_name: String, color: Color, h: float) -> Array:
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 5)
	var ic := T.icon_rect(icon_name, 13.0, color)
	ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(ic)
	var bar := _make_bar(color, h)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(bar)
	var txt: Label = null
	if h >= 12.0:
		txt = T.hud_label("0 / 0", 10 if h < 13.0 else (11 if h < 16.0 else 12), Color.WHITE, true)
		txt.set_anchors_preset(Control.PRESET_FULL_RECT)
		txt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		txt.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		txt.add_theme_constant_override("outline_size", 3)
		bar.add_child(txt)
	return [bar, txt, row]

func _make_bar(color: Color, h: float) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.min_value = 0; bar.max_value = 100; bar.value = 100
	bar.custom_minimum_size = Vector2(176, h)
	bar.show_percentage = false
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_theme_stylebox_override("fill", T.UISkin.bar_fill(color))
	bar.add_theme_stylebox_override("background", T.UISkin.bar_frame())
	return bar

## Đặt tâm control tại (dx, cy): dx tính từ giữa màn hình, cy tính từ đáy (âm = vào trong).
func _place_bc(c: Control, dx: float, cy: float, r: float) -> void:
	c.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	c.offset_left = dx - r; c.offset_right = dx + r
	c.offset_top = cy - r; c.offset_bottom = cy + r

func _place_br(c: Control, cx: float, cy: float, r: float) -> void:
	## Đặt tâm control tại (cx, cy) tính từ góc phải-dưới (giá trị âm = vào trong màn hình).
	c.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	c.offset_left = cx - r; c.offset_right = cx + r
	c.offset_top = cy - r; c.offset_bottom = cy + r
