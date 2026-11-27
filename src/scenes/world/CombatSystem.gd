extends "res://src/scenes/world/WorldPart.gd"
## Chiến đấu: đòn thường, kỹ năng, vùng trúng, đạn bay, sát thương, lướt.
## Hệ thống của World (w = World). Trạng thái riêng khai báo ngay dưới; trạng thái dùng chung đọc qua thuộc tính chuyển tiếp.

const HIT_GAP := 0.13
const ProjScript := preload("res://src/world/Proj.gd")

# Trạng thái riêng
var _heal_tick := 0                  # Kiếm Tâm: chống hồi dồn trong 120ms
var _skill_ids: Array = ["pa1", "pa2", "pa3", "pa4", "pa5"]
var _shadow_crit := false
## Hồi phục theo số lẻ như web (App.hp là số thực): cộng dồn phần lẻ, trả về phần nguyên mỗi lần.
var _carry_acc: Dictionary = {}

# Trạng thái dùng chung (lưu ở World)
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
var _fxs: Node2D:
	get: return w._fxs if is_instance_valid(w._fxs) else null
	set(x): w._fxs = x
var _last_hit_uid: int:
	get: return w._last_hit_uid
	set(x): w._last_hit_uid = x
var _last_hit_at: int:
	get: return w._last_hit_at
	set(x): w._last_hit_at = x
var _mobs: Dictionary:
	get: return w._mobs
	set(x): w._mobs = x
var _cols: int:
	get: return w._cols
	set(x): w._cols = x
var _facing: int:
	get: return w._facing
	set(x): w._facing = x
var _vy: float:
	get: return w._vy
	set(x): w._vy = x
var _knock_vx: float:
	get: return w._knock_vx
	set(x): w._knock_vx = x
var _knock_until: int:
	get: return w._knock_until
	set(x): w._knock_until = x
var _attack_until: int:
	get: return w._attack_until
	set(x): w._attack_until = x
var _next_attack: int:
	get: return w._next_attack
	set(x): w._next_attack = x
var _invuln_until: int:
	get: return w._invuln_until
	set(x): w._invuln_until = x
var _buffs: Dictionary:
	get: return w._buffs
	set(x): w._buffs = x
var _nth_count: Dictionary:
	get: return w._nth_count
	set(x): w._nth_count = x
var _free_cast_used: bool:
	get: return w._free_cast_used
	set(x): w._free_cast_used = x
var _dead: bool:
	get: return w._dead
	set(x): w._dead = x
var _changing: bool:
	get: return w._changing
	set(x): w._changing = x
var _cd_until: Array:
	get: return w._cd_until
	set(x): w._cd_until = x
var _hud_dirty: bool:
	get: return w._hud_dirty
	set(x): w._hud_dirty = x
var _interact: Dictionary:
	get: return w._interact
	set(x): w._interact = x
var _target_mob: Node2D:
	get: return w._target_mob if is_instance_valid(w._target_mob) else null
	set(x): w._target_mob = x
var _projs: Array:
	get: return w._projs
	set(x): w._projs = x
var _shadow_focus: int:
	get: return w._shadow_focus
	set(x): w._shadow_focus = x
var _shadow_focus_until: int:
	get: return w._shadow_focus_until
	set(x): w._shadow_focus_until = x

# Hàm của hệ thống khác
func _cell(x: float, y: float) -> String:
	return w.map._cell(x, y)

func _walkable(x: float, y: float) -> bool:
	return w.map._walkable(x, y)

func _buff_sum(key: String) -> float:
	return w.buffs._buff_sum(key)

func _add_buff(id: String, sk: Dictionary, stype: String) -> void:
	w.buffs._add_buff(id, sk, stype)

func _skill_heal(ratio: float) -> void:
	w.buffs._skill_heal(ratio)

func _die() -> void:
	w.life._die()

func _do_interact() -> void:
	w.loot._do_interact()

func shake(strength: float, duration: float) -> void:
	w.shake(strength, duration)

func _attack_sta_cost() -> float:
	return w.life._attack_sta_cost()

func _spend_sta(cost: float) -> bool:
	return w.life._spend_sta(cost)

func _aim_at_target() -> void:
	w.target._aim_at_target()

func _target_angle() -> float:
	return w.target._target_angle()

## Ô nút HUD -> id kỹ năng (đúng mô hình ô của web/server). Ô trang bị là ô ảo lấy từ món đang mặc.
func _btn_skill(i: int) -> String:
	var slots: Array = Game.player.get("skillSlots", [])
	if i == 8: return _gear_skill_id()
	if i < 0 or i > 7: return ""
	var s0 := str(slots[i]) if i < slots.size() and slots[i] != null else ""
	if s0 == "" and i < 4: s0 = str(_skill_ids[i])
	return s0

func _gear_skill_id() -> String:
	var eq: Variant = Game.player.get("equip", {})
	if typeof(eq) != TYPE_DICTIONARY: return ""
	for slot in (eq as Dictionary).keys():
		var it: Variant = (eq as Dictionary)[slot]
		if typeof(it) != TYPE_DICTIONARY: continue
		if Formulas.is_broken(it): continue
		var g := str(Data.item(str((it as Dictionary).get("id", ""))).get("grantsSkill", ""))
		if g != "" and not Data.skill(g).is_empty() and not bool(Data.skill(g).get("ult", false)): return g
	return ""

func _atk_stat() -> int:
	var st: Dictionary = Game.stats
	if st.is_empty(): st = Game.player.get("stats", {})
	return int(st.get("atk", Game.player.get("atk", 30)))

## Sát thương một đòn lên một con quái — cùng công thức calcDamage của web:
## ATK x hệ số x (1+buff) x trùm x (1-giáp quái) x [0.9,1.1], chí mạng x1.6 (Cung Thủ x1.8), trần chí mạng 90%.
func _calc_hit(mob: Node2D, mult: float, boss_bonus: float, pierce: Dictionary, basic: bool = false) -> Dictionary:
	var pierced := false
	if not pierce.is_empty():
		pierced = mob.mob_level >= int(pierce.get("minLevel", 1)) and mob.mob_level <= int(pierce.get("maxLevel", 999))
	# Chỉ boss / thủ lĩnh mới chịu "sát thương lên trùm" (web: def.boss || def.leader; trùm cuối không có cờ này thì không tính)
	var md: Dictionary = Data.monster(mob.mob_id)
	var boss_mul := 1.0 + boss_bonus / 100.0 if (bool(md.get("boss", false)) or bool(md.get("leader", false))) else 1.0
	var armor := 1.0 if pierced else 1.0 - Formulas.def_reduce(float(mob.def_stat), mob.mob_level)
	# Buff "exec": nhân thêm khi quái dưới ngưỡng máu
	var now_ms := Time.get_ticks_msec()
	for bid in _buffs.keys():
		var bb: Dictionary = _buffs[bid]
		var ex: Dictionary = Game._as_dict(bb.get("exec", {}))
		if not ex.is_empty() and now_ms < int(bb.get("until", 0)) and float(mob.hp) <= float(mob.max_hp) * float(ex.get("below", 0.0)): mult *= float(ex.get("mult", 1.0))
	var dmg := float(_atk_stat()) * mult * (1.0 + _buff_sum("atk")) * boss_mul * armor
	dmg = maxf(1.0, dmg) * randf_range(0.9, 1.1)
	var crit_p := minf(90.0, float(Game.stats.get("crit", 3.0)) + _buff_sum("crit"))
	var crit := randf() * 100.0 < crit_p
	if crit:
		if _shadow_crit and Game.has_passive("sat_thu"):
			dmg *= 2.5
			_shadow_crit = false
		else:
			dmg *= 1.8 if Game.has_passive("cung_thu") else 1.6
	var out := maxi(1, int(roundf(dmg)))
	# Kháng đòn thường áp sau chí mạng + làm tròn (web: combat.js damageMonster)
	if basic and mob.resist > 0.0: out = maxi(1, int(roundf(float(out) * (1.0 - mob.resist))))
	return {"dmg": out, "crit": crit}

func _weapon() -> Dictionary:
	var wt: Dictionary = Game._as_dict(Data.calc.get("WEAPON_TYPES", {}))
	var w: Variant = wt.get(str(Game.stats.get("wtype", "tay")), null)
	if typeof(w) == TYPE_DICTIONARY: return w
	return {"range": 74.0, "cooldown": 360.0, "mult": 1.0, "style": "melee"}

## Bối cảnh một lượt đòn: hiệu ứng trang bị tính 1 lần cho mọi quái trúng.
func _hit_ctx() -> Dictionary:
	var fx: Dictionary = Game.special_fx()
	return {"boss": float(Game.stats.get("boss", 0.0)), "lifesteal": float(Game.stats.get("lifesteal", 0.0)),
		"pierce": Game._as_dict(fx.get("pierce", {})), "nth": Game._as_dict(fx.get("everyNth", {})),
		"freeze": Game._as_dict(fx.get("setFreeze", {})), "aura": Game._as_dict(fx.get("slowAura", {}))}

## Vùng trúng: {"kind":"rect","cx","cy","w","h"} hoặc {"kind":"circle","cx","cy","r"}.
func _shape_hits(shape: Dictionary, r: Rect2) -> bool:
	var cx := float(shape["cx"])
	var cy := float(shape["cy"])
	if str(shape.get("kind", "rect")) == "circle":
		var rad := float(shape["r"])
		var nx := clampf(cx, r.position.x, r.position.x + r.size.x)
		var ny := clampf(cy, r.position.y, r.position.y + r.size.y)
		return (nx - cx) * (nx - cx) + (ny - cy) * (ny - cy) <= rad * rad
	var w := float(shape["w"])
	var h := float(shape["h"])
	return Rect2(cx - w * 0.5, cy - h * 0.5, w, h).intersects(r)

## Một lượt đòn lên mọi quái nằm trong vùng. `power` chưa nhân skillMul (kỹ năng) — hàm tự nhân.
func _strike_shape(shape: Dictionary, skill_id: String, power: float, kind: int, extra: Dictionary = {}) -> int:
	var skill_mul := float(Game.stats.get("skillMul", 1.0)) if kind > 0 else 1.0
	var mult := maxf(0.05, power) * skill_mul
	var ctx := _hit_ctx()
	var n := 0
	if extra.has("chain") and not extra.has("chainBudget"): extra["chainBudget"] = {"n": 6}   # tối đa 6 mục tiêu lan cho CẢ lần tung (như web), không phải mỗi quái
	# Có quái đang chỉ định nằm trong vùng chém -> chỉ trúng đúng con đó (web: hitBox `only`)
	var only: Node2D = null
	if bool(extra.get("only_target", false)) and _target_mob != null and is_instance_valid(_target_mob) and _target_mob.alive and _shape_hits(shape, _target_mob.body_rect()): only = _target_mob
	for u in _mobs.keys():
		var mob: Node2D = _mobs[u]
		if not is_instance_valid(mob) or not mob.alive or (only != null and mob != only): continue
		if _shape_hits(shape, mob.body_rect()):
			_hit_mob(int(u), mob, mult, kind, skill_id, extra, ctx)
			n += 1
	return n

## Nhiều nhát liên tiếp (cận chiến): nhát cuối dùng `finisher` nếu có. Hộp trước mặt rộng `range_px`.
func _strike(range_px: float, skill_id: String, power: float, kind: int, hits: int = 1, gap: float = HIT_GAP, extra: Dictionary = {}, height: float = 70.0) -> void:
	for i in range(hits):
		if i > 0: await get_tree().create_timer(gap).timeout
		if _dead or not is_inside_tree(): return
		var pw := power
		var is_last := i == hits - 1
		if extra.has("finisher") and is_last: pw = float(extra["finisher"])
		# Hất văng / choáng dồn vào nhát CUỐI; làm chậm / đóng băng / phá giáp thì nhát nào cũng ăn (như web)
		var hx := extra.duplicate()
		hx["only_target"] = true
		if not is_last:
			hx["knock"] = 0.0
			hx["stun"] = 0.0
		var shape := {"kind": "rect", "cx": _player.position.x + float(_facing) * range_px * 0.5, "cy": _player.position.y, "w": range_px, "h": height}
		_strike_shape(shape, skill_id, pw, kind, hx)

func _after(sec: float, cb: Callable) -> void:
	await get_tree().create_timer(sec).timeout
	if not is_inside_tree(): return
	cb.call()

## Lõi một đòn lên một con quái: tính sát thương, hiệu ứng trang bị, gửi server, hút máu, dây chuyền.
func _hit_mob(u: int, mob: Node2D, mult: float, kind: int, skill_id: String, extra: Dictionary, ctx: Dictionary) -> void:
	var m2 := mult
	# Kỹ năng gấp bội lên quái đang bị làm chậm / đóng băng
	if extra.has("vsSlowed") and (int(mob.flags) & 3) != 0: m2 *= float(extra["vsSlowed"])
	var r := _calc_hit(mob, m2, float(ctx["boss"]), ctx["pierce"], kind == 0)
	var dmg := int(r["dmg"])
	# Ấn Sát (Kỳ Nguyên Sát Kiếp): cứ n đòn trúng một mục tiêu thì đòn thứ n nặng hơn, đếm riêng từng quái
	var nth: Dictionary = ctx["nth"]
	if not nth.is_empty():
		var cnt := int(_nth_count.get(u, 0)) + 1
		if cnt >= int(nth.get("n", 5)):
			cnt = 0
			dmg = maxi(1, int(roundf(float(dmg) * float(nth.get("mult", 1.0)))))
			FloatText.spawn(_fx, mob.position + Vector2(0, -70), "Ấn Sát", Color(1.0, 0.84, 0.33), 15)
		_nth_count[u] = cnt
	# Tên Phá Giáp: quái đang bị phá giáp chịu thêm sát thương; đòn mang `shred` (đặt lại 6 giây) — như web
	var now_sh := Time.get_ticks_msec()
	if mob.shred_until > now_sh: dmg = maxi(1, int(roundf(float(dmg) * (1.0 + mob.shred))))
	if float(extra.get("shred", 0.0)) > 0.0:
		mob.shred = float(extra["shred"])
		mob.shred_until = now_sh + 6000
	var hit_x: Dictionary = {"slow": float(extra.get("slow", 0.0)), "freeze": float(extra.get("freeze", 0.0)), "stun": float(extra.get("stun", 0.0))}
	if extra.has("knock"): hit_x["knock"] = float(extra["knock"])
	# Bộ Băng Long 10 món: đòn có cơ hội đóng băng quái
	var freeze_fx: Dictionary = ctx["freeze"]
	if not freeze_fx.is_empty() and not bool(mob.passive) and hit_x["freeze"] <= 0.0 and randf() < float(freeze_fx.get("chance", 0.0)):
		hit_x["freeze"] = float(freeze_fx.get("dur", 2.0))
		FloatText.spawn(_fx, mob.position + Vector2(0, -84), "Đóng Băng", Color(0.5, 0.85, 1.0), 14)
	# Kiếm Thượng Băng Sương: quái trong tầm bị làm chậm
	var aura: Dictionary = ctx["aura"]
	if not aura.is_empty() and absf(mob.position.x - _player.position.x) < float(aura.get("range", 170.0)):
		hit_x["slow"] = maxf(float(hit_x["slow"]), 0.5)
	var dir := 1 if mob.position.x >= _player.position.x else -1
	_last_hit_uid = u
	_last_hit_at = Time.get_ticks_msec()
	if skill_id != "" and _skill_fx != null and _skill_fx.has_method("play_hit"):
		_skill_fx.play_hit(skill_id, (mob.body_rect() as Rect2).get_center(), 1 if mob.position.x >= _player.position.x else -1)   # hiệu ứng riêng của kỹ năng trên đúng quái bị trúng
	Socket.send_hit(u, dmg, skill_id, kind, dir, bool(r["crit"]), hit_x)
	if not bool(mob.passive) and not _dead:
		var mxh := int(Game.stats.get("maxHp", 1))
		var ls := float(ctx["lifesteal"])
		if ls > 0.0: Game.hp = mini(mxh, Game.hp + _carry("lifesteal", float(dmg) * ls / 100.0))   # cộng dồn phần lẻ, hút máu nhỏ không bị làm tròn về 0
		# Nội tại Kiếm Tâm: đánh thường trúng quái hồi 0,5% máu tối đa
		if kind == 0 and Game.has_passive("kiem_si") and Time.get_ticks_msec() > _heal_tick:
			_heal_tick = Time.get_ticks_msec() + 120
			Game.hp = mini(mxh, Game.hp + _carry("kiem_tam", float(mxh) * 0.005))
	# Dây chuyền: lan sang quái gần mục tiêu (tối đa 6 con)
	if extra.has("chain"):
		var cbud: Dictionary = extra.get("chainBudget", {"n": 6})
		var budget := int(cbud.get("n", 6))
		var rad := float(extra.get("chainRadius", 150.0))
		for u2 in _mobs.keys():
			if budget <= 0: break
			var o: Node2D = _mobs[u2]
			if int(u2) == u or not is_instance_valid(o) or not o.alive or bool(o.passive): continue
			if o.position.distance_to(mob.position) <= rad:
				budget -= 1
				cbud["n"] = budget
				var rc := _calc_hit(o, m2 * float(extra["chain"]), float(ctx["boss"]), ctx["pierce"], false)
				Socket.send_hit(int(u2), int(rc["dmg"]), skill_id, kind, dir, bool(rc["crit"]))

## o: speed, range, mult (đã nhân skillMul), angle, dy, pierce, skill_id, kind, extra, color, basic, arrow
func _shoot(o: Dictionary) -> void:
	var node: Node2D = ProjScript.new()
	node.position = _player.position + Vector2(float(_facing) * 16.0, -2.0 + float(o.get("dy", 0.0)))
	var ang := float(o.get("angle", 0.0))
	node.setup(o.get("color", Color(1.0, 0.6, 0.3)), ang, _facing, float(o.get("size", 1.0)), bool(o.get("arrow", false)))
	var pinfo: Dictionary = _skill_fx.proj_info(str(o.get("skill_id", ""))) if (_skill_fx != null and _skill_fx.has_method("proj_info")) else {}
	if not pinfo.is_empty(): node.setup_skill(str(o["skill_id"]), pinfo["col"], pinfo["core"], bool(pinfo["dark"]))   # đạn mang hình riêng của kỹ năng
	_fx.add_child(node)
	var spd := float(o.get("speed", 700.0))
	# Đạn đơn mục tiêu bay vào đúng quái đang chỉ định, bỏ qua quái khác chắn đường (đạn xuyên thì trúng hết)
	var focus: Node2D = _target_mob if (not bool(o.get("pierce", false)) and _target_mob != null and is_instance_valid(_target_mob) and _target_mob.alive) else null
	_projs.append({"node": node, "v": Vector2(cos(ang) * spd * float(_facing), sin(ang) * spd), "dist": 0.0, "hit": {}, "o": o, "focus": focus})

func _free_proj(p: Dictionary) -> void:
	var n: Variant = p.get("node", null)
	if n != null and is_instance_valid(n): (n as Node).queue_free()
	_projs.erase(p)

func _update_projectiles(delta: float) -> void:
	if _projs.is_empty(): return
	var ctx := {}   # tính lười: chỉ khi có đạn trúng (special_fx khá tốn)
	# Chạy ngược bằng chỉ số: không cấp phát mảng mới mỗi khung, vẫn xoá an toàn khi trúng/đạn hết tầm.
	var pi := _projs.size() - 1
	while pi >= 0:
		var p: Dictionary = _projs[pi]
		pi -= 1
		var node: Node2D = p["node"]
		if not is_instance_valid(node): _projs.erase(p); continue
		var o: Dictionary = p["o"]
		var step: Vector2 = (p["v"] as Vector2) * delta
		node.position += step
		p["dist"] = float(p["dist"]) + step.length()
		if float(p["dist"]) > float(o.get("range", 400.0)) or _cell(node.position.x, node.position.y) == "#":
			_free_proj(p); continue
		var box := Rect2(node.position - Vector2(12, 9), Vector2(24, 18))
		for u in _mobs.keys():
			var mob: Node2D = _mobs[u]
			if not is_instance_valid(mob) or not mob.alive or (p["hit"] as Dictionary).has(u): continue
			if absf(mob.position.x - node.position.x) > 350.0: continue
			var fo: Variant = p.get("focus", null)
			if fo != null and is_instance_valid(fo) and (fo as Node2D).alive and mob != fo: continue
			# Lọc tầm dọc trước khi tạo hộp va chạm (đạn bay ngang tầm ngực).
			if absf(mob.position.y - node.position.y) > 90.0: continue
			var mr: Rect2 = mob.body_rect()
			# Quái thấp vẫn bị đạn tầm ngực trúng (web dùng khung sprite cao hơn): nới khung lên tối thiểu 70px
			if mr.size.y < 70.0: mr = Rect2(mr.position.x, mr.end.y - 70.0, mr.size.x, 70.0)
			if box.intersects(mr):
				(p["hit"] as Dictionary)[u] = true
				if ctx.is_empty(): ctx = _hit_ctx()
				_hit_mob(int(u), mob, float(o.get("mult", 1.0)), int(o.get("kind", 0)), str(o.get("skill_id", "")), o.get("extra", {}), ctx)
				if not bool(o.get("pierce", false)):
					_free_proj(p)
					break

func _skill_extra(sk: Dictionary) -> Dictionary:
	var sx := {}
	for key in ["slow", "freeze", "stun", "knock", "vsSlowed", "chain", "finisher", "shred"]:
		if sk.has(key): sx[key] = sk[key]
	return sx

func _proj_color(sk: Dictionary) -> Color:
	if str(sk.get("school", "")) == "phap_su": return Color(0.45, 0.78, 1.0)
	return Color(1.0, 0.62, 0.28)

## Gây sát thương của một kỹ năng theo đúng dạng của web (xem WorldSkills.castSkill).
func _skill_damage(id: String, sk: Dictionary, stype: String, kind: int) -> void:
	if stype in ["melee", "projectile", "spread", "sword_fall", "meteor", "arrow_rain"]: _aim_at_target()   # quay mặt về quái đang chỉ định (web: aimAtTarget)
	var power := float(sk.get("power", 0.0))
	var sx := _skill_extra(sk)
	var fa := float(_facing)
	var px := _player.position.x
	var py := _player.position.y
	var smul := float(Game.stats.get("skillMul", 1.0))
	# Mục tiêu đang nhắm: các chiêu rơi (kiếm/đá/mưa tên) phải trúng đúng quái trong tầm,
	# không phải điểm cố định trước mặt người chơi (quái có thể đứng lệch trên/dưới hoặc sau lưng).
	var aim: Node2D = _target_mob if (_target_mob != null and is_instance_valid(_target_mob) and _target_mob.alive) else null
	var aim_x := px + fa * 140.0
	var aim_y := py
	if aim != null:
		aim_x = aim.position.x
		aim_y = aim.position.y - float(aim.get("_height")) * 0.5
	match stype:
		"melee":
			_strike(float(sk.get("range", 90.0)), id, power, kind, maxi(1, int(sk.get("hits", 1))), HIT_GAP, sx)
		"aoe":
			_strike_shape({"kind": "circle", "cx": px, "cy": py, "r": float(sk.get("radius", 160.0))}, id, power, kind, sx)
		"sword_fall":
			var cnt_s := mini(int(sk.get("count", 1)), 3)
			for k in range(cnt_s):
				# Có mục tiêu: tất cả kiếm rơi quanh mục tiêu. Không có: rơi trước mặt như cũ.
				var x := clampf(aim_x + fa * (float(k) - float(cnt_s - 1) * 0.5) * 70.0, 30.0, float(_cols) * TILE - 30.0)
				var kx := sx.duplicate(); kx["knock"] = float(sk.get("knock", 300.0))
				_after(float(k) * 0.22 + 0.3, func(): _strike_shape({"kind": "circle", "cx": x, "cy": aim_y, "r": float(sk.get("radius", 120.0))}, id, power, kind, kx))
		"meteor":
			var cnt_m := maxi(1, int(sk.get("count", 1)))
			for k in range(cnt_m):
				var x2 := clampf(aim_x + fa * (float(k) - float(cnt_m - 1) * 0.5) * 90.0, 30.0, float(_cols) * TILE - 30.0)
				var km := sx.duplicate(); km["knock"] = float(sk.get("knock", 260.0)); km["chainRadius"] = 170.0
				_after(float(k) * 0.42 + 0.6, func(): _strike_shape({"kind": "circle", "cx": x2, "cy": aim_y, "r": float(sk.get("radius", 120.0))}, id, power, kind, km))
			if float(sk.get("heal", 0.0)) > 0.0: _skill_heal(float(sk["heal"]))
		"arrow_rain":
			var width := float(sk.get("width", 300.0))
			var cx := clampf(aim_x, 30.0, float(_cols) * TILE - 30.0)
			var n := maxi(1, int(sk.get("arrows", 1)))
			for i in range(n):
				var ax := cx + randf_range(-width * 0.5, width * 0.5)
				_after(0.15 + float(i) * (1.2 / float(n)) + 0.26, func(): _strike_shape({"kind": "rect", "cx": ax, "cy": aim_y, "w": 46.0, "h": 90.0}, id, power, kind, sx))
		"projectile":
			var water := str(sk.get("school", "")) == "phap_su"
			var cnt := maxi(1, int(sk.get("count", 1)))
			for k in range(cnt):
				var ex := sx.duplicate()
				if not ex.has("knock"): ex["knock"] = 140.0 if water else 60.0
				_shoot({"speed": 520.0 if water else 820.0, "range": float(sk.get("range", 400.0)), "mult": power * smul, "kind": kind, "skill_id": id,
					"pierce": bool(sk.get("pierce", false)), "extra": ex, "dy": (float(k) - float(cnt - 1) * 0.5) * 16.0, "angle": _target_angle(), "color": _proj_color(sk)})
		"spread":
			var cs := maxi(1, int(sk.get("count", 1)))
			for k in range(cs):
				_shoot({"speed": 760.0, "range": float(sk.get("range", 400.0)), "mult": power * smul, "kind": kind, "skill_id": id,
					"pierce": bool(sk.get("pierce", false)), "extra": sx, "angle": (float(k) - float(cs - 1) * 0.5) * 0.16 + _target_angle(), "color": _proj_color(sk)})
		"backstep":
			var now := Time.get_ticks_msec()
			_invuln_until = maxi(_invuln_until, now + 450)
			_knock_vx = -fa * 650.0
			_knock_until = now + 260
			_vy = -320.0
			var cb := maxi(1, int(sk.get("count", 1)))
			_after(0.12, func():
				for k in range(cb):
					_shoot({"speed": 780.0, "range": 420.0, "mult": power * smul, "kind": kind, "skill_id": id, "extra": sx,
						"angle": (float(k) - float(cb - 1) * 0.5) * 0.12, "color": _proj_color(sk)}))
		"shadow_command":
			var target := _nearest_mob(500.0, 200.0)
			var cx2 := px + fa * 100.0
			var cy2 := py
			if target != null:
				cx2 = target.position.x; cy2 = target.position.y - 20.0
				_shadow_focus = int(target.uid); _shadow_focus_until = Time.get_ticks_msec() + 6000
			_strike_shape({"kind": "circle", "cx": cx2, "cy": cy2, "r": float(sk.get("radius", 200.0))}, id, power, kind, sx)

func _nearest_mob(range_x: float, reach_y: float) -> Node2D:
	var best: Node2D = null
	var bd := 1e9
	for u in _mobs.keys():
		var m: Node2D = _mobs[u]
		if not is_instance_valid(m) or not m.alive or bool(m.passive): continue
		var dx := absf(m.position.x - _player.position.x)
		if dx < range_x and absf(m.position.y - _player.position.y) < reach_y and dx < bd:
			bd = dx; best = m
	return best

func _on_attack() -> void:
	if _dead or _changing: return
	# Có NPC / đồ rơi / cổng ngay cạnh và không có quái sát bên: nút Đánh dùng để tương tác (như Ninja School).
	if not _interact.is_empty() and _nearest_mob(110.0, 90.0) == null:
		_do_interact()
		return
	var now := Time.get_ticks_msec()
	if now < _next_attack: return
	var w := _weapon()
	if not _spend_sta(_attack_sta_cost()): return
	_next_attack = now + int(float(w.get("cooldown", 360.0)) / (1.0 + _buff_sum("speed")))
	_attack_until = now + 280
	var style := str(w.get("style", "melee"))
	var wmult := float(w.get("mult", 1.0))
	var wrange := float(w.get("range", 74.0))
	if style == "melee":
		Audio.play("hit", 1.2)
		_fxs.slash(_player.position + Vector2(0, 6), _facing, Color(1.0, 0.95, 0.8), 1.0, int(now / 340) % 2 == 0)
		_strike_shape({"kind": "rect", "cx": _player.position.x + float(_facing) * wrange * 0.5, "cy": _player.position.y, "w": wrange, "h": 60.0}, "", wmult, 0, {"only_target": true})
	elif style == "projectile":
		Audio.play("cast", 1.3)
		var orb := str(w.get("proj", "")) == "proj_orb"
		_shoot({"speed": float(w.get("speed", 720.0)), "range": wrange, "mult": wmult, "kind": 0, "skill_id": "", "extra": {"knock": 90.0}, "angle": _target_angle(),
			"color": Color(0.75, 0.6, 1.0) if orb else Color(0.9, 0.85, 0.7), "arrow": not orb})
	else:
		Audio.play("cast", 1.1)
		_shoot({"speed": 460.0, "range": wrange, "mult": wmult, "kind": 0, "skill_id": "", "pierce": true, "extra": {"knock": 160.0}, "angle": _target_angle(),
			"color": Color(0.6, 0.85, 1.0), "size": 1.3})

func _cast(index: int) -> void:
	if _dead or _changing or index >= 9: return
	var id := _btn_skill(index)
	var sk: Dictionary = Data.skill_eff(Game.player, id)
	if sk.is_empty():
		if _hud_node: _hud_node.toast("Ô kỹ năng trống — mở Kỹ năng để gán", "warn")
		return
	var now := Time.get_ticks_msec()
	if now < int(_cd_until[index]):
		return
	var cost := int(roundf(float(sk.get("mp", 0)) * float(Game.stats.get("costMul", 1.0))))
	# Bộ Lưu Trữ 10 món (Cổ Ngữ): kỹ năng đầu tiên mỗi trận không tốn năng lượng
	var free_cast: bool = Game.special_fx().has("setFreeCast") and not _free_cast_used
	if free_cast: cost = 0
	if Game.mp < cost:
		if _hud_node: _hud_node.toast("Không đủ MP", "warn")
		return
	var sta_cost: float = float(Data.STAMINA.get("ult", 50.0)) if bool(sk.get("ult", false)) else float(Data.STAMINA.get("skill", 14.0))
	if not _spend_sta(sta_cost): return
	Game.mp -= cost
	if free_cast:
		_free_cast_used = true
		FloatText.spawn(_fx, _player.position + Vector2(0, -60), "Cổ Ngữ", Color(0.31, 0.76, 0.97), 14)
	var cd := float(sk.get("cd", 1.0)) * (1.0 - float(Game.stats.get("cdr", 0.0)) / 100.0)
	_cd_until[index] = now + int(cd * 1000.0)
	if _hud_node: _hud_node.start_cooldown(index, cd)
	var stype0 := str(sk.get("type", ""))
	var exec_target: Node2D = null
	if stype0 == "execute":
		exec_target = _exec_target(float(sk.get("range", 520.0)), float(sk.get("reach", 320.0)))
		if exec_target == null:
			if _hud_node: _hud_node.toast("Không có mục tiêu trong tầm", "warn")
			_cd_until[index] = 0
			Game.mp += cost
			return
	if stype0 != "fusion" and stype0 != "execute":
		Socket.send_cast(id, _player.position.x, _player.position.y)
	Audio.play("cast")
	_attack_until = now + 320
	# Chiêu rơi (kiếm/đá/mưa tên): căn hiệu ứng vào mục tiêu đang nhắm để kiếm đâm đúng quái.
	var fx_origin := _player.position
	if stype0 in ["sword_fall", "meteor", "arrow_rain"] and _target_mob != null and is_instance_valid(_target_mob) and _target_mob.alive:
		fx_origin = _target_mob.position
	if _skill_fx and _skill_fx.has_method("play"):
		_skill_fx.play("cast", id, fx_origin, _facing)
	var custom_fx: bool = _skill_fx != null and _skill_fx.has_method("has_custom") and _skill_fx.has_custom(id)   # có hình riêng -> bỏ hiệu ứng chung theo loại
	var kind := 3 if bool(sk.get("superUlt", false)) else (2 if bool(sk.get("ult", false)) else 1)
	var stype := str(sk.get("type", ""))
	match stype:
		"manaburst": Socket.send_manaburst()
		"allin": Socket.send_allin()
		"fusion": Socket.send_fusion()
		"execute":
			if exec_target != null:
				Socket.send({"t": "exec", "u": int(exec_target.get("uid")), "bua": 0})
				_fxs.ring(exec_target.position, Color(1, 1, 1), 90.0, 0.5, 5.0)
				shake(5.0, 0.25)
				Game.hp = 0
				_die()
		"dash":
			var x0 := _player.position.x
			_dash(float(sk.get("distance", 170.0)))
			_invuln_until = maxi(_invuln_until, now + 400)
			_shadow_crit = true   # Sát Thủ: chí mạng đầu tiên sau lướt gây 250%
			# Đòn đánh xuyên suốt quãng đã lướt (và đòn nối `after` sau 180ms)
			var da := minf(x0, _player.position.x)
			var db := maxf(x0, _player.position.x)
			var dshape := {"kind": "rect", "cx": (da + db) * 0.5, "cy": _player.position.y, "w": db - da + 50.0, "h": 64.0}
			var dx := _skill_extra(sk)
			if float(sk.get("power", 0.0)) > 0.0: _strike_shape(dshape, id, float(sk["power"]), kind, dx)
			if float(sk.get("after", 0.0)) > 0.0: _after(0.18, func(): _strike_shape(dshape, id, float(sk["after"]), kind, dx))
		"melee", "backstep":
			if not custom_fx: _fxs.slash(_player.position + Vector2(0, 6), _facing, Color(1.0, 0.85, 0.5), 1.5)
		"guard", "manashield", "buff":
			_add_buff(id, sk, stype)
			if not custom_fx: _fxs.shield(_player.position + Vector2(0, 26), Color(0.45, 0.72, 1.0) if stype != "buff" else Color(1.0, 0.85, 0.4))
		"heal":
			_skill_heal(float(sk.get("heal", 0.0)))
			if float(sk.get("mpHeal", 0.0)) > 0.0:
				var mxm := int(Game.stats.get("maxMp", 1))
				var gm := int(roundf(float(mxm) * float(sk["mpHeal"])))
				Game.mp = mini(mxm, Game.mp + gm)
				FloatText.spawn(_fx, _player.position + Vector2(0, -46), "+%d" % gm, Color(0.39, 0.71, 0.96), 14)
			if not custom_fx: _fxs.heal(_player.position)
			Audio.play("coin", 0.8)
		"aoe", "meteor", "sword_fall", "arrow_rain":
			if stype == "aoe" and float(sk.get("heal", 0.0)) > 0.0: _skill_heal(float(sk["heal"]))
			if not custom_fx: _fxs.ring(_player.position + Vector2(float(_facing) * 70.0, 28), Color(1.0, 0.6, 0.3), 120.0, 0.5, 5.0)
		"summon", "shadow_toggle", "shadow_command":
			if stype == "summon": Net.action("summon_toggle", {}, {"silent": true})
			elif stype == "shadow_toggle": Net.action("shadow_toggle", {}, {"silent": true})
			if not custom_fx: _fxs.ring(_player.position + Vector2(0, 28), Color(0.7, 0.5, 1.0), 80.0, 0.6, 4.0)
	if stype != "dash" and float(sk.get("power", 0.0)) > 0.0:
		_skill_damage(id, sk, stype, kind)
	_hud_dirty = true

## Mục tiêu gần nhất cho Tuyệt Phẩm "execute" (quái sống, trong tầm ngang/dọc).
func _exec_target(range_x: float, reach_y: float) -> Node2D:
	var best: Node2D = null
	var bd := 1e9
	for u in _mobs.keys():
		var m: Node2D = _mobs[u]
		if not is_instance_valid(m) or int(m.get("hp")) <= 0: continue
		var dx := absf(m.position.x - _player.position.x)
		if dx < range_x and absf(m.position.y - _player.position.y) < reach_y and dx < bd:
			bd = dx; best = m
	return best

func _dash(distance: float) -> void:
	var from := _player.position
	var steps := int(distance / 16.0)
	for i in range(steps):
		var nx := _player.position.x + float(_facing) * 16.0
		if not _walkable(nx, _player.position.y + 28.0) or nx < 20.0 or nx > float(_cols) * TILE - 20.0: break
		_player.position.x = nx
	_fxs.dash_trail(from + Vector2(0, 8), _player.position + Vector2(0, 8))
	_invuln_until = Time.get_ticks_msec() + 250

## Màu viền nút kỹ năng theo loại: tuyệt kỹ vàng, tấn công cam, phòng thủ xanh dương, hồi phục xanh lá, triệu hồi tím.
func _skill_color(sk: Dictionary) -> Color:
	if sk.is_empty(): return Color(0.45, 0.5, 0.6)
	if bool(sk.get("ult", false)): return Color(1.0, 0.82, 0.36)
	match str(sk.get("type", "")):
		"guard", "manashield", "buff": return Color(0.45, 0.72, 1.0)
		"heal": return Color(0.45, 0.9, 0.6)
		"summon", "shadow_toggle", "shadow_command": return Color(0.75, 0.55, 1.0)
	return Color(1.0, 0.6, 0.35)

func _carry(key: String, amount: float) -> int:
	var v := float(_carry_acc.get(key, 0.0)) + amount
	var whole := int(floor(v))
	_carry_acc[key] = v - float(whole)
	return whole
