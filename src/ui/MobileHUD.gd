extends CanvasLayer
## HUD cảm ứng (điện thoại, ngang). Không chứa luật chơi — chỉ phát tín hiệu cho World và dựng panel qua GamePanels.
##
## Bố cục (viewport ~960x432, có safe area):
##   trái-trên: avatar + tên + HP/MP/STA     giữa-trên: nhiệm vụ     phải-trên: tên map, chat, menu
##   trái-dưới: log chat + joystick động     phải-dưới: nút Đánh lớn + vòng 5 kỹ năng + nút Nhảy
##   đáy: thanh EXP mảnh toàn chiều rộng
## Mọi điều khiển game dùng InputEventScreenTouch/Drag (đa điểm); nút panel dùng chuột giả lập từ cảm ứng.


signal move_vector(dir: Vector2)
signal skill_pressed(index: int)
signal attack_pressed()
signal jump_pressed()
signal menu_pressed(tab: String)
signal chat_sent(text: String)
signal interact_pressed()
signal potion_pressed(kind: String)
signal form_pressed()
signal seal_pressed()
signal death_choice(where: String)

const T := preload("res://src/ui/UITheme.gd")
const HudStats := preload("res://src/ui/hud/HudStats.gd")
const HudMenu := preload("res://src/ui/hud/HudMenu.gd")
const HudControls := preload("res://src/ui/hud/HudControls.gd")
const HudChat := preload("res://src/ui/hud/HudChat.gd")
const HudNotices := preload("res://src/ui/hud/HudNotices.gd")
const HudPanel := preload("res://src/ui/hud/HudPanel.gd")
const HudPrompts := preload("res://src/ui/hud/HudPrompts.gd")
const HudScreenFx := preload("res://src/ui/hud/HudScreenFx.gd")
const HudBuffs := preload("res://src/ui/hud/HudBuffs.gd")

# Hub: giữ node gốc + vùng an toàn, tạo các thành phần (src/ui/hud/), chuyển tiếp API công khai cho World.
var _root: Control = null
var _inset := Vector4(14, 8, 14, 8)

# Thành phần
var stats = HudStats.new(self)
var menu = HudMenu.new(self)
var controls = HudControls.new(self)
var chat = HudChat.new(self)
var notices = HudNotices.new(self)
var panel = HudPanel.new(self)
var prompts = HudPrompts.new(self)
var screenfx = HudScreenFx.new(self)
var buffs = HudBuffs.new(self)

# Lối vào cho công cụ test / debug
var _panels: Variant:
	get: return panel._panels
var _dialog: Variant:
	get: return prompts._dialog
var _panel_body: Variant:
	get: return panel._panel_body

func _ready() -> void:
	layer = 10   # CanvasLayer lồng trong node layer 10 vẫn có chỉ số riêng; phải nằm trên lớp thời tiết
	panel.create_panels()
	_build()
	get_viewport().size_changed.connect(_layout)
	set_process(true)

func _process(_delta: float) -> void:
	panel.tick()
	chat.tick()

func _build() -> void:
	_inset = _calc_inset()
	_root = Control.new()
	_root.name = "Root"
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.theme = T.make_theme()
	_root.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(_root)

	controls._build_joystick()
	stats._build_top_left()
	buffs._build_buffs()
	menu._build_top_right()
	controls._build_actions()
	chat._build_log_and_chat()
	notices._build_toast()
	screenfx._build_screen_fx()
	prompts._build_interact()
	notices._build_banner()
	menu._build_menu()
	panel._build_panel()
	notices._build_pickup()
	notices._build_zone()
	prompts._build_death()
	prompts._build_invite()
	prompts._build_dialog()
	prompts._build_confirm()
	notices._build_net_status()
	_layout()
	Social.changed.connect(panel._on_social_changed)
	Social.invited.connect(prompts._on_invited)
	Social.trade_ended.connect(panel._on_trade_ended)
	Game.event_received.connect(notices._on_event_pickup_feed)

## Khoảng cách tới mép màn hình: sát góc, chỉ chừa một phần nhỏ vùng an toàn (tai thỏ / bo góc).
func _calc_inset() -> Vector4:
	var s := T.safe_insets(get_viewport(), 0.0)
	return Vector4(maxf(3.0, s.x * 0.35), maxf(3.0, s.y * 0.5), maxf(3.0, s.z * 0.35), maxf(3.0, s.w * 0.4))

func _layout() -> void:
	_inset = _calc_inset()
	panel.layout()
	controls._layout_joy()

# ---------------------------------------------------------------- API cho World (chuyển tiếp sang thành phần)
func accept_event_safe() -> void:
	controls.accept_event_safe()

func _toggle_menu() -> void:
	menu._toggle_menu()

func set_stats(hp: int, max_hp: int, mp: int, max_mp: int, sta: int = -1, max_sta: int = 0, exp: int = 0, exp_next: int = 0) -> void:
	stats.set_stats(hp, max_hp, mp, max_mp, sta, max_sta, exp, exp_next)

func set_hero(_name: String, level: int, _rank: String, school: String) -> void:
	stats.set_hero(_name, level, _rank, school)

func set_map(_name: String) -> void:
	stats.set_map(_name)

func set_quest(text: String) -> void:
	stats.set_quest(text)

func set_skill_styles(colors: Array, usable: Array) -> void:
	controls.set_skill_styles(colors, usable)

func set_skill_labels(labels: Array) -> void:
	controls.set_skill_labels(labels)

func set_skill_visible(index: int, v: bool) -> void:
	controls.set_skill_visible(index, v)

func start_cooldown(index: int, seconds: float) -> void:
	controls.start_cooldown(index, seconds)

func log(text: String, color: Color = T.C_TEXT) -> void:
	chat.log(text, color)

func toast(text: String, kind: String = "info") -> void:
	notices.toast(text, kind)

func show_zone(map_name: String, zone: int) -> void:
	notices.show_zone(map_name, zone)

func pickup(text: String, icon_name: String = "bag", color: Color = T.C_GOLD) -> void:
	notices.pickup(text, icon_name, color)

func open_panel(tab: String, extra: Dictionary = {}) -> void:
	panel.open_panel(tab, extra)

func refresh_panel(extra: Dictionary = {}) -> void:
	panel.refresh_panel(extra)

func close_panel() -> void:
	panel.close_panel()

func set_interact(label: String) -> void:
	prompts.set_interact(label)

func show_death() -> void:
	prompts.show_death()

func hide_death() -> void:
	prompts.hide_death()

func banner(text: String, color: Color = T.C_GOLD) -> void:
	notices.banner(text, color)

func flash(color: Color, strength: float = 0.3) -> void:
	screenfx.flash(color, strength)

func open_dialog(npc_id: String) -> void:
	prompts.open_dialog(npc_id)

func dialog_open() -> bool:
	return prompts.dialog_open()

func refresh_dialog() -> void:
	prompts.refresh_dialog()

func confirm(title: String, body: String, ok_text: String, cb: Callable, danger: bool = false) -> void:
	prompts.confirm(title, body, ok_text, cb, danger)

func hint_once(id: String, text: String) -> void:
	notices.hint_once(id, text)

func set_potions(hp_id: String, hp_n: int, mp_id: String, mp_n: int) -> void:
	controls.set_potions(hp_id, hp_n, mp_id, mp_n)

func potion_cooldown(kind: String, seconds: float) -> void:
	controls.potion_cooldown(kind, seconds)

func set_form_state(unlocked: int, tier: int, active: bool) -> void:
	controls.set_form_state(unlocked, tier, active)

func set_buffs(list: Array) -> void:
	buffs.set_buffs(list)

func _update_low_hp(ratio: float) -> void:
	screenfx._update_low_hp(ratio)

func _toggle_chat() -> void:
	chat._toggle_chat()

func _render_log() -> void:
	chat._render_log()

func _tween_busy(alpha: float) -> void:
	screenfx._tween_busy(alpha)

func _close_menu() -> void:
	menu._close_menu()
