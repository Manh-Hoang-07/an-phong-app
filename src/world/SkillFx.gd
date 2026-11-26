extends Node2D
const FxExt := preload("res://src/world/fx/FxExt.gd")
const FxProj := preload("res://src/world/fx/FxProj.gd")
const FxCreature := preload("res://src/world/fx/FxCreature.gd")
## Bộ vẽ hiệu ứng kỹ năng cho app: đọc CÙNG file JSON với web
## (shared/data/skillfx/<id>.json, đóng gói vào res://data/skillfx/).
##
## Nguyên tắc giữ hệt web (xem public/js/scene/skillfx-json.js):
##   - Mỗi kỹ năng một file; layer có trigger → chỉ vẽ đúng lần gọi sfx().
##   - Có pool Node2D, giới hạn MAX_PARTICLES, giảm một nửa khi Settings.quality_low.
##   - Thiếu file / lỗi parse → bỏ qua, KHÔNG crash, KHÔNG làm hỏng đòn đánh.

signal fx_finished(id: String, kind: String)

const FX_DIR := "res://data/skillfx"
const MANIFEST := "res://data/skillfx/manifest.json"
const MAX_PARTICLES := 40

# primitive đang hỗ trợ (khớp kind trong JSON)
const KINDS := ["glow", "ring", "burst", "stream", "beam", "bolt", "arc", "pillar",
	"sigil", "runeDisc", "cracks", "debris", "swirl", "ghost", "flash", "shake",
	"fall", "arrowZone", "meteor"]

var _manifest: Dictionary = {}
var _recipes: Dictionary = {}
var _pool: Dictionary = {}          # key -> Array[Node2D]
var _active: Array[Dictionary] = [] # các hiệu ứng đang chạy {node, born, dur}

func _ready() -> void:
	_load_manifest()

func _load_manifest() -> void:
	if not FileAccess.file_exists(MANIFEST):
		push_warning("SkillFx: thiếu manifest.json — dùng fallback (không vẽ JSON)")
		return
	var f := FileAccess.open(MANIFEST, FileAccess.READ)
	if f == null:
		return
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parsed) == TYPE_DICTIONARY:
		var skills: Variant = parsed.get("skills", {})
		if typeof(skills) == TYPE_DICTIONARY:
			_manifest = skills

func ready() -> bool:
	return not _manifest.is_empty()

func count() -> int:
	return int(_manifest.get("size", _manifest.size()))

func recipe(id: String) -> Dictionary:
	if _recipes.has(id):
		return _recipes[id]
	var entry: Variant = _manifest.get(id, null)
	if typeof(entry) != TYPE_DICTIONARY:
		_recipes[id] = {}
		return {}
	var file := str((entry as Dictionary).get("file", id + ".json"))
	var path := FX_DIR + "/" + file
	if not FileAccess.file_exists(path):
		_recipes[id] = {}
		return {}
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		_recipes[id] = {}
		return {}
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	var out: Dictionary = parsed if typeof(parsed) == TYPE_DICTIONARY else {}
	_recipes[id] = out
	return out

# ------------------------------------------------------------------ Màu
func _color(c: Variant, colors: Array) -> Color:
	var idx := 1
	if c == "core": idx = 0
	elif c == "dark": idx = 2
	elif typeof(c) == TYPE_STRING:
		var s := str(c)
		if s.begins_with("#"):
			return Color(s)
		if s.to_lower().begins_with("0x"):
			return _hex(s)
	if idx < colors.size():
		return _hex(str(colors[idx]))
	return Color.WHITE

## Parse màu dạng "0xrrggbb" / "#rrggbb" sang Color (GDScript int() không nhận base).
static func _hex(s: String) -> Color:
	var v := s
	if v.begins_with("0x") or v.begins_with("0X"): v = v.substr(2)
	elif v.begins_with("#"): v = v.substr(1)
	if v.length() < 6: return Color.WHITE
	return Color(v.substr(0, 2).hex_to_int() / 255.0, v.substr(2, 2).hex_to_int() / 255.0, v.substr(4, 2).hex_to_int() / 255.0)

# ------------------------------------------------------------------ Pool
const GROUND := 28.0
var _add_mat: CanvasItemMaterial = null

func _additive() -> CanvasItemMaterial:
	if _add_mat == null:
		_add_mat = CanvasItemMaterial.new()
		_add_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	return _add_mat

func _take(key: String, color: Color, core: Color, ctx: Dictionary, p: Dictionary) -> _FxShape:
	var arr: Array = _pool.get(key, [])
	var node: _FxShape = null
	while not arr.is_empty() and node == null:
		var cand: Variant = arr.pop_back()
		if is_instance_valid(cand): node = cand as _FxShape
	if node == null:
		node = _FxShape.new()
		var parts := key.split("|")
		node.kind = parts[0]
		node.theme = parts[1] if parts.size() > 1 else ""
		add_child(node)
	node.steady = false
	node.auto = false
	node.dark = bool(ctx.get("dark", false))
	node.material = null if node.dark else _additive()
	node.col = color
	node.core = core
	node.p = p
	node.seed_v = randi()
	node.phase = 0.0
	node.modulate = Color.WHITE
	node.visible = true
	node.scale = Vector2.ONE
	node.rotation = 0.0
	node.z_index = 8
	node.queue_redraw()
	return node

func _give(node: Variant, key: String) -> void:
	if not is_instance_valid(node): return
	node.visible = false
	var arr: Array = _pool.get(key, [])
	if arr.size() < 64:
		arr.append(node)
	_pool[key] = arr

## Mờ dần (có thể hiện dần lúc đầu / giữ nguyên một đoạn) rồi trả node về pool.
func _fade(node: Node2D, key: String, dur: float, fade_in: float = 0.0, hold: float = 0.0) -> void:
	node.modulate.a = 0.0 if fade_in > 0.0 else 1.0
	var t := create_tween()
	if fade_in > 0.0: t.tween_property(node, "modulate:a", 1.0, dur * fade_in)
	if hold > 0.0: t.tween_interval(dur * hold)
	t.tween_property(node, "modulate:a", 0.0, maxf(0.05, dur * (1.0 - fade_in - hold))).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.tween_callback(_give.bind(node, key))

func _flash(color: Color, dur: float) -> void:
	var cl := CanvasLayer.new()
	cl.layer = 9
	var r := ColorRect.new()
	r.color = Color(color.r, color.g, color.b, 0.26)
	r.set_anchors_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cl.add_child(r)
	add_child(cl)
	var tw := create_tween()
	tw.tween_property(r, "modulate:a", 0.0, maxf(0.15, dur))
	tw.tween_callback(cl.queue_free)

## Vòng sóng nổ ra khi vật rơi chạm đất.
func _impact(pos: Vector2, color: Color, core: Color, ctx: Dictionary, r: float) -> void:
	var key := "ring|%s|%d" % [str(ctx.get("theme", "")), 1 if ctx.get("dark", false) else 0]
	var node := _take(key, color, core, ctx, {})
	node.position = pos
	node.scale = Vector2(0.2, 0.08)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(node, "scale", Vector2(r / 28.0, r / 28.0 * 0.4), 0.35).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_fade(node, key, 0.4)
	for i in range(6 if not Settings.quality_low else 3):
		var k := "burst|%s|%d" % [str(ctx.get("theme", "")), 1 if ctx.get("dark", false) else 0]
		var s := _take(k, color, core, ctx, {})
		s.position = pos
		var ang := randf_range(-PI, 0.0)
		s.rotation = ang
		s.scale = Vector2.ONE * randf_range(0.9, 1.5)
		var end := pos + Vector2(cos(ang), sin(ang)) * randf_range(30.0, r * 0.7)
		var t2 := create_tween().set_parallel(true)
		t2.tween_method(func(u: float): if is_instance_valid(s): s.position = pos + (end - pos) * u + Vector2(0, 40.0 * u * u), 0.0, 1.0, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		_fade(s, k, 0.5)

# ------------------------------------------------------------------ Vẽ một layer
func _paint(layer: Dictionary, colors: Array, origin: Vector2, facing: int, ctx: Dictionary) -> void:
	var kind := str(layer.get("kind", ""))
	if not kind in KINDS:
		return
	var p: Dictionary = layer.get("params", {})
	var dur := maxf(0.12, float(layer.get("dur", 300)) / 1000.0)
	var color := _color(layer.get("color", "main"), colors)
	var core := _color("core", colors)
	var f := float(facing) if facing != 0 else 1.0
	if kind == "flash":
		_flash(color, dur)
		return
	if kind == "shake":
		var cam := get_viewport().get_camera_2d()
		if cam:
			var amount := float(p.get("intensity", 0.01)) * 900.0
			var tws := create_tween()
			tws.tween_property(cam, "offset", Vector2(randf_range(-amount, amount), randf_range(-amount, amount)), 0.05)
			tws.tween_property(cam, "offset", Vector2.ZERO, dur)
		return
	var key := "%s|%s|%d" % [kind, str(ctx.get("theme", "")), 1 if ctx.get("dark", false) else 0]
	var n := 1
	if kind in ["burst", "debris", "stream", "swirl"]:
		n = maxi(1, mini(MAX_PARTICLES, int(round(float(p.get("n", 8)) * (0.5 if Settings.quality_low else 1.0)))))
	elif kind == "beam":
		n = maxi(1, mini(7, int(p.get("count", 1))))
	for i in range(n):
		var node := _take(key, color, core, ctx, p)
		node.position = origin
		var tw := create_tween().set_parallel(true)
		match kind:
			"glow":
				var s1 := float(p.get("scale", 1.4))
				node.scale = Vector2.ONE * s1 * 0.35
				tw.tween_property(node, "scale", Vector2.ONE * s1, dur).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
				_fade(node, key, dur, 0.15)
			"ring":
				var flat := 0.4 if str(p.get("y", "")) == "ground" else 1.0
				if flat < 1.0: node.position.y += GROUND
				var r1 := float(p.get("r1", 60.0)) / 28.0
				node.scale = Vector2(0.2, 0.2 * flat)
				tw.tween_property(node, "scale", Vector2(r1, r1 * flat), dur).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
				_fade(node, key, dur, 0.0, 0.2)
			"burst", "debris":
				var a0 := float(p.get("a0", 0.0))
				var a1 := float(p.get("a1", TAU))
				var ang := randf_range(a0, a1)
				var dist := randf_range(float(p.get("d0", 20.0)), float(p.get("d1", 70.0)))
				var grav := float(p.get("grav", 0.0 if kind == "burst" else 110.0))
				var end := origin + Vector2(cos(ang), sin(ang)) * dist
				node.rotation = ang
				node.scale = Vector2.ONE * float(p.get("size", 1.0)) * randf_range(1.0, 1.5)
				tw.tween_method(func(u: float): if is_instance_valid(node): node.position = origin + (end - origin) * u + Vector2(0, grav * u * u), 0.0, 1.0, dur).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
				_fade(node, key, dur, 0.0, 0.25)
			"stream":
				var w := float(p.get("w", 80.0))
				var start := origin + Vector2(randf_range(-w * 0.5, w * 0.5), randf_range(0.0, float(p.get("hh", 30.0))))
				var move := Vector2(float(p.get("dx", 0.0)) * f, float(p.get("dy", -60.0)))
				node.position = start
				node.rotation = move.angle()
				node.scale = Vector2.ONE * float(p.get("size", 1.0)) * randf_range(1.0, 1.6)
				tw.tween_property(node, "position", start + move, dur).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
				_fade(node, key, dur, 0.15)
			"swirl":
				var r0 := float(p.get("r0", 80.0))
				var r1s := float(p.get("r1", 8.0))
				var turns := float(p.get("turns", 1.4))
				var base := TAU * float(i) / float(n)
				node.scale = Vector2.ONE * 1.3
				tw.tween_method(_swirl_step.bind(node, origin, base, turns, r0, r1s), 0.0, 1.0, dur).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
				_fade(node, key, dur, 0.15, 0.3)
			"beam":
				var dir := Vector2(float(p.get("dx", 100.0)) * f, float(p.get("dy", 0.0)))
				var count := maxi(1, mini(7, int(p.get("count", 1))))
				var off := 0.0 if count == 1 else (float(i) - float(count - 1) * 0.5) * float(p.get("spread", 0.25))
				if str(p.get("angle", "")) == "random": off = randf_range(-0.7, 0.7)
				var d2 := dir.rotated(off)
				node.rotation = d2.angle()
				node.scale = Vector2(maxf(0.4, d2.length() / 64.0), maxf(0.6, float(p.get("w", 8.0)) / 8.0))
				node.position = origin + d2 * 0.25
				tw.tween_property(node, "position", origin + d2 * 0.75, dur).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
				_fade(node, key, dur, 0.0, 0.3)
			"bolt":
				var bd := Vector2(float(p.get("dx", 160.0)) * f, float(p.get("dy", 0.0)))
				if bd.length() < 1.0: bd = Vector2(0, 160)
				node.rotation = bd.angle()
				node.scale = Vector2.ONE * maxf(0.4, bd.length() / 64.0)
				node.position = origin + bd * 0.5
				tw.tween_interval(0.01)
				_fade(node, key, dur, 0.0, 0.35)
			"arc":
				var rr2 := float(p.get("r", 60.0)) / 40.0
				node.scale = Vector2(rr2 * f, rr2)
				node.position = origin + Vector2(f * 6.0, 6.0)
				node.rotation = -0.6 * f
				tw.tween_property(node, "rotation", 0.5 * f, dur * 0.7).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
				tw.tween_property(node, "scale", Vector2(rr2 * f * 1.12, rr2 * 1.12), dur).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
				_fade(node, key, dur, 0.0, 0.3)
			"pillar":
				var pw := float(p.get("w", 70.0)) / 48.0
				var ph := float(p.get("h", 280.0)) / 160.0
				node.position = origin + Vector2(0, GROUND)
				node.scale = Vector2(pw * 0.3, ph * 0.1)
				tw.tween_property(node, "scale", Vector2(pw, ph), dur * 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
				_fade(node, key, dur, 0.0, 0.35)
			"sigil", "runeDisc":
				var sr := float(p.get("r", 70.0)) / 60.0
				var spin := float(p.get("spin", 90.0))
				if absf(spin) < 1.0: spin = 90.0
				node.position = origin + Vector2(0, GROUND)
				node.scale = Vector2(sr * 0.6, sr * 0.6 * 0.34)
				tw.tween_property(node, "scale", Vector2(sr, sr * 0.34), dur * 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
				tw.tween_property(node, "phase", deg_to_rad(spin), dur)
				_fade(node, key, dur, 0.2, 0.4)
			"ghost":
				node.scale = Vector2(f, 1.0)
				tw.tween_property(node, "position", origin - Vector2(f * 26.0, 0), dur).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
				_fade(node, key, dur, 0.0, 0.1)
				node.modulate.a = float(p.get("alpha", 0.6))
			"cracks":
				var cs := float(p.get("span", 160.0)) * 0.5 / 70.0
				node.position = origin + Vector2(0, GROUND)
				node.scale = Vector2(cs * 0.4, cs * 0.4 * 0.34)
				tw.tween_property(node, "scale", Vector2(cs, cs * 0.34), dur * 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
				_fade(node, key, dur, 0.0, 0.5)
			"fall":
				var rad := float(p.get("r", 180.0))
				var land := origin + Vector2(f * minf(rad * 0.45, 110.0) + randf_range(-30.0, 30.0), GROUND - 18.0)
				node.position = land + Vector2(0, -230)
				tw.tween_property(node, "position", land, dur * 0.4).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN)
				get_tree().create_timer(dur * 0.4).timeout.connect(func(): _impact(land + Vector2(0, 18), color, core, ctx, minf(rad, 150.0)))
				_fade(node, key, dur, 0.0, 0.45)
			"meteor":
				var rad2 := float(p.get("r", 200.0))
				var land2 := origin + Vector2(f * rad2 * 0.35 + randf_range(-rad2 * 0.3, rad2 * 0.3), GROUND - 8.0)
				var from := land2 + Vector2(-f * 190.0, -250.0)
				node.position = from
				node.rotation = (land2 - from).angle()
				node.scale = Vector2.ONE * 1.2
				tw.tween_property(node, "position", land2, dur * 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
				get_tree().create_timer(dur * 0.45).timeout.connect(func(): _impact(land2, color, core, ctx, minf(rad2, 160.0)))
				_fade(node, key, dur, 0.0, 0.5)
			"arrowZone":
				var hw := float(p.get("halfW", 160.0))
				var land3 := origin + Vector2(f * hw * 0.5, GROUND - 10.0)
				node.scale = Vector2.ONE * (hw / 100.0)
				node.position = land3 + Vector2(0, -200)
				tw.tween_property(node, "position", land3, dur * 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
				_fade(node, key, dur, 0.0, 0.5)

func _swirl_step(u: float, node: Node2D, origin: Vector2, base: float, turns: float, r0: float, r1: float) -> void:
	if not is_instance_valid(node): return
	var a := base + TAU * turns * u
	node.position = origin + Vector2(cos(a), sin(a)) * lerpf(r0, r1, u)
	node.rotation = a + PI * 0.5

const SIG_GROUND := ["trap", "quake", "thorn", "dawn", "garden", "summon", "fortress", "hell", "net", "miasma", "crystal", "hammer", "blizzard"]
const SIG_BODY := ["shadow", "clones", "cloak", "veil", "smoke", "blink", "hop", "whirl", "orbit", "disc", "storm", "vortex", "spirit", "holy", "bless", "angel", "wings", "bird", "star", "moon", "rune", "dome", "shield", "rage", "awaken", "elem", "nova", "drain", "bloodlust", "judge"]
const SIG_SKIP := ["manaburst", "execute", "allin", "fusion"]
## Ghi đè biểu tượng theo id kỹ năng (khi sig chung chung không khớp tên).
const SIG_BY_ID := {
	"ks40": "swordrain", "ulKiem1": "swordrain",       # Vạn Kiếm Quy Tông / Kiếm Trận Hủy Diệt: kiếm từ trời đâm xuống
	"ks30": "swordshield", "pa9": "swordshield",       # Kiếm Tâm Phản Kích / Kiếm Phản Kích: khiên kiếm + phản đòn
	"ulChung1": "quake",                               # Thiên Địa Chấn Động: nứt đất, sóng xung kích, đá bay
	"ks45": "swordawaken",                             # Chân Kiếm Thức Tỉnh: kiếm phóng to + hào quang
	"tl1": "healplus", "ps38": "healplus", "tn2": "healplus",   # hồi máu: dấu cộng bay lên
	"ps37": "lightball",                               # Lôi Cầu Xoáy: quả cầu sét xoáy
	"st8": "poison",                                   # Phi Tiêu Độc: bọt độc + giọt độc
}
const SIG_NOPOP := ["swordrain", "quake", "swordawaken"]

## Rung màn hình (camera offset), tự trả về 0.
func _rumble(amount: float, dur: float) -> void:
	var cam := get_viewport().get_camera_2d()
	if cam == null: return
	var tw := create_tween()
	for i in range(8):
		tw.tween_property(cam, "offset", Vector2(randf_range(-amount, amount), randf_range(-amount, amount)) * (1.0 - float(i) / 8.0), dur / 8.0)
	tw.tween_property(cam, "offset", Vector2.ZERO, 0.05)

## Biểu tượng đặc trưng của kỹ năng (theo `sig` trong công thức): mỗi kiểu một hình riêng, thêm biến thể theo id.
func _paint_sig(r: Dictionary, origin: Vector2, facing: int, ctx: Dictionary, colors: Array) -> void:
	var sg := str(SIG_BY_ID.get(str(r.get("id", "")), r.get("sig", "")))
	var ext_sg := FxExt.sig_for(str(r.get("id", "")))
	if ext_sg != "": sg = ext_sg
	if FxProj.has(str(r.get("id", ""))) and str(Data.skill(str(r.get("id", ""))).get("type", "")) in ["projectile", "spread"]:
		sg = "pj_muzzle_bow" if str((_manifest.get(str(r.get("id", "")), {}) as Dictionary).get("school", "")) == "cung_thu" else "pj_muzzle"   # kỹ năng bắn: đạn bay mang hình riêng, tung chiêu chỉ loé nòng
	var xc := FxExt.cfg_for(sg)
	if sg == "" or sg in SIG_SKIP: return
	var f := float(facing) if facing != 0 else 1.0
	var color := _color("main", colors)
	var core := _color("core", colors)
	var key := "sig|%s|%d" % [str(ctx.get("theme", "")), 1 if ctx.get("dark", false) else 0]
	var node := _take(key, color, core, ctx, {})
	node.sig = sg
	node.nocreature = FxCreature.has(str(r.get("id", ""))) or FxCreature.has_aura(str(r.get("id", "")))
	node._lowq = Settings.quality_low
	node.vs = str(r.get("id", sg)).hash() + int(ctx.get("variant", 0)) * 7919
	node.prog = 0.0
	node.z_index = 9
	var big := 1.4 if str(r.get("tier", "")) == "ult" else 1.0
	if bool(xc.get("nobig", false)): big = 1.0
	var pos := origin + Vector2(f * 58.0, -4.0)
	var sx := f
	if sg == "swordrain":
		pos = origin + Vector2(f * 70.0, GROUND - 4.0)
		sx = 1.0
	elif sg == "quake":
		pos = origin + Vector2(f * 20.0, GROUND - 2.0)
		sx = 1.0
	elif sg in SIG_GROUND:
		pos = origin + Vector2(f * 30.0, GROUND - 4.0)
	elif sg in SIG_BODY:
		pos = origin + Vector2(0, -4.0)
		sx = 1.0
	if not xc.is_empty():
		match str(xc.get("place", "front")):
			"ground": pos = origin + Vector2(f * 30.0, GROUND - 4.0)
			"body": pos = origin + Vector2(0, -4.0); sx = 1.0
			"bodyf": pos = origin + Vector2(0, -4.0)   # thân nhân vật, lật theo hướng nhìn
			"far": pos = origin + Vector2(f * 90.0, GROUND - 4.0); sx = 1.0
		if xc.get("rumble", 0.0) > 0.0: _rumble(float(xc["rumble"]) * big, 0.7)
	node.position = pos
	var dur := 0.9 if big > 1.0 else 0.7
	if not xc.is_empty() and xc.has("dur"): dur = float(xc["dur"])
	if sg == "swordrain": dur = 1.4
	elif sg == "quake": dur = 1.2
	elif sg == "swordawaken": dur = 1.3
	var tw := create_tween().set_parallel(true)
	if sg in SIG_NOPOP or bool(xc.get("nopop", false)):
		node.scale = Vector2(sx, 1.0) * big
	else:
		node.scale = Vector2(sx, 1.0) * 0.6 * big
		tw.tween_property(node, "scale", Vector2(sx, 1.0) * big, dur * 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if sg == "quake":
		_rumble(10.0 * big, 0.7)
	tw.tween_property(node, "prog", 1.0, dur * 0.75)
	_fade(node, key, dur, 0.0, 0.5)

## Kỹ năng trùng công thức với kỹ năng khác (variant > 0): xoay tông màu để nhìn là kỹ năng riêng.
func _shift_colors(colors: Array, shift: float) -> Array:
	var out: Array = []
	for c in colors:
		var col := _hex(str(c))
		var h := fposmod(col.h + shift, 1.0)
		var sh := Color.from_hsv(h, col.s, col.v)
		out.append("0x%02x%02x%02x" % [int(sh.r * 255.0), int(sh.g * 255.0), int(sh.b * 255.0)])
	return out

## ---------------------------------------------------------------- Trúng đòn trên từng quái
const HIT_THEME := {"sword": "slash", "steel": "slash", "wind": "slash", "dragon": "slash", "arrow": "pierce", "fire": "fire", "inferno": "fire",
	"ice": "ice", "bolt": "bolt", "holy": "holy", "heal": "holy", "star": "holy", "shadow": "dark", "blood": "blood", "necro": "soul",
	"spirit": "soul", "void": "soul", "earth": "rock", "water": "water", "arcane": "arcane"}
const HIT_SCHOOL := {"kiem_si": "slash", "tanker": "", "cung_thu": ""}
const MAX_HIT_FX := 8     # tối đa số quái có hiệu ứng riêng cùng lúc (4 khi quality_low)
var _hit_active := 0

func hit_style(id: String) -> String:
	var r := recipe(id)
	var school := str((_manifest.get(id, {}) as Dictionary).get("school", ""))
	var theme := str(r.get("theme", ""))
	if HIT_SCHOOL.get(school, "") != "": return str(HIT_SCHOOL[school])
	if school == "cung_thu" and theme in ["arrow", "wind", "steel", "spirit"]: return "pierce"
	if school == "tanker" and theme in ["steel", "earth", "dragon"]: return "rock" if theme != "steel" else "slash"
	return str(HIT_THEME.get(theme, "slash"))

## Hiệu ứng trúng đòn đặt đúng vào người quái bị đánh trúng (gọi từ World._hit_mob).
func play_hit(id: String, pos: Vector2, dir: int = 1) -> void:
	if id == "" or _manifest.is_empty(): return
	if _hit_active >= (MAX_HIT_FX / 2 if Settings.quality_low else MAX_HIT_FX): return
	var r := recipe(id)
	if r.is_empty(): return
	var colors: Array = r.get("colors", ["0xffffff", "0xffffff", "0xffffff"])
	var variant := int(r.get("variant", 0))
	if variant > 0: colors = _shift_colors(colors, 0.085 * float(variant))
	var ctx := {"theme": str(r.get("theme", "")), "dark": bool(r.get("dark", false)), "variant": variant}
	var key := "sig|%s|%d" % [str(ctx["theme"]), 1 if ctx["dark"] else 0]
	var node := _take(key, _color("main", colors), _color("core", colors), ctx, {})
	node.sig = "hit_" + hit_style(id)
	node._lowq = Settings.quality_low
	node.vs = str(id).hash()
	node.prog = 0.0
	node.z_index = 12
	node.position = pos
	node.scale = Vector2(float(dir) if dir != 0 else 1.0, 1.0)
	var dur := 0.4
	var tw := create_tween()
	tw.tween_property(node, "prog", 1.0, dur)
	_fade(node, key, dur, 0.0, 0.35)
	_hit_active += 1
	get_tree().create_timer(dur + 0.02).timeout.connect(func(): _hit_active = maxi(0, _hit_active - 1))

## ---------------------------------------------------------------- Buff kéo dài: hào quang theo người suốt thời gian hiệu lực
var _auras: Dictionary = {}   # id kỹ năng -> Node2D hào quang đang gắn vào người

## Gọi định kỳ từ World: buffs = {id: {until(ms), ...}}; target = node nhân vật.
func sync_auras(buffs: Dictionary, target: Node2D, facing: int) -> void:
	if _manifest.is_empty() or target == null: return
	var now := Time.get_ticks_msec()
	for id in buffs.keys():
		var b: Dictionary = buffs[id]
		var active := now < int(b.get("until", 0))
		var has: bool = _auras.has(id) and is_instance_valid(_auras[id])
		if active and not has:
			_start_aura(str(id), target, facing)
		elif active and has:
			(_auras[id] as Node2D).scale.x = float(facing) if facing != 0 else 1.0
		elif not active and has:
			_end_aura(str(id))
	for id in _auras.keys():
		if not buffs.has(id): _end_aura(str(id))

func _start_aura(id: String, target: Node2D, facing: int) -> void:
	var r := recipe(id)
	if r.is_empty(): return
	# buff/hộ thể có con vật hoặc hình người sprite đi theo: gắn sprite thay cho hào quang vẽ tay
	if FxCreature.has_aura(id):
		var rc0 := recipe(id)
		var cols0: Array = rc0.get("colors", ["0xffffff", "0xffffff", "0xffffff"])
		var rn := FxCreature.attach(target, id, facing, _color("main", cols0), _color("core", cols0))
		if rn != null: _auras[id] = rn
		return
	var stype := str(Data.skill(id).get("type", ""))
	var sg := FxExt.sig_for(id)
	if not FxExt.has_aura(sg):
		sg = "au_guard" if stype == "guard" else ("au_shield" if stype == "manashield" else "au_buff")
	var colors: Array = r.get("colors", ["0xffffff", "0xffffff", "0xffffff"])
	var variant := int(r.get("variant", 0))
	if variant > 0: colors = _shift_colors(colors, 0.085 * float(variant))
	var n := _FxShape.new()
	n.kind = "sig"
	n.theme = str(r.get("theme", ""))
	n.dark = bool(r.get("dark", false))
	n.material = null if n.dark else _additive()
	n.col = _color("main", colors)
	n.core = _color("core", colors)
	n.sig = sg
	n.steady = true
	n.auto = true
	n._lowq = Settings.quality_low
	n.vs = id.hash()
	n.z_index = 1
	n.position = Vector2(0, -4)
	n.scale = Vector2(float(facing) if facing != 0 else 1.0, 1.0)
	n.modulate = Color(1, 1, 1, 0.0)
	target.add_child(n)
	_auras[id] = n
	var tw := n.create_tween()
	tw.tween_interval(0.9)   # chờ hiệu ứng tung chiêu ban đầu tan bớt rồi mới hiện hào quang
	tw.tween_property(n, "modulate:a", 0.8, 0.5)

func _end_aura(id: String) -> void:
	var n: Variant = _auras.get(id, null)
	_auras.erase(id)
	if n == null or not is_instance_valid(n): return
	var node := n as Node2D
	var tw := node.create_tween()
	tw.tween_property(node, "modulate:a", 0.0, 0.4)
	tw.tween_callback(node.queue_free)

## Thông tin để vẽ đạn riêng của kỹ năng ({} nếu kỹ năng không có hình đạn riêng).
func proj_info(id: String) -> Dictionary:
	if not FxProj.has(id): return {}
	var r := recipe(id)
	if r.is_empty(): return {}
	var colors: Array = r.get("colors", ["0xffffff", "0xffffff", "0xffffff"])
	var variant := int(r.get("variant", 0))
	if variant > 0: colors = _shift_colors(colors, 0.085 * float(variant))
	return {"col": _color("main", colors), "core": _color("core", colors), "dark": bool(r.get("dark", false))}

## Kỹ năng đã có hình vẽ riêng (FxExt hoặc SIG_BY_ID): bỏ các lớp hiệu ứng chung của web (rune/quầng sáng/tia lửa/cột sáng).
func has_custom(id: String) -> bool:
	return FxExt.sig_for(id) != "" or SIG_BY_ID.has(id)

## Điểm vào: gọi từ World khi cast/khit. args tuỳ kind (toạ độ mục tiêu...).
func play(kind: String, id: String, origin: Vector2, facing: int = 1, args: Array = []) -> bool:
	if _manifest.is_empty():
		return false
	var r := recipe(id)
	if r.is_empty():
		return false
	var layers: Array = r.get("layers", [])
	var colors: Array = r.get("colors", ["0xffffff", "0xffffff", "0xffffff"])
	var variant := int(r.get("variant", 0))
	if variant > 0: colors = _shift_colors(colors, 0.085 * float(variant))
	var ctx := {"theme": str(r.get("theme", "")), "dark": bool(r.get("dark", false)), "variant": variant}
	var hit := false
	# Web chọn fx theo skill id và fire MỌI trigger của recipe; "cast" gọi kèm các layer còn lại.
	var fire_all := kind == "cast"
	var custom := has_custom(id)
	for layer in layers:
		if typeof(layer) != TYPE_DICTIONARY:
			continue
		# Kỹ năng có hình riêng: khi cast chỉ giữ rung màn hình, bỏ lớp chung chồng lên.
		if custom and kind == "cast" and str(layer.get("kind", "")) != "shake":
			continue
		var lk := str(layer.get("trigger", ""))
		if lk != kind and not fire_all:
			continue
		hit = true
		var t := float(layer.get("t", 0)) / 1000.0
		if t > 0.0:
			await get_tree().create_timer(t).timeout
		if is_inside_tree():
			_paint(layer, colors, origin, facing, ctx)
	if kind == "cast":
		if FxCreature.has(id):
			FxCreature.spawn(self, id, origin, facing, _color("main", colors), _color("core", colors))
		_paint_sig(r, origin, facing, ctx, colors)
		hit = true
	if hit:
		fx_finished.emit(id, kind)
	return hit

func clear() -> void:
	for child in get_children():
		child.queue_free()
	_pool.clear()
	_active.clear()

# ------------------------------------------------------------------ Hình vẽ bằng code (cộng sáng, theo chủ đề kỹ năng)
class _FxShape extends Node2D:
	var kind := "glow"
	var theme := ""
	var dark := false
	var col := Color.WHITE
	var core := Color.WHITE
	var p: Dictionary = {}
	var seed_v := 0
	var phase := 0.0:
		set(v):
			phase = v
			queue_redraw()
	var _rng := RandomNumberGenerator.new()

	func _a(a: float) -> Color:
		return Color(col.r, col.g, col.b, a)

	func _k(a: float) -> Color:
		return Color(core.r, core.g, core.b, a)

	func _mix(t: float, a: float) -> Color:
		var c := col.lerp(core, t)
		return Color(c.r, c.g, c.b, a)

	func _draw() -> void:
		_rng.seed = seed_v
		match kind:
			"glow": _d_glow()
			"ring": _d_ring()
			"burst", "debris", "stream", "swirl": _d_motif()
			"beam": _d_beam()
			"bolt": _d_bolt()
			"arc": _d_arc()
			"pillar": _d_pillar()
			"sigil", "runeDisc": _d_sigil()
			"ghost": _d_ghost()
			"cracks": _d_cracks()
			"fall": _d_fall()
			"meteor": _d_meteor()
			"arrowZone": _d_arrows()
			"sig": _d_sig()
			_: draw_circle(Vector2.ZERO, 10.0, _a(0.6))

	# --- nhỏ: hạt theo chủ đề
	func _d_motif() -> void:
		match theme:
			"fire", "inferno", "dragon":
				draw_colored_polygon(PackedVector2Array([Vector2(15, 0), Vector2(3, -6), Vector2(-10, 0), Vector2(3, 6)]), _a(0.85))
				draw_colored_polygon(PackedVector2Array([Vector2(10, 0), Vector2(3, -3), Vector2(-5, 0), Vector2(3, 3)]), _k(0.95))
			"ice":
				draw_colored_polygon(PackedVector2Array([Vector2(-9, 0), Vector2(0, -4.5), Vector2(15, 0), Vector2(0, 4.5)]), _a(0.9))
				draw_colored_polygon(PackedVector2Array([Vector2(-4, 0), Vector2(1, -1.8), Vector2(10, 0), Vector2(1, 1.8)]), _k(0.95))
			"bolt":
				var z := PackedVector2Array([Vector2(-10, 0), Vector2(-4, -5), Vector2(2, 3), Vector2(10, -2)])
				draw_polyline(z, _a(0.5), 5.0)
				draw_polyline(z, _k(0.95), 1.8)
			"shadow", "void":
				for k in range(3):
					draw_circle(Vector2(-5.0 + 5.0 * k, _rng.randf_range(-3.0, 3.0)), 8.0 - k, _a(0.42))
				draw_circle(Vector2.ZERO, 3.5, Color(0.02, 0.0, 0.05, 0.6))
			"necro", "spirit":
				draw_colored_polygon(PackedVector2Array([Vector2(13, 0), Vector2(0, -5.5), Vector2(-11, 0), Vector2(0, 5.5)]), _a(0.6))
				draw_circle(Vector2(-1, 0), 3.2, _k(0.9))
			"blood", "water":
				draw_circle(Vector2(-3, 0), 5.5, _a(0.92))
				draw_colored_polygon(PackedVector2Array([Vector2(1, -4.5), Vector2(13, 0), Vector2(1, 4.5)]), _a(0.92))
				draw_circle(Vector2(-4.5, -2), 1.8, _k(0.85))
			"holy", "heal", "star":
				var pts := PackedVector2Array()
				for k in range(8):
					var a := TAU * k / 8.0
					var rr := 11.0 if k % 2 == 0 else 2.8
					pts.append(Vector2(cos(a), sin(a)) * rr)
				draw_colored_polygon(pts, _a(0.8))
				draw_circle(Vector2.ZERO, 3.0, _k(1.0))
			"wind":
				draw_arc(Vector2(-6, 0), 14.0, -0.95, 0.95, 10, _a(0.75), 3.4)
				draw_arc(Vector2(-6, 0), 14.0, -0.7, 0.7, 10, _k(0.9), 1.3)
			"earth":
				var rp := PackedVector2Array()
				for k in range(6):
					var a2 := TAU * k / 6.0
					var rr2 := _rng.randf_range(4.0, 8.5)
					rp.append(Vector2(cos(a2), sin(a2)) * rr2)
				draw_colored_polygon(rp, _a(0.95))
				draw_circle(Vector2(-1, -1), 2.0, _k(0.7))
			"steel", "sword", "arrow":
				draw_colored_polygon(PackedVector2Array([Vector2(-17, 0), Vector2(0, -2.6), Vector2(17, 0), Vector2(0, 2.6)]), _a(0.9))
				draw_line(Vector2(-12, 0), Vector2(14, 0), _k(0.95), 1.2)
			_:
				draw_colored_polygon(PackedVector2Array([Vector2(0, -9), Vector2(6, 0), Vector2(0, 9), Vector2(-6, 0)]), _a(0.85))
				draw_circle(Vector2.ZERO, 2.6, _k(0.95))

	# --- quầng sáng mềm
	func _d_glow() -> void:
		for i in range(9):
			var t := float(i) / 8.0
			draw_circle(Vector2.ZERO, 30.0 * (1.0 - t * 0.88), _mix(t, 0.06 + 0.08 * t))
		if dark:
			draw_circle(Vector2.ZERO, 10.0, Color(0.02, 0.0, 0.06, 0.55))

	# --- vòng sóng (có gai theo chủ đề)
	func _d_ring() -> void:
		draw_arc(Vector2.ZERO, 28.0, 0.0, TAU, 56, _a(0.14), 8.0)
		draw_arc(Vector2.ZERO, 28.0, 0.0, TAU, 56, _a(0.75), 4.0)
		draw_arc(Vector2.ZERO, 28.0, 0.0, TAU, 56, _k(0.7), 1.4)
		if theme in ["fire", "inferno", "dragon", "ice", "holy", "star", "bolt"]:
			var cnt := 20
			for k in range(cnt):
				var a := TAU * k / cnt
				var ln := 7.0
				if theme in ["fire", "inferno", "dragon", "bolt"]: ln = 6.0 + _rng.randf() * 9.0
				elif theme == "ice": ln = 11.0
				var d := Vector2(cos(a), sin(a))
				var nrm := Vector2(-d.y, d.x)
				draw_colored_polygon(PackedVector2Array([d * 26.0 + nrm * 2.8, d * (28.0 + ln), d * 26.0 - nrm * 2.8]), _a(0.8))

	# --- tia chém / phi tiêu
	func _d_beam() -> void:
		var key := str(p.get("key", ""))
		if key.find("dagger") >= 0 or key.find("knife") >= 0:
			draw_colored_polygon(PackedVector2Array([Vector2(-4, 0), Vector2(26, -3.2), Vector2(34, 0), Vector2(26, 3.2)]), _a(0.95))
			draw_line(Vector2(-4, 0), Vector2(30, 0), _k(1.0), 1.2)
			draw_line(Vector2(-6, -5), Vector2(-6, 5), _a(0.9), 2.5)
			draw_line(Vector2(-16, 0), Vector2(-6, 0), _a(0.9), 3.0)
			draw_colored_polygon(PackedVector2Array([Vector2(-34, 0), Vector2(-6, -2.5), Vector2(-6, 2.5)]), _a(0.25))
			return
		draw_colored_polygon(PackedVector2Array([Vector2(-32, 0), Vector2(8, -8), Vector2(32, 0), Vector2(8, 8)]), _a(0.22))
		draw_colored_polygon(PackedVector2Array([Vector2(-32, 0), Vector2(10, -4.2), Vector2(32, 0), Vector2(10, 4.2)]), _a(0.9))
		draw_colored_polygon(PackedVector2Array([Vector2(-30, 0), Vector2(12, -1.7), Vector2(32, 0), Vector2(12, 1.7)]), _k(0.98))

	# --- tia sét ngoằn ngoèo
	func _d_bolt() -> void:
		var sx := maxf(0.3, absf(scale.x))
		var segs := maxi(3, int(p.get("segs", 6)))
		var jag := float(p.get("jag", 14.0)) / sx
		var w := maxf(1.5, float(p.get("w", 5.0)) / sx)
		var pts := PackedVector2Array()
		for i in range(segs + 1):
			var y := 0.0 if i == 0 or i == segs else _rng.randf_range(-jag, jag)
			pts.append(Vector2(-32.0 + 64.0 * i / segs, y))
		draw_polyline(pts, _a(0.22), w * 3.5)
		draw_polyline(pts, _a(0.9), w)
		draw_polyline(pts, _k(1.0), w * 0.4)
		var m := pts[segs / 2]
		var fork := PackedVector2Array([m, m + Vector2(14.0, _rng.randf_range(-jag, jag) * 1.3), m + Vector2(26.0, _rng.randf_range(-jag, jag) * 1.6)])
		draw_polyline(fork, _a(0.8), w * 0.6)

	# --- nhát chém lưỡi liềm
	func _crescent(rad: float, span: float, tk: float, c: Color) -> void:
		var steps := 18
		var pts := PackedVector2Array()
		for i in range(steps + 1):
			var a := -span + 2.0 * span * float(i) / steps
			pts.append(Vector2(cos(a), sin(a)) * rad)
		for i in range(steps, -1, -1):
			var a2 := -span + 2.0 * span * float(i) / steps
			var prof := cos(a2 / span * PI * 0.5)
			pts.append(Vector2(cos(a2), sin(a2)) * (rad - tk * prof))
		draw_colored_polygon(pts, c)

	func _d_arc() -> void:
		var span := maxf(0.5, (float(p.get("a1", 1.0)) - float(p.get("a0", -1.0))) * 0.5)
		var tk := float(p.get("thick", 26.0)) / maxf(0.3, float(p.get("r", 60.0)) / 40.0)
		_crescent(40.0, span, tk * 1.5, _a(0.2))
		_crescent(40.0, span, tk, _a(0.85))
		_crescent(40.0, span * 0.92, tk * 0.35, _k(0.98))

	# --- cột sáng
	func _quad(wb: float, wt: float, h: float, cb: Color, ct: Color) -> void:
		draw_polygon(PackedVector2Array([Vector2(-wb, 0), Vector2(wb, 0), Vector2(wt, -h), Vector2(-wt, -h)]), PackedColorArray([cb, cb, ct, ct]))

	func _d_pillar() -> void:
		var h := 160.0
		_quad(22.0, 12.0, h, _a(0.3), _a(0.0))
		_quad(12.0, 4.0, h, _mix(0.3, 0.5), _a(0.0))
		_quad(4.0, 1.2, h * 0.9, _k(0.6), _k(0.0))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.3))
		draw_circle(Vector2.ZERO, 34.0, _a(0.22))
		draw_circle(Vector2.ZERO, 18.0, _k(0.35))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		if theme in ["ice", "holy", "sword", "steel"]:
			for k in range(5):
				var x := -20.0 + 10.0 * k
				var hh := 30.0 + _rng.randf() * 36.0
				draw_colored_polygon(PackedVector2Array([Vector2(x - 3.0, 0), Vector2(x + 3.0, 0), Vector2(x, -hh)]), _k(0.85))
		elif theme in ["fire", "inferno", "dragon"]:
			for k in range(5):
				var x2 := -18.0 + 9.0 * k
				var h2 := 40.0 + _rng.randf() * 60.0
				draw_colored_polygon(PackedVector2Array([Vector2(x2 - 5.0, 0), Vector2(x2 + 5.0, 0), Vector2(x2 + _rng.randf_range(-5.0, 5.0), -h2)]), _mix(0.4, 0.55))

	# --- trận pháp trên nền đất (theo chủ đề)
	func _star_lines(n: int, skip: int, rad: float, width: float, c: Color, start: float = -PI * 0.5) -> void:
		for k in range(n):
			var a := start + TAU * k / n
			var b := start + TAU * ((k + skip) % n) / n
			draw_line(Vector2(cos(a), sin(a)) * rad, Vector2(cos(b), sin(b)) * rad, c, width)

	func _d_sigil() -> void:
		var R := 60.0
		draw_set_transform(Vector2.ZERO, phase, Vector2.ONE)
		draw_circle(Vector2.ZERO, R, _a(0.12))
		draw_arc(Vector2.ZERO, R, 0.0, TAU, 64, _a(0.28), 9.0)
		draw_arc(Vector2.ZERO, R, 0.0, TAU, 64, _a(0.9), 2.6)
		draw_arc(Vector2.ZERO, R * 0.82, 0.0, TAU, 64, _a(0.65), 1.6)
		for k in range(24):
			var a := TAU * k / 24.0
			var d := Vector2(cos(a), sin(a))
			draw_line(d * R * 0.84, d * R * (0.97 if k % 2 == 0 else 0.92), _a(0.8), 1.8)
		var c := _k(0.95)
		match theme:
			"holy", "star", "heal":
				for k in range(8):
					var a2 := TAU * k / 8.0
					var d2 := Vector2(cos(a2), sin(a2))
					draw_line(d2 * R * 0.22, d2 * R * (0.78 if k % 2 == 0 else 0.55), c, 2.2)
				draw_arc(Vector2.ZERO, R * 0.3, 0.0, TAU, 32, _a(0.9), 2.0)
			"shadow", "necro", "blood", "void":
				_star_lines(5, 2, R * 0.74, 2.2, c)
				draw_arc(Vector2.ZERO, R * 0.74, 0.0, TAU, 48, _a(0.7), 1.4)
			"fire", "inferno", "dragon":
				for k in range(6):
					var a3 := TAU * k / 6.0
					var pet := PackedVector2Array([Vector2.ZERO, Vector2(cos(a3 - 0.3), sin(a3 - 0.3)) * R * 0.45, Vector2(cos(a3), sin(a3)) * R * 0.8, Vector2(cos(a3 + 0.3), sin(a3 + 0.3)) * R * 0.45])
					draw_colored_polygon(pet, _a(0.5))
					draw_polyline(PackedVector2Array([pet[1], pet[2], pet[3]]), c, 1.6)
			"ice":
				for k in range(6):
					var a4 := TAU * k / 6.0
					var d4 := Vector2(cos(a4), sin(a4))
					var nrm := Vector2(-d4.y, d4.x)
					draw_line(Vector2.ZERO, d4 * R * 0.78, c, 2.2)
					for bb in [0.45, 0.62]:
						draw_line(d4 * R * bb, d4 * R * (bb + 0.12) + nrm * R * 0.1, c, 1.6)
						draw_line(d4 * R * bb, d4 * R * (bb + 0.12) - nrm * R * 0.1, c, 1.6)
			"bolt":
				for k in range(8):
					var a5 := TAU * k / 8.0
					var d5 := Vector2(cos(a5), sin(a5))
					var n5 := Vector2(-d5.y, d5.x)
					draw_polyline(PackedVector2Array([d5 * R * 0.25, d5 * R * 0.45 + n5 * 6.0, d5 * R * 0.6 - n5 * 6.0, d5 * R * 0.8]), c, 2.0)
			"earth":
				_star_lines(4, 1, R * 0.74, 2.4, c, PI * 0.25)
				_star_lines(4, 1, R * 0.5, 1.8, _a(0.8), 0.0)
			"wind":
				var sp := PackedVector2Array()
				for k in range(41):
					var t := float(k) / 40.0
					var aa := TAU * 2.6 * t
					sp.append(Vector2(cos(aa), sin(aa)) * (R * 0.12 + R * 0.66 * t))
				draw_polyline(sp, c, 2.0)
			"steel", "sword", "arrow":
				for k in range(4):
					var a6 := TAU * k / 4.0 + PI * 0.25
					var d6 := Vector2(cos(a6), sin(a6))
					var n6 := Vector2(-d6.y, d6.x)
					draw_colored_polygon(PackedVector2Array([d6 * R * 0.8, d6 * R * 0.25 + n6 * 6.0, d6 * R * 0.1, d6 * R * 0.25 - n6 * 6.0]), _a(0.7))
					draw_line(d6 * R * 0.1, d6 * R * 0.78, c, 1.4)
			"water":
				for k in range(3):
					draw_arc(Vector2.ZERO, R * (0.3 + 0.17 * k), phase, phase + PI * 1.4, 24, c, 2.0)
			_:
				_star_lines(6, 2, R * 0.74, 2.2, c)
				draw_arc(Vector2.ZERO, R * 0.4, 0.0, TAU, 32, _a(0.8), 1.6)
		draw_circle(Vector2.ZERO, 4.5, _k(1.0))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	# --- bóng tàn ảnh
	# ================= BIỂU TƯỢNG ĐẶC TRƯNG (mỗi `sig` của kỹ năng một hình riêng) =================
	var sig := "nova"
	var nocreature := false   # kỹ năng có con vật sprite riêng (FxCreature): sig bỏ phần con vật vẽ tay
	var steady := false   # hào quang buff: giữ trạng thái đầy đủ
	var auto := false     # tự tăng prog theo thời gian
	var vs := 0
	var _lowq := false
	var prog := 0.0:
		set(v):
			prog = v
			queue_redraw()

	func _streak(a: Vector2, b: Vector2, w: float) -> void:
		var d := b - a
		if d.length() < 1.0: return
		var nrm := d.orthogonal().normalized()
		var m := a.lerp(b, 0.35)
		for L in [[2.4, 0.18, 0], [1.0, 0.92, 0], [0.34, 1.0, 1]]:
			var ww: float = float(L[0]) * w * 0.5
			var c: Color = _k(float(L[1])) if int(L[2]) == 1 else _a(float(L[1]))
			draw_colored_polygon(PackedVector2Array([a, m + nrm * ww, b, m - nrm * ww]), c)

	func _flame(base: Vector2, h: float, w: float) -> void:
		var pts := PackedVector2Array([base + Vector2(-w, 0), base + Vector2(-w * 0.7, -h * 0.45), base + Vector2(-w * 0.1, -h * 0.7), base + Vector2(0, -h), base + Vector2(w * 0.35, -h * 0.6), base + Vector2(w * 0.8, -h * 0.4), base + Vector2(w, 0)])
		draw_colored_polygon(pts, _a(0.85))
		draw_colored_polygon(PackedVector2Array([base + Vector2(-w * 0.5, 0), base + Vector2(0, -h * 0.65), base + Vector2(w * 0.5, 0)]), _k(0.95))

	func _starpoly(n: int, r1: float, r2: float, c: Color, rot: float = -PI * 0.5) -> void:
		var pts := PackedVector2Array()
		for k in range(n * 2):
			var a := rot + PI * float(k) / n
			var rr := r1 if k % 2 == 0 else r2
			pts.append(Vector2(cos(a), sin(a)) * rr)
		draw_colored_polygon(pts, c)

	func _wing(side: float, span: float) -> void:
		for i in range(6):
			var t := float(i) / 5.0
			var tip := Vector2(side * span * (1.0 - t * 0.35), -span * 0.55 + t * span * 0.95)
			_streak(Vector2(side * 4.0, -6.0), tip, 7.0 - t * 2.0)

	func _man(x: float, al: float) -> void:
		draw_circle(Vector2(x, -22), 6.0, _a(al))
		draw_colored_polygon(PackedVector2Array([Vector2(x - 8, -15), Vector2(x + 8, -15), Vector2(x + 6, 6), Vector2(x - 6, 6)]), _a(al))
		draw_line(Vector2(x - 3, 6), Vector2(x - 6, 24), _a(al), 4.0)
		draw_line(Vector2(x + 3, 6), Vector2(x + 6, 24), _a(al), 4.0)

	## Kiếm cắm xuống: mũi ở gốc toạ độ, thân hướng lên.
	func _sword_down(pos: Vector2, ln: float, lean: float, al: float) -> void:
		draw_set_transform(pos, lean, Vector2.ONE)
		draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(-5, -ln * 0.8), Vector2(0, -ln), Vector2(5, -ln * 0.8)]), PackedColorArray([_a(al), _a(al), _a(al), _a(al)]))
		draw_line(Vector2(0, -2), Vector2(0, -ln * 0.9), _k(al), 1.4)
		draw_rect(Rect2(-9, -ln - 4, 18, 4), _a(al))
		draw_rect(Rect2(-2, -ln - 22, 4, 18), _a(al * 0.9))
		draw_circle(Vector2(0, -ln - 24), 3.0, _k(al))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	func _plus(c: Vector2, sz: float, c1: Color, c2: Color) -> void:
		draw_rect(Rect2(c.x - sz, c.y - sz * 0.32, sz * 2.0, sz * 0.64), c1)
		draw_rect(Rect2(c.x - sz * 0.32, c.y - sz, sz * 0.64, sz * 2.0), c1)
		draw_rect(Rect2(c.x - sz * 0.6, c.y - sz * 0.12, sz * 1.2, sz * 0.24), c2)
		draw_rect(Rect2(c.x - sz * 0.12, c.y - sz * 0.6, sz * 0.24, sz * 1.2), c2)

	func _process(delta: float) -> void:
		if auto: prog += delta

	func _d_sig_new() -> bool:
		var t := prog
		if steady: return FxExt.draw_aura(self, sig, t, _lowq)
		if FxExt.draw_sig(self, sig, t, _lowq): return true
		match sig:
			"swordrain":
				# vùng sáng dưới đất + nhiều kiếm từ trên trời rơi xuống, cắm vào khu vực
				draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.3))
				draw_circle(Vector2.ZERO, 96.0, _a(0.14 * minf(1.0, t * 2.0)))
				draw_arc(Vector2.ZERO, 96.0, 0.0, TAU, 48, _a(0.55 * minf(1.0, t * 2.0)), 3.0)
				draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
				var n := 5 if _lowq else 11
				for k in range(n):
					var x := -86.0 + 172.0 * float(k) / float(n - 1) + _rng.randf_range(-6.0, 6.0)
					var d := fposmod(float(k) * 0.382, 1.0) * 0.5
					var gy := _rng.randf_range(-4.0, 14.0)
					var q := clampf((t - d) / 0.26, 0.0, 1.0)
					if q <= 0.0: continue
					var y := lerpf(-230.0, gy, q * q)
					var lean := -x / 420.0
					if q < 1.0:
						draw_line(Vector2(x, y - 90.0), Vector2(x, y - 30.0), _a(0.3), 6.0)
					_sword_down(Vector2(x, y), 44.0, lean, 0.95)
					if q >= 1.0:
						var r := minf(1.0, (t - d - 0.26) * 5.0)
						draw_set_transform(Vector2(x, gy), 0.0, Vector2(1.0, 0.35))
						draw_arc(Vector2.ZERO, 8.0 + 22.0 * r, 0.0, TAU, 20, _k(0.8 * (1.0 - r)), 2.0)
						draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
				return true
			"swordshield":
				# khiên kiếm phát sáng trước người; nửa sau: phản đòn
				var form := minf(1.0, t * 2.2)
				var pulse := 1.0 + 0.06 * sin(t * 28.0)
				for i in range(6):
					var u := float(i) / 5.0
					draw_circle(Vector2(-6, -6), (48.0 - 26.0 * u) * pulse * form, _mix(u, 0.07 + 0.07 * u))
				draw_arc(Vector2(-6, -6), 40.0 * form, 0.0, TAU, 40, _a(0.9), 3.5)
				draw_arc(Vector2(-6, -6), 33.0 * form, 0.0, TAU, 40, _k(0.8), 1.5)
				for sgn in [-1.0, 1.0]:
					var dir := Vector2(1.0, sgn).normalized()
					var nr := dir.orthogonal()
					var a := Vector2(-6, -6) - dir * 38.0 * form
					var b := Vector2(-6, -6) + dir * 38.0 * form
					draw_colored_polygon(PackedVector2Array([a, a.lerp(b, 0.15) + nr * 3.5, b, a.lerp(b, 0.15) - nr * 3.5]), _a(0.92))
					draw_line(a, b, _k(0.95), 1.4)
					draw_line(a.lerp(b, 0.12) + nr * 8.0, a.lerp(b, 0.12) - nr * 8.0, _a(0.95), 3.0)
				if t > 0.5:
					var c := (t - 0.5) * 2.0
					_starpoly(8, 10.0 + 44.0 * c, 4.0, _k(0.85 * (1.0 - c)))
					draw_arc(Vector2(-6, -6), 40.0 + 40.0 * c, 0.0, TAU, 40, _k(0.9 * (1.0 - c)), 4.0)
					_streak(Vector2(10, -6), Vector2(10 + 90.0 * c, -6), 12.0 * (1.0 - c * 0.5))
				return true
			"quake":
				# sóng xung kích lan trên mặt đất, nứt đất, đá văng
				draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.32))
				for k in range(3):
					var q := t * 1.5 - 0.15 * k
					if q <= 0.0: continue
					var rr := 18.0 + 130.0 * minf(1.0, q)
					var al := clampf(1.0 - q * 0.8, 0.0, 1.0)
					draw_arc(Vector2.ZERO, rr, 0.0, TAU, 48, _a(0.3 * al), 12.0)
					draw_arc(Vector2.ZERO, rr, 0.0, TAU, 48, _a(0.9 * al), 4.0)
					draw_arc(Vector2.ZERO, rr, 0.0, TAU, 48, _k(0.8 * al), 1.4)
				draw_circle(Vector2.ZERO, 30.0 * minf(1.0, t * 3.0), _a(0.25))
				draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
				var nc := 7 if _lowq else 11
				for k in range(nc):
					var a := TAU * float(k) / float(nc) + _rng.randf_range(-0.2, 0.2)
					var L := _rng.randf_range(70.0, 130.0) * minf(1.0, t * 2.5)
					var pts := PackedVector2Array([Vector2.ZERO])
					var cur := Vector2.ZERO
					for s2 in range(5):
						var aa := a + _rng.randf_range(-0.3, 0.3)
						cur += Vector2(cos(aa), sin(aa) * 0.34) * L / 5.0
						pts.append(cur)
					draw_polyline(pts, _a(0.3), 6.0)
					draw_polyline(pts, _a(0.95), 2.4)
				var nr2 := 6 if _lowq else 12
				for k in range(nr2):
					var ang := _rng.randf_range(-2.6, -0.5)
					var spd := _rng.randf_range(60.0, 120.0)
					var life := minf(1.0, t * 1.3)
					var px := cos(ang) * spd * life * 1.1 * (1.0 if k % 2 == 0 else -1.0)
					var py := sin(ang) * spd * life + 150.0 * life * life
					var sz := _rng.randf_range(3.0, 7.0)
					draw_set_transform(Vector2(px, py), life * 6.0 + k, Vector2.ONE)
					draw_colored_polygon(PackedVector2Array([Vector2(-sz, -sz * 0.6), Vector2(sz * 0.8, -sz), Vector2(sz, sz * 0.5), Vector2(-sz * 0.3, sz)]), Color(core.r * 0.5 + col.r * 0.4, core.g * 0.5 + col.g * 0.4, core.b * 0.5 + col.b * 0.4, 0.95))
					draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
				return true
			"swordawaken":
				# thanh kiếm lớn dần, hào quang toả quanh người
				var g := minf(1.0, t * 1.4)
				var pulse2 := 1.0 + 0.08 * sin(t * 20.0)
				for i in range(8):
					var u := float(i) / 7.0
					draw_circle(Vector2(0, -6), (76.0 * g * pulse2) * (1.0 - u * 0.85), _mix(u, 0.05 + 0.07 * u))
				for k in range(14):
					var a := TAU * float(k) / 14.0 + t * 1.2
					var d := Vector2(cos(a), sin(a))
					var ln := (50.0 + (k % 2) * 26.0) * g
					draw_colored_polygon(PackedVector2Array([d * 30.0 + d.orthogonal() * 3.5, d * (30.0 + ln), d * 30.0 - d.orthogonal() * 3.5]), _a(0.55))
				draw_arc(Vector2(0, -6), 52.0 * g, 0.0, TAU, 40, _k(0.75), 2.5)
				var s := 0.35 + 0.95 * g
				var bl := 62.0 * s
				var cy := 14.0
				draw_colored_polygon(PackedVector2Array([Vector2(0, cy - bl - 16.0 * s), Vector2(-9.0 * s, cy - bl), Vector2(-8.0 * s, cy), Vector2(8.0 * s, cy), Vector2(9.0 * s, cy - bl)]), _a(0.78))
				draw_line(Vector2(0, cy), Vector2(0, cy - bl - 10.0 * s), _k(0.95), 2.0 * s)
				draw_rect(Rect2(-18.0 * s, cy, 36.0 * s, 5.0 * s), _a(0.9))
				draw_rect(Rect2(-3.0 * s, cy + 5.0 * s, 6.0 * s, 20.0 * s), _a(0.85))
				draw_circle(Vector2(0, cy + 28.0 * s), 4.0 * s, _k(0.95))
				_starpoly(4, 20.0 * g, 3.0, _k(0.9 * g), -PI * 0.5)
				return true
			"healplus":
				for i in range(6):
					var u := float(i) / 5.0
					draw_circle(Vector2(0, 4), 36.0 * (1.0 - u * 0.8), _mix(u, 0.05 + 0.06 * u))
				var nn := 4 if _lowq else 7
				for k in range(nn):
					var x := -34.0 + 68.0 * float(k) / float(nn - 1) + sin(t * 6.0 + k) * 5.0
					var q := fposmod(t * 1.1 + float(k) * 0.19, 1.0)
					var y := 24.0 - 78.0 * q
					var al := sin(q * PI)
					_plus(Vector2(x, y), 6.0 + float(k % 3) * 2.0, _a(0.9 * al), _k(al))
				draw_set_transform(Vector2(0, 26), 0.0, Vector2(1.0, 0.32))
				draw_arc(Vector2.ZERO, 14.0 + 30.0 * t, 0.0, TAU, 32, _a(0.8 * (1.0 - t)), 3.0)
				draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
				return true
			"lightball":
				var cx := -24.0 + 60.0 * t
				_rng.seed = vs + int(t * 18.0) * 31
				for i in range(6):
					var u := float(i) / 5.0
					draw_circle(Vector2(cx, 0), 26.0 * (1.0 - u * 0.8), _mix(u, 0.12 + 0.1 * u))
				for k in range(8):
					var a := TAU * float(k) / 8.0 + t * 9.0
					var d := Vector2(cos(a), sin(a))
					var pts := PackedVector2Array([Vector2(cx, 0) + d * 8.0])
					for j in range(1, 4):
						pts.append(Vector2(cx, 0) + d * (8.0 + 9.0 * j) + d.orthogonal() * _rng.randf_range(-6.0, 6.0))
					draw_polyline(pts, _a(0.9), 3.0)
					draw_polyline(pts, _k(1.0), 1.2)
				draw_circle(Vector2(cx, 0), 7.0, _k(1.0))
				for k in range(3):
					var a2 := -t * 12.0 + TAU * k / 3.0
					draw_circle(Vector2(cx, 0) + Vector2(cos(a2), sin(a2) * 0.6) * 30.0, 3.0, _k(0.95))
				return true
			"poison":
				var gc := Color(0.55, 0.92, 0.2)
				var gd := Color(0.25, 0.55, 0.1)
				for k in range(6):
					var x := _rng.randf_range(-36.0, 36.0)
					draw_circle(Vector2(x, 6.0 - 6.0 * t), 12.0 + 8.0 * t, Color(gd.r, gd.g, gd.b, 0.3))
				for k in range(7):
					var x2 := _rng.randf_range(-34.0, 34.0)
					var q := fposmod(t * 1.2 + float(k) * 0.16, 1.0)
					var y := 16.0 - 50.0 * q
					var r := 3.0 + _rng.randf() * 4.0
					draw_arc(Vector2(x2, y), r, 0.0, TAU, 12, Color(gc.r, gc.g, gc.b, 0.9 * (1.0 - q)), 1.6)
					draw_circle(Vector2(x2 - r * 0.3, y - r * 0.3), r * 0.25, Color(1, 1, 1, 0.7 * (1.0 - q)))
				for k in range(4):
					var x3 := -24.0 + 16.0 * k
					var y3 := -30.0 + 56.0 * minf(1.0, t * 1.3 + k * 0.04)
					draw_circle(Vector2(x3, y3), 5.0, Color(gc.r, gc.g, gc.b, 0.95))
					draw_colored_polygon(PackedVector2Array([Vector2(x3 - 3.5, y3 - 2), Vector2(x3 + 3.5, y3 - 2), Vector2(x3, y3 - 14)]), Color(gc.r, gc.g, gc.b, 0.95))
				return true
		return false

	func _d_sig() -> void:
		_rng.seed = vs
		if _d_sig_new(): return
		var t := prog
		var flip := 1.0 if (vs % 2 == 0) else -1.0
		match sig:
			"claw":
				for k in range(3):
					var x := (k - 1) * 17.0
					_streak(Vector2(x - 14, -38), Vector2(x - 14, -38).lerp(Vector2(x + 14, 38), t), 9.0)
			"dagger", "blade", "blades", "sword", "steel", "slash":
				var n2 := 2 if sig != "blades" else 3
				for k in range(n2):
					var q := clampf(t * 1.6 - 0.35 * k, 0.0, 1.0)
					var ang := (-0.7 + 1.4 * k / maxf(1.0, n2 - 1.0)) if n2 > 1 else -0.6
					var a0 := Vector2(-48, -34).rotated(ang * 0.3 * flip)
					var b0 := Vector2(48, 34).rotated(ang * 0.3 * flip)
					if k % 2 == 1: a0 = Vector2(-48, 34); b0 = Vector2(48, -34)
					_streak(a0, a0.lerp(b0, q), 11.0 if sig != "dagger" else 7.0)
				if sig == "steel" or sig == "sword": _starpoly(4, 16.0 * t, 3.0, _k(0.9))
			"cross":
				_streak(Vector2(0, -52), Vector2(0, -52).lerp(Vector2(0, 52), t), 10.0)
				_streak(Vector2(-52, 0), Vector2(-52, 0).lerp(Vector2(52, 0), t), 10.0)
				_starpoly(4, 22.0, 4.0, _k(0.85))
			"stab", "thrust", "lance", "arrow":
				for k in range(5):
					var y := -16.0 + 8.0 * k
					var l := 40.0 + (k % 3) * 22.0
					draw_line(Vector2(-l + 70.0 * t, y), Vector2(-10 + 70.0 * t, y), _a(0.5), 2.0)
				var hx := -20.0 + 90.0 * t
				_streak(Vector2(hx - 70.0, 0), Vector2(hx + 6.0, 0), 8.0 if sig != "lance" else 12.0)
				draw_colored_polygon(PackedVector2Array([Vector2(hx, -8), Vector2(hx + 22, 0), Vector2(hx, 8)]), _k(0.95))
				if sig == "arrow": draw_line(Vector2(hx - 70, 0), Vector2(hx - 82, -7), _a(0.8), 2.5); draw_line(Vector2(hx - 70, 0), Vector2(hx - 82, 7), _a(0.8), 2.5)
			"sweep", "wave", "fan", "streak":
				var cnt := 3 if sig in ["fan", "wave", "streak"] else 1
				for k in range(cnt):
					var rr := 34.0 + k * 14.0
					var sp := 1.0 * t + 0.1
					draw_set_transform(Vector2.ZERO, (k - 1) * (0.5 if sig == "fan" else 0.0) * flip, Vector2(1.0, 0.7))
					_crescent(rr, sp, 12.0, _a(0.8 - 0.15 * k))
					_crescent(rr, sp * 0.9, 4.0, _k(0.9))
				draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			"whirl", "orbit", "disc", "storm", "vortex":
				var rot := t * TAU * 2.2 * flip
				if sig in ["vortex", "storm"]:
					for arm in range(3):
						var pts := PackedVector2Array()
						for k in range(24):
							var u := float(k) / 23.0
							var a := rot + arm * TAU / 3.0 + u * 3.2
							pts.append(Vector2(cos(a), sin(a)) * (6.0 + 44.0 * u))
						draw_polyline(pts, _a(0.25), 9.0)
						draw_polyline(pts, _a(0.9), 3.5)
						draw_polyline(pts, _k(0.9), 1.2)
				else:
					draw_arc(Vector2.ZERO, 38.0, 0.0, TAU, 40, _a(0.3), 6.0)
					for k in range(4 if sig != "orbit" else 3):
						var a2 := rot + TAU * k / (4.0 if sig != "orbit" else 3.0)
						var c2 := Vector2(cos(a2), sin(a2)) * 38.0
						if sig == "orbit": draw_circle(c2, 8.0, _a(0.9)); draw_circle(c2, 3.5, _k(1.0))
						else: draw_colored_polygon(PackedVector2Array([c2 + Vector2(cos(a2 + 1.6), sin(a2 + 1.6)) * 12.0, c2 + Vector2(cos(a2), sin(a2)) * 16.0, c2 - Vector2(cos(a2 + 1.6), sin(a2 + 1.6)) * 12.0]), _a(0.9))
					if sig == "disc": draw_circle(Vector2.ZERO, 14.0, _a(0.7)); draw_circle(Vector2.ZERO, 6.0, _k(0.95))
			"bash", "hammer", "quake", "charge", "counter", "fortress", "roar":
				if sig == "hammer":
					var hy := -60.0 + 50.0 * minf(1.0, t * 1.6)
					draw_rect(Rect2(-18, hy - 20, 36, 22), _a(0.95))
					draw_rect(Rect2(-18, hy - 20, 36, 5), _k(0.9))
					draw_rect(Rect2(-3, hy + 2, 6, 40), _a(0.85))
				if sig == "roar":
					for k in range(3):
						draw_arc(Vector2(-20, 0), 20.0 + 18.0 * k + 30.0 * t, -0.8, 0.8, 14, _a(0.9 - 0.25 * k), 5.0 - k)
				elif sig == "charge":
					for k in range(3):
						var xo := -50.0 + 38.0 * k + 24.0 * t
						draw_polyline(PackedVector2Array([Vector2(xo, -22), Vector2(xo + 22, 0), Vector2(xo, 22)]), _a(0.9 - 0.2 * k), 7.0)
				elif sig == "counter":
					draw_polyline(PackedVector2Array([Vector2(30, -22), Vector2(8, 0), Vector2(30, 22)]), _a(0.9), 7.0)
					draw_polyline(PackedVector2Array([Vector2(-8, -22), Vector2(-30, 0), Vector2(-8, 22)]), _a(0.9), 7.0)
					draw_arc(Vector2.ZERO, 14.0 + 30.0 * t, 0.0, TAU, 28, _k(0.9), 3.0)
				elif sig == "fortress":
					for k in range(3):
						var xx := -36.0 + 36.0 * k
						draw_rect(Rect2(xx - 12, -26.0 * minf(1.0, t * 1.5 + 0.2), 24, 26.0 * minf(1.0, t * 1.5 + 0.2)), _a(0.75))
						for m in range(3): draw_rect(Rect2(xx - 12 + m * 9.0, -32.0 * minf(1.0, t * 1.5 + 0.2), 6, 6), _k(0.85))
				elif sig == "quake":
					for k in range(7):
						var a3 := PI * (0.05 + 0.9 * k / 6.0) + PI
						var l2 := (30.0 + (k % 3) * 14.0) * t
						draw_polyline(PackedVector2Array([Vector2.ZERO, Vector2(cos(a3), sin(a3)) * l2 * 0.5 + Vector2(0, 3), Vector2(cos(a3), sin(a3)) * l2]), _a(0.9), 3.0)
					draw_arc(Vector2.ZERO, 50.0 * t, PI, TAU, 24, _k(0.8), 3.0)
				else:
					for k in range(10):
						var a4 := TAU * k / 10.0
						var d4 := Vector2(cos(a4), sin(a4))
						var nr := d4.orthogonal()
						var L4 := (18.0 + (k % 2) * 14.0) + 40.0 * t
						draw_colored_polygon(PackedVector2Array([d4 * 8.0 + nr * 4.0, d4 * L4, d4 * 8.0 - nr * 4.0]), _a(0.9))
					draw_arc(Vector2.ZERO, 12.0 + 40.0 * t, 0.0, TAU, 32, _k(0.9), 3.0)
			"shadow", "clones", "cloak", "veil", "blink", "hop", "smoke":
				if sig == "clones":
					for k in range(4): _man(-42.0 + 28.0 * k + 8.0 * (1.0 - t), 0.55)
				elif sig == "shadow":
					for k in range(3): _man(-28.0 * k * t, 0.6 - 0.15 * k)
				elif sig == "smoke":
					for k in range(7):
						draw_circle(Vector2(_rng.randf_range(-26, 26), -_rng.randf_range(0, 40) * t), 10.0 + 14.0 * t, _a(0.3))
				elif sig == "blink":
					draw_arc(Vector2(-40, 0), 16.0, 0.0, TAU, 20, _a(0.9), 3.0)
					draw_arc(Vector2(40, 0), 16.0 * t, 0.0, TAU, 20, _k(0.9), 3.0)
					for k in range(7): draw_circle(Vector2(-30.0 + 10.0 * k, 0), 2.0, _a(0.7))
				elif sig == "hop":
					for k in range(9):
						var u2 := float(k) / 8.0
						draw_circle(Vector2(-44.0 + 88.0 * u2, -34.0 * 4.0 * u2 * (1.0 - u2)), 3.0, _a(0.9))
					draw_arc(Vector2(40, 8), 10.0, 0.0, TAU, 14, _k(0.8), 2.0)
				else:
					for k in range(5):
						var xw := -40.0 + 20.0 * k
						var pts2 := PackedVector2Array()
						for j in range(8):
							pts2.append(Vector2(xw + sin(j * 0.9 + t * 6.0 + k) * 5.0, -34.0 + j * 9.0))
						draw_polyline(pts2, _a(0.65), 6.0 if sig == "cloak" else 3.0)
			"cursed", "miasma", "soul", "drain", "void", "spirit", "summon", "chain", "trap", "net", "eye":
				match sig:
					"cursed":
						draw_circle(Vector2(0, -6), 18.0, _a(0.92))
						draw_rect(Rect2(-10, 6, 20, 12), _a(0.92))
						draw_circle(Vector2(-6.5, -7), 4.5, Color(0, 0, 0, 0.9)); draw_circle(Vector2(6.5, -7), 4.5, Color(0, 0, 0, 0.9))
						draw_colored_polygon(PackedVector2Array([Vector2(-2.5, 2), Vector2(2.5, 2), Vector2(0, -2)]), Color(0, 0, 0, 0.9))
						draw_arc(Vector2(0, -6), 26.0 * t + 6.0, 0.0, TAU, 28, _k(0.7), 2.0)
					"miasma":
						for k in range(8): draw_circle(Vector2(_rng.randf_range(-40, 40), _rng.randf_range(-16, 8)), 14.0 + 10.0 * t, _a(0.28))
					"soul":
						for k in range(4):
							var xs := -30.0 + 20.0 * k
							var ys := -10.0 - 40.0 * t - k * 5.0
							draw_circle(Vector2(xs, ys), 6.0, _a(0.9)); draw_circle(Vector2(xs, ys), 2.5, _k(1.0))
							draw_polyline(PackedVector2Array([Vector2(xs, ys + 6), Vector2(xs + 4, ys + 16), Vector2(xs - 3, ys + 26)]), _a(0.5), 4.0)
					"drain":
						for k in range(10):
							var a5 := TAU * k / 10.0
							var d5 := Vector2(cos(a5), sin(a5))
							var r5 := 60.0 * (1.0 - t)
							draw_line(d5 * (r5 + 18.0), d5 * r5, _a(0.7), 2.5)
							draw_circle(d5 * r5, 3.0, _k(0.95))
						draw_circle(Vector2.ZERO, 10.0 + 6.0 * t, _a(0.9))
					"void":
						draw_circle(Vector2.ZERO, 22.0, Color(0.02, 0.0, 0.06, 0.92))
						for arm in range(2):
							var pv := PackedVector2Array()
							for k in range(20):
								var u3 := float(k) / 19.0
								var a6 := t * 5.0 + arm * PI + u3 * 3.6
								pv.append(Vector2(cos(a6), sin(a6)) * (22.0 + 26.0 * u3))
							draw_polyline(pv, _a(0.8), 3.0)
					"spirit":
						for k in range(3):
							var a7 := t * 5.0 + TAU * k / 3.0
							var c7 := Vector2(cos(a7), sin(a7)) * 32.0
							draw_circle(c7, 8.0, _a(0.8)); draw_circle(c7, 3.0, _k(1.0))
							draw_arc(Vector2.ZERO, 32.0, a7 - 0.9, a7, 8, _a(0.4), 4.0)
					"summon":
						draw_set_transform(Vector2(0, 12), 0.0, Vector2(1, 0.4))
						draw_arc(Vector2.ZERO, 34.0, 0.0, TAU, 32, _a(0.9), 3.0)
						draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
						_man(0, 0.7 * t)
					"chain":
						for k in range(4):
							var cx := -36.0 + 24.0 * k
							var cy := 8.0 * sin(k * 1.3)
							draw_set_transform(Vector2(cx, cy), 0.0 if k % 2 == 0 else PI * 0.5, Vector2(1.0, 0.55))
							draw_arc(Vector2.ZERO, 12.0, 0.0, TAU, 14, _a(0.95), 3.5)
							draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
					"trap":
						for k in range(9):
							var xt := -40.0 + 10.0 * k
							var ht := 26.0 * minf(1.0, t * 2.0)
							draw_colored_polygon(PackedVector2Array([Vector2(xt - 5, 0), Vector2(xt + 5, 0), Vector2(xt, -ht)]), _a(0.9))
					"net":
						for k in range(-3, 4):
							draw_line(Vector2(k * 12.0 - 36.0, -36.0 * t), Vector2(k * 12.0 + 36.0, 36.0 * t), _a(0.8), 2.0)
							draw_line(Vector2(k * 12.0 + 36.0, -36.0 * t), Vector2(k * 12.0 - 36.0, 36.0 * t), _a(0.8), 2.0)
					_:   # eye
						draw_colored_polygon(PackedVector2Array([Vector2(-34, 0), Vector2(-16, -14), Vector2(0, -17), Vector2(16, -14), Vector2(34, 0), Vector2(16, 14), Vector2(0, 17), Vector2(-16, 14)]), _a(0.45))
						draw_circle(Vector2.ZERO, 11.0, _a(0.95)); draw_circle(Vector2.ZERO, 5.0 + 2.0 * t, Color(0, 0, 0, 0.9)); draw_circle(Vector2(-3, -3), 2.0, _k(1.0))
			"fire", "flame", "hell", "phoenix", "dragon":
				if sig == "phoenix":
					_wing(1.0, 52.0 * minf(1.0, t + 0.3)); _wing(-1.0, 52.0 * minf(1.0, t + 0.3))
					_flame(Vector2(0, 14), 44.0, 12.0)
				elif sig == "dragon":
					var pd := PackedVector2Array()
					for k in range(18):
						var u4 := float(k) / 17.0 * t
						pd.append(Vector2(-50.0 + 100.0 * u4, sin(u4 * 9.0) * 18.0))
					if pd.size() > 1:
						draw_polyline(pd, _a(0.25), 14.0); draw_polyline(pd, _a(0.9), 7.0); draw_polyline(pd, _k(0.9), 2.4)
						var hd := pd[pd.size() - 1]
						draw_colored_polygon(PackedVector2Array([hd + Vector2(-4, -10), hd + Vector2(20, 0), hd + Vector2(-4, 10)]), _k(0.95))
				elif sig == "hell":
					for k in range(5): _flame(Vector2(-32.0 + 16.0 * k, 10), (30.0 + (k % 2) * 22.0) * minf(1.0, t + 0.2), 9.0)
					_star_lines(5, 2, 40.0, 2.0, _k(0.9))
				else:
					for k in range(3): _flame(Vector2(-18.0 + 18.0 * k, 12), (34.0 + (k % 2) * 24.0) * minf(1.0, t + 0.2), 12.0)
			"frost", "blizzard", "crystal", "drop":
				if sig == "crystal":
					for k in range(3):
						var xc := -22.0 + 22.0 * k
						var hc := (40.0 + (k % 2) * 20.0) * minf(1.0, t + 0.2)
						draw_colored_polygon(PackedVector2Array([Vector2(xc - 8, 8), Vector2(xc - 6, -hc * 0.6), Vector2(xc, -hc), Vector2(xc + 6, -hc * 0.6), Vector2(xc + 8, 8)]), _a(0.85))
						draw_line(Vector2(xc, 8), Vector2(xc, -hc), _k(0.95), 1.5)
				elif sig == "drop":
					for k in range(5):
						var xd := -36.0 + 18.0 * k
						var yd := -40.0 + 70.0 * fposmod(t * 1.4 + k * 0.23, 1.0)
						draw_circle(Vector2(xd, yd), 5.0, _a(0.9)); draw_colored_polygon(PackedVector2Array([Vector2(xd - 3.5, yd - 2), Vector2(xd + 3.5, yd - 2), Vector2(xd, yd - 14)]), _a(0.9))
				elif sig == "blizzard":
					for k in range(14):
						var fxp := _rng.randf_range(-50, 50)
						var fyp := -50.0 + fposmod(_rng.randf() + t * 1.2, 1.0) * 100.0
						draw_circle(Vector2(fxp, fyp), 2.5, _k(0.9)); draw_line(Vector2(fxp - 4, fyp), Vector2(fxp + 4, fyp), _a(0.8), 1.4)
				else:
					for k in range(6):
						var a8 := TAU * k / 6.0 + t * 0.6
						var d8 := Vector2(cos(a8), sin(a8))
						var n8 := d8.orthogonal()
						draw_line(Vector2.ZERO, d8 * 46.0 * minf(1.0, t + 0.2), _a(0.95), 3.0)
						for bb in [0.45, 0.7]:
							draw_line(d8 * 46.0 * bb, d8 * 46.0 * (bb + 0.15) + n8 * 9.0, _k(0.9), 2.0)
							draw_line(d8 * 46.0 * bb, d8 * 46.0 * (bb + 0.15) - n8 * 9.0, _k(0.9), 2.0)
			"lightning", "bolt", "elem", "shard", "nova":
				if sig == "lightning":
					var pl := PackedVector2Array([Vector2(8, -60), Vector2(-6, -34), Vector2(10, -20), Vector2(-8, 4), Vector2(4, 14)])
					var cutn := int(ceil(pl.size() * clampf(t * 1.6, 0.1, 1.0)))
					var pp := pl.slice(0, cutn)
					if pp.size() > 1: draw_polyline(pp, _a(0.25), 16.0); draw_polyline(pp, _a(0.95), 6.0); draw_polyline(pp, _k(1.0), 2.2)
				elif sig == "bolt":
					for k in range(3):
						var pb := PackedVector2Array([Vector2(-50, -14 + 14 * k)])
						for j in range(5): pb.append(Vector2(-50.0 + 100.0 * (j + 1) / 5.0 * t, -14 + 14 * k + _rng.randf_range(-9, 9)))
						draw_polyline(pb, _a(0.9), 4.0); draw_polyline(pb, _k(1.0), 1.5)
				elif sig == "shard":
					for k in range(7):
						var a9 := TAU * k / 7.0 + vs * 0.1
						var d9 := Vector2(cos(a9), sin(a9))
						var c9 := d9 * (14.0 + 40.0 * t)
						draw_colored_polygon(PackedVector2Array([c9 + d9 * 12.0, c9 + d9.orthogonal() * 4.0, c9 - d9 * 6.0, c9 - d9.orthogonal() * 4.0]), _a(0.9))
				elif sig == "elem":
					var cols := [Color(1.0, 0.5, 0.2), Color(0.5, 0.85, 1.0), Color(1.0, 0.95, 0.4)]
					for k in range(3):
						var a10 := TAU * k / 3.0 + t * 2.0
						var c10 := Vector2(cos(a10), sin(a10)) * 30.0
						draw_circle(c10, 11.0, Color(cols[k] as Color, 0.3)); draw_circle(c10, 6.0, Color(cols[k] as Color, 0.95)); draw_circle(c10, 2.5, _k(1.0))
				else:
					_starpoly(8, 14.0 + 46.0 * t, 5.0, _a(0.85))
					draw_arc(Vector2.ZERO, 10.0 + 50.0 * t, 0.0, TAU, 36, _k(0.9), 3.0)
			"holy", "bless", "angel", "judge", "wings", "dawn", "garden", "bird", "star", "moon", "rune", "dome", "shield":
				match sig:
					"holy":
						draw_arc(Vector2(0, -34), 14.0, 0.0, TAU, 24, _k(0.95), 3.0)
						for k in range(8):
							var a11 := TAU * k / 8.0
							draw_line(Vector2(cos(a11), sin(a11)) * 20.0 + Vector2(0, -34), Vector2(cos(a11), sin(a11)) * (36.0 * t + 20.0) + Vector2(0, -34), _a(0.85), 3.0)
					"bless":
						draw_arc(Vector2.ZERO, 30.0, 0.0, TAU, 32, _a(0.5), 4.0)
						for k in range(9):
							var xb := _rng.randf_range(-34, 34)
							draw_circle(Vector2(xb, -50.0 + 70.0 * fposmod(t * 1.3 + k * 0.17, 1.0)), 3.0, _k(0.95))
					"angel":
						draw_arc(Vector2(0, -42), 13.0, 0.0, TAU, 24, _k(0.95), 3.0)
						_wing(1.0, 46.0 * minf(1.0, t + 0.3)); _wing(-1.0, 46.0 * minf(1.0, t + 0.3))
					"judge":
						_streak(Vector2(0, -64), Vector2(0, -64).lerp(Vector2(0, 26), minf(1.0, t * 1.5)), 14.0)
						draw_colored_polygon(PackedVector2Array([Vector2(-7, 26), Vector2(7, 26), Vector2(0, 40)]), _k(0.95))
						draw_line(Vector2(-18, 0), Vector2(18, 0), _a(0.95), 4.0)
					"wings":
						_wing(1.0, 62.0 * minf(1.0, t + 0.25)); _wing(-1.0, 62.0 * minf(1.0, t + 0.25))
					"dawn":
						for k in range(9):
							var a12 := PI + PI * float(k) / 8.0
							draw_line(Vector2(cos(a12), sin(a12)) * 16.0, Vector2(cos(a12), sin(a12)) * (28.0 + 30.0 * t), _a(0.85), 3.5)
						draw_circle(Vector2.ZERO, 14.0, _k(0.95))
					"garden":
						for k in range(6):
							var a13 := TAU * k / 6.0
							var d13 := Vector2(cos(a13), sin(a13))
							draw_colored_polygon(PackedVector2Array([Vector2.ZERO, d13 * 14.0 + d13.orthogonal() * 10.0, d13 * 36.0 * minf(1.0, t + 0.2), d13 * 14.0 - d13.orthogonal() * 10.0]), _a(0.75))
						draw_circle(Vector2.ZERO, 7.0, _k(0.95))
					"bird":
						var wy := -sin(t * 14.0) * 12.0
						draw_polyline(PackedVector2Array([Vector2(-40, 8 + wy), Vector2(-18, -8 + wy * 0.5), Vector2(0, 4), Vector2(18, -8 + wy * 0.5), Vector2(40, 8 + wy)]), _a(0.95), 7.0)
						draw_circle(Vector2(0, 2), 6.0, _k(0.95))
					"star":
						_starpoly(5, 30.0 * minf(1.0, t + 0.3), 12.0, _a(0.9)); _starpoly(5, 16.0, 6.0, _k(0.95))
					"moon":
						draw_set_transform(Vector2.ZERO, -0.4, Vector2.ONE)
						_crescent(34.0, 1.9, 26.0, _a(0.9))
						_crescent(34.0, 1.7, 8.0, _k(0.9))
						draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
					"rune":
						draw_arc(Vector2.ZERO, 34.0, 0.0, TAU, 32, _a(0.9), 3.0)
						for k in range(6):
							var a14 := TAU * k / 6.0 + t * 2.0
							var p14 := Vector2(cos(a14), sin(a14)) * 22.0
							draw_line(p14 + Vector2(-5, -6), p14 + Vector2(5, 6), _k(0.95), 2.5); draw_line(p14 + Vector2(5, -6), p14 + Vector2(-5, 6), _k(0.95), 2.5)
					"dome":
						draw_arc(Vector2(0, 14), 46.0, PI, TAU, 28, _a(0.35), 12.0)
						draw_arc(Vector2(0, 14), 46.0, PI, TAU, 28, _a(0.95), 3.0)
						for k in range(5): draw_arc(Vector2(0, 14), 46.0 - k * 2.0, PI + k * 0.6, PI + k * 0.6 + 0.4, 6, _k(0.9), 2.0)
					_:   # shield
						draw_colored_polygon(PackedVector2Array([Vector2(-24, -28), Vector2(24, -28), Vector2(24, 0), Vector2(0, 32), Vector2(-24, 0)]), _a(0.75))
						draw_polyline(PackedVector2Array([Vector2(-24, -28), Vector2(24, -28), Vector2(24, 0), Vector2(0, 32), Vector2(-24, 0), Vector2(-24, -28)]), _k(0.95), 3.0)
						draw_line(Vector2(0, -22), Vector2(0, 20), _k(0.9), 3.0); draw_line(Vector2(-14, -8), Vector2(14, -8), _k(0.9), 3.0)
			"blood", "bloodlust", "rage", "thorn", "awaken":
				match sig:
					"blood":
						for k in range(5):
							var xb2 := -30.0 + 15.0 * k
							var yb := -30.0 + 56.0 * minf(1.0, t * 1.4 + k * 0.05)
							draw_circle(Vector2(xb2, yb), 6.0, _a(0.95)); draw_colored_polygon(PackedVector2Array([Vector2(xb2 - 4, yb - 2), Vector2(xb2 + 4, yb - 2), Vector2(xb2, yb - 16)]), _a(0.95))
					"bloodlust":
						draw_arc(Vector2.ZERO, 30.0, 0.0, TAU, 32, _a(0.4), 7.0)
						for k in range(8):
							var a15 := TAU * k / 8.0
							var d15 := Vector2(cos(a15), sin(a15))
							draw_colored_polygon(PackedVector2Array([d15 * 28.0 + d15.orthogonal() * 4.0, d15 * (40.0 + 14.0 * t), d15 * 28.0 - d15.orthogonal() * 4.0]), _a(0.9))
					"rage":
						for k in range(7):
							var xr := -30.0 + 10.0 * k
							var hr := (30.0 + (k % 3) * 16.0) * minf(1.0, t + 0.3)
							draw_polyline(PackedVector2Array([Vector2(xr, 10), Vector2(xr + 4, 10 - hr * 0.5), Vector2(xr - 3, 10 - hr)]), _a(0.9), 4.0)
						draw_polyline(PackedVector2Array([Vector2(-14, -26), Vector2(0, -20), Vector2(14, -26)]), _k(0.95), 4.0)
					"thorn":
						for k in range(7):
							var xth := -42.0 + 14.0 * k
							var hth := (24.0 + (k % 2) * 14.0) * minf(1.0, t * 1.6)
							draw_colored_polygon(PackedVector2Array([Vector2(xth - 5, 0), Vector2(xth + 5, 0), Vector2(xth + 2.0 * flip, -hth)]), _a(0.92))
					_:   # awaken
						for k in range(10):
							var xa := -36.0 + 8.0 * k
							draw_line(Vector2(xa, 14), Vector2(xa, 14.0 - (30.0 + (k % 3) * 18.0) * minf(1.0, t + 0.2)), _a(0.7), 3.0)
						draw_arc(Vector2(0, 8), 30.0 + 14.0 * t, 0.0, TAU, 32, _k(0.9), 3.0)
			_:
				_starpoly(8, 14.0 + 40.0 * t, 5.0, _a(0.85))
				draw_arc(Vector2.ZERO, 10.0 + 44.0 * t, 0.0, TAU, 36, _k(0.9), 3.0)

	func _d_ghost() -> void:
		for g in range(3):
			var ox := -float(g) * 14.0
			var al := 0.55 - 0.17 * g
			draw_circle(Vector2(ox, -34), 7.0, _a(al))
			draw_colored_polygon(PackedVector2Array([Vector2(ox - 9, -26), Vector2(ox + 9, -26), Vector2(ox + 6, -6), Vector2(ox - 6, -6)]), _a(al))
			draw_line(Vector2(ox - 3, -6), Vector2(ox - 7, 12), _a(al), 4.0)
			draw_line(Vector2(ox + 3, -6), Vector2(ox + 8, 12), _a(al), 4.0)
		draw_line(Vector2(0, -34), Vector2(-40, -34), _k(0.35), 2.0)

	# --- vết nứt mặt đất
	func _d_cracks() -> void:
		draw_circle(Vector2.ZERO, 14.0, _a(0.3))
		for k in range(8):
			var a := TAU * k / 8.0 + _rng.randf_range(-0.2, 0.2)
			var pts := PackedVector2Array([Vector2.ZERO])
			var cur := Vector2.ZERO
			var L := _rng.randf_range(42.0, 70.0)
			for s in range(5):
				var aa := a + _rng.randf_range(-0.35, 0.35)
				cur += Vector2(cos(aa), sin(aa)) * L / 5.0
				pts.append(cur)
			draw_polyline(pts, _a(0.3), 7.0)
			draw_polyline(pts, _a(0.9), 3.0)
			draw_polyline(pts, _k(0.95), 1.2)

	# --- vật rơi từ trên xuống (kiếm / búa / giáo)
	func _d_fall() -> void:
		var sh := str(p.get("shape", ""))
		draw_polygon(PackedVector2Array([Vector2(-10, -10), Vector2(10, -10), Vector2(0, -150)]), PackedColorArray([_a(0.5), _a(0.5), _a(0.0)]))
		if sh == "hammer":
			draw_rect(Rect2(-20, 8, 40, 24), _a(0.95))
			draw_rect(Rect2(-20, 8, 40, 5), _k(0.9))
			draw_rect(Rect2(-3, -36, 6, 46), _a(0.9))
		elif sh == "sword":
			draw_colored_polygon(PackedVector2Array([Vector2(0, 46), Vector2(-7, -10), Vector2(7, -10)]), _a(0.95))
			draw_line(Vector2(0, 40), Vector2(0, -8), _k(1.0), 1.6)
			draw_rect(Rect2(-14, -14, 28, 5), _a(0.95))
			draw_rect(Rect2(-2.5, -34, 5, 21), _a(0.9))
			draw_circle(Vector2(0, -36), 4.0, _k(0.95))
		else:
			draw_colored_polygon(PackedVector2Array([Vector2(0, 50), Vector2(-11, -20), Vector2(11, -20)]), _a(0.9))
			draw_colored_polygon(PackedVector2Array([Vector2(0, 40), Vector2(-4, -12), Vector2(4, -12)]), _k(0.8))
		draw_circle(Vector2(0, 40), 9.0, _k(0.5))

	# --- thiên thạch (rơi chéo, đuôi lửa)
	func _d_meteor() -> void:
		draw_polygon(PackedVector2Array([Vector2(0, -16), Vector2(0, 16), Vector2(-150, 0)]), PackedColorArray([_a(0.65), _a(0.65), _a(0.0)]))
		draw_polygon(PackedVector2Array([Vector2(0, -8), Vector2(0, 8), Vector2(-90, 0)]), PackedColorArray([_k(0.8), _k(0.8), _k(0.0)]))
		for k in range(5):
			draw_circle(Vector2(-_rng.randf_range(10.0, 90.0), _rng.randf_range(-12.0, 12.0)), _rng.randf_range(1.5, 3.5), _k(0.8))
		for i in range(6):
			var t := float(i) / 5.0
			draw_circle(Vector2.ZERO, 20.0 * (1.0 - t * 0.8), _mix(t, 0.35 + 0.1 * t))

	# --- mưa tên
	func _d_arrows() -> void:
		for k in range(11):
			var x := -48.0 + 9.6 * k + _rng.randf_range(-3.0, 3.0)
			var y := _rng.randf_range(-30.0, 10.0)
			draw_line(Vector2(x, y - 22), Vector2(x, y + 8), _a(0.85), 2.0)
			draw_line(Vector2(x, y - 22), Vector2(x, y - 6), _a(0.25), 5.0)
			draw_colored_polygon(PackedVector2Array([Vector2(x - 3.5, y + 6), Vector2(x + 3.5, y + 6), Vector2(x, y + 17)]), _k(0.95))
