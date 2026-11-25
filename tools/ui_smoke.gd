extends SceneTree
## Chụp ảnh giao diện để duyệt, không cần server.
##   godot --path . --script res://tools/ui_smoke.gd -- <login|boot|hud|bag|menu|char|skills> [out.png] [WxH]
## (chạy có cửa sổ, KHÔNG dùng --headless vì cần render)

var _what := "hud"
var _out := "user://shot.png"
var _frames := 0
var _hud: Node = null

func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() > 0: _what = a[0]
	if a.size() > 1: _out = a[1]
	if a.size() > 2 and "x" in a[2]:
		var wh := a[2].split("x")
		root.size = Vector2i(int(wh[0]), int(wh[1]))
		DisplayServer.window_set_size(root.size)

func _block_net() -> void:
	# KHÔNG nối server thật (token đã lưu trên máy sẽ bị dùng): địa chỉ chết + xoá đăng nhập, chỉ trong bộ nhớ
	var st = root.get_node("Settings")
	st.token = ""
	st.session = ""
	st.server_url = "http://127.0.0.1:9"
	if not OS.get_environment("SMOKE_SCALE").is_empty():
		st.ui_scale = float(OS.get_environment("SMOKE_SCALE"))
		st._apply_display()
	if not OS.get_environment("SMOKE_WORLD_ZOOM").is_empty():
		st.world_zoom = float(OS.get_environment("SMOKE_WORLD_ZOOM"))

var _began := false

func _start() -> void:
	root.get_node("Data").load_local()
	match _what:
		"login": change_scene_to_file("res://src/scenes/Login.tscn")
		"boot": change_scene_to_file("res://src/scenes/Boot.tscn")
		"skin": _skin_demo()
		_:
			root.get_node("Game").set_player(_fake_player())
			change_scene_to_file("res://src/scenes/World.tscn")

func _fake_player() -> Dictionary:
	return {
		"name": "Hoàng Phong", "level": 18, "rank": "D", "school": "kiem_si", "map": ("lang" if OS.get_environment("SMOKE_MAP").is_empty() else OS.get_environment("SMOKE_MAP")),
		"x": (640 if OS.get_environment("SMOKE_MAP").is_empty() else null), "y": (300 if OS.get_environment("SMOKE_MAP").is_empty() else null), "hp": 420, "mp": 120, "sta": 86, "exp": 640, "gold": 12850, "linhNgoc": 35,
		"perks": ["y_chi_thay", "lien_minh"], "titles": ["Kẻ Thức Tỉnh"], "awakenTier": 3, "formChoice": "awaken3", "kyNguyen": {"owned": ["kn_bat_tu"], "active": ["kn_bat_tu"]}, "shopDiscount": 0.05,
		"points": {"str": 6, "vit": 4, "agi": 3, "spi": 2}, "freePoints": 7,
		"skillSlots": ["pa1", "pa2", "pa3", "pa4", null, null, null, null], "superUlts": {}, "mounts": {"active": null, "owned": ["ky_lan"], "skill": "bite", "skills": {"ky_lan": "bite"}, "summoned": []},
		"skills": {"pa1": 3.0, "pa2": 2.0, "pa3": 1.0},
		"bag": [
			{"uid": 1, "id": "binh_mau_nho", "n": 12}, {"uid": 2, "id": "binh_mau_vua", "n": 4},
			{"uid": 3, "id": "cung_go", "n": 1}, {"uid": 4, "id": "ao_da", "n": 1},
			{"uid": 5, "id": "chuy_sat", "n": 1}, {"uid": 6, "id": "binh_nl_nho", "n": 7},
		],
		"bagPlus": 3, "equip": ({} if OS.get_environment("SMOKE_EQUIP").is_empty() else {"weapon": {"id": OS.get_environment("SMOKE_EQUIP"), "plus": 3}}), "quest": {"step": 2, "state": "active", "progress": {}},
	}

func _process(_d: float) -> bool:
	if not _began:
		_began = true
		_block_net()
		_start()
		return false
	_frames += 1
	if _frames == 20 and _what == "formhud":
		var gg = root.get_node("Game")
		var tr := 2 if OS.get_environment("SMOKE_TIER").is_empty() else int(OS.get_environment("SMOKE_TIER"))
		gg.player["awakenTier"] = tr
		gg.player["formChoice"] = "awaken" + str(tr)
		gg.mp = 100
		gg.sta = 90
		current_scene._toggle_form()
		print("form_active ", gg.form_active, " maxHp ", gg.stats.get("maxHp"), " atk ", gg.stats.get("atk"))
	if _frames == 20 and _what == "skillfx":
		var sw := current_scene
		var sid := OS.get_environment("SMOKE_SKILL")
		sw._skill_fx.play("cast", sid, sw.get_node("Player").position, 1)
	if _frames == 20 and _what == "mobs":
		var w5 := current_scene
		var p5: Vector2 = w5.get_node("Player").position
		var ids := OS.get_environment("SMOKE_MOBS").split(",")
		var lst: Array = []
		var i5 := 0
		for mid5 in ids:
			lst.append({"u": 200 + i5, "id": mid5, "x": p5.x - 160 + i5 * 90, "y": p5.y + 30, "f": -1, "hp": 50, "mh": 100, "al": 1, "st": 0, "fl": 0})
			i5 += 1
		w5._on_mobs({"list": lst})
	if _frames == 20 and _what == "fx":
		var w3 := current_scene
		var p3: Vector2 = w3.get_node("Player").position
		w3._on_mobs({"list": [{"u": 100, "id": "hinh_nhan", "x": p3.x + 70, "y": p3.y + 30, "f": -1, "hp": 50, "mh": 100, "al": 1, "st": 0, "fl": 0}, {"u": 101, "id": "hinh_nhan", "x": p3.x + 150, "y": p3.y + 30, "f": -1, "hp": 50, "mh": 100, "al": 1, "st": 0, "fl": 0}]})
		w3._on_attack()
		w3._on_mob_packet({"t": "mhit", "u": 100, "hp": 20, "d": 340, "c": 1, "by": 0, "dir": 1})
		w3._on_mob_packet({"t": "mdie", "u": 101, "by": 0})
		w3._on_event({"t": "levelup", "level": 19})
	if _frames == 100 and _what.begins_with("npc"):
		var dd = current_scene.get_node("MobileHUD").get_child(0)._dialog
		print("DLG@100 vis ", dd.visible, " mod ", dd.modulate, " rect ", dd.get_global_rect(), " kids ", dd.get_child_count(), " in_tree ", dd.is_inside_tree(), " vis_in_tree ", dd.is_visible_in_tree())
	if _frames == 20 and _what == "combat":
		var w2 := current_scene
		var px2: float = w2.get_node("Player").position.x
		var py2: float = w2.get_node("Player").position.y
		var gm = root.get_node("Game")
		var mid := ""
		for id in root.get_node("Data").MONSTERS.keys():
			if int(root.get_node("Data").MONSTERS[id].get("atk", 0)) > 0: mid = id; break
		w2._on_mobs({"list": [{"u": 100, "id": mid, "x": px2, "y": py2 + 30, "f": 1, "hp": 50, "mh": 50, "al": 1, "st": 0, "fl": 0}]})
		print("HP before ", gm.hp, " mob ", mid)
		w2._on_mob_packet({"t": "msnap", "p": [[100, px2, py2 + 30, 1, 2, 0]]})
		w2._cast(0)
		print("MP after cast ", gm.mp, " cd ", w2._cd_until[0] > 0)
	if _frames == 100 and _what == "combat":
		var mm = current_scene._mobs[100]
		var pp = current_scene.get_node("Player").position
		print("mob state ", mm.state, " lunge_hit ", mm.lunge_hit, " atk ", mm.atk, " alive ", mm.alive, " rect ", mm.body_rect(), " player ", pp, " invuln ", current_scene._invuln_until, " now ", Time.get_ticks_msec())
	if _frames == 240 and _what == "combat":
		var gm2 = root.get_node("Game")
		print("HP after lunge ", gm2.hp, " dead ", current_scene._dead)
		gm2.hp = 0
		current_scene._hurt_player(current_scene._mobs[100])
		print("after forced: dead ", current_scene._dead)
	if _frames == 20 and _what == "world":
		var w := current_scene
		var px: float = w.get_node("Player").position.x
		var py: float = w.get_node("Player").position.y
		var mobs := []
		var n := 0
		for id in root.get_node("Data").MONSTERS.keys():
			var d: Dictionary = root.get_node("Data").MONSTERS[id]
			if int(d.get("atk", 0)) > 0 and not d.get("boss", false) and n < 3:
				mobs.append({"u": 100 + n, "id": id, "x": px + 90 + n * 70, "y": py + 30, "f": -1, "hp": 40, "mh": 100, "al": 1, "st": 0, "fl": 0})
				n += 1
		w._on_mobs({"list": mobs})
		w._on_mob_packet({"t": "mhit", "u": 100, "hp": 55, "d": 123, "c": 1, "by": 0})
		w._on_players({"t": "room", "list": [{"id": 7, "name": "Linh Nguyệt", "sc": "phap_su", "lv": 22, "x": px - 120, "y": py, "f": 1, "a": "idle"}]})
		w._on_event({"t": "loot", "loot": {"lid": "L1", "map": "lang", "x": px + 30, "y": py + 30, "inst": {"id": "binh_mau_nho", "q": 0}}})
		w._on_event({"t": "msg", "text": "Nhận 120 xu", "color": "#ffd54f"})
		w._on_event({"t": "levelup", "level": 19})
	if _frames == 20 and _what in ["bag", "menu", "char", "skills", "bagsel", "shop", "equip", "smith", "map", "npc", "config", "storage", "school", "daily", "teleport", "quest", "social", "trade", "skillsel", "npcq", "npcs", "gate", "code", "mount", "companion", "shadows", "kynguyen", "companionown", "form", "npcan", "confirm", "hint", "bagcmp", "equipsel", "petgear"]:
		var w := current_scene
		if w and w.has_node("MobileHUD"):
			_hud = w.get_node("MobileHUD").get_child(0)
			if _what == "menu": _hud._toggle_menu()
			elif _what == "bagsel":
				_hud.open_panel("bag"); _hud._panels._select("bag", "3")
			elif _what == "shop":
				_hud.open_panel("shop", {"npc": "tap_hoa"}); _hud._panels._select("shop", "da_cuong_hoa")
			elif _what == "trade":
				var so = root.get_node("Social")
				so.on_message({"t": "trade", "id": 1, "lockAt": 0, "me": {"items": [{"uid": 1, "id": "binh_mau_nho", "qty": 2}], "gold": 500, "locked": false}, "them": {"id": 7, "name": "Linh Nguyệt", "lv": 22, "items": [], "gold": 0, "locked": true}})
			elif _what == "skillsel":
				_hud.open_panel("skills"); _hud._panels._select("skill", "pa1")
			elif _what == "npc" or _what == "npcq":
				_hud.open_dialog("lao_su")
				print("dlg visible ", _hud._dialog.visible, " size ", _hud._dialog.size, " parent ", _hud._dialog.get_parent().name, " mod ", _hud._dialog.modulate)
			elif _what == "kynguyen":
				root.get_node("Game").player["kyNguyen"] = {"owned": ["kn_bat_tu", "kn_sat_kiep"], "active": ["kn_bat_tu"]}
				_hud.open_panel("kynguyen")
			elif _what == "companionown":
				root.get_node("Game").player["mounts"] = {"owned": ["hinh_nhan", "bong_do"], "summoned": ["bong_do"]}
				root.get_node("Game").player["pets"] = {"bong_do": {"hp": 60, "maxHp": 100, "lv": 7}}
				_hud.open_panel("companion")
			elif _what == "petgear":
				var gp = root.get_node("Game").player
				gp["mounts"] = {"owned": ["bong_do"], "summoned": ["bong_do"]}
				gp["petGear"] = {"bong_do": {"giap": "thu_giap_nho"}}
				gp["bag"] = [{"uid": 9, "id": "thu_yen_nho", "n": 2}, {"uid": 10, "id": "thu_yen_vua", "n": 1}]
				gp["level"] = 12
				_hud.open_panel("companion"); _hud._panels.pet_sel = "bong_do|yen"; _hud._panels.refresh()
			elif _what == "form":
				root.get_node("Game").player["awakenTier"] = 2
				root.get_node("Game").player["formChoice"] = "awaken1"
				_hud.open_panel("form")
			elif _what == "npcan":
				root.get_node("Game").player["advancement"] = {"done": {}, "quest": null}
				_hud.open_dialog("npc_an")
			elif _what == "confirm":
				_hud.confirm("Vứt vật phẩm?", "Bạn sắp vứt Cung gỗ sồi. Không thể lấy lại.", "Vứt", Callable(), true)
				_hud.toast("Không đủ xu", "error")
			elif _what == "hint":
				_hud.hint_once("test_" + str(Time.get_ticks_usec()), "Chạm nút ở giữa-dưới để nói chuyện với NPC.")
				_hud.toast("Cường hóa thành công!", "success")
			elif _what == "bagcmp":
				root.get_node("Game").player["equip"] = {"weapon": {"id": "cung_go", "plus": 0}}
				_hud.open_panel("bag"); _hud._panels._select("bag", "5")
			elif _what == "equipsel":
				# Inject ngay trước khi chụp để gói room từ server không ghi đè equip.
				root.get_node("Game").player["equip"] = {"weapon": {"id": OS.get_environment("SMOKE_EQUIP") if not OS.get_environment("SMOKE_EQUIP").is_empty() else "cung_go", "plus": 3}}
				_hud.open_panel("equip"); _hud._panels._select("equip", "weapon")
				if _hud._panels.has_method("refresh"): _hud._panels.refresh()
			elif _what == "npcs": _hud.open_dialog("tap_hoa")
			else: _hud.open_panel(_what)
	if _frames == 50 and _what == "equipsel":
		root.get_node("Game").player["equip"] = {"weapon": {"id": OS.get_environment("SMOKE_EQUIP") if not OS.get_environment("SMOKE_EQUIP").is_empty() else "cung_go", "plus": 3}}
		_hud.open_panel("equip"); _hud._panels._select("equip", "weapon")
	if _frames == 50 and _what == "petworld":
		var pet_id := "ky_lan" if OS.get_environment("SMOKE_PET").is_empty() else OS.get_environment("SMOKE_PET")
		root.get_node("Game").player["mounts"] = {"owned": [pet_id], "summoned": [pet_id], "skill": "bite", "skills": {pet_id: "bite"}}
		current_scene._sync_pet()
	if _frames == (260 if _what == "combat" else (25 if _what == "fx" else (20 + int(OS.get_environment("SMOKE_FRAME")) if _what == "skillfx" else (120 if _what.begins_with("npc") else 60)))):
		var img := root.get_texture().get_image()
		img.save_png(_out)
		print("saved ", _out, " ", img.get_size())
		quit()
	return false

func _skin_demo() -> void:
	var Skin = load("res://src/ui/UISkin.gd")
	var T = load("res://src/ui/UITheme.gd")
	var bg := ColorRect.new()
	bg.color = Color(0.12, 0.2, 0.14)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	root.add_child(bg)
	var p := PanelContainer.new()
	p.position = Vector2(20, 14); p.size = Vector2(500, 400)
	p.add_theme_stylebox_override("panel", Skin.panel())
	bg.add_child(p)
	var vb := VBoxContainer.new()
	p.add_child(vb)
	var rb := PanelContainer.new()
	rb.add_theme_stylebox_override("panel", Skin.ribbon())
	rb.add_child(T.label("TRANG BỊ", 18, T.C_GOLD, true))
	vb.add_child(rb)
	var hb := HBoxContainer.new()
	vb.add_child(hb)
	for kind in ["default", "primary", "danger", "ghost"]:
		var b := Button.new(); b.text = kind; b.custom_minimum_size = Vector2(90, 40)
		for st in ["normal", "hover", "pressed", "disabled"]:
			b.add_theme_stylebox_override(st, Skin.button(kind, st))
		hb.add_child(b)
	var row := HBoxContainer.new()
	vb.add_child(row)
	for q in range(6):
		var sp := Panel.new(); sp.custom_minimum_size = Vector2(58, 58)
		sp.add_theme_stylebox_override("panel", Skin.slot(q, q == 2))
		row.add_child(sp)
	var sp2 := Panel.new(); sp2.custom_minimum_size = Vector2(58, 58)
	sp2.add_theme_stylebox_override("panel", Skin.slot(0, false, true))
	row.add_child(sp2)
	var bar := ProgressBar.new(); bar.custom_minimum_size = Vector2(300, 20); bar.value = 60; bar.show_percentage = false
	bar.add_theme_stylebox_override("background", Skin.bar_frame())
	bar.add_theme_stylebox_override("fill", Skin.bar_fill(Color(0.9, 0.25, 0.3)))
	vb.add_child(bar)
	var r2 := HBoxContainer.new()
	vb.add_child(r2)
	for i in range(3):
		var rbn := Button.new(); rbn.custom_minimum_size = Vector2(46, 46)
		rbn.add_theme_stylebox_override("normal", Skin.round_button(46, "normal", i == 1))
		r2.add_child(rbn)
	var tabs := HBoxContainer.new()
	vb.add_child(tabs)
	for a in [true, false]:
		var tb := PanelContainer.new(); tb.add_theme_stylebox_override("panel", Skin.tab(a)); tb.add_child(T.label("Tab", 15)); tabs.add_child(tb)
	var cd := PanelContainer.new(); cd.add_theme_stylebox_override("panel", Skin.card()); cd.add_child(T.label("Thẻ card", 15)); vb.add_child(cd)
	var iv := PanelContainer.new(); iv.add_theme_stylebox_override("panel", Skin.inset()); iv.add_child(T.label("Khung lõm", 15)); vb.add_child(iv)
	var pl := PanelContainer.new(); pl.add_theme_stylebox_override("panel", Skin.pill()); pl.add_child(T.label("Nhiệm vụ · Bước 2", 14)); pl.position = Vector2(540, 20); bg.add_child(pl)
