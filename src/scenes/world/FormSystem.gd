extends "res://src/scenes/world/WorldPart.gd"
## Biến hình (Ấn thức tỉnh): bật/tắt, hào quang, đổi Ấn.
## Hệ thống của World (w = World). Trạng thái riêng khai báo ngay dưới; trạng thái dùng chung đọc qua thuộc tính chuyển tiếp.

# Trạng thái riêng
var _form_ready_at := 0
var _form_acc := 0.0

# Trạng thái dùng chung (lưu ở World)
var _fx: Node2D:
	get: return w._fx if is_instance_valid(w._fx) else null
	set(x): w._fx = x
var _player: Node2D:
	get: return w._player if is_instance_valid(w._player) else null
	set(x): w._player = x
var _hud_node: Node:
	get: return w._hud_node if is_instance_valid(w._hud_node) else null
	set(x): w._hud_node = x
var _fxs: Node2D:
	get: return w._fxs if is_instance_valid(w._fxs) else null
	set(x): w._fxs = x
var _last_hurt: int:
	get: return w._last_hurt
	set(x): w._last_hurt = x
var _dead: bool:
	get: return w._dead
	set(x): w._dead = x
var _changing: bool:
	get: return w._changing
	set(x): w._changing = x
var _hud_dirty: bool:
	get: return w._hud_dirty
	set(x): w._hud_dirty = x
var _sta_used_at: int:
	get: return w._sta_used_at
	set(x): w._sta_used_at = x
var _sta_frac: float:
	get: return w._sta_frac
	set(x): w._sta_frac = x
var _aura: Node2D:
	get: return w._aura if is_instance_valid(w._aura) else null
	set(x): w._aura = x

# Hàm của hệ thống khác
func _process(delta: float) -> void:
	w._process(delta)

func shake(strength: float, duration: float) -> void:
	w.shake(strength, duration)

func _active_awaken() -> Dictionary:
	return Data.awaken(maxi(1, Data.awaken_tier_of(Game.player.get("formChoice", ""))))

func _toggle_form() -> void:
	if _dead or _changing: return
	var tier := maxi(1, Data.awaken_tier_of(Game.player.get("formChoice", "")))
	if tier > int(Game.player.get("awakenTier", 0)):
		_hud_node.toast("Ấn chưa mở khóa. Hoàn thành thử thách NPC ẩn rồi dùng Sách Biến Hình.", "warn")
		return
	if Game.form_active:
		_end_form("")
		return
	var now := Time.get_ticks_msec()
	if now < _form_ready_at: return
	var aw := _active_awaken()
	var drain := float(aw.get("drain", 3))
	var need := drain * 3.0
	if float(Game.mp) < need or float(Game.sta) < need or Game.sta_locked:
		_hud_node.toast("Không đủ năng lượng / thể lực để biến hình (cần %d)." % int(need), "warn")
		return
	var hr := float(Game.hp) / float(maxi(1, int(Game.stats.get("maxHp", 1))))
	var mr := float(Game.mp) / float(maxi(1, int(Game.stats.get("maxMp", 1))))
	var sr := float(Game.sta) / float(maxi(1, int(Game.stats.get("maxSta", 1))))
	Game.form_active = true
	Game.recalc_stats()
	Game.hp = int(roundf(float(Game.stats.get("maxHp", 1)) * hr))
	Game.mp = int(roundf(float(Game.stats.get("maxMp", 1)) * mr))
	Game.sta = int(roundf(float(Game.stats.get("maxSta", 1)) * sr))
	_sta_frac = float(Game.sta)
	_form_acc = 0.0
	_form_ready_at = now + 1500
	_apply_form_visual(true, false)
	Net.action("form_toggle", {}, {"silent": true})
	_hud_node.banner("BIẾN HÌNH · ẤN THỨ %s" % ["NHẤT", "HAI", "BA", "TƯ", "NĂM"][clampi(int(aw.get("tier", 1)) - 1, 0, 4)], _col_int(int(aw.get("aura", 0xffcc66))))
	_hud_dirty = true

func _end_form(reason: String) -> void:
	if not Game.form_active: return
	var hr := float(Game.hp) / float(maxi(1, int(Game.stats.get("maxHp", 1))))
	var mr := float(Game.mp) / float(maxi(1, int(Game.stats.get("maxMp", 1))))
	var sr := float(Game.sta) / float(maxi(1, int(Game.stats.get("maxSta", 1))))
	Game.form_active = false
	Game.recalc_stats()
	Game.hp = maxi(1, int(roundf(float(Game.stats.get("maxHp", 1)) * hr)))
	Game.mp = maxi(0, int(roundf(float(Game.stats.get("maxMp", 1)) * mr)))
	Game.sta = maxi(0, int(roundf(float(Game.stats.get("maxSta", 1)) * sr)))
	_sta_frac = float(Game.sta)
	_form_ready_at = Time.get_ticks_msec() + 1500
	_apply_form_visual(false, false)
	Net.action("form_toggle", {}, {"silent": true})
	if not reason.is_empty() and _hud_node: _hud_node.toast(reason, "warn")
	FloatText.spawn(_fx, _player.position + Vector2(0, -52), "Trở lại dạng thường", Color(0.88, 0.88, 0.88), 12)
	_hud_dirty = true

func _col_int(v: int) -> Color:
	return Color.from_rgba8((v >> 16) & 255, (v >> 8) & 255, v & 255)

## Hào quang + nhuộm màu khi biến hình (idempotent). quiet: không phát hiệu ứng bùng nổ.
func _apply_form_visual(on: bool, quiet: bool = true) -> void:
	var aw := _active_awaken()
	if on and not aw.is_empty():
		_player.modulate = Color.WHITE.lerp(_col_int(int(aw.get("tint", 0xffffff))), 0.42)
		if _aura == null or not is_instance_valid(_aura):
			_aura = _make_aura(aw)
			_player.add_child(_aura)
		if not quiet:
			var col := _col_int(int(aw.get("aura", 0xffcc66)))
			_fxs.ring(_player.position + Vector2(0, 28), col, 120.0, 0.7, 6.0)
			_fxs.ring(_player.position + Vector2(0, 28), Color(1, 1, 1, 0.8), 70.0, 0.5, 3.0)
			_fxs.burst(_player.position, col, 24, 220.0)
			shake(7.0, 0.4)
			Audio.play("levelup", 0.8)
			if _hud_node: _hud_node.flash(col, 0.3)
	else:
		_player.modulate = Color.WHITE
		if _aura != null and is_instance_valid(_aura):
			_aura.queue_free()
		_aura = null

## Hào quang riêng từng Ấn: 1 vàng bốc lên · 2 hồng tím có tia điện · 3 băng lam rơi tuyết · 4 huyết hỏa dữ dội · 5 tím trắng quầng sáng + vệt sao xoay.
func _make_aura(aw: Dictionary) -> Node2D:
	var tier := int(aw.get("tier", 1))
	var c1 := _col_int(int(aw.get("aura", 0xffcc66)))
	var c2 := _col_int(int(aw.get("aura2", 0xffffff)))
	var root := Node2D.new()
	root.z_index = -1
	root.position = Vector2(0, 14)
	var halo := _AuraHalo.new()
	halo.col = c1
	halo.tier = tier
	root.add_child(halo)
	var low := Settings.quality_low
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	var p := CPUParticles2D.new()
	p.material = mat
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(11, 6)
	p.direction = Vector2.UP
	var g := Gradient.new()
	g.set_color(0, Color(c2, 0.9))
	g.add_point(0.5, Color(c1, 0.7))
	g.set_color(g.get_point_count() - 1, Color(c1, 0.0))
	p.color_ramp = g
	match tier:
		1:   # vàng: đốm sáng nhẹ bay lên
			p.amount = 14 if low else 26; p.lifetime = 0.9; p.spread = 22.0
			p.initial_velocity_min = 28.0; p.initial_velocity_max = 70.0
			p.gravity = Vector2(0, -30); p.scale_amount_min = 2.0; p.scale_amount_max = 5.0
		2:   # hồng tím: tia điện giật quanh người
			p.amount = 16 if low else 34; p.lifetime = 0.35; p.spread = 180.0
			p.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
			p.emission_sphere_radius = 16.0
			p.initial_velocity_min = 60.0; p.initial_velocity_max = 150.0
			p.gravity = Vector2.ZERO; p.scale_amount_min = 1.5; p.scale_amount_max = 3.5
			p.position = Vector2(0, -14)
			var bolt := _AuraBolts.new()
			bolt.col = c2
			root.add_child(bolt)
		3:   # băng lam: bông băng rơi chậm toả ra ngoài
			p.amount = 14 if low else 30; p.lifetime = 1.6; p.direction = Vector2.DOWN; p.spread = 70.0
			p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
			p.emission_rect_extents = Vector2(20, 26); p.position = Vector2(0, -34)
			p.initial_velocity_min = 8.0; p.initial_velocity_max = 28.0
			p.gravity = Vector2(0, 14); p.scale_amount_min = 2.0; p.scale_amount_max = 4.5
			p.angular_velocity_min = -90.0; p.angular_velocity_max = 90.0
		4:   # huyết hỏa: lửa cao, dữ dội
			p.amount = 22 if low else 48; p.lifetime = 0.8; p.spread = 16.0
			p.emission_rect_extents = Vector2(14, 5)
			p.initial_velocity_min = 70.0; p.initial_velocity_max = 150.0
			p.gravity = Vector2(0, -90); p.scale_amount_min = 3.0; p.scale_amount_max = 8.0
			g.set_color(0, Color(c2, 0.95))
		_:   # tím trắng: vệt sao xoay quanh người
			p.amount = 20 if low else 40; p.lifetime = 1.1; p.spread = 180.0
			p.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
			p.emission_sphere_radius = 24.0; p.position = Vector2(0, -16)
			p.initial_velocity_min = 4.0; p.initial_velocity_max = 20.0
			p.orbit_velocity_min = 0.6; p.orbit_velocity_max = 1.1
			p.gravity = Vector2(0, -22); p.scale_amount_min = 2.0; p.scale_amount_max = 5.0
	root.add_child(p)
	p.emitting = true
	return root

## Mỗi giây trừ năng lượng + thể lực theo ấn; cạn mà hồi không đủ bù thì tự trở lại dạng thường (như web).
func _form_tick(delta: float) -> void:
	if not Game.form_active or _dead: return
	var aw := _active_awaken()
	if aw.is_empty():
		_end_form("")
		return
	_form_acc += delta
	var drain := int(aw.get("drain", 3))
	while _form_acc >= 1.0:
		_form_acc -= 1.0
		Game.mp = maxi(0, Game.mp - drain)
		Game.sta = maxi(0, Game.sta - drain)
		_sta_frac = float(Game.sta)
		_hud_dirty = true
	# Tốc độ hồi thực tế mỗi giây — khớp formRegenRates() của web (hồi MP chỉ khi không giao chiến; Dòng Chảy luôn hồi)
	var max_mp_f := float(int(Game.stats.get("maxMp", 100)))
	var now_f := Time.get_ticks_msec()
	var calm_f := int(Game._as_dict(Data.calc.get("REGEN", {})).get("calmMs", 2000))
	var fighting_f := now_f - _sta_used_at < calm_f or now_f - _last_hurt < calm_f
	var mp_regen := max_mp_f * 0.005 if Game.has_passive("phap_su") else 0.0
	if not fighting_f: mp_regen += maxf(float(Game._as_dict(Data.calc.get("REGEN", {})).get("mp", 1)), max_mp_f * 0.005)
	var sta_regen := float(Data.STAMINA.get("regen", 12.0)) * (1.0 if now_f - _sta_used_at > int(Data.STAMINA.get("delay", 800)) else float(Data.STAMINA.get("activeMul", 0.3))) * (1.0 + float(Game.stats.get("staRegen", 0.0)) / 100.0)
	if Game.mp <= 0 and mp_regen < float(drain): _end_form("Hết năng lượng, biến hình kết thúc.")
	elif Game.sta <= 0 and sta_regen < float(drain):
		Game.sta_locked = true
		_end_form("Hết thể lực, biến hình kết thúc.")

## Đổi vòng qua các Ấn đã mở (Ấn I -> II -> ... -> I). Chỉ đổi được ở dạng thường.
func _switch_seal() -> void:
	var unlocked := int(Game.player.get("awakenTier", 0))
	if unlocked < 2 or _dead or _changing: return
	if Game.form_active:
		_hud_node.toast("Hãy trở lại dạng thường trước khi đổi ấn.", "warn")
		return
	var cur := maxi(1, Data.awaken_tier_of(Game.player.get("formChoice", "")))
	var nxt := cur % unlocked + 1
	Net.action("form_select", {"choice": "awaken%d" % nxt}, {"silent": true})
	_hud_node.toast("Đã chọn Biến hình · Ấn %s" % str(Data.ROMAN[nxt - 1]), "success")
	Audio.play("ui")

class _AuraHalo extends Node2D:
	var col := Color.WHITE
	var tier := 1
	var _t := 0.0
	var _redraw_acc := 0.0
	func _process(d: float) -> void:
		_t += d
		_redraw_acc += d
		if _redraw_acc >= 1.0 / 30.0:
			_redraw_acc = 0.0
			queue_redraw()
	func _draw() -> void:
		var pulse := 0.5 + 0.5 * sin(_t * (2.5 + float(tier) * 0.7))
		var r := 30.0 + float(tier) * 3.0 + pulse * 4.0
		draw_set_transform(Vector2(0, -18), 0.0, Vector2(0.8, 1.15))
		draw_circle(Vector2.ZERO, r, Color(col, 0.10 + 0.06 * pulse))
		draw_circle(Vector2.ZERO, r * 0.7, Color(col, 0.12))
		if tier >= 5:
			draw_arc(Vector2.ZERO, r + 6.0, _t * 1.4, _t * 1.4 + PI * 1.2, 24, Color(1, 1, 1, 0.55), 2.0)
			draw_arc(Vector2.ZERO, r + 12.0, -_t * 1.0, -_t * 1.0 + PI * 0.9, 24, Color(col, 0.6), 2.0)
		elif tier == 3:
			for i in range(6):
				var a := float(i) * TAU / 6.0 + _t * 0.4
				draw_line(Vector2(cos(a), sin(a)) * (r - 4.0), Vector2(cos(a), sin(a)) * (r + 6.0), Color(1, 1, 1, 0.45), 1.5)
		elif tier == 4:
			draw_arc(Vector2.ZERO, r + 3.0, 0.0, TAU, 32, Color(col, 0.35 + 0.25 * pulse), 3.0)

class _AuraBolts extends Node2D:
	var col := Color.WHITE
	var _t := 0.0
	var _seed := 0
	var _rng := RandomNumberGenerator.new()
	func _process(d: float) -> void:
		_t += d
		if _t > 0.09:
			_t = 0.0
			_seed = randi()
			queue_redraw()
	func _draw() -> void:
		_rng.seed = _seed
		for k in range(2):
			var p := Vector2(0, -18)
			var a := _rng.randf() * TAU
			for i in range(4):
				a += _rng.randf_range(-0.9, 0.9)
				var n := p + Vector2(cos(a), sin(a)) * _rng.randf_range(7.0, 13.0)
				draw_line(p, n, Color(col, 0.95), 1.6)
				p = n
