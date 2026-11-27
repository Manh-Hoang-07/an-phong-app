extends Node
## Âm thanh: ưu tiên file trong assets/audio/<tên>.ogg|wav; thiếu thì TỔNG HỢP bằng code
## (không cần file ngoài). Hai kênh riêng: SFX (hiệu ứng) và Music (nhạc nền), mỗi kênh
## có công tắc + âm lượng riêng, khớp web (public/js/core/sound.js).
## Tên SFX: hit, crit, hurt, cast, pickup, coin, levelup, portal, ui, death, error.

const AUDIO_DIR := "res://assets/audio"
const MIX_RATE := 22050

var _players: Array[AudioStreamPlayer] = []       # 8 player cho SFX
var _music_players: Array[AudioStreamPlayer] = [] # 2 player cho nhạc (crossfade)
var _cache: Dictionary = {}
var _bar_cache: Dictionary = {}                    # key "song|bar_idx" -> AudioStreamWAV (mỗi bài chỉ 4 bar)
var volume: float = 0.7                            # alias SFX (tương thích code cũ)
var sfx_enabled: bool = true
var music_enabled: bool = true
var sfx_volume: float = 1.0
var music_volume: float = 0.6
var _last_at: Dictionary = {}

# tên -> [tần số đầu, tần số cuối, thời lượng (s), kiểu sóng ("sine"|"square"|"noise"), âm lượng]
const SYNTH := {
	"hit":     [220.0, 110.0, 0.07, "noise", 0.35],
	"crit":    [520.0, 220.0, 0.13, "square", 0.30],
	"hurt":    [180.0, 70.0, 0.18, "square", 0.35],
	"cast":    [320.0, 760.0, 0.16, "sine", 0.30],
	"pickup":  [660.0, 990.0, 0.10, "sine", 0.35],
	"coin":    [880.0, 1320.0, 0.12, "sine", 0.30],
	"levelup": [440.0, 1320.0, 0.55, "sine", 0.40],
	"portal":  [200.0, 900.0, 0.40, "sine", 0.35],
	"ui":      [540.0, 540.0, 0.04, "sine", 0.25],
	"death":   [300.0, 50.0, 0.7, "square", 0.35],
	"error":   [200.0, 150.0, 0.12, "square", 0.25],
}

# Nhạc nền: mỗi theme là một hợp âm lặp (MIDI) + nhịp. Tự tổng hợp bằng code.
# Khớp danh sách theme trong web public/js/core/sound.js SONGS.
const SONGS := {
	"city":    {"bpm": 84, "chords": [[57, 60, 64], [53, 57, 60], [48, 52, 55], [55, 59, 62]], "bright": 1800.0},
	"forest":  {"bpm": 72, "chords": [[50, 53, 57], [55, 58, 62], [58, 62, 65], [57, 61, 64]], "bright": 1300.0},
	"cave":    {"bpm": 92, "chords": [[52, 55, 59], [48, 52, 55], [57, 60, 64], [59, 63, 66]], "bright": 1100.0},
	"redgate": {"bpm": 64, "chords": [[48, 51, 55], [49, 53, 56], [48, 51, 55], [43, 47, 50]], "bright": 700.0},
	"void":    {"bpm": 60, "chords": [[45, 48, 52], [43, 47, 50], [41, 45, 48], [40, 43, 47]], "bright": 600.0},
	"meteor":  {"bpm": 100, "chords": [[50, 53, 57], [55, 59, 62], [48, 52, 55], [53, 57, 60]], "bright": 1400.0},
	"dragon":  {"bpm": 88, "chords": [[48, 55, 59], [50, 57, 60], [53, 60, 64], [43, 50, 55]], "bright": 1200.0},
	"stars":   {"bpm": 76, "chords": [[60, 64, 67], [57, 60, 64], [62, 65, 69], [55, 59, 62]], "bright": 2200.0},
	"dream":   {"bpm": 68, "chords": [[53, 57, 60], [50, 53, 57], [57, 60, 64], [55, 58, 62]], "bright": 900.0},
	"genesis": {"bpm": 96, "chords": [[48, 52, 55], [53, 57, 60], [55, 59, 62], [60, 64, 67]], "bright": 2600.0},
}
# Map từ chương 5 trở đi có nhạc riêng; map cũ dùng theme của nó.
const MAP_SONG := {
	"tan_do_bt": "void", "cau_dan": "void", "sanh_cho": "void", "dinh_cong_vh": "void", "tam_diem": "void", "cong_ss": "void",
	"tan_do_6": "city", "thien_khoi_1": "meteor", "thien_khoi_2": "meteor", "thien_khoi_3": "meteor", "thien_khoi_4": "meteor", "thien_khoi": "meteor",
	"long_mach_1": "dragon", "long_mach_2": "dragon", "long_mach_3": "dragon", "long_mach_4": "dragon", "long_mach": "dragon",
	"tan_do_7": "city", "tinh_van_1": "stars", "tinh_van_2": "stars", "tinh_van_3": "stars", "tinh_van_4": "stars", "tinh_van": "stars",
	"than_mong_1": "dream", "than_mong_2": "dream", "than_mong_3": "dream", "than_mong_4": "dream", "than_mong": "dream",
	"sang_the_1": "genesis", "sang_the_2": "genesis", "sang_the_3": "genesis", "sang_the_4": "genesis", "sang_the": "genesis",
}

var _song_key: String = ""
var _song_bar: int = 0
var _song_next: float = 0.0
var _song_timer: Timer = null
var _bar_mutex := Mutex.new()
var _bar_pending: Dictionary = {}   # ck -> true: đã giao luồng phụ dựng (chỉ luồng chính đụng)
var _bar_done: Dictionary = {}      # ck -> PackedByteArray: luồng phụ dựng xong, chờ luồng chính nhận (khoá bằng _bar_mutex)

func _ready() -> void:
	volume = Settings.volume
	sfx_enabled = Settings.sfx_enabled
	music_enabled = Settings.music_enabled
	sfx_volume = Settings.sfx_volume
	music_volume = Settings.music_volume
	for i in 8:
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		_players.append(p)
	for i in 2:
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)   # AudioStreamPlayer không có thuộc tính loop (lặp do stream quyết định)
		_music_players.append(p)
	_apply_gain()
	_song_timer = Timer.new()
	_song_timer.wait_time = 0.25
	_song_timer.timeout.connect(_on_song_tick)
	add_child(_song_timer)
	# Warm-up SFX một lần lúc boot: tránh synth (tới ~15k sample/âm) đúng lúc đang đánh.
	for name in SYNTH.keys(): _stream(str(name))

func _apply_gain() -> void:
	# SFX_BASE 0.5 / MUSIC_BASE 0.16 như web, nhân âm lượng người chọn; tắt = -80 dB.
	var sfx_lin := 0.5 * sfx_volume if sfx_enabled else 0.0
	var mus_lin := 0.16 * music_volume if music_enabled else 0.0
	for p in _players: p.volume_db = linear_to_db(sfx_lin) if sfx_lin > 0.001 else -80.0
	for p in _music_players: p.volume_db = linear_to_db(mus_lin) if mus_lin > 0.001 else -80.0

# Giữ tương thích với mã cũ gọi set_volume().
func set_volume(v: float) -> void:
	set_sfx_volume(v)

func set_sfx_enabled(on: bool) -> void:
	sfx_enabled = on
	_apply_gain()

func set_music_enabled(on: bool) -> void:
	music_enabled = on
	_apply_gain()
	if not on: stop_music()

func set_sfx_volume(v: float) -> void:
	sfx_volume = clampf(v, 0.0, 1.0)
	volume = sfx_volume
	_apply_gain()

func set_music_volume(v: float) -> void:
	music_volume = clampf(v, 0.0, 1.0)
	_apply_gain()

func _stream(name: String) -> AudioStream:
	if _cache.has(name): return _cache[name]
	var s: AudioStream = null
	for ext in ["ogg", "wav"]:
		var path := "%s/%s.%s" % [AUDIO_DIR, name, ext]
		if ResourceLoader.exists(path):
			s = load(path) as AudioStream
			break
	if s == null and SYNTH.has(name): s = _synth(SYNTH[name])
	_cache[name] = s
	return s

func _synth(def: Array) -> AudioStreamWAV:
	var f0 := float(def[0]); var f1 := float(def[1]); var dur := float(def[2])
	var kind := str(def[3]); var amp := float(def[4])
	var n := int(dur * MIX_RATE)
	var data := PackedByteArray()
	data.resize(n * 2)
	var phase := 0.0
	var rng := RandomNumberGenerator.new()
	rng.seed = 1234
	for i in range(n):
		var t := float(i) / float(n)
		var f := lerpf(f0, f1, t)
		phase += TAU * f / float(MIX_RATE)
		var v := 0.0
		match kind:
			"sine": v = sin(phase)
			"square": v = 1.0 if sin(phase) > 0.0 else -1.0
			"noise": v = rng.randf_range(-1.0, 1.0) * 0.8 + sin(phase) * 0.3
		# bao hình: vào nhanh, tắt dần
		var env := minf(1.0, t * 40.0) * pow(1.0 - t, 1.6)
		var sample := int(clampf(v * env * amp, -1.0, 1.0) * 32000.0)
		data.encode_s16(i * 2, sample)
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = MIX_RATE
	w.stereo = false
	w.data = data
	return w

## Phát một âm; mỗi tên cách nhau tối thiểu 50ms để đòn dồn dập không thành tiếng ù.
func play(name: String, pitch: float = 1.0) -> void:
	if not sfx_enabled or sfx_volume <= 0.001: return
	var now := Time.get_ticks_msec()
	if now - int(_last_at.get(name, 0)) < 50: return
	_last_at[name] = now
	var stream := _stream(name)
	if stream == null: return
	var target: AudioStreamPlayer = _players[0]
	for p in _players:
		if not p.playing:
			target = p
			break
	target.stream = stream
	target.pitch_scale = pitch
	target.play()

# ---------------------------------------------------------------- Nhạc nền
func song_for(map_id: String, theme: String) -> String:
	if MAP_SONG.has(map_id): return str(MAP_SONG[map_id])
	return theme if SONGS.has(theme) else "city"

## Đổi nhạc nền theo bản đồ; gọi lại với cùng theme thì không làm gì.
func music(map_id: String, theme: String = "") -> void:
	var key := song_for(map_id, theme)
	if not music_enabled:
		_song_key = key   # nhớ để bật lại đúng bản
		return
	if _song_key == key and _song_timer != null and not _song_timer.is_stopped(): return
	_song_key = key
	_song_bar = 0
	_song_next = 0.25
	for p in _music_players: p.stop()
	if not SONGS.has(key): return
	for bi in range((SONGS[key]["chords"] as Array).size()): _request_bar(key, bi)   # dựng trước cả 4 bar ở luồng phụ
	_song_timer.start()
	_on_song_tick()

func stop_music() -> void:
	_song_key = ""
	_song_timer.stop()
	for p in _music_players: p.stop()

func _midi(n: int) -> float:
	return 440.0 * pow(2.0, float(n - 69) / 12.0)

## Tổng hợp 1 bar (4 nhịp) thành mảng byte PCM 16-bit. Hàm THUẦN (chỉ đọc hằng số) nên chạy được ở luồng phụ.
## Mỗi giọng chỉ lặp trong đoạn thời gian của chính nó (không duyệt mọi giọng ở mọi mẫu như trước) và cộng vào bộ đệm float.
func _mix_bar(song: Dictionary, bar_idx: int) -> PackedByteArray:
	var beat := 60.0 / float(song.get("bpm", 84))
	var bar_len := beat * 4.0
	var n := int(bar_len * MIX_RATE)
	var chords: Array = song.get("chords", [[57, 60, 64]])
	var ch: Array = chords[bar_idx % chords.size()]
	# hợp âm pad + bass; mỗi nốt là sin có bao hình riêng
	var voices: Array = []
	for note in ch:
		voices.append([_midi(int(note)), 0.16, 0.0, bar_len])
	voices.append([_midi(int(ch[0]) - 12), 0.30, 0.0, beat * 1.6])
	voices.append([_midi(int(ch[0]) - 12), 0.22, beat * 2.0, beat * 1.6])
	for i in range(8):
		var note := int(ch[i % ch.size()]) + 12
		voices.append([_midi(note), 0.10, beat * 0.5 * float(i), beat * 0.9])
	var mix := PackedFloat32Array()
	mix.resize(n)
	for voice in voices:
		var w := TAU * float(voice[0])
		var amp := float(voice[1])
		var delay := float(voice[2])
		var dur := float(voice[3])
		var i0 := maxi(0, int(ceil(delay * MIX_RATE)))
		var i1 := mini(n - 1, int(floor((delay + dur) * MIX_RATE)))
		for i in range(i0, i1 + 1):
			var dt := float(i) / float(MIX_RATE) - delay
			if dt < 0.0 or dt > dur: continue
			mix[i] += sin(w * dt) * minf(1.0, dt * 30.0) * pow(1.0 - dt / dur, 1.4) * amp
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in range(n):
		data.encode_s16(i * 2, int(clampf(mix[i], -1.0, 1.0) * 26000.0))
	return data

func _wav_from(data: PackedByteArray) -> AudioStreamWAV:
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = MIX_RATE
	w.stereo = false
	w.data = data
	return w

## Giao việc dựng một bar cho luồng phụ (nếu chưa có / chưa đang dựng) — luồng chính không bị đứng khi vào map mới.
func _request_bar(song_key: String, slot: int) -> void:
	var ck := "%s|%d" % [song_key, slot]
	if _bar_cache.has(ck) or _bar_pending.has(ck): return
	_bar_pending[ck] = true
	var song: Dictionary = SONGS[song_key]
	WorkerThreadPool.add_task(func() -> void:
		var data := _mix_bar(song, slot)
		_bar_mutex.lock()
		_bar_done[ck] = data
		_bar_mutex.unlock())

## Nhận các bar luồng phụ đã dựng xong (chạy ở luồng chính, mỗi tick nhạc).
func _collect_bars() -> void:
	_bar_mutex.lock()
	var done := _bar_done
	_bar_done = {}
	_bar_mutex.unlock()
	for ck in done.keys():
		_bar_cache[ck] = _wav_from(done[ck])
		_bar_pending.erase(ck)

func _on_song_tick() -> void:
	_collect_bars()
	if not music_enabled or _song_key.is_empty() or not SONGS.has(_song_key): return
	var song: Dictionary = SONGS[_song_key]
	var bar_len := 60.0 / float(song.get("bpm", 84)) * 4.0
	# _song_next = số giây còn lại tới bar kế. Mỗi tick 0.25s; khi còn < 0.25s thì xếp bar mới.
	_song_next -= 0.25
	var tries := 0
	while _song_next <= 0.0 and tries < 2:
		var p: AudioStreamPlayer = null
		for q in _music_players:
			if not q.playing: p = q; break
		if p == null: break
		var chords: Array = song.get("chords", [[57, 60, 64]])
		var bar_slot := _song_bar % chords.size()
		var ck := "%s|%d" % [_song_key, bar_slot]
		var stream: AudioStreamWAV = _bar_cache.get(ck, null)
		if stream == null:
			_request_bar(_song_key, bar_slot)   # chưa dựng xong ở luồng phụ: đợi tick sau (không đứng hình)
			_song_next = 0.0
			break
		p.stream = stream
		p.play()
		_song_bar += 1
		_song_next += bar_len
		tries += 1
