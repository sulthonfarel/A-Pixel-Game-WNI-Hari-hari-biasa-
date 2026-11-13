class_name RainOverlay
extends Control
## Hujan 2 lapis, cipratan di tanah, dan petir sesekali (kilat + sinyal `thunder` untuk getar kamera).

signal thunder

var raining: bool = false
var outdoor: bool = true
var drops: PackedVector2Array = PackedVector2Array()
var far_drops: PackedVector2Array = PackedVector2Array()
var splashes: Array = []        # [x, y, umur]
var flash: float = 0.0
var _flash_seq: Array = []
var _next_thunder: float = 25.0
var _thunder_delay: float = -1.0
var _splash_acc: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for i in range(110):
		drops.append(Vector2(randf() * 540.0, randf() * 270.0))
	for i in range(90):
		far_drops.append(Vector2(randf() * 540.0, randf() * 270.0))


func set_cuaca(hujan: bool, luar: bool) -> void:
	if hujan and not raining:
		_next_thunder = randf_range(12.0, 40.0)
	raining = hujan
	outdoor = luar


func _process(delta: float) -> void:
	if flash > 0.0:
		flash = maxf(0.0, flash - delta * 2.4)
	if not _flash_seq.is_empty():
		_flash_seq[0][0] -= delta
		if float(_flash_seq[0][0]) <= 0.0:
			flash = float(_flash_seq[0][1])
			_flash_seq.pop_front()
	if _thunder_delay >= 0.0:
		_thunder_delay -= delta
		if _thunder_delay < 0.0:
			Sfx.play("thunder", 0.9)
			thunder.emit()
	if not raining:
		if flash > 0.0 or not splashes.is_empty():
			splashes.clear()
			queue_redraw()
		return
	_next_thunder -= delta
	if _next_thunder <= 0.0:
		_next_thunder = randf_range(25.0, 70.0)
		_flash_seq = [[0.0, 0.85], [0.14, 0.35], [0.12, 0.7]]
		_thunder_delay = randf_range(0.4, 1.6)
	if outdoor:
		for i in range(drops.size()):
			var p: Vector2 = drops[i] + Vector2(-46, 290) * delta
			if p.y > 272.0 or p.x < -10.0:
				p = Vector2(randf() * 560.0, -10.0)
			drops[i] = p
		for i in range(far_drops.size()):
			var q: Vector2 = far_drops[i] + Vector2(-26, 170) * delta
			if q.y > 272.0 or q.x < -10.0:
				q = Vector2(randf() * 540.0, -10.0)
			far_drops[i] = q
		_splash_acc += delta * 38.0
		while _splash_acc >= 1.0:
			_splash_acc -= 1.0
			splashes.append([randf() * 480.0, randf_range(205.0, 266.0), 0.0])
		for s in splashes:
			s[2] = float(s[2]) + delta
		splashes = splashes.filter(func(s: Array) -> bool: return float(s[2]) < 0.35)
	queue_redraw()


func _draw() -> void:
	if flash > 0.0:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.9, 0.93, 1.0, flash * 0.5))
	if not raining or not outdoor:
		return
	for p in far_drops:
		draw_line(p, p + Vector2(-1.5, 4), Color(0.7, 0.8, 0.95, 0.25), 1.0)
	for p in drops:
		draw_line(p, p + Vector2(-3, 9), Color(0.78, 0.88, 1.0, 0.5), 1.0)
	for s in splashes:
		var t: float = float(s[2]) / 0.35
		var w: float = 1.0 + t * 4.0
		var c := Color(0.85, 0.92, 1.0, (1.0 - t) * 0.6)
		var x: float = float(s[0])
		var y: float = float(s[1])
		draw_line(Vector2(x - w, y), Vector2(x - w * 0.4, y - 1), c, 1.0)
		draw_line(Vector2(x + w, y), Vector2(x + w * 0.4, y - 1), c, 1.0)
