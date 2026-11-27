extends Node2D
## Nhân vật / NPC dùng sprite sheet thật từ assets/chars/<school>/<anim>.png.
## Thông số fw/fh/cx/fy/s và bảng anim lấy từ public/js/art/sprites.js (CHARS).
## Mỗi anim là một PNG ngang gồm N khung; cắt bằng AtlasTexture, đánh đổi chiều ngang bằng flip_h.

const ASSET_DIR := "res://assets/chars"

# fw, fh: cỡ 1 khung; cx: tâm ngang; fy: chân; s: tỉ lệ; anims: tên -> [số khung, fps]
const CHARS := {
	"kiem_si":      {"fw": 238, "fh": 194, "cx": 73,  "fy": 189, "s": 0.45,  "anims": {"idle":[10,10],"run":[10,16],"jump":[3,10],"fall":[3,10],"attack1":[8,20],"attack2":[8,20],"attack3":[9,20],"hit":[4,12],"death":[11,12]}},
	"cung_thu":     {"fw": 200, "fh": 200, "cx": 101, "fy": 134, "s": 0.775, "anims": {"idle":[10,10],"run":[8,14],"jump":[2,8],"fall":[2,8],"attack1":[6,16],"hit":[3,12],"death":[10,12]}},
	"phap_su":      {"fw": 231, "fh": 190, "cx": 110, "fy": 141, "s": 0.68,  "anims": {"idle":[6,8],"run":[8,14],"jump":[2,8],"fall":[2,8],"attack1":[8,18],"attack2":[8,18],"hit":[4,12],"death":[7,10]}},
	"toan_nang":    {"fw": 311, "fh": 199, "cx": 156, "fy": 195, "s": 0.452, "anims": {"idle":[6,10],"run":[12,16],"jump":[3,10],"fall":[3,10],"attack1":[8,20],"attack2":[8,20],"attack3":[8,20],"hit":[6,12],"death":[8,10]}},
	"sat_thu":      {"fw": 221, "fh": 198, "cx": 89,  "fy": 155, "s": 0.45,  "anims": {"idle":[10,10],"run":[8,14],"jump":[3,10],"fall":[3,10],"attack1":[8,22],"attack2":[7,22],"attack3":[9,22],"hit":[4,12],"death":[10,12]}},
	"tanker":       {"fw": 199, "fh": 175, "cx": 101, "fy": 170, "s": 0.45,  "anims": {"idle":[10,10],"run":[8,14],"jump":[3,10],"fall":[3,10],"attack1":[7,16],"attack2":[7,16],"attack3":[8,16],"hit":[4,12],"death":[10,10]}},
	"tri_lieu_su":  {"fw": 196, "fh": 146, "cx": 60,  "fy": 138, "s": 0.55,  "anims": {"idle":[8,10],"run":[8,14],"jump":[2,8],"fall":[2,8],"attack1":[8,16],"hit":[4,12],"death":[5,8]}},
	"trieu_hoi_su": {"fw": 246, "fh": 202, "cx": 116, "fy": 202, "s": 0.45,  "anims": {"idle":[8,10],"run":[8,14],"jump":[4,10],"fall":[4,10],"attack1":[7,16],"attack2":[9,18],"hit":[4,12],"death":[4,8]}},
	"tu_linh_thuat_su": {"fw": 184,"fh":222,"cx":72,"fy":210,"s":0.6,"anims":{"idle":[8,10],"run":[8,14],"jump":[2,8],"fall":[2,8],"attack1":[13,18],"attack2":[17,18],"hit":[5,12],"death":[9,10]}},
	"kiem_thanh":   {"fw": 260, "fh": 245, "cx": 130, "fy": 237, "s": 0.27,  "anims": {"idle":[8,10],"run":[8,14],"jump":[4,10],"fall":[3,10],"attack1":[9,18],"hit":[5,12],"death":[8,10]}},
}
# Nhánh tiến hóa mượn hình class gốc
const ALIAS := {
	"than_xa":"cung_thu", "anh_vuong":"sat_thu", "thanh_linh":"tri_lieu_su",
	"ho_ve_bat_khuat":"tanker", "dai_phap_su":"phap_su", "none":"kiem_si",
	"kiem_thanh":"kiem_thanh",
}

## SpriteFrames dựng một lần cho mỗi class rồi dùng chung cho mọi CharSprite (người chơi khác, NPC...).
## Trước đây mỗi người tạo ~60-70 AtlasTexture mới → vào khu đủ 20 người bị khựng. Không ai sửa SpriteFrames sau khi dựng.
static var _frames_cache: Dictionary = {}

var school: String = "kiem_si"
var facing: int = 1
var _sprites: Dictionary = {}   # anim -> SpriteFrames
var _current: AnimatedSprite2D = null
var _fallback: ColorRect = null

func setup(school_id: String) -> void:
	school = ALIAS.get(school_id, school_id)
	if not CHARS.has(school):
		school = "kiem_si"
	_build()

func _build() -> void:
	var def: Dictionary = CHARS[school]
	if _frames_cache.has(school):
		_sprites = _frames_cache[school]
	else:
		_sprites = {}
		_build_frames(def)
		_frames_cache[school] = _sprites
	_attach(def)

func _build_frames(def: Dictionary) -> void:
	var anims: Dictionary = def["anims"]
	for anim in anims.keys():
		var path := "%s/%s/%s.png" % [ASSET_DIR, school, anim]
		if not ResourceLoader.exists(path):
			continue
		var tex := load(path) as Texture2D
		if tex == null:
			continue
		var frames := SpriteFrames.new()
		if frames.has_animation("default"):
			frames.remove_animation("default")
		var info: Array = anims[anim]
		var count := int(info[0])
		var fps := float(info[1])
		frames.add_animation(anim)
		frames.set_animation_speed(anim, fps)
		frames.set_animation_loop(anim, anim != "death")
		var fw := int(def["fw"])
		var fh := int(def["fh"])
		for i in range(count):
			var at := AtlasTexture.new()
			at.atlas = tex
			at.region = Rect2(i * fw, 0, fw, fh)
			frames.add_frame(anim, at)
		_sprites[anim] = frames

func _attach(def: Dictionary) -> void:
	if _sprites.is_empty():
		# Không có ảnh: vẫn có thân màu để không vỡ màn hình
		_fallback = ColorRect.new()
		_fallback.color = Color(0.9, 0.72, 0.4)
		_fallback.size = Vector2(20, 30)
		_fallback.position = Vector2(-10, -30)
		add_child(_fallback)
		return

	_current = AnimatedSprite2D.new()
	_current.sprite_frames = _sprites["idle"]
	_current.animation = "idle"
	var s := float(def["s"])
	var cx := float(def["cx"])
	var fy := float(def["fy"])
	_current.scale = Vector2.ONE * s
	# Khớp Sprites.fitPlayer của web (art/sprites.js:296):
	#   setOrigin(cx/fw, (fy - 30/s)/fh) -> server lưu y = TÂM THÂN, chân nằm ở y+30.
	# Với centered=false Godot vẽ ảnh từ (offset) đến (offset+size), rồi scale.
	#   tâm ngang cx phải nằm ở x=0  => offset.x = -cx
	#   chân fy phải nằm ở y=+30     => (offset.y+fy)*s = 30 => offset.y = 30/s - fy
	_current.centered = false
	_current.offset = Vector2(-cx, 30.0 / s - fy)
	add_child(_current)
	_current.play("idle")

func play(anim: String) -> void:
	if _current == null: return
	if not _sprites.has(anim):
		anim = "idle"
	if _current.animation == anim and _current.is_playing():
		return
	_current.sprite_frames = _sprites[anim]
	_current.play(anim)

func set_facing(f: int) -> void:
	if f == 0: return
	facing = f
	if _current:
		_current.flip_h = f < 0
