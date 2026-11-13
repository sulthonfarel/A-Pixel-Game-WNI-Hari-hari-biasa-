extends Node
## Membangkitkan scenes/maps/*.tscn dari tools/lokasi_data.gd (sekali jalan, atau ulang bila arsip diubah).
##   godot --headless --path . res://tools/bangun_peta.tscn
## PERINGATAN: menimpa scenes/maps/*.tscn. Setelah peta diedit di editor, jangan jalankan lagi.

const PLAYER_SCENE: PackedScene = preload("res://scenes/sections/player.tscn")
const AYAM_SCENE: PackedScene = preload("res://scenes/entities/ayam.tscn")

var root_node: LocationView


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute("res://scenes/maps")
	for id in LokasiData.LOKASI.keys():
		_bangun(str(id), LokasiData.LOKASI[id])
	print("Selesai membangun ", LokasiData.LOKASI.size(), " peta.")
	get_tree().quit()


func _tambah(induk: Node, anak: Node, nama: String = "") -> Node:
	if nama != "":
		anak.name = nama
	induk.add_child(anak)
	anak.owner = root_node
	return anak


func _bangun(id: String, d: Dictionary) -> void:
	var r := LocationView.new()
	root_node = r
	r.name = id.capitalize().replace(" ", "")
	r.loc_id = id
	r.nama = str(d["nama"])
	r.ukuran = Vector2(float(d["w"]), float(d.get("h", 360)))
	r.dalam_ruangan = bool(d.get("indoor", false))
	r.y_min = float(d["ymin"])
	r.y_max = float(d.get("ymax", 332))
	r.x_max = float(d.get("xmax", -1.0))
	r.tinggi_sprite = int(d.get("sprite", 50))
	r.kecepatan_jalan = float(d.get("kecepatan", 1.0))
	if d.has("depth"):
		r.depth = Vector2(float(d["depth"][0]), float(d["depth"][1]))
	r.radius_interaksi = float(d.get("radius", 0.0))
	r.warna_lantai = Color(str(d["lantai"]))
	r.warna_dinding = Color(str(d["dinding"]))
	r.lalu_lintas = id == "jalan"
	r.pejalan_kaki = id == "gang" or id == "lapangan"
	r.jalur_pejalan = Vector2(228.0, 246.0) if id == "gang" else Vector2(246.0, 262.0)
	r.papan = d.get("papan", [])
	r.jendela_lampu = d.get("jendela_lampu", [])
	var lx := PackedFloat32Array()
	for x in d.get("lampu_x", []):
		lx.append(float(x))
	r.lampu_x = lx

	# latar gambar (Sprite2D di belakang induk, supaya efek yang digambar induk tetap terlihat)
	if d.has("bg") and ResourceLoader.exists(str(d["bg"])):
		var tex: Texture2D = load(str(d["bg"])) as Texture2D
		var sp := Sprite2D.new()
		sp.texture = tex
		sp.centered = false
		sp.show_behind_parent = true
		sp.scale = r.ukuran / tex.get_size()
		_tambah(r, sp, "Latar")

	var ent := Node2D.new()
	ent.y_sort_enabled = true
	_tambah(r, ent, "Entities")

	var mk := Node2D.new()
	mk.set_script(load("res://scripts/interact_marker.gd"))
	_tambah(r, mk, "InteractMarker")

	if d.has("pagar"):
		var f := FenceLayer.new()
		f.z_index = 20
		var a := PackedInt32Array()
		for v in d["pagar"]:
			a.append(int(v))
		f.area = a
		_tambah(r, f, "Pagar")

	# titik muncul
	var spawns := Node2D.new()
	_tambah(r, spawns, "Spawns")
	var first_pos: Vector2 = Vector2.ZERO
	var first := true
	for k in d["spawn"].keys():
		var m := Marker2D.new()
		m.position = Vector2(float(d["spawn"][k][0]), float(d["spawn"][k][1]))
		_tambah(spawns, m, str(k))
		if first:
			first_pos = m.position
			first = false

	# objek
	var objek := Node2D.new()
	_tambah(r, objek, "Objek")
	for o in d["objek"]:
		var it := Interactable.new()
		it.position = Vector2(float(o[1]), float(o[2]))
		it.size = Vector2(float(o[3]), float(o[4]))
		it.warna = Color(str(o[5]))
		it.teks = str(o[6])
		it.solid = bool(o[7])
		it.label = str(o[8])
		if o.size() > 9:
			it.syarat_flag = str(o[9])
		_tambah(objek, it, str(o[0]))

	# pintu
	var pintu := Node2D.new()
	_tambah(r, pintu, "Pintu")
	for p in d["pintu"]:
		var pt := Pintu.new()
		pt.position = Vector2(float(p["r"][0]), float(p["r"][1]))
		pt.size = Vector2(float(p["r"][2]), float(p["r"][3]))
		pt.ke = str(p["ke"])
		pt.spawn = str(p["spawn"])
		pt.nama_tujuan = str(p["nama"])
		pt.label = str(p.get("label", ""))
		_tambah(pintu, pt, str(p["id"]))

	# tepi lokasi
	var tepi := Node2D.new()
	_tambah(r, tepi, "Tepi")
	for arah in ["kiri", "kanan"]:
		var kunci: String = "tepi_" + arah
		if d.has(kunci):
			var t := TepiLokasi.new()
			t.arah = arah
			t.ke = str(d[kunci]["ke"])
			t.spawn = str(d[kunci]["spawn"])
			t.label = str(d[kunci]["label"])
			_tambah(tepi, t, "Tepi" + arah.capitalize())

	# ayam kampung (dulu dibuat lewat kode)
	var ayam_cfg: Array = []
	if id == "lapangan":
		ayam_cfg = [[90.0, 256.0, 60.0, 520.0, "#8a4a28"], [470.0, 256.0, 60.0, 520.0, "#d8c8a8"]]
	elif id == "gang":
		ayam_cfg = [[320.0, 239.0, 250.0, 700.0, "#8a4a28"], [560.0, 239.0, 250.0, 700.0, "#d8c8a8"]]
	var i: int = 1
	for c in ayam_cfg:
		var ay: Ayam = AYAM_SCENE.instantiate() as Ayam
		ay.position = Vector2(float(c[0]), float(c[1]))
		ay.x_min = float(c[2])
		ay.x_max = float(c[3])
		ay.warna = Color(str(c[4]))
		_tambah(ent, ay, "Ayam%d" % i)
		i += 1

	# pemain pratinjau (hanya tampil di editor; dibuang saat game berjalan)
	var pv: Node = PLAYER_SCENE.instantiate()
	pv.position = first_pos
	pv.set("editor_preview_sprite_height", r.tinggi_sprite)
	_tambah(ent, pv, "PlayerPratinjau")
	pv.add_to_group("preview_editor", true)

	var ps := PackedScene.new()
	var err: int = ps.pack(r)
	if err != OK:
		push_error("Gagal pack " + id + ": " + str(err))
		return
	var path: String = "res://scenes/maps/%s.tscn" % id
	err = ResourceSaver.save(ps, path)
	print(id, " -> ", path, " (", err, ")")
	r.free()
