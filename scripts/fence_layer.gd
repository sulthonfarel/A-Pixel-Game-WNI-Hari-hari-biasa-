@tool
class_name FenceLayer
extends Node2D
## Pagar koridor yang digambar di DEPAN pemain, sehingga Dimas terlihat berdiri di balik pagar.
## Pagar dibuat menyambung dari ujung ke ujung (celah di depan pintu kamar sudah ditutup).

## Area pagar: [x_kiri, x_kanan, y_atas_rel, y_bawah_rel]
@export var area: PackedInt32Array = PackedInt32Array([0, 480, 224, 259]):
	set(v):
		area = v
		_terapkan()
var x0: float = 0.0
var x1: float = 480.0
var y_top: float = 224.0
var y_bot: float = 259.0

const BAR_PHASE := 204.2     # mengikuti jarak & posisi batang pagar pada gambar asli
const BAR_STEP := 9.65
const BAR_FROM := 60.0       # sisi kiri (x < 58) memakai batang bawaan gambar


func _ready() -> void:
	_terapkan()


func _terapkan() -> void:
	if area.size() < 4:
		return
	x0 = float(area[0])
	x1 = float(area[1])
	y_top = float(area[2])
	y_bot = float(area[3])
	queue_redraw()


func _draw() -> void:
	var hi := Color("#aaa3a3")
	var mid := Color("#80797b")
	var lo := Color("#4b4648")
	var bar := Color("#6b6669")
	var bar_hi := Color("#938d8f")
	var w: float = x1 - x0
	# batang
	var n: int = int(ceil((BAR_FROM - BAR_PHASE) / BAR_STEP))
	var x: float = BAR_PHASE + float(n) * BAR_STEP
	while x < x1 - 3.0:
		var xi: float = round(x)
		draw_rect(Rect2(xi, y_top + 3.0, 2.0, y_bot - y_top + 1.0), bar)
		draw_rect(Rect2(xi, y_top + 3.0, 1.0, y_bot - y_top + 1.0), bar_hi)
		x += BAR_STEP
	# rel atas & bawah
	draw_rect(Rect2(x0, y_top, w, 1.0), hi)
	draw_rect(Rect2(x0, y_top + 1.0, w, 2.0), mid)
	draw_rect(Rect2(x0, y_top + 3.0, w, 1.0), lo)
	draw_rect(Rect2(x0, y_bot, w, 2.0), mid)
	draw_rect(Rect2(x0, y_bot + 2.0, w, 1.0), lo)
	# tiang (ujung kiri, dua tiang tengah, ujung kanan di mulut tangga)
	for px in [0.0, 56.0, 192.0, x1 - 3.0]:
		draw_rect(Rect2(px, y_top - 1.0, 3.0, 270.0 - y_top), mid)
		draw_rect(Rect2(px, y_top - 1.0, 1.0, 270.0 - y_top), hi)
		draw_rect(Rect2(px + 2.0, y_top - 1.0, 1.0, 270.0 - y_top), lo)
