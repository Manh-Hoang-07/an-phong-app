extends Node2D
## Màn chơi: nền parallax, bản đồ, nhân vật, quái (server quản lý), người chơi khác, đồ rơi, NPC/cổng, HUD cảm ứng.
## Luật chơi vẫn ở server. File này: vật lý nhân vật, gửi đòn, nhận sát thương từ đòn lao của quái,
## chết/hồi sinh, đổi bản đồ, đổi phiếu thưởng (`kills`), nhặt đồ, lưu trạng thái.


const T := preload("res://src/ui/UITheme.gd")
const GlyphArt := preload("res://src/ui/GlyphArt.gd")
const LootNode := preload("res://src/world/LootNode.gd")
const RemotePlayer := preload("res://src/world/RemotePlayer.gd")
const MapEntities := preload("res://src/world/MapEntities.gd")
const Fx := preload("res://src/world/Fx.gd")
const Weather := preload("res://src/world/Weather.gd")
const ATTACK_GAP_MS := 340
const AssistScript := preload("res://src/world/Assist.gd")

const MapSystem := preload("res://src/scenes/world/MapSystem.gd")
const MotorSystem := preload("res://src/scenes/world/MotorSystem.gd")
const TargetSystem := preload("res://src/scenes/world/TargetSystem.gd")
const BuffSystem := preload("res://src/scenes/world/BuffSystem.gd")
const CombatSystem := preload("res://src/scenes/world/CombatSystem.gd")
const LifeSystem := preload("res://src/scenes/world/LifeSystem.gd")
const PetSystem := preload("res://src/scenes/world/PetSystem.gd")
const LootSystem := preload("res://src/scenes/world/LootSystem.gd")
const NetSystem := preload("res://src/scenes/world/NetSystem.gd")
const PotionSystem := preload("res://src/scenes/world/PotionSystem.gd")
const FormSystem := preload("res://src/scenes/world/FormSystem.gd")

# Hệ thống (src/scenes/world/): mỗi hệ thống giữ trạng thái riêng, World giữ trạng thái dùng chung và điều phối.
var map = MapSystem.new(self)
var motor = MotorSystem.new(self)
var target = TargetSystem.new(self)
var buffs = BuffSystem.new(self)
var combat = CombatSystem.new(self)
var life = LifeSystem.new(self)
var pets = PetSystem.new(self)
var loot = LootSystem.new(self)
var net = NetSystem.new(self)
var potions = PotionSystem.new(self)
var form = FormSystem.new(self)

@onready var _bg: Node2D = $Background
@onready var _map_layer: Node2D = $MapLayer
@onready var _remote: Node2D = $RemoteLayer
@onready var _mob_layer: Node2D = $MobLayer
@onready var _fx: Node2D = $FxLayer
@onready var _player: Node2D = $Player
@onready var _hud: CanvasLayer = $MobileHUD
@onready var _cam: Camera2D = $Camera2D
var _char_script: Script = null
var _hud_node: Node = null
var _skill_fx: Node = null
var _bg_node: Node = null
var _map_view: Node2D = null
var _entities: Node2D = null
var _loot_layer: Node2D = null
var _fade: ColorRect = null
var _fxs: Node2D = null
var _weather: CanvasLayer = null
var _mob_script: Script = null
var _assist: Node = null         # thú đồng hành / linh thú / bóng ma tự đánh quái
var _last_hit_uid := 0           # quái người chơi vừa đánh (bạn đồng hành nhắm theo)
var _last_hit_at := 0
var _shadow_power_until := 0
var _players: Dictionary = {}   # id -> RemotePlayer
var _mobs: Dictionary = {}      # uid -> MobSprite
var _loots: Dictionary = {}     # lid -> LootNode
var _map_id := ""
var _meta: Dictionary = {}
var _grid: Array = []
var _cols := 0
var _rows := 0
# nhân vật
var _facing := 1
var _anim := "idle"
var _move_dir := Vector2.ZERO
var _vy := 0.0
var _knock_vx := 0.0
var _knock_until := 0
var _jump_req := false
var _attack_until := 0
var _next_attack := 0
var _hurt_until := 0
var _invuln_until := 0
var _last_hurt := 0
var _buffs: Dictionary = {}          # id kỹ năng -> {name, until, reduce, reflect, absorb, atk, crit, speed, regen}
var _slow_until := 0                 # trùm Nước / Băng làm chậm người chơi
var _nth_count: Dictionary = {}           # Ấn Sát: số đòn đã trúng theo uid quái
var _free_cast_used := false         # bộ Lưu Trữ: kỹ năng đầu tiên mỗi trận miễn MP
var _dead := false
var _changing := false
var _cd_until: Array = [0, 0, 0, 0, 0, 0, 0, 0, 0]   # 0-4 thường, 5-7 tuyệt kỹ/tuyệt phẩm (ô 5,6,7 của server), 8 kỹ năng trang bị
var _last_saved := Vector2(-1, -1)
var _hud_dirty := true
var _hud_acc := 0.0
var _interact_acc := 0.0
var _pickup_pending: Dictionary = {}
var _pickup_lid := ""
var _interact: Dictionary = {}
var _player_sprite: Node2D = null   # reference trực tiếp, tránh get_children() mỗi khung trong _set_facing/_play_anim
var _target_mob: Node2D = null
var _target_t := 0.0
# ---- Đạn bay
var _projs: Array = []
var _shadow_focus := 0
var _shadow_focus_until := 0
var _interact_mark: Node2D = null
var _loot_store: Dictionary = {}   # lid -> {data, ch}: đồ rơi nhớ theo khu (kênh), chỉ hiện ở khu nó rơi
var _enter_try := 0
var _shake_tween: Tween = null
var _sta_used_at := 0
var _sta_frac := -1.0
var _aura: Node2D = null

func _ready() -> void:
	_char_script = load("res://src/world/CharSprite.gd")
	_mob_script = load("res://src/world/MobSprite.gd")
	get_viewport().size_changed.connect(_apply_zoom)
	Settings.changed.connect(func(k, _v): if k == "world_zoom": _apply_zoom.call_deferred())
	_assist = AssistScript.new()
	add_child(_assist)
	_assist.setup(self)
	var mv_script: Script = load("res://src/world/MapView.gd")
	if mv_script:
		_map_view = mv_script.new()
		_map_view.name = "MapView"
		_map_layer.add_child(_map_view)
	_entities = MapEntities.new()
	_entities.name = "Entities"
	_map_layer.add_child(_entities)
	_loot_layer = Node2D.new()
	_loot_layer.name = "Loot"
	_mob_layer.get_parent().add_child(_loot_layer)
	_mob_layer.get_parent().move_child(_loot_layer, _mob_layer.get_index())
	_fxs = Fx.new()
	_fxs.name = "Fx"
	_fx.add_child(_fxs)
	var fx_script: Script = load("res://src/world/SkillFx.gd")
	if fx_script:
		_skill_fx = fx_script.new()
		_skill_fx.name = "SkillFx"
		_fx.add_child(_skill_fx)
	var bg_script: Script = load("res://src/world/Background.gd")
	if bg_script:
		_bg_node = bg_script.new()
		_bg.name = "BackgroundFx"
		_bg.add_child(_bg_node)
	_weather = Weather.new()
	add_child(_weather)
	var hud_script: Script = load("res://src/ui/MobileHUD.gd")
	if hud_script:
		_hud_node = hud_script.new()
		_hud.add_child(_hud_node)
		_hud_node.move_vector.connect(func(d): _move_dir = d)
		_hud_node.skill_pressed.connect(combat._cast)
		_hud_node.attack_pressed.connect(combat._on_attack)
		_hud_node.jump_pressed.connect(func(): _jump_req = true)
		_hud_node.menu_pressed.connect(func(_t): _hud_dirty = true)
		_hud_node.chat_sent.connect(net._on_chat)
		_hud_node.interact_pressed.connect(loot._do_interact)
		_hud_node.death_choice.connect(life._on_death_choice)
		_hud_node.potion_pressed.connect(potions._use_quick_potion)
		_hud_node.form_pressed.connect(form._toggle_form)
		_hud_node.seal_pressed.connect(form._switch_seal)

	# Lớp phủ đen dùng khi chuyển cảnh
	var fl := CanvasLayer.new()
	fl.layer = 30
	add_child(fl)
	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 1)
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fl.add_child(_fade)

	Socket.connected_to_server.connect(net._on_socket_connected)
	Socket.players.connect(net._on_players)
	Socket.mobs.connect(net._on_mobs)
	Socket.chat.connect(net._on_chat_recv)
	Game.player_changed.connect(func(_q): _hud_dirty = true)
	Game.event_received.connect(net._on_event)
	Net.action_done.connect(net._on_action_done)

	if not Game.has_player():
		get_tree().call_deferred("change_scene_to_file", "res://src/scenes/Login.tscn")
		return
	if Game.hp <= 0:
		Game.hp = int(Game.player.get("hp", 0))
		if Game.hp <= 0: Game.hp = int(Game.stats.get("maxHp", 100))
	if Game.mp <= 0 and int(Game.player.get("mp", 0)) > 0: Game.mp = int(Game.player.get("mp", 0))
	_setup_player_sprite()
	map._load_player_map("")
	_refresh_hud()
	Socket.start()
	_fade_in()

func _exit_tree() -> void:
	if Game.has_player() and not _dead and not _changing:
		life._save_state()
	life._flush_kills()
	Socket.stop()

func _fade_in() -> void:
	_fade.modulate.a = 1.0
	create_tween().tween_property(_fade, "modulate:a", 0.0, 0.3)

func _setup_player_sprite() -> void:
	var school := str(Game.player.get("school", "kiem_si"))
	for c in _player.get_children(): c.queue_free()
	_player_sprite = null
	if _char_script:
		var sprite: Node2D = _char_script.new()
		_player.add_child(sprite)
		sprite.setup(school)
		_player_sprite = sprite
	_aura = null
	_player.modulate = Color.WHITE
	if Game.form_active: form._apply_form_visual(true, true)

func _find_char(ch: String) -> Vector2i:
	for r in range(_grid.size()):
		var row: Array = _grid[r]
		for c in range(row.size()):
			if str(row[c]) == ch: return Vector2i(c, r)
	return Vector2i(-1, -1)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("skill1"): combat._cast(0)
	elif event.is_action_pressed("skill2"): combat._cast(1)
	elif event.is_action_pressed("skill3"): combat._cast(2)
	elif event.is_action_pressed("skill4"): combat._cast(3)
	elif event.is_action_pressed("skill5"): combat._cast(4)
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_X: combat._cast(5)
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_V: combat._cast(8)
	elif event.is_action_pressed("attack"): combat._on_attack()

func _process(delta: float) -> void:
	if not Game.has_player(): return
	motor._move_step(minf(delta, 1.0 / 30.0))
	if _assist != null: _assist.tick(delta)
	# Nền bám đúng tâm màn hình THẬT của camera (đã bị chặn ở biên map), không phải vị trí nhân vật
	if _cam and _bg_node:
		_bg_node.set_camera(_cam.get_screen_center_position())
	_hud_acc += delta
	if _hud_dirty and _hud_acc > 0.1:
		_hud_acc = 0.0
		_hud_dirty = false
		_refresh_hud()
	# Chưa nhận được danh sách quái sau 3s: xin server gửi lại (vào phòng bằng pos r=1)
	if Socket.online and not Socket.mobs_received and Time.get_ticks_msec() - _enter_try > 3000:
		net._on_socket_connected()
	_interact_acc += delta
	if _interact_acc >= 0.1:
		_interact_acc = 0.0
		loot._update_interact()
	elif _interact_mark != null and is_instance_valid(_interact_mark):
		# vẫn nhấp nhô mũi tên giữa các lần quét
		var it := str(_interact.get("type", ""))
		if it != "" and _interact.has("pos"):
			_interact_mark.position = (_interact["pos"] as Vector2) + Vector2(0, sin(_target_t * 7.7) * 4.0)
	target._update_target(delta)
	buffs._buff_hud_tick(delta)
	life._regen(delta)
	combat._update_projectiles(minf(delta, 1.0 / 30.0))   # kẹp như _move_step: khung khựng không làm đạn nhảy xa hơn bề rộng quái (xuyên qua)
	life._stamina_tick(delta)
	form._form_tick(delta)

## Độ phóng camera = Settings.world_zoom (nhỏ hơn = thấy rộng hơn). CHỈ phụ thuộc world_zoom,
## KHÔNG chia cho content_scale_factor như cũ — chính phép chia đó triệt tiêu hoàn tác dụng của
## tỉ lệ hiển thị (đổi 75/85/115% nhưng tầm nhìn thế giới y hệt). HUD nằm ở lớp canvas riêng nên
## content_scale_factor vẫn chỉnh cỡ chữ/nút bình thường, không ảnh hưởng tầm nhìn map.
func _apply_zoom() -> void:
	if _cam == null: return
	_cam.zoom = Vector2.ONE * Settings.world_zoom
	# Nền tính _view theo zoom của camera -> báo nó tính lại sau khi zoom đổi.
	if _bg_node != null and _bg_node.has_method("refresh_view"):
		_bg_node.refresh_view.call_deferred()

func shake(strength: float, duration: float) -> void:
	if _cam == null: return
	# Chỉ một Tween rung tại một thời điểm: trúng đòn dồn dập không chồng offset.
	if _shake_tween != null and _shake_tween.is_valid(): _shake_tween.kill()
	var tw := create_tween()
	_shake_tween = tw
	var steps := maxi(1, int(duration / 0.04))
	for i in range(steps):
		var k := 1.0 - float(i) / float(steps)
		tw.tween_property(_cam, "offset", Vector2(randf_range(-1, 1), randf_range(-1, 1)) * strength * k, 0.04)
	tw.tween_property(_cam, "offset", Vector2.ZERO, 0.04)

func _refresh_hud() -> void:
	if _hud_node == null: return
	var p: Dictionary = Game.player
	var lv := int(p.get("level", 1))
	var st: Dictionary = Game.stats
	if st.is_empty(): st = p.get("stats", {})
	if st.is_empty(): st = p
	_hud_node.set_stats(
		Game.hp, int(st.get("maxHp", p.get("maxHp", 100))),
		Game.mp, int(st.get("maxMp", p.get("maxMp", 100))),
		maxi(0, Game.sta) if Game.sta >= 0 else int(p.get("sta", 0)), int(st.get("maxSta", 100)),
		int(p.get("exp", 0)), Formulas.exp_to_next(lv))
	_hud_node.set_map(str(Data.map_def(_map_id).get("name", _map_id)))
	_hud_node.set_hero(str(p.get("name", "Thức Tỉnh")), lv, str(p.get("rank", "E")), str(p.get("school", "")))
	var q: Dictionary = p.get("quest", {}) if typeof(p.get("quest", {})) == TYPE_DICTIONARY else {}
	var qtext := "Nhiệm vụ: hoàn tất cốt truyện"
	if not q.is_empty():
		var qstate := str(q.get("state", "none"))
		if qstate == "active" and not Game.quest_hint.is_empty():
			qtext = Game.quest_hint
		else:
			var ready := Data.quest_ready(p)
			var cqq: Dictionary = Data.quest_current(p)
			if qstate == "active" and ready:
				qtext = "Trả nhiệm vụ: %s" % str(cqq.get("name", ""))
			elif qstate == "active":
				var nl := ""
				for l in Data.quest_obj_lines(p, cqq.get("obj", {}), q.get("progress", {}) if typeof(q.get("progress", {})) == TYPE_DICTIONARY else {}):
					if not bool(l[1]): nl = str(l[0]); break
				qtext = nl if nl != "" else str(cqq.get("name", "Nhiệm vụ"))
			elif cqq.is_empty():
				qtext = "Nhiệm vụ: hoàn tất cốt truyện"
			else:
				qtext = "Gặp NPC để nhận: %s" % str(cqq.get("name", ""))
	if not Data.quest_ready(p):
		for sid in (Data.side_state(p).get("active", {}) as Dictionary).keys():
			if Data.side_ready(p, str(sid)):
				qtext = "Trả phụ tuyến: %s" % str(Data.quest_by_id(str(sid)).get("name", sid))
				break
	_hud_node.set_quest(qtext)
	if _entities:
		var cq: Dictionary = Data.quest_current(p)
		_entities.set_quest_marks(str(cq.get("npc", "")), ("done" if Data.quest_ready(p) else str(q.get("state", ""))) if not q.is_empty() else "")
		_entities.refresh_visibility(p, _map_id)
	var labels: Array = []
	for i in range(9):
		var sid := combat._btn_skill(i)
		var sk: Dictionary = Data.skill(sid)
		labels.append("%s|%s" % [(GlyphArt.skill_token(sid, str(sk.get("icon", "@star"))) if not sk.is_empty() else ("@star" if i >= 5 and i < 8 else "")), str(sk.get("name", sid))])
	_hud_node.set_skill_visible(8, combat._gear_skill_id() != "")
	var toan_nang := str(Data.school(str(p.get("school", ""))).get("base", str(p.get("school", "")))) == "toan_nang"   # Toàn Năng có thêm ô thường 5 và ô tuyệt kỹ 3 (như web)
	_hud_node.set_skill_visible(4, toan_nang)
	_hud_node.set_skill_visible(7, toan_nang)
	_hud_node.set_skill_labels(labels)
	var colors: Array = []
	var usable: Array = []
	for i in range(9):
		var sk2: Dictionary = Data.skill_eff(Game.player, combat._btn_skill(i))
		colors.append(combat._skill_color(sk2) if not sk2.is_empty() else Color(0.5, 0.5, 0.58))
		usable.append(not sk2.is_empty() and Game.mp >= int(sk2.get("mp", 0)))
	_hud_node.set_skill_styles(colors, usable)
	_hud_node.set_form_state(int(p.get("awakenTier", 0)), maxi(1, Data.awaken_tier_of(p.get("formChoice", ""))), Game.form_active)
	loot._sync_hidden_npc()
	potions._update_potions()
