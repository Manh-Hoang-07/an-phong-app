extends Node2D
## Người chơi khác cùng bản đồ: sprite theo class, tên + cấp trên đầu, bóng chat, nội suy vị trí.
## Vị trí gốc nhân vật = tâm thân (server), chân ở y+30 — CharSprite đã căn sẵn.

const T := preload("res://src/ui/UITheme.gd")
const CharSprite := preload("res://src/world/CharSprite.gd")

const ANIM_MAP := {"idle": "idle", "run": "run", "jump": "jump", "fall": "fall", "atk": "attack1", "hit": "hit", "dead": "death"}

var pid := 0
var pname := "?"
var school := ""
var level := 1
var target := Vector2.ZERO
var _sprite: Node2D
var _tag: Label
var _bubble: Label
var _bubble_until := 0
var _has_target := false

func setup(info: Dictionary) -> void:
	pid = int(info.get("id", 0))
	pname = str(info.get("name", "?"))
	school = str(info.get("sc", "")) if info.get("sc", null) != null else ""
	level = int(info.get("lv", 1))
	_sprite = CharSprite.new()
	add_child(_sprite)
	_sprite.setup(school if not school.is_empty() else "kiem_si")
	_tag = T.hud_label(_tag_text(), 12, Color(0.85, 0.93, 1.0), true)
	_tag.position = Vector2(-70, -60)
	_tag.custom_minimum_size = Vector2(140, 0)
	_tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_tag)
	_bubble = T.hud_label("", 13, Color(1, 1, 1), false)
	_bubble.position = Vector2(-90, -88)
	_bubble.custom_minimum_size = Vector2(180, 0)
	_bubble.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_bubble.visible = false
	add_child(_bubble)
	if info.has("x"): apply_state(info)

func _tag_text() -> String:
	return "%s  Lv.%d" % [pname, level]

func apply_look(info: Dictionary) -> void:
	pname = str(info.get("name", pname))
	level = int(info.get("lv", level))
	var sc := str(info.get("sc", "")) if info.get("sc", null) != null else ""
	if sc != school and not sc.is_empty():
		school = sc
		_sprite.setup(sc)
	_tag.text = _tag_text()

func apply_state(info: Dictionary) -> void:
	var p := Vector2(float(info.get("x", position.x)), float(info.get("y", position.y)))
	if not _has_target:
		position = p
		_has_target = true
	target = p
	# Gói vị trí rút gọn không có f/a: giữ nguyên hướng và hoạt ảnh hiện tại
	if _sprite:
		if info.has("f"): _sprite.set_facing(int(info["f"]))
		if info.has("a"):
			var a := str(ANIM_MAP.get(str(info.get("a", "idle")), "idle"))
			_sprite.play(a)

func say(text: String) -> void:
	_bubble.text = text
	_bubble.visible = true
	_bubble_until = Time.get_ticks_msec() + 4000

func _process(delta: float) -> void:
	if _has_target:
		position = position.lerp(target, 1.0 - exp(-12.0 * delta))
	if _bubble.visible and Time.get_ticks_msec() > _bubble_until:
		_bubble.visible = false
