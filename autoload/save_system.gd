extends Node
## Simpan otomatis tiap tidur, dan simpan manual dari menu jeda (menyimpan lokasi & posisi).

const PATH := "user://wni_save.json"
const VERSI := 2

var last_loc: String = "kos_room"
var last_pos: Vector2 = Vector2(-1.0, -1.0)


func ada() -> bool:
	return FileAccess.file_exists(PATH)


func simpan(loc: String = "kos_room", pos: Vector2 = Vector2(-1.0, -1.0)) -> bool:
	var data: Dictionary = {
		"versi": VERSI,
		"gs": GameState.to_dict(),
		"day": TimeManager.day,
		"minutes": TimeManager.minutes,
		"raining": TimeManager.raining,
		"mult": Economy.mult,
		"habis": Economy.habis,
		"loc": loc,
		"px": pos.x,
		"py": pos.y,
	}
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify(data))
	f.close()
	return true


func muat() -> bool:
	if not ada():
		return false
	var f := FileAccess.open(PATH, FileAccess.READ)
	if f == null:
		return false
	var txt: String = f.get_as_text()
	f.close()
	var parsed: Variant = JSON.parse_string(txt)
	if typeof(parsed) != TYPE_DICTIONARY:
		return false
	var d: Dictionary = parsed
	if not (d.has("gs") and d.has("day") and d.has("minutes")):
		return false
	GameState.from_dict(d["gs"])
	TimeManager.reset()
	TimeManager.day = clampi(int(d["day"]), 1, GameData.JUMLAH_HARI)
	TimeManager.minutes = clampi(int(d["minutes"]), 360, 1439)
	TimeManager.raining = bool(d.get("raining", false))
	Economy.reset()
	var m: Dictionary = d.get("mult", {})
	for k in m.keys():
		Economy.mult[k] = float(m[k])
	var h: Dictionary = d.get("habis", {})
	for k in h.keys():
		Economy.habis[k] = int(h[k])
	last_loc = str(d.get("loc", "kos_room"))
	if not ResourceLoader.exists("res://scenes/maps/%s.tscn" % last_loc):
		last_loc = "kos_room"
	last_pos = Vector2(float(d.get("px", -1.0)), float(d.get("py", -1.0)))
	return true


func hapus() -> void:
	if ada():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
