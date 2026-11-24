extends Control
## Màn khởi động: nạp dữ liệu đóng sẵn, so hash với server, rồi vào Login hoặc World.
## Không chặn người chơi khi server chưa có /api/version.

const T := preload("res://src/ui/UITheme.gd")
const SplashBG := preload("res://src/ui/SplashBG.gd")

var _status: Label
var _detail: Label
var _retry: Button
var _bar: ProgressBar

func _ready() -> void:
	theme = T.make_theme()
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(SplashBG.new())
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var vb := VBoxContainer.new()
	vb.custom_minimum_size = Vector2(360, 0)
	vb.add_theme_constant_override("separation", T.SP_M)
	center.add_child(vb)
	vb.add_child(SplashBG.make_logo())
	vb.add_child(Control.new())
	_bar = ProgressBar.new()
	_bar.custom_minimum_size = Vector2(0, 16)
	_bar.show_percentage = false
	_bar.max_value = 1.0
	_bar.add_theme_stylebox_override("fill", T.UISkin.bar_fill(T.C_GOLD))
	_bar.add_theme_stylebox_override("background", T.UISkin.bar_frame())
	vb.add_child(_bar)
	_status = T.label("Đang khởi động…", T.FS_M, T.C_TEXT)
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(_status)
	_detail = T.label("", T.FS_S, T.C_MUTED)
	_detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(_detail)
	_retry = T.button_primary("Thử lại")
	_retry.visible = false
	_retry.pressed.connect(_start)
	vb.add_child(_retry)
	_start()

func _set_status(text: String, detail: String = "", progress: float = -1.0) -> void:
	_status.text = text
	_detail.text = detail
	if progress >= 0.0:
		create_tween().tween_property(_bar, "value", progress, 0.25)

func _start() -> void:
	_retry.visible = false
	_bar.value = 0.0
	_set_status("Đang nạp dữ liệu…", "", 0.25)

	if not Data.load_local():
		_set_status("Thiếu dữ liệu game", "Chạy: node server/tools/export-gamedata.js", 0.0)
		_retry.visible = true
		return

	# Có token thì thử vào thẳng, không thì sang màn đăng nhập
	if not Settings.token.is_empty() or not Settings.session.is_empty():
		_set_status("Đang đăng nhập lại…", "", 0.8)
		var me: Dictionary = await Net.me()
		if me.get("ok") != false and me.has("player"):
			Game.set_player(me["player"])
			Game.rev = int(me.get("rev", 0))
			_enter_world()
			return
		Settings.set_token("")
		Settings.set_session("")

	_set_status("Sẵn sàng", "", 1.0)
	get_tree().change_scene_to_file("res://src/scenes/Login.tscn")

func _enter_world() -> void:
	_set_status("Vào thế giới…", "", 1.0)
	get_tree().change_scene_to_file("res://src/scenes/World.tscn")
