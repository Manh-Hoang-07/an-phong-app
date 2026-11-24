extends Node
## Lớp HTTP: gọi /api/*, gửi lại theo rid khi rớt mạng, parse {ok, events, patch, base, rev}.
## Mọi thao tác với server đi qua đây. Không khởi tạo HTTPRequest trong vòng lặp.

signal action_done(result: Dictionary, type: String)
signal request_failed(error: String, type: String)
signal offline_changed(offline: bool)
signal busy_changed(busy: bool)

const KEEP_TRYING := ["kills", "save"]  # các loại hành động không bỏ cuộc khi mất mạng
const RETRY_WAIT := [0.3, 0.7, 1.5, 3.0, 5.0]

var _rid_base: String = ""
var _rid_seq: int = 0
var _offline: bool = false
var _queue: Array[Dictionary] = []
var _busy: bool = false
# Giữ HTTPRequest lại sau khi await. Gọi queue_free() ngay trong coroutine đang
# resume tu HTTPRequest::_request_done lam crash tren iOS/arm64 release build
# (EXC_BAD_ACCESS trong GDScriptFunctionState::resume).
var _spent: Array[HTTPRequest] = []

func _ready() -> void:
	_rid_base = str(Time.get_unix_time_from_system()).md5_text().substr(0, 6)

func _next_rid() -> String:
	_rid_seq += 1
	return "%s-%d" % [_rid_base, _rid_seq]

func _cleanup_spent() -> void:
	# Chi giu 8 request gan nhat. Khong free request vua resume trong _request_done.
	while _spent.size() > 8:
		var r: HTTPRequest = _spent.pop_front()
		if is_instance_valid(r): r.queue_free()

func _exit_tree() -> void:
	for r in _spent:
		if is_instance_valid(r): r.queue_free()
	_spent.clear()

func _set_offline(v: bool) -> void:
	if v == _offline: return
	_offline = v
	offline_changed.emit(v)

## Gọi API chung. Trả Dictionary (rỗng nếu lỗi parse).
func request(path: String, body: Variant = null, method: String = "") -> Dictionary:
	var url: String = Settings.server_url + path
	var req := HTTPRequest.new()
	add_child(req)
	req.timeout = 12.0   # không có timeout thì server không tới được sẽ treo vô hạn
	var headers := ["Content-Type: application/json", "Accept: application/json"]
	if not Settings.session.is_empty():
		headers.append("Cookie: " + Settings.cookie_header())
	var verb := HTTPClient.METHOD_GET
	if method == "POST": verb = HTTPClient.METHOD_POST
	elif method == "GET": verb = HTTPClient.METHOD_GET
	elif method != "": verb = HTTPClient.METHOD_PATCH
	elif body != null: verb = HTTPClient.METHOD_POST
	var payload := ""
	if body != null:
		payload = JSON.stringify(body)
	var err := req.request(url, headers, verb, payload if body != null else "")
	if err != OK:
		_spent.append(req)
		return {"ok": false, "error": "Không gửi được yêu cầu: %s" % err}
	# await là cơ chế chính thức của Godot 4 cho HTTPRequest
	var response: Array = await req.request_completed
	# KHÔNG queue_free() ở đây: coroutine đang resume trong HTTPRequest::_request_done.
	# Giữ request trong _spent; dọn khi vượt ngưỡng (xem _cleanup_spent) hoac luc thoat.
	_spent.append(req)
	_cleanup_spent()
	if response.size() < 4:
		return {"ok": false, "error": "Phản hồi không hợp lệ"}
	var result: int = int(response[0])
	var code: int = int(response[1])
	var raw: PackedByteArray = response[3] if typeof(response[3]) == TYPE_PACKED_BYTE_ARRAY else PackedByteArray()
	# Server đặt phiên qua Set-Cookie; trích ap_session để dùng cho request sau và WebSocket.
	var resp_headers: PackedStringArray = response[2] if typeof(response[2]) == TYPE_PACKED_STRING_ARRAY else PackedStringArray()
	for h in resp_headers:
		var low := h.to_lower()
		if low.begins_with("set-cookie:") and low.contains("ap_session="):
			var parts := h.split(";")[0].split("=", true, 1)
			if parts.size() == 2 and parts[1] != "":
				Settings.set_session(parts[1].strip_edges())
	if result != HTTPRequest.RESULT_SUCCESS:
		return {"ok": false, "error": "Lỗi mạng (%d)" % result}
	var text := raw.get_string_from_utf8()
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return {"ok": false, "error": "Server trả dữ liệu không hợp lệ (%d)" % code}
	var data: Dictionary = parsed
	if code >= 502 and code <= 504:
		return {"ok": false, "error": "gateway %d" % code, "retry": true}
	if not data.has("error") and (code < 200 or code >= 300):
		data["error"] = "Lỗi kết nối (%d)" % code
	return data

## Đăng nhập / đăng ký. Server hiện chỉ trả Set-Cookie; nếu có `token` trong JSON thì lưu luôn.
func login(username: String, password: String) -> Dictionary:
	var r := await request("/api/login", {"username": username, "password": password})
	if r.get("ok") == true and r.has("token"):
		Settings.set_token(str(r["token"]))
	return r

func register(username: String, password: String, char_name: String) -> Dictionary:
	var r := await request("/api/register", {"username": username, "password": password, "charName": char_name})
	if r.get("ok") == true and r.has("token"):
		Settings.set_token(str(r["token"]))
	return r

func me() -> Dictionary:
	return await request("/api/me")

func version() -> Dictionary:
	return await request("/api/version")

func logout() -> Dictionary:
	var r := await request("/api/logout", {})
	Settings.set_token("")
	return r

## Gửi một hành động, tự gửi lại cùng rid khi mất mạng. Không áp patch ở đây — Game làm.
func send_action(type: String, params: Dictionary = {}) -> Dictionary:
	var rid := _next_rid()
	var body := params.duplicate()
	body["type"] = type
	body["rid"] = rid
	var keep: bool = type in KEEP_TRYING
	for attempt in range(6):
		var data := await request("/api/action", body)
		if not data.get("retry", false) and not (data.has("error") and str(data["error"]).begins_with("Lỗi mạng")):
			_set_offline(false)
			return data
		_set_offline(true)
		if not keep and attempt >= 4:
			return {"ok": false, "error": "Mất kết nối tới server."}
		await get_tree().create_timer(RETRY_WAIT[mini(attempt, RETRY_WAIT.size() - 1)]).timeout
	return {"ok": false, "error": "Mất kết nối tới server."}

## Hàng đợi: các hành động đi lần lượt để server thấy đúng thứ tự (giống Net.action của web).
func action(type: String, params: Dictionary = {}, opts: Dictionary = {}) -> Dictionary:
	_queue.append({"type": type, "params": params, "opts": opts})
	if _busy: return {}
	_busy = true
	busy_changed.emit(true)
	while not _queue.is_empty():
		var item: Dictionary = _queue.pop_front()
		var t: String = item["type"]
		var data := await send_action(t, item["params"])
		# Ưu tiên nhân vật đầy đủ (lỗi hoàn tác / gửi lại rid) — đồng bộ lại hoàn toàn
		if data.has("player"):
			Game.set_player(data["player"], false)
			if data.has("rev"): Game.rev = int(data["rev"])
		elif data.get("ok") != false and data.has("rev"):
			if Game.has_player() and data.get("base") == Game.rev:
				Game.rev = int(data["rev"])
				if typeof(data.get("patch", null)) == TYPE_DICTIONARY: Game.apply_patch(data["patch"])
			else:
				# Lệch rev: tải lại cả nhân vật như web
				var fresh := await me()
				if fresh.has("player"):
					Game.set_player(fresh["player"], false)
					Game.rev = int(fresh.get("rev", 0))
		# Sự kiện kèm phản hồi (msg, levelup, loot, map...) phát cho giao diện / thế giới xử lý.
		if data.get("ok") != false and data.has("events"):
			Game.on_events(data["events"])
		action_done.emit(data, t)
	_busy = false
	busy_changed.emit(false)
	return {}
