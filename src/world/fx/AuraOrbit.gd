extends Node2D
## Vật thể xoay quanh người SUỐT thời gian buff — theo class và theo loại buff (khớp bản web: skillfx.js R.aura):
##   tăng công / chí mạng / tốc đánh  -> vòng vũ khí của class (Kiếm Sĩ: 5 thanh kiếm dựng đứng)
##   giảm sát thương / phản đòn / khiên -> vòng phòng thủ (Kiếm Sĩ: 4 khiên tròn)
##   có cả hai                        -> hiện cả hai vòng (vũ khí bên trong, phòng thủ bên ngoài, quay ngược chiều)
##   hồi dần                          -> thập tự xanh
## Mỗi buff dùng HAI node con của nhân vật: layer 0 (nửa sau, vẽ sau lưng người) và layer 1 (nửa trước, vẽ đè lên người)
## để vật thể thật sự đi vòng quanh. Hiện dần sau `delay` giây (chờ hiệu ứng tung chiêu tan), mờ dần 0,5 giây cuối buff.

const GY := 28.0   # y chân nhân vật trong toạ độ node nhân vật

# k: hình; n: số vật; sc: cỡ; spin: tự xoay; big: nở rộng vòng
const RINGS := {
	"kiem_si": {"atk": {"k": "sword", "n": 5}, "def": {"k": "shield", "n": 4}},
	"cung_thu": {"atk": {"k": "arrow", "n": 5}, "def": {"k": "feather", "n": 6, "spin": true}},
	"phap_su": {"atk": {"k": "orb", "n": 5, "mix": true}, "def": {"k": "crystal", "n": 6}},
	"toan_nang": {"atk": {"k": "star", "n": 5, "spin": true, "mix": true}, "def": {"k": "disc", "n": 4, "spin": true}},
	"sat_thu": {"atk": {"k": "dagger", "n": 5}, "def": {"k": "smoke", "n": 7}},
	"tanker": {"atk": {"k": "hammer", "n": 4}, "def": {"k": "shield", "n": 4, "sc": 1.35, "big": 1.12}},
	"tri_lieu_su": {"atk": {"k": "star", "n": 5, "spin": true}, "def": {"k": "feather", "n": 6, "spin": true, "halo": true}},
	"trieu_hoi_su": {"atk": {"k": "orb", "n": 5}, "def": {"k": "bird", "n": 3, "sc": 1.1}},
	"tu_linh_thuat_su": {"atk": {"k": "skull", "n": 5}, "def": {"k": "skull", "n": 4, "sc": 0.8, "darker": true}},
}
const HEAL := {"k": "cross", "n": 4}
const MIX := {
	"phap_su": [Color(1.0, 0.55, 0.2), Color(0.55, 0.9, 1.0), Color(1.0, 0.95, 0.45)],
	"toan_nang": [Color(1.0, 0.5, 0.3), Color(1.0, 0.9, 0.4), Color(0.5, 0.9, 1.0), Color(0.75, 0.5, 1.0), Color(0.5, 1.0, 0.6)],
}

var layer := 0            # 0 = nửa sau, 1 = nửa trước
var school := "kiem_si"
var col := Color(1.0, 0.85, 0.4)
var core := Color.WHITE
var dark_col := Color(0.4, 0.35, 0.55)
var until_ms := 0
var delay := 1.1
var lowq := false
var _t := 0.0
var _rings: Array = []

## want_*: loại buff. Trả false nếu buff này không cần vòng nào.
func setup(sch: String, atk: bool, defn: bool, heal: bool) -> bool:
	school = sch if RINGS.has(sch) else "toan_nang"
	var both := atk and defn
	_rings.clear()
	var set: Dictionary = RINGS[school]
	if atk:
		var a: Dictionary = (set["atk"] as Dictionary).duplicate()
		a["rx"] = 36.0 if both else 44.0
		a["ry"] = 12.0 if both else 15.0
		a["dy"] = -4.0
		a["spd"] = 1.7
		a["dir"] = 1.0
		_rings.append(a)
	if defn:
		var d: Dictionary = (set["def"] as Dictionary).duplicate()
		var big := float(d.get("big", 1.0))
		d["rx"] = (62.0 if both else 52.0) * big
		d["ry"] = 20.0 if both else 17.0
		d["dy"] = 2.0
		d["spd"] = 1.1
		d["dir"] = -1.0 if both else 1.0
		_rings.append(d)
	if heal and not atk and not defn:
		var h: Dictionary = HEAL.duplicate()
		h["rx"] = 46.0; h["ry"] = 15.0; h["dy"] = -4.0; h["spd"] = 1.2; h["dir"] = 1.0
		_rings.append(h)
	return not _rings.is_empty()

var _redraw_acc := 0.0

func _process(delta: float) -> void:
	_t += delta
	if Time.get_ticks_msec() >= until_ms:
		queue_free()
		return
	_redraw_acc += delta
	if _redraw_acc >= 1.0 / 30.0:
		_redraw_acc = 0.0
		queue_redraw()

func _fade() -> float:
	var fin := clampf((_t - delay) / 0.45, 0.0, 1.0)
	var fout := clampf(float(until_ms - Time.get_ticks_msec()) / 500.0, 0.0, 1.0)
	return fin * fout

func _draw() -> void:
	var k := _fade()
	if k <= 0.01: return
	if layer == 0:
		# trận đồ mờ dưới chân suốt thời gian buff
		draw_set_transform(Vector2(0, GY - 3.0), 0.0, Vector2(1.0, 0.26))
		var pulse := 0.3 + 0.1 * sin(_t * 4.0)
		draw_arc(Vector2.ZERO, 58.0, 0.0, TAU, 48, Color(col, pulse * k), 2.2)
		draw_arc(Vector2.ZERO, 44.0, 0.0, TAU, 40, Color(core, pulse * 0.6 * k), 1.2)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var ri := 0
	for r in _rings:
		var rd: Dictionary = r
		var n: int = int(rd["n"])
		var kind := str(rd["k"])
		var spin := bool(rd.get("spin", false))
		var base_sc := float(rd.get("sc", 1.0))
		var mix: Array = MIX.get(school, []) if bool(rd.get("mix", false)) else []
		var c0 := col
		if bool(rd.get("darker", false)): c0 = dark_col.lerp(col, 0.35)
		elif kind == "smoke": c0 = dark_col
		for i in range(n):
			var a: float = TAU * float(i) / float(n) + _t * float(rd["spd"]) * float(rd["dir"]) + float(ri) * 0.6
			var sn := sin(a)
			var front := sn > 0.0
			if (layer == 1) != front: continue
			var p := Vector2(cos(a) * float(rd["rx"]), float(rd["dy"]) + sn * float(rd["ry"]))
			var s := base_sc * k * (0.9 + 0.1 * sn)
			var al := k * (1.0 if front else 0.6)
			var c := (mix[i % mix.size()] as Color) if not mix.is_empty() else c0
			var rot := (_t * 4.0 + float(i)) if spin else 0.0
			_item(kind, p, rot, s, c, al)
		if layer == 1 and bool(rd.get("halo", false)):
			draw_set_transform(Vector2(0, -38.0), 0.0, Vector2(1.0, 0.3))
			draw_arc(Vector2.ZERO, 15.0, 0.0, TAU, 32, Color(core, 0.85 * k), 2.4)
			draw_arc(Vector2.ZERO, 15.0, 0.0, TAU, 32, Color(col, 0.35 * k), 6.0)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		ri += 1

func _poly(pts: PackedVector2Array, c: Color) -> void:
	draw_colored_polygon(pts, c)

## Vẽ một vật tại p, xoay rot, cỡ s. Hình dựng đứng (mũi hướng lên) trong toạ độ cục bộ cao ~32px.
func _item(kind: String, p: Vector2, rot: float, s: float, c: Color, al: float) -> void:
	draw_set_transform(p, rot, Vector2(s, s))
	var main := Color(c, al)
	var edge := Color(core, al)
	var soft := Color(c, al * 0.2)
	match kind:
		"sword":
			draw_circle(Vector2(0, -2), 13.0, soft)
			_poly(PackedVector2Array([Vector2(0, -17), Vector2(3.6, -10), Vector2(3.0, 8), Vector2(-3.0, 8), Vector2(-3.6, -10)]), main)
			draw_line(Vector2(0, -14), Vector2(0, 7), edge, 1.4)
			draw_rect(Rect2(-7.0, 8.0, 14.0, 2.6), Color(c.lerp(core, 0.4), al))
			draw_rect(Rect2(-1.6, 10.6, 3.2, 6.0), Color(c.darkened(0.45), al))
		"dagger":
			draw_circle(Vector2(0, -2), 10.0, soft)
			_poly(PackedVector2Array([Vector2(0, -14), Vector2(3.0, -8), Vector2(2.6, 6), Vector2(-2.6, 6), Vector2(-3.0, -8)]), main)
			draw_line(Vector2(0, -11), Vector2(0, 5), edge, 1.2)
			draw_rect(Rect2(-5.5, 6.0, 11.0, 2.2), Color(c.lerp(core, 0.3), al))
			draw_rect(Rect2(-1.3, 8.2, 2.6, 5.0), Color(c.darkened(0.5), al))
		"arrow":
			draw_circle(Vector2(0, -2), 11.0, soft)
			draw_line(Vector2(0, -12), Vector2(0, 14), Color(c.darkened(0.25), al), 1.8)
			_poly(PackedVector2Array([Vector2(0, -19), Vector2(-3.8, -11), Vector2(3.8, -11)]), edge)
			_poly(PackedVector2Array([Vector2(0, 14), Vector2(-4, 18), Vector2(0, 11)]), main)
			_poly(PackedVector2Array([Vector2(0, 14), Vector2(4, 18), Vector2(0, 11)]), main)
		"hammer":
			draw_circle(Vector2(0, 0), 12.0, soft)
			draw_rect(Rect2(-1.8, -4.0, 3.6, 21.0), Color(0.45, 0.3, 0.18, al))
			draw_rect(Rect2(-9.0, -15.0, 18.0, 11.5), main)
			draw_rect(Rect2(-9.0, -15.0, 18.0, 11.5), edge, false, 1.4)
		"shield":
			draw_circle(Vector2.ZERO, 14.0, soft)
			draw_circle(Vector2.ZERO, 12.0, Color(c, al * 0.32))
			draw_arc(Vector2.ZERO, 12.0, 0.0, TAU, 28, main, 3.0)
			draw_arc(Vector2.ZERO, 7.5, 0.0, TAU, 20, Color(c, al * 0.8), 1.4)
			draw_circle(Vector2.ZERO, 3.2, edge)
			draw_line(Vector2(0, -12), Vector2(0, 12), Color(core, al * 0.5), 1.2)
			draw_line(Vector2(-12, 0), Vector2(12, 0), Color(core, al * 0.5), 1.2)
		"orb":
			draw_circle(Vector2.ZERO, 10.0, Color(c, al * 0.18))
			draw_circle(Vector2.ZERO, 6.5, Color(c, al * 0.5))
			draw_circle(Vector2.ZERO, 3.6, edge)
		"star":
			_poly(PackedVector2Array([Vector2(0, -11), Vector2(2.6, -2.6), Vector2(11, 0), Vector2(2.6, 2.6), Vector2(0, 11), Vector2(-2.6, 2.6), Vector2(-11, 0), Vector2(-2.6, -2.6)]), main)
			draw_circle(Vector2.ZERO, 3.0, edge)
		"skull":
			draw_circle(Vector2(0, -1), 11.0, soft)
			draw_circle(Vector2(0, -2.5), 7.0, Color(c.lerp(core, 0.5), al))
			draw_rect(Rect2(-4.2, 2.0, 8.4, 6.0), Color(c.lerp(core, 0.5), al))
			draw_circle(Vector2(-2.7, -2.5), 1.9, Color(0.05, 0.03, 0.08, al))
			draw_circle(Vector2(2.7, -2.5), 1.9, Color(0.05, 0.03, 0.08, al))
		"feather":
			_poly(PackedVector2Array([Vector2(0, -12), Vector2(4.2, -2), Vector2(0, 12), Vector2(-4.2, -2)]), main)
			draw_line(Vector2(0, -10), Vector2(0, 11), edge, 1.0)
		"cross":
			draw_rect(Rect2(-2.4, -9.0, 4.8, 18.0), main)
			draw_rect(Rect2(-9.0, -2.4, 18.0, 4.8), main)
			draw_rect(Rect2(-1.0, -7.0, 2.0, 14.0), edge)
			draw_rect(Rect2(-7.0, -1.0, 14.0, 2.0), edge)
		"bird":
			_poly(PackedVector2Array([Vector2(-13, -6), Vector2(-3, 0), Vector2(0, -3), Vector2(3, 0), Vector2(13, -6), Vector2(5, 5), Vector2(0, 3), Vector2(-5, 5)]), main)
			draw_circle(Vector2(0, -1), 2.4, edge)
		"crystal":
			draw_circle(Vector2.ZERO, 11.0, soft)
			_poly(PackedVector2Array([Vector2(0, -14), Vector2(5.5, 0), Vector2(0, 14), Vector2(-5.5, 0)]), main)
			_poly(PackedVector2Array([Vector2(0, -10), Vector2(2.4, 0), Vector2(0, 8), Vector2(-1.6, 0)]), Color(core, al * 0.8))
		"disc":
			draw_circle(Vector2.ZERO, 11.0, soft)
			draw_arc(Vector2.ZERO, 9.0, 0.0, TAU, 24, main, 3.0)
			draw_line(Vector2(0, -9), Vector2(0, 9), edge, 1.2)
			draw_line(Vector2(-9, 0), Vector2(9, 0), edge, 1.2)
		"smoke":
			draw_circle(Vector2.ZERO, 11.0, Color(c, al * 0.45))
			draw_circle(Vector2(-3, -2), 7.0, Color(c.lightened(0.25), al * 0.4))
			draw_circle(Vector2(4, 3), 6.0, Color(c.lightened(0.15), al * 0.35))
		_:
			draw_circle(Vector2.ZERO, 7.0, main)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
