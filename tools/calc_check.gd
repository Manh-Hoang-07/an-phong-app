extends SceneTree
## So Game.recalc_stats (GDScript) với G.calcStats của web trên các ca mẫu trong .calc_cases.json (node /tmp/gen.js).
func _initialize() -> void:
	var data = root.get_node("Data")
	data.load_local()
	var game = root.get_node("Game")
	var f := FileAccess.open("res://.calc_cases.json", FileAccess.READ)
	var cases: Array = JSON.parse_string(f.get_as_text())
	var bad := 0
	for c in cases:
		game.player = c["player"]
		game.form_active = false
		game.recalc_stats()
		var exp: Dictionary = c["expected"]
		for k in ["maxHp", "maxMp", "atk", "def", "crit", "speed", "maxSta", "cdr", "lifesteal", "boss", "goldfind", "expfind", "staRegen"]:
			var a := float(game.stats.get(k, -999)); var b := float(exp.get(k, -999))
			if absf(a - b) > 0.06:
				bad += 1
				print("LECH ", c["player"]["school"], " ", k, " app=", a, " web=", b)
		if absf(float(game.stats["skillMul"]) - float(exp["skillMul"])) > 0.001: bad += 1; print("LECH skillMul ", c["player"]["school"], " ", game.stats["skillMul"], " vs ", exp["skillMul"])
	print("calc_check xong, lech=", bad)
	quit()
