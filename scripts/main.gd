extends Node
## Orkestrator: membangun dunia & UI, mengatur interaksi, tidur/hari baru, rapat, dan ending.

const FOLDER_PETA := "res://scenes/maps/"
var world: Node2D
var view: LocationView = null
var player: Player
var cam: Camera2D
var mod: CanvasModulate
var hud: HUD
var menu: UIMenu
var dlg: DialogueBox
var fade: ColorRect
var rain: RainOverlay
var busy: bool = true
var started: bool = false
var near: Dictionary = {}
var marker: InteractMarker = null
var vig: ColorRect
var _pop_q: Array = []
var _pop_t: float = 0.0
var _pop_slot: int = 0
var _pop_diam: float = 0.0
var _warn: Dictionary = {"energi": false, "kenyang": false, "mood": false}
var _cek_tutup: bool = false
var _amb_t: float = 0.0
var _vig_t: float = 0.0
var _vig_kuat: float = 0.2
var _kehujanan_info: bool = false
const WAKTU_BANGUN := 360


func _ready() -> void:
	randomize()
	world = $WorldSection/World
	mod = $WorldSection/CanvasModulate
	cam = $WorldSection/World/Camera2D
	view = $WorldSection/World/LocationView as LocationView
	player = $WorldSection/World/Player as Player
	cam.position_smoothing_enabled = true
	cam.position_smoothing_speed = 7.0
	player.setup("dimas", 100)
	player.show_label = false
	var root: Control = $InterfaceSection/Root
	rain = $InterfaceSection/Root/RainOverlay
	vig = $InterfaceSection/Root/Vignette
	hud = $InterfaceSection/Root/HUD
	fade = $InterfaceSection/Root/Fade
	dlg = $InterfaceSection/Root/DialogueBox
	menu = $InterfaceSection/Root/UIMenu
	TimeManager.running = false
	EventBus.toast.connect(hud.toast)
	EventBus.popup.connect(_on_popup)
	EventBus.waktu_maju.connect(_on_waktu)
	EventBus.pencapaian.connect(_on_pencapaian)
	rain.thunder.connect(_on_thunder)
	_load_location("kos_room", "kasur")   # latar untuk layar judul
	hud.set_panel_visible(false)
	EventBus.hour_changed.connect(_on_hour)
	EventBus.rain_changed.connect(_on_rain)
	await _title()


# ================================================================ judul & mulai
func _title() -> void:
	busy = true
	while true:
		var opts: Array = [
			{"id": "baru", "label": "Mulai baru"},
			{"id": "lanjut", "label": "Lanjutkan (simpanan terakhir)", "enabled": SaveSystem.ada()},
			{"id": "keluar", "label": "Keluar"},
		]
		var body: String = "Sampai Akhir Bulan\n\nSebuah game cozy tentang hidup biasa di Bandung Timur: uang tipis, tugas numpuk, hujan sore, dan negara yang terus memberi hal-hal luar biasa pada orang biasa.\n\nKontrol: WASD / panah = jalan • E = interaksi • Tab = ponsel • Enter / Spasi = memilih"
		var r: String = await menu.choose("WNI: HARI-HARI BIASA", body, opts)
		if r == "baru":
			await _mulai_baru()
			return
		elif r == "lanjut":
			if await _lanjut():
				return
		else:
			get_tree().quit()
			return


func _mulai_baru() -> void:
	var nama: String = await menu.ask_text("Nama tokoh", "Siapa nama mahasiswa kita? (bawaan: Dimas)", "Dimas")
	GameState.reset()
	TimeManager.reset()
	Economy.reset()
	nama = nama.strip_edges()
	GameState.player_name = nama if nama != "" else "Dimas"
	NewsSystem.run_day(1)
	await _fade(true)
	started = true
	TimeManager.running = true
	_load_location("kos_room", "kasur")
	await _fade(false)
	DialogueDB.build_intro()
	GameState.ui_open = true
	await dlg.run("intro_1")
	GameState.ui_open = false
	busy = false


func _lanjut() -> bool:
	if not SaveSystem.muat():
		return false
	await _fade(true)
	started = true
	TimeManager.running = true
	var loc: String = SaveSystem.last_loc
	_load_location(loc)
	if SaveSystem.last_pos.x >= 0.0:
		player.position = SaveSystem.last_pos
		cam.position = player.position
		cam.reset_smoothing()
	await _fade(false)
	busy = false
	_banner_lokasi()
	EventBus.toast.emit("Permainan dimuat. Hari ke-%d." % TimeManager.day)
	return true


func _fade(to_black: bool) -> void:
	var tw := create_tween()
	tw.tween_property(fade, "color:a", 1.0 if to_black else 0.0, 0.25)
	await tw.finished


## Memuat scene peta scenes/maps/<loc>.tscn. spawn kosong = titik muncul pertama peta itu.
func _load_location(loc: String, spawn: String = "") -> void:
	if player.get_parent() != null:
		player.get_parent().remove_child(player)
	if view != null:
		world.remove_child(view)
		view.queue_free()
		view = null
	view = (load(FOLDER_PETA + loc + ".tscn") as PackedScene).instantiate() as LocationView
	world.add_child(view)
	view.entities.add_child(player)
	player.view = view
	if spawn == "":
		spawn = view.spawn_pertama()
	player.position = view.posisi_spawn(spawn)
	cam.limit_left = 0
	cam.limit_top = 0
	cam.limit_right = int(view.size_px.x)
	cam.limit_bottom = int(view.size_px.y)
	player.set_sprite(view.spr)
	view.player = player
	marker = view.get_node("InteractMarker") as InteractMarker
	_cek_tutup = false
	cam.position = player.position
	cam.reset_smoothing()
	GameState.lokasi = loc
	hud.set_lokasi(view.nama)


func _pindah(loc: String, spawn: String) -> void:
	await _fade(true)
	_load_location(loc, spawn)
	await _fade(false)
	_banner_lokasi()


func _banner_lokasi() -> void:
	if view == null:
		return
	hud.show_banner(view.nama, "Hari %d • %s • %s" % [TimeManager.day, TimeManager.nama_hari(), TimeManager.jam_str()])


# ================================================================ loop
func _on_hour(h: int) -> void:
	if view != null:
		view.refresh()
	_cek_tutup = true
	if view != null and view.loc_id == "gang" and randf() < 0.55:
		var pool: Array = _ambience(h)
		EventBus.toast.emit(str(pool[randi() % pool.size()]))
	if h == 19 and TimeManager.day == GameData.HARI_RAPAT:
		EventBus.toast.emit("Rapat warga dimulai di Balai RW!")
	elif h == 22:
		EventBus.toast.emit("Sudah malam. Kasur memanggil. Tugas juga, tapi kasur lebih keras suaranya.")
	# kehujanan di luar ruangan
	if TimeManager.raining and view != null and (view.loc_id in GameData.OUTDOOR):
		if GameState.has_flag("payung"):
			GameState.apply_effects({"energi": -1}, true)
		else:
			GameState.apply_effects({"energi": -3, "mood": -1})
			if not _kehujanan_info:
				_kehujanan_info = true
				EventBus.toast.emit("Kehujanan melelahkan. Payung dijual di Warung Madura.")
	Ach.cek()


## Adzan berbunyi tepat pada awal waktu salat (bukan di jam bulat).
func _on_waktu(dari: int, ke: int) -> void:
	for sl in GameData.SALAT:
		var m: int = int(sl["dari"])
		if dari < m and ke >= m:
			Sfx.play("bell", 0.8)
			var jumat: bool = sl["id"] == "zuhur" and GameData.hari_jumat(TimeManager.day)
			var teks: String = "Adzan %s berkumandang dari Masjid Al-Ikhlas." % str(sl["nama"])
			if jumat:
				teks = "Adzan Jumat berkumandang. Jamaah berdatangan ke Masjid Al-Ikhlas."
			elif sl["id"] == "magrib":
				teks = "Adzan Magrib. Langit gang berubah warna, lampu-lampu warung mulai menyala."
			EventBus.toast.emit(teks)


func _on_pencapaian(nama: String) -> void:
	Sfx.play("chime")
	EventBus.toast.emit("Pencapaian: " + nama)


func _on_thunder() -> void:
	var tw := create_tween()
	for i in range(4):
		tw.tween_property(cam, "offset", Vector2(randf_range(-2.5, 2.5), randf_range(-2.0, 2.0)), 0.05)
	tw.tween_property(cam, "offset", Vector2.ZERO, 0.08)


# ---------------------------------------------------------------- teks melayang
func _on_popup(teks: String, warna: Color) -> void:
	_pop_q.append([teks, warna])


func _update_popup(delta: float) -> void:
	_pop_diam += delta
	if _pop_diam > 0.9 and _pop_q.is_empty():
		_pop_slot = 0
	_pop_t -= delta
	if _pop_t > 0.0 or _pop_q.is_empty() or view == null:
		return
	var item: Array = _pop_q.pop_front()
	_pop_t = 0.16
	_pop_diam = 0.0
	var tinggi: float = float(view.spr) * player.scale.y + 12.0 + float(_pop_slot) * 10.0
	_pop_slot = (_pop_slot + 1) % 5
	FloatText.spawn(view, str(item[0]), item[1], player.position + Vector2(0.0, -tinggi))
	Sfx.play("pop", 0.35, 0.9 + float(_pop_slot) * 0.06)


# ---------------------------------------------------------------- warna waktu & vignette
const TINT: Array = [
	[0.0, Color(0.42, 0.45, 0.68)], [5.0, Color(0.62, 0.68, 0.90)], [6.0, Color(0.80, 0.86, 0.98)],
	[7.5, Color(1.0, 0.97, 0.92)], [9.0, Color(1.0, 1.0, 1.0)], [15.5, Color(1.0, 1.0, 1.0)],
	[17.0, Color(1.0, 0.93, 0.82)], [18.2, Color(0.97, 0.78, 0.68)], [19.2, Color(0.68, 0.64, 0.82)],
	[21.0, Color(0.50, 0.52, 0.76)], [24.0, Color(0.42, 0.45, 0.68)],
]


func _tint(h: float) -> Color:
	for i in range(1, TINT.size()):
		var a: Array = TINT[i - 1]
		var b: Array = TINT[i]
		if h <= float(b[0]):
			var t: float = inverse_lerp(float(a[0]), float(b[0]), h)
			return (a[1] as Color).lerp(b[1] as Color, t)
	return TINT[TINT.size() - 1][1]


func _ambience(h: int) -> Array:
	if h < 9:
		return ["Hawa dingin turun dari arah Manglayang. Napas sampai berembun.", "Tukang bubur ayam lewat sambil memukul mangkok: tung, tung, tung.", "Ayam berkokok bersahut-sahutan dari belakang rumah warga."]
	elif h < 15:
		return ["Klakson angkot: tin tin. Entah menyapa, entah menagih penumpang.", "Dari kejauhan: 'Batagor… cuanki…' Gerobaknya masih jauh, perut sudah menengok.", "Motor melintas; knalpotnya meninggalkan bunyi dan kenangan."]
	elif h < 19:
		return ["Awan kelabu bergeser dari arah bukit. Orang-orang menengok jemuran.", "Bau tanah basah dan gorengan: kombinasi paling Bandung.", "Anak-anak pulang sekolah; tas mereka lebih besar dari badan."]
	return ["Lampu warung menyala satu per satu. Dingin menyelinap lewat lengan jaket.", "Dari masjid terdengar tadarus, pelan, seperti selimut bagi gang.", "Bunyi sendok di mangkuk dari gerobak seberang: seseorang sedang menang melawan lapar."]


func _on_rain(r: bool) -> void:
	EventBus.toast.emit("Hujan turun." if r else "Hujan reda.")
	if view != null:
		view.queue_redraw()


func _process(delta: float) -> void:
	if not started or view == null:
		return
	cam.position = player.position
	hud.set_panel_visible(not (dlg.visible or menu.visible))
	var luar: bool = view.loc_id in GameData.OUTDOOR
	var h: float = float(TimeManager.minutes) / 60.0
	var c: Color = _tint(h)
	if TimeManager.raining:
		c = c.darkened(0.12)
	if not luar:
		c = c.lerp(Color.WHITE, 0.55)
		if not Daily.listrik_ada() and (h >= 18.0 or h < 6.0):
			c = c.darkened(0.3)
	mod.color = mod.color.lerp(c, clampf(delta * 3.0, 0.0, 1.0))
	rain.set_cuaca(TimeManager.raining, luar)
	player.umbrella = TimeManager.raining and luar and GameState.has_flag("payung")
	_update_vignette(delta, h)
	_update_popup(delta)
	_amb_t -= delta
	if _amb_t <= 0.0:
		_amb_t = 0.5
		Sfx.set_ambience(luar, TimeManager.raining, TimeManager.jam())
	_cek_peringatan()
	if busy:
		hud.set_prompt("")
		marker.sembunyi()
		return
	near = _cari_dekat()
	var tepi: Dictionary = _tepi_dekat()
	if not near.is_empty():
		hud.set_prompt(str(near["label"]))
		marker.tunjuk(_titik_marker(near))
	elif not tepi.is_empty():
		hud.set_prompt(str(tepi["label"]))
		marker.sembunyi()
	else:
		hud.set_prompt("")
		marker.sembunyi()
	if not tepi.is_empty() and bool(tepi["tembus"]):
		_lewat_tepi(tepi)
		return
	if TimeManager.minutes >= 1440:
		_tidur(true)
		return
	if GameState.energi <= 0:
		_pingsan()
		return
	if _cek_tutup:
		_cek_tutup = false
		if view.loc_id in GameData.INTERIOR_JAM and not GameData.buka(view.loc_id, TimeManager.day, TimeManager.jam()):
			_usir()


func _titik_marker(it: Dictionary) -> Vector2:
	if it["kind"] == "npc":
		return it["pos"] + Vector2(0.0, -float(view.spr) - 18.0)
	var r: Rect2 = it["rect"]
	return Vector2(r.position.x + r.size.x * 0.5, maxf(r.position.y, r.end.y - 60.0) - 2.0)


func _update_vignette(delta: float, h: float) -> void:
	_vig_t += delta
	var malam: bool = h >= 19.0 or h < 5.5
	var kuat: float = 0.2 + (0.2 if malam else 0.0) + (0.06 if TimeManager.raining else 0.0)
	var warna := Color(0.0, 0.0, 0.06)
	var rendah: float = minf(float(GameState.energi), float(GameState.kenyang))
	if rendah < 22.0:
		var p: float = 0.5 + 0.5 * sin(_vig_t * 3.0)
		kuat += (22.0 - rendah) / 22.0 * 0.3 * p
		warna = warna.lerp(Color(0.5, 0.0, 0.0), (22.0 - rendah) / 22.0)
	var m: ShaderMaterial = vig.material as ShaderMaterial
	_vig_kuat = lerpf(_vig_kuat, kuat, clampf(delta * 4.0, 0.0, 1.0))
	m.set_shader_parameter("strength", _vig_kuat)
	m.set_shader_parameter("tint", warna)


## Peringatan sekali saat stat jatuh ke level kritis.
func _cek_peringatan() -> void:
	var kasus: Array = [
		["energi", GameState.energi, 25, "Matamu berat sekali. Cari kasur, kopi, atau air putih."],
		["kenyang", GameState.kenyang, 20, "Perutmu berbunyi keras. Waktunya makan sesuatu."],
		["mood", GameState.mood, 20, "Mood menipis. Obrolan, kucing, atau salat bisa membantu."],
	]
	for k in kasus:
		var key: String = str(k[0])
		if int(k[1]) < int(k[2]):
			if not bool(_warn[key]):
				_warn[key] = true
				Sfx.play("alert", 0.6)
				EventBus.toast.emit(str(k[3]))
		elif int(k[1]) >= int(k[2]) + 10:
			_warn[key] = false


func _pingsan() -> void:
	busy = true
	GameState.ui_open = true
	Sfx.play("alert")
	await _fade(true)
	GameState.apply_effects({"waktu": 150, "mood": -6}, true)
	GameState.energi = 35
	if view != null:
		view.refresh()
	await _fade(false)
	await _say("", "Dunia berputar, lalu gelap. Beberapa saat kemudian seseorang menyodorkan air putih. Badan lemas, tapi masih utuh. Besok-besok, tidur lebih awal ya.")
	GameState.ui_open = false
	busy = false


func _usir() -> void:
	busy = true
	GameState.ui_open = true
	var nama: String = view.nama
	var spawn: String = "fotokopi" if view.loc_id == "fotokopi" else "kopi"
	EventBus.toast.emit("%s sudah tutup. Kamu dipersilakan keluar dengan sopan." % nama)
	Sfx.play("door")
	await _pindah("jalan", spawn)
	GameState.ui_open = false
	busy = false


func _tepi_dekat() -> Dictionary:
	var p: float = player.position.x
	var xmax: float = view.xmax()
	var kanan: Dictionary = view.tepi("kanan")
	if not kanan.is_empty() and p >= xmax - 70.0:
		kanan["tembus"] = p >= xmax - 4.0
		return kanan
	var kiri: Dictionary = view.tepi("kiri")
	if not kiri.is_empty() and p <= 80.0:
		kiri["tembus"] = p <= 14.0
		return kiri
	return {}


func _lewat_tepi(t: Dictionary) -> void:
	busy = true
	GameState.ui_open = true
	await _pindah(str(t["ke"]), str(t["spawn"]))
	GameState.ui_open = false
	busy = false


func _cari_dekat() -> Dictionary:
	var p: Vector2 = player.position
	var best: Dictionary = {}
	var best_d: float = 1e9
	for it in view.interactables:
		var d: float = 0.0
		var batas: float = 22.0 * view.skala
		if it["kind"] == "npc":
			d = p.distance_to(it["pos"] + Vector2(0, -6))
			batas = 46.0 * view.skala
		else:
			var r: Rect2 = it["rect"]
			d = p.distance_to(Vector2(clampf(p.x, r.position.x, r.end.x), clampf(p.y, r.position.y, r.end.y)))
		if d < batas and d < best_d:
			best = it
			best_d = d
	return best


func _unhandled_input(event: InputEvent) -> void:
	if not started or busy:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_E:
			_interact()
		elif event.keycode == KEY_TAB:
			get_viewport().set_input_as_handled()
			_phone()
		elif event.keycode == KEY_ESCAPE:
			get_viewport().set_input_as_handled()
			_jeda()


func _interact() -> void:
	if near.is_empty():
		return
	busy = true
	GameState.ui_open = true
	await _handle(near)
	GameState.ui_open = false
	busy = false
	if view != null:
		view.refresh()
	Ach.cek()


func _jeda() -> void:
	busy = true
	GameState.ui_open = true
	while true:
		var r: String = await menu.choose("Jeda", "Hari %d, %s. Waktu berhenti selama menu ini terbuka." % [TimeManager.day, TimeManager.jam_str()], [
			{"id": "lanjut", "label": "Lanjut bermain"},
			{"id": "simpan", "label": "Simpan sekarang (di lokasi ini)"},
			{"id": "atur", "label": "Pengaturan suara & layar"},
			{"id": "judul", "label": "Simpan & kembali ke layar judul"},
		], "lanjut")
		if r == "lanjut":
			break
		elif r == "simpan":
			var ok: bool = SaveSystem.simpan(view.loc_id, player.position)
			EventBus.toast.emit("Permainan disimpan." if ok else "Gagal menyimpan permainan.")
			Sfx.play("chime" if ok else "error")
		elif r == "atur":
			await _pengaturan()
		elif r == "judul":
			SaveSystem.simpan(view.loc_id, player.position)
			TimeManager.running = false
			get_tree().reload_current_scene()
			return
	GameState.ui_open = false
	busy = false


func _pengaturan() -> void:
	while true:
		var pm: int = int(round(Sfx.vol_musik * 100.0))
		var pe: int = int(round(Sfx.vol_efek * 100.0))
		var r: String = await menu.choose("Pengaturan", "Klik untuk mengubah nilai (bertingkat 20%).", [
			{"id": "musik", "label": "Volume musik & suasana: %d%%" % pm},
			{"id": "efek", "label": "Volume efek suara: %d%%" % pe},
			{"id": "layar", "label": "Layar penuh: %s" % ("ya" if Sfx.fullscreen else "tidak")},
			{"id": "kembali", "label": "Kembali"},
		], "kembali")
		if r == "kembali":
			break
		elif r == "musik":
			Sfx.vol_musik = fposmod(Sfx.vol_musik + 0.2, 1.2)
			if Sfx.vol_musik > 1.0:
				Sfx.vol_musik = 0.0
		elif r == "efek":
			Sfx.vol_efek = fposmod(Sfx.vol_efek + 0.2, 1.2)
			if Sfx.vol_efek > 1.0:
				Sfx.vol_efek = 0.0
		elif r == "layar":
			Sfx.fullscreen = not Sfx.fullscreen
		Sfx.apply_settings()
	Sfx.simpan_pengaturan()


func _phone() -> void:
	busy = true
	GameState.ui_open = true
	Sfx.play("page")
	player.pose = Player.FRAME_PONSEL
	await _ponsel()
	player.pose = -1
	GameState.ui_open = false
	busy = false


func _handle(item: Dictionary) -> void:
	match item["kind"]:
		"pintu":
			var ke: String = str(item["ke"])
			if not GameData.buka(ke, TimeManager.day, TimeManager.jam()):
				EventBus.toast.emit("Tutup. " + GameData.jam_buka(ke))
				return
			Sfx.play("door", 0.8)
			await _pindah(ke, str(item["spawn"]))
		"npc":
			await _bicara(str(item["id"]))
		"objek":
			await _objek(str(item["id"]))


func _bicara(npc: String) -> void:
	var start: String = DialogueDB.hub(npc)
	player.pose = Player.FRAME_BICARA
	var act: String = await dlg.run(start)
	player.pose = -1
	if act != "":
		await _aksi(act)


func _info(title: String, body: String) -> void:
	await menu.choose(title, body, [{"id": "x", "label": "Tutup"}], "x")


func _say(speaker: String, text: String, eff: Dictionary = {}) -> void:
	await dlg.run(DialogueDB.solo(speaker, text, eff))


# ================================================================ aksi dari dialog
func _aksi(a: String) -> void:
	match a:
		"menu_tati":
			await _menu_makan("Warteg Bu Tati", GameData.MENU_WARUNG, 20, "tati")
		"menu_mira":
			await _menu_makan("Kopi Teh Mira", GameData.MENU_MIRA, 25, "mira")
		"menu_asep":
			await _belanja("asep")
		"menu_imam":
			await _belanja("imam")
		"menu_foto":
			await _fotokopi()
		"tv":
			await _tv()
		"kerja_kopi":
			await _kerja("kopi")
		"bayar_utang":
			if GameState.uang >= GameState.utang:
				var u: int = GameState.utang
				GameState.apply_effects({"uang": -u, "utang": -u, "rel": {"tati": 1}})
				await _say("Bu Tati", "Alhamdulillah. Ibu percaya sama kamu, {nama}.")
			else:
				EventBus.toast.emit("Uang belum cukup untuk melunasi utang.")
		"bayar_sewa":
			if GameState.uang >= Daily.sewa_tagihan():
				Sfx.play("coin")
				GameState.apply_effects({"uang": -Daily.sewa_tagihan(), "flag": "sewa_lunas", "rel": {"darto": 1}, "mood": 3})
				await _say("Pak Darto", "Nah, begitu. Kuitansinya saya selipkan di pintu. Jangan lupa buang sampah, ya.")
			else:
				await _say("Pak Darto", "Belum cukup, ya? Saya tunggu sampai tanggal 25. Setelah itu… saya tetap sabar, tapi dengan nada bicara berbeda.")
		"beli_kursi":
			if GameState.uang >= 50000:
				GameState.apply_effects({"uang": -50000, "flag": "kursi", "mood": 3})
				await _say("Pak Darto", "Kursinya agak oleng, tapi punggungmu akan berterima kasih.")
			else:
				EventBus.toast.emit("Uang belum cukup (Rp50.000).")
		"rapat":
			await _rapat()
		"salat_masjid":
			await _salat()
		"menu_ujang":
			await _menu_makan("Gerobak Batagor Mang Ujang", GameData.MENU_UJANG, 15, "ujang")


## Setiap 3 kali membeli dari seorang pedagang, hubungan naik 1 (sampai 5).
func _langganan(npc: String) -> void:
	if npc == "":
		return
	var key: String = "beli_" + npc
	GameState.counters[key] = int(GameState.counters.get(key, 0)) + 1
	if int(GameState.counters[key]) % 3 == 0 and GameState.relasi(npc) < 5:
		GameState.apply_effects({"rel": {npc: 1}})


func _menu_makan(title: String, items: Array, menit: int, npc: String = "") -> void:
	while true:
		var opts: Array = []
		for id in items:
			var it: Dictionary = GameData.ITEMS[id]
			var h: int = Economy.harga(id)
			opts.append({"id": id, "label": "%s — %s" % [it["nama"], GameData.rp(h)], "enabled": GameState.uang >= h})
		opts.append({"id": "selesai", "label": "Selesai"})
		var body: String = "Uang: %s   Kenyang: %d/100   Energi: %d/100" % [GameData.rp(GameState.uang), GameState.kenyang, GameState.energi]
		var r: String = await menu.choose(title, body, opts, "selesai")
		if r == "selesai":
			return
		var it2: Dictionary = GameData.ITEMS[r]
		Sfx.play("coin", 0.7)
		GameState.apply_effects({"uang": -Economy.harga(r), "kenyang": it2["kenyang"], "energi": it2["energi"], "mood": it2["mood"], "waktu": menit})
		_langganan(npc)


func _belanja(npc: String = "asep") -> void:
	while true:
		var opts: Array = []
		for k in GameData.TOKO_MADURA.keys():
			opts.append({"id": k, "label": k})
		opts.append({"id": "selesai", "label": "Selesai belanja"})
		var body: String = "Warung Madura, buka 24 jam. Etalase penuh, plastik menggantung, dan harga yang hafal sendiri kapan harus naik.\nUang: %s" % GameData.rp(GameState.uang)
		var r: String = await menu.choose("Warung Madura", body, opts, "selesai")
		if r == "selesai":
			return
		await _belanja_kat(r, npc)


func _belanja_kat(kat: String, npc: String = "asep") -> void:
	while true:
		var opts: Array = []
		for id in GameData.TOKO_MADURA[kat]:
			var it: Dictionary = GameData.ITEMS[id]
			var h: int = Economy.harga(id)
			var label: String = "%s — %s" % [it["nama"], GameData.rp(h)]
			var ok: bool = GameState.uang >= h
			if it.has("kenyang"):
				label += "  (kenyang +%d, energi +%d)" % [int(it["kenyang"]), int(it["energi"])]
			if it.has("upgrade"):
				if GameState.has_flag(str(it["upgrade"])):
					label += " (sudah punya)"
					ok = false
			elif not Economy.tersedia(id):
				label += " (habis)"
				ok = false
			opts.append({"id": id, "label": label, "enabled": ok})
		opts.append({"id": "kembali", "label": "Kembali"})
		var body: String = "%s\nUang: %s\nPersediaan: mi %d • telur %d • nasi %d • kopi %d • deterjen %d • listrik %s" % [kat, GameData.rp(GameState.uang), GameState.jumlah_inv("mi_instan"), GameState.jumlah_inv("telur"), GameState.jumlah_inv("nasi"), GameState.jumlah_inv("kopi_sachet"), GameState.jumlah_inv("deterjen"), ("PADAM" if Daily.listrik_hari() == 0 else "%d hari" % Daily.listrik_hari())]
		var r: String = await menu.choose(kat, body, opts, "kembali")
		if r == "kembali":
			return
		var it2: Dictionary = GameData.ITEMS[r]
		var eff: Dictionary = {"uang": -Economy.harga(r), "waktu": 3}
		if it2.has("upgrade"):
			eff["flag"] = it2["upgrade"]
			eff["mood"] = int(it2.get("mood_up", 8))
		elif it2.has("kenyang"):
			eff["kenyang"] = it2["kenyang"]
			eff["energi"] = it2["energi"]
			eff["mood"] = it2["mood"]
		elif it2.has("instan"):
			for k in it2["instan"].keys():
				eff[k] = it2["instan"][k]
			if it2.has("counter"):
				eff["counter"] = it2["counter"]
		elif it2.has("inv"):
			eff["inv"] = it2["inv"]
		else:
			eff["inv"] = {r: 1}
		Sfx.play("coin")
		GameState.apply_effects(eff)
		_langganan(npc)
		if it2.has("counter") and it2["counter"].has("listrik"):
			EventBus.toast.emit("Token dimasukkan ke meteran. Listrik menyala %d hari lagi." % Daily.listrik_hari())


# ================================================================ kerja, cetak, kelas
func _kerja(tempat: String) -> void:
	player.pose = Player.FRAME_GARUK
	await _kerja_inner(tempat)
	player.pose = -1


func _kerja_inner(tempat: String) -> void:
	var aktif: Array = []
	for t in GameData.TUGAS:
		var st: Dictionary = GameState.tugas[t["id"]]
		if TimeManager.day >= int(t["mulai"]) and int(st["progress"]) < 100:
			aktif.append(t)
	if aktif.is_empty():
		EventBus.toast.emit("Tidak ada tugas yang perlu dikerjakan sekarang. Itu mencurigakan. Cek ponsel.")
		return
	if GameState.energi < 20:
		EventBus.toast.emit("Energi terlalu rendah. Mata tinggal 5 watt.")
		return
	if tempat == "kopi" and GameState.uang < 3000:
		EventBus.toast.emit("Uang tidak cukup untuk pesan es teh.")
		return
	var opts: Array = []
	for t in aktif:
		var st2: Dictionary = GameState.tugas[t["id"]]
		opts.append({"id": t["id"], "label": "%s — progres %d%% (tenggat hari %d)" % [t["nama"], int(st2["progress"]), int(t["tenggat"])]})
	opts.append({"id": "batal", "label": "Batal"})
	var r: String = await menu.choose("Kerjakan tugas", "Satu sesi = ±2 jam.", opts, "batal")
	if r == "batal":
		return
	var gain: int = 25
	var energi_biaya: int = 15
	var waktu: int = 120
	if tempat == "kos":
		if GameState.has_flag("lampu"):
			gain += 5
		if GameState.has_flag("kursi"):
			energi_biaya -= 4
		if GameState.has_flag("laptop_lemot"):
			waktu += 30
			EventBus.toast.emit("Laptop lemot. Loading bar berjalan seperti kura-kura bijak.")
		if not Daily.listrik_ada():
			waktu += 30
			gain -= 5
			EventBus.toast.emit("Listrik padam. Laptop jalan dengan sisa baterai dan cahaya jendela.")
	if tempat == "kopi":
		gain += 5
	if GameState.has_flag("earphone"):
		gain += 2
	if GameState.mood >= 70:
		gain += 3
	elif GameState.mood < 25:
		gain -= 5
	if randf() < 0.25:
		waktu += 30
		EventBus.toast.emit("Cuma mau cek notifikasi… sejam kemudian masih di notifikasi.")
	var eff: Dictionary = {"waktu": waktu, "energi": -energi_biaya, "tugas": {r: gain}}
	if tempat == "kopi":
		eff["uang"] = -3000
		eff["mood"] = 3
	Sfx.play("click")
	GameState.apply_effects(eff)
	if int(GameState.tugas[r]["progress"]) >= 100:
		Sfx.play("chime")
		await _say("", "Draf selesai! Tinggal dicetak di fotokopian, lalu dikumpulkan di kelas.")


func _fotokopi() -> void:
	var opts: Array = []
	var antre: int = 15
	for t in GameData.TUGAS:
		var st: Dictionary = GameState.tugas[t["id"]]
		if int(st["progress"]) >= 100 and not bool(st["dicetak"]) and int(t["tenggat"]) - TimeManager.day <= 1:
			antre = 45
	for t in GameData.TUGAS:
		var st2: Dictionary = GameState.tugas[t["id"]]
		if int(st2["progress"]) >= 100 and not bool(st2["dicetak"]):
			opts.append({"id": "cetak_" + str(t["id"]), "label": "Cetak: %s (Rp5.000, antre ±%d mnt)" % [t["nama"], antre], "enabled": GameState.uang >= 5000})
	if GameState.has_flag("surat_butuh_salinan") and not GameState.has_flag("surat_selesai") and GameState.jumlah_inv("salinan") == 0:
		opts.append({"id": "salinan", "label": "Fotokopi KTP & KK (Rp3.000)", "enabled": GameState.uang >= 3000})
	opts.append({"id": "batal", "label": "Tidak jadi"})
	var body: String = "Antrean mahasiswa mengular. Mesin berdengung seperti sedang berpikir keras."
	if opts.size() == 1:
		body += "\n\nTidak ada yang perlu dicetak sekarang."
	var r: String = await menu.choose("Fotokopi & Print", body, opts, "batal")
	if r == "batal":
		return
	if r == "salinan":
		GameState.apply_effects({"uang": -3000, "inv": {"salinan": 1}, "waktu": antre})
		await _say("", "Dua lembar salinan hangat dari mesin. Tinggal dibawa ke Pak RW.")
	else:
		var id: String = r.substr(6)
		GameState.tugas[id]["dicetak"] = true
		GameState.apply_effects({"uang": -5000, "waktu": antre + 10})
		await _say("", "Kertas keluar satu per satu. Halaman terakhir macet, lalu keluar juga setelah ditepuk pelan. Siap dikumpulkan.")


func _kelas() -> void:
	var m: int = TimeManager.minutes
	var opts: Array = []
	var weekday: bool = TimeManager.hari_kerja()
	if weekday and m >= 450 and m < 570 and not GameState.flag_hari("kuliah"):
		opts.append({"id": "kuliah", "label": "Ikut kuliah (08.00–10.30)"})
	for t in GameData.TUGAS:
		var st: Dictionary = GameState.tugas[t["id"]]
		if bool(st["dicetak"]) and not bool(st["dikumpul"]) and weekday:
			opts.append({"id": "kumpul_" + str(t["id"]), "label": "Kumpulkan: " + str(t["nama"])})
	opts.append({"id": "batal", "label": "Keluar"})
	var body: String = "Ruang kelas. Papan tulis masih menyimpan sisa rumus kemarin."
	if not weekday:
		body = "Hari libur. Kelas kosong; hanya ada gema dan satu kursi yang goyang."
	elif opts.size() == 1:
		body += "\nKuliah 08.00–10.30 (boleh masuk 07.30–09.30, sekali sehari). Belum ada yang bisa dikumpulkan."
	var r: String = await menu.choose("Ruang Kelas", body, opts, "batal")
	if r == "kuliah":
		var lama: int = maxi(30, 630 - TimeManager.minutes)
		GameState.apply_effects({"waktu": lama, "energi": -10, "mood": -2, "counter": {"hadir": 1}, "flag_hari": "kuliah"})
		var kutipan: Array = [
			"Dosen: 'Silakan buka slide ke-47.' Dimas: 'Slide ke-47 dari 212.'",
			"Kuliah pagi: setengah ilmu masuk, setengahnya mimpi.",
			"Dosen: 'Ini mudah.' Seisi kelas saling melirik.",
		]
		EventBus.toast.emit(str(kutipan[randi() % kutipan.size()]))
	elif r.begins_with("kumpul_"):
		var id: String = r.substr(7)
		var tg: Dictionary = {}
		for t in GameData.TUGAS:
			if t["id"] == id:
				tg = t
		var tepat: bool = TimeManager.day <= int(tg["tenggat"])
		GameState.tugas[id]["dikumpul"] = true
		GameState.tugas[id]["nilai"] = 90 if tepat else 65
		if tepat:
			GameState.counters["tepat"] = int(GameState.counters.get("tepat", 0)) + 1
		Sfx.play("chime" if tepat else "alert")
		GameState.apply_effects({"mood": 6 if tepat else 1, "waktu": 10})
		await _say("", "Tugas dikumpulkan %s. %s" % ["tepat waktu" if tepat else "terlambat", "Lega rasanya." if tepat else "Dosennya mengangkat alis. Itu saja sudah cukup untuk menyesal."])


# ================================================================ transport
func _transport() -> void:
	var dari_kampus: bool = GameState.lokasi == "kampus"
	var tujuan: String = "jalan" if dari_kampus else "kampus"
	var spawn: String = "halte" if dari_kampus else "gerbang"
	var opts: Array = []
	for m in ["jalan", "angkot", "ojol"]:
		var t: Dictionary = Economy.transport(m)
		var biaya: String = "gratis" if int(t["harga"]) == 0 else GameData.rp(int(t["harga"]))
		opts.append({
			"id": m,
			"label": "%s — %s • %d mnt • energi -%d" % [GameData.TRANSPORT[m]["nama"], biaya, int(t["menit"]), int(t["energi"])],
			"enabled": GameState.uang >= int(t["harga"]) and GameState.energi > int(t["energi"]),
		})
	opts.append({"id": "batal", "label": "Batal"})
	var info: String = "Tujuan: " + ("Jalan Sukamaju" if dari_kampus else "Kampus")
	if TimeManager.raining:
		info += "\nHujan. Ongkos ojol naik, jalan kaki makin basah."
	if GameState.has_flag("jalan_ditutup"):
		info += "\nJalan menuju halte sedang diperbaiki. Waktu tempuh bertambah."
	var r: String = await menu.choose("Mau ke mana?", info, opts, "batal")
	if r == "batal":
		return
	var t2: Dictionary = Economy.transport(r)
	GameState.apply_effects({"uang": -int(t2["harga"]), "energi": -int(t2["energi"]), "waktu": int(t2["menit"])})
	if r == "ojol":
		var k: String = NewsSystem.komentar("fikri", randi())
		if k != "":
			EventBus.toast.emit("Pengemudi: " + k)
	await _pindah(tujuan, spawn)


# ================================================================ objek
func _objek(id: String) -> void:
	match id:
		"kasur":
			await _kasur()
		"meja":
			await _kerja("kos")
		"gazebo":
			await _kerja("gazebo")
		"lemari":
			var inv_t: String = "mi instan x%d, kopi sachet x%d, deterjen x%d" % [GameState.jumlah_inv("mi_instan"), GameState.jumlah_inv("kopi_sachet"), GameState.jumlah_inv("deterjen")]
			await _info("Lemari", "Dua kaos, satu kemeja kuliah, dan jaket yang sudah jadi bagian dari identitas.\n\nPersediaan: " + inv_t + ".")
		"rak":
			await _rak()
		"cucian":
			if GameState.jumlah_inv("deterjen") >= 1:
				GameState.apply_effects({"inv": {"deterjen": -1}, "mood": 4, "waktu": 45})
				EventBus.toast.emit("Baju bersih. Rasanya seperti reset kecil.")
			else:
				EventBus.toast.emit("Deterjen habis. Belum beli, belum cuci. Logika yang sempurna.")
		"pintu1", "pintu3", "pintu4", "pintu5":
			await _tetangga(id)
		"rak1":
			EventBus.toast.emit("Rak sepatu. Sandal jepit, sepatu kets, dan sepasang pantofel yang sepertinya hanya keluar saat sidang.")
		"rak2":
			EventBus.toast.emit("Rak sepatu tetangga, rapi sekali, dengan tanaman kecil di atasnya. Jelas bukan rak sepatu kamu.")
		"sampah1", "sampah2":
			if GameState.flag_hari("sampah"):
				EventBus.toast.emit("Sampah hari ini sudah dibuang. Pak Darto pasti bangga, entah di mana.")
			else:
				var eff_s: Dictionary = {"flag_hari": "sampah", "waktu": 5, "mood": 1}
				if GameState.relasi("darto") < 5:
					eff_s["rel"] = {"darto": 1}
				GameState.apply_effects(eff_s)
		"tanaman":
			if GameState.flag_hari("tanaman"):
				EventBus.toast.emit("Tanamannya sudah disiram. Dia kelihatan puas.")
			else:
				GameState.apply_effects({"flag_hari": "tanaman", "waktu": 5, "mood": 1})
				EventBus.toast.emit("Kamu menyiram tanaman besar itu. Anehnya, tenang.")
		"meteran":
			await _info("Meteran listrik", "Meteran prabayar. Lampu merahnya berkedip pelan: tanda token menipis, atau tanda semua penghuni menyalakan kompor listrik barengan.

Token dibeli bulan ini: %d kali.\nSisa listrik: %s.\n\n(Pak Darto: 'Matikan lampu kalau keluar. Itu juga sedekah.')" % [int(GameState.counters.get("token", 0)), ("HABIS" if Daily.listrik_hari() == 0 else "%d hari" % Daily.listrik_hari())])
		"jemuran":
			EventBus.toast.emit("Jemuran tetangga. Kaos hijau itu bukan punyamu. Sayang sekali, bagus.")
		"jendela":
			await _jendela()
		"galon":
			var minum: String = ""
			for i in range(1, 4):
				if not GameState.flag_hari("galon" + str(i)):
					minum = "galon" + str(i)
					break
			if minum == "":
				EventBus.toast.emit("Sudah minum cukup hari ini. Perut bukan galon, Dim.")
			else:
				GameState.apply_effects({"energi": 2, "mood": 1, "waktu": 3, "flag_hari": minum})
				EventBus.toast.emit("Air galon dingin. Tidak ada yang lebih jujur daripada air putih.")
		"kamar_mandi":
			if GameState.flag_hari("mandi"):
				EventBus.toast.emit("Sudah mandi hari ini. Jangan sampai airnya merasa dimanfaatkan.")
			else:
				GameState.apply_effects({"flag_hari": "mandi", "energi": 5, "mood": 4, "waktu": 15})
				EventBus.toast.emit("Mandi. Air Bandung pagi hari: dingin yang membangunkan jiwa.")
		"papan_info":
			await _papan_info()
		"nasi_kotak":
			if GameState.flag_hari("nasi_kotak_ambil"):
				EventBus.toast.emit("Sudah ambil. Jangan serakah… atau jangan ketahuan.")
			elif TimeManager.jam() >= 12:
				EventBus.toast.emit("Nasi kotak sudah habis. Tersisa kerupuk melempem dan harapan.")
			else:
				GameState.apply_effects({"flag_hari": "nasi_kotak_ambil", "kenyang": 45, "energi": 4, "mood": 3, "waktu": 30})
				EventBus.toast.emit("Antre 25 menit. Isi: nasi, ayam, telur, dan kerupuk yang melempem.")
		"warteg":
			if not GameData.buka("warung_tati", TimeManager.day, TimeManager.jam()):
				EventBus.toast.emit("Warteg Bu Tati tutup. " + GameData.jam_buka("warung_tati"))
			else:
				await _bicara("tati")
		"balai":
			if not GameData.buka("balai_rw", TimeManager.day, TimeManager.jam()):
				EventBus.toast.emit("Balai RW tutup. " + GameData.jam_buka("balai_rw"))
			else:
				await _bicara("rw")
		"lapangan":
			await _lapangan()
		"kentongan":
			EventBus.toast.emit("Kentongan kayu di pos kamling. Dipukul kalau ada kabar penting atau pencuri ayam; hari ini belum ada yang membutuhkan.")
		"lapak_baju", "lapak_baju2":
			EventBus.toast.emit("Gantungan baju obral: kaos band, kemeja flanel, jaket tebal untuk hawa Bandung. Rani pasti jago menawar di sini.")
		"warung_madura":
			await _bicara("imam" if TimeManager.jam() >= 22 else "asep")
		"gerobak":
			EventBus.toast.emit("Gerobak batagor yang diparkir. Mang Ujang biasanya mangkal sore hari di Jalan Sukamaju, di ujung kanan gang.")
		"gerobak_ujang":
			var jj: int = TimeManager.jam()
			if jj < 14 or jj >= 22:
				EventBus.toast.emit("Gerobak batagor Mang Ujang. Belum buka; biasanya mulai sore sampai malam.")
			else:
				await _menu_makan("Gerobak Batagor Mang Ujang", GameData.MENU_UJANG, 15)
		"gardu":
			await _gardu()
		"selebaran":
			await _selebaran()
		"halte", "gerbang":
			await _transport()
		"sajadah":
			await _salat()
		"wudu":
			var kunci: String = "wudu_" + str(TimeManager.jam())
			if GameState.flag_hari(kunci):
				EventBus.toast.emit("Baru saja wudu. Air dinginnya masih menempel di wajah.")
			else:
				GameState.apply_effects({"flag_hari": kunci, "energi": 2, "mood": 1, "waktu": 5})
				EventBus.toast.emit("Wudu. Air dingin dan segar, seperti tombol restart kecil.")
		"rak_sandal":
			EventBus.toast.emit("Rak sandal masjid. Sandal jepit, sepatu, dan satu sandal tunggal yang selalu tertinggal. Misteri abadi.")
		"rak_quran":
			if GameState.flag_hari("quran"):
				EventBus.toast.emit("Sudah membaca hari ini. Rak itu tersenyum, diam-diam.")
			else:
				GameState.apply_effects({"flag_hari": "quran", "mood": 3, "waktu": 15})
				EventBus.toast.emit("Membaca beberapa halaman dengan tenang. Kepala terasa lebih ringan.")
		"bedug":
			EventBus.toast.emit("Bedug besar. Katanya hanya ditabuh pada hari-hari tertentu. Dimas menahan diri untuk tidak mengetuknya.")
		"mimbar":
			EventBus.toast.emit("Mimbar kayu tiga undak. Kayunya licin oleh puluhan tahun tangan yang berpegangan.")
		"kotak_amal":
			await _amal()
		"jumat_berkah":
			await _jumat_berkah()
		"kucing":
			if GameState.flag_hari("kucing"):
				EventBus.toast.emit("Kucingnya sudah cukup dielus. Dia bilang cukup.")
			else:
				GameState.apply_effects({"flag_hari": "kucing", "mood": 3, "waktu": 5, "counter": {"kucing": 1}})
		"papan_menu":
			var t: String = ""
			for it in GameData.MENU_WARUNG:
				t += "%s — %s\n" % [GameData.ITEMS[it]["nama"], GameData.rp(Economy.harga(it))]
			t += "\nHarga berlaku hari ini. Besok tergantung hati telur."
			await _info("Menu Bu Tati (tulisan tangan)", t)
		"papan_balai":
			await _papan_balai()
		"tv":
			await _tv()
		"kelas":
			await _kelas()


func _tetangga(id: String) -> void:
	var jam: int = TimeManager.jam()
	var malam: bool = jam >= 17 or jam < 7
	var t: String = ""
	match id:
		"pintu1":
			t = "Kamar 1. Dangdut koplo diputar pelan, seolah penghuninya takut ketahuan Pak Darto." if malam else "Kamar 1 sepi. Hanya sandal jepit yang setia menjaga pintu."
		"pintu3":
			t = "Kamar 3. Terdengar suara keyboard cepat. Anak TI juga, mungkin. Atau sedang main game." if malam else "Kamar 3 terkunci. Penghuninya pasti sedang di kampus, atau pura-pura."
		"pintu4":
			t = "Kamar 4. Bau mi goreng merembes dari bawah pintu. Aroma yang tidak bisa dibantah." if malam else "Kamar 4 terkunci. Ada catatan tempel: 'Jangan diketuk, lagi tidur siang'."
		"pintu5":
			t = "Kamar 5, dekat tangga. Terdengar suara video call dan tawa pelan." if malam else "Kamar 5 sepi. Di gagang pintu tergantung kantong belanjaan yang belum diambil."
	EventBus.toast.emit(t)


func _salat() -> void:
	var s: Dictionary = GameData.salat_sekarang(TimeManager.day, TimeManager.minutes)
	if s.is_empty():
		EventBus.toast.emit("Belum waktu salat. Berikutnya: " + GameData.salat_berikutnya(TimeManager.minutes) + ".")
		return
	var kunci: String = "salat_" + str(s["id"])
	if GameState.flag_hari(kunci):
		EventBus.toast.emit(str(s["nama"]) + " hari ini sudah ditunaikan. Tenang.")
		return
	var r: String = await menu.choose(str(s["nama"]), "Sajadah terbentang di shaf kedua. Tidak ada yang menghakimi kalau kamu ragu; tapi tidak ada yang melarang kalau kamu ingin berhenti sebentar.", [
		{"id": "ya", "label": "Salat (%d menit)" % int(s["menit"])},
		{"id": "batal", "label": "Nanti saja"},
	], "batal")
	if r != "ya":
		return
	var eff: Dictionary = {"flag_hari": kunci, "waktu": int(s["menit"]), "mood": 4, "energi": 3, "counter": {"salat": 1}}
	if s["id"] == "jumat":
		eff["mood"] = 6
		eff["rel"] = {"ustaz": 1}
	GameState.apply_effects(eff)
	await _say("", "Hening sebentar. Pikiran yang tadinya ramai (tugas, uang, sewa) perlahan mengecil, lalu diam.")


func _amal() -> void:
	var r: String = await menu.choose("Kotak amal", "Kotak besi berkarat dengan celah selebar harapan. Sumbangan kecil pun dicatat takmir di papan.", [
		{"id": "1000", "label": "Rp1.000", "enabled": GameState.uang >= 1000},
		{"id": "2000", "label": "Rp2.000", "enabled": GameState.uang >= 2000},
		{"id": "5000", "label": "Rp5.000", "enabled": GameState.uang >= 5000},
		{"id": "batal", "label": "Tidak sekarang"},
	], "batal")
	if r == "batal":
		return
	var n: int = int(r)
	var eff: Dictionary = {"uang": -n, "mood": 1 if n == 1000 else (2 if n == 2000 else 4), "counter": {"amal": 1}}
	if int(GameState.counters.get("amal", 0)) == 0:
		eff["rel"] = {"ustaz": 1}
	GameState.apply_effects(eff)


func _jumat_berkah() -> void:
	var mnt: int = TimeManager.minutes
	if GameState.flag_hari("jumat_makan"):
		EventBus.toast.emit("Sudah ambil jatah Jumat Berkah. Jangan serakah, yang di belakang juga lapar.")
		return
	if mnt < 735:
		EventBus.toast.emit("Belum dibagikan. Jumatan dulu; pembagian sekitar pukul 12.30.")
		return
	if mnt >= 825:
		EventBus.toast.emit("Jumat Berkah sudah habis. Selalu cepat habisnya; itu tandanya baik, dan juga tandanya telat.")
		return
	var menu_t: String = str(GameData.JUMAT_MENU.get(TimeManager.day, "nasi dan lauk"))
	var jumatan: bool = GameState.flag_hari("salat_jumat")
	var teks: String = "Silakan, {nama}. Hari ini %s. Rezeki dari donatur, jangan sungkan." % menu_t
	var eff: Dictionary = {"flag_hari": "jumat_makan", "kenyang": 50, "energi": 8, "mood": 5, "waktu": 20, "counter": {"jumat": 1}}
	if jumatan:
		teks += " Tadi ikut Jumatan, ya? Alhamdulillah."
		eff["rel"] = {"ustaz": 1}
	await _say("Pak Ustaz Hilman", teks, eff)


func _gardu() -> void:
	var opts: Array = [
		{"id": "duduk", "label": "Duduk & ngobrol dengan bapak-bapak (30 mnt, mood +3)" if not GameState.flag_hari("duduk2") else "Sudah cukup ngobrol hari ini", "enabled": not GameState.flag_hari("duduk2")},
		{"id": "catur", "label": "Nonton bapak-bapak main catur (45 mnt, mood +4)" if TimeManager.jam() >= 16 else "Nonton catur (baru ramai setelah jam 16.00)", "enabled": TimeManager.jam() >= 16 and not GameState.flag_hari("catur")},
		{"id": "batal", "label": "Batal"},
	]
	var r: String = await menu.choose("Pos Ronda RW 05", "Bangku bambu di bawah atap genteng. Papan catur terbuka, gelas kopi kosong, dan dua bapak yang berdebat soal harga cabai sejak sore.", opts, "batal")
	if r == "duduk":
		GameState.apply_effects({"waktu": 30, "mood": 3, "flag_hari": "duduk2" if GameState.flag_hari("duduk1") else "duduk1"})
		var w: Array = NewsSystem.warga_lines()
		await _say("Bapak-bapak ronda", str(w[randi() % w.size()]))
	elif r == "catur":
		GameState.apply_effects({"flag_hari": "catur", "waktu": 45, "mood": 4, "energi": -2})
		var kal: Array = ["'Skak!' 'Itu bukan skak, itu pion pindah rumah.'", "'Gajah jangan jalan lurus!' 'Ini gajah modern.'", "'Kuda itu jalannya L, Pak.' 'Di rumah saya L-nya lain.'"]
		await _say("", str(kal[randi() % kal.size()]) + " Seisi gardu tertawa; Dimas ikut, tanpa sadar tugasnya makin menjauh.")


func _selebaran() -> void:
	await _info("Selebaran di dinding pos ronda", "• KOS PUTRA KOSONG: Rp450rb/bln, dekat kampus, air jernih (kadang). Hub: Pak Darto.\n• LES PRIVAT MATEMATIKA, FISIKA, ALGORITMA: mahasiswa berpengalaman, bayar seikhlasnya (seikhlasnya bukan berarti gratis).\n• LAUNDRY KILOAN Rp6.000/kg, antar-jemput se-Gang Sukamaju.\n• SEDOT WC 24 JAM, TANPA BAU (sehabis dikerjakan).\n• DICARI: anak kos jago masak. Imbalan: makan.\n• ADA YANG KEHILANGAN KUCING ORENG? Mungkin ada di dekat Balai RW.\n• Jadwal ronda bulan ini ditempel miring; harap dimiringkan juga pikirannya.")


func _lapangan() -> void:
	var sore: bool = TimeManager.jam() >= 15 and TimeManager.jam() < 19
	var teman: bool = GameState.relasi("fikri") >= 3 or GameState.relasi("rani") >= 3 or GameState.relasi("mira") >= 3
	var opts: Array = [
		{"id": "sendiri", "label": "Pukul-pukul kok sendirian ke net (30 mnt, energi -8, mood +4)", "enabled": GameState.energi >= 20 and not GameState.flag_hari("badminton")},
		{"id": "bareng", "label": "Ajak warga main (sore 15.00–19.00; hubungan ≥3, energi -12, mood +7)" if teman else "Ajak warga main (butuh teman akrab: Fikri / Rani / Teh Mira)", "enabled": teman and sore and GameState.energi >= 25 and not GameState.flag_hari("badminton")},
		{"id": "batal", "label": "Batal"},
	]
	var r: String = await menu.choose("Lapangan bulutangkis RW 05", "Net sedikit kendur, garis putih mulai pudar, tapi tiap sore selalu ada yang main. Tiang jaring juga dipakai menjemur raket.", opts, "batal")
	if r == "sendiri":
		GameState.apply_effects({"flag_hari": "badminton", "waktu": 30, "energi": -8, "mood": 4})
		EventBus.toast.emit("Kok sering nyangkut di pagar. Tapi keringat pertama hari ini terasa jujur.")
	elif r == "bareng":
		GameState.apply_effects({"flag_hari": "badminton", "waktu": 50, "energi": -12, "mood": 7, "rel": {"fikri": 1, "rani": 1, "mira": 1}})
		EventBus.toast.emit("Skor dihitung asal-asalan, tawa tidak. Kamu kalah. Dengan senang hati.")


func _kasur() -> void:
	var jam: int = TimeManager.jam()
	var boleh: bool = jam >= 18 or GameState.energi < 30
	var opts: Array = [
		{"id": "rebah", "label": "Rebahan sejam (energi +12, mood +2)"},
		{"id": "tidur", "label": "Tidur (akhiri hari)" if boleh else "Tidur (belum ngantuk — setelah 18.00)", "enabled": boleh},
		{"id": "batal", "label": "Batal"},
	]
	var r: String = await menu.choose("Kasur", "Hari ke-%d, %s. Rencana besar: belum dimulai." % [TimeManager.day, TimeManager.jam_str()], opts, "batal")
	if r == "rebah":
		GameState.apply_effects({"waktu": 60, "energi": 12, "mood": 2})
	elif r == "tidur":
		await _tidur(false)


func _rak() -> void:
	if not Daily.listrik_ada():
		Sfx.play("error")
		EventBus.toast.emit("Kompor listrik mati: token habis. Beli token di Warung Madura, atau makan di luar.")
		return
	var nasi: int = GameState.jumlah_inv("nasi")
	var telur: int = GameState.jumlah_inv("telur")
	var mi: int = GameState.jumlah_inv("mi_instan")
	var opts: Array = [
		{"id": "mi", "label": "Masak mi instan (kenyang +35, 20 mnt)", "enabled": mi > 0},
		{"id": "mi_telur", "label": "Masak mi + telur (kenyang +45, 25 mnt)", "enabled": mi > 0 and telur > 0},
		{"id": "nasi_telur", "label": "Masak nasi + telur dadar (kenyang +48, 35 mnt)", "enabled": nasi > 0 and telur > 0},
		{"id": "nasi_mi", "label": "Nasi + mi instan, ala anak kos (kenyang +55, 30 mnt)", "enabled": nasi > 0 and mi > 0},
		{"id": "kopi", "label": "Seduh kopi sachet (energi +8, 10 mnt)", "enabled": GameState.jumlah_inv("kopi_sachet") > 0},
		{"id": "batal", "label": "Batal"},
	]
	var body: String = "Penanak nasi, kompor listrik, dan panci penyok.\nPersediaan: mi %d • telur %d • nasi %d • kopi %d" % [mi, telur, nasi, GameState.jumlah_inv("kopi_sachet")]
	var r: String = await menu.choose("Rak masak", body, opts, "batal")
	if r == "mi":
		GameState.apply_effects({"inv": {"mi_instan": -1}, "kenyang": 35, "energi": 4, "waktu": 20, "counter": {"masak": 1}})
	elif r == "mi_telur":
		GameState.apply_effects({"inv": {"mi_instan": -1, "telur": -1}, "kenyang": 45, "energi": 5, "mood": 2, "waktu": 25, "counter": {"masak": 1}})
	elif r == "nasi_telur":
		GameState.apply_effects({"inv": {"nasi": -1, "telur": -1}, "kenyang": 48, "energi": 6, "mood": 3, "waktu": 35, "counter": {"masak": 1}})
	elif r == "nasi_mi":
		GameState.apply_effects({"inv": {"nasi": -1, "mi_instan": -1}, "kenyang": 55, "energi": 5, "mood": 3, "waktu": 30, "counter": {"masak": 1}})
	elif r == "kopi":
		GameState.apply_effects({"inv": {"kopi_sachet": -1}, "energi": 8, "mood": 3, "waktu": 10})


func _jendela() -> void:
	var jam: int = TimeManager.jam()
	var t: String = ""
	if TimeManager.raining:
		t = "Hujan. Aspal gang berkilau dan jemuran tetangga menyerah."
	elif jam < 9:
		t = "Kabut tipis menempel di bukit jauh. Penjual bubur lewat sambil memukul mangkok."
	elif jam < 16:
		t = "Gang terang dan ramai motor. Seekor kucing menatap tajam, seolah menagih sewa."
	elif jam < 19:
		t = "Langit sore mulai kelabu. Aroma gorengan bercampur tanah basah."
	else:
		t = "Gang mulai sepi. Beberapa warung masih buka, lampunya hangat."
	await _info("Dari jendela", t)


func _papan_info() -> void:
	var t: String = "PROGRAM KAMPUNG NYAMAN\nCapaian: %d dari 12 kegiatan selesai\nStatus: BERJALAN BAIK\n\nKegiatan: penerangan jalan • perbaikan jalan • papan informasi • pos layanan administrasi • taman mini • dan lain-lain.\n\n(huruf kecil) Pengaduan warga: Pak RW, Senin–Jumat 08.00–15.00, kecuali istirahat." % GameData.kegiatan_selesai(TimeManager.day)
	if GameState.has_flag("pos_layanan"):
		t += "\nPos layanan: Senin–Kamis 09.00–12.00."
	await _info("Papan Informasi", t)
	if TimeManager.day >= 16:
		EventBus.toast.emit("Angkanya naik terus. Got depan kos masih mampet.")


func _papan_balai() -> void:
	var t: String = "• Diskon token listrik (stiker pudar)\n• Jadwal ronda"
	if GameState.has_flag("pos_layanan"):
		t += "\n• Pos layanan: Senin–Kamis 09.00–12.00"
	if GameState.has_flag("laporan_rw"):
		t += "\n• Laporan program akan dikirim ke kecamatan"
	if GameState.has_flag("undangan_rapat"):
		t += "\n• RAPAT WARGA: Sabtu, hari ke-27, 19.00, Balai RW"
	if GameState.has_flag("papan_info"):
		t += "\n• PROGRAM KAMPUNG NYAMAN — capaian: %d dari 12 kegiatan selesai (status: BERJALAN BAIK)" % GameData.kegiatan_selesai(TimeManager.day)
	await _info("Papan Pengumuman RW", t)


func _tv() -> void:
	var t: String = "Acara kuis, lalu iklan sampo."
	var log: Array = GameState.news_log
	if not log.is_empty():
		t = "Berita:\n"
		for i in range(maxi(0, log.size() - 2), log.size()):
			var e: Dictionary = GameData.event_by_id(str(log[i]))
			t += "• " + str(e["judul"]) + "\n"
	if TimeManager.day % 7 == 6 and TimeManager.jam() >= 19:
		t += "\nPertandingan bola berlangsung. Seisi warung mendadak jadi pengamat taktik."
	var r: String = await menu.choose("Televisi", t, [{"id": "tonton", "label": "Tonton sebentar (1 jam)"}, {"id": "batal", "label": "Nggak jadi"}], "batal")
	if r == "tonton":
		GameState.apply_effects({"waktu": 60, "mood": 4})


# ================================================================ ponsel
func _ponsel() -> void:
	while true:
		var r: String = await menu.choose("Ponsel", "Baterai 41%. Notifikasi: 3. Kuota: cukup, selama tidak dipakai.", [
			{"id": "hari_ini", "label": "Rencana hari ini"},
			{"id": "berita", "label": "Berita & pesan"},
			{"id": "uang", "label": "Keuangan"},
			{"id": "tugas", "label": "Tugas kuliah"},
			{"id": "hubungan", "label": "Hubungan dengan warga"},
			{"id": "catatan", "label": "Catatan warga (dokumentasi)"},
			{"id": "jadwal", "label": "Jam buka & jadwal salat"},
			{"id": "ach", "label": "Pencapaian (%d dari %d)" % [Ach.jumlah(), Ach.DAFTAR.size()]},
			{"id": "scroll", "label": "Scroll medsos (1 jam, mood +5, tugas tetap menunggu)"},
			{"id": "tutup", "label": "Tutup"},
		], "tutup")
		if r == "tutup":
			return
		elif r == "hari_ini":
			var rencana: Array = Daily.rencana_hari_ini()
			var tr: String = ""
			for baris in rencana:
				tr += "• " + str(baris) + "\n\n"
			await _info("Rencana hari %d" % TimeManager.day, tr if tr != "" else "Tidak ada yang mendesak. Nikmati hari.")
		elif r == "ach":
			var ta: String = ""
			for a in Ach.DAFTAR:
				var ada: bool = Ach.sudah(str(a["id"]))
				ta += "%s %s\n   %s\n" % ["[v]" if ada else "[ ]", a["nama"], a["ket"]]
			await _info("Pencapaian (%d dari %d)" % [Ach.jumlah(), Ach.DAFTAR.size()], ta)
		elif r == "berita":
			var t: String = ""
			var log: Array = GameState.news_log
			for i in range(log.size() - 1, maxi(-1, log.size() - 7), -1):
				var e: Dictionary = GameData.event_by_id(str(log[i]))
				t += "• [Hari %d] %s\n  %s\n\n" % [int(e["day"]), e["judul"], e["isi"]]
			if t == "":
				t = "Belum ada pesan baru. Hanya notifikasi diskon ongkir."
			await _info("Berita & pesan", t)
		elif r == "uang":
			var t2: String = "Uang: %s\nUtang: %s\n\nSewa kos %s: %s (jatuh tempo hari %d, toleransi hari %d; denda %s)\n" % [GameData.rp(GameState.uang), GameData.rp(GameState.utang), GameData.rp(Daily.sewa_tagihan()), "LUNAS" if GameState.has_flag("sewa_lunas") else "belum dibayar", GameData.SEWA_TEMPO, GameData.SEWA_TOLERANSI, GameData.rp(GameData.SEWA_DENDA)]
			t2 += "Kiriman Ibu: " + ("sudah masuk" if TimeManager.day >= 14 else "hari ke-14 (Rp500.000)")
			await _info("Keuangan", t2)
		elif r == "tugas":
			var t3: String = ""
			for t in GameData.TUGAS:
				var st: Dictionary = GameState.tugas[t["id"]]
				var s: String = ""
				if bool(st["dikumpul"]):
					s = "dikumpulkan (nilai %d)" % int(st["nilai"])
				elif TimeManager.day < int(t["mulai"]):
					s = "belum dimulai"
				elif int(st["progress"]) < 100:
					s = "progres %d%%" % int(st["progress"])
				elif not bool(st["dicetak"]):
					s = "siap dicetak"
				else:
					s = "siap dikumpulkan"
				if not bool(st["dikumpul"]) and TimeManager.day > int(t["tenggat"]):
					s += " — TELAT"
				t3 += "• %s\n  %s • tenggat %s (hari %d)\n\n" % [t["nama"], s, TimeManager.nama_hari(int(t["tenggat"])), int(t["tenggat"])]
			await _info("Tugas kuliah", t3)
		elif r == "hubungan":
			var th: String = ""
			for k in ["tati", "asep", "imam", "rani", "fikri", "darto", "mira", "rw", "yoga", "ustaz", "ujang"]:
				var n: int = GameState.relasi(k)
				th += "%s  %s%s\n" % [str(GameData.NPC[k]["nama"]).rpad(18), "●".repeat(n), "○".repeat(10 - n)]
			await _info("Hubungan dengan warga", th)
		elif r == "catatan":
			var tc: String = ""
			var daftar: Dictionary = {"testimoni_tati": "Bu Tati: biaya dapur naik, belum ada bantuan untuk pedagang kecil.", "testimoni_asep": "Kang Asep: keramaian naik, tapi pasokan telat saat jalan ditutup.", "testimoni_rani": "Rani: jam pos layanan bentrok dengan kuliah dan kerja.", "testimoni_fikri": "Fikri: penutupan jalan memotong penghasilan harian.", "testimoni_mira": "Teh Mira: informasi jam layanan tidak ada di tempat orang lewat.", "testimoni_ustaz": "Pak Ustaz: jamaah sepuh sulit lewat jalan tutup; kabar program jarang sampai ke mereka."}
			for k in daftar.keys():
				if GameState.has_flag(k):
					tc += "• " + str(daftar[k]) + "\n"
			if tc == "":
				tc = "Belum ada catatan. Warga baru bercerita kalau ditanya dengan benar-benar mau mendengar."
			await _info("Catatan warga (%d dari 6)" % GameState.count_testimoni(), tc)
		elif r == "jadwal":
			await _info("Jam buka & jadwal salat", "Warung Madura: 24 jam (Kang Asep siang, Cak Imam malam)\nWarung Nasi Bu Tati: 06.00–21.00\nFotokopi & Print: Senin–Sabtu 08.00–20.00\nBalai RW: Senin–Jumat 08.00–12.00 & 13.00–15.00\nKopi Teh Mira: 07.00–23.00\n\nSalat: Zuhur ±11.45 • Ashar ±15.00 • Magrib ±18.00 • Isya ±19.15\nJumat: Jumatan 11.45, Jumat Berkah ±12.30 (sampai habis)")
		elif r == "scroll":
			GameState.apply_effects({"waktu": 60, "mood": 5})
			EventBus.toast.emit("Satu jam hilang di antara video kucing dan debat yang tak ada ujungnya.")
			return


# ================================================================ tidur, pagi, rapat, ending
func _tidur(paksa: bool) -> void:
	busy = true
	GameState.ui_open = true
	Sfx.play("sleep")
	await _fade(true)
	if TimeManager.day >= GameData.JUMLAH_HARI:
		await _ending()
		return
	var jam_tidur: float = float(TimeManager.minutes) / 60.0
	if paksa:
		GameState.energi = 55
		GameState.mood = clampi(GameState.mood - 6, 0, 100)
	else:
		# tidur lebih malam = lebih pulas: 18.00 -> +60, 24.00 -> +84
		var pulih: int = 60 + clampi(int((jam_tidur - 18.0) * 4.0), 0, 24)
		GameState.energi = clampi(GameState.energi + pulih, 0, 100)
		if GameState.has_flag("poster"):
			GameState.mood = clampi(GameState.mood + 2, 0, 100)
	GameState.kenyang = clampi(GameState.kenyang - 10, 0, 100)
	TimeManager.new_day()
	Economy.tick_day()
	var ev: Array = NewsSystem.run_day(TimeManager.day)
	var baris: Array = Daily.proses_pagi()
	_kehujanan_info = false
	_load_location("kos_room", "kasur")
	Ach.cek()
	SaveSystem.simpan()
	await _fade(false)
	_banner_lokasi()
	await _pagi(ev, paksa, baris)
	GameState.ui_open = false
	busy = false


func _pagi(ev: Array, paksa: bool, baris: Array) -> void:
	var pagi: Array = ["Pagi di Bandung Timur: kabut tipis di atas atap, udara sejuk, dan jemuran yang belum menyerah.", "Di kejauhan Manglayang tampak biru. Hari ini mungkin hujan, mungkin tidak, seperti biasa.", "Cahaya pagi masuk lewat celah genteng. Suara motor sudah mulai memenuhi gang."]
	var t: String = str(pagi[randi() % pagi.size()]) + "\n\n"
	if paksa:
		t += "Dimas ketiduran di tempat sebelum sempat pulang. Badan pegal, tapi masih hidup.\n\n"
	t += "Uang: %s   Energi: %d   Kenyang: %d\n\n" % [GameData.rp(GameState.uang), GameState.energi, GameState.kenyang]
	for e in ev:
		t += "• %s\n  %s\n\n" % [e["judul"], e["isi"]]
	if ev.is_empty():
		t += "Tidak ada berita besar hari ini. Mungkin.\n"
	for l in baris:
		t += "\n» " + str(l)
	for tg in GameData.TUGAS:
		if int(tg["tenggat"]) == TimeManager.day and not bool(GameState.tugas[tg["id"]]["dikumpul"]):
			t += "\n\nTENGGAT HARI INI: " + str(tg["nama"])
	await menu.choose("Hari ke-%d • %s" % [TimeManager.day, TimeManager.nama_hari()], t, [{"id": "ok", "label": "Mulai hari"}])


func _rapat() -> void:
	DialogueDB.build_rapat()
	await dlg.run("r1")
	EventBus.toast.emit("Rapat selesai.")


func _hitung_skor() -> Dictionary:
	var ok: int = 0
	var jumlah_nilai: int = 0
	for t in GameData.TUGAS:
		var st: Dictionary = GameState.tugas[t["id"]]
		if bool(st["dikumpul"]):
			ok += 1
			jumlah_nilai += int(st["nilai"])
	var tepat: int = int(GameState.counters.get("tepat", 0))
	var skor: float = float(ok) * 8.0 + float(tepat) * 2.0
	skor += 12.0 if GameState.has_flag("sewa_lunas") else 0.0
	skor -= 4.0 if GameState.has_flag("sewa_denda") else 0.0
	skor += float(mini(GameState.count_testimoni(), 6)) * 2.0 + (5.0 if GameState.has_flag("rapat_hadir") else 0.0)
	skor += clampf(float(GameState.uang) / 40000.0, 0.0, 6.0) - minf(float(GameState.utang) / 10000.0, 4.0)
	skor += float(GameState.mood) / 100.0 * 8.0
	skor += float(Ach.jumlah())
	skor += minf(float(GameState.counters.get("hadir", 0)), 10.0) * 0.4
	var nilai: int = clampi(int(round(skor)), 0, 100)
	var predikat: String = "D — Selamat, masih bertahan"
	if nilai >= 85:
		predikat = "S — Warga Teladan Gang Sukamaju"
	elif nilai >= 70:
		predikat = "A — Anak Kos yang Tangguh"
	elif nilai >= 55:
		predikat = "B — Cukup, dan itu sudah baik"
	elif nilai >= 40:
		predikat = "C — Bulan yang berat, tapi lewat"
	return {"ok": ok, "rata": int(jumlah_nilai / maxi(ok, 1)), "nilai": nilai, "predikat": predikat}


func _ending() -> void:
	TimeManager.running = false
	hud.set_panel_visible(false)
	Sfx.play("chime")
	var sk: Dictionary = _hitung_skor()
	var total: int = GameData.TUGAS.size()
	var s: String = "Hari ke-28 selesai. Sampai akhir bulan, %s masih di sini.\n\n" % GameState.player_name
	s += "RAPOR BULAN INI: %d/100 — %s\n\n" % [int(sk["nilai"]), str(sk["predikat"])]
	s += "RINGKASAN\n"
	s += "• Uang tersisa: %s%s\n" % [GameData.rp(GameState.uang), ("  (utang %s)" % GameData.rp(GameState.utang)) if GameState.utang > 0 else ""]
	s += "• Sewa kos: %s\n" % ("lunas" if GameState.has_flag("sewa_lunas") else "belum lunas (Pak Darto menunggu dengan kesabaran yang ada batasnya)")
	s += "• Tugas dikumpulkan: %d dari %d (rata-rata nilai %d)\n" % [int(sk["ok"]), total, int(sk["rata"])]
	s += "• Hadir kuliah: %d kali\n" % int(GameState.counters.get("hadir", 0))
	s += "• Pengalaman warga yang dicatat: %d dari 6\n" % GameState.count_testimoni()
	s += "• Pencapaian: %d dari %d\n\n" % [Ach.jumlah(), Ach.DAFTAR.size()]
	s += "PROGRAM KAMPUNG NYAMAN\n"
	if GameState.has_flag("hasil_baik"):
		s += "Laporan ke kecamatan: 12 dari 12 kegiatan, dengan lampiran 'Catatan Warga'. Jam pos layanan ditinjau ulang. Tidak semuanya beres, tapi daftar masalah warga untuk pertama kalinya ikut masuk laporan.\n\n"
	elif GameState.has_flag("hasil_campuran"):
		s += "Laporan tetap 12 dari 12, kini dengan catatan tambahan dari warga. Sebagian masalah mulai diperhatikan; sebagian lagi masih menunggu giliran.\n\n"
	elif GameState.has_flag("hasil_formal"):
		s += "Rapat selesai tepat waktu. Laporan 12 dari 12 dikirim. Di papan informasi, angkanya sempurna. Di gang, harga telur masih jadi topik harian.\n\n"
	else:
		s += "%s melewatkan rapat dan mendengar hasilnya dari grup RW: laporan 12 dari 12. Sisanya tinggal tergantung siapa yang bercerita.\n\n" % GameState.player_name
	s += "KABAR WARGA\n"
	if GameState.relasi("tati") >= 4:
		s += "• Bu Tati menyisihkan tempe orek terakhir untuk %s. 'Ibu simpenin, soalnya kamu kurusan.'\n" % GameState.player_name
	else:
		s += "• Bu Tati tetap membuka warung jam enam pagi, menghitung harga telur dengan hati-hati.\n"
	if GameState.relasi("fikri") >= 3:
		s += "• Fikri mengabarkan: order lancar, jalan mulus, bensin tetap mahal. Ojolnya selalu ada diskon buat langganan.\n"
	else:
		s += "• Fikri terus narik, menghitung apakah penghasilan hari ini cukup.\n"
	if GameState.relasi("rani") >= 4:
		s += "• Rani berhasil mengurus surat adiknya. Dia mengirim stiker 'terima kasih' yang ukurannya terlalu besar.\n"
	else:
		s += "• Rani masih menyeimbangkan kuliah, kerja, dan keluarga, sambil mencatat pengeluaran kopi.\n"
	if GameState.relasi("mira") >= 4:
		s += "• Teh Mira menyiapkan satu kursi 'khusus' di warungnya. Tidak ada tulisannya, tapi semua orang tahu.\n"
	if GameState.has_flag("hoax_cek"):
		s += "• Kang Asep sekarang bertanya 'sumbernya mana?' sebelum membagikan apa pun.\n"
	s += "\nPesan dari Ibu: 'Dimas, bulan depan jangan lupa makan yang teratur ya. Ibu bangga sama kamu.'"
	SaveSystem.hapus()
	var r: String = await menu.choose("SAMPAI AKHIR BULAN", s, [{"id": "ulang", "label": "Main lagi"}, {"id": "keluar", "label": "Keluar"}])
	if r == "ulang":
		get_tree().reload_current_scene()
	else:
		get_tree().quit()
