class_name Ayam
extends Node2D
## Ayam kampung yang berkeliaran di trotoar.

@export var x_min: float = 250.0
@export var x_max: float = 700.0
var vx: float = 0.0
var _t: float = 0.0
var _plan: float = 0.0
@export var warna: Color = Color("#8a4a28")


func _process(delta: float) -> void:
	_t += delta
	_plan -= delta
	if _plan <= 0.0:
		_plan = randf_range(1.0, 3.5)
		vx = [0.0, 0.0, 9.0, -9.0][randi() % 4]
	position.x = clampf(position.x + vx * delta, x_min, x_max)
	queue_redraw()


func _draw() -> void:
	var dir: float = 1.0 if vx >= 0.0 else -1.0
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(dir, 1.0))
	var peck: float = 3.0 if (vx == 0.0 and sin(_t * 6.0) > 0.4) else 0.0
	draw_rect(Rect2(-5, -9, 10, 6), warna)                 # badan
	draw_rect(Rect2(-7, -11, 4, 4), warna.darkened(0.25))  # ekor
	draw_rect(Rect2(3, -12 + peck, 4, 5), warna)           # leher
	draw_rect(Rect2(5, -14 + peck, 4, 4), warna.lightened(0.15))
	draw_rect(Rect2(9, -12 + peck, 2, 1), Color("#e8b838"))  # paruh
	draw_rect(Rect2(6, -15 + peck, 2, 2), Color("#c83830"))  # jengger
	draw_rect(Rect2(-2, -3, 1, 3), Color("#e8b838")); draw_rect(Rect2(2, -3, 1, 3), Color("#e8b838"))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
