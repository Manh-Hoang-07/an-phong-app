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
static var _frames_cache: Dictionary = {}   # "sheet|pet_look" -> {anim: SpriteFrames}
var _anim: AnimatedSprite2D = null
var _bar: Control = null
var _bar_fill: ColorRect = null
var _name: Label = null
var _tint: Color = Color.WHITE
var _bar_until := 0
var _flash_until := 0
var _hit_until := 0
var _height := 44.0

## Hình thú đồng hành / linh thú: sprite sheet riêng trong assets/pets (cùng bộ ảnh với web, public/js/art/pets.js),
## KHÔNG mượn sprite quái. fw/fh: khung; frames: số khung; left: hình gốc quay trái; lift: bay cao hơn mặt đất (px).
const PET_DIR := "res://assets/pets/"
const PET_DEF := {
	"wolf": {"fw": 174, "fh": 98, "frames": {"run": 3, "walk": 4, "attack": 5}, "left": true, "scale": 0.75, "files": {"run": "wolf-run", "walk": "wolf-walk", "attack": "wolf-attack"}},
	"horse": {"fw": 82, "fh": 66, "frames": {"run": 7, "walk": 7}, "scale": 0.82, "files": {"run": "horse-walk", "walk": "horse-walk"}},
	"dragon": {"fw": 454, "fh": 249, "frames": {"run": 8, "walk": 8, "attack": 8}, "scale": 0.3, "lift": -6, "rate": {"walk": 10, "run": 14, "attack": 14}, "files": {"run": "dragon-run", "walk": "dragon-run", "attack": "dragon-attack"}},
	"bat": {"fw": 150, "fh": 147, "frames": {"run": 4, "walk": 4, "attack": 3}, "left": true, "scale": 0.6, "lift": 30, "rate": {"walk": 8, "run": 12, "attack": 10}, "files": {"run": "bat-run", "walk": "bat-run", "attack": "bat-attack"}},
	"bird": {"fw": 48, "fh": 32, "frames": {"walk": 11, "run": 11, "attack": 11}, "rows": {"walk": 2, "run": 4, "attack": 3}, "scale": 1.6, "files": {"walk": "bird", "run": "bird", "attack": "bird"}},
	"lizard": {"fw": 209, "fh": 118, "frames": {"run": 8, "walk": 8, "attack": 8}, "scale": 0.55, "files": {"run": "lizard-run", "walk": "lizard-walk", "attack": "lizard-attack"}},
	"fox": {"fw": 177, "fh": 128, "frames": {"walk": 10, "run": 12, "attack": 10}, "scale": 0.55, "rate": {"walk": 10, "run": 16, "attack": 14}, "files": {"run": "fox-run", "walk": "fox-walk", "attack": "fox-attack"}},
	"insect": {"fw": 136, "fh": 117, "frames": {"walk": 10, "run": 10, "attack": 12}, "scale": 0.5, "lift": 20, "rate": {"walk": 14, "run": 18, "attack": 16}, "files": {"run": "insect-run", "walk": "insect-walk", "attack": "insect-attack"}},
}
var pet_look := ""
var _pet_files: Dictionary = {}   # anim (idle/run/attack) -> đường dẫn ảnh
var _pet_rows: Dictionary = {}    # anim -> hàng trong sheet (chỉ bird)

func _use_pet(look: String) -> void:
	var d: Dictionary = PET_DEF[look]
	var frames: Dictionary = d["frames"]
	var files: Dictionary = d["files"]
	var rate: Dictionary = d.get("rate", {})
	var sc := float(d.get("scale", 1.0))
	var anims := {}
	for pair in [["idle", "walk"], ["run", "run"], ["attack", "attack"]]:
		var a := str(pair[0])
		var src := str(pair[1])
		if not frames.has(src): src = "walk" if frames.has("walk") else "run"
		anims[a] = [int(frames[src]), float(rate.get(src, 12.0 if src == "run" else 7.0))]
		_pet_files[a] = PET_DIR + str(files[src]) + ".png"
		if d.has("rows"): _pet_rows[a] = int((d["rows"] as Dictionary)[src])
	if not frames.has("attack"): anims.erase("attack")
	pet_look = look
	mob_def = {"fw": d["fw"], "fh": d["fh"], "cx": float(d["fw"]) * 0.5, "fy": float(d["fh"]) + float(d.get("lift", 0.0)) / sc, "s": sc, "anims": anims}
	face_left = bool(d.get("left", false))
	fake_death = false
	fly = false
	grade = {"scale": 1.0, "tint": null, "nameColor": "#ffe9a8", "barW": 36}
	_tint = Color.WHITE

func setup(u: int, id: String, look: String, sprite_override: String = "", as_pet: bool = false) -> void:
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
	if as_pet and PET_DEF.has(look): _use_pet(look)
	_build()

var mob_level := 1
var def_stat := 0            # phòng thủ của quái (trừ vào sát thương người chơi gây ra)
var mob_style := ""          # kiểu đòn đặc biệt của trùm (water/ice/void/...)
var resist := 0.0            # kháng đòn đánh thường (def.resist)
var shred := 0.0             # % sát thương chịu thêm do Tên Phá Giáp
var shred_until := 0
var flags := 0               # cờ từ server: 1 chậm, 2 đóng băng, 4 phẫn nộ
var enraged := false         # cờ phẫn nộ từ server (fl & 4): đòn đánh nặng hơn 25%

func _build() -> void:
	var def: Dictionary = mob_def
	_scale = float(def.get("s", 1.0)) * float(grade.get("scale", 1.0))
	var fy := float(def.get("cy", def.get("fy", 0.0))) if fly else float(def.get("fy", 0.0))
	_height = fy * _scale + 6.0
	# SpriteFrames chỉ đọc nên dùng chung cho mọi con cùng loại (trạng thái phát nằm ở AnimatedSprite2D).
	var ckey := "%s|%s" % [sheet, pet_look]
	if _frames_cache.has(ckey):
		_sprites = _frames_cache[ckey]
	else:
		var anims: Dictionary = def.get("anims", {})
		for anim in anims.keys():
			var path := str(_pet_files.get(anim, "")) if pet_look != "" else "%s/%s/%s.png" % [MOB_DIR, sheet, anim]
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
				at.region = Rect2(i * fw, int(_pet_rows.get(anim, 0)) * fh, fw, fh)
				sf.add_frame(anim, at)
			_sprites[anim] = sf
		_frames_cache[ckey] = _sprites
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
	# Thanh máu + tên dựng lười: quái thường chỉ cần khi bị đánh / được chọn (đỡ ~6 node mỗi con); trùm dựng ngay.
	if is_boss:
		_ensure_bar()
		_ensure_name()

func _ensure_bar() -> void:
	if _bar != null: return
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
	if max_hp > 0:
		_bar_fill.size.x = (w - 2.0) * clampf(float(hp) / float(maxi(1, max_hp)), 0.0, 1.0)

# Tên + cấp (chỉ hiện khi là mục tiêu; World bật/tắt)
func _ensure_name() -> void:
	if _name != null: return
	_name = T.hud_label("%s Lv%d" % [mob_name, mob_level], 12, Color(str(grade.get("nameColor", "#ffcdd2"))), true)
	_name.position = Vector2(-70, -_height - 28.0)
	_name.custom_minimum_size = Vector2(140, 0)
	_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name.visible = is_boss   # quái thường chỉ hiện tên khi là mục tiêu (World bật qua show_name); trùm luôn hiện
	add_child(_name)

var _off_screen := false
var _vis_check_at := 0

func _process(delta: float) -> void:
	var tick := Time.get_ticks_msec()
	if tick >= _vis_check_at:
		_vis_check_at = tick + 250
		var vp := get_viewport()
		if vp != null:
			var view: Rect2 = vp.get_canvas_transform().affine_inverse() * vp.get_visible_rect()
			_off_screen = not view.grow(240.0).has_point(position)
	if _off_screen:
		# Ngoài màn hình: nhảy thẳng tới đích, bỏ nội suy/đổi màu mỗi khung (tiết kiệm CPU khi map đông quái)
		if _has_target and alive: position = target
		return
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
	if alive: _ensure_bar()
	_flash_until = Time.get_ticks_msec() + 90
	_bar_until = Time.get_ticks_msec() + 4000
	if state == 0 and _sprites.has("hit"):
		_hit_until = Time.get_ticks_msec() + 220
		play("hit")

## Bật/tắt tên + cấp trên đầu quái. Quái thường chỉ hiện khi là mục tiêu; trùm luôn hiện.
func show_name(on: bool) -> void:
	if on and alive: _ensure_name()
	if _name: _name.visible = alive and (on or is_boss)

## Hộp va chạm xấp xỉ (toạ độ thế giới) để kiểm đòn lao.
func body_rect() -> Rect2:
	var w := 40.0 if not is_boss else 90.0
	var h := minf(_height, 60.0) if not is_boss else 110.0
	if fly: return Rect2(position.x - w * 0.5, position.y - h * 0.5, w, h)
	return Rect2(position.x - w * 0.5, position.y - h, w, h)

func revive() -> void:
	alive = true
	set_process(true)   # die() đã tắt: quái sống lại cần chạy lại nội suy
	if _bar: _bar.visible = is_boss
	if _name: _name.visible = is_boss
	modulate.a = 1.0
	if _anim: _anim.rotation = 0.0
	state = 0
	play("idle")

func die() -> void:
	if not alive: return
	alive = false
	set_process(false)   # chết rồi: không cần nội suy/đổi màu mỗi khung trong lúc tween tan
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
