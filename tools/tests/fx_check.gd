extends SceneTree
## So Game.special_fx / has_passive (GDScript) với G.specialFx / G.passivesOf của web trên .calc_cases.json.
## Cần cột "fx" và "passives" trong ca mẫu (tools/tests/gen_calc_cases.js ghi sẵn).
func _initialize() -> void:
	var data = root.get_node("Data")
	data.load_local()
	var game = root.get_node("Game")
	var f := FileAccess.open("res://.calc_cases.json", FileAccess.READ)
	var cases: Array = JSON.parse_string(f.get_as_text())
	var bad := 0
	var n := 0
	for c in cases:
		if not c.has("fx"): continue
		n += 1
		game.player = c["player"]
		var got: Dictionary = game.special_fx()
		var want: Dictionary = c["fx"]
		var a := got.keys(); a.sort()
		var b := want.keys(); b.sort()
		if str(a) != str(b):
			bad += 1; print("LECH fx [", c.get("label", "?"), "] app=", a, " web=", b)
		for p in ["kiem_si", "cung_thu", "phap_su", "sat_thu", "tanker", "tri_lieu_su"]:
			if bool(game.has_passive(p)) != (c["passives"] as Array).has(p):
				bad += 1; print("LECH passive ", p, " [", c.get("label", "?"), "]")
	print("fx_check ", n, " ca, lech=", bad)
	quit()
