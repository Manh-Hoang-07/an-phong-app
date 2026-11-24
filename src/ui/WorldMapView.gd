extends Control
## Bản đồ thế giới dạng sơ đồ: các khu là điểm tròn nối với nhau bằng đường (giống web, cùng thuật toán bố cục).
## Kéo để di chuyển, chạm một điểm để xem thông tin. Chỉ để xem; muốn đi phải tới cổng trong game.

signal selected(id: String)

const T := preload("res://src/ui/UITheme.gd")
const ROOT_MAP := "cong_do"
const W := 1320.0
const H := 1320.0

static var _cache: Dictionary = {}      # {pos, edges, depth}
static var _pan := Vector2(INF, INF)    # nhớ vị trí kéo giữa các lần mở panel
static var sel := ""
static var zoom := 0.8
const ZOOMS := [0.35, 0.5, 0.65, 0.8, 1.0]

var _canvas: Control
var _press_pos := Vector2.ZERO
var _pressed := false
var _moved := false
var _bg_tex: GradientTexture2D

func _ready() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(200, 200)
	# Mỗi lần mở panel: căn lại theo zoom vừa khung, không dùng pan cũ của lần trước.
	_pan = Vector2(INF, INF)
	var grad := Gradient.new()
	grad.set_color(0, Color("f0dcae"))
	grad.add_point(0.7, Color("d9bb80"))
	grad.set_color(grad.get_point_count() - 1, Color("b48f55"))
	_bg_tex = GradientTexture2D.new()
	_bg_tex.gradient = grad
	_bg_tex.fill = GradientTexture2D.FILL_RADIAL
	_bg_tex.fill_from = Vector2(0.5, 0.48)
	_bg_tex.fill_to = Vector2(1.0, 0.98)
	_bg_tex.width = 256
	_bg_tex.height = 256
	_canvas = _Canvas.new()
	_canvas.view = self
	_canvas.size = Vector2(W, H)
	_canvas.custom_minimum_size = Vector2(W, H)
	_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_canvas)
	resized.connect(_on_resized)
	_build_zoom_buttons()
	if sel.is_empty(): sel = str(Game.player.get("map", ROOT_MAP))

var _need_init := true

func _on_resized() -> void:
	# Bỏ qua resize giả lúc control mới tạo (size = custom_minimum_size 200).
	if size.x < 300.0: return
	if _need_init:
		_need_init = false
		_init_pan()
	else:
		_clamp_pan()

func _init_pan() -> void:
	# Lấp đầy chiều ngang panel (chiều cao được cắt/kéo bằng pan) -> hết khoảng đen bên phải.
	if size.x <= 20.0: return
	_need_init = false
	zoom = clampf(size.x / W, 0.3, 1.0)
	if _pan.x == INF or _pan.x == -INF: center_on(str(Game.player.get("map", ROOT_MAP)))
	else: _apply_pan()

func center_on(id: String) -> void:
	var L := layout()
	var q: Vector2 = L["pos"].get(id, Vector2(W * 0.5, H * 0.5))
	_pan = -q * zoom + size * 0.5
	_apply_pan()

func _clamp_pan() -> void:
	# Cho phép căn giữa khi bản đồ nhỏ hơn khung; vẫn chặn kéo quá đà khi phóng to.
	var min_x := minf(0.0, size.x - W * zoom)
	var min_y := minf(0.0, size.y - H * zoom)
	var max_x := maxf(0.0, size.x - W * zoom)
	var max_y := maxf(0.0, size.y - H * zoom)
	_pan.x = clampf(_pan.x, min_x, max_x)
	_pan.y = clampf(_pan.y, min_y, max_y)

func _apply_pan() -> void:
	_clamp_pan()
	_canvas.position = _pan
	_canvas.scale = Vector2(zoom, zoom)

func _build_zoom_buttons() -> void:
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	box.offset_left = -44; box.offset_right = -6; box.offset_top = 6; box.offset_bottom = 90
	box.add_theme_constant_override("separation", 4)
	add_child(box)
	for d in [1, -1]:
		# Dùng ASCII '-' (U+2212 bị GlyphArt.clean lọc mất -> nút trừ hiện rỗng).
		var b := T.button("+" if d > 0 else "-", Vector2(38, 38))
		b.add_theme_font_size_override("font_size", 22)
		var dd: int = d
		b.pressed.connect(func(): _zoom_step(dd))
		box.add_child(b)

func _zoom_step(d: int) -> void:
	# Zoom tự vừa khung có thể không nằm trong ZOOMS: tìm mức gần nhất rồi mới bước.
	var i := -1
	var best := INF
	for k in range(ZOOMS.size()):
		var diff := absf(float(ZOOMS[k]) - zoom)
		if diff < best: best = diff; i = k
	if i < 0: i = 2
	i = clampi(i + d, 0, ZOOMS.size() - 1)
	var centre := (size * 0.5 - _pan) / zoom
	zoom = ZOOMS[i]
	_pan = size * 0.5 - centre * zoom
	_apply_pan()

# ---------------------------------------------------------------- Nhập
func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
		if e.pressed:
			_pressed = true; _moved = false; _press_pos = e.position
		else:
			if _pressed and not _moved: _tap(e.position)
			_pressed = false
		accept_event()
	elif e is InputEventMouseMotion and _pressed:
		if (e.position - _press_pos).length() > 8.0: _moved = true
		if _moved:
			_pan += e.relative
			_apply_pan()
		accept_event()

func _tap(p: Vector2) -> void:
	var L := layout()
	var cp := (p - _canvas.position) / zoom
	var best := ""
	var bd := 1e9
	for id in L["pos"].keys():
		var q: Vector2 = L["pos"][id]
		var d := q.distance_to(cp)
		var hub := Data.is_village(Data.map_def(str(id)))
		var reach := (14.0 if hub else 8.5) + 14.0
		if d < reach and d < bd:
			bd = d
			best = str(id)
	if not best.is_empty():
		sel = best
		_canvas.queue_redraw()
		Audio.play("ui")
		selected.emit(best)

# ---------------------------------------------------------------- Trạng thái mở khoá
static func quest_done(id: String) -> bool:
	return Data.quest_done(Game.player, id)

static func is_open(id: String) -> bool:
	var m: Dictionary = Data.map_def(id)
	var req := str(m.get("require", ""))
	return req.is_empty() or quest_done(req)

static func quest_name(id: String) -> String:
	var q: Dictionary = Data.quest_by_id(id)
	return str(q.get("name", id))

## {ok, reason} của một map so với map đang đứng (giống G.mapList của web).
static func status_of(id: String) -> Dictionary:
	var cur := str(Game.player.get("map", ""))
	if id == cur: return {"ok": true, "reason": "Bạn đang ở đây", "here": true}
	var cp: Dictionary = Data.map_def(cur).get("portals", {})
	var via := ""
	for ch in cp.keys():
		if str((cp[ch] as Dictionary).get("to", "")) == id: via = str(ch); break
	var m: Dictionary = Data.map_def(id)
	if not via.is_empty():
		var portal: Dictionary = cp[via]
		for req in [str(portal.get("require", "")), str(m.get("require", ""))]:
			if not req.is_empty() and not quest_done(req):
				return {"ok": false, "reason": "Cần hoàn thành nhiệm vụ \"%s\"" % quest_name(req), "here": false}
		return {"ok": true, "reason": "Đã mở — có cổng từ đây", "here": false}
	var req2 := str(m.get("require", ""))
	if not req2.is_empty() and not quest_done(req2):
		return {"ok": false, "reason": "Cần hoàn thành nhiệm vụ \"%s\"" % quest_name(req2), "here": false}
	return {"ok": false, "reason": "Chưa có đường đi trực tiếp từ đây", "here": false}

# ---------------------------------------------------------------- Bố cục (cùng thuật toán web/panels/map.js)
static func short_name(n: String) -> String:
	if n.begins_with("Cổng đỏ"): return "Cổng đỏ"
	var parts := n.split(" – ") if n.contains(" – ") else n.split(" - ")
	var s := parts[parts.size() - 1]
	return s.substr(0, 21) + "…" if s.length() > 22 else s

static func layout() -> Dictionary:
	if not _cache.is_empty(): return _cache
	var maps: Dictionary = Data.MAPS
	var kids := {}
	var seen := {ROOT_MAP: true}
	var edges: Array = []
	_grow(ROOT_MAP, maps, kids, seen, edges)
	for id in maps.keys():
		if not seen.has(id):
			seen[id] = true
			(kids[ROOT_MAP] as Array).append(id)
			kids[id] = []
			edges.append([ROOT_MAP, id])
	var state := [20240611]
	var rnd := func() -> float:
		state[0] = (int(state[0]) * 1664525 + 1013904223) & 0xFFFFFFFF
		return float(state[0]) / 4294967296.0
	var n := kids.size()
	var step := 1.15 / sqrt(float(n))
	var P := {ROOT_MAP: {"x": 0.5, "y": 0.5, "a": 0.0}}
	var depth := {ROOT_MAP: 0}
	_place(ROOT_MAP, kids, P, depth, step, rnd)
	var x0 := 1e9; var x1 := -1e9; var y0 := 1e9; var y1 := -1e9
	for id in P.keys():
		x0 = minf(x0, P[id]["x"]); x1 = maxf(x1, P[id]["x"]); y0 = minf(y0, P[id]["y"]); y1 = maxf(y1, P[id]["y"])
	var pad := 56.0
	var pos := {}
	for id in P.keys():
		var sx := (float(P[id]["x"]) - x0) / maxf(x1 - x0, 0.0001)
		var sy := (float(P[id]["y"]) - y0) / maxf(y1 - y0, 0.0001)
		pos[id] = Vector2(pad + sx * (W - 2.0 * pad), pad + sy * (H - 2.0 * pad))
	# Đẩy nhau cho khỏi chồng khung tên
	var ids: Array = pos.keys()
	var box := {}
	var font := T.font(true)
	for id in ids:
		var m: Dictionary = maps[id]
		var hub := Data.is_village(m)
		var nm := short_name(str(m.get("name", id)))
		var r := 14.0 if hub else 8.5
		var lw := font.get_string_size(nm, HORIZONTAL_ALIGNMENT_LEFT, -1, 14 if hub else 12).x + 10.0
		box[id] = Vector2(maxf(2.0 * r + 14.0, lw) + 26.0, 2.0 * r + 16.0 + 26.0)
	for it in range(200):
		var moved := false
		for i in range(ids.size()):
			for j in range(i + 1, ids.size()):
				var a: Vector2 = pos[ids[i]]
				var b: Vector2 = pos[ids[j]]
				var ba: Vector2 = box[ids[i]]
				var bb: Vector2 = box[ids[j]]
				var dx := b.x - a.x
				var dy := b.y - a.y
				var ox := (ba.x + bb.x) / 2.0 - absf(dx)
				var oy := (ba.y + bb.y) / 2.0 - absf(dy)
				if ox <= 0.0 or oy <= 0.0: continue
				moved = true
				if ox < oy:
					var s := (1.0 if dx >= 0.0 else -1.0) * (ox / 2.0 + 0.5)
					a.x -= s; b.x += s
				else:
					var s2 := (1.0 if dy >= 0.0 else -1.0) * (oy / 2.0 + 0.5)
					a.y -= s2; b.y += s2
				pos[ids[i]] = a
				pos[ids[j]] = b
		for id in ids:
			var q: Vector2 = pos[id]
			q.x = clampf(q.x, 60.0, W - 60.0)
			q.y = clampf(q.y, 50.0, H - 50.0)
			pos[id] = q
		if not moved: break
	_cache = {"pos": pos, "edges": edges, "depth": depth}
	return _cache

static func _grow(id: String, maps: Dictionary, kids: Dictionary, seen: Dictionary, edges: Array) -> void:
	kids[id] = []
	var portals: Dictionary = (maps.get(id, {}) as Dictionary).get("portals", {})
	for k in portals.keys():
		var to := str((portals[k] as Dictionary).get("to", ""))
		if seen.has(to) or not maps.has(to): continue
		seen[to] = true
		(kids[id] as Array).append(to)
		edges.append([id, to])
		_grow(to, maps, kids, seen, edges)

static func _place(id: String, kids: Dictionary, P: Dictionary, depth: Dictionary, step: float, rnd: Callable) -> void:
	for k in kids[id]:
		var par: Dictionary = P[id]
		var best := {}
		var bs := -1e9
		for t in range(40):
			var a: float = float(par["a"]) + (float(rnd.call()) - 0.5) * 1.7 if t < 20 else float(rnd.call()) * 6.283
			var d: float = step * (0.85 + float(rnd.call()) * 0.5)
			var x: float = float(par["x"]) + cos(a) * d
			var y: float = float(par["y"]) + sin(a) * d
			if x < 0.03 or x > 0.97 or y < 0.03 or y > 0.97: continue
			var md := 9.0
			for o in P.keys():
				if o != id: md = minf(md, Vector2(float(P[o]["x"]) - x, float(P[o]["y"]) - y).length())
			var s: float = minf(md, step * 1.2) + (0.02 if t < 20 else 0.0) + float(rnd.call()) * 0.03
			if md > step * 0.55 and s > bs:
				bs = s
				best = {"x": x, "y": y, "a": a}
		if best.is_empty():
			var a2: float = float(rnd.call()) * 6.283
			best = {"x": clampf(float(par["x"]) + cos(a2) * step, 0.03, 0.97), "y": clampf(float(par["y"]) + sin(a2) * step, 0.03, 0.97), "a": a2}
		P[k] = best
		depth[k] = int(depth[id]) + 1
		_place(k, kids, P, depth, step, rnd)

# ---------------------------------------------------------------- Vẽ
class _Canvas extends Control:
	var view: Control = null

	func _draw() -> void:
		if view == null: return
		var T_ := preload("res://src/ui/UITheme.gd")
		var L: Dictionary = view.layout()
		var pos: Dictionary = L["pos"]
		var depth: Dictionary = L["depth"]
		draw_texture_rect(view._bg_tex, Rect2(Vector2.ZERO, Vector2(1320, 1320)), false)
		# vân giấy
		var rng := RandomNumberGenerator.new()
		rng.seed = 7
		for i in range(900):
			draw_circle(Vector2(rng.randf() * 1320.0, rng.randf() * 1320.0), rng.randf_range(0.6, 1.8), Color(0.35, 0.24, 0.10, rng.randf_range(0.04, 0.12)))
		draw_rect(Rect2(8, 8, 1304, 1304), Color(0.48, 0.35, 0.17, 0.55), false, 2.0)
		# đường nối
		for e in L["edges"]:
			var a: Vector2 = pos[e[0]]
			var b: Vector2 = pos[e[1]]
			var open: bool = view.is_open(str(e[0])) and view.is_open(str(e[1]))
			if open: draw_line(a, b, Color(0.25, 0.56, 0.23, 0.92), 4.0, true)
			else: draw_dashed_line(a, b, Color(0.54, 0.48, 0.38, 0.9), 3.0, 7.0, true)
		var font := T_.font(true)
		var cur := str(Game.player.get("map", ""))
		for id in pos.keys():
			var m: Dictionary = Data.map_def(str(id))
			var q: Vector2 = pos[id]
			var open: bool = view.is_open(str(id))
			var here := str(id) == cur
			var hub := Data.is_village(m)
			var r := 14.0 if hub else 8.5
			var fill := Color("ffcf4a") if here else (Color("5bbf4a") if open else Color("9b9588"))
			if str(id) == view.sel:
				_dashed_ring(q, r + 7.0, Color("7b2d1a"))
			draw_circle(q, r + (2.0 if hub else 1.25), Color("7b2d1a") if hub else Color("4a3216"))
			draw_circle(q, r - (2.0 if hub else 1.25), fill)
			if here: _star(q, r * 0.7, Color("7b2d1a"))
			elif not open: _lock(q)
			var nm: String = view.short_name(str(m.get("name", id)))
			var fs := 15 if hub else 13
			var tw := font.get_string_size(nm, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
			var above := int(depth.get(id, 0)) % 2 == 0
			var ty := q.y - r - 8.0 if above else q.y + r + 16.0
			var tp := Vector2(q.x - tw * 0.5, ty)
			draw_string_outline(font, tp, nm, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 4, Color(0.94, 0.86, 0.68, 0.95))
			draw_string(font, tp, nm, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color("3a2410"))

	func _dashed_ring(c: Vector2, r: float, col: Color) -> void:
		var n := 14
		for i in range(n):
			var a0 := TAU * float(i) / float(n)
			draw_arc(c, r, a0, a0 + TAU / float(n) * 0.6, 6, col, 2.5, true)

	func _star(c: Vector2, r: float, col: Color) -> void:
		var pts := PackedVector2Array()
		for i in range(10):
			var rr := r if i % 2 == 0 else r * 0.45
			var a := -PI * 0.5 + PI * float(i) / 5.0
			pts.append(c + Vector2(cos(a), sin(a)) * rr)
		draw_colored_polygon(pts, col)

	func _lock(c: Vector2) -> void:
		draw_rect(Rect2(c.x - 3.6, c.y - 0.5, 7.2, 5.2), Color("4a3216"))
		draw_arc(c + Vector2(0, -0.5), 2.6, PI, TAU, 8, Color("4a3216"), 1.6, true)
