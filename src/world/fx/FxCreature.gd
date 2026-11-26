extends RefCounted
## Con vật / hình người trong kỹ năng: dùng lại sprite hoạt hình có sẵn của game (assets/pets, assets/mobs), tô lại theo màu
## kỹ năng bằng shader (có viền sáng + quầng ngoài). Hai kiểu: spawn() = hiện một lần khi tung chiêu (lao, trồi lên, hiện ra...),
## attach() = đi theo người suốt thời gian hiệu lực của buff/hộ thể.
## Phần hiệu ứng (nứt đất, trận, bụi...) vẫn do sig vẽ bằng code; sig bỏ phần con vật vẽ tay khi s.nocreature = true.
const FxProj := preload("res://src/world/fx/FxProj.gd")

## Thư viện sprite. path = đường dẫn dưới res://assets/ (mặc định pets/<file>.png); fw/fh/n = khung/số khung; fy = y của chân trong khung
## (để đặt chân chạm đất); flip = hình gốc quay trái.
const LIB := {
	"dragon": {"file": "dragon-run", "fw": 454, "fh": 249, "n": 8, "row": 0, "rate": 14.0, "fy": 240},
	"dragon_atk": {"file": "dragon-attack", "fw": 454, "fh": 249, "n": 8, "row": 0, "rate": 14.0, "fy": 240},
	"wolf": {"file": "wolf-run", "fw": 174, "fh": 98, "n": 3, "row": 0, "rate": 9.0, "flip": true, "fy": 96},
	"wolf_atk": {"file": "wolf-attack", "fw": 174, "fh": 98, "n": 5, "row": 0, "rate": 10.0, "flip": true, "fy": 96},
	"wolfw": {"file": "wolf-walk", "fw": 174, "fh": 98, "n": 4, "row": 0, "rate": 8.0, "flip": true, "fy": 96},
	"beast": {"path": "mobs/beast/run.png", "fw": 252, "fh": 197, "n": 10, "row": 0, "rate": 14.0, "fy": 190},
	"skel": {"path": "mobs/skeleton_knight/run.png", "fw": 361, "fh": 364, "n": 10, "row": 0, "rate": 9.0, "fy": 355},
	"knight": {"path": "mobs/knight_silver/idle.png", "fw": 218, "fh": 102, "n": 10, "row": 0, "rate": 8.0, "fy": 100},
	"cultist": {"path": "mobs/cultist/idle.png", "fw": 156, "fh": 178, "n": 5, "row": 0, "rate": 8.0, "fy": 177},
}

## Hiện một lần khi tung chiêu. path: dash = bay thẳng dist px; rise = trồi từ đất rồi chìm; spawn = hiện trong trận rồi tan;
## charge = chạy húc thẳng dist px sát đất; shadows = nhiều bóng trồi lên ở các vị trí xs rồi tan.
const DEFS := {
	"ks35": {"lib": "dragon", "path": "dash", "dist": 220.0, "y": -14.0, "scale": 0.34, "dur": 0.9, "ghosts": 0, "dark": 0.2, "lum": 0.14, "mix": 0.7},
	"hv42": {"lib": "dragon_atk", "path": "rise", "x": 70.0, "scale": 0.6, "dur": 1.5, "ghosts": 0, "dark": 0.3, "lum": 0.12, "mix": 0.6},
	"th5": {"lib": "wolf_atk", "path": "spawn", "x": 70.0, "scale": 0.95, "dur": 1.6, "ghosts": 0, "dark": 0.25, "lum": 0.4, "mix": 0.7},
	"tk8": {"lib": "beast", "path": "charge", "dist": 190.0, "scale": 0.5, "dur": 0.85, "dark": 0.25, "lum": 0.22, "mix": 0.55},
	"nl2": {"lib": "cultist", "path": "shadows", "xs": [-40.0, -100.0, -160.0], "scale": 0.42, "dur": 1.5, "dark": 0.12, "lum": 0.3, "mix": 0.85},
}

## Đi theo người suốt thời gian hiệu lực của buff/hộ thể (gắn làm con của node nhân vật; chân chạm đất ở y=28).
const AURA_DEFS := {
	"nl4": {"lib": "skel", "xs": [-50.0, -100.0, -150.0], "scale": 0.3, "dark": 0.14, "lum": 0.3, "mix": 0.8},
	"th2": {"lib": "knight", "xs": [48.0], "scale": 0.9, "dark": 0.2, "lum": 0.35, "mix": 0.7},
	"th4": {"lib": "wolfw", "xs": [-48.0], "scale": 0.78, "dark": 0.25, "lum": 0.4, "mix": 0.7},
	"th9": {"lib": "wolfw", "xs": [48.0], "scale": 0.78, "dark": 0.25, "lum": 0.4, "mix": 0.7},
}

static func has(id: String) -> bool:
	return DEFS.has(id)

static func has_aura(id: String) -> bool:
	return AURA_DEFS.has(id)

static func _tex(lib: Dictionary) -> Texture2D:
	var pth := str(lib.get("path", "pets/" + str(lib.get("file", "")) + ".png"))
	return load("res://assets/" + pth) as Texture2D

static func _mat(col: Color, core: Color, d: Dictionary) -> ShaderMaterial:
	var sm := ShaderMaterial.new()
	var dk := float(d.get("dark", 0.2))
	sm.shader = FxProj.sprite_shader()
	sm.set_shader_parameter("tint_dark", Color(col.r * dk, col.g * dk, col.b * dk, 1.0))
	sm.set_shader_parameter("tint_light", col.lerp(core, 0.4))
	sm.set_shader_parameter("rim_color", core.lerp(Color.WHITE, 0.35))
	sm.set_shader_parameter("lum_scale", float(d.get("lum", 0.3)))
	sm.set_shader_parameter("mix_amt", float(d.get("mix", 0.8)))
	sm.set_shader_parameter("rim_amt", 0.9)
	sm.set_shader_parameter("glow_amt", 0.5)
	return sm

static func _mk_sprite(tex: Texture2D, lib: Dictionary, mat: ShaderMaterial, sc: float) -> Sprite2D:
	var sp := Sprite2D.new()
	sp.texture = tex
	sp.region_enabled = true
	sp.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	sp.scale = Vector2.ONE * sc
	sp.flip_h = bool(lib.get("flip", false))
	sp.material = mat
	sp.modulate = Color(1, 1, 1, 0.0)
	return sp

## Vị trí tâm sprite để chân chạm mặt đất gy (y của mặt đất trong hệ toạ độ của root).
static func _ground_y(lib: Dictionary, sc: float, gy: float) -> float:
	return gy - (float(lib.get("fy", lib["fh"])) - float(lib["fh"]) * 0.5) * sc

## Dựng một lần tại origin (toạ độ thế giới), hướng facing. parent = node SkillFx.
static func spawn(parent: Node2D, id: String, origin: Vector2, facing: int, col: Color, core: Color) -> void:
	var d: Dictionary = DEFS.get(id, {})
	if d.is_empty(): return
	var lib: Dictionary = LIB[str(d["lib"])]
	var tex := _tex(lib)
	if tex == null: return
	var root := Node2D.new()
	root.position = origin
	root.scale.x = float(facing) if facing != 0 else 1.0
	root.z_index = 10
	parent.add_child(root)
	var mat := _mat(col, core, d)
	var sc := float(d.get("scale", 0.5))
	var fw := int(lib["fw"])
	var fh := int(lib["fh"])
	var n := int(lib["n"])
	var path := str(d.get("path", "dash"))
	var xs: Array = d.get("xs", [0.0])
	var cnt := (xs.size() if path == "shadows" else 1 + int(d.get("ghosts", 0)))
	var sprs: Array = []
	for i in range(cnt):
		var sp := _mk_sprite(tex, lib, mat, sc)
		sp.z_index = cnt - i
		root.add_child(sp)
		sprs.append(sp)
	var dur := float(d.get("dur", 1.0))
	var half_h := float(fh) * sc * 0.5
	var gcy := _ground_y(lib, sc, 32.0)
	var step := func(u: float) -> void:
		var fi := int(u * dur * float(lib["rate"])) % n
		var pos := Vector2.ZERO
		var a := 1.0
		var scm := 1.0
		match path:
			"dash":
				var p := clampf(u / 0.6, 0.0, 1.0)
				var e := 1.0 - pow(1.0 - p, 3.0)
				pos = Vector2(-30.0 + (float(d["dist"]) + 30.0) * e, float(d.get("y", -14.0)) + sin(u * 25.0) * 3.0)
				a = clampf(u / 0.12, 0.0, 1.0) * (1.0 - clampf((u - 0.72) / 0.28, 0.0, 1.0))
			"charge":
				var pc := clampf(u / 0.55, 0.0, 1.0)
				var ec := pc * pc * (3.0 - 2.0 * pc)
				pos = Vector2(-30.0 + (float(d["dist"]) + 30.0) * ec, gcy - 4.0 * absf(sin(u * 30.0)))
				a = clampf(u / 0.1, 0.0, 1.0) * (1.0 - clampf((u - 0.7) / 0.3, 0.0, 1.0))
			"rise":
				var up := clampf(u / 0.38, 0.0, 1.0)
				var down := clampf((u - 0.74) / 0.26, 0.0, 1.0)
				var eo := 1.0 - pow(1.0 - up, 3.0)
				pos = Vector2(float(d["x"]), 32.0 - half_h * 0.9 + 70.0 * (1.0 - eo) + 60.0 * down * down)
				a = clampf(u / 0.2, 0.0, 1.0) * (1.0 - clampf((u - 0.8) / 0.2, 0.0, 1.0))
				scm = 1.0 + 0.07 * sin(clampf((u - 0.38) / 0.3, 0.0, 1.0) * PI)
			"spawn":
				var up2 := clampf((u - 0.18) / 0.3, 0.0, 1.0)
				var eo2 := 1.0 - pow(1.0 - up2, 3.0)
				pos = Vector2(float(d["x"]), 32.0 - half_h * 0.95 + 18.0 * (1.0 - eo2))
				a = clampf((u - 0.18) / 0.2, 0.0, 1.0) * (1.0 - clampf((u - 0.8) / 0.2, 0.0, 1.0))
		for i in range(sprs.size()):
			var sp := sprs[i] as Sprite2D
			if not is_instance_valid(sp): continue
			if path == "shadows":
				var st := 0.08 + 0.1 * float(i)
				var up3 := clampf((u - st) / 0.3, 0.0, 1.0)
				var eo3 := 1.0 - pow(1.0 - up3, 3.0)
				var dis := clampf((u - 0.66 - 0.04 * float(i)) / 0.3, 0.0, 1.0)
				sp.position = Vector2(float(xs[i]), gcy + 36.0 * (1.0 - eo3) - 14.0 * dis)
				sp.modulate.a = up3 * (1.0 - dis) * 0.95
				sp.region_rect = Rect2(((fi + i * 2) % n) * fw, int(lib.get("row", 0)) * fh, fw, fh)
				continue
			var gi := (fi + n - i) % n
			sp.region_rect = Rect2(gi * fw, int(lib.get("row", 0)) * fh, fw, fh)
			sp.position = pos - Vector2(float(d.get("gap", 44.0)) * float(i), 0.0)
			sp.scale = Vector2.ONE * sc * scm
			sp.modulate.a = a * (1.0 if i == 0 else 0.32 / float(i))
	var tw := root.create_tween()
	tw.tween_method(step, 0.0, 1.0, dur)
	tw.tween_callback(root.queue_free)

## Gắn con vật/hình người theo người suốt thời gian hiệu lực; trả về node gốc (gắn làm con của target, SkillFx sẽ làm mờ và xoá khi hết buff).
static func attach(target: Node2D, id: String, facing: int, col: Color, core: Color) -> Node2D:
	var d: Dictionary = AURA_DEFS.get(id, {})
	if d.is_empty() or target == null: return null
	var lib: Dictionary = LIB[str(d["lib"])]
	var tex := _tex(lib)
	if tex == null: return null
	var root := Node2D.new()
	root.scale.x = float(facing) if facing != 0 else 1.0
	root.z_index = 1
	root.modulate = Color(1, 1, 1, 0.0)
	target.add_child(root)
	var mat := _mat(col, core, d)
	var sc := float(d.get("scale", 0.5))
	var fw := int(lib["fw"])
	var fh := int(lib["fh"])
	var n := int(lib["n"])
	var xs: Array = d.get("xs", [0.0])
	var gcy := _ground_y(lib, sc, 28.0)
	var sprs: Array = []
	for i in range(xs.size()):
		var sp := _mk_sprite(tex, lib, mat, sc)
		sp.modulate.a = 0.92
		sp.position = Vector2(float(xs[i]), gcy)
		root.add_child(sp)
		sprs.append(sp)
	var step := func(_u: float) -> void:
		var tm := float(Time.get_ticks_msec()) / 1000.0
		for i in range(sprs.size()):
			var sp := sprs[i] as Sprite2D
			if not is_instance_valid(sp): continue
			sp.region_rect = Rect2(((int(tm * float(lib["rate"])) + i * 3) % n) * fw, int(lib.get("row", 0)) * fh, fw, fh)
			sp.position.y = gcy - 2.0 * (0.5 + 0.5 * sin(tm * 3.0 + float(i) * 1.7))
	var tw := root.create_tween().set_loops()
	tw.tween_method(step, 0.0, 1.0, 0.1)
	var tin := root.create_tween()
	tin.tween_property(root, "modulate:a", 1.0, 0.4)
	return root
