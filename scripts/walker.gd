class_name Walker
extends Actor
## Warga yang lewat di trotoar gang (hiasan hidup). Memakai sprite NPC yang sama.

var vx: float = 20.0
var x_end: float = 1100.0


func _frame() -> int:
	return int(_t * 4.0) % 2


func _process(delta: float) -> void:
	position.x += vx * delta
	facing = 1 if vx > 0.0 else -1
	if (vx > 0.0 and position.x > x_end) or (vx < 0.0 and position.x < -40.0):
		queue_free()
		return
	super._process(delta)
