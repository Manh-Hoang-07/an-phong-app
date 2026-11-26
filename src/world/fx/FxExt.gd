extends RefCounted
## Sổ đăng ký các bộ hiệu ứng kỹ năng riêng theo nhóm class (mỗi file FxExt_*.gd do một người sửa).
## Mỗi bộ có: IDS {id_kỹ_năng: tên_sig}, CFG {sig: {place, dur, nopop, rumble}}, static draw(s, sig, t, lowq).
const ALL := [
	preload("res://src/world/fx/FxExt_h.gd"),
	preload("res://src/world/fx/FxExt_i.gd"),
	preload("res://src/world/fx/FxExt_j.gd"),
	preload("res://src/world/fx/FxExt_k.gd"),
	preload("res://src/world/fx/FxExt_l.gd"),
	preload("res://src/world/fx/FxExt_m.gd"),
	preload("res://src/world/fx/FxExt_g.gd"),
	preload("res://src/world/fx/FxExt_f.gd"),
	preload("res://src/world/fx/FxExt_e.gd"),
	preload("res://src/world/fx/FxExt_a.gd"),
	preload("res://src/world/fx/FxExt_b.gd"),
	preload("res://src/world/fx/FxExt_c.gd"),
	preload("res://src/world/fx/FxExt_d.gd"),
]

static func sig_for(id: String) -> String:
	for e in ALL:
		if e.IDS.has(id): return str(e.IDS[id])
	return ""

static func cfg_for(sg: String) -> Dictionary:
	for e in ALL:
		if e.CFG.has(sg): return e.CFG[sg]
	return {}

static func draw_sig(s: Node2D, sg: String, t: float, lowq: bool) -> bool:
	for e in ALL:
		if e.CFG.has(sg):
			e.draw(s, sg, t, lowq)
			return true
	return false

## Hào quang buff kéo dài: file nhóm nào khai báo AURA_IDS chứa sig này thì nhóm đó vẽ (s.steady = true).
static func _aura_owner(sg: String) -> Variant:
	for e in ALL:
		var cm: Dictionary = e.get_script_constant_map()
		if cm.has("AURA_IDS") and sg in (cm["AURA_IDS"] as Array): return e
	return null

static func has_aura(sg: String) -> bool:
	return _aura_owner(sg) != null

static func draw_aura(s: Node2D, sg: String, t: float, lowq: bool) -> bool:
	var e: Variant = _aura_owner(sg)
	if e == null: return false
	e.draw_aura(s, sg, t, lowq)
	return true
