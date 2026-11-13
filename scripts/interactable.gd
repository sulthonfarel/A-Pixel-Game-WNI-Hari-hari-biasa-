@tool
class_name Interactable
extends Node2D
## Objek lokasi yang bisa jadi titik interaksi dan/atau penghalang. Posisi node = pojok kiri-atas kotak.
## Nama node = id objek (dipakai main.gd di _objek()). Di editor kotaknya tampil berwarna:
## merah = penghalang, biru = bisa diinteraksi, abu = dekor.

## Tulisan prompt interaksi. Kosong = bukan titik interaksi (dekor/penghalang saja).
@export var label: String = ""
@export var size: Vector2 = Vector2(32, 32):
	set(v):
		size = v
		queue_redraw()
## Menghalangi jalan pemain.
@export var solid: bool = false
## Bila diisi, objek hanya aktif ketika flag ini menyala (mis. "jumat_berkah_aktif").
@export var syarat_flag: String = ""
## Warna placeholder untuk lokasi tanpa latar gambar. Hitam (#000000) = tak kasatmata.
@export var warna: Color = Color(0, 0, 0, 1)
## Tulisan di atas placeholder (opsional).
@export var teks: String = ""


func aktif() -> bool:
	if syarat_flag == "":
		return true
	return GameState.has_flag(syarat_flag)


## Kotak dalam koordinat lokasi (induk LocationView).
func rect_di(view: Node2D) -> Rect2:
	return Rect2(view.to_local(global_position), size)


func _warna_gizmo() -> Color:
	if solid:
		return Color(1.0, 0.3, 0.3)
	if label != "":
		return Color(0.3, 0.8, 1.0)
	return Color(0.7, 0.7, 0.7)


func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	var c: Color = _warna_gizmo()
	draw_rect(Rect2(Vector2.ZERO, size), Color(c.r, c.g, c.b, 0.18))
	draw_rect(Rect2(Vector2.ZERO, size), Color(c.r, c.g, c.b, 0.9), false, 1.0)
	draw_string(ThemeDB.fallback_font, Vector2(2, 9), String(name), HORIZONTAL_ALIGNMENT_LEFT, size.x, 8, Color(1, 1, 1, 0.9))
