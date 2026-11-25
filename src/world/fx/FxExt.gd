extends RefCounted
## Sổ đăng ký các bộ hiệu ứng kỹ năng riêng theo nhóm class (mỗi file FxExt_*.gd do một người sửa).
## Mỗi bộ có: IDS {id_kỹ_năng: tên_sig}, CFG {sig: {place, dur, nopop, rumble}}, static draw(s, sig, t, lowq).
const ALL := [
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
