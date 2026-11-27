extends "res://src/scenes/world/WorldPart.gd"
## Mạng: kết quả action, sự kiện server, chat, gói người chơi/quái.
## Hệ thống của World (w = World). Trạng thái riêng khai báo ngay dưới; trạng thái dùng chung đọc qua thuộc tính chuyển tiếp.

## Hệ số sát thương đòn đặc biệt của trùm theo web (boss.js): giậm đất x1.5, các chiêu theo kiểu `style`.
const BOSS_STYLE_MUL := {"water": 0.8, "ice": 1.3, "void": 1.1, "moon": 0.9}

# Trạng thái riêng
var _reload_queued := false
var _other_fx_at := 0
var _other_fx_n := 0

# Trạng thái dùng chung (lưu ở World)
var _remote: Node2D:
	get: return w._remote if is_instance_valid(w._remote) else null
	set(x): w._remote = x
var _mob_layer: Node2D:
	get: return w._mob_layer if is_instance_valid(w._mob_layer) else null
	set(x): w._mob_layer = x
var _fx: Node2D:
	get: return w._fx if is_instance_valid(w._fx) else null
	set(x): w._fx = x
var _player: Node2D:
	get: return w._player if is_instance_valid(w._player) else null
	set(x): w._player = x
var _hud_node: Node:
	get: return w._hud_node if is_instance_valid(w._hud_node) else null
	set(x): w._hud_node = x
var _skill_fx: Node:
	get: return w._skill_fx if is_instance_valid(w._skill_fx) else null
	set(x): w._skill_fx = x
var _fade: ColorRect:
	get: return w._fade if is_instance_valid(w._fade) else null
	set(x): w._fade = x
var _fxs: Node2D:
	get: return w._fxs if is_instance_valid(w._fxs) else null
	set(x): w._fxs = x
var _mob_script: Script:
	get: return w._mob_script if is_instance_valid(w._mob_script) else null
	set(x): w._mob_script = x
var _players: Dictionary:
	get: return w._players
	set(x): w._players = x
var _mobs: Dictionary:
	get: return w._mobs
	set(x): w._mobs = x
var _loots: Dictionary:
	get: return w._loots
	set(x): w._loots = x
var _map_id: String:
	get: return w._map_id
	set(x): w._map_id = x
var _facing: int:
	get: return w._facing
	set(x): w._facing = x
var _anim: String:
	get: return w._anim
	set(x): w._anim = x
var _slow_until: int:
	get: return w._slow_until
	set(x): w._slow_until = x
var _dead: bool:
	get: return w._dead
	set(x): w._dead = x
var _changing: bool:
	get: return w._changing
	set(x): w._changing = x
var _hud_dirty: bool:
	get: return w._hud_dirty
	set(x): w._hud_dirty = x
var _pickup_pending: Dictionary:
	get: return w._pickup_pending
	set(x): w._pickup_pending = x
var _pickup_lid: String:
	get: return w._pickup_lid
	set(x): w._pickup_lid = x
var _loot_store: Dictionary:
	get: return w._loot_store
	set(x): w._loot_store = x
var _enter_try: int:
	get: return w._enter_try
	set(x): w._enter_try = x

# Hàm của hệ thống khác
func _fade_in() -> void:
	w._fade_in()

func _setup_player_sprite() -> void:
	w._setup_player_sprite()

func _load_player_map(arrive: String) -> void:
	w.map._load_player_map(arrive)

func _sync_pet() -> void:
	w.pets._sync_pet()

func _process(delta: float) -> void:
	w._process(delta)

func _server_anim(a: String) -> String:
	return w.motor._server_anim(a)

func _hp_pct() -> int:
	return w.motor._hp_pct()

func _hurt_player(m: Node2D, mult: float = 1.0, enrage_scale: bool = true) -> void:
	w.life._hurt_player(m, mult, enrage_scale)

func _on_my_kill() -> void:
	w.life._on_my_kill()

func _queue_kill(kid: String) -> void:
	w.life._queue_kill(kid)

func _hex(s: String, fallback: Color) -> Color:
	return w.loot._hex(s, fallback)

func _add_loot(data: Dictionary, animate: bool) -> void:
	w.loot._add_loot(data, animate)

func _nearest_shop_npc() -> String:
	return w.loot._nearest_shop_npc()

func _nearest_npc() -> String:
	return w.loot._nearest_npc()

func shake(strength: float, duration: float) -> void:
	w.shake(strength, duration)

func _refresh_hud() -> void:
	w._refresh_hud()

func _apply_form_visual(on: bool, quiet: bool = true) -> void:
	w.form._apply_form_visual(on, quiet)

func _apply_loot_channel(ch: int) -> void:
	w.loot._apply_loot_channel(ch)

func _on_action_done(data: Dictionary, type: String) -> void:
	if type == "save" or type == "kills" or type == "talk":
		if data.has("error") and type == "kills": pass
		return
	if type == "pickup":
		# Đồ được dọn khi nhận event 'picked'; lỗi thì cho nhặt lại.
		var plid := _pickup_lid
		_pickup_pending.erase(plid)
		if data.has("error"):
			if str(data["error"]) == "Món đồ đã biến mất." and _loots.has(plid):
				(_loots[plid] as Node).queue_free()
				_loots.erase(plid)
			if _hud_node: _hud_node.log(str(data["error"]), Color(1, 0.55, 0.5))
		return
	if data.has("error"):
		if _hud_node:
			_hud_node.log("Lỗi: " + str(data["error"]), Color(1, 0.4, 0.4))
			_hud_node.toast(str(data["error"]), "error")
		if type in ["change_map", "teleport"]:
			_changing = false
			create_tween().tween_property(_fade, "modulate:a", 0.0, 0.2)
		elif type == "die":
			_changing = false
			_dead = false
			Game.hp = maxi(1, int(Game.stats.get("maxHp", 100) * 0.5))
			_hud_dirty = true
		return
	if type in ["change_map", "teleport", "die", "respawn_choice"]:
		_reload_after_move(type == "die")
		return
	if type == "mount_set": _sync_pet()
	if _hud_node:
		_hud_node.refresh_panel()
		_hud_node.refresh_dialog()
	_hud_dirty = true

func _reload_after_move(from_death: bool) -> void:
	if _reload_queued: return
	_reload_queued = true
	_changing = true
	var tw := create_tween()
	tw.tween_property(_fade, "modulate:a", 1.0, 0.18)
	await tw.finished
	_reload_queued = false
	if not is_inside_tree(): return
	if from_death:
		if Game.hp <= 0: Game.hp = maxi(1, int(Game.player.get("hp", int(Game.stats.get("maxHp", 100) * 0.5))))
		if Game.mp < 0: Game.mp = 0
	var arrive := str(Game.player.get("arrive", "")) if Game.player.get("arrive", null) != null else ""
	_setup_player_sprite()
	_load_player_map(arrive)
	_hud_node.hide_death()
	_hud_node.close_panel()
	_refresh_hud()
	_fade_in()

func _on_event(ev: Dictionary) -> void:
	var t := str(ev.get("t", ""))
	if t in ["exec", "fusion", "manaburst", "allin"] and ev.has("sk"):
		if _skill_fx and _skill_fx.has_method("play"):
			_skill_fx.play(t, str(ev["sk"]), _player.position, _facing)
	if _hud_node == null: return
	match t:
		"msg": _hud_node.log(str(ev.get("text", "")), _hex(str(ev.get("color", "")), Color(0.95, 0.88, 0.60)))
		"float":
			var txt := str(ev.get("text", ""))
			if txt.ends_with("xu"): Audio.play("coin")
			# Bùa x2: chỉ hiện icon trên HUD; không hiện số bay / log chat cho dòng kinh nghiệm.
			if not txt.ends_with("kinh nghiệm"):
				FloatText.spawn(_fx, _player.position + Vector2(0, -40), txt, _hex(str(ev.get("color", "")), Color(0.6, 0.95, 0.7)), 15)
				_hud_node.log(txt, Color(0.60, 0.95, 0.70))
		"levelup":
			Audio.play("levelup")
			_fxs.levelup(_player.position)
			_hud_node.flash(Color(1.0, 0.9, 0.5), 0.35)
			_hud_node.banner("THĂNG CẤP · Lv %s" % str(ev.get("level", "?")))
			_hud_node.log("★ Thăng cấp lên Lv %s" % str(ev.get("level", "?")), T.C_GOLD)
			Game.hp = int(Game.stats.get("maxHp", Game.hp)); Game.mp = int(Game.stats.get("maxMp", Game.mp))
		"rank": _hud_node.banner("THỢ SĂN HẠNG %s" % str(ev.get("rank", "?")))
		"queststep":
			Game.quest_hint = "%s: %s %s/%s" % [str(ev.get("name", "Nhiệm vụ")), str(ev.get("label", "")), str(ev.get("have", 0)), str(ev.get("need", 0))]
			_hud_node.toast(Game.quest_hint, "info")
			_hud_dirty = true
		"loot": _add_loot(ev.get("loot", {}), true)
		"picked":
			var lid := str(ev.get("lid", ""))
			Audio.play("pickup")
			_pickup_pending.erase(lid)
			_loot_store.erase(lid)
			if _loots.has(lid):
				var ln: LootNode = _loots[lid]
				_loots.erase(lid)
				FloatText.spawn(_fx, _player.position + Vector2(0, -52), "+" + ln.item_name, Color(1.0, 0.88, 0.5), 14)
				_fxs.pickup(ln.position)
				ln.fly_to(_player.global_position + Vector2(0, -10))
		"map":
			if not _changing or true: _reload_after_move(false)
		"form": _apply_form_visual(bool(ev.get("active", false)))
		"awaken":
			_hud_node.banner("THỨC TỈNH · MỞ KHÓA ẤN MỚI", Color(1.0, 0.7, 0.3))
			_fxs.levelup(_player.position)
		"market": Social.on_market(ev)
		"upgrade": _hud_node.toast("Cường hóa thành công!" if ev.get("ok", true) else "Cường hóa thất bại", "success" if ev.get("ok", true) else "error")
		"side": _hud_node.banner("PHỤ TUYẾN: %s" % str(ev.get("name", "")).to_upper(), T.C_BLUE)
		"mount_new", "perk", "unlock": _hud_node.banner(t.to_upper().replace("_", " "))
	_hud_dirty = true

func _on_chat(text: String) -> void:
	var t := text.strip_edges()
	if t.is_empty(): return
	if t.to_lower() in ["npc an", "ncp an"]:
		Net.action("hidden_chat", {"text": t})
		return
	if t.begins_with("/map"): _hud_node.open_panel("map"); return
	if t.begins_with("/shop"): _hud_node.open_panel("shop", {"npc": _nearest_shop_npc()}); return
	if t.begins_with("/npc"): _hud_node.open_panel("npc", {"id": _nearest_npc()}); return
	if t.begins_with("/w "): Socket.send_chat(t.substr(3), "world"); return
	if t.begins_with("/t ") or t.begins_with("/ds "):
		Socket.send_chat(t.substr(t.find(" ") + 1), "party"); return
	if not Socket.send_chat(t, "map"):
		_hud_node.log("Chưa kết nối máy chủ, tin nhắn sẽ gửi khi có mạng.", Color(1.0, 0.7, 0.5))

func _on_chat_recv(msg: Dictionary) -> void:
	var who := str(msg.get("name", "?"))
	var text := str(msg.get("text", ""))
	if text.is_empty(): return
	var ch := str(msg.get("ch", "map"))
	var tag := "" if ch == "map" else ("[Thế giới] " if ch == "world" else "[Đội] ")
	var col := Color(0.88, 0.92, 1.0) if ch == "map" else (Color(1.0, 0.85, 0.5) if ch == "world" else Color(0.6, 0.95, 0.7))
	if int(msg.get("id", 0)) == Socket.my_id: col = Color(0.75, 0.9, 1.0)
	_hud_node.log("%s%s: %s" % [tag, who, text], col)
	var pid := int(msg.get("id", 0))
	if _players.has(pid): (_players[pid] as RemotePlayer).say(text)

func _on_socket_connected() -> void:
	_enter_try = Time.get_ticks_msec()
	Socket.send_pos(_map_id, _player.position.x, _player.position.y, _facing, _server_anim(_anim), true, _hp_pct())

func _on_players(msg: Dictionary) -> void:
	var t := str(msg.get("t", ""))
	if t in ["msnap", "mspawn", "mhit", "mhp", "mdie", "mdel", "mresp", "mact"]:
		_on_mob_packet(msg); return
	if t in ["party", "party_inv", "trade", "trade_inv", "trade_end", "chlist"]:
		Social.on_message(msg); return
	match t:
		"room":
			for id in _players.keys(): (_players[id] as Node).queue_free()
			_players.clear()
			Social.nearby.clear()
			_apply_loot_channel(int(msg.get("ch", 1)))
			# Đổi khu xong: cập nhật "đang ở Khu n" ngay và xin danh sách mới (trước đây bảng vẫn hiện khu cũ nên phải bấm nhiều lần)
			if not Social.channels.is_empty():
				Social.channels["cur"] = int(msg.get("ch", Social.channels.get("cur", 1)))
				Social.changed.emit("channels")
				Socket.send_chlist()
			for p in msg.get("list", []):
				if typeof(p) == TYPE_DICTIONARY: _add_remote(p)
		"join":
			if typeof(msg.get("p", null)) == TYPE_DICTIONARY: _add_remote(msg["p"])
		"leave":
			var id2 := int(msg.get("id", 0))
			if _players.has(id2):
				(_players[id2] as Node).queue_free()
				_players.erase(id2)
				Social.nearby.erase(id2)
		"snap":
			for e in msg.get("p", []):
				# Mục ngắn [id,x,y] = hướng và hoạt ảnh không đổi; mục đủ [id,x,y,f,a] khi có đổi
				if typeof(e) != TYPE_ARRAY or (e as Array).size() < 3: continue
				var rp: RemotePlayer = _players.get(int(e[0]), null)
				if rp:
					var st := {"x": e[1], "y": e[2]}
					if (e as Array).size() >= 5:
						st["f"] = e[3]
						st["a"] = e[4]
					rp.apply_state(st)
		"look":
			var p2: Dictionary = msg.get("p", {})
			var rp2: RemotePlayer = _players.get(int(p2.get("id", 0)), null)
			if rp2: rp2.apply_look(p2)
		"sys":
			if _hud_node: _hud_node.log(str(msg.get("text", "")), Color(0.75, 0.85, 1.0))

func _add_remote(info: Dictionary) -> void:
	var id := int(info.get("id", 0))
	if id == 0 or id == Socket.my_id or _players.has(id): return
	var rp: RemotePlayer = RemotePlayer.new()
	_remote.add_child(rp)
	rp.setup(info)
	_players[id] = rp
	Social.nearby[id] = {"name": str(info.get("name", "?")), "lv": int(info.get("lv", 1)), "sc": str(info.get("sc", ""))}

func _on_mobs(msg: Dictionary) -> void:
	# Gói đầy đủ khi vào map: dựng lại toàn bộ quái.
	for u in _mobs.keys():
		var n: Node = _mobs[u]
		if is_instance_valid(n): n.queue_free()
	_mobs.clear()
	for info in msg.get("list", []):
		if typeof(info) == TYPE_DICTIONARY: _spawn_mob(info, false)

func _spawn_mob(info: Dictionary, fx: bool) -> void:
	var u := int(info.get("u", 0))
	if u == 0 or _mob_script == null: return
	if _mobs.has(u):
		_apply_mob_full(_mobs[u], info); return
	var node: Node2D = _mob_script.new()
	var mid := str(info.get("id", ""))
	var def: Dictionary = Data.monster(mid)
	node.setup(u, mid, str(def.get("look", "")), str(def.get("sprite", "")))
	_mob_layer.add_child(node)
	_mobs[u] = node
	_apply_mob_full(node, info)
	if fx: node.modulate.a = 0.0; create_tween().tween_property(node, "modulate:a", 1.0, 0.4)

func _apply_mob_full(node: Node2D, info: Dictionary) -> void:
	node.set_target(Vector2(float(info.get("x", 0)), float(info.get("y", 0))), true)
	node.set_facing(int(info.get("f", 1)))
	node.set_hp(int(info.get("hp", 0)), int(info.get("mh", 1)))
	node.set_state(int(info.get("st", 0)))
	node.flags = int(info.get("fl", 0))
	node.enraged = (node.flags & 4) != 0
	if int(info.get("al", 1)) == 1:
		if not node.alive: node.revive()
		node.visible = true
	else:
		node.alive = false
		node.set_process(false)   # mob chết/ẩn khỏi snapshot: khỏi chạy _process mỗi khung
		node.visible = false

func _on_mob_packet(msg: Dictionary) -> void:
	var t := str(msg.get("t", ""))
	match t:
		"msnap":
			for e in msg.get("p", []):
				if typeof(e) != TYPE_ARRAY or (e as Array).size() < 5: continue
				var n: Node2D = _mobs.get(int(e[0]), null)
				if n == null or not n.alive: continue
				n.set_target(Vector2(float(e[1]), float(e[2])))
				n.set_facing(int(e[3]))
				n.set_state(int(e[4]))
				if (e as Array).size() > 5:
					n.flags = int(e[5])
					n.enraged = (int(e[5]) & 4) != 0
		"mspawn":
			if typeof(msg.get("m", null)) == TYPE_DICTIONARY: _spawn_mob(msg["m"], true)
		"mresp":
			var info: Dictionary = msg.get("m", {})
			var n2: Node2D = _mobs.get(int(info.get("u", 0)), null)
			if n2 == null: _spawn_mob(info, true)
			else:
				_apply_mob_full(n2, info)
				n2.revive()
				n2.modulate.a = 0.0
				create_tween().tween_property(n2, "modulate:a", 1.0, 0.4)
		"mhp":
			var n3: Node2D = _mobs.get(int(msg.get("u", 0)), null)
			if n3: n3.set_hp(int(msg.get("hp", 0)), int(msg.get("mh", n3.max_hp)))
		"mhit":
			var n4: Node2D = _mobs.get(int(msg.get("u", 0)), null)
			if n4 == null or not n4.alive: return
			n4.set_hp(int(msg.get("hp", 0)), n4.max_hp)
			var mine := int(msg.get("by", -1)) == Socket.my_id
			if not mine:
				var now := Time.get_ticks_msec()
				if now - _other_fx_at > 1000: _other_fx_at = now; _other_fx_n = 0
				_other_fx_n += 1
				if _other_fx_n > 8: return
			n4.hit_flash()
			_fxs.hit_spark(n4.position + Vector2(0, -n4._height * 0.5), int(msg.get("c", 0)) == 1, int(msg.get("dir", 1)))
			if mine: Audio.play("crit" if int(msg.get("c", 0)) == 1 else "hit")
			var crit := int(msg.get("c", 0)) == 1
			var col := Color(1.0, 0.84, 0.25) if crit else (Color.WHITE if mine else Color(0.69, 0.75, 0.78))
			if Settings.show_damage: FloatText.spawn(_fx, n4.position + Vector2(randf_range(-8, 8), -n4._height - 6.0), ("%d!" if crit else "%d") % int(msg.get("d", 0)), col, 22 if crit else 16)
		"mdie":
			var n5: Node2D = _mobs.get(int(msg.get("u", 0)), null)
			if n5 and n5.alive:
				_fxs.death_poof(n5.position, n5.is_boss)
				n5.die()
				if int(msg.get("fled", 0)) == 1:
					FloatText.spawn(_fx, n5.position + Vector2(0, -60), "Bỏ chạy!", T.C_GOLD, 16)
			var kid := str(msg.get("kid", ""))
			var me := Socket.my_id
			if not kid.is_empty() and me != 0 and (int(msg.get("by", -1)) == me or (msg.get("as", []) as Array).has(me)):
				_queue_kill(kid)
			if int(msg.get("by", -1)) == me and me != 0: _on_my_kill()
		"mact":
			var bm: Node2D = _mobs.get(int(msg.get("u", 0)), null)
			if bm == null or not bm.alive: return
			var dxm := absf(bm.position.x - _player.position.x)
			match str(msg.get("a", "")):
				"slam":
					shake(8.0, 0.35)
					FloatText.spawn(_fx, bm.position + Vector2(0, -90), "Giậm đất!", Color(1.0, 0.6, 0.3), 18)
					if dxm < 230.0 and absf(bm.position.y - _player.position.y) < 120.0: _hurt_player(bm, 1.5, false)
				"special":
					shake(5.0, 0.4)
					FloatText.spawn(_fx, bm.position + Vector2(0, -90), "Tuyệt chiêu!", Color(1.0, 0.4, 0.8), 18)
					if dxm < 300.0 and absf(bm.position.y - _player.position.y) < 160.0:
						_hurt_player(bm, float(BOSS_STYLE_MUL.get(bm.mob_style, 1.0)), false)
						# Trùm Nước / Băng: đòn trúng thì làm chậm người chơi (60% tốc độ)
						if bm.mob_style == "water": _slow_until = Time.get_ticks_msec() + 2600
						elif bm.mob_style == "ice": _slow_until = Time.get_ticks_msec() + 3000
				"enrage":
					FloatText.spawn(_fx, bm.position + Vector2(0, -90), "Phẫn nộ!", Color(1.0, 0.3, 0.3), 20)
					shake(4.0, 0.3)
		"mdel":
			var u := int(msg.get("u", 0))
			if _mobs.has(u):
				(_mobs[u] as Node).queue_free()
				_mobs.erase(u)
