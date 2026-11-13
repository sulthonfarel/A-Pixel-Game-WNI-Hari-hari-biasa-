extends Node
## Harga barang & transportasi. Event berita mengubah pengali harga per "tag".

var mult: Dictionary = {}    # tag -> pengali
var habis: Dictionary = {}   # item -> sisa hari kosong


func reset() -> void:
	mult = {}
	habis = {}


func _bulat(nilai: float) -> int:
	return int(round(nilai / 500.0)) * 500


func harga(item_id: String) -> int:
	var it: Dictionary = GameData.ITEMS[item_id]
	var tag: String = str(it.get("tag", ""))
	var m: float = float(mult.get(tag, 1.0))
	return _bulat(float(it["harga"]) * m)


func tersedia(item_id: String) -> bool:
	return not habis.has(item_id)


func apply_event(eff: Dictionary) -> void:
	if eff.has("harga"):
		for tag in eff["harga"].keys():
			mult[tag] = float(mult.get(tag, 1.0)) * float(eff["harga"][tag])
	if eff.has("habis"):
		for it in eff["habis"].keys():
			habis[it] = int(eff["habis"][it])


func tick_day() -> void:
	for it in habis.keys():
		habis[it] = int(habis[it]) - 1
		if int(habis[it]) <= 0:
			habis.erase(it)


func transport(mode: String) -> Dictionary:
	var t: Dictionary = GameData.TRANSPORT[mode]
	var h: int = int(t["harga"])
	var tag: String = str(t["tag"])
	if tag != "":
		h = _bulat(float(h) * float(mult.get(tag, 1.0)))
	var menit: int = int(t["menit"])
	var energi: int = int(t["energi"])
	var hujan: bool = TimeManager.raining
	var tutup: bool = GameState.has_flag("jalan_ditutup")
	if mode == "angkot":
		if GameState.has_flag("rute_angkot"):
			menit += 10
		if tutup:
			menit += 10
		if hujan:
			menit += 10
	elif mode == "jalan":
		if tutup:
			menit += 15
		if hujan:
			menit += 10
			energi += 5
	elif mode == "ojol":
		if tutup:
			menit += 5
		if hujan:
			h += 3000
			menit += 5
		if GameState.relasi("fikri") >= 3:
			h = maxi(0, h - 2000)
	return {"harga": h, "menit": menit, "energi": energi}
