class_name HudIkon
extends Control
## Ikon kecil di HUD yang digambar lewat kode: matahari, senja, bulan, atau awan hujan.

var mode: int = 0   # 0 siang, 1 senja, 2 malam, 3 hujan
var _t: float = 0.0


func _init() -> void:
	custom_minimum_size = Vector2(14, 14)


func _process(d: float) -> void:
	_t += d
	queue_redraw()


func _draw() -> void:
	var c := Vector2(7, 7)
	match mode:
		0:
			draw_circle(c, 3.0, Color("#ffd84a"))
			for i in range(8):
				var a: float = float(i) * TAU / 8.0 + _t * 0.6
				draw_line(c + Vector2(cos(a), sin(a)) * 4.5, c + Vector2(cos(a), sin(a)) * 6.5, Color("#ffd84a"), 1.0)
		1:
			draw_circle(Vector2(7, 9), 3.5, Color("#ff9a4a"))
			draw_rect(Rect2(0, 9, 14, 5), Color(0.06, 0.06, 0.1, 0.9))
			draw_line(Vector2(0, 9), Vector2(14, 9), Color("#ffb86a"), 1.0)
		2:
			draw_circle(c, 4.5, Color("#e8e4c8"))
			draw_circle(c + Vector2(2.2, -1.5), 4.0, Color(0.06, 0.06, 0.1))
		3:
			draw_circle(Vector2(5, 6), 3.0, Color("#9aa8b8"))
			draw_circle(Vector2(9, 5), 3.5, Color("#aab6c6"))
			draw_rect(Rect2(3, 6, 9, 3), Color("#9aa8b8"))
			for i in range(3):
				var y: float = 10.0 + fmod(_t * 12.0 + float(i) * 2.0, 4.0)
				draw_line(Vector2(4 + i * 3, y), Vector2(3 + i * 3, y + 2), Color("#8fc4ff"), 1.0)
