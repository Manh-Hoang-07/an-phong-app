extends SceneTree
## Test chiến đấu chạy thật trong scene World (không cần server): đếm gói `hit` đi vào hàng đợi Socket.
##   godot --path . --rendering-driver opengl3 --script res://tools/combat_test.gd
## Kiểm: số đòn / hình dạng vùng của từng kiểu kỹ năng, đòn thường theo vũ khí, quái đánh người,
## HP không bị patch ghi đè, bạn đồng hành tự đánh.

var _w: Node2D = null
var _frames := 0
var _stage := 0
var _fails := 0
var _mob_id := ""

func _initialize() -> void:
	# KHÔNG được nối server thật: xoá thông tin đăng nhập trong bộ nhớ (không ghi đĩa)
	var st = root.get_node("Settings")
	st.token = ""
	st.session = ""
	root.get_node("Data").load_local()
	var d: Dictionary = root.get_node("Data").MONSTERS
	for k in d.keys():
		var m: Dictionary = d[k]
		if not bool(m.get("boss", false)) and not bool(m.get("passive", false)) and int(m.get("atk", 0)) > 0:
			_mob_id = str(k); break
	root.get_node("Game").set_player(_player())
	change_scene_to_file("res://src/scenes/World.tscn")

func _player() -> Dictionary:
	var skills := {}
	for sid in root.get_node("Data").SKILLS.keys(): skills[sid] = 10
	return {
		"name": "Test", "level": 60, "rank": "D", "school": "kiem_si", "map": "lang", "x": 640, "y": 300, "hp": 2000, "mp": 900, "sta": 500, "exp": 0,
		"gold": 0, "perks": [], "titles": [], "kyNguyen": {"owned": [], "active": []}, "points": {"str": 20, "vit": 20, "agi": 20, "spi": 20}, "freePoints": 0,
		"skillSlots": [null, null, null, null, null, null, null, null], "superUlts": {}, "skills": skills,
		"mounts": {"active": null, "owned": ["soi_xam"], "skill": "bite", "skills": {"soi_xam": "bite"}, "summoned": ["soi_xam"]},
		"summons": {"enabled": false, "states": {}}, "shadows": {"roster": [], "active": [], "enabled": false},
		"bag": [], "equip": {"weapon": {"id": "kiem_sat", "plus": 0}}, "quest": {"step": 2, "state": "active", "progress": {}},
	}

func _hits() -> Array:
	var out: Array = []
	for s in root.get_node("Socket")._outbox:
		var j = JSON.parse_string(str(s))
		if typeof(j) == TYPE_DICTIONARY and str(j.get("t", "")) == "hit": out.append(j)
	return out

func _reset() -> void:
	root.get_node("Socket")._outbox.clear()

func _mob_at(u: int, dx: float, dy: float = 0.0) -> Node2D:
	var p: Vector2 = _w._player.position
	_w._spawn_mob({"u": u, "id": _mob_id, "x": p.x + dx, "y": p.y + 30.0 + dy, "f": 1, "hp": 99999, "mh": 99999, "al": 1, "st": 0, "fl": 0}, false)
	var n: Node2D = _w._mobs[u]
	n.position = Vector2(p.x + dx, p.y + 30.0 + dy)
	return n

func _clear_mobs() -> void:
	for u in _w._mobs.keys():
		var n: Node = _w._mobs[u]
		if is_instance_valid(n): n.queue_free()
	_w._mobs.clear()

func _check(name: String, ok: bool, detail: String = "") -> void:
	if not ok: _fails += 1
	print(("OK   " if ok else "FAIL ") + name + ("  " + detail if detail != "" else ""))

func _skill_of(stype: String) -> String:
	var sk: Dictionary = root.get_node("Data").SKILLS
	var ids := sk.keys()
	ids.sort()
	for id in ids:
		var s: Dictionary = sk[id]
		if str(s.get("type", "")) == stype and not bool(s.get("ult", false)): return str(id)
	return ""

func _process(_d: float) -> bool:
	_frames += 1
	match _frames:
		2: root.get_node("Socket").stop()
		30: _w = current_scene; root.get_node("Socket").stop(); _t_basic()
		50: _t_shapes()
		90: _t_projectile()
		170: _t_projectile_check(); _t_spread()
		250: _t_spread_check(); _t_bow()
		330: _t_bow_check(); _t_rain(); 
		450: _t_rain_check(); _t_companion()
		560:
			_t_companion_check()
			print("combat_test xong, fail=", _fails)
			quit(1 if _fails > 0 else 0)
	return false

func _setup(facing: int = 1) -> void:
	_clear_mobs(); _reset()
	_w._dead = false
	_w._facing = facing
	_w._player.position.x = 640.0

func _t_basic() -> void:
	var G = root.get_node("Game")
	print("--- cơ bản: vị trí ", _w._player.position, " quái=", _mob_id, " wtype=", G.stats.get("wtype"))
	G.hp = 1500
	G.apply_patch({"set": {"hp": 100, "mp": 5}, "del": []})
	_check("patch không ghi đè HP", G.hp == 1500, "hp=%d" % G.hp)
	_check("stats.speed > 190", float(G.stats.get("speed", 0)) > 190.0, "speed=%s" % str(G.stats.get("speed")))
	_setup()
	var m := _mob_at(1, 20.0)
	var hp0: int = G.hp
	_w._invuln_until = 0
	_w._hurt_player(m)
	_check("quái đánh làm mất máu", G.hp < hp0, "%d -> %d" % [hp0, G.hp])
	_w._invuln_until = 0
	var hp1: int = G.hp
	_w._hurt_player(m, 1.5, false)
	_check("giậm đất x1.5 gây đau", G.hp < hp1, "-%d" % (hp1 - G.hp))
	G.hp = 1500

func _t_shapes() -> void:
	var G = root.get_node("Game")
	var data = root.get_node("Data")
	_setup()
	_mob_at(20, 150.0); _mob_at(21, -90.0)
	var id := _skill_of("aoe")
	var sk: Dictionary = data.skill_eff(G.player, id)
	_w._skill_damage(id, sk, "aoe", 1)
	var f := 0; var b := 0
	for h in _hits():
		if int(h["u"]) == 20: f += 1
		if int(h["u"]) == 21: b += 1
	_check("aoe %s (r=%s) trúng cả quái sau lưng" % [id, str(sk.get("radius"))], b >= 1, "trước=%d sau=%d" % [f, b])
	_setup()
	_mob_at(22, 60.0)
	id = _skill_of("melee")
	sk = data.skill_eff(G.player, id)
	_w._skill_damage(id, sk, "melee", 1)
	_check("melee nhát đầu trúng ngay", _hits().size() >= 1, "hits(sk)=%s finisher=%s" % [str(sk.get("hits")), str(sk.get("finisher"))])
	_setup()
	_mob_at(23, 140.0)
	id = _skill_of("sword_fall")
	if id != "":
		sk = data.skill_eff(G.player, id)
		_w._skill_damage(id, sk, "sword_fall", 1)

func _t_projectile() -> void:
	var G = root.get_node("Game")
	_setup()
	_mob_at(40, 220.0)
	var id := _skill_of("projectile")
	var sk: Dictionary = root.get_node("Data").skill_eff(G.player, id)
	_w._skill_damage(id, sk, "projectile", 1)
	print("--- projectile ", id, " count=", sk.get("count"), " range=", sk.get("range"), " pierce=", sk.get("pierce"))

func _count_u(u: int) -> int:
	var n := 0
	for h in _hits():
		if int(h["u"]) == u: n += 1
	return n

func _t_projectile_check() -> void:
	var G = root.get_node("Game")
	var sk: Dictionary = root.get_node("Data").skill_eff(G.player, _skill_of("projectile"))
	var want := maxi(1, int(sk.get("count", 1)))
	_check("projectile bắn đủ %d viên, mỗi viên trúng 1 lần" % want, _count_u(40) == want, "hits=%d" % _count_u(40))

func _t_spread() -> void:
	var G = root.get_node("Game")
	_setup()
	_mob_at(41, 120.0)
	var id := _skill_of("spread")
	var sk: Dictionary = root.get_node("Data").skill_eff(G.player, id)
	_w._skill_damage(id, sk, "spread", 1)
	print("--- spread ", id, " count=", sk.get("count"))

func _t_spread_check() -> void:
	_check("spread: quái gần trúng nhiều viên", _count_u(41) >= 2, "hits=%d" % _count_u(41))

func _t_bow() -> void:
	var G = root.get_node("Game")
	G.player["equip"] = {"weapon": {"id": "cung_go", "plus": 0}}
	G.recalc_stats()
	_setup()
	_mob_at(50, 250.0)
	_w._next_attack = 0
	_w._on_attack()
	print("--- wtype ", G.stats.get("wtype"), " đạn=", _w._projs.size())
	_check("cung có đạn bay", _w._projs.size() > 0)

func _t_bow_check() -> void:
	_check("mũi tên trúng quái xa 250px", _count_u(50) == 1, "hits=%d" % _count_u(50))

func _t_rain() -> void:
	var G = root.get_node("Game")
	_setup()
	var id := _skill_of("arrow_rain")
	if id == "": return
	var sk: Dictionary = root.get_node("Data").skill_eff(G.player, id)
	var cx: float = 640.0 + float(sk.get("width", 300)) * 0.5 + 30.0
	for i in range(7): _mob_at(60 + i, cx - 640.0 + float(i - 3) * 40.0)
	_w._skill_damage(id, sk, "arrow_rain", 1)
	print("--- arrow_rain ", id, " arrows=", sk.get("arrows"), " width=", sk.get("width"))

func _t_rain_check() -> void:
	var G = root.get_node("Game")
	var sk: Dictionary = root.get_node("Data").skill_eff(G.player, _skill_of("arrow_rain"))
	var total := _hits().size()
	var arrows := int(sk.get("arrows", 1))
	_check("arrow_rain: số đòn xấp xỉ số mũi tên (x mục tiêu đứng chồng)", total >= arrows, "hits=%d arrows=%d" % [total, arrows])

func _t_companion() -> void:
	_setup()
	_w._assist.sync()
	_mob_at(70, 150.0)
	_w._last_hit_uid = 70
	_w._last_hit_at = Time.get_ticks_msec()
	print("--- bạn đồng hành: units=", _w._assist.units.keys())
	_check("thú đồng hành được tạo", _w._assist.units.size() == 1)

func _t_companion_check() -> void:
	var n := 0
	for h in _hits():
		if str(h.get("src", "")) == "pet": n += 1
	_check("thú tự đánh quái (src=pet)", n >= 1, "gói pet=%d" % n)
