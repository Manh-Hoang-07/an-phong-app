extends Node2D
const FxExt := preload("res://src/world/fx/FxExt.gd")
const FxProj := preload("res://src/world/fx/FxProj.gd")
const FxCreature := preload("res://src/world/fx/FxCreature.gd")
const AuraOrbit := preload("res://src/world/fx/AuraOrbit.gd")
const FxShape := preload("res://src/world/fx/FxShape.gd")
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

func _take(key: String, color: Color, core: Color, ctx: Dictionary, p: Dictionary) -> FxShape:
	var arr: Array = _pool.get(key, [])
	var node: FxShape = null
	while not arr.is_empty() and node == null:
		var cand: Variant = arr.pop_back()
		if is_instance_valid(cand): node = cand as FxShape
	if node == null:
		node = FxShape.new()
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

## Hiệu ứng trúng đòn đặt đúng vào người quái bị đánh trúng (gọi từ CombatSystem._hit_mob).
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
	if target == null: return
	_sync_orbits(buffs, target)
	if _manifest.is_empty(): return
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
	var n := FxShape.new()
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
	# Hào quang riêng của chiêu (kiếm khổng lồ, cột sáng…) chỉ là phần mở màn: hiện, giữ ~1,5 giây rồi tan hẳn.
	# Sau đó vòng vật thể xoay quanh người (AuraOrbit, xem _sync_orbits) ở lại suốt thời gian buff.
	var tw := n.create_tween()
	tw.tween_interval(0.3)
	tw.tween_property(n, "modulate:a", 0.8, 0.4)
	tw.tween_interval(1.3)
	tw.tween_property(n, "modulate:a", 0.0, 0.6)
	tw.tween_callback(func():
		if is_instance_valid(n):
			n.visible = false
			n.set_process(false))

## ---------------------------------------------------------------- Vòng vật thể xoay quanh người (kiếm / khiên / … theo class)
var _orbits: Dictionary = {}   # id kỹ năng -> [node nửa sau, node nửa trước]

func _sync_orbits(buffs: Dictionary, target: Node2D) -> void:
	var now := Time.get_ticks_msec()
	for id in buffs.keys():
		var b: Dictionary = buffs[id]
		var until := int(b.get("until", 0))
		var cur: Array = _orbits.get(id, [])
		var alive := not cur.is_empty() and is_instance_valid(cur[0]) and is_instance_valid(cur[1])
		if now >= until:
			if alive: _end_orbit(str(id))
			continue
		if alive:
			for n in cur: (n as Node2D).set("until_ms", until)   # dùng lại kỹ năng: gia hạn
		else:
			_start_orbit(str(id), b, target)
	for id in _orbits.keys():
		if not buffs.has(id): _end_orbit(str(id))

func _start_orbit(id: String, b: Dictionary, target: Node2D) -> void:
	var atk := float(b.get("atk", 0.0)) > 0.0 or float(b.get("crit", 0.0)) > 0.0 or float(b.get("speed", 0.0)) > 0.0 or b.get("exec", null) != null
	var defn := str(b.get("name", "")) in ["guard", "manashield"] or float(b.get("reduce", 0.0)) > 0.0 or float(b.get("absorb", 0.0)) > 0.0
	var heal := float(b.get("regen", 0.0)) > 0.0
	if not (atk or defn or heal): return
	# Class của kỹ năng; kỹ năng dùng chung ("chung") thì lấy class của người chơi
	var sch := str(Data.skill(id).get("school", ""))
	if not AuraOrbit.RINGS.has(sch):
		var ps := str(Game.player.get("school", ""))
		sch = str(Data.school(ps).get("base", ps))
	var colors: Array = recipe(id).get("colors", ["0xffffff", "0xffe9a0", "0xffc23c"])
	var pair: Array = []
	for layer in range(2):
		var n := AuraOrbit.new()
		n.layer = layer
		if not n.setup(sch, atk, defn, heal): return
		n.col = _color("main", colors)
		n.core = _color("core", colors)
		n.dark_col = _color("dark", colors).lightened(0.25)
		n.until_ms = int(b.get("until", 0))
		n.delay = 2.0   # sau khi hiệu ứng mở màn tan
		n.lowq = Settings.quality_low
		n.z_index = -1 if layer == 0 else 2
		n.position = Vector2(0, 0)
		n.material = _additive()
		target.add_child(n)
		pair.append(n)
	_orbits[id] = pair

func _end_orbit(id: String) -> void:
	var pair: Array = _orbits.get(id, [])
	_orbits.erase(id)
	for n in pair:
		if is_instance_valid(n): (n as Node2D).set("until_ms", Time.get_ticks_msec() + 350)   # mờ dần rồi tự xoá

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
