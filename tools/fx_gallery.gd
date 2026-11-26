extends Node
## Cảnh xem thử hiệu ứng kỹ năng: phát từng kỹ năng, chụp các mốc thời gian ghép thành 1 ảnh/kỹ năng.
## KHÔNG kết nối server (chỉ dùng SkillFx + dữ liệu local).
## Chạy (cần cửa sổ, KHÔNG dùng --headless):
##   Godot.exe --path <repo> res://tools/FxGallery.tscn -- ids=ks40,pa5 out=docs/fx_review
## Tham số: ids=a,b,c (mặc định: tất cả trong manifest) | school=kiem_si | out=thư mục | mobs=3 | times=0.12,0.35,0.6,0.95

var SkillFxScript: Script = load("res://src/world/SkillFx.gd")
const CROP := Rect2i(80, 40, 820, 330)   # vùng quanh nhân vật (px viewport)
const PLAYER := Vector2(300.0, 300.0)

var _world: Node2D
var _fx: Node2D
var _times: Array = [0.12, 0.35, 0.6, 0.95]
var _mobs := 3
var _cols := 4
var _mode := "cast"   # cast | hit (hiệu ứng trúng trên từng quái) | aura (buff kéo dài)
var _hero: Node2D = null
var _out := "res://docs/fx_review"

class Stage extends Node2D:
	var mobs: Array = []
	func _draw() -> void:
		draw_rect(Rect2(-200, -200, 1600, 800), Color(0.10, 0.13, 0.17))
		draw_rect(Rect2(-200, 328, 1600, 200), Color(0.16, 0.19, 0.14))
		draw_line(Vector2(-200, 328), Vector2(1400, 328), Color(0.3, 0.35, 0.25), 2.0)
		# nhân vật
		var p := Vector2(300, 300)
		draw_circle(p + Vector2(0, -24), 8.0, Color(0.9, 0.78, 0.62))
		draw_rect(Rect2(p.x - 8, p.y - 16, 16, 26), Color(0.35, 0.5, 0.85))
		draw_line(p + Vector2(0, 10), p + Vector2(-5, 28), Color(0.3, 0.3, 0.4), 4.0)
		draw_line(p + Vector2(0, 10), p + Vector2(6, 28), Color(0.3, 0.3, 0.4), 4.0)
		for m in mobs:
			var mp: Vector2 = m
			draw_rect(Rect2(mp.x - 14, mp.y - 18, 28, 38), Color(0.7, 0.3, 0.3))
			draw_circle(mp + Vector2(-5, -8), 2.5, Color.WHITE)
			draw_circle(mp + Vector2(5, -8), 2.5, Color.WHITE)
			# thước 100px dưới chân để biết tầm
		for i in range(0, 12):
			draw_line(Vector2(300 + i * 50, 332), Vector2(300 + i * 50, 338 if i % 2 == 0 else 335), Color(1, 1, 1, 0.4), 1.0)

func _ready() -> void:
	var args := _parse_args()
	if args.has("times"): _times = Array(str(args["times"]).split(",")).map(func(s): return float(s))
	if args.has("mode"): _mode = str(args["mode"])
	if args.has("cols"): _cols = int(args["cols"])
	if args.has("mobs"): _mobs = int(args["mobs"])
	if args.has("out"): _out = str(args["out"])
	_world = Stage.new()
	add_child(_world)
	var stage: Stage = _world
	for i in range(_mobs):
		stage.mobs.append(Vector2(300.0 + 110.0 + 70.0 * i, 310.0 + (i % 2) * 6.0))
	var cam := Camera2D.new()
	cam.anchor_mode = Camera2D.ANCHOR_MODE_FIXED_TOP_LEFT
	_world.add_child(cam)
	cam.make_current()
	_fx = SkillFxScript.new()
	_world.add_child(_fx)
	var settings = get_node("/root/Settings")
	settings.quality_low = false
	_run(args)

func _parse_args() -> Dictionary:
	var d := {}
	for a in OS.get_cmdline_user_args():
		var kv := str(a).split("=", true, 1)
		if kv.size() == 2: d[kv[0]] = kv[1]
	return d

func _ids(args: Dictionary) -> Array:
	var manifest: Dictionary = _fx._manifest
	if args.has("ids"): return Array(str(args["ids"]).split(","))
	var out: Array = []
	for k in manifest.keys():
		if args.has("school") and str(manifest[k].get("school", "")) != str(args["school"]): continue
		out.append(k)
	out.sort()
	return out

func _run(args: Dictionary) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	var ids := _ids(args)
	var abs_out := ProjectSettings.globalize_path(_out) if _out.begins_with("res://") else _out
	if not abs_out.is_absolute_path():
		abs_out = ProjectSettings.globalize_path("res://" + _out)
	DirAccess.make_dir_recursive_absolute(abs_out)
	print("fx_gallery: ", ids.size(), " ky nang -> ", abs_out)
	for id in ids:
		await _shoot(str(id), abs_out)
	print("fx_gallery: xong")
	get_tree().quit()

func _shoot(id: String, dir: String) -> void:
	_fx.clear()
	await get_tree().process_frame
	var t0 := Time.get_ticks_msec()
	if _mode == "hit":
		for m in (_world as Stage).mobs:
			_fx.play_hit(id, (m as Vector2) + Vector2(0, -18), 1)
	elif _mode == "proj":
		_fx.play("cast", id, PLAYER, 1)
		var pr: Node2D = load("res://src/world/Proj.gd").new()
		pr.position = PLAYER + Vector2(16.0, -2.0)
		pr.setup(Color(1, 0.6, 0.3), 0.0, 1, 1.0, false)
		var pi: Dictionary = _fx.proj_info(id)
		if not pi.is_empty(): pr.setup_skill(id, pi["col"], pi["core"], bool(pi["dark"]))
		_world.add_child(pr)
		pr.z_index = 7
		create_tween().tween_property(pr, "position:x", PLAYER.x + 600.0, 1.0)
		get_tree().create_timer(1.2).timeout.connect(pr.queue_free)
	elif _mode == "aura":
		if _hero == null or not is_instance_valid(_hero):
			_hero = Node2D.new()
			_hero.position = PLAYER
			_world.add_child(_hero)
		_fx.sync_auras({id: {"until": Time.get_ticks_msec() + 60000}}, _hero, 1)
	else:
		_fx.play("cast", id, PLAYER, 1)
	var frames: Array[Image] = []
	for t in _times:
		while float(Time.get_ticks_msec() - t0) / 1000.0 < float(t):
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var img := get_viewport().get_texture().get_image()
		var sc := float(img.get_width()) / 960.0
		frames.append(img.get_region(Rect2i(int(CROP.position.x * sc), int(CROP.position.y * sc), int(CROP.size.x * sc), int(CROP.size.y * sc))))
	var fw := frames[0].get_width()
	var fh := frames[0].get_height()
	var cols := mini(frames.size(), int(_cols))
	var rows := int(ceil(float(frames.size()) / float(cols)))
	var sheet := Image.create(fw * cols, fh * rows, false, Image.FORMAT_RGBA8)
	for i in range(frames.size()):
		sheet.blit_rect(frames[i], Rect2i(0, 0, fw, fh), Vector2i((i % cols) * fw, (i / cols) * fh))
	sheet.save_png(dir + "/" + id + ("" if _mode == "cast" else "_" + _mode) + ".png")
	if _mode == "aura":
		_fx.sync_auras({}, _hero, 1)
		await get_tree().create_timer(0.6).timeout
	await get_tree().create_timer(0.2).timeout
