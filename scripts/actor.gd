@tool
class_name Actor
extends Node2D
## Tokoh pixel-art. Memuat sprite sheet assets/chars/<id>_<tinggi>.png (tinggi 50/62/100),
## kaki di titik asal. NPC memakai 2 frame diam yang bergantian pelan.

var npc_id: String = ""
var nama: String = ""
var show_label: bool = true
var tex: Texture2D = null
var cell: int = 0
var sprite_h: int = 50
var moving: bool = false
var facing: int = 1
var _t: float = 0.0


func setup(id: String, h: int = 50) -> void:
	npc_id = id
	scale = Vector2(0.7, 0.7)
	nama = str(GameData.NPC[id]["nama"])
	_t = randf() * 10.0
	set_sprite(h)


func set_sprite(h: int) -> void:
	sprite_h = h
	var p: String = "res://assets/chars/%s_%d.png" % [npc_id, h]
	tex = null
	cell = 0
	if ResourceLoader.exists(p):
		tex = load(p) as Texture2D
		cell = tex.get_height()
	queue_redraw()


func _frame() -> int:
	return int(_t * 1.2) % 2


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var sh: float = float(sprite_h)
	draw_rect(Rect2(-sh * 0.2, -1, sh * 0.4, 3), Color(0, 0, 0, 0.25))
	if tex == null:
		draw_rect(Rect2(-sh * 0.12, -sh * 0.9, sh * 0.24, sh * 0.9), Color("#888888"))
	else:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(float(facing), 1.0))
		draw_texture_rect_region(tex, Rect2(-cell / 2.0, -cell + 1.0, cell, cell), Rect2(_frame() * cell, 0, cell, cell))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if show_label and nama != "":
		var f: Font = ThemeDB.fallback_font
		var p := Vector2(-60, -sh - 5.0)
		draw_string_outline(f, p, nama, HORIZONTAL_ALIGNMENT_CENTER, 120, 7, 3, Color(0, 0, 0, 0.9))
		draw_string(f, p, nama, HORIZONTAL_ALIGNMENT_CENTER, 120, 7, Color(1, 1, 1, 0.97))
