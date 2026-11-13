extends Node
## Audio prosedural: semua suara (efek, hujan, jangkrik, burung, musik) disintesis lewat kode,
## jadi proyek tidak membutuhkan berkas audio apa pun.
## Pemakaian: Sfx.play("click"), Sfx.set_ambience(outdoor, raining, jam).

const RATE := 22050
const MUSIC_RATE := 11025
const SETTINGS_PATH := "user://wni_settings.cfg"

var vol_musik: float = 0.5
var vol_efek: float = 0.8
var fullscreen: bool = false

var _cache: Dictionary = {}
var _pool: Array = []
var _pool_i: int = 0
var _rain: AudioStreamPlayer
var _cricket: AudioStreamPlayer
var _mus: Dictionary = {}              # "day"/"night" -> AudioStreamPlayer
var _lv: Dictionary = {"rain": 0.0, "cricket": 0.0, "day": 0.0, "night": 0.0}
var _tg: Dictionary = {"rain": 0.0, "cricket": 0.0, "day": 0.0, "night": 0.0}
var _thread: Thread = null
var _gen: Dictionary = {}
var _bird_t: float = 5.0
var _amb: Dictionary = {"outdoor": false, "rain": false, "jam": 6}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_settings()
	_setup_bus()
	for i in range(8):
		_pool.append(_mk_player("Efek"))
	_buat_efek()
	_rain = _mk_player("Efek")
	_rain.stream = _wav(_loopify(_make_rain(), 2400), RATE, true)
	_cricket = _mk_player("Efek")
	_cricket.stream = _wav(_make_cricket(), RATE, true)
	for p in [_rain, _cricket]:
		p.volume_db = -80.0
		p.play()
	apply_settings()
	_thread = Thread.new()
	_thread.start(_gen_music)


func _exit_tree() -> void:
	if _thread != null and _thread.is_started():
		_thread.wait_to_finish()


# ---------------------------------------------------------------- pengaturan
func _setup_bus() -> void:
	for n in ["Musik", "Efek"]:
		if AudioServer.get_bus_index(n) == -1:
			AudioServer.add_bus()
			var i: int = AudioServer.bus_count - 1
			AudioServer.set_bus_name(i, n)
			AudioServer.set_bus_send(i, "Master")


func _load_settings() -> void:
	var cf := ConfigFile.new()
	if cf.load(SETTINGS_PATH) != OK:
		return
	vol_musik = clampf(float(cf.get_value("audio", "musik", 0.5)), 0.0, 1.0)
	vol_efek = clampf(float(cf.get_value("audio", "efek", 0.8)), 0.0, 1.0)
	fullscreen = bool(cf.get_value("layar", "penuh", false))


func simpan_pengaturan() -> void:
	var cf := ConfigFile.new()
	cf.set_value("audio", "musik", vol_musik)
	cf.set_value("audio", "efek", vol_efek)
	cf.set_value("layar", "penuh", fullscreen)
	cf.save(SETTINGS_PATH)


func apply_settings() -> void:
	var im: int = AudioServer.get_bus_index("Musik")
	var ie: int = AudioServer.get_bus_index("Efek")
	if im >= 0:
		AudioServer.set_bus_volume_db(im, linear_to_db(maxf(vol_musik, 0.0001)))
	if ie >= 0:
		AudioServer.set_bus_volume_db(ie, linear_to_db(maxf(vol_efek, 0.0001)))
	var mode: int = DisplayServer.window_get_mode()
	if fullscreen and mode != DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	elif not fullscreen and mode == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)


# ---------------------------------------------------------------- API
func play(nama: String, vol: float = 1.0, pitch: float = 1.0) -> void:
	if not _cache.has(nama) or _pool.is_empty():
		return
	var p: AudioStreamPlayer = _pool[_pool_i]
	_pool_i = (_pool_i + 1) % _pool.size()
	p.stream = _cache[nama]
	p.volume_db = linear_to_db(maxf(vol, 0.0001))
	p.pitch_scale = pitch
	p.play()


## Atur suasana: di luar/dalam ruangan, hujan, dan jam (untuk musik siang/malam & jangkrik).
func set_ambience(outdoor: bool, raining: bool, jam: int) -> void:
	_amb = {"outdoor": outdoor, "rain": raining, "jam": jam}
	var malam: bool = jam >= 18 or jam < 5
	_tg["rain"] = (0.55 if outdoor else 0.2) if raining else 0.0
	_tg["cricket"] = 0.4 if (malam and outdoor and not raining) else 0.0
	_tg["day"] = 0.0 if malam else (0.55 if raining else 0.8)
	_tg["night"] = (0.8 if not raining else 0.55) if malam else 0.0


# ---------------------------------------------------------------- proses
func _process(delta: float) -> void:
	if _thread != null and _thread.is_started() and not _thread.is_alive():
		_thread.wait_to_finish()
		_mulai_musik()
	var players: Dictionary = {"rain": _rain, "cricket": _cricket}
	for k in _mus.keys():
		players[k] = _mus[k]
	for k in players.keys():
		var p: AudioStreamPlayer = players[k]
		var cur: float = float(_lv[k])
		cur = move_toward(cur, float(_tg[k]), delta * 0.5)
		_lv[k] = cur
		p.volume_db = linear_to_db(maxf(cur, 0.0001)) if cur > 0.003 else -80.0
	# kicau burung acak di siang hari, di luar ruangan, tanpa hujan
	var jam: int = int(_amb["jam"])
	if bool(_amb["outdoor"]) and not bool(_amb["rain"]) and jam >= 6 and jam < 17:
		_bird_t -= delta
		if _bird_t <= 0.0:
			_bird_t = randf_range(5.0, 14.0)
			play("burung1" if randf() < 0.5 else "burung2", 0.35, randf_range(0.9, 1.15))


func _mulai_musik() -> void:
	for k in ["day", "night"]:
		if not _gen.has(k):
			continue
		var p := _mk_player("Musik")
		p.stream = _wav(_gen[k], MUSIC_RATE, true)
		p.volume_db = -80.0
		p.play()
		_mus[k] = p


func _mk_player(bus: String) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.bus = bus
	add_child(p)
	return p


# ---------------------------------------------------------------- sintesis dasar
func _wav(f: PackedFloat32Array, rate: int, loop: bool = false) -> AudioStreamWAV:
	var b := PackedByteArray()
	b.resize(f.size() * 2)
	for i in range(f.size()):
		b.encode_s16(i * 2, int(clampf(f[i], -1.0, 1.0) * 32000.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = rate
	w.stereo = false
	w.data = b
	if loop:
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_begin = 0
		w.loop_end = f.size()
	return w


func _loopify(a: PackedFloat32Array, fade: int) -> PackedFloat32Array:
	var n: int = a.size() - fade
	var o := PackedFloat32Array()
	o.resize(n)
	for i in range(n):
		o[i] = a[i]
	for i in range(fade):
		var w: float = float(i) / float(fade)
		o[i] = o[i] * w + a[n + i] * (1.0 - w)
	return o


func _tone(f0: float, f1: float, dur: float, vol: float, shape: int = 0, atk: float = 0.004, dec: float = 4.0, rate: int = RATE) -> PackedFloat32Array:
	var n: int = int(dur * float(rate))
	var a := PackedFloat32Array()
	a.resize(n)
	var ph: float = 0.0
	for i in range(n):
		var t: float = float(i) / float(n)
		ph += TAU * lerpf(f0, f1, t) / float(rate)
		var s: float = sin(ph)
		if shape == 1:
			s = asin(s) * 2.0 / PI
		elif shape == 2:
			s = 1.0 if s > 0.0 else -1.0
		var env: float = minf(1.0, float(i) / maxf(1.0, atk * float(rate))) * exp(-dec * t)
		a[i] = s * env * vol
	return a


func _noise(dur: float, vol: float, lp: float, dec: float, sd: int) -> PackedFloat32Array:
	var n: int = int(dur * float(RATE))
	var a := PackedFloat32Array()
	a.resize(n)
	var rng := RandomNumberGenerator.new()
	rng.seed = sd
	var y: float = 0.0
	for i in range(n):
		y += lp * (rng.randf_range(-1.0, 1.0) - y)
		var t: float = float(i) / float(n)
		var env: float = minf(1.0, float(i) / 60.0) * exp(-dec * t)
		a[i] = y * env * vol
	return a


func _mix(dst: PackedFloat32Array, src: PackedFloat32Array, offset: int) -> PackedFloat32Array:
	var need: int = offset + src.size()
	if dst.size() < need:
		dst.resize(need)
	for i in range(src.size()):
		dst[offset + i] += src[i]
	return dst


func _seq(parts: Array) -> PackedFloat32Array:
	## parts: [[detik_mulai, PackedFloat32Array], ...]
	var o := PackedFloat32Array()
	for p in parts:
		o = _mix(o, p[1], int(float(p[0]) * float(RATE)))
	return o


# ---------------------------------------------------------------- daftar efek
func _buat_efek() -> void:
	_cache["click"] = _wav(_tone(1200.0, 900.0, 0.05, 0.28, 1, 0.002, 5.0), RATE)
	_cache["tick"] = _wav(_tone(760.0, 700.0, 0.025, 0.14, 1, 0.002, 6.0), RATE)
	_cache["blip"] = _wav(_tone(430.0, 380.0, 0.032, 0.13, 1, 0.002, 4.5), RATE)
	_cache["pop"] = _wav(_tone(520.0, 900.0, 0.07, 0.2, 0, 0.003, 4.0), RATE)
	_cache["coin"] = _wav(_seq([[0.0, _tone(988.0, 988.0, 0.08, 0.26, 1, 0.002, 3.0)], [0.07, _tone(1319.0, 1319.0, 0.22, 0.26, 1, 0.002, 4.5)]]), RATE)
	_cache["chime"] = _wav(_seq([[0.0, _tone(523.0, 523.0, 0.18, 0.2, 0, 0.004, 3.5)], [0.09, _tone(659.0, 659.0, 0.18, 0.2, 0, 0.004, 3.5)], [0.18, _tone(784.0, 784.0, 0.18, 0.2, 0, 0.004, 3.5)], [0.27, _tone(1047.0, 1047.0, 0.4, 0.22, 0, 0.004, 4.0)]]), RATE)
	_cache["alert"] = _wav(_seq([[0.0, _tone(440.0, 440.0, 0.12, 0.22, 1, 0.004, 3.0)], [0.14, _tone(330.0, 330.0, 0.2, 0.22, 1, 0.004, 3.5)]]), RATE)
	_cache["error"] = _wav(_tone(220.0, 160.0, 0.14, 0.24, 2, 0.003, 4.0), RATE)
	_cache["step"] = _wav(_noise(0.06, 0.5, 0.28, 5.0, 11), RATE)
	_cache["door"] = _wav(_seq([[0.0, _noise(0.2, 0.55, 0.12, 4.0, 21)], [0.0, _tone(95.0, 60.0, 0.18, 0.4, 0, 0.003, 5.0)]]), RATE)
	_cache["page"] = _wav(_noise(0.09, 0.3, 0.6, 5.0, 31), RATE)
	_cache["sleep"] = _wav(_seq([[0.0, _tone(659.0, 659.0, 0.25, 0.18, 0, 0.01, 3.0)], [0.22, _tone(523.0, 523.0, 0.25, 0.18, 0, 0.01, 3.0)], [0.44, _tone(392.0, 392.0, 0.6, 0.18, 0, 0.01, 3.0)]]), RATE)
	_cache["bell"] = _wav(_seq([[0.0, _tone(523.0, 523.0, 1.0, 0.2, 0, 0.01, 3.0)], [0.0, _tone(1046.0, 1046.0, 0.8, 0.07, 0, 0.01, 4.0)], [0.55, _tone(659.0, 659.0, 1.1, 0.2, 0, 0.01, 3.0)]]), RATE)
	_cache["thunder"] = _wav(_seq([[0.0, _noise(2.4, 0.85, 0.035, 1.6, 41)], [0.0, _tone(55.0, 38.0, 2.0, 0.35, 0, 0.05, 2.0)]]), RATE)
	_cache["burung1"] = _wav(_seq([[0.0, _tone(2700.0, 3500.0, 0.07, 0.2, 0, 0.005, 2.5)], [0.1, _tone(3500.0, 2600.0, 0.09, 0.2, 0, 0.005, 2.5)], [0.24, _tone(2900.0, 3700.0, 0.06, 0.18, 0, 0.005, 2.5)]]), RATE)
	_cache["burung2"] = _wav(_seq([[0.0, _tone(3200.0, 2400.0, 0.1, 0.18, 0, 0.005, 2.5)], [0.14, _tone(2400.0, 3300.0, 0.08, 0.18, 0, 0.005, 2.5)]]), RATE)


func _make_rain() -> PackedFloat32Array:
	var n: int = int(2.4 * float(RATE))
	var a := PackedFloat32Array()
	a.resize(n)
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var y: float = 0.0
	var y2: float = 0.0
	for i in range(n):
		var w: float = rng.randf_range(-1.0, 1.0)
		y += 0.30 * (w - y)
		y2 += 0.03 * (w - y2)
		a[i] = (y * 0.5 + y2 * 1.6) * 0.32
	return a


func _make_cricket() -> PackedFloat32Array:
	var n: int = int(3.0 * float(RATE))
	var a := PackedFloat32Array()
	a.resize(n)
	for c in range(2):
		var f: float = 4200.0 + 330.0 * float(c)
		var period: float = 0.6 if c == 0 else 0.75
		var ph: float = 0.0
		for i in range(n):
			var t: float = float(i) / float(RATE)
			var tm: float = fmod(t, period)
			var s: float = 0.0
			if tm < 0.30:
				var env: float = sin(fmod(tm, 0.075) / 0.075 * PI)
				s = env * env
			ph += TAU * f / float(RATE)
			a[i] += sin(ph) * s * 0.07
	return a


# ---------------------------------------------------------------- musik (dibangkitkan di thread)
func _gen_music() -> void:
	_gen = {"day": _compose(true), "night": _compose(false)}


static func _mtof(m: float) -> float:
	return 440.0 * pow(2.0, (m - 69.0) / 12.0)


func _compose(day: bool) -> PackedFloat32Array:
	var rate: int = MUSIC_RATE
	var bpm: float = 72.0 if day else 58.0
	var beat: float = 60.0 / bpm
	var beats: int = 16
	var n: int = int(beat * float(beats) * float(rate))
	var tail: int = int(1.4 * float(rate))
	var out := PackedFloat32Array()
	out.resize(n + tail)
	var chords: Array = [[48, 52, 55, 59], [45, 48, 52, 55], [41, 45, 48, 52], [43, 47, 50, 52]] if day else [[45, 48, 52, 55], [41, 45, 48, 52], [38, 41, 45, 48], [40, 44, 47, 50]]
	var chord_len: float = beat * 4.0
	var rng := RandomNumberGenerator.new()
	rng.seed = 2468 if day else 1357
	# pad lembut
	for k in range(4):
		var t0: float = float(k) * chord_len
		var span: float = chord_len + 1.0
		var s0: int = int(t0 * float(rate))
		var cnt: int = int(span * float(rate))
		for m in chords[k]:
			var f: float = _mtof(float(m) + 12.0)
			var ph: float = 0.0
			var step: float = TAU * f / float(rate)
			for i in range(cnt):
				var t: float = float(i) / float(rate)
				var env: float = minf(t / 0.9, 1.0) * minf((span - t) / 0.9, 1.0)
				ph += step
				out[s0 + i] += (sin(ph) + 0.28 * sin(ph * 2.0)) * env * 0.045
	# bas
	for k in range(4):
		for b in [0.0, 2.0]:
			var t0: float = float(k) * chord_len + b * beat
			var s0: int = int(t0 * float(rate))
			var f: float = _mtof(float(chords[k][0]) - 12.0)
			var ph: float = 0.0
			var cnt: int = int(1.3 * float(rate))
			for i in range(cnt):
				var t: float = float(i) / float(rate)
				ph += TAU * f / float(rate)
				out[s0 + i] += sin(ph) * exp(-t * 2.6) * 0.13
	# petikan acak (pentatonik dari nada akor)
	var prob: float = 0.55 if day else 0.32
	for st in range(beats * 2):
		if rng.randf() > prob:
			continue
		var t0: float = float(st) * beat * 0.5
		var k: int = mini(int(t0 / chord_len), 3)
		var note: int = int(chords[k][rng.randi() % 4]) + 24
		var f: float = _mtof(float(note))
		var s0: int = int(t0 * float(rate))
		var cnt: int = int(1.1 * float(rate))
		var ph: float = 0.0
		for i in range(cnt):
			var t: float = float(i) / float(rate)
			ph += TAU * f / float(rate)
			var w: float = sin(ph) + 0.25 * sin(ph * 2.0) + 0.08 * sin(ph * 3.0)
			out[s0 + i] += w * exp(-t * 4.5) * minf(t / 0.006, 1.0) * 0.075
	# lipat ekor ke awal supaya loop mulus
	for i in range(tail):
		out[i] += out[n + i]
	out.resize(n)
	# gema tipis
	var echo := PackedFloat32Array()
	echo.resize(n)
	var d1: int = int(0.29 * float(rate))
	var d2: int = int(0.58 * float(rate))
	var peak: float = 0.0001
	for i in range(n):
		var v: float = out[i] + out[(i - d1 + n) % n] * 0.3 + out[(i - d2 + n) % n] * 0.14
		echo[i] = v
		peak = maxf(peak, absf(v))
	var gain: float = 0.32 / peak
	for i in range(n):
		echo[i] *= gain
	return echo
