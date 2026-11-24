extends Node
## Bạn đồng hành tự đánh quái, port từ web (WorldPlayer.companionUpdate / summonUpdate / shadowUpdate):
##  - thú đồng hành (player.mounts.summoned)  -> src "pet"
##  - linh thú của Triệu Hồi Sư (player.summons) -> src "pet"
##  - bóng ma của Tử Linh Thuật Sư (player.shadows) -> src "shadow"
## Sát thương gom 0,5 giây thành một gói mỗi quái (như flushAssistHits) để không vượt ngân sách đòn của server.

const MobScript := preload("res://src/world/MobSprite.gd")
const FloatText := preload("res://src/world/FloatText.gd")

var w: Node2D = null           # World
var units: Dictionary = {}     # key -> {kind, id, node, next_attack, last_combat, cd{}, uid}
var _batch: Dictionary = {}    # "uid|src" -> {u, src, dmg, slow, dir}
var _flush_at := 0
var _next_uid := 910000
var _sync_at := 0

func setup(world: Node2D) -> void:
	w = world

# ------------------------------------------------------------------ Danh sách cần có
func _wanted() -> Dictionary:
	var out := {}
	var p: Dictionary = Game.player
	if p.is_empty(): return out
	for id in w._companion_ids():
		var d: Dictionary = Data.monster(str(id))
		out["c:%s" % id] = {"kind": "pet", "id": str(id), "look": str(d.get("look", "")), "mob": str(id), "sprite": str(d.get("sprite", ""))}
	var sm: Dictionary = Game._as_dict(p.get("summons", {}))
	var skills: Dictionary = Game._as_dict(p.get("skills", {}))
	if bool(sm.get("enabled", false)) and int(skills.get("th5", 0)) >= 1:
		var table: Dictionary = Game._as_dict(Data.calc.get("SUMMONS", {}))
		var ch := str(sm.get("choice", ""))
		if not table.has(ch) and not table.is_empty(): ch = str(table.keys()[0])
		if table.has(ch):
			out["s:%s" % ch] = {"kind": "summon", "id": ch, "look": str(Game._as_dict(table[ch]).get("look", "")), "mob": "", "sprite": ""}
	var sh: Dictionary = Game._as_dict(p.get("shadows", {}))
	if bool(sh.get("enabled", false)) and typeof(sh.get("active", null)) == TYPE_ARRAY:
		var roster: Array = sh.get("roster", []) if typeof(sh.get("roster", null)) == TYPE_ARRAY else []
		var act: Array = sh["active"]
		for i in range(mini(act.size(), 7)):
			var uid := int(act[i])
			for soul in roster:
				if typeof(soul) == TYPE_DICTIONARY and int((soul as Dictionary).get("uid", -1)) == uid:
					var mid := str((soul as Dictionary).get("monster", ""))
					var d2: Dictionary = Data.monster(mid)
					out["h:%d" % uid] = {"kind": "shadow", "id": str(uid), "look": str(d2.get("look", "")), "mob": mid, "sprite": str(d2.get("sprite", ""))}
	return out

func sync() -> void:
	if w == null or not is_instance_valid(w._mob_layer): return
	var want := _wanted()
	for key in units.keys():
		if not want.has(key):
			_free_unit(key)
	var idx := 0
	for key in want.keys():
		idx += 1
		if units.has(key) and is_instance_valid(units[key]["node"]): continue
		var spec: Dictionary = want[key]
		var node: Node2D = MobScript.new()
		_next_uid += 1
		node.setup(_next_uid, str(spec["mob"]), str(spec["look"]), str(spec["sprite"]))
		node.set_process(true)
		node.set_physics_process(false)
		node.z_index = 3
		var pn: Variant = node.get("_name")
		if pn is Node: (pn as Node).visible = false
		var pb: Variant = node.get("_bar")
		if pb is Node: (pb as Node).visible = false
		if str(spec["kind"]) == "shadow": node.modulate = Color(0.72, 0.55, 1.0, 0.92)
		var host: Node = w._mob_layer.get_parent()
		host.add_child(node)
		host.move_child(node, w._mob_layer.get_index())
		node.set_target(w._player.position, true)
		units[key] = {"kind": spec["kind"], "id": spec["id"], "node": node, "next_attack": 0, "last_combat": 0, "cd": {}, "index": idx}

func _free_unit(key: String) -> void:
	var n: Variant = units[key].get("node", null)
	if n != null and is_instance_valid(n): (n as Node).queue_free()
	units.erase(key)

func clear() -> void:
	for key in units.keys(): _free_unit(key)

# ------------------------------------------------------------------ Mục tiêu
func _target() -> Node2D:
	var now := Time.get_ticks_msec()
	# Ưu tiên quái người chơi vừa đánh, rồi đến quái gần nhất trong tầm
	var u := int(w._last_hit_uid)
	if u != 0 and now - int(w._last_hit_at) < 5000 and w._mobs.has(u):
		var m: Node2D = w._mobs[u]
		if is_instance_valid(m) and m.alive and not bool(m.passive): return m
	return w._nearest_mob(420.0, 200.0)

func _focus() -> Node2D:
	if int(w._shadow_focus) != 0 and Time.get_ticks_msec() < int(w._shadow_focus_until) and w._mobs.has(int(w._shadow_focus)):
		var m: Node2D = w._mobs[int(w._shadow_focus)]
		if is_instance_valid(m) and m.alive: return m
	return null

# ------------------------------------------------------------------ Vòng lặp
func tick(delta: float) -> void:
	if w == null or Game.player.is_empty(): return
	# Đồng bộ danh sách đơn vị chỉ khi dữ liệu nhân vật đổi hoặc mỗi 0,5s (không dựng lại mỗi khung)
	var tnow := Time.get_ticks_msec()
	if _sync_at == 0 or tnow - _sync_at > 500:
		_sync_at = tnow
		sync()
	if units.is_empty(): return
	var now := Time.get_ticks_msec()
	var target := _target() if (not w._dead and not w._changing) else null
	var facing := int(w._facing)
	var ppos: Vector2 = w._player.position
	var order := 0
	for key in units.keys():
		var u: Dictionary = units[key]
		var node: Node2D = u["node"]
		if not is_instance_valid(node): continue
		order += 1
		var kind := str(u["kind"])
		var tpos := ppos
		match kind:
			"pet": tpos = ppos + Vector2(-float(facing) * (42.0 + float(order - 1) * 34.0), 6.0)
			"summon": tpos = ppos + Vector2(float(facing) * 56.0, 6.0)
			_: tpos = ppos + Vector2((-1.0 if order % 2 == 1 else 1.0) * float(facing) * (50.0 + float(order / 2) * 36.0), 4.0)
		var state := _state_of(u)
		node.visible = true
		if kind == "pet" and float(state.get("hp", 1)) <= 0.0:
			node.visible = false
			continue
		if kind == "summon": _summon_regen(u, state, delta, now)
		var atk_target: Node2D = target
		if kind == "shadow":
			var f := _focus()
			if f != null: atk_target = f
		if atk_target != null:
			var dx: float = atk_target.position.x - node.position.x
			if absf(dx) > 58.0:
				tpos = Vector2(atk_target.position.x - signf(dx) * 48.0, atk_target.position.y)
			elif now >= int(u["next_attack"]):
				_attack(u, state, atk_target, dx, now)
		node.set_target(tpos)
	if _batch.size() > 0 and now >= _flush_at: _flush()

func _state_of(u: Dictionary) -> Dictionary:
	var id := str(u["id"])
	match str(u["kind"]):
		"pet": return w._pet_state(id, w._companion_stats(id))
		"summon":
			var sm: Dictionary = Game._as_dict(Game.player.get("summons", {}))
			if typeof(sm.get("states", null)) != TYPE_DICTIONARY:
				sm["states"] = {}
				Game.player["summons"] = sm
			var states: Dictionary = sm["states"]
			if typeof(states.get(id, null)) != TYPE_DICTIONARY:
				var ss := summon_stats(id)
				states[id] = {"hp": ss["maxHp"], "mp": ss["maxMp"], "sta": ss["maxSta"]}
			return states[id]
	return {}

func _summon_regen(u: Dictionary, state: Dictionary, delta: float, now: int) -> void:
	var ss := summon_stats(str(u["id"]))
	if float(state.get("hp", 0)) <= 0.0:
		state["hp"] = maxf(1.0, roundf(float(ss["maxHp"]) * 0.5)); state["mp"] = ss["maxMp"]; state["sta"] = ss["maxSta"]
	if now - int(u["last_combat"]) >= 3000:
		state["hp"] = minf(float(ss["maxHp"]), float(state.get("hp", 0)) + float(ss["maxHp"]) * 0.018 * delta)
		state["mp"] = minf(float(ss["maxMp"]), float(state.get("mp", 0)) + 5.0 * delta)
		state["sta"] = minf(float(ss["maxSta"]), float(state.get("sta", 0)) + 14.0 * delta)

# ------------------------------------------------------------------ Chỉ số linh thú (port summonUnitStats)
func summon_unit_lv(id: String) -> int:
	var cap := maxi(1, int(Game.player.get("level", 1)))
	var sm: Dictionary = Game._as_dict(Game.player.get("summons", {}))
	var un: Dictionary = Game._as_dict(Game._as_dict(sm.get("units", {})).get(id, {}))
	var lv := 1
	if un.get("lv", null) != null: lv = int(floorf(float(un["lv"])))
	return maxi(1, mini(cap, lv))

func summon_stats(id: String) -> Dictionary:
	var lv := summon_unit_lv(id)
	var skl := maxi(1, int(Game._as_dict(Game.player.get("skills", {})).get("th5", 1)))
	var mul := 1.0 + 0.12 * float(skl - 1)
	var sp: Dictionary = Game._as_dict(Game._as_dict(Data.calc.get("SUMMONS", {})).get(id, {}))
	var pc: Dictionary = Game._as_dict(Data.calc.get("PET_CURVE", {}))
	var st := {
		"maxHp": roundf(Formulas.interp(pc.get("hp", []), float(lv)) * float(sp.get("hp", 1.0)) * mul),
		"maxMp": roundf((24.0 + 4.0 * float(lv - 1)) * mul),
		"maxSta": roundf((70.0 + 2.0 * float(lv - 1)) * mul),
		"atk": Formulas.interp(pc.get("atk", []), float(lv)) * mul,
		"def": roundf(Formulas.interp(pc.get("def", []), float(lv)) * float(sp.get("def", 1.0))),
	}
	var gear: Dictionary = Game._as_dict(Game._as_dict(Game.player.get("petGear", {})).get(id, {}))
	var table: Dictionary = Game._as_dict(Data.calc.get("PET_GEAR", {}))
	for slot in gear.keys():
		var b: Dictionary = Game._as_dict(table.get(str(gear[slot]), {}))
		if b.has("maxHp"): st["maxHp"] = roundf(float(st["maxHp"]) + float(b["maxHp"]))
		if b.has("atk"): st["atk"] = float(st["atk"]) + float(b["atk"])
		if b.has("def"): st["def"] = roundf(float(st["def"]) + float(b["def"]))
	return st

## Chỉ số một bóng ma (shadowStats): đường cong quái theo cấp của bóng.
func shadow_stats(soul: Dictionary) -> Dictionary:
	var mons: Dictionary = Game._as_dict(Data.calc.get("FUSION_MON", {}))
	var mon: Dictionary = Game._as_dict(mons.get(str(soul.get("monster", "")), {}))
	var curve: Array = Data.calc.get("MON_CURVE", [])
	if mon.is_empty() or curve.is_empty(): return {}
	var sstats: Dictionary = Game._as_dict(soul.get("stats", {}))
	var lv := 1
	if soul.get("lv", null) != null: lv = maxi(1, int(floorf(float(soul["lv"]))))
	else: lv = maxi(1, int(sstats.get("level", 1)))
	var base: Array = curve[clampi(int(mon.get("level", 1)) - 1, 0, curve.size() - 1)]
	var now_c: Array = curve[clampi(lv - 1, 0, curve.size() - 1)]
	return {"atk": float(mon.get("atk", 0)) * (float(now_c[1]) / float(base[1])), "level": lv}

# ------------------------------------------------------------------ Tấn công
func _attack(u: Dictionary, state: Dictionary, target: Node2D, dx: float, now: int) -> void:
	var kind := str(u["kind"])
	var id := str(u["id"])
	var node: Node2D = u["node"]
	var dir := 1 if dx >= 0.0 else -1
	var armor := 1.0 - Formulas.def_reduce(float(target.def_stat), target.mob_level)
	var rage: Dictionary = w._buff_on("rage")
	var frenzy: Dictionary = w._buff_on("frenzy")
	var class_mul := 1.1 if Game.has_passive("trieu_hoi_su") else 1.0
	if kind == "shadow":
		var boost := frenzy if not frenzy.is_empty() else rage
		var soul: Dictionary = {}
		for s in Game._as_dict(Game.player.get("shadows", {})).get("roster", []):
			if typeof(s) == TYPE_DICTIONARY and str((s as Dictionary).get("uid", "")) == id: soul = s
		var sst := shadow_stats(soul)
		if sst.is_empty(): return
		u["next_attack"] = now + int(1250.0 / (1.0 + float(boost.get("speed", 0.0))))
		var ult_boost := 0.5 if now < int(w._shadow_power_until) else 0.0
		var mult := 0.82 * (1.0 + float(boost.get("atk", 0.0)) + ult_boost)
		_queue(target, maxi(1, int(roundf(float(sst["atk"]) * mult * armor))), "shadow", 0.0, dir)
		return
	var pdef: Dictionary = {}
	var pstats: Dictionary = {}
	var atk_mul := 1.0
	var skills: Array = []
	if kind == "pet":
		pstats = w._companion_stats(id)
		atk_mul = float(Game._as_dict(Data.calc.get("MOUNT_ATK", {})).get(id, 1.0))
		var ms: Dictionary = Game._as_dict(Game.player.get("mounts", {}))
		var sk_id := str(Game._as_dict(ms.get("skills", {})).get(id, ms.get("skill", "bite")))
		var table: Dictionary = Game._as_dict(Data.calc.get("PET_SKILLS", {}))
		var one: Dictionary = Game._as_dict(table.get(sk_id, table.get("bite", {})))
		skills = [one]
	else:
		pstats = summon_stats(id)
		pdef = Game._as_dict(Game._as_dict(Data.calc.get("SUMMONS", {})).get(id, {}))
		atk_mul = float(pdef.get("atk", 1.0))
		var lv := summon_unit_lv(id)
		for sk in Game._as_dict(Data.calc.get("SUMMON_SKILLS", {})).get(id, []):
			if int((sk as Dictionary).get("lv", 1)) <= lv: skills.append(sk)
	var speed := (float(pdef.get("aspd", 1.0)) if kind == "summon" else 1.0) * (1.0 + float(rage.get("speed", 0.0)))
	var cdm: Dictionary = u["cd"]
	var cast: Dictionary = {}
	for i in range(skills.size() - 1, -1, -1):
		var sk2: Dictionary = skills[i]
		var sid := str(sk2.get("id", "bite"))
		if now >= int(cdm.get(sid, 0)) and float(state.get("mp", 0)) >= float(sk2.get("mp", 0)) and float(state.get("sta", 0)) >= float(sk2.get("sta", 0)) and absf(dx) <= float(sk2.get("range", 74)):
			cast = sk2; break
	var atk_boost := 1.0 + float(rage.get("atk", 0.0))
	if not cast.is_empty():
		state["mp"] = float(state.get("mp", 0)) - float(cast.get("mp", 0))
		state["sta"] = float(state.get("sta", 0)) - float(cast.get("sta", 0))
		cdm[str(cast.get("id", "bite"))] = now + int(float(cast.get("cooldown", 1800)) / speed)
		u["next_attack"] = now + int((700.0 if kind == "summon" else float(cast.get("cooldown", 1800))) / speed)
		var mult2 := float(cast.get("mult", 1.0)) * atk_mul * class_mul * atk_boost
		_queue(target, maxi(1, int(roundf(float(pstats["atk"]) * mult2 * armor))), "pet", float(cast.get("slow", 0.0)), dir)
		if float(cast.get("radius", 0.0)) > 0.0:
			for u2 in w._mobs.keys():
				var o: Node2D = w._mobs[u2]
				if o == target or not is_instance_valid(o) or not o.alive or bool(o.passive): continue
				if o.position.distance_to(target.position) <= float(cast["radius"]):
					var ar := 1.0 - Formulas.def_reduce(float(o.def_stat), o.mob_level)
					_queue(o, maxi(1, int(roundf(float(pstats["atk"]) * mult2 * 0.8 * ar))), "pet", float(cast.get("slow", 0.0)), dir)
		if float(cast.get("heal", 0.0)) > 0.0: w._skill_heal(float(cast["heal"]))
		u["last_combat"] = now
		FloatText.spawn(w._fx, node.position + Vector2(0, -32), str(cast.get("name", "")), Color(0.55, 0.91, 1.0), 11)
	elif float(state.get("sta", 0)) >= 4.0:
		state["sta"] = float(state.get("sta", 0)) - 4.0
		u["next_attack"] = now + int(1150.0 / speed)
		_queue(target, maxi(1, int(roundf(float(pstats["atk"]) * 0.82 * atk_mul * class_mul * atk_boost * armor))), "pet", 0.0, dir)
		u["last_combat"] = now

# ------------------------------------------------------------------ Gom đòn gửi server
func _queue(mob: Node2D, dmg: int, src: String, slow: float, dir: int) -> void:
	var key := "%d|%s" % [int(mob.uid), src]
	var e: Dictionary = _batch.get(key, {})
	if e.is_empty():
		_batch[key] = {"u": int(mob.uid), "src": src, "dmg": dmg, "slow": slow, "dir": dir}
	else:
		e["dmg"] = int(e["dmg"]) + dmg
		e["slow"] = maxf(float(e["slow"]), slow)
		e["dir"] = dir
	if _flush_at == 0 or Time.get_ticks_msec() > _flush_at + 600: _flush_at = Time.get_ticks_msec() + 500

func _flush() -> void:
	_flush_at = 0
	var chunk := maxi(30, int(Game.stats.get("atk", 30)) * 7)
	for e in _batch.values():
		var mob: Variant = w._mobs.get(int(e["u"]), null)
		if mob == null or not is_instance_valid(mob) or not mob.alive: continue
		var left := int(e["dmg"])
		var first := true
		while left >= 1:
			var d := mini(left, chunk)
			left -= d
			Socket.send_hit(int(e["u"]), d, "", 0, int(e["dir"]), false, {"slow": float(e["slow"]) if first else 0.0, "src": str(e["src"])})
			first = false
	_batch.clear()
