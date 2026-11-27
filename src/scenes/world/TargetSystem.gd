extends "res://src/scenes/world/WorldPart.gd"
## Nhắm mục tiêu (như target.js của web): chọn quái, vòng đánh dấu, góc nhắm.
## Hệ thống của World (w = World). Trạng thái riêng khai báo ngay dưới; trạng thái dùng chung đọc qua thuộc tính chuyển tiếp.

## ---- Mục tiêu quái (mũi tên tam giác như web): quái gần nhất trong tầm được chỉ định, chỉ quái đó hiện tên.
## Chọn lại 5 lần/giây (không phải mỗi khung) với cùng tầm + cách tính điểm như web (target.js).
const TARGET_RX := 520.0
const TARGET_RY := 260.0

# Trạng thái riêng
var _target_mark: Node2D = null
var _target_acc := 0.0

# Trạng thái dùng chung (lưu ở World)
var _mob_layer: Node2D:
	get: return w._mob_layer if is_instance_valid(w._mob_layer) else null
	set(x): w._mob_layer = x
var _player: Node2D:
	get: return w._player if is_instance_valid(w._player) else null
	set(x): w._player = x
var _mobs: Dictionary:
	get: return w._mobs
	set(x): w._mobs = x
var _facing: int:
	get: return w._facing
	set(x): w._facing = x
var _target_mob: Node2D:
	get: return w._target_mob if is_instance_valid(w._target_mob) else null
	set(x): w._target_mob = x
var _target_t: float:
	get: return w._target_t
	set(x): w._target_t = x

func _update_target(delta: float) -> void:
	_target_t += delta
	_target_acc += delta
	if _target_acc >= 0.2:
		_target_acc = 0.0
		_pick_target()
	var ok: bool = _target_mob != null and is_instance_valid(_target_mob) and _target_mob.alive
	if not ok:
		if _target_mark != null: _target_mark.visible = false
		return
	if _target_mark == null or not is_instance_valid(_target_mark):
		_target_mark = _TargetMark.new()
		_target_mark.z_index = 50
		_mob_layer.add_child(_target_mark)
	# Đặt trên đầu quái (cùng mốc với dòng tên), nhấp nhô nhẹ
	_target_mark.visible = true
	_target_mark.position = _target_mob.position + Vector2(0, -_target_mob._height - 44.0 + sin(_target_t * 7.7) * 4.0)

func _pick_target() -> void:
	var best: Node2D = null
	var best_score := 1e9
	for u in _mobs.keys():
		var m: Node2D = _mobs[u]
		if not is_instance_valid(m) or not m.alive: continue
		var dx := absf(m.position.x - _player.position.x)
		var dy := absf(m.position.y - _player.position.y)
		if dx >= TARGET_RX or dy >= TARGET_RY: continue
		var score := dx + dy * 0.5
		if score < best_score:
			best_score = score
			best = m
	if best == _target_mob: return
	if _target_mob != null and is_instance_valid(_target_mob): _target_mob.show_name(false)
	_target_mob = best
	if best != null: best.show_name(true)

## Quay mặt về quái đang chỉ định trước khi tung kỹ năng đánh thẳng.
func _aim_at_target() -> void:
	var m := _target_mob
	if m == null or not is_instance_valid(m) or not m.alive: return
	var dx: float = m.position.x - _player.position.x
	if absf(dx) > 8.0: _facing = -1 if dx < 0.0 else 1

## Góc bắn (rad, theo hướng đã quay mặt) để đạn bay vào đúng quái đang chỉ định, kẹp ±0,6.
func _target_angle() -> float:
	var m := _target_mob
	if m == null or not is_instance_valid(m) or not m.alive: return 0.0
	var dx: float = absf(m.position.x - _player.position.x)
	if dx < 30.0: return 0.0
	var cy: float = m.position.y - float(m._height) * 0.5 if not bool(m.fly) else m.position.y
	return clampf(atan2(cy - _player.position.y, dx), -0.6, 0.6)
