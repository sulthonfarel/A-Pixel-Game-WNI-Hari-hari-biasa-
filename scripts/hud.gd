class_name HUD
extends Control
## Waktu, uang, bar status, tenggat tugas, prompt interaksi, banner lokasi, dan toast.

@onready var _panel: PanelContainer = %Panel
@onready var _ikon: HudIkon = %Ikon
@onready var _top: Label = %Top
@onready var _hari_bar: ProgressBar = %HariBar
@onready var _uang: Label = %Uang
@onready var _tugas: Label = %Tugas
@onready var _listrik: Label = %Listrik
@onready var _lokasi: Label = %Lokasi
@onready var _prompt: Label = %Prompt
@onready var _toasts: VBoxContainer = %Toasts
@onready var _banner_box: VBoxContainer = %BannerBox
@onready var _banner: Label = %Banner
@onready var _banner_sub: Label = %BannerSub
var _bars: Dictionary = {}
var _nilai: Dictionary = {"Energi": -1, "Kenyang": -1, "Mood": -1}
var _nama_lokasi: String = ""
var _banner_tw: Tween = null
var _uang_tampil: float = -1.0
var _uang_target: int = 0
var _uang_flash: float = 0.0
var _t: float = 0.0


func _ready() -> void:
	_bars = {"Energi": %BarEnergi, "Kenyang": %BarKenyang, "Mood": %BarMood}


func set_lokasi(nama: String) -> void:
	_nama_lokasi = nama


func set_panel_visible(v: bool) -> void:
	_panel.visible = v


func set_prompt(t: String) -> void:
	_prompt.text = t


## Banner besar di tengah atas saat memasuki lokasi.
func show_banner(judul: String, sub: String) -> void:
	_banner.text = judul
	_banner_sub.text = sub
	if _banner_tw != null:
		_banner_tw.kill()
	_banner_box.modulate.a = 0.0
	_banner_tw = create_tween()
	_banner_tw.tween_property(_banner_box, "modulate:a", 1.0, 0.35)
	_banner_tw.tween_interval(1.8)
	_banner_tw.tween_property(_banner_box, "modulate:a", 0.0, 0.7)


func _process(delta: float) -> void:
	_t += delta
	var vs: Vector2 = get_viewport_rect().size
	_lokasi.position = Vector2(vs.x - 156.0, 6.0)
	_prompt.position = Vector2(vs.x * 0.5 - 150.0, vs.y - 24.0)
	_prompt.modulate.a = 0.82 + 0.18 * sin(_t * 4.0)
	_toasts.position = Vector2(vs.x - 236.0, 26.0)
	_banner_box.position = Vector2(vs.x * 0.5 - 160.0, 40.0)
	_banner_box.custom_minimum_size = Vector2(320, 0)
	_top.text = "Hari %d • %s • %s" % [TimeManager.day, TimeManager.nama_hari(), TimeManager.jam_str()]
	_hari_bar.value = TimeManager.minutes
	var jam: int = TimeManager.jam()
	_ikon.mode = 3 if TimeManager.raining else (0 if (jam >= 6 and jam < 17) else (1 if jam < 19 and jam >= 17 else 2))
	# uang berputar naik/turun
	if _uang_tampil < 0.0:
		_uang_tampil = float(GameState.uang)
	if GameState.uang != _uang_target:
		_uang_flash = 1.0 if GameState.uang > _uang_target else -1.0
		_uang_target = GameState.uang
	_uang_tampil = move_toward(_uang_tampil, float(GameState.uang), maxf(800.0, absf(float(GameState.uang) - _uang_tampil) * 6.0 * delta))
	_uang_flash = move_toward(_uang_flash, 0.0, delta * 1.5)
	var u: String = GameData.rp(int(_uang_tampil))
	if GameState.utang > 0:
		u += "  (utang %s)" % GameData.rp(GameState.utang)
	_uang.text = u
	var dasar := Color("#9be37a")
	if _uang_flash > 0.0:
		_uang.add_theme_color_override("font_color", dasar.lerp(Color.WHITE, _uang_flash))
	elif _uang_flash < 0.0:
		_uang.add_theme_color_override("font_color", dasar.lerp(Color("#ff6a5a"), -_uang_flash))
	else:
		_uang.add_theme_color_override("font_color", dasar)
	_update_bar("Energi", GameState.energi)
	_update_bar("Kenyang", GameState.kenyang)
	_update_bar("Mood", GameState.mood)
	_tugas.text = _tenggat()
	var l: int = Daily.listrik_hari()
	_listrik.visible = l <= 2
	_listrik.text = "Listrik PADAM" if l == 0 else "Token listrik: %d hari" % l
	_lokasi.text = _nama_lokasi + (" • Hujan" if TimeManager.raining else "")


func _update_bar(n: String, v: int) -> void:
	var pb: ProgressBar = _bars[n]
	var lama: int = int(_nilai[n])
	if lama >= 0 and v != lama:
		var tw := pb.create_tween()
		pb.modulate = Color(1.6, 1.6, 1.6) if v > lama else Color(1.8, 0.7, 0.7)
		tw.tween_property(pb, "modulate", Color.WHITE, 0.4)
	_nilai[n] = v
	pb.value = move_toward(pb.value, float(v), 90.0 * get_process_delta_time() + 0.5)
	var fl: StyleBoxFlat = pb.get_theme_stylebox("fill") as StyleBoxFlat
	if fl != null:
		var w: Color = pb.get_meta("warna")
		fl.bg_color = w.lerp(Color("#ff4a3a"), 0.5 + 0.5 * sin(_t * 8.0)) if v < 20 else w


func _tenggat() -> String:
	for t in GameData.TUGAS:
		var st: Dictionary = GameState.tugas[t["id"]]
		if bool(st["dikumpul"]):
			continue
		if TimeManager.day < int(t["mulai"]):
			continue
		var sisa: int = int(t["tenggat"]) - TimeManager.day
		var ket: String = "H-%d" % sisa if sisa >= 0 else "TELAT"
		if sisa == 0:
			ket = "HARI INI"
		return "Tugas: %s (%s)" % [str(t["nama"]).left(18) + "…", ket]
	return "Tugas: semua beres"


func toast(text: String) -> void:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(230, 0)
	l.modulate.a = 0.0
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 5)
	_toasts.add_child(l)
	while _toasts.get_child_count() > 4:
		var old: Node = _toasts.get_child(0)
		_toasts.remove_child(old)
		old.queue_free()
	var tw := l.create_tween()
	tw.tween_property(l, "modulate:a", 1.0, 0.18)
	tw.tween_interval(3.2)
	tw.tween_property(l, "modulate:a", 0.0, 0.6)
	tw.tween_callback(l.queue_free)
