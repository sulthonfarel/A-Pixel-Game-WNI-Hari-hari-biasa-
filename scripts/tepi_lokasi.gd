@tool
class_name TepiLokasi
extends Marker2D
## Tepi lokasi yang tembus ke lokasi lain saat pemain berjalan sampai ujung (mis. ujung gang -> lapangan).
## Posisi diabaikan; yang dipakai hanya arah, tujuan, dan tulisan prompt.

@export_enum("kiri", "kanan") var arah: String = "kanan"
@export var ke: String = ""
@export var spawn: String = ""
@export var label: String = ""
