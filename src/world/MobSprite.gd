extends Node2D
## Quái do server quản lý. Vẽ theo sprite sheet trong assets/mobs/<sheet>/<anim>.png.
## Vị trí nhận từ server (target) và được nội suy mượt. Thanh máu chỉ hiện sau khi bị đánh.
## Mã trạng thái st: 0 đi, 1 gồng (windup), 2 lao tới (lunge) — xem server/realtime/mobs.js.

const T := preload("res://src/ui/UITheme.gd")
const MOB_DIR := "res://assets/mobs"

# look -> sheet (khớp public/js/art/sprites.js LOOK)
const LOOK := {
	"mushroom":"mushroom", "wolf":"goblin", "frog":"ff_slime", "bat":"bat",
	"spider":"ff_skeleton", "shade":"eye", "dummy":"dummy", "troll":"troll",
	"hydra":"hydra", "dragon":"dragon", "reaper":"reaper_boss",
	"werewolf":"werewolf", "nightborne":"nightborne", "beast":"beast",
}
# Thông số cắt frame (fw,fh,cx,fy,s) cho các sheet hay dùng
const SHEETS := {
	"eye":       {"fw":128,"fh":86, "cx":66, "fy":86, "s":0.6},
	"goblin":    {"fw":180,"fh":96, "cx":88, "fy":94, "s":0.65},
	"mushroom":  {"fw":164,"fh":94, "cx":82, "fy":92, "s":0.55},
	"bat":       {"fw":87, "fh":57, "cx":48, "fy":57, "s":0.95},
	"ff_slime":  {"fw":96, "fh":80, "cx":48, "fy":78, "s":0.7},
	"ff_skeleton":{"fw":96,"fh":96, "cx":48, "fy":94, "s":0.7},
	"dummy":     {"fw":79, "fh":96, "cx":46, "fy":95, "s":0.5},
	"troll":     {"fw":251,"fh":199,"cx":91, "fy":195,"s":0.5},
	"hydra":     {"fw":220,"fh":111,"cx":84, "fy":98, "s":0.68},
	"dragon":    {"fw":454,"fh":249,"cx":207,"fy":229,"s":0.5},
	"reaper_boss":{"fw":160,"fh":146,"cx":74, "fy":114,"s":0.85},
	"werewolf":  {"fw":252,"fh":157,"cx":120,"fy":150,"s":0.63},
	"nightborne":{"fw":160,"fh":146,"cx":74, "fy":114,"s":0.85},
	"beast":     {"fw":252,"fh":197,"cx":113,"fy":190,"s":0.47},
}
const ANIMS := {"idle":[4,8], "run":[8,12], "attack":[8,16], "hit":[4,14], "death":[4,8]}

var uid: int = 0
var mob_id: String = ""
var mob_name: String = ""
var sheet: String = "eye"
var hp: int = 0
var max_hp: int = 0
var alive: bool = true
var state: int = 0          # st từ server
var atk: int = 0
var is_boss := false
var passive := false
var lunge_hit := false      # đã gây sát thương trong lần lao này chưa
var target := Vector2.ZERO
var _has_target := false
var _sprites: Dictionary = {}
var _anim: AnimatedSprite2D = null
var _bar: Control = null
var _bar_fill: ColorRect = null
var _name: Label = null
var _tint: Color = Color.WHITE
var _bar_until := 0
var _flash_until := 0
var _hit_until := 0
var _height := 44.0

func setup(u: int, id: String, look: String, sprite_override: String = "") -> void:
	uid = u
	mob_id = id
	var def: Dictionary = Data.monster(id)
	mob_name = str(def.get("name", id))
	atk = int(def.get("atk", 0))
	is_boss = bool(def.get("boss", false)) or bool(def.get("leader", false))
	passive = bool(def.get("passive", false))
	sheet = sprite_override if (sprite_override != "" and SHEETS.has(sprite_override)) else LOOK.get(look, "eye")
	if not SHEETS.has(sheet): sheet = "eye"
	if look == "shade": _tint = Color(1.0, 0.44, 0.5)
	_build()

func _build() -> void:
	var def: Dictionary = SHEETS[sheet]
	_height = float(def["fy"]) * float(def["s"]) + 6.0
	for anim in ANIMS.keys():
		var path := "%s/%s/%s.png" % [MOB_DIR, sheet, anim]
		if not ResourceLoader.exists(path): continue
		var tex := load(path) as Texture2D
		if tex == null: continue
		var sf := SpriteFrames.new()
		if sf.has_animation("default"): sf.remove_animation("default")
		var info: Array = ANIMS[anim]
		var n := int(info[0])
		sf.add_animation(anim)
		sf.set_animation_speed(anim, float(info[1]))
		sf.set_animation_loop(anim, anim != "death")
		var fw := int(def["fw"]); var fh := int(def["fh"])
		for i in range(n):
			var at := AtlasTexture.new()
			at.atlas = tex
			at.region = Rect2(i * fw, 0, fw, fh)
			sf.add_frame(anim, at)
		_sprites[anim] = sf
	if _sprites.is_empty():
		var cr := ColorRect.new()
		cr.color = Color(0.8, 0.3, 0.35)
		cr.size = Vector2(24, 28)
		cr.position = Vector2(-12, -28)
		add_child(cr)
	else:
		_anim = AnimatedSprite2D.new()
		_anim.sprite_frames = _sprites["idle"]
		_anim.modulate = _tint
		_anim.scale = Vector2.ONE * float(def["s"])
		_anim.offset = Vector2(-float(def["cx"]) * float(def["s"]), -float(def["fy"]) * float(def["s"]))
		add_child(_anim)
		_anim.play("idle")
	# Thanh máu (chỉ hiện sau khi bị đánh; trùm luôn hiện)
	var w := 56.0 if is_boss else 34.0
	_bar = Control.new()
	_bar.position = Vector2(-w * 0.5, -_height - 8.0)
	_bar.visible = is_boss
	add_child(_bar)
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.65)
	bg.size = Vector2(w, 6)
	_bar.add_child(bg)
	_bar_fill = ColorRect.new()
	_bar_fill.color = Color(0.92, 0.27, 0.32)
	_bar_fill.position = Vector2(1, 1)
	_bar_fill.size = Vector2(w - 2.0, 4)
	_bar.add_child(_bar_fill)
	# Tên (chỉ hiện khi người chơi ở gần; World bật/tắt)
	_name = T.hud_label(mob_name, 12, Color(1.0, 0.86, 0.5) if is_boss else Color(0.95, 0.95, 1.0), true)
	_name.position = Vector2(-60, -_height - 28.0)
	_name.custom_minimum_size = Vector2(120, 0)
	_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name.visible = is_boss
	add_child(_name)

func _process(delta: float) -> void:
	if _has_target and alive:
		var k := 1.0 - exp(-14.0 * delta)
		var moving := position.distance_to(target) > 3.0
		position = position.lerp(target, k)
		if state == 0 and _hit_until < Time.get_ticks_msec():
			play("run" if moving and _sprites.has("run") else "idle")
	var now := Time.get_ticks_msec()
	if _bar and not is_boss:
		_bar.visible = alive and now < _bar_until
	if _anim:
		if now < _flash_until: _anim.modulate = Color(2.2, 2.2, 2.2)
		elif state == 1 and (now / 70) % 2 == 0: _anim.modulate = Color(1.6, 0.5, 0.5)
		else: _anim.modulate = _tint

func set_target(p: Vector2, snap: bool = false) -> void:
	target = p
	if snap or not _has_target:
		position = p
	_has_target = true

func set_state(st: int) -> void:
	if st == state: return
	state = st
	if st == 2: lunge_hit = false
	if alive and _anim:
		if st == 1 or st == 2: play("attack")
		else: play("idle")

func play(anim: String) -> void:
	if _anim == null: return
	if not _sprites.has(anim): anim = "idle"
	if _anim.animation != anim:
		_anim.sprite_frames = _sprites[anim]
		_anim.play(anim)

func set_facing(f: int) -> void:
	if _anim: _anim.flip_h = f < 0

func set_hp(h: int, mh: int) -> void:
	hp = h; max_hp = mh
	if _bar_fill:
		var w := (56.0 if is_boss else 34.0) - 2.0
		var ratio := float(h) / float(maxi(1, mh))
		_bar_fill.size.x = w * clampf(ratio, 0.0, 1.0)

func hit_flash() -> void:
	_flash_until = Time.get_ticks_msec() + 90
	_bar_until = Time.get_ticks_msec() + 4000
	if state == 0 and _sprites.has("hit"):
		_hit_until = Time.get_ticks_msec() + 220
		play("hit")

func show_name(on: bool) -> void:
	if _name and not is_boss: _name.visible = on

## Hộp va chạm xấp xỉ (toạ độ thế giới) để kiểm đòn lao.
func body_rect() -> Rect2:
	var w := 40.0 if not is_boss else 90.0
	var h := minf(_height, 60.0) if not is_boss else 110.0
	return Rect2(position.x - w * 0.5, position.y - h, w, h)

func revive() -> void:
	alive = true
	if _bar: _bar.visible = is_boss
	if _name: _name.visible = is_boss
	modulate.a = 1.0
	state = 0
	play("idle")

func die() -> void:
	if not alive: return
	alive = false
	play("death")
	if _bar: _bar.visible = false
	if _name: _name.visible = false
	var tw := create_tween()
	tw.tween_interval(1.0)
	tw.tween_property(self, "modulate:a", 0.0, 0.5)
