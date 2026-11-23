extends Node
## Âm thanh: ưu tiên file trong assets/audio/<tên>.ogg|wav; thiếu thì TỔNG HỢP tiếng đơn giản bằng code
## (không cần file ngoài). Tên âm: hit, crit, hurt, cast, pickup, coin, levelup, portal, ui, death, error.

const AUDIO_DIR := "res://assets/audio"
const MIX_RATE := 22050

var _players: Array[AudioStreamPlayer] = []
var _cache: Dictionary = {}
var volume: float = 0.7
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

func _ready() -> void:
	volume = Settings.volume
	for i in 8:
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		_players.append(p)
	set_volume(volume)

func set_volume(v: float) -> void:
	volume = clampf(v, 0.0, 1.0)
	for p in _players: p.volume_db = linear_to_db(volume) if volume > 0.001 else -80.0

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
	if volume <= 0.001: return
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
