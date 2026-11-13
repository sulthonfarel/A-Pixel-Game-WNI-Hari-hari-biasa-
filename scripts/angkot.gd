class_name Angkot
extends Node2D
## Angkot Cibiru–Ujungberung yang melintas di jalur depan gang.
## Visual: assets/angkot.png (dibuat dari angkot.jpg lewat tools/make_angkot.py).

const TEKSTUR: Texture2D = preload("res://assets/angkot.png")

@export var vx: float = 60.0
@export var x_end: float = 1200.0


func _process(delta: float) -> void:
	position.x += vx * delta
	if (vx > 0.0 and position.x > x_end) or (vx < 0.0 and position.x < -140.0):
		queue_free()
	queue_redraw()


func _draw() -> void:
	var dir: float = 1.0 if vx > 0.0 else -1.0
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(dir, 1.0))
	draw_texture_rect(TEKSTUR, Rect2(-95, -104, 190, 103), false)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
