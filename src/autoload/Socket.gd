extends Node
## WebSocket /ws: nhận hello/room/mobs/batch/patch/chat..., gửi pos/chat/hit/cast/...
## Tự nối lại theo cấp số nhân, heartbeat bằng gói pos (giống Realtime của web).

signal connected_to_server()
signal disconnected_from_server(code: int)
signal hello(id: int)
signal room(msg: Dictionary)
signal mobs(msg: Dictionary)
signal batch(msg: Dictionary)
signal patch(msg: Dictionary)
signal chat(msg: Dictionary)
signal players(msg: Dictionary)
signal message_received(msg: Dictionary)

const MAX_QUEUE := 256

var _peer := WebSocketPeer.new()
var _running: bool = false
var _retry: int = 0
var _reconnect_at: int = 0
var _connect_started: int = 0
var _close_handled: bool = false
var last_close_code: int = 0
var connect_attempts: int = 0
var rx_count: int = 0
var mobs_received: bool = false
var _outbox: Array[String] = []
var _heartbeat_at: int = 0
var _pos_state: Dictionary = {}
var my_id: int = 0
var channel: int = 1
var online: bool = false

func _ready() -> void:
	set_process(false)

func start() -> void:
	_running = true
	_connect()

func stop() -> void:
	_running = false
	online = false
	_peer.close(1000, "thoát app")
	mobs_received = false
	set_process(false)

func _connect() -> void:
	if not _running: return
	# Không đưa token vào query string (lọt vào log Nginx/proxy/history).
	# Server nhận phiên qua Cookie header ở handshake — giữ nguyên bên dưới.
	var url: String = Settings.ws_url()
	_peer = WebSocketPeer.new()
	_peer.inbound_buffer_size = 1 << 20
	_peer.outbound_buffer_size = 1 << 18
	_peer.max_queued_packets = 4096
	# Cookie header lúc handshake: đây là đường xác thực WS chính thức.
	if not Settings.session.is_empty():
		_peer.handshake_headers = PackedStringArray(["Cookie: " + Settings.cookie_header()])
	_connect_started = Time.get_ticks_msec()
	_close_handled = false
	connect_attempts += 1
	print("[WS] noi ", Settings.ws_url())
	var err := _peer.connect_to_url(url)
	set_process(true)
	if err != OK:
		_close_handled = true
		_schedule_reconnect()

func _schedule_reconnect() -> void:
	var wait: int = mini(10000, int(1000 * pow(1.6, _retry)))
	_retry += 1
	_reconnect_at = Time.get_ticks_msec() + wait

func _process(_delta: float) -> void:
	_peer.poll()
	var state: int = _peer.get_ready_state()
	if state == WebSocketPeer.STATE_OPEN:
		if not online:
			online = true
			print("[WS] MO ket noi")
			_retry = 0
			_pos_state.clear()   # vào lại phòng ở gói pos kế tiếp
			connected_to_server.emit()
		_flush()
		_heartbeat()
		while _peer.get_available_packet_count() > 0:
			var raw := _peer.get_packet()
			var text := raw.get_string_from_utf8()
			var parsed: Variant = JSON.parse_string(text)
			if typeof(parsed) != TYPE_DICTIONARY: continue
			rx_count += 1
			_dispatch(parsed)
	elif state == WebSocketPeer.STATE_CLOSED:
		var code := _peer.get_close_code()
		if online:
			online = false
			disconnected_from_server.emit(code)
		if last_close_code != code or online == false and _close_handled == false: print("[WS] DONG code=", code, " reason=", _peer.get_close_reason())
		last_close_code = code
		if not _close_handled:
			_close_handled = true
			_schedule_reconnect()
		# 4001: tài khoản mở ở nơi khác; 4003: phiên hết hạn → không nối lại
		if code != 4001 and code != 4003 and _running and Time.get_ticks_msec() >= _reconnect_at:
			_connect()
	elif state == WebSocketPeer.STATE_CLOSING:
		pass
	else:  # CONNECTING
		# Quá 15 giây kể từ lúc BẮT ĐẦU nối mà chưa mở được thì thử lại (trước đây so với _reconnect_at=0 nên bị ngắt ngay).
		if Time.get_ticks_msec() - _connect_started >= 15000:
			_peer.close()
			_schedule_reconnect()

func _dispatch(m: Dictionary) -> void:
	var t := str(m.get("t", ""))
	if rx_count < 12 or t == "mobs" or t == "room": print("[WS] nhan t=", t, " size=", str(m).length())
	message_received.emit(m)
	# 'batch': server gộp nhiều gói quái cùng nhịp — mở ra theo đúng thứ tự
	if t == "batch":
		var list: Array = m.get("l", [])
		for x in list:
			if typeof(x) == TYPE_DICTIONARY: _dispatch(x)
		batch.emit(m)
		return
	match t:
		"hello":
			my_id = int(m.get("id", 0)); hello.emit(my_id)
		"room":
			channel = int(m.get("ch", 1)); room.emit(m)
		"mobs":
			mobs_received = true
			mobs.emit(m)
		"patch":
			Game.apply_push_patch(m)
			patch.emit(m)
		"chat": chat.emit(m)
		"who", "join", "leave", "snap", "look", "msnap", "mspawn", "mhit", "mhp", "mdie", "mdel", "mresp", "mact", "sys", "chlist": players.emit(m)
		"party", "party_inv", "trade", "trade_inv", "trade_end": players.emit(m)
		_: pass

## Đưa tin vào hàng đợi; gửi khi kết nối sẵn sàng.
func send(obj: Dictionary) -> bool:
	if _outbox.size() >= MAX_QUEUE: _outbox.pop_front()
	_outbox.append(JSON.stringify(obj))
	if online: _flush()
	return online

func _flush() -> void:
	while not _outbox.is_empty() and _peer.get_ready_state() == WebSocketPeer.STATE_OPEN:
		var text: String = _outbox.pop_front()
		var err := _peer.send_text(text)
		if err != OK:
			_outbox.insert(0, text)
			break

func _heartbeat() -> void:
	# Đứng yên thì 1 giây gửi pos một lần để server biết còn sống (theo Realtime.sendPos)
	var now := Time.get_ticks_msec()
	if now - _heartbeat_at < 1000: return
	_heartbeat_at = now
	if not _pos_state.is_empty():
		var m := _pos_state.duplicate()
		m["t"] = "pos"
		send(m)

## Gửi vị trí; có đổi thì gửi ngay, không đổi thì để heartbeat lo.
func send_pos(map_id: String, x: float, y: float, facing: int, anim: String, enter: bool = false, hp_pct: int = -1) -> bool:
	var ix := roundi(x); var iy := roundi(y)
	var same: bool = _pos_state.get("map") == map_id and _pos_state.get("x") == ix \
		and _pos_state.get("y") == iy and _pos_state.get("f") == facing \
		and _pos_state.get("a") == anim and _pos_state.get("h") == hp_pct
	if same and not enter: return false
	var m: Dictionary = {"t": "pos", "map": map_id, "x": ix, "y": iy, "f": facing, "a": anim}
	if hp_pct >= 0: m["h"] = hp_pct
	if enter: m["r"] = 1
	_pos_state = {"map": map_id, "x": ix, "y": iy, "f": facing, "a": anim, "h": hp_pct}
	return send(m)

# ---- Các tin client → server (giữ đúng tên / tham số trong server/realtime/index.js) ----
## ch: "map" (mặc định) | "world" | "party" — khớp server/realtime/index.js onChat.
func send_chat(text: String, ch: String = "map") -> bool:
	return send({"t": "chat", "text": text, "ch": ch})

## Gửi đòn trúng quái. Server đọc: u=uid quái, d=sát thương, k=loại (0 thường/1 kỹ năng/2 tuyệt/3 siêu), id=mã kỹ năng.
## `extra`: hiệu ứng điều khiển kèm đòn — slow / freeze / stun (giây), knock (px), src ("pet" | "shadow" | "player").
func send_hit(target_uid: int, dmg: int, skill_id: String = "", kind: int = -1, dir: int = 1, crit: bool = false, extra: Dictionary = {}) -> bool:
	var k := kind
	if k < 0: k = 1 if not skill_id.is_empty() else 0
	# Khớp payload web (combat.js): c=0, dir=hướng đòn. Server đọc k để chọn trần sát thương.
	var m := {"t": "hit", "u": target_uid, "d": dmg, "c": 1 if crit else 0, "k": k, "dir": dir, "knock": 90}
	for key in ["slow", "freeze", "stun", "knock", "src"]:
		if extra.has(key): m[key] = extra[key]
	if not skill_id.is_empty(): m["id"] = skill_id
	return send(m)

func send_cast(skill_id: String, x: float, y: float, target: int = 0) -> bool:
	return send({"t": "cast", "id": skill_id, "x": roundi(x), "y": roundi(y), "target": target})

func send_exec(kind: String, params: Dictionary = {}) -> bool:
	var m := params.duplicate(); m["t"] = "exec"; m["kind"] = kind
	return send(m)

func send_fusion() -> bool: return send({"t": "fusion"})
func send_manaburst() -> bool: return send({"t": "manaburst"})
func send_allin() -> bool: return send({"t": "allin"})
func send_fusion_end() -> bool: return send({"t": "fusion_end"})
func send_party(action: String, params: Dictionary = {}) -> bool:
	var m := params.duplicate(); m["t"] = "party_" + action
	return send(m)
func send_trade(action: String, params: Dictionary = {}) -> bool:
	var m := params.duplicate(); m["t"] = "trade_" + action
	return send(m)
func send_who() -> bool: return send({"t": "who"})
func send_chlist() -> bool: return send({"t": "chlist"})
func send_channel(n: int) -> bool: return send({"t": "ch", "n": n})
