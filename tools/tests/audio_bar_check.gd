extends SceneTree
## Kiểm nhạc nền: mỗi bar dựng ra đủ độ dài, không im lặng, và music() dựng bar ở luồng phụ rồi phát được.
##   godot --headless --path . --script res://tools/tests/audio_bar_check.gd
func _initialize() -> void:
	var a = root.get_node("Audio")
	var bad := 0
	for key in a.SONGS.keys():
		var song: Dictionary = a.SONGS[key]
		var t0 := Time.get_ticks_msec()
		var data: PackedByteArray = a._mix_bar(song, 0)
		var ms := Time.get_ticks_msec() - t0
		var want := int(60.0 / float(song["bpm"]) * 4.0 * a.MIX_RATE) * 2
		var peak := 0
		for i in range(0, data.size(), 2): peak = maxi(peak, absi(data.decode_s16(i)))
		var ok := data.size() == want and peak > 1000
		if not ok: bad += 1
		print("%-8s %4d ms  %d byte  peak %d %s" % [key, ms, data.size(), peak, "" if ok else "LỖI"])
	await process_frame   # chờ autoload chạy _ready
	a.music("cong_do", "city")
	var waited := 0
	while a._bar_cache.size() < 4 and waited < 600:
		await process_frame
		waited += 1
	print("bar nạp từ luồng phụ: ", a._bar_cache.size(), "/4 sau ", waited, " khung")
	if a._bar_cache.size() < 4: bad += 1
	print("Xong: %d lỗi" % bad)
	quit(1 if bad > 0 else 0)
