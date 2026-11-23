extends Node2D
## Đồ rơi trên đất: icon nhấp nhô + quầng sáng theo độ hiếm. Nhặt bằng nút "Nhặt" trên HUD khi đứng gần.

const T := preload("res://src/ui/UITheme.gd")
const QCOL := [Color(0.91, 0.89, 0.82), Color(1, 1, 1), Color(0.39, 0.71, 0.96), Color(0.81, 0.58, 0.85), Color(1.0, 0.79, 0.16)]

var lid := ""
var until := 0
var item_id := ""
var item_name := ""
var quality := 0
var _t := 0.0
var _icon: Sprite2D

func setup(data: Dictionary) -> void:
	lid = str(data.get("lid", ""))
	until = int(data.get("until", 0))
	var inst: Dictionary = data.get("inst", {})
	item_id = str(inst.get("id", ""))
	var def: Dictionary = Data.item(item_id)
	item_name = str(def.get("name", item_id))
	quality = int(inst.get("q", 0)) if not str(def.get("slot", "")).is_empty() else 0
	quality = clampi(quality, 0, 4)
	position = Vector2(float(data.get("x", 0)), float(data.get("y", 0)) - 14.0)
	z_index = 3
	_icon = Sprite2D.new()
	var path := "res://assets/items/%s.svg" % item_id
	if ResourceLoader.exists(path): _icon.texture = load(path)
	if _icon.texture:
		var s := 26.0 / maxf(1.0, float(_icon.texture.get_width()))
		_icon.scale = Vector2(s, s)
	add_child(_icon)
	if quality >= 2:
		var l := T.hud_label(item_name, 12, QCOL[quality], true)
		l.position = Vector2(-40, -42)
		l.custom_minimum_size = Vector2(80, 0)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		add_child(l)
	_t = randf() * 6.0
	# Rơi xuống nảy nhẹ
	position.y -= 40.0
	scale = Vector2(0.4, 0.4)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(self, "position:y", position.y + 40.0, 0.45).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "scale", Vector2.ONE, 0.3)

func _process(delta: float) -> void:
	_t += delta
	if _icon: _icon.position.y = sin(_t * 4.0) * 3.0 - 2.0
	queue_redraw()

func _draw() -> void:
	var c: Color = QCOL[quality]
	var pulse := 1.0 + 0.15 * sin(_t * 5.0)
	draw_circle(Vector2.ZERO, (15.0 if quality >= 2 else 11.0) * pulse, Color(c, 0.28 if quality >= 2 else 0.16))
	if quality >= 3:
		draw_rect(Rect2(-4, -90, 8, 90), Color(c, 0.18 + 0.08 * sin(_t * 3.0)), true)

func fly_to(target: Vector2) -> void:
	var tw := create_tween().set_parallel(true)
	tw.tween_property(self, "global_position", target, 0.22)
	tw.tween_property(self, "scale", Vector2(0.3, 0.3), 0.22)
	tw.tween_property(self, "modulate:a", 0.0, 0.22)
	tw.chain().tween_callback(queue_free)
