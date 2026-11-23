extends Control
## Đăng nhập / đăng ký. Bố cục ngang: logo bên trái, thẻ form bên phải.
## Server trả Set-Cookie (Net lưu vào Settings.session). Lỗi hiển thị nguyên văn từ server.

const T := preload("res://src/ui/UITheme.gd")
const SplashBG := preload("res://src/ui/SplashBG.gd")

var _mode := "login"   # "login" | "register"
var _user: LineEdit
var _pass: LineEdit
var _char: LineEdit
var _server: LineEdit
var _server_row: Control
var _submit: Button
var _tab_login: Button
var _tab_reg: Button
var _msg: Label
var _busy_flag := false

func _ready() -> void:
	theme = T.make_theme()
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(SplashBG.new())
	var inset := T.safe_insets(get_viewport(), 24.0)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", int(inset.x))
	margin.add_theme_constant_override("margin_right", int(inset.z))
	margin.add_theme_constant_override("margin_top", int(inset.y))
	margin.add_theme_constant_override("margin_bottom", int(inset.w))
	add_child(margin)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 32)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(row)

	# ---- Trái: logo ----
	var left := CenterContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(left)
	left.add_child(SplashBG.make_logo(56))

	# ---- Phải: thẻ form ----
	var right := CenterContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(right)
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(380, 0)
	card.add_theme_stylebox_override("panel", T.UISkin.panel(18))
	right.add_child(card)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", T.SP_M)
	card.add_child(vb)

	# Tab đăng nhập / đăng ký
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", T.SP_S)
	vb.add_child(tabs)
	_tab_login = T.button("Đăng nhập", Vector2(0, 40))
	_tab_login.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_tab_login.pressed.connect(func(): _set_mode("login"))
	tabs.add_child(_tab_login)
	_tab_reg = T.button("Đăng ký", Vector2(0, 40))
	_tab_reg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_tab_reg.pressed.connect(func(): _set_mode("register"))
	tabs.add_child(_tab_reg)

	_user = _field("Tên đăng nhập")
	_user.text = Settings.last_user
	vb.add_child(_user)
	_pass = _field("Mật khẩu")
	_pass.secret = true
	vb.add_child(_pass)
	_char = _field("Tên nhân vật")
	_char.max_length = 20
	vb.add_child(_char)

	_server_row = VBoxContainer.new()
	vb.add_child(_server_row)
	_server = _field("Địa chỉ server (https://…)")
	_server.text = Settings.server_url
	_server_row.add_child(_server)
	_server_row.visible = false

	_msg = T.label("", T.FS_S, T.C_RED)
	_msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(_msg)

	_submit = T.button_primary("Đăng nhập", Vector2(0, 50))
	_submit.pressed.connect(_on_submit)
	vb.add_child(_submit)

	var adv := T.button_link("Cài đặt máy chủ")
	adv.pressed.connect(func(): _server_row.visible = not _server_row.visible)
	vb.add_child(adv)

	_pass.text_submitted.connect(func(_t): _on_submit())
	_char.text_submitted.connect(func(_t): _on_submit())
	_set_mode("login")

func _field(placeholder: String) -> LineEdit:
	var e := LineEdit.new()
	e.placeholder_text = placeholder
	e.custom_minimum_size = Vector2(0, 46)
	e.caret_blink = true
	e.context_menu_enabled = false
	return e

func _style_tab(b: Button, active: bool) -> void:
	var n: StyleBox = T.UISkin.tab(active)
	b.add_theme_stylebox_override("normal", n)
	b.add_theme_stylebox_override("hover", n)
	b.add_theme_stylebox_override("pressed", T.UISkin.tab(true))
	b.add_theme_stylebox_override("disabled", n)
	b.add_theme_color_override("font_color", T.C_GOLD if active else T.C_MUTED)

func _set_mode(m: String) -> void:
	_mode = m
	_char.visible = m == "register"
	_submit.text = "Đăng nhập" if m == "login" else "Tạo tài khoản"
	_style_tab(_tab_login, m == "login")
	_style_tab(_tab_reg, m == "register")
	_pass.placeholder_text = "Mật khẩu"
	_say("")

func _say(text: String, ok: bool = false) -> void:
	_msg.text = text
	_msg.add_theme_color_override("font_color", T.C_GREEN if ok else T.C_RED)
	_msg.visible = not text.is_empty()

func _busy(on: bool) -> void:
	_busy_flag = on
	_submit.disabled = on
	_tab_login.disabled = on
	_tab_reg.disabled = on
	if on: _say("Đang xử lý…", true)

func _apply_server() -> void:
	var url := _server.text.strip_edges()
	if url.is_empty(): return
	if not url.begins_with("http"): url = "https://" + url
	if url != Settings.server_url:
		Settings.set_server_url(url)

func _on_submit() -> void:
	if _busy_flag: return
	_apply_server()
	var u := _user.text.strip_edges()
	if u.is_empty() or _pass.text.is_empty():
		_say("Nhập tài khoản và mật khẩu.")
		return
	if _mode == "register":
		var cn := _char.text.strip_edges()
		if cn.is_empty():
			_say("Nhập tên nhân vật.")
			return
		_busy(true)
		var r: Dictionary = await Net.register(u, _pass.text, cn)
		if r.get("ok") == false or r.has("error"):
			_busy(false)
			_say(str(r.get("error", "Đăng ký thất bại.")))
			return
		# Đăng ký xong dùng luôn phiên mới (hoặc đăng nhập lại nếu server không tự đăng nhập).
		await _enter_after_auth(u, true)
	else:
		_busy(true)
		var r2: Dictionary = await Net.login(u, _pass.text)
		if r2.get("ok") == false or r2.has("error"):
			_busy(false)
			_say(str(r2.get("error", "Đăng nhập thất bại.")))
			return
		await _enter_after_auth(u, false)

func _enter_after_auth(u: String, just_registered: bool) -> void:
	Settings.set_last_user(u)
	var me: Dictionary = await Net.me()
	if not me.has("player") and just_registered:
		var r: Dictionary = await Net.login(u, _pass.text)
		if r.get("ok") != false and not r.has("error"):
			me = await Net.me()
	_busy(false)
	if me.has("player"):
		Game.set_player(me["player"])
		Game.rev = int(me.get("rev", 0))
		get_tree().change_scene_to_file("res://src/scenes/World.tscn")
	else:
		_say(str(me.get("error", "Không tải được nhân vật.")))
