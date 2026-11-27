extends "res://src/ui/hud/HudPart.gd"
## Log chat + ô nhập chat.
## Thành phần của MobileHUD (hud = MobileHUD): tự dựng node, tự giữ trạng thái; API công khai được MobileHUD chuyển tiếp.

# log / chat / toast
var _log: RichTextLabel = null

var _log_lines: Array = []   # [{text, color, at}]

var _chat_bar: Control = null

var _chat: LineEdit = null

func _build_log_and_chat() -> void:
	_log = RichTextLabel.new()
	_log.bbcode_enabled = true
	_log.scroll_active = false
	_log.fit_content = true
	_log.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_log.add_theme_font_size_override("normal_font_size", T.FS_S)
	_log.add_theme_font_override("normal_font", T.font(false))
	_log.add_theme_font_override("bold_font", T.font(true))
	_log.add_theme_constant_override("outline_size", 4)
	_log.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.75))
	# Nằm DƯỚI thẻ HP/MP (trước đây y=82 bị thẻ che nên tin chat mới không thấy).
	_anchor_rect(_log, Control.PRESET_TOP_LEFT, _inset.x + 4, _inset.y + 156, 300, 120)
	_root.add_child(_log)

	# Thanh chat: bật bằng nút chat, hiện ở giữa-trên.
	var bar := PanelContainer.new()
	bar.visible = false
	bar.add_theme_stylebox_override("panel", T.UISkin.panel(8))
	_anchor_rect(bar, Control.PRESET_CENTER_TOP, 0, _inset.y + 44, 420, 58)
	_root.add_child(bar)
	_chat_bar = bar
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 8)
	bar.add_child(hb)
	_chat = LineEdit.new()
	_chat.placeholder_text = "Chat… (/map, /shop, /npc)"
	_chat.custom_minimum_size = Vector2(0, 42)
	_chat.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_chat.text_submitted.connect(func(_t): _send_chat())
	hb.add_child(_chat)
	var send := T.button_primary("Gửi", Vector2(72, 42))
	send.add_theme_font_size_override("font_size", T.FS_M)
	send.pressed.connect(_send_chat)
	hb.add_child(send)

func _toggle_chat() -> void:
	_chat_bar.visible = not _chat_bar.visible
	if _chat_bar.visible: _chat.grab_focus()
	else: _chat.release_focus()

func _send_chat() -> void:
	var t := _chat.text.strip_edges()
	if not t.is_empty(): hud.chat_sent.emit(t)
	_chat.clear()
	_chat_bar.visible = false
	_chat.release_focus()

func log(text: String, color: Color = T.C_TEXT) -> void:
	# Dòng vừa hiện ở khung giữa-dưới thì không nhân đôi trong log góc trái.
	if text == hud.notices._last_pickup_text and Time.get_ticks_msec() - hud.notices._last_pickup_at < 400: return
	_log_lines.append({"text": text.replace("[", "(").replace("]", ")"), "color": color, "at": Time.get_ticks_msec()})
	while _log_lines.size() > 6: _log_lines.pop_front()
	_render_log()

func _render_log() -> void:
	var parts: PackedStringArray = []
	for l in _log_lines:
		parts.append("[color=#%s]%s[/color]" % [(l["color"] as Color).to_html(false), l["text"]])
	_log.text = "\n".join(parts)

## Dòng log tự biến mất sau 14 giây; gọi mỗi khung từ MobileHUD._process.
func tick() -> void:
	if _log_lines.is_empty(): return
	var now := Time.get_ticks_msec()
	var changed := false
	while not _log_lines.is_empty() and now - int(_log_lines[0]["at"]) > 14000:
		_log_lines.pop_front()
		changed = true
	if changed: _render_log()
