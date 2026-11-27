extends "res://src/scenes/world/WorldPart.gd"
## Hiệu ứng (buff) của người chơi: cộng dồn, hết hạn, hồi máu kỹ năng, báo HUD.
## Hệ thống của World (w = World). Trạng thái riêng khai báo ngay dưới; trạng thái dùng chung đọc qua thuộc tính chuyển tiếp.

# Trạng thái riêng
var _buff_hud_acc := 0.0

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
var _facing: int:
	get: return w._facing
	set(x): w._facing = x
var _buffs: Dictionary:
	get: return w._buffs
	set(x): w._buffs = x
var _hud_dirty: bool:
	get: return w._hud_dirty
	set(x): w._hud_dirty = x

## Quét hình chữ nhật trước mặt, gửi đòn cho MỌI quái trúng (khớp hitBox của web).
## Tổng một chỉ số buff (atk / crit / speed) của mọi hiệu ứng còn hạn — cộng dồn như web (buffTotals).
func _buff_sum(key: String) -> float:
	var now := Time.get_ticks_msec()
	var t := 0.0
	for id in _buffs.keys():
		var b: Dictionary = _buffs[id]
		if now < int(b.get("until", 0)): t += float(b.get(key, 0.0))
	return t

## Như trên nhưng chỉ tính buff cùng loại (guard: reduce/reflect, manashield: absorb).
func _buff_sum_of(name: String, key: String) -> float:
	var now := Time.get_ticks_msec()
	var t := 0.0
	for id in _buffs.keys():
		var b: Dictionary = _buffs[id]
		if now < int(b.get("until", 0)) and str(b.get("name", "")) == name: t += float(b.get(key, 0.0))
	return t

## Buff đang bật mang tên này ({} nếu không có) — buffOn của web.
func _buff_on(name: String) -> Dictionary:
	var now := Time.get_ticks_msec()
	for id in _buffs.keys():
		var b: Dictionary = _buffs[id]
		if now < int(b.get("until", 0)) and str(b.get("name", "")) == name: return b
	return {}

func _add_buff(id: String, sk: Dictionary, stype: String) -> void:
	var dur := float(sk.get("duration", 0.0))
	if dur <= 0.0: return
	_buffs[id] = {
		"name": str(sk.get("buff", id)) if stype == "buff" else stype, "until": Time.get_ticks_msec() + int(dur * 1000.0),
		"reduce": float(sk.get("reduce", 0.0)), "reflect": float(sk.get("reflect", 0.0)), "absorb": float(sk.get("absorb", 0.0)),
		"atk": float(sk.get("atkBuff", 0.0)), "crit": float(sk.get("critBuff", 0.0)), "speed": float(sk.get("speedBuff", 0.0)),
		"regen": float(sk.get("regen", 0.0)), "exec": sk.get("exec", null), "dur": int(dur * 1000.0), "skill": id,
	}

## Hồi máu theo % máu tối đa; Trị Liệu Sư hồi thêm 20% (skillHeal của web).
func _skill_heal(ratio: float) -> void:
	var boost := 1.2 if Game.has_passive("tri_lieu_su") else 1.0
	var mx := int(Game.stats.get("maxHp", 1))
	var amount := int(roundf(float(mx) * ratio * boost))
	Game.hp = mini(mx, Game.hp + amount)
	FloatText.spawn(_fx, _player.position + Vector2(0, -30), "+%d" % amount, Color(0.41, 0.94, 0.68), 16)
	_hud_dirty = true

func _buff_hud_tick(delta: float) -> void:
	_buff_hud_acc += delta
	if _buff_hud_acc < 0.12: return
	_buff_hud_acc = 0.0
	if _skill_fx != null and _skill_fx.has_method("sync_auras"): _skill_fx.sync_auras(_buffs, _player, _facing)   # hào quang buff theo người suốt thời gian hiệu lực
	if _hud_node == null: return
	var now := Time.get_ticks_msec()
	var list: Array = []
	for id in _buffs.keys():
		var b: Dictionary = _buffs[id]
		var left := int(b.get("until", 0)) - now
		if left <= 0: continue
		var sk: Dictionary = Data.skill(str(b.get("skill", id)))
		var icon := GlyphArt.skill_token(str(id), str(sk.get("icon", "@star"))) if not sk.is_empty() else "@star"
		list.append({"id": str(id), "icon": icon, "label": str(sk.get("name", b.get("name", id))), "left": left, "dur": maxi(1, int(b.get("dur", left)))})
	# Bùa nhân đôi kinh nghiệm: mốc hết hạn là unix ms do server lưu trong player.boosts.exp.
	var boosts: Dictionary = Game._as_dict(Game.player.get("boosts", {}))
	var exp_until := int(boosts.get("exp", 0))
	var exp_left := exp_until - int(Time.get_unix_time_from_system() * 1000.0)
	if exp_left > 0:
		list.append({"id": "boost_exp", "icon": "x2", "label": "Bùa x2 kinh nghiệm", "left": exp_left, "dur": 3600000})
	_hud_node.set_buffs(list)
