extends Node
## Uji kesetaraan: dialog lama (tools/dialog_lama.gd, dari kode) vs dialog baru (data/naskah/*.naskah).
##   godot --headless --path . res://tools/uji_dialog.tscn
## Membandingkan teks (spasi/baris baru diabaikan), pilihan, efek, lanjutan, dan aksi pada banyak
## keadaan permainan acak. Gagal bila ada satu saja perbedaan.

const KASUS := 600
const TOKOH: Array = ["tati", "asep", "rani", "fikri", "darto", "mira", "rw", "yoga", "ustaz", "imam", "ujang", "pelanggan1", "pelanggan2"]
const FLAG: Array = ["hoax_beras", "hoax_selesai", "hoax_cek", "hoax_forward", "hoax_abaikan", "program_launch",
	"testimoni_tati", "testimoni_asep", "testimoni_rani", "testimoni_fikri", "testimoni_mira", "testimoni_ustaz",
	"rani_cerita", "rani_janji", "rw_pertanyaan_rani", "paket_dibawa", "paket_selesai", "surat_mulai", "surat_selesai",
	"catatan_diserahkan", "rapat_hadir", "sewa_lunas", "kursi", "bantu_tati"]
const UANG: Array = [0, 5000, 8500, 20000, 900000]

var gagal: int = 0
var dicek: int = 0


func _ready() -> void:
	var event_ids: Array = []
	for e in GameData.EVENTS:
		event_ids.append(e["id"])
	for kasus in range(KASUS):
		for npc in TOKOH:
			_atur(kasus, event_ids)
			DialogLama.hub(npc)
			var lama: Dictionary = DialogLama.nodes.duplicate(true)
			_atur(kasus, event_ids)
			DialogueDB.hub(npc)
			for id in lama.keys():
				_banding("%s kasus#%d simpul %s" % [npc, kasus, id], lama[id], DialogueDB.ambil(id))
		_atur(kasus, event_ids)
		DialogLama.build_rapat()
		var rl: Array = _telusur(func(i: String) -> Dictionary: return DialogLama.nodes.get(i, {}), "r1")
		_atur(kasus, event_ids)
		DialogueDB.build_rapat()
		var rb: Array = _telusur(func(i: String) -> Dictionary: return DialogueDB.ambil(i), "r1")
		dicek += 1
		if rl != rb:
			gagal += 1
			print("BEDA rapat kasus#", kasus, "\n  lama: ", rl, "\n  baru: ", rb)
	_atur(0, event_ids)
	DialogLama.build_intro()
	var il: Array = _telusur(func(i: String) -> Dictionary: return DialogLama.nodes.get(i, {}), "intro_1")
	DialogueDB.build_intro()
	var ib: Array = _telusur(func(i: String) -> Dictionary: return DialogueDB.ambil(i), "intro_1")
	dicek += 1
	if il != ib:
		gagal += 1
		print("BEDA intro")
	print("Naskah.galat: ", Naskah.galat)
	print("HASIL: %d pembandingan, %d beda" % [dicek, gagal])
	get_tree().quit(1 if (gagal > 0 or not Naskah.galat.is_empty()) else 0)


## Keadaan permainan acak yang deterministik (kasus yang sama = keadaan yang sama).
func _atur(kasus: int, event_ids: Array) -> void:
	var r := RandomNumberGenerator.new()
	r.seed = 1000 + kasus
	GameState.reset()
	TimeManager.day = r.randi_range(1, 28)
	TimeManager.minutes = r.randi_range(360, 1439)
	for f in FLAG:
		if r.randf() < 0.4:
			GameState.flags[f] = true
	if r.randf() < 0.3:
		GameState.flags["ustaz_bantu_d" + str(TimeManager.day)] = true
	GameState.uang = UANG[r.randi() % UANG.size()]
	GameState.utang = 7000 if r.randf() < 0.3 else 0
	GameState.inv["paket"] = r.randi_range(0, 1)
	GameState.inv["salinan"] = r.randi_range(0, 1)
	GameState.counters["proyek"] = r.randi_range(0, 3)
	GameState.counters["listrik"] = r.randi_range(0, 7)
	for k in ["tati", "asep", "rani", "fikri", "darto", "mira", "rw", "yoga", "ustaz", "imam", "ujang"]:
		GameState.rel[k] = r.randi_range(0, 6)
		GameState.talk_count[k] = r.randi_range(0, 8)
	for k in ["pelanggan1", "pelanggan2"]:
		GameState.talk_count[k] = r.randi_range(0, 8)
	GameState.news_log.clear()
	for id in event_ids:
		if r.randf() < 0.5:
			GameState.news_log.append(id)


## Teks seperti yang dilihat pemain: placeholder diisi, spasi/baris baru diratakan.
func _n(s: String) -> String:
	return " ".join(DialogueDB.fill(s).replace("\n", " ").split(" ", false))


func _eff(e: Dictionary) -> Dictionary:
	var o: Dictionary = e.duplicate(true)
	for k in ["flag"]:
		if o.has(k):
			var a: Array = o[k] if o[k] is Array else [o[k]]
			a = a.map(func(x): return str(x))
			a.sort()
			o[k] = a
	return o


func _pil(c: Dictionary) -> Dictionary:
	return {"t": _n(str(c["t"])), "n": str(c.get("n", "")), "aksi": str(c.get("aksi", "")), "eff": _eff(c.get("eff", {}))}


func _banding(label: String, lama: Dictionary, baru: Dictionary) -> void:
	dicek += 1
	var ok: bool = not baru.is_empty()
	var pesan: String = ""
	if ok and str(lama.get("s", "")) != str(baru.get("s", "")):
		ok = false
		pesan = "pembicara: '%s' vs '%s'" % [lama.get("s", ""), baru.get("s", "")]
	if ok and _n(str(lama["t"])) != _n(str(baru["t"])):
		ok = false
		pesan = "teks:\n    lama: %s\n    baru: %s" % [_n(str(lama["t"])), _n(str(baru["t"]))]
	if ok and _eff(lama.get("eff", {})) != _eff(baru.get("eff", {})):
		ok = false
		pesan = "efek: %s vs %s" % [lama.get("eff", {}), baru.get("eff", {})]
	if ok and str(lama.get("next", "")) != str(baru.get("next", "")):
		ok = false
		pesan = "lanjut: '%s' vs '%s'" % [lama.get("next", ""), baru.get("next", "")]
	if ok and str(lama.get("aksi", "")) != str(baru.get("aksi", "")):
		ok = false
		pesan = "aksi"
	if ok:
		var cl: Array = (lama["ch"] as Array).map(_pil)
		var cb: Array = (baru["ch"] as Array).map(_pil)
		if cl != cb:
			ok = false
			pesan = "pilihan:\n    lama: %s\n    baru: %s" % [cl, cb]
	if not ok:
		gagal += 1
		if gagal <= 12:
			print("BEDA ", label, " -> ", pesan if pesan != "" else "simpul tidak ditemukan")


## Telusuri semua simpul yang dapat dicapai dari 'mulai' dan kembalikan daftar ciri-cirinya (terurut).
func _telusur(ambil: Callable, mulai: String) -> Array:
	var hasil: Array = []
	var antri: Array = [mulai]
	var lihat: Dictionary = {}
	while not antri.is_empty():
		var id: String = antri.pop_front()
		if id == "" or lihat.has(id):
			continue
		lihat[id] = true
		var n: Dictionary = ambil.call(id)
		if n.is_empty():
			hasil.append("HILANG:" + id)
			continue
		var cs: Array = (n["ch"] as Array).map(_pil)
		hasil.append(str([str(n.get("s", "")), _n(str(n["t"])), _eff(n.get("eff", {})), cs, str(n.get("aksi", ""))]))
		if n.has("next"):
			antri.append(str(n["next"]))
		for c in n["ch"]:
			if c.has("n"):
				antri.append(str(c["n"]))
	hasil.sort()
	return hasil
