class_name DialogueDB
extends RefCounted
## Penghubung antara kotak dialog dan berkas naskah (data/naskah/*.naskah).
## Seluruh isi dialog ada di berkas naskah; file ini hanya MEMILIH simpul sesuai keadaan permainan.
##
## Simpul diselesaikan saat akan ditampilkan (bukan di awal percakapan), sehingga kondisi
## "| jika ..." selalu memakai keadaan terbaru. Bentuk simpul yang dikembalikan ambil():
##   { "s": pembicara, "t": teks, "ch": [ {"t", "n"|"aksi", "eff"} ], "eff": {...}, "next": id, "aksi": nama }

## Tokoh yang bisa naik akrab lewat obrolan rutin (tiap obrolan ke-3, sampai hubungan 4).
const BISA_AKRAB: Array = ["tati", "asep", "rani", "fikri", "darto", "mira", "rw", "yoga", "ustaz", "imam", "ujang"]

## Simpul sekali-pakai yang dibuat dari kode (mis. teks sistem lewat solo()).
static var nodes: Dictionary = {}
static var _doc: Dictionary = {}
static var _npc: String = ""
static var _cnt: int = 0


# ---------------------------------------------------------------- penyisipan teks
static func fill(t: String) -> String:
	return t.replace("{nama}", GameState.player_name) \
		.replace("{uang}", GameData.rp(GameState.uang)) \
		.replace("{utang}", GameData.rp(GameState.utang)) \
		.replace("{tagihan}", GameData.rp(Daily.sewa_tagihan())) \
		.replace("{listrik}", str(Daily.listrik_hari())) \
		.replace("{catatan}", str(GameState.count_testimoni()))


## Satu baris dialog sekali tampil, dibuat dari kode (mis. kalimat sistem).
static func solo(speaker: String, text: String, eff: Dictionary = {}) -> String:
	nodes.clear()
	var d: Dictionary = {"s": speaker, "t": text, "ch": []}
	if not eff.is_empty():
		d["eff"] = eff
	nodes["solo"] = d
	return "solo"


# ---------------------------------------------------------------- memulai percakapan
## Mulai obrolan dengan seorang tokoh. Mengembalikan id simpul awal ("hub").
static func hub(npc: String) -> String:
	nodes.clear()
	var cnt: int = int(GameState.talk_count.get(npc, 0))
	GameState.talk_count[npc] = cnt + 1
	if cnt % 3 == 2 and BISA_AKRAB.has(npc) and GameState.relasi(npc) < 4:
		GameState.apply_effects({"rel": {npc: 1}})
	_npc = npc
	_cnt = cnt
	_doc = Naskah.muat("pelanggan" if npc.begins_with("pelanggan") else npc)
	return "hub"


static func build_intro() -> void:
	nodes.clear()
	_npc = ""
	_cnt = 0
	_doc = Naskah.muat("intro")


static func build_rapat() -> void:
	nodes.clear()
	_npc = ""
	_cnt = 0
	_doc = Naskah.muat("rapat")


# ---------------------------------------------------------------- menyelesaikan simpul
static func ambil(id: String) -> Dictionary:
	if nodes.has(id):
		return nodes[id]
	var bagian: Dictionary = _doc.get("bagian", {})
	if not bagian.has(id):
		return {}
	return _selesaikan(bagian[id], id)


static func _selesaikan(bag: Dictionary, id: String) -> Dictionary:
	var d: Dictionary = {"s": "", "t": "", "ch": []}
	var teks: String = ""
	var teks_ada: bool = false
	var tambahan: Array = []
	for br in bag["baris"]:
		if not Syarat.cek(br["syarat"]):
			continue
		var v: String = br["v"]
		match str(br["k"]):
			"bicara":
				d["s"] = v
			"teks":
				if not teks_ada:
					teks = v
					teks_ada = true
			"bergilir":
				var pilih: Array = []
				for it in br["item"]:
					if Syarat.cek(it["syarat"]):
						pilih.append(it["v"])
				if not teks_ada and not pilih.is_empty():
					teks = str(pilih[_cnt % pilih.size()])
					teks_ada = true
			"tambah":
				tambahan.append(["\n\n", v])
			"baris":
				tambahan.append(["\n", v])
			"efek":
				d["eff"] = Efek.isi(br["efek_p"])
			"pilihan":
				for it in br["item"]:
					if Syarat.cek(it["syarat"]):
						d["ch"].append(_pilihan(it))
			"lanjut":
				if not d.has("next") and not d.has("aksi"):
					d["next"] = v
			"aksi":
				d["aksi"] = v
	# kabar terbaru dari tokoh ditempel di akhir sapaan (hanya simpul "hub", tidak untuk pelanggan)
	if id == "hub" and _npc != "" and not _npc.begins_with("pelanggan"):
		var k: String = NewsSystem.komentar(_npc, _cnt)
		if k != "":
			teks += "\n\n" + k
	for t in tambahan:
		teks += str(t[0]) + str(t[1])
	if teks.find("{warga}") >= 0:
		var w: Array = NewsSystem.warga_lines()
		teks = teks.replace("{warga}", str(w[(0 if _npc == "pelanggan1" else 1) % w.size()]))
	d["t"] = teks
	return d


static func _pilihan(it: Dictionary) -> Dictionary:
	var m: String = it["v"]
	var i: int = m.rfind(" -> ")
	var c: Dictionary = {"t": m if i < 0 else m.substr(0, i).strip_edges()}
	var tujuan: String = "" if i < 0 else m.substr(i + 4).strip_edges()
	if tujuan.begins_with("aksi "):
		c["aksi"] = tujuan.substr(5).strip_edges()
	elif tujuan != "" and tujuan != "selesai":
		c["n"] = tujuan
	if not (it["efek_p"] as Dictionary).is_empty():
		c["eff"] = Efek.isi(it["efek_p"])
	return c
