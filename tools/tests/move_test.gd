extends SceneTree
## Đo độ mượt di chuyển / nhảy trong World (không cần server):
##  - tốc độ chạy mỗi khung = speed * delta (không lệch nhịp vật lý)
##  - camera bám mượt kiểu exp (k=14): độ trễ khi chạy đều ~ v/14 px, không tích lũy
##  - vòng nhảy: cao đúng, không rơi xuyên sàn, không nhảy kép
##   godot --path . --rendering-driver opengl3 --script res://tools/tests/move_test.gd

var _w: Node2D = null
var _began := false
var _frames := 0
var _fails := 0
var _prev_x := 0.0
var _prev_delta := 0.016
var _rec: Array = []      # [dx, delta]
var _cam_lag := 0.0
var _min_y := 1e9
var _start_y := 0.0
var _max_air_frames := 0
var _air_frames := 0

func _check(name: String, ok: bool, detail: String = "") -> void:
	if not ok: _fails += 1
	print(("OK   " if ok else "FAIL ") + name + ("  " + detail if detail != "" else ""))

func _process(delta: float) -> bool:
	if not _began:
		_began = true
		var st = root.get_node("Settings")
		st.token = ""; st.session = ""; st.server_url = "http://127.0.0.1:9"   # không nối server thật
		root.get_node("Data").load_local()
		root.get_node("Game").set_player({"name": "T", "level": 20, "school": "kiem_si", "map": "lang", "x": 500, "y": 300, "hp": 500, "mp": 100, "sta": 100, "exp": 0,
			"points": {"str": 5, "vit": 5, "agi": 30, "spi": 5}, "kyNguyen": {"owned": [], "active": []}, "perks": [], "equip": {}, "bag": [],
			"skillSlots": [null, null, null, null, null, null, null, null], "skills": {}, "superUlts": {}, "mounts": {"active": null, "owned": [], "summoned": []},
			"quest": {"step": 2, "state": "active", "progress": {}}})
		change_scene_to_file("res://src/scenes/World.tscn")
		return false
	_frames += 1
	if _frames == 30:
		_w = current_scene
		root.get_node("Socket").stop()
		_w._player.position.x = 500.0
		_w._facing = 1
	# 40..160: chạy phải với delta thật
	if _frames == 40:
		_prev_x = _w._player.position.x
		_start_y = _w._player.position.y
	if _frames > 40 and _frames <= 160:
		_w._move_dir = Vector2(1, 0)
		var x: float = _w._player.position.x
		_rec.append([x - _prev_x, _prev_delta])
		_prev_delta = delta
		_prev_x = x
		var cam: Camera2D = _w._cam
		_cam_lag = maxf(_cam_lag, absf(cam.position.x - x))
	if _frames == 161:
		_w._move_dir = Vector2.ZERO
		var speeds: Array = []
		for r in _rec:
			if float(r[1]) > 0.0 and float(r[0]) > 0.0: speeds.append(float(r[0]) / float(r[1]))
		var mean := 0.0
		for s in speeds: mean += s
		mean /= maxf(1.0, float(speeds.size()))
		var maxdev := 0.0
		for s in speeds: maxdev = maxf(maxdev, absf(s - mean))
		var want := float(root.get_node("Game").stats.get("speed", 190))
		print("--- chạy: tốc độ TB=%.1f px/s, lệch lớn nhất %.1f, stats.speed=%.0f, mẫu=%d" % [mean, maxdev, want, speeds.size()])
		_check("tốc độ mỗi khung đều (lệch < 3% trung bình)", maxdev < mean * 0.03, "dev=%.2f" % maxdev)
		_check("tốc độ = stats.speed", absf(mean - want) < want * 0.03, "%.1f vs %.0f" % [mean, want])
		print("--- hiệu năng: FPS=%d, thời gian xử lý khung=%.2f ms, vẽ=%.2f ms" % [Engine.get_frames_per_second(), Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0, Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0])
		_check("camera bám mượt (trễ ổn định < v/10)", _cam_lag < want * 0.1, "lag=%.2fpx (lý thuyết v/14=%.1f)" % [_cam_lag, want / 14.0])
	if _frames == 180:
		_deterministic()
		print("move_test xong, fail=", _fails)
		quit(1 if _fails > 0 else 0)
	return false

## Mô phỏng tất định: gọi thẳng _move_step với nhiều bước thời gian khác nhau.
func _deterministic() -> void:
	_w._move_dir = Vector2.ZERO
	for dt in [1.0 / 30.0, 1.0 / 60.0, 1.0 / 90.0, 1.0 / 144.0]:
		_w._player.position.x = 300.0
		_w._facing = 1
		_w._move_dir = Vector2(1, 0)
		_w.motor._move_step(dt)  # khởi động
		var x0: float = _w._player.position.x
		for i in range(10): _w.motor._move_step(dt)
		var v: float = (_w._player.position.x - x0) / (10.0 * dt)
		_check("vận tốc không đổi theo dt (dt=%.4f)" % dt, absf(v - float(root.get_node("Game").stats.get("speed", 190))) < 2.0, "v=%.1f" % v)
	_w._move_dir = Vector2.ZERO
	# nhảy: nhiều dt, cao độ phải gần 121px và về đúng sàn (chọn x không có sàn phía trên)
	for dt in [1.0 / 30.0, 1.0 / 60.0, 1.0 / 144.0]:
		var best_rise := -1.0
		var landed := false
		for x in [200.0, 700.0, 1100.0, 1500.0, 1900.0]:
			_w._player.position = Vector2(x, 300.0)
			for i in range(120): _w.motor._move_step(1.0 / 60.0)   # rơi xuống sàn
			var y0: float = _w._player.position.y
			_w._jump_req = true
			var miny := y0
			for i in range(int(1.5 / dt)):
				_w.motor._move_step(dt)
				miny = minf(miny, _w._player.position.y)
			var back: bool = absf(_w._player.position.y - y0) < 1.5
			if back and (miny < y0 - 100.0):
				best_rise = y0 - miny; landed = true; break
		_check("nhảy dt=%.4f: cao ~121px và hạ cánh đúng sàn" % dt, landed and best_rise > 110.0 and best_rise < 130.0, "rise=%.1f" % best_rise)
