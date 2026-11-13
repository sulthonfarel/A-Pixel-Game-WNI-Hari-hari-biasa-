class_name DataCerita
extends RefCounted
## Mengubah berkas data/naskah/berita.naskah dan tugas.naskah menjadi struktur yang dipakai game
## (GameData.EVENTS dan GameData.TUGAS). Tidak berisi cerita sama sekali; semua teks ada di berkas.


## Satu berita = satu simpul "== id". Kunci: hari, tipe, judul, isi, efek, kata.<tokoh>, warga (daftar '-').
static func berita() -> Array:
	var doc: Dictionary = Naskah.muat("berita")
	var out: Array = []
	for id in doc["urut"]:
		var e: Dictionary = {"id": id, "day": 1, "tipe": "berita", "judul": "", "isi": "", "eff": {}, "kata": {}, "warga": []}
		for br in doc["bagian"][id]["baris"]:
			var k: String = br["k"]
			match k:
				"hari":
					e["day"] = int(br["v"])
				"tipe":
					e["tipe"] = br["v"]
				"judul":
					e["judul"] = br["v"]
				"isi":
					e["isi"] = br["v"]
				"efek":
					e["eff"] = br["efek_p"]
				"warga":
					for it in br["item"]:
						e["warga"].append(it["v"])
				_:
					if k.begins_with("kata."):
						e["kata"][k.substr(5)] = br["v"]
					else:
						Naskah.lapor("berita.naskah:%d: kunci '%s' tidak dikenal" % [int(br["no"]), k])
		if e["kata"].is_empty():
			e.erase("kata")
		if e["warga"].is_empty():
			e.erase("warga")
		out.append(e)
	return out


## Tugas kuliah. Kunci: nama, mulai, tenggat.
static func tugas() -> Array:
	var doc: Dictionary = Naskah.muat("tugas")
	var out: Array = []
	for id in doc["urut"]:
		var t: Dictionary = {"id": id, "nama": id, "mulai": 1, "tenggat": 1}
		for br in doc["bagian"][id]["baris"]:
			match str(br["k"]):
				"nama":
					t["nama"] = br["v"]
				"mulai", "tenggat":
					t[br["k"]] = int(br["v"])
				_:
					Naskah.lapor("tugas.naskah:%d: kunci '%s' tidak dikenal" % [int(br["no"]), br["k"]])
		out.append(t)
	return out
