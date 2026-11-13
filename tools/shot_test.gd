extends SceneTree
## Tangkap layar beberapa skenario (butuh renderer, mis. xvfb): hasil di /tmp/shots

var main: Node
var tm: Node
var gs: Node
var f: int = 0
var skenario: Array = []
var idx: int = 0
var tunggu: int = 0


func _initialize() -> void:
	tm = root.get_node("TimeManager")
	gs = root.get_node("GameState")
	DirAccess.make_dir_recursive_absolute("/tmp/shots")
	main = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)


func _klik(box: Node) -> void:
	for c in box.get_children():
		if c is Button and not (c as Button).disabled and not (c as Button).text.begins_with("Keluar"):
			(c as Button).pressed.emit()
			return


func _atur(loc: String, spawn: String, jam: float, hujan: bool, nama: String, extra: Callable = Callable()) -> void:
	main._load_location(loc, spawn)
	tm.minutes = int(jam * 60.0)
	tm.raining = hujan
	main.mod.color = main._tint(jam)
	if loc in ["kos_room", "koridor", "masjid", "kopi_mira", "fotokopi"]:
		main.mod.color = main.mod.color.lerp(Color.WHITE, 0.55)
	if extra.is_valid():
		extra.call()


func _simpan(nama: String) -> void:
	var img: Image = root.get_texture().get_image()
	img.save_png("/tmp/shots/%s.png" % nama)
	print("shot ", nama)


func _process(_d: float) -> bool:
	f += 1
	if not main.started:
		if main.menu.visible:
			if main.menu._line != null:
				main.menu.chosen.emit("ok")
			else:
				_klik(main.menu._opts)
		elif main.dlg.visible:
			if main.dlg._typing:
				main.dlg._finish()
			else:
				_klik(main.dlg._choices)
		return false
	if tunggu > 0:
		tunggu -= 1
		return false
	if main.menu.visible and idx < 99:
		_klik(main.menu._opts)
		return false
	main.busy = true
	main.dlg.visible = false
	match idx:
		0:
			_atur("kos_room", "kasur", 8.5, false, "kos_pagi")
			tunggu = 40
		1:
			_simpan("kos_pagi")
			_atur("kos_room", "kasur", 21.0, false, "kos_malam")
			tunggu = 40
		2:
			_simpan("kos_malam")
			_atur("gang", "kos", 18.3, true, "gang_hujan")
			main.player.position = Vector2(380, 236)
			main.player.umbrella = true
			gs.flags["payung"] = true
			gs.apply_effects({"uang": 15000, "energi": 5, "mood": 3, "rel": {"tati": 1}})
			tunggu = 60
		3:
			_simpan("gang_hujan")
			main.rain._flash_seq = [[0.0, 0.8]]
			tunggu = 2
		4:
			_simpan("gang_petir")
			_atur("gang", "kos", 20.5, false, "gang_malam")
			main.player.position = Vector2(300, 236)
			main.hud.show_banner("Gang Sukamaju", "Hari 3 • Rabu • 20:30")
			tunggu = 50
		5:
			_simpan("gang_malam")
			_atur("koridor", "tangga", 20.0, false, "koridor_malam")
			gs.counters["listrik"] = 1
			tunggu = 40
		6:
			_simpan("koridor_malam")
			_atur("lapangan", "kiri", 6.8, false, "lapangan_pagi")
			tunggu = 40
		7:
			_simpan("lapangan_pagi")
			main.dlg.visible = true
			main.dlg._set_potret("Bu Tati")
			main.dlg._speaker.text = "Bu Tati"
			main.dlg._text.text = "Dimas, sarapan dulu. Hari ini ada tempe orek."
			main.dlg._text.visible_characters = -1
			main.dlg._add_choice("Boleh, Bu", 0)
			tunggu = 10
		8:
			_simpan("dialog_tati")
			main.dlg.visible = false
			_atur("jalan", "halte", 10.0, false, "jalan_siang")
			tunggu = 40
		9:
			_simpan("jalan_siang")
			_atur("fotokopi", "masuk", 10.0, false, "fotokopi")
			tunggu = 30
		10:
			_simpan("fotokopi")
			_atur("kampus", "gerbang", 10.0, false, "kampus")
			tunggu = 30
		11:
			_simpan("kampus")
			quit()
	idx += 1
	return false
