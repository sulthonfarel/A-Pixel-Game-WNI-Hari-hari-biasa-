@tool
class_name Pintu
extends Interactable
## Pintu/jalan masuk ke lokasi lain. Nama node = id pintu.

## Id lokasi tujuan (nama berkas di scenes/maps/, mis. "kos_room").
@export var ke: String = ""
## Nama Marker2D di bawah "Spawns" pada lokasi tujuan.
@export var spawn: String = ""
## Nama tujuan untuk prompt otomatis ("Masuk: <nama>" / "Keluar ke <nama>").
@export var nama_tujuan: String = ""


func label_final(dalam_ruangan: bool) -> String:
	if label != "":
		return label
	return ("Keluar ke " if dalam_ruangan else "Masuk: ") + nama_tujuan


func _warna_gizmo() -> Color:
	return Color(1.0, 0.8, 0.2)
