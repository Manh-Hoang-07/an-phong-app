extends Node2D
## Quái do server quản lý. Vẽ theo sprite sheet trong assets/mobs/<sheet>/<anim>.png.
## Vị trí nhận từ server (target) và được nội suy mượt. Thanh máu chỉ hiện sau khi bị đánh.
## Mã trạng thái st: 0 đi, 1 gồng (windup), 2 lao tới (lunge) — xem server/realtime/mobs.js.

const T := preload("res://src/ui/UITheme.gd")
const MOB_DIR := "res://assets/mobs"

var mob_def: Dictionary = {}     # MOBS[sheet] của web (fw, fh, cx, fy, s, anims, faceLeft, fakeDeath, fly...)
var grade: Dictionary = {}
var face_left := false
var fake_death := false
var fly := false
var _scale := 1.0

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
	var gkey := "boss" if (bool(def.get("boss", false)) or bool(def.get("finalBoss", false))) else ("leader" if bool(def.get("leader", false)) else ("elite" if bool(def.get("elite", false)) else "normal"))
	grade = (Data.mob_art.get("MON_GRADE", {}) as Dictionary).get(gkey, {"scale": 1.0, "tint": null, "nameColor": "#ffcdd2", "barW": 36})
	is_boss = gkey == "boss" or gkey == "leader"
	passive = bool(def.get("passive", false))
	var mobs: Dictionary = Data.mob_art.get("MOBS", {})
	var own := sprite_override != "" and mobs.has(sprite_override)
	# Giống Sprites.sheetOf của web: def.sprite (hình riêng) → không có thì mượn theo kiểu dáng def.look
	sheet = sprite_override if own else str((Data.mob_art.get("LOOK", {}) as Dictionary).get(look, "eye"))
	if not mobs.has(sheet): sheet = "eye"
	mob_def = mobs[sheet]
	face_left = bool(mob_def.get("faceLeft", false))
	fake_death = bool(mob_def.get("fakeDeath", false))
	fly = bool(def.get("fly", false)) or bool(mob_def.get("fly", false))
	# Màu: def.tint → màu hạng → màu theo kiểu dáng (chỉ khi còn mượn hình chung) — như tintOf của web
	var tint_v: Variant = def.get("tint", null)
	if tint_v == null: tint_v = grade.get("tint", null)
	if tint_v == null and not own: tint_v = (Data.mob_art.get("LOOK_TINT", {}) as Dictionary).get(look, null)
	if tint_v != null: _tint = Color.hex((int(tint_v) << 8) | 0xff)
	mob_level = int(def.get("level", 1))
	def_stat = int(def.get("def", 0))
	mob_style = str(def.get("style", ""))
	resist = float(def.get("resist", 0.0))
	_build()

var mob_level := 1
var def_stat := 0            # phòng thủ của quái (trừ vào sát thương người chơi gây ra)
var mob_style := ""          # kiểu đòn đặc biệt của trùm (water/ice/void/...)
var resist := 0.0            # kháng đòn đánh thường (def.resist)
var flags := 0               # cờ từ server: 1 chậm, 2 đóng băng, 4 phẫn nộ
var enraged := false         # cờ phẫn nộ từ server (fl & 4): đòn đánh nặng hơn 25%

func _build() -> void:
	var def: Dictionary = mob_def
	_scale = float(def.get("s", 1.0)) * float(grade.get("scale", 1.0))
	var fy := float(def.get("cy", def.get("fy", 0.0))) if fly else float(def.get("fy", 0.0))
	_height = fy * _scale + 6.0
	var anims: Dictionary = def.get("anims", {})
	for anim in anims.keys():
		var path := "%s/%s/%s.png" % [MOB_DIR, sheet, anim]
		if not ResourceLoader.exists(path): continue
		var tex := load(path) as Texture2D
		if tex == null: continue
		var sf := SpriteFrames.new()
		if sf.has_animation("default"): sf.remove_animation("default")
		var info: Array = anims[anim]
		var n := int(info[0])
		sf.add_animation(anim)
		sf.set_animation_speed(anim, float(info[1]))
		sf.set_animation_loop(anim, anim == "idle" or anim == "run")
		var fw := int(def["fw"]); var fh := int(def["fh"])
		for i in range(n):
			var at := AtlasTexture.new()
			at.atlas = tex
			at.region = Rect2(i * fw, 0, fw, fh)
			sf.add_frame(anim, at)
		_sprites[anim] = sf
	if _sprites.is_empty() or not _sprites.has("idle"):
		var cr := ColorRect.new()
		cr.color = Color(0.8, 0.3, 0.35)
		cr.size = Vector2(24, 28)
		cr.position = Vector2(-12, -28)
		add_child(cr)
	else:
		_anim = AnimatedSprite2D.new()
		_anim.sprite_frames = _sprites["idle"]
		_anim.modulate = _tint
		_anim.scale = Vector2.ONE * _scale
		_anim.centered = false
		# Gốc tọa độ như Sprites.fitMob: quái đi bộ neo ở chân (fy), quái bay neo ở tâm (cy)
		_anim.offset = Vector2(-float(def["cx"]), -fy)
		_anim.flip_h = face_left
		add_child(_anim)
		_anim.play("idle")
	# Thanh máu (chỉ hiện sau khi bị đánh; trùm luôn hiện), bề rộng theo hạng
	var w := float(grade.get("barW", 36))
	_bar = Control.new()
	_bar.position = Vector2(-w * 0.5, -_height - 8.0)
	_bar.visible = is_boss
	add_child(_bar)
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.65)
	bg.size = Vector2(w, 6)
	_bar.add_child(bg)
	_bar_fill = ColorRect.new()
	_bar_fill.color = Color.hex((int(grade.get("bar", 0xe53935)) << 8) | 0xff) if grade.has("bar") else Color(0.92, 0.27, 0.32)
	_bar_fill.position = Vector2(1, 1)
	_bar_fill.size = Vector2(w - 2.0, 4)
	_bar.add_child(_bar_fill)
	# Tên + cấp (chỉ hiện khi người chơi ở gần; World bật/tắt)
	_name = T.hud_label("%s Lv%d" % [mob_name, mob_level], 12, Color(str(grade.get("nameColor", "#ffcdd2"))), true)
	_name.position = Vector2(-70, -_height - 28.0)
	_name.custom_minimum_size = Vector2(140, 0)
	_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name.visible = is_boss   # quái thường chỉ hiện tên khi là mục tiêu (World bật qua show_name); trùm luôn hiện
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
	# Hình gốc quay trái (faceLeft) thì đảo chiều lật — như fitMob của web
	if _anim: _anim.flip_h = (f < 0) != face_left

func set_hp(h: int, mh: int) -> void:
	hp = h; max_hp = mh
	if _bar_fill:
		var w := float(grade.get("barW", 36)) - 2.0
		var ratio := float(h) / float(maxi(1, mh))
		_bar_fill.size.x = w * clampf(ratio, 0.0, 1.0)

func hit_flash() -> void:
	_flash_until = Time.get_ticks_msec() + 90
	_bar_until = Time.get_ticks_msec() + 4000
	if state == 0 and _sprites.has("hit"):
		_hit_until = Time.get_ticks_msec() + 220
		play("hit")

## Bật/tắt tên + cấp trên đầu quái. Quái thường chỉ hiện khi là mục tiêu; trùm luôn hiện.
func show_name(on: bool) -> void:
	if _name: _name.visible = alive and (on or is_boss)

## Hộp va chạm xấp xỉ (toạ độ thế giới) để kiểm đòn lao.
func body_rect() -> Rect2:
	var w := 40.0 if not is_boss else 90.0
	var h := minf(_height, 60.0) if not is_boss else 110.0
	if fly: return Rect2(position.x - w * 0.5, position.y - h * 0.5, w, h)
	return Rect2(position.x - w * 0.5, position.y - h, w, h)

func revive() -> void:
	alive = true
	if _bar: _bar.visible = is_boss
	if _name: _name.visible = is_boss
	modulate.a = 1.0
	if _anim: _anim.rotation = 0.0
	state = 0
	play("idle")

func die() -> void:
	if not alive: return
	alive = false
	play("death")
	if fake_death and _anim:
		# Bộ hình không có hoạt ảnh chết thật: cho ngã xuống như web
		var side := -1.0 if (_anim.flip_h != face_left) else 1.0
		create_tween().tween_property(_anim, "rotation", side * 1.45, 0.35).set_trans(Tween.TRANS_QUAD)
	if _bar: _bar.visible = false
	if _name: _name.visible = false
	var tw := create_tween()
	tw.tween_interval(1.0)
	tw.tween_property(self, "modulate:a", 0.0, 0.5)
