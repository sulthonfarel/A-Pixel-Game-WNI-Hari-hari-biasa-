extends SceneTree
## Bot uji otomatis (opsional, tidak dipakai game):
##   godot --headless --path . --script res://tools/bot_test.gd -- 120
## Memainkan game secara acak selama N detik (waktu nyata, dipercepat) untuk mencari error runtime.

var main: Node = null
var t: float = 0.0
var limit: float = 120.0
var acc: float = 0.0
var step_log: float = 0.0
var aksi: int = 0
var max_day: int = 1
var tm: Node
var gs: Node


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() > 0:
		limit = float(args[0])
	seed(1234)
	var scn: PackedScene = load("res://scenes/main.tscn")
	tm = root.get_node("TimeManager")
	gs = root.get_node("GameState")
	main = scn.instantiate()
	root.add_child(main)
	Engine.time_scale = 6.0


func _klik(box: Node) -> bool:
	var cand: Array = []
	for c in box.get_children():
		if c is Button and not (c as Button).disabled:
			var tx: String = (c as Button).text
			if tx.begins_with("Keluar") or tx.begins_with("Main lagi") or tx.find("layar judul") >= 0:
				continue
			cand.append(c)
	if cand.is_empty():
		return false
	var b: Button = cand[randi() % cand.size()]
	# condong memilih opsi pertama supaya cerita maju, tapi tetap acak
	if randf() < 0.5:
		b = cand[0]
	b.pressed.emit()
	return true


func _process(delta: float) -> bool:
	t += delta
	acc += delta
	if t > limit:
		print("BOT SELESAI. aksi=%d hari_maks=%d hari=%d uang=%d" % [aksi, max_day, tm.day, gs.uang])
		quit()
		return true
	if main == null or not is_instance_valid(main):
		return false
	max_day = maxi(max_day, tm.day)
	if acc < 0.15:
		return false
	acc = 0.0
	if main.menu.visible:
		if main.menu._line != null:
			main.menu.chosen.emit("ok")
		elif not _klik(main.menu._opts):
			main.menu.chosen.emit("x")
		aksi += 1
		return false
	if main.dlg.visible:
		if main.dlg._typing:
			main.dlg._finish()
		else:
			_klik(main.dlg._choices)
		aksi += 1
		return false
	if not main.started or main.busy:
		return false
	# percepat waktu
	if randf() < 0.5:
		tm.advance(randi_range(40, 140))
	var r: float = randf()
	if r < 0.55 and not main.view.interactables.is_empty():
		var it: Dictionary = main.view.interactables[randi() % main.view.interactables.size()]
		if it["kind"] == "npc":
			main.player.position = it["pos"] + Vector2(10, 0)
		else:
			var rc: Rect2 = it["rect"]
			main.player.position = rc.get_center()
			main.player.position.y = clampf(main.player.position.y, main.view.y_min, main.view.y_max)
		main.near = main._cari_dekat()
		main._interact()
	elif r < 0.65:
		var locs: Array = ["kos_room", "koridor", "gang", "lapangan", "jalan", "masjid", "fotokopi", "kopi_mira", "kampus"]
		main._pindah(str(locs[randi() % locs.size()]), "")
	elif r < 0.72:
		main._phone()
	elif r < 0.75:
		main._jeda()
	elif r < 0.82:
		main.player.position.x = main.view.xmax() - 2.0
	elif r < 0.9:
		gs.energi = maxi(0, gs.energi - 40)
	aksi += 1
	if Time.get_ticks_msec() % 7 == 0:
		print("t=%.0f hari=%d jam=%s lokasi=%s uang=%d en=%d ken=%d" % [t, tm.day, tm.jam_str(), gs.lokasi, gs.uang, gs.energi, gs.kenyang])
	return false
