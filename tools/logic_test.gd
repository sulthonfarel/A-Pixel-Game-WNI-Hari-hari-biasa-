extends SceneTree
## Uji logika terarah: godot --headless --path . --script res://tools/logic_test.gd

var main: Node
var tm: Node
var gs: Node
var daily: Node
var f: int = 0


func _initialize() -> void:
	tm = root.get_node("TimeManager")
	gs = root.get_node("GameState")
	daily = root.get_node("Daily")
	main = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)


func _klik(box: Node) -> void:
	for c in box.get_children():
		if c is Button and not (c as Button).disabled and not (c as Button).text.begins_with("Keluar"):
			(c as Button).pressed.emit()
			return


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
	if f % 5 != 0:
		return false
	if main.menu.visible and not main.get_meta("uji_selesai", false):
		_klik(main.menu._opts)   # tutup ringkasan pagi dsb
		return false
	if not main.has_meta("tahap"):
		main.set_meta("tahap", 0)
	var tahap: int = main.get_meta("tahap")
	match tahap:
		0:
			print("[1] listrik awal:", daily.listrik_hari())
			for i in range(7):
				daily.proses_pagi()
			print("[1] listrik setelah 7 pagi:", daily.listrik_hari(), " ada=", daily.listrik_ada())
			tm.day = 25
			gs.flags.erase("sewa_lunas")
			tm.day = 26
			var baris: Array = daily.proses_pagi()
			print("[2] denda flag:", gs.has_flag("sewa_denda"), " tagihan:", daily.sewa_tagihan())
			print("[2] baris:", baris.size())
			# efek popup tak crash
			gs.apply_effects({"uang": 5000, "energi": 5, "mood": 2, "rel": {"tati": 1}})
			print("[3] rencana hari ini:", daily.rencana_hari_ini().size(), "baris")
			main.set_meta("tahap", 1)
		1:
			tm.day = 28
			gs.flags["sewa_lunas"] = true
			main.set_meta("uji_selesai", true)
			var sk: Dictionary = main._hitung_skor()
			print("[4] skor:", sk)
			main._ending()
			main.set_meta("tahap", 2)
		2:
			print("[5] menu ending tampil:", main.menu.visible, " fade alpha:", main.fade.color.a)
			print("[5] judul:", main.menu._title.text)
			print("[5] body (awal):", main.menu._body.text.substr(0, 160).replace("\n", " | "))
			quit()
	return false
