extends Node2D
## Nền parallax riêng từng bản đồ (cùng công thức với web: ghép lớp sky/far/mid/near từ nhiều bộ ảnh + chỉnh màu).
## Công thức lấy từ data/map_looks.json (tools/export_looks.js). Lớp chỉnh màu bằng shader (hue/sat/lum/tint/mix/gamma),
## cảnh tĩnh (lr_*) phủ kín bề ngang và ghép gương để lặp liền mạch. Thiếu ảnh thì dùng nền gradient theo theme.

const BG_DIR := "res://assets/bg"
const SCROLL := {"sky": 0.0, "far": 0.08, "mid": 0.16, "near": 0.30}
const LAYER_Z := {"sky": -30, "far": -20, "mid": -15, "near": -10}

const FLAT := {
	"city":    [Color(0.09, 0.10, 0.15), Color(0.16, 0.15, 0.21)],
	"forest":  [Color(0.06, 0.11, 0.09), Color(0.12, 0.19, 0.13)],
	"cave":    [Color(0.05, 0.06, 0.09), Color(0.11, 0.11, 0.16)],
	"redgate": [Color(0.12, 0.05, 0.07), Color(0.20, 0.09, 0.11)],
}

const GRADE_SHADER := """
shader_type canvas_item;
uniform mat3 colmat = mat3(1.0);
uniform vec3 kmul = vec3(1.0);
uniform vec3 mixc = vec3(0.0);
uniform float mixa = 0.0;
uniform float gamma = 1.0;
void fragment() {
	vec4 c = texture(TEXTURE, UV);
	vec3 rgb = colmat * c.rgb;
	rgb *= kmul;
	rgb = clamp(rgb, 0.0, 1.0);
	if (gamma != 1.0) rgb = pow(rgb, vec3(1.0 / gamma));
	rgb = rgb * (1.0 - mixa) + mixc * mixa;
	COLOR = vec4(rgb, c.a) * COLOR;
}
"""

var _layers: Array = []     # [{name, spr, tw, th, sc, factor, tys}]
var _view := Vector2(960, 432)
var _cam := Vector2.ZERO
var _shader: Shader = null
var _flat: TextureRect = null
var _haze: TextureRect = null
var _theme := "city"
var _map_id := ""
var _low_quality := false
## set_camera được gọi mỗi khung từ World._process. Nếu camera không dịch thì bỏ qua:
## gán size/position trên TextureRect (Control) invalidate layout dù giá trị không đổi.
var _last_cam := Vector2.ZERO
var _cam_valid := false

## Kích thước vùng THẾ GIỚI mà camera nhìn thấy (đơn vị của MapView/Player), KHÔNG phải cỡ màn hình.
## Node2D nền nằm trong không gian thế giới, nên phải chia cho zoom của camera; nếu dùng thẳng
## get_visible_rect() thì nền bị phóng to đúng bằng zoom (1.176x) và lệch tâm => chân trời tụt thấp, nền lệch mặt đất.
func _world_view() -> Vector2:
	var v := get_viewport().get_visible_rect().size
	var cam := get_viewport().get_camera_2d()
	if cam != null and cam.zoom.x > 0.0 and cam.zoom.y > 0.0:
		v /= cam.zoom
	return v

func _ready() -> void:
	_view = _world_view()

func _load_tex(pack: String, layer: String) -> Texture2D:
	for ext in ["png", "jpg"]:
		var p := "%s/%s/%s.%s" % [BG_DIR, pack, layer, ext]
		if ResourceLoader.exists(p): return load(p) as Texture2D
	return null

func _grade_material(d: Dictionary) -> ShaderMaterial:
	var needs := float(d.get("hue", 0.0)) != 0.0 or d.has("sat") or d.has("lum") or d.has("tint") or d.has("mix") or d.has("gamma")
	if not needs: return null
	if _shader == null:
		_shader = Shader.new()
		_shader.code = GRADE_SHADER
	var hue := deg_to_rad(float(d.get("hue", 0.0)))
	var sat := float(d.get("sat", 1.0))
	var lum := float(d.get("lum", 1.0))
	var c := cos(hue); var s := sin(hue)
	var S := [0.213 + 0.787 * sat, 0.715 - 0.715 * sat, 0.072 - 0.072 * sat, 0.213 - 0.213 * sat, 0.715 + 0.285 * sat, 0.072 - 0.072 * sat, 0.213 - 0.213 * sat, 0.715 - 0.715 * sat, 0.072 + 0.928 * sat]
	var H := [0.213 + c * 0.787 - s * 0.213, 0.715 - c * 0.715 - s * 0.715, 0.072 - c * 0.072 + s * 0.928,
		0.213 - c * 0.213 + s * 0.143, 0.715 + c * 0.285 + s * 0.140, 0.072 - c * 0.072 - s * 0.283,
		0.213 - c * 0.213 - s * 0.787, 0.715 - c * 0.715 + s * 0.715, 0.072 + c * 0.928 + s * 0.072]
	var m := []
	m.resize(9)
	for r in range(3):
		for q in range(3):
			m[r * 3 + q] = H[r * 3] * S[q] + H[r * 3 + 1] * S[3 + q] + H[r * 3 + 2] * S[6 + q]
	# GLSL mat3 theo cột: colmat * v  => hàng i của ma trận web = m[i*3..]
	var basis := Basis(Vector3(m[0], m[3], m[6]), Vector3(m[1], m[4], m[7]), Vector3(m[2], m[5], m[8]))
	var tint := Vector3(1, 1, 1)
	if d.has("tint"):
		var t := int(d["tint"])
		tint = Vector3(float((t >> 16) & 255) / 255.0, float((t >> 8) & 255) / 255.0, float(t & 255) / 255.0)
	var mixc := Vector3.ZERO
	var mixa := 0.0
	var mix: Array = d.get("mix", [])
	if mix.size() == 2:
		var mc := int(mix[0])
		mixc = Vector3(float((mc >> 16) & 255) / 255.0, float((mc >> 8) & 255) / 255.0, float(mc & 255) / 255.0)
		mixa = float(mix[1])
	var mat := ShaderMaterial.new()
	mat.shader = _shader
	mat.set_shader_parameter("colmat", basis)
	mat.set_shader_parameter("kmul", tint * lum)
	mat.set_shader_parameter("mixc", mixc)
	mat.set_shader_parameter("mixa", mixa)
	mat.set_shader_parameter("gamma", float(d.get("gamma", 1.0)))
	return mat

# Ảnh đã lật/ghép đôi dựng bằng CPU khá tốn (tới ~16MB/lớp): chỉ dựng một lần cho mỗi (ảnh gốc, cờ), quay lại map cũ dùng lại.
static var _prep_cache: Dictionary = {}

func _prep_texture(tex: Texture2D, d: Dictionary) -> Texture2D:
	if not (bool(d.get("mirror", false)) or bool(d.get("flip", false))): return tex
	var key := "%s|%d|%d" % [tex.resource_path, 1 if bool(d.get("mirror", false)) else 0, 1 if bool(d.get("flip", false)) else 0]
	if tex.resource_path != "" and _prep_cache.has(key): return _prep_cache[key]
	var out_tex := _prep_texture_build(tex, d)
	if tex.resource_path != "":
		# Giữ tối đa 3 ảnh đã dựng để không phình RAM khi đi qua nhiều map.
		if _prep_cache.size() >= 3: _prep_cache.erase(_prep_cache.keys()[0])
		_prep_cache[key] = out_tex
	return out_tex

func _prep_texture_build(tex: Texture2D, d: Dictionary) -> Texture2D:
	var im := tex.get_image()
	if im.is_compressed(): im.decompress()
	im.convert(Image.FORMAT_RGBA8)
	var a := im.duplicate() as Image
	if bool(d.get("flip", false)): a.flip_x()
	if not bool(d.get("mirror", false)): return ImageTexture.create_from_image(a)
	var w := a.get_width()
	var out := Image.create(w * 2, a.get_height(), false, Image.FORMAT_RGBA8)
	out.blit_rect(a, Rect2i(0, 0, w, a.get_height()), Vector2i(0, 0))
	var b := a.duplicate() as Image
	b.flip_x()
	out.blit_rect(b, Rect2i(0, 0, w, a.get_height()), Vector2i(w, 0))
	return ImageTexture.create_from_image(out)

func set_map(map_id: String, theme: String, low_quality: bool = false) -> void:
	for c in get_children(): c.queue_free()
	_layers.clear()
	_flat = null
	_haze = null
	_theme = theme
	_map_id = map_id
	_low_quality = low_quality
	_view = _world_view()
	var look: Dictionary = Data.look(map_id)
	var layers: Dictionary = look.get("layers", {})
	var packs: Dictionary = Data.looks.get("packs", {})
	# Nền gradient theo theme (luôn có, dưới cùng) — che phần nền ảnh không phủ tới
	_build_flat(look)
	var any := false
	for name in ["sky", "far", "mid", "near"]:
		if name == "mid" and low_quality: continue
		var d: Dictionary = layers.get(name, {})
		if d.is_empty(): continue
		var pack := str(d.get("pack", ""))
		var layer := str(d.get("layer", name))
		if pack == "blank": continue   # lớp rỗng: chỉ để che hình vẽ code
		var tex := _load_tex(pack, layer)
		if tex == null: continue
		tex = _prep_texture(tex, d)
		var pinfo: Dictionary = packs.get(pack, {})
		var spr := TextureRect.new()
		spr.texture = tex
		spr.stretch_mode = TextureRect.STRETCH_TILE
		spr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		spr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		spr.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST if str(pinfo.get("filter", "linear")) == "nearest" else CanvasItem.TEXTURE_FILTER_LINEAR
		spr.z_index = int(LAYER_Z[name])
		var mat := _grade_material(d)
		if mat: spr.material = mat
		add_child(spr)
		var tw := float(tex.get_width())
		var th := float(tex.get_height())
		var sc := _view.y / th
		var ty := 0.0
		if bool(pinfo.get("cover", false)):
			var logic_w := tw / (2.0 if bool(d.get("mirror", false)) else 1.0)
			sc = maxf(sc, _view.x / logic_w)
			ty = maxf(0.0, (th - _view.y / sc) * 0.5)
		spr.scale = Vector2(sc, sc)
		_layers.append({"name": name, "spr": spr, "tw": tw, "th": th, "sc": sc, "ty": ty, "factor": float(SCROLL[name]) if not bool(pinfo.get("cover", false)) else 0.06})
		any = true
	# Sương sát đất nối nền với mặt đất
	if not low_quality:
		_build_haze(look)
	_apply()

func _build_flat(look: Dictionary) -> void:
	var cols: Array = FLAT.get(_theme, FLAT["city"])
	var top: Color = cols[0]
	var bot: Color = cols[1]
	if look.has("bg"):
		var b := int(look["bg"])
		top = Color.from_rgba8((b >> 16) & 255, (b >> 8) & 255, b & 255)
		bot = top.lightened(0.15)
	var grad := Gradient.new()
	grad.set_color(0, top)
	grad.set_color(1, bot)
	var gt := GradientTexture2D.new()
	gt.gradient = grad
	gt.fill_from = Vector2(0, 0)
	gt.fill_to = Vector2(0, 1)
	gt.width = 8
	gt.height = 256
	_flat = TextureRect.new()
	_flat.texture = gt
	_flat.stretch_mode = TextureRect.STRETCH_SCALE
	_flat.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_flat.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flat.z_index = -100
	add_child(_flat)

func _build_haze(look: Dictionary) -> void:
	var hz := int(look.get("haze", 0xb8aaa0))
	var col := Color.from_rgba8((hz >> 16) & 255, (hz >> 8) & 255, hz & 255)
	var grad := Gradient.new()
	grad.set_color(0, Color(col, 0.0))
	grad.set_color(1, Color(col, 0.30))
	var gt := GradientTexture2D.new()
	gt.gradient = grad
	gt.fill_from = Vector2(0, 0)
	gt.fill_to = Vector2(0, 1)
	gt.width = 8
	gt.height = 128
	_haze = TextureRect.new()
	_haze.texture = gt
	_haze.stretch_mode = TextureRect.STRETCH_SCALE
	_haze.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_haze.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_haze.z_index = -8
	add_child(_haze)

func set_camera(pos: Vector2) -> void:
	if _cam_valid and pos.is_equal_approx(_last_cam): return
	_cam = pos
	_apply()

func _apply() -> void:
	_last_cam = _cam
	_cam_valid = true
	var tl := _cam - _view * 0.5
	if _flat:
		_flat.size = _view
		_flat.position = tl
	if _haze:
		_haze.size = Vector2(_view.x, _view.y * 0.55)
		_haze.position = tl + Vector2(0, _view.y * 0.45)
	for L in _layers:
		var spr: TextureRect = L["spr"]
		var sc: float = L["sc"]
		var tw: float = L["tw"]
		var off_tex := fmod(_cam.x * float(L["factor"]) / sc, tw)
		if off_tex < 0.0: off_tex += tw
		spr.size = Vector2(_view.x / sc + tw + 2.0, float(L["th"]))
		spr.position = tl + Vector2(-off_tex * sc, -float(L["ty"]) * sc)

func resize() -> void:
	_view = _world_view()
	_apply()

## Gọi lại khi zoom camera đổi (đổi cỡ cửa sổ / tỉ lệ hiển thị): _view phụ thuộc zoom.
func refresh_view() -> void:
	var nv := _world_view()
	if nv.is_equal_approx(_view): return
	_view = nv
	# Lớp ảnh đã tính scale theo _view cũ -> dựng lại cho đúng cỡ.
	var theme := _theme
	var mid := _map_id
	if mid != "":
		set_map(mid, theme, _low_quality)
	else:
		_apply()
