extends Node
## Mencetak GameData.EVENTS dan TUGAS sebagai JSON (dipakai untuk membandingkan dengan data lama).
func _ready() -> void:
	var f := FileAccess.open("/tmp/data_baru.json", FileAccess.WRITE)
	f.store_string(JSON.stringify({"events": GameData.EVENTS, "tugas": GameData.TUGAS, "galat": Naskah.galat}))
	f.close()
	get_tree().quit()
