extends "res://src/ui/hud/HudPart.gd"
## Hiệu ứng toàn màn hình: nháy màu, viền máu thấp, thanh bận.
## Thành phần của MobileHUD (hud = MobileHUD): tự dựng node, tự giữ trạng thái; API công khai được MobileHUD chuyển tiếp.

var _flash: ColorRect = null

var _vignette: TextureRect = null

var _low_hp_tween: Tween = null

var _busy_tween: Tween = null

var _flash_tween: Tween = null

func _build_screen_fx() -> void:
	_flash = ColorRect.new()
	_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash.color = Color(1, 1, 1, 0)
	_root.add_child(_flash)
	var grad := Gradient.new()
	grad.set_color(0, Color(0.8, 0.0, 0.05, 0.0))
	grad.set_color(1, Color(0.8, 0.0, 0.05, 0.75))
	grad.set_offset(0, 0.55)
	var gt := GradientTexture2D.new()
	gt.gradient = grad
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.5)
	gt.fill_to = Vector2(1.05, 1.05)
	gt.width = 256
	gt.height = 128
	_vignette = TextureRect.new()
	_vignette.texture = gt
	_vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	_vignette.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_vignette.stretch_mode = TextureRect.STRETCH_SCALE
	_vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vignette.modulate.a = 0.0
	_root.add_child(_vignette)

func _tween_busy(alpha: float) -> void:
	if hud.panel._busy_bar == null: return
	if _busy_tween != null and _busy_tween.is_valid(): _busy_tween.kill()
	_busy_tween = create_tween()
	_busy_tween.tween_property(hud.panel._busy_bar, "modulate:a", alpha, 0.15)

## Nháy toàn màn hình một màu (bị đánh, thăng cấp).
func flash(color: Color, strength: float = 0.3) -> void:
	if _flash == null: return
	if _flash_tween != null and _flash_tween.is_valid(): _flash_tween.kill()
	_flash.color = Color(color, strength)
	_flash_tween = create_tween()
	_flash_tween.tween_property(_flash, "color:a", 0.0, 0.25)

func _update_low_hp(ratio: float) -> void:
	if _vignette == null: return
	var low := ratio < 0.28 and ratio > 0.0
	if low and _low_hp_tween == null:
		_low_hp_tween = create_tween().set_loops()
		_low_hp_tween.tween_property(_vignette, "modulate:a", 0.9, 0.5)
		_low_hp_tween.tween_property(_vignette, "modulate:a", 0.3, 0.5)
	elif not low and _low_hp_tween != null:
		_low_hp_tween.kill()
		_low_hp_tween = null
		create_tween().tween_property(_vignette, "modulate:a", 0.0, 0.3)
