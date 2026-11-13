class_name Naskah
extends RefCounted
## Pembaca berkas .naskah (format teks untuk dialog, berita, dan tugas). Panduan menulis: data/naskah/PANDUAN.md
##
## Hasil membaca satu berkas:
##   { "id": nama_berkas, "urut": [id_simpul, ...], "bagian": { id_simpul: {"id", "no", "baris": [...] } } }
## Tiap baris: { "k": kunci, "v": nilai, "no": nomor_baris, "syarat": [...], "efek_p": {...},
##               "item": [ {"v", "no", "syarat", "efek_p"} ... ] }
## Kondisi ("| jika ...") dan efek ("| efek ..." atau baris "efek:") sudah di-parse saat berkas dimuat.

const FOLDER := "res://data/naskah/"

static var _cache: Dictionary = {}
## Daftar pesan kesalahan sejak game berjalan (dibaca tools/cek_naskah.gd).
static var galat: Array = []


static func lapor(pesan: String) -> void:
	galat.append(pesan)
	push_error("[naskah] " + pesan)


static func kosongkan_cache() -> void:
	_cache.clear()
	galat.clear()


static func muat(nama: String) -> Dictionary:
	if _cache.has(nama):
		return _cache[nama]
	var path: String = FOLDER + nama + ".naskah"
	var doc: Dictionary = {"id": nama, "urut": [], "bagian": {}}
	if not FileAccess.file_exists(path):
		lapor("%s: berkas tidak ditemukan" % path)
	else:
		_urai(FileAccess.get_file_as_string(path), path, doc)
	_cache[nama] = doc
	return doc


static func ada(nama: String) -> bool:
	return FileAccess.file_exists(FOLDER + nama + ".naskah")


## Semua nama berkas .naskah di folder data (tanpa ekstensi).
static func daftar_berkas() -> Array:
	var out: Array = []
	for f in DirAccess.get_files_at(FOLDER):
		if f.ends_with(".naskah"):
			out.append(f.trim_suffix(".naskah"))
	out.sort()
	return out


static func _kunci_valid(k: String) -> bool:
	if k == "":
		return false
	for i in range(k.length()):
		var c: String = k[i]
		var ok: bool = (c >= "a" and c <= "z") or c == "_" or c == "." or (i > 0 and c >= "0" and c <= "9")
		if not ok:
			return false
	return true


static func _urai(teks: String, path: String, doc: Dictionary) -> void:
	var bagian: Dictionary = doc["bagian"]
	var cur: Dictionary = {}
	var baris_akhir: Dictionary = {}
	var item_akhir: Dictionary = {}
	var no: int = 0
	var isi: String = teks.replace("\r\n", "\n").trim_prefix("\ufeff")
	for mentah in isi.split("\n"):
		no += 1
		var l: String = mentah
		var s: String = l.strip_edges()
		if s == "" or s.begins_with("#"):
			continue
		var lok: String = "%s:%d" % [path, no]
		if l.begins_with("=="):
			var id: String = l.substr(2).strip_edges()
			if id == "":
				lapor(lok + ": '==' harus diikuti id simpul")
				continue
			if bagian.has(id):
				lapor(lok + ": id simpul '%s' sudah dipakai di baris %d" % [id, int(bagian[id]["no"])])
			cur = {"id": id, "no": no, "baris": []}
			bagian[id] = cur
			doc["urut"].append(id)
			baris_akhir = {}
			item_akhir = {}
			continue
		if cur.is_empty():
			lapor(lok + ": baris di luar simpul (mulai dengan '== id')")
			continue
		if l.begins_with(" ") or l.begins_with("\t"):
			# lanjutan baris sebelumnya
			if not item_akhir.is_empty():
				item_akhir["mentah"] = str(item_akhir["mentah"]) + " " + s
			elif not baris_akhir.is_empty():
				baris_akhir["mentah"] = str(baris_akhir["mentah"]) + " " + s
			else:
				lapor(lok + ": baris lanjutan tanpa baris induk")
			continue
		if s.begins_with("- "):
			if baris_akhir.is_empty():
				lapor(lok + ": item '-' harus berada di bawah kunci (mis. 'pilihan:')")
				continue
			var it: Dictionary = {"mentah": s.substr(2).strip_edges(), "no": no}
			(baris_akhir["item"] as Array).append(it)
			item_akhir = it
			continue
		var p: int = s.find(":")
		var kunci: String = s.substr(0, p).strip_edges() if p > 0 else ""
		if not _kunci_valid(kunci):
			lapor(lok + ": baris tidak dikenali -> '%s' (format: kunci: nilai)" % s.left(50))
			continue
		var br: Dictionary = {"k": kunci, "mentah": s.substr(p + 1).strip_edges(), "item": [], "no": no}
		cur["baris"].append(br)
		baris_akhir = br
		item_akhir = {}
	# tahap 2: pisahkan "| jika" / "| efek" lalu kompilasi
	for id in doc["urut"]:
		for br in bagian[id]["baris"]:
			_selesaikan_baris(br, path)
			for it in br["item"]:
				_selesaikan_baris(it, path)


static func _selesaikan_baris(b: Dictionary, path: String) -> void:
	var lok: String = "%s:%d" % [path, int(b["no"])]
	var bagian: PackedStringArray = str(b["mentah"]).split(" | ")
	b["v"] = bagian[0].strip_edges().replace("\\n", "\n")
	var jika: String = ""
	var efek: String = ""
	for i in range(1, bagian.size()):
		var seg: String = bagian[i].strip_edges()
		if seg.begins_with("jika "):
			jika = seg.substr(5).strip_edges()
		elif seg.begins_with("efek "):
			efek = seg.substr(5).strip_edges()
		else:
			lapor(lok + ": bagian '| %s' tidak dikenali (pakai '| jika ...' atau '| efek ...')" % seg.left(30))
	b["syarat"] = Syarat.parse(jika, lok)
	var gabung: String = efek
	if b.has("k") and b["k"] == "efek":
		gabung = (str(b["v"]) + ", " + efek) if efek != "" else str(b["v"])
	b["efek_p"] = Efek.parse(gabung, lok)
	b.erase("mentah")
