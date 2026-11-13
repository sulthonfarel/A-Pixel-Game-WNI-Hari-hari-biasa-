extends Node
## Validator naskah: menangkap salah ketik sebelum game dijalankan.
##   godot --headless --path . res://tools/cek_naskah.tscn
## GALAT (menggagalkan): sintaks, kunci tak dikenal, tujuan simpul/aksi tak ada.
## PERINGATAN: simpul yatim (tak bisa dicapai), flag yang dipakai tapi tak pernah dinyalakan, pembicara asing.

const KUNCI_DIALOG: Array = ["bicara", "teks", "bergilir", "tambah", "baris", "efek", "pilihan", "lanjut", "aksi"]
const BUKAN_DIALOG: Array = ["berita", "tugas"]
const PINTU_MASUK: Array = ["hub", "r1", "intro_1"]   # simpul yang dimulai oleh kode game

var galat: Array = []
var peringatan: Array = []
var aksi_dikenal: Array = []
var flag_dinyalakan: Dictionary = {}
var flag_dipakai: Dictionary = {}   # nama -> lokasi pertama
var kode_sumber: String = ""
var nama_tokoh: Array = ["", "{nama}", "Pelanggan", "Dimas"]


func _ready() -> void:
	_baca_kode()
	for k in GameData.NPC.keys():
		nama_tokoh.append(str(GameData.NPC[k]["nama"]))
	var berkas: Array = Naskah.daftar_berkas()
	for nama in berkas:
		var doc: Dictionary = Naskah.muat(nama)
		for br_id in doc["urut"]:
			for br in doc["bagian"][br_id]["baris"]:
				_catat(br, nama)
	for nama in berkas:
		if not BUKAN_DIALOG.has(nama):
			_cek_dialog(nama)
	for g in Naskah.galat:
		galat.append(g)
	for f in flag_dipakai.keys():
		if not flag_dinyalakan.has(f) and kode_sumber.find("\"" + str(f) + "\"") < 0:
			peringatan.append("flag '%s' dipakai di %s tetapi tidak pernah dinyalakan (salah ketik?)" % [f, flag_dipakai[f]])
	print("--- cek naskah: %d berkas ---" % berkas.size())
	for p in peringatan:
		print("PERINGATAN: ", p)
	for g in galat:
		print("GALAT: ", g)
	print("Selesai: %d galat, %d peringatan" % [galat.size(), peringatan.size()])
	get_tree().quit(1 if not galat.is_empty() else 0)


func _baca_kode() -> void:
	var main_src: String = FileAccess.get_file_as_string("res://scripts/main.gd")
	var a: int = main_src.find("func _aksi(")
	var b: int = main_src.find("\nfunc ", a + 10)
	var re := RegEx.new()
	re.compile("(?m)^\\t\\t\"([a-z0-9_]+)\":")
	for m in re.search_all(main_src.substr(a, b - a)):
		aksi_dikenal.append(m.get_string(1))
	for dir in ["res://scripts/", "res://autoload/"]:
		for f in DirAccess.get_files_at(dir):
			if f.ends_with(".gd"):
				kode_sumber += FileAccess.get_file_as_string(dir + f)


func _nyalakan(e: Dictionary) -> void:
	for k in ["flag"]:
		if e.has(k):
			for f in (e[k] as Array):
				flag_dinyalakan[str(f).replace("{hari}", "")] = true
	if e.has("timed"):
		for f in e["timed"].keys():
			flag_dinyalakan[str(f)] = true
	if e.has("flag_hari"):
		flag_dinyalakan[str(e["flag_hari"])] = true


func _catat(b: Dictionary, nama: String) -> void:
	_nyalakan(b["efek_p"])
	for t in b["syarat"]:
		if t["t"] == "flag":
			var f: String = str(t["n"]).replace("{hari}", "")
			if not flag_dipakai.has(f):
				flag_dipakai[f] = "%s.naskah:%d" % [nama, int(b["no"])]
	for it in b.get("item", []):
		_catat(it, nama)


func _cek_dialog(nama: String) -> void:
	var doc: Dictionary = Naskah.muat(nama)
	var bagian: Dictionary = doc["bagian"]
	var dituju: Dictionary = {}
	for id in doc["urut"]:
		var bag: Dictionary = bagian[id]
		for br in bag["baris"]:
			var lok: String = "%s.naskah:%d" % [nama, int(br["no"])]
			var k: String = br["k"]
			if not KUNCI_DIALOG.has(k):
				galat.append("%s: kunci '%s' tidak dikenal (kunci yang ada: %s)" % [lok, k, ", ".join(KUNCI_DIALOG)])
				continue
			if k == "bicara" and not nama_tokoh.has(str(br["v"])):
				peringatan.append("%s: pembicara '%s' bukan tokoh yang dikenal (potret tidak akan muncul)" % [lok, br["v"]])
			if k == "lanjut":
				_tujuan(str(br["v"]), bagian, nama, lok, dituju)
			if k == "aksi":
				_aksi(str(br["v"]), lok)
			if k == "pilihan":
				for it in br["item"]:
					var m: String = str(it["v"])
					var i: int = m.rfind(" -> ")
					var tj: String = "" if i < 0 else m.substr(i + 4).strip_edges()
					var lok2: String = "%s.naskah:%d" % [nama, int(it["no"])]
					if tj.begins_with("aksi "):
						_aksi(tj.substr(5).strip_edges(), lok2)
					elif tj != "" and tj != "selesai":
						_tujuan(tj, bagian, nama, lok2, dituju)
	for id in doc["urut"]:
		if not dituju.has(id) and not PINTU_MASUK.has(id):
			peringatan.append("%s.naskah:%d: simpul '%s' tidak pernah dituju oleh simpul lain (yatim)" % [nama, int(bagian[id]["no"]), id])


func _tujuan(id: String, bagian: Dictionary, nama: String, lok: String, dituju: Dictionary) -> void:
	dituju[id] = true
	if not bagian.has(id):
		galat.append("%s: tujuan simpul '%s' tidak ada di %s.naskah" % [lok, id, nama])


func _aksi(a: String, lok: String) -> void:
	if not aksi_dikenal.has(a):
		galat.append("%s: aksi '%s' tidak dikenal oleh main.gd" % [lok, a])
