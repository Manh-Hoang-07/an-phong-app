extends Node2D
## Đạn bay (mũi tên, quả cầu phép, đạn lửa). Chỉ vẽ; World.gd tự di chuyển và tính trúng.

const FxProj := preload("res://src/world/fx/FxProj.gd")

var color := Color(1.0, 0.7, 0.3)
var core := Color(1.0, 1.0, 1.0)
var sid := ""
var _spr: Sprite2D = null
var _spr_def: Dictionary = {}
var _ghosts: Array = []   # id kỹ năng: có hình đạn riêng trong FxProj thì vẽ theo đó
var _rng := RandomNumberGenerator.new()
var big := 1.0
var arrow := false
var _t := 0.0

func setup(c: Color, angle: float, facing: int, size: float = 1.0, is_arrow: bool = false) -> void:
	color = c
	big = size
	arrow = is_arrow
	rotation = angle * float(facing)
	scale = Vector2(float(facing), 1.0)
	z_index = 7

## Gắn hình đạn riêng của kỹ năng (màu theo chủ đề kỹ năng).
func setup_skill(id: String, col: Color, core_c: Color, dark: bool) -> void:
	sid = id
	color = col
	core = core_c
	# thú sprite có sẵn của game (rồng, chim...): Sprite2D con, hòa trộn thường, tô lại theo màu kỹ năng
	var sd := FxProj.sprite_def(id)
	if not sd.is_empty():
		_spr_def = sd
		_spr = Sprite2D.new()
		_spr.texture = load("res://assets/pets/" + str(sd["file"]) + ".png")
		_spr.region_enabled = true
		_spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_spr.scale = Vector2.ONE * float(sd["scale"])
		_spr.position = sd.get("off", Vector2.ZERO)
		_spr.z_index = 1
		var sm := ShaderMaterial.new()
		sm.shader = FxProj.sprite_shader()
		var dk := col_dark(color, float(sd.get("dark", 0.2)))
		sm.set_shader_parameter("tint_dark", dk)
		sm.set_shader_parameter("tint_light", color.lerp(core, 0.4))
		sm.set_shader_parameter("lum_scale", float(sd.get("lum", 0.3)))
		sm.set_shader_parameter("mix_amt", float(sd.get("mix", 0.85)))
		sm.set_shader_parameter("rim_color", core.lerp(Color.WHITE, 0.35))
		sm.set_shader_parameter("rim_amt", float(sd.get("rim", 0.8)))
		sm.set_shader_parameter("glow_amt", float(sd.get("glow", 0.5)))
		_spr.flip_h = bool(sd.get("flip", false))
		_spr.material = sm
		add_child(_spr)
		# bóng mờ phía sau (tàn ảnh tốc độ)
		for gi in range(int(sd.get("ghosts", 0))):
			var gs := Sprite2D.new()
			gs.texture = _spr.texture
			gs.region_enabled = true
			gs.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			gs.scale = _spr.scale
			gs.flip_h = _spr.flip_h
			gs.position = _spr.position - Vector2(46.0 * float(gi + 1), 0.0)
			gs.material = _spr.material
			gs.modulate = Color(1, 1, 1, 0.34 / float(gi + 1))
			gs.z_index = 0
			add_child(gs)
			_ghosts.append(gs)
		_update_sprite()
	if not dark:
		var m := CanvasItemMaterial.new()
		m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		material = m

# các hàm màu mà bộ nét FxExt gọi (giống _FxShape của SkillFx)
func _a(a: float) -> Color:
	return Color(color.r, color.g, color.b, a)

func _k(a: float) -> Color:
	return Color(core.r, core.g, core.b, a)

func _mix(u: float, a: float) -> Color:
	var c := color.lerp(core, u)
	return Color(c.r, c.g, c.b, a)

func col_dark(c: Color, k: float) -> Color:
	return Color(c.r * k, c.g * k, c.b * k, 1.0)

func _update_sprite() -> void:
	if _spr == null: return
	var fw := int(_spr_def["fw"])
	var fh := int(_spr_def["fh"])
	var i := int(_t * float(_spr_def["rate"])) % int(_spr_def["n"])
	_spr.region_rect = Rect2(i * fw, int(_spr_def["row"]) * fh, fw, fh)
	for gi in range(_ghosts.size()):
		var gj := (i + int(_spr_def["n"]) - (gi + 1)) % int(_spr_def["n"])
		(_ghosts[gi] as Sprite2D).region_rect = Rect2(gj * fw, int(_spr_def["row"]) * fh, fw, fh)

func _process(delta: float) -> void:
	_t += delta
	_update_sprite()
	queue_redraw()

func _draw() -> void:
	if sid != "":
		_rng.seed = hash(sid)
		if FxProj.draw(self, sid, _t): return
	if arrow:
		draw_line(Vector2(-16, 0) * big, Vector2(10, 0) * big, Color(0.85, 0.72, 0.5), 2.0 * big)
		draw_colored_polygon(PackedVector2Array([Vector2(14, 0) * big, Vector2(8, -4) * big, Vector2(8, 4) * big]), Color(0.9, 0.9, 0.95))
		draw_line(Vector2(-16, 0) * big, Vector2(-20, -4) * big, color, 2.0)
		draw_line(Vector2(-16, 0) * big, Vector2(-20, 4) * big, color, 2.0)
		return
	var pulse := 1.0 + 0.12 * sin(_t * 30.0)
	draw_circle(Vector2.ZERO, 11.0 * big * pulse, Color(color.r, color.g, color.b, 0.22))
	draw_circle(Vector2.ZERO, 7.0 * big * pulse, Color(color.r, color.g, color.b, 0.55))
	draw_circle(Vector2.ZERO, 3.5 * big, Color(1, 1, 1, 0.95))
	draw_line(Vector2(-4, 0), Vector2(-26, 0) * big, Color(color.r, color.g, color.b, 0.4), 5.0 * big)
