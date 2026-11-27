extends Node2D
## NPC và cổng dịch chuyển trên bản đồ, đặt theo ký tự marker trong file map (meta.npcs / meta.portals).
## Hình NPC / cổng lấy từ web (assets/art/npc_*.png, d_portal.png do tools/export/export_art.js xuất) hoặc ảnh NPC gốc (assets/npcs).
## Tương tác bằng nút ngữ cảnh trên HUD khi đứng gần.

const T := preload("res://src/ui/UITheme.gd")
const NPC_DIR := "res://assets/npcs/"
const ART := "res://assets/art/"
# NPC có ảnh riêng: chiều cao hiển thị (px) — khớp Art NPC_IMAGES của web
const NPC_IMAGES := {"lao_su": 62.0, "tap_hoa": 62.0, "thu_kho": 64.0}
const ROLE_MARK_ICON := {"shop": "shop", "smith": "anvil", "storage": "storage", "teleport": "portal", "market": "social", "daily": "quest", "zone": "map"}

var npcs: Array = []      # [{id, pos, node, role, glyph, icon, quest_mark}]
var portals: Array = []   # [{key, to, pos, node, name}]
var _world_w := 0.0

func _art(key: String) -> Texture2D:
	var p := ART + key + ".png"
	return load(p) as Texture2D if ResourceLoader.exists(p) else null

func _art_scale(key: String) -> float:
	return 1.0 / float((Data.art_meta.get(key, {}) as Dictionary).get("scale", 1.0))

## grid: mảng 2 chiều ký tự (đã giãn). ground_fn(r, c) -> y mặt đất của cột đó.
func build(grid: Array, tile: float, meta: Dictionary, ground_fn: Callable) -> void:
	for c in get_children(): c.queue_free()
	npcs.clear()
	portals.clear()
	_world_w = float((grid[0] as Array).size()) * tile if not grid.is_empty() else 0.0
	var pos_of := {}
	for r in range(grid.size()):
		var row: Array = grid[r]
		for c in range(row.size()):
			var ch := str(row[c])
			if not pos_of.has(ch): pos_of[ch] = Vector2i(c, r)
	var npc_defs: Dictionary = meta.get("npcs", {})
	for ch in npc_defs.keys():
		if not pos_of.has(ch): continue
		var cr: Vector2i = pos_of[ch]
		var foot := Vector2(float(cr.x) * tile + tile * 0.5, float(ground_fn.call(cr.y, cr.x)))
		_add_npc(str(npc_defs[ch]), foot)
	var portal_defs: Dictionary = meta.get("portals", {})
	var gate := str(meta.get("gate", ""))
	for key in portal_defs.keys():
		if gate != "" and str(key) != gate and str(key) != "<": continue   # bản đồ có cổng gom: chỉ dựng cổng gom + lối vào
		if not pos_of.has(key): continue
		var cr2: Vector2i = pos_of[key]
		var foot2 := Vector2(float(cr2.x) * tile + tile * 0.5, float(ground_fn.call(cr2.y, cr2.x)))
		var d: Dictionary = portal_defs[key]
		_add_portal(str(key), str(d.get("to", "")), foot2, key == gate, portal_defs.size())
	_build_zone_npcs(grid, tile, meta)

## Người dẫn khu (khu_su): mỗi map 2 người ở ĐẦU và CUỐI map, map rộng (từ 156 cột) thêm 1 người ở giữa.
## Cùng thuật toán shared/logic/zone-npcs.js của web/server (server coi các chỗ này như cổng để quái không tới sát).
func _build_zone_npcs(grid: Array, tile: float, meta: Dictionary) -> void:
	if Data.npc("khu_su").is_empty() or grid.is_empty(): return
	var rows := grid.size()
	var cols := (grid[0] as Array).size()
	var used: Array = []
	for n in npcs: used.append((n["pos"] as Vector2).x)
	for p in portals: used.append((p["pos"] as Vector2).x)
	var spawn_x: Array = []
	for ch in (meta.get("spawns", {}) as Dictionary).keys():
		for r in range(rows):
			for c in range(cols):
				if str((grid[r] as Array)[c]) == str(ch): spawn_x.append(float(c) * tile + tile * 0.5)
	var marks: Array = [0.06, 0.5, 0.94] if cols >= 156 else [0.06, 0.94]
	# từ chặt tới lỏng: [cách chỗ quái xuất hiện, đất bằng mỗi bên, cách cổng / NPC khác]
	var tiers: Array = [[200.0, 2, 120.0], [120.0, 2, 120.0], [0.0, 2, 120.0], [0.0, 1, 80.0], [0.0, 0, 56.0]]
	for f in marks:
		var c0 := int(round(float(cols) * float(f)))
		var edge: bool = float(f) != 0.5
		var reach := maxi(12, int(round(float(cols) * 0.22))) if edge else 60
		var done := false
		for tier in tiers:
			for d in range(reach):
				var cand: Array = [c0]
				if d > 0:
					cand = ([c0 + d] if float(f) < 0.5 else [c0 - d]) if edge else [c0 - d, c0 + d]
				for c in cand:
					if c < 5 or c > cols - 6: continue
					var r := _zone_floor_row(grid, rows, cols, c)
					if r < 0: continue
					var ok := true
					for k in range(1, int(tier[1]) + 1):
						if _zone_floor_row(grid, rows, cols, c - k) != r or _zone_floor_row(grid, rows, cols, c + k) != r:
							ok = false
							break
					if not ok: continue
					var x := float(c) * tile + tile * 0.5
					var clash := false
					for u in used:
						if absf(float(u) - x) < float(tier[2]): clash = true; break
					if clash: continue
					for u2 in spawn_x:
						if absf(float(u2) - x) < float(tier[0]): clash = true; break
					if clash: continue
					used.append(x)
					_add_npc("khu_su", Vector2(x, float(r) * tile))
					done = true
					break
				if done: break
			if done: break

func _zone_cell(grid: Array, rows: int, cols: int, r: int, c: int) -> String:
	if r < 0 or r >= rows or c < 0 or c >= cols: return "#"
	return str((grid[r] as Array)[c])

func _zone_floor_row(grid: Array, rows: int, cols: int, c: int) -> int:
	for r in range(rows - 1, 2, -1):
		var ch := _zone_cell(grid, rows, cols, r, c)
		if ch != "#" and ch != "=": continue
		var ok := true
		for k in [1, 2, 3]:
			var up := _zone_cell(grid, rows, cols, r - k, c)
			if up == "#" or up == "%" or up == "\"": ok = false; break
		if ok: return r
	return -1

## Ẩn / hiện NPC theo tiến độ cốt truyện (appear) — giống web. npc_an do World quản lý riêng.
func refresh_visibility(player: Dictionary, map_id: String) -> void:
	for n in npcs:
		var id := str(n["id"])
		var show := true
		if id != "npc_an" and id != "khu_su": show = Data.npc_here(player, map_id, id)
		(n["node"] as Node2D).visible = show

## Hình NPC: ảnh gốc (nếu có) hoặc hình vẽ của web; chân ở (0,0), căn giữa theo chiều ngang.
func make_npc_visual(id: String, def: Dictionary, flip: bool = false) -> Node2D:
	var root := Node2D.new()
	var spr := Sprite2D.new()
	spr.centered = false
	var tex: Texture2D = null
	var sc := 1.0
	if NPC_IMAGES.has(id):
		var p := NPC_DIR + id + ".png"
		if ResourceLoader.exists(p):
			tex = load(p) as Texture2D
			sc = float(NPC_IMAGES[id]) / float(tex.get_height())
	if tex == null:
		var look := str(def.get("look", id))
		for key in ["npc_" + id, "npc_" + look]:
			tex = _art(key)
			if tex != null:
				sc = _art_scale(key)
				break
	if tex == null:
		tex = _art("npc_he_thong")
		sc = _art_scale("npc_he_thong")
	if tex != null:
		spr.texture = tex
		spr.scale = Vector2(-sc if flip else sc, sc)
		spr.position = Vector2((float(tex.get_width()) * sc * 0.5) if flip else -float(tex.get_width()) * sc * 0.5, -float(tex.get_height()) * sc)
		spr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		root.add_child(spr)
	return root

func _add_npc(id: String, foot: Vector2) -> void:
	var def: Dictionary = Data.npc(id)
	var n := Node2D.new()
	n.position = foot
	n.z_index = 0   # cùng lớp với nhân vật; MapLayer đứng trước Player trong cây nên NPC luôn nằm SAU nhân vật (trước đây z=2 che mất người đứng cạnh)
	add_child(n)
	# bóng dưới chân
	var shadow := _Shadow.new()
	shadow.z_index = 0   # bóng vẽ trước (add_child trước ảnh NPC) nên nằm dưới ảnh
	n.add_child(shadow)
	var vis := make_npc_visual(id, def, foot.x > _world_w * 0.5)
	n.add_child(vis)
	var tw0 := vis.create_tween().set_loops()
	tw0.tween_property(vis, "scale:y", 1.02, 1.3).set_trans(Tween.TRANS_SINE)
	tw0.tween_property(vis, "scale:y", 1.0, 1.3).set_trans(Tween.TRANS_SINE)
	var name_bg := PanelContainer.new()
	name_bg.position = Vector2(-70, -84)
	name_bg.custom_minimum_size = Vector2(140, 0)
	name_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var name_sb := StyleBoxFlat.new()
	name_sb.bg_color = Color(0.02, 0.03, 0.06, 0.55)
	name_sb.set_corner_radius_all(7)
	name_sb.set_content_margin_all(4)
	name_bg.add_theme_stylebox_override("panel", name_sb)
	var name_l := T.label(str(def.get("name", id)), 12, Color("ffe9a8"), true)
	name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_bg.add_child(name_l)
	n.add_child(name_bg)
	# Dấu trên đầu: dấu nhiệm vụ (ảnh web) hoặc icon dịch vụ
	var role := str(def.get("role", ""))
	var mark := Node2D.new()
	mark.position = Vector2(0, -100)
	n.add_child(mark)
	var qm := Sprite2D.new()
	qm.scale = Vector2(1.5, 1.5)
	qm.position = Vector2(0, -12)
	qm.visible = false
	mark.add_child(qm)
	# Không vẽ biểu tượng dịch vụ trên đầu NPC nữa — chỉ còn dấu nhiệm vụ.
	var icon_spr := Sprite2D.new()
	mark.add_child(icon_spr)
	var tw := mark.create_tween().set_loops()
	tw.tween_property(mark, "position:y", -106.0, 0.5)
	tw.tween_property(mark, "position:y", -100.0, 0.5)
	npcs.append({"id": id, "pos": foot, "node": n, "role": role, "qmark": qm, "icon": icon_spr})

func has_npc(id: String) -> bool:
	for n in npcs:
		if str(n["id"]) == id: return true
	return false

func spawn_npc(id: String, foot: Vector2) -> void:
	if not has_npc(id): _add_npc(id, foot)

func remove_npc(id: String) -> void:
	for i in range(npcs.size() - 1, -1, -1):
		if str(npcs[i]["id"]) == id:
			(npcs[i]["node"] as Node).queue_free()
			npcs.remove_at(i)

## Cập nhật dấu "!" / "?" theo nhiệm vụ chính hiện tại: chỉ NPC giao nhiệm vụ mới có dấu (giống web).
func set_quest_marks(quest_npc: String, state: String) -> void:
	for n in npcs:
		var qm: Sprite2D = n["qmark"]
		var key := ""
		if str(n["id"]) == quest_npc:
			if state == "none": key = "mark_quest"
			elif state == "done": key = "mark_done"
		qm.visible = key != ""
		if key != "": qm.texture = _art(key)

func _add_portal(key: String, to: String, foot: Vector2, is_gate: bool, total: int) -> void:
	var n := Node2D.new()
	n.position = foot
	n.z_index = -3
	add_child(n)
	var tex := _art("d_portal")
	if tex != null:
		var sc := _art_scale("d_portal")
		var spr := Sprite2D.new()
		spr.texture = tex
		spr.centered = false
		spr.scale = Vector2(sc, sc)
		spr.position = Vector2(-float(tex.get_width()) * sc * 0.5, -float(tex.get_height()) * sc)
		var mat := CanvasItemMaterial.new()
		mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		spr.material = mat
		spr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		n.add_child(spr)
		var tw := spr.create_tween().set_loops()
		tw.tween_property(spr, "scale:x", sc * 0.85, 0.7).set_trans(Tween.TRANS_SINE)
		tw.tween_property(spr, "scale:x", sc, 0.7).set_trans(Tween.TRANS_SINE)
	var dest := str(Data.map_def(to).get("name", to))
	var text := "Cổng dịch chuyển" if (is_gate and total > 1) else dest
	var l := T.hud_label(text, 13, Color("e1d5ff"), true)
	l.position = Vector2(-80, -138)
	l.custom_minimum_size = Vector2(160, 0)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.z_index = 6
	n.add_child(l)
	portals.append({"key": key, "to": to, "pos": foot, "node": n, "name": text})

## NPC / cổng gần nhất trong tầm tương tác. Trả {} nếu không có.
func nearest(player_foot: Vector2) -> Dictionary:
	var best := {}
	var bd := 1e9
	for p in portals:
		var d: float = absf(player_foot.x - (p["pos"] as Vector2).x)
		if d < 46.0 and absf(player_foot.y - (p["pos"] as Vector2).y) < 70.0 and d < bd:
			bd = d; best = {"type": "portal", "key": p["key"], "to": p["to"], "name": p["name"], "pos": (p["pos"] as Vector2) + Vector2(0, -170)}
	for n in npcs:
		var d2: float = absf(player_foot.x - (n["pos"] as Vector2).x)
		if not (n["node"] as Node2D).visible: continue
		if d2 < 90.0 and absf(player_foot.y - (n["pos"] as Vector2).y) < 70.0 and d2 < bd:
			bd = d2; best = {"type": "npc", "id": n["id"], "name": str(Data.npc(str(n["id"])).get("name", n["id"])), "pos": (n["pos"] as Vector2) + Vector2(0, -122)}
	return best

class _Shadow extends Node2D:
	func _draw() -> void:
		draw_set_transform(Vector2(0, -1), 0.0, Vector2(1.0, 0.3))
		draw_circle(Vector2.ZERO, 16.0, Color(0, 0, 0, 0.28))
