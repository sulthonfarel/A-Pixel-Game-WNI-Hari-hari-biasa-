class_name Motor
extends Node2D
## Motor yang melintas di jalur jauh gang (hiasan hidup).

var vx: float = 70.0
@export var body: Color = Color("#b43430")
@export var jaket: Color = Color("#2e9b57")
var x_end: float = 1400.0
var _t: float = 0.0


func _process(delta: float) -> void:
	position.x += vx * delta
	_t += delta
	if (vx > 0.0 and position.x > x_end) or (vx < 0.0 and position.x < -80.0):
		queue_free()
	queue_redraw()


func _draw() -> void:
	var dir: float = 1.0 if vx > 0.0 else -1.0
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(dir, 1.0))
	var dk := Color("#1c1c20")
	var met := Color("#989ca4")
	for cx in [-14.0, 14.0]:
		draw_circle(Vector2(cx, -8), 8.0, dk)
		draw_circle(Vector2(cx, -8), 4.0, met)
		draw_circle(Vector2(cx, -8), 1.5, dk)
	draw_colored_polygon(PackedVector2Array([Vector2(-16, -14), Vector2(-2, -21), Vector2(10, -19), Vector2(12, -10), Vector2(2, -6), Vector2(-12, -6)]), body)
	draw_rect(Rect2(-12, -24, 15, 3), Color("#222026"))
	draw_line(Vector2(12, -10), Vector2(14, -22), met, 2.0)
	draw_line(Vector2(11, -24), Vector2(18, -24), dk, 2.0)
	draw_rect(Rect2(16, -22, 3, 3), Color("#faf0aa"))
	# pengendara
	draw_rect(Rect2(-9, -40, 11, 17), jaket)
	draw_rect(Rect2(-6, -49, 8, 9), Color("#cf9560"))
	draw_rect(Rect2(-7, -52, 10, 5), Color("#202428"))        # helm
	draw_rect(Rect2(1, -30, 12, 3), jaket.darkened(0.15))     # lengan ke stang
	draw_rect(Rect2(-8, -23, 5, 12), Color("#222a3a"))
	if TimeManager.jam() >= 18 or TimeManager.jam() < 5:
		draw_colored_polygon(PackedVector2Array([Vector2(19, -20), Vector2(70, -34), Vector2(70, -6)]), Color(1.0, 0.95, 0.65, 0.16))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
