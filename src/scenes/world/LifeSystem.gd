extends "res://src/scenes/world/WorldPart.gd"
## Sinh tồn: nhận sát thương, chết/hồi sinh, hồi HP/MP, thể lực, lưu trạng thái, phiếu thưởng.
## Hệ thống của World (w = World). Trạng thái riêng khai báo ngay dưới; trạng thái dùng chung đọc qua thuộc tính chuyển tiếp.

# Trạng thái riêng
var _phase_cd := 0                   # bộ Vĩnh Hằng: lướt qua đòn
var _stone_cd := 0                   # bộ Thạch Vương: khiên đá
var _laststand_cd := 0               # Bùa Hộ Mệnh (Kỳ Nguyên Bất Tử)
var _laststand_until := 0
# mạng / lưu
var _pending_kills: Array = []
var _kill_timer: SceneTreeTimer = null
var _regen_acc := 0.0
var _sta_warn_at := 0

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
var _map_id: String:
	get: return w._map_id
	set(x): w._map_id = x
var _facing: int:
	get: return w._facing
	set(x): w._facing = x
var _move_dir: Vector2:
	get: return w._move_dir
	set(x): w._move_dir = x
var _vy: float:
	get: return w._vy
	set(x): w._vy = x
var _knock_vx: float:
	get: return w._knock_vx
	set(x): w._knock_vx = x
var _knock_until: int:
	get: return w._knock_until
	set(x): w._knock_until = x
var _hurt_until: int:
	get: return w._hurt_until
	set(x): w._hurt_until = x
var _invuln_until: int:
	get: return w._invuln_until
	set(x): w._invuln_until = x
var _last_hurt: int:
	get: return w._last_hurt
	set(x): w._last_hurt = x
var _buffs: Dictionary:
	get: return w._buffs
	set(x): w._buffs = x
var _slow_until: int:
	get: return w._slow_until
	set(x): w._slow_until = x
var _free_cast_used: bool:
	get: return w._free_cast_used
	set(x): w._free_cast_used = x
var _dead: bool:
	get: return w._dead
	set(x): w._dead = x
var _changing: bool:
	get: return w._changing
	set(x): w._changing = x
var _hud_dirty: bool:
	get: return w._hud_dirty
	set(x): w._hud_dirty = x
var _sta_used_at: int:
	get: return w._sta_used_at
	set(x): w._sta_used_at = x
var _sta_frac: float:
	get: return w._sta_frac
	set(x): w._sta_frac = x

# Hàm của hệ thống khác
func _buff_sum(key: String) -> float:
	return w.buffs._buff_sum(key)

func _buff_sum_of(name: String, key: String) -> float:
	return w.buffs._buff_sum_of(name, key)

func _weapon() -> Dictionary:
	return w.combat._weapon()

func _share_to_companions(dmg: int) -> void:
	w.pets._share_to_companions(dmg)

func _pets_tick(now: int) -> void:
	w.pets._pets_tick(now)

func _pets_payload() -> Dictionary:
	return w.pets._pets_payload()

func _fusion_expire_tick() -> void:
	w.pets._fusion_expire_tick()

func shake(strength: float, duration: float) -> void:
	w.shake(strength, duration)

func _end_form(reason: String) -> void:
	w.form._end_form(reason)

func _carry(key: String, amount: float) -> int:
	return w.combat._carry(key, amount)

## `mult`: hệ số của đòn (giậm đất 1.5, chiêu trùm theo style); `enrage_scale`: đòn lao thường nhân thêm 1.25 khi quái phẫn nộ.
func _hurt_player(m: Node2D, mult: float = 1.0, enrage_scale: bool = true) -> void:
	var now := Time.get_ticks_msec()
	if now < _invuln_until or _dead: return
	var fx: Dictionary = Game.special_fx()
	# Cánh Phiêu Diêu: né hoàn toàn một đòn
	var dodge: Dictionary = Game._as_dict(fx.get("dodge", {}))
	if not dodge.is_empty() and randf() < float(dodge.get("chance", 0.0)):
		FloatText.spawn(_fx, _player.position + Vector2(0, -34), "Né", Color(0.56, 0.94, 1.0), 17)
		Audio.play("cast", 1.4)
		_invuln_until = now + 300
		return
	# Bộ Vĩnh Hằng 10 món: lướt qua đòn mỗi `cd` giây
	var phase: Dictionary = Game._as_dict(fx.get("setPhase", {}))
	if not phase.is_empty() and now >= _phase_cd:
		_phase_cd = now + int(float(phase.get("cd", 8.0)) * 1000.0)
		FloatText.spawn(_fx, _player.position + Vector2(0, -34), "Xuyên Không", Color(0.70, 0.53, 1.0), 16)
		_invuln_until = now + 300
		return
	# Bộ Thạch Vương 10 món: khiên đá đỡ trọn một đòn mỗi `cd` giây
	var stone: Dictionary = Game._as_dict(fx.get("setStone", {}))
	if not stone.is_empty() and now >= _stone_cd:
		_stone_cd = now + int(float(stone.get("cd", 12.0)) * 1000.0)
		FloatText.spawn(_fx, _player.position + Vector2(0, -46), "Khiên Đá", Color(0.63, 0.53, 0.50), 15)
		_invuln_until = now + 400
		return
	var def_v := float(Game.stats.get("def", 0))
	var lv := int(Game.player.get("level", 1))
	var atk_v := float(m.atk) * mult
	if enrage_scale and m.enraged: atk_v *= 1.25
	var dmg := Formulas.mitigate(atk_v * randf_range(0.9, 1.1), def_v, lv)
	var mx_hp := int(Game.stats.get("maxHp", 100))
	# Nội tại Tanker "Thành Đồng": máu dưới 50% giảm thêm 10%
	if float(Game.hp) < float(mx_hp) * 0.5 and Game.has_passive("tanker"): dmg = maxi(1, int(roundf(float(dmg) * 0.9)))
	# Thủ thế: giảm cộng dồn (đòn vẫn tối thiểu 1) + phản sát thương
	var reduce := _buff_sum_of("guard", "reduce")
	if reduce > 0.0:
		dmg = maxi(1, int(roundf(float(dmg) * (1.0 - reduce))))
		var refl := _buff_sum_of("guard", "reflect")
		if refl > 0.0 and m.alive and m.uid != 900001:
			var rdir := 1 if m.position.x >= _player.position.x else -1
			Socket.send_hit(int(m.uid), maxi(1, int(roundf(float(m.atk) * refl))), "", 0, rdir, false)
	# Khiên năng lượng: hấp thụ bằng MP, cộng dồn
	var absorb := _buff_sum_of("manashield", "absorb")
	if absorb > 0.0 and Game.mp > 0:
		var take := mini(Game.mp, int(roundf(float(dmg) * absorb)))
		Game.mp -= take
		dmg -= take
		if take > 0: FloatText.spawn(_fx, _player.position + Vector2(0, -46), "%d" % take, Color(0.56, 0.71, 1.0), 13)
		if dmg <= 0:
			_invuln_until = now + 500
			_hud_dirty = true
			return
	# Hộ Mệnh đang chạy: mọi đòn không trừ máu
	if _laststand_until > 0 and now < _laststand_until:
		_invuln_until = now + 400
		return
	Game.hp = maxi(0, Game.hp - dmg)
	Socket.send_hurt(int(m.uid))
	_share_to_companions(dmg)
	_last_hurt = now
	_hurt_until = now + 260
	_invuln_until = now + 700
	var dirx := signf(_player.position.x - m.position.x)
	if dirx == 0.0: dirx = 1.0
	_knock_vx = dirx * 260.0
	_knock_until = now + 220
	_vy = -220.0
	FloatText.spawn(_fx, _player.position + Vector2(0, -34), "-%d" % dmg, Color(1.0, 0.32, 0.32), 20)
	Audio.play("hurt")
	shake(3.0, 0.15)
	if _hud_node: _hud_node.flash(Color(1.0, 0.1, 0.1), 0.28)
	if Settings.haptics: Input.vibrate_handheld(40)
	_hud_dirty = true
	# Bùa Hộ Mệnh (Kỳ Nguyên Bất Tử): máu cạn thì giữ 1 máu trong `dur` giây, hồi lại sau `cd` giây
	var undying: Dictionary = Game._as_dict(fx.get("undying", {}))
	if Game.hp <= 0 and not undying.is_empty() and now >= _laststand_cd:
		_laststand_cd = now + int(float(undying.get("cd", 60.0)) * 1000.0)
		_laststand_until = now + int(float(undying.get("dur", 5.0)) * 1000.0)
		Game.hp = 1
		FloatText.spawn(_fx, _player.position + Vector2(0, -52), "Hộ Mệnh %ds" % int(undying.get("dur", 5)), Color(1.0, 0.88, 0.51), 16)
	if Game.hp > 0 and float(Game.hp) / float(maxi(1, mx_hp)) < 0.3: _hud_node.hint_once("lowhp", "Máu thấp! Mở Túi và dùng bình máu.")
	if Game.hp <= 0: _die()

## Hết 5 giây Hộ Mệnh mà máu vẫn <= 0 thì gục (gọi mỗi giây từ _regen).
func _laststand_tick(now: int) -> void:
	if _laststand_until > 0 and now >= _laststand_until:
		_laststand_until = 0
		if Game.hp <= 0 and not _dead: _die()

func _regen(delta: float) -> void:
	if _dead or _changing: return
	_regen_acc += delta
	if _regen_acc < 1.0: return
	_regen_acc = 0.0
	var now := Time.get_ticks_msec()
	_laststand_tick(now)
	_pets_tick(now)
	_fusion_expire_tick()
	var mx_hp := int(Game.stats.get("maxHp", 0))
	var mx_mp := int(Game.stats.get("maxMp", 0))
	var changed := false
	# Buff hồi máu liên tục: `regen` là % máu tối đa mỗi 2 giây (cộng dồn)
	var regen_pct := _buff_sum("regen")
	if regen_pct > 0.0 and Game.hp < mx_hp:
		Game.hp = mini(mx_hp, Game.hp + _carry("hp_buff", float(mx_hp) * regen_pct / 2.0))
		changed = true
	# Cấm Chú Giải Phóng: đang phong ấn năng lượng thì không hồi MP bằng đường nào
	var mp_locked := float(Game.player.get("mpLock", 0)) > Time.get_unix_time_from_system() * 1000.0
	# Nội tại Dòng Chảy (Pháp Sư): hồi 0,5% MP mỗi giây kể cả khi đang đánh
	if Game.has_passive("phap_su") and not mp_locked and Game.mp < mx_mp:
		Game.mp = mini(mx_mp, Game.mp + _carry("mp_flow", float(mx_mp) * 0.005))
		changed = true
	# Chỉ hồi khi KHÔNG giao chiến (không đánh / không bị đánh trong calmMs gần nhất), như web
	var calm_ms := int(Game._as_dict(Data.calc.get("REGEN", {})).get("calmMs", 2000))
	var fighting := now - _sta_used_at < calm_ms or now - _last_hurt < calm_ms
	if not fighting:
		# Đồ nhiễm đỏ: không hồi máu ngoài giao chiến
		if Game.hp < mx_hp and int(Game.stats.get("nhiem", 0)) == 0:
			Game.hp = mini(mx_hp, Game.hp + _carry("hp_calm", maxf(float(Game._as_dict(Data.calc.get("REGEN", {})).get("hp", 1)), float(mx_hp) * 0.005)))
			changed = true
		if Game.mp < mx_mp and not mp_locked:
			Game.mp = mini(mx_mp, Game.mp + _carry("mp_calm", maxf(float(Game._as_dict(Data.calc.get("REGEN", {})).get("mp", 1)), float(mx_mp) * 0.005)))
			changed = true
	if changed: _hud_dirty = true

## Hồi chút khi hạ quái (Chuông Trấn Hồn): % máu / năng lượng tối đa.
func _on_my_kill() -> void:
	var fx: Dictionary = Game._as_dict(Game.special_fx().get("onKill", {}))
	if fx.is_empty() or _dead: return
	var mxh := int(Game.stats.get("maxHp", 1))
	var mxm := int(Game.stats.get("maxMp", 1))
	var hp_gain := int(roundf(float(mxh) * float(fx.get("hp", 0.0))))
	var mp_gain := int(roundf(float(mxm) * float(fx.get("mp", 0.0))))
	if hp_gain > 0 and Game.hp < mxh:
		Game.hp = mini(mxh, Game.hp + hp_gain)
		FloatText.spawn(_fx, _player.position + Vector2(0, -34), "+%d" % hp_gain, Color(0.41, 0.94, 0.68), 13)
	if mp_gain > 0 and Game.mp < mxm: Game.mp = mini(mxm, Game.mp + mp_gain)
	_hud_dirty = true

func _die() -> void:
	if _dead: return
	_end_form("")
	_dead = true
	Game.hp = 0
	_free_cast_used = false
	_laststand_until = 0
	_buffs.clear()   # chết thì mọi buff tan (web: resetCombatFlags)
	_slow_until = 0
	_move_dir = Vector2.ZERO
	_flush_kills()
	Audio.play("death")
	Socket.send_pos(_map_id, _player.position.x, _player.position.y, _facing, "dead", false, 0)
	if _hud_node:
		_hud_node.show_death()
	_hud_dirty = true

func _on_death_choice(where: String) -> void:
	_changing = true
	Net.action("die", {"where": where})

func _save_state() -> void:
	if _map_id.is_empty() or _changing: return
	Net.action("save", {"map": _map_id, "x": roundi(_player.position.x), "y": roundi(_player.position.y),
		"hp": Game.hp, "mp": Game.mp, "pets": _pets_payload()}, {"silent": true})

func _queue_kill(kid: String) -> void:
	_pending_kills.append({"kid": kid})
	if _kill_timer == null:
		_kill_timer = get_tree().create_timer(0.12)
		_kill_timer.timeout.connect(_flush_kills)

func _flush_kills() -> void:
	_kill_timer = null
	if _pending_kills.is_empty(): return
	var list := _pending_kills.duplicate()
	_pending_kills.clear()
	var i := 0
	while i < list.size():
		Net.action("kills", {"list": list.slice(i, i + 15)}, {"silent": true})
		i += 15

func _attack_sta_cost() -> float:
	return maxf(1.0, roundf(float(Data.STAMINA.get("attack", 4.8)) * float(_weapon().get("cooldown", 360.0)) / 400.0))

## Trừ thể lực cho một đòn. Không đủ hoặc đang kiệt sức -> false (không đánh được).
func _spend_sta(cost: float) -> bool:
	if Game.sta_locked or float(Game.sta) < cost:
		Game.sta_locked = true
		var now := Time.get_ticks_msec()
		if now > _sta_warn_at:
			_sta_warn_at = now + 1500
			FloatText.spawn(_fx, _player.position + Vector2(0, -52), "Kiệt sức", Color(1.0, 0.79, 0.16), 14)
			if _hud_node: _hud_node.toast("Hết thể lực! Chờ hồi lại rồi đánh tiếp.", "warn")
		return false
	Game.sta = maxi(0, int(roundf(float(Game.sta) - cost)))
	_sta_used_at = Time.get_ticks_msec()
	_sta_frac = float(Game.sta)
	_hud_dirty = true
	return true

func _stamina_tick(delta: float) -> void:
	if _dead: return
	var max_sta := int(Game.stats.get("maxSta", 100))
	if _sta_frac < 0.0 or absf(_sta_frac - float(Game.sta)) > 1.5: _sta_frac = float(Game.sta)
	if _sta_frac < float(max_sta):
		var rate := 1.0 if Time.get_ticks_msec() - _sta_used_at > int(Data.STAMINA.get("delay", 800)) else float(Data.STAMINA.get("activeMul", 0.3))
		_sta_frac = minf(float(max_sta), _sta_frac + float(Data.STAMINA.get("regen", 12.0)) * rate * (1.0 + float(Game.stats.get("staRegen", 0.0)) / 100.0) * delta)
		var new_sta := int(_sta_frac)
		if new_sta != Game.sta:
			Game.sta = new_sta
			_hud_dirty = true
	if Game.sta_locked and float(Game.sta) >= float(max_sta) * float(Data.STAMINA.get("unlock", 0.3)):
		Game.sta_locked = false
