class_name InteractMarker
extends Node2D
## Panah kecil + kotak tombol [E] yang melayang di atas objek/tokoh yang bisa diajak interaksi.

var target: Vector2 = Vector2.ZERO
var aktif: bool = false
var _alpha: float = 0.0
var _t: float = 0.0


func _ready() -> void:
	z_index = 90


func tunjuk(pos: Vector2) -> void:
	if not aktif or _alpha < 0.05:
		position = pos
	target = pos
	aktif = true


func sembunyi() -> void:
	aktif = false


func _process(delta: float) -> void:
	_t += delta
	_alpha = move_toward(_alpha, 1.0 if aktif else 0.0, delta * 6.0)
	position = position.lerp(target, clampf(delta * 14.0, 0.0, 1.0))
	visible = _alpha > 0.01
	if visible:
		queue_redraw()


func _draw() -> void:
	var bob: float = sin(_t * 5.0) * 1.5
	var a: float = _alpha
	var f: Font = ThemeDB.fallback_font
	# kotak tombol
	var r := Rect2(-6.0, -17.0 + bob, 12.0, 12.0)
	draw_rect(Rect2(r.position + Vector2(0, 1), r.size), Color(0, 0, 0, 0.45 * a))
	draw_rect(r, Color(0.96, 0.78, 0.4, a))
	draw_rect(r.grow(-1.0), Color(0.12, 0.12, 0.2, a))
	draw_string(f, Vector2(-3.0, -7.5 + bob), "E", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(1, 0.92, 0.65, a))
	# panah ke bawah
	draw_colored_polygon(PackedVector2Array([Vector2(-3, -4 + bob), Vector2(3, -4 + bob), Vector2(0, -0.5 + bob)]), Color(0.96, 0.78, 0.4, a))
