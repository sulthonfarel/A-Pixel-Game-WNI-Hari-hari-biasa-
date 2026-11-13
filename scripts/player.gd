@tool
class_name Player
extends Actor
## Dimas. Frame 0-3 diam • 4-9 jalan • 10 ponsel • 11 garuk kepala • 12 gestur bicara • 13 jalan bawa tas.

const SPEED := 95.0
const FRAME_PONSEL := 10
const FRAME_GARUK := 11
const FRAME_BICARA := 12
const FRAME_TAS := 13

var view: LocationView = null
var pose: int = -1
var _idle_t: float = 0.0
var _walk_t: float = 0.0
var _step_t: float = 0.0
var umbrella: bool = false
var _debu: CPUParticles2D = null
@export_range(50, 150, 1) var editor_preview_sprite_height: int = 100


func _ready() -> void:
	if Engine.is_editor_hint():
		scale = Vector2(0.7, 0.7)
		set_sprite(editor_preview_sprite_height)


func setup(id: String, h: int = 50) -> void:
	super.setup(id, h)
	_buat_debu()


func _buat_debu() -> void:
	_debu = CPUParticles2D.new()
	_debu.amount = 10
	_debu.lifetime = 0.5
	_debu.local_coords = false
	_debu.emitting = false
	_debu.direction = Vector2(0, -1)
	_debu.spread = 70.0
	_debu.gravity = Vector2(0, -6)
	_debu.initial_velocity_min = 5.0
	_debu.initial_velocity_max = 13.0
	_debu.scale_amount_min = 1.2
	_debu.scale_amount_max = 2.4
	var g := Gradient.new()
	g.colors = PackedColorArray([Color(0.85, 0.8, 0.7, 0.55), Color(0.85, 0.8, 0.7, 0.0)])
	g.offsets = PackedFloat32Array([0.0, 1.0])
	_debu.color_ramp = g
	add_child(_debu)


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	var dir: Vector2 = Vector2.ZERO
	if not GameState.ui_open and view != null:
		if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT):
			dir.x -= 1.0
		if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT):
			dir.x += 1.0
		if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP):
			dir.y -= 1.0
		if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN):
			dir.y += 1.0
	var was: bool = moving
	moving = dir != Vector2.ZERO
	if moving:
		if not was:
			_walk_t = 0.0
		dir = dir.normalized()
		if dir.x != 0.0:
			facing = 1 if dir.x > 0.0 else -1
		var stp: Vector2 = dir * SPEED * view.kecepatan * delta
		var np: Vector2 = position + Vector2(stp.x, 0.0)
		if view.can_stand(np):
			position = np
		np = position + Vector2(0.0, stp.y)
		if view.can_stand(np):
			position = np
		_walk_t += delta
		_step_t += delta
		if _step_t >= 0.3:
			_step_t = 0.0
			Sfx.play("step", 0.45, randf_range(0.85, 1.15))
	else:
		_idle_t += delta
		_step_t = 0.2
	if _debu != null:
		_debu.emitting = moving
	queue_redraw()


func _draw() -> void:
	var idx: int = 0
	if pose >= 0:
		idx = pose
	elif moving:
		idx = 4 + (int(_walk_t * 9.0) % 6)
	else:
		idx = int(_idle_t * 2.0) % 4
	var sh: float = float(sprite_h)
	draw_rect(Rect2(-sh * 0.2, -1, sh * 0.4, 3), Color(0, 0, 0, 0.25))
	if tex == null:
		draw_rect(Rect2(-sh * 0.12, -sh * 0.9, sh * 0.24, sh * 0.9), Color("#3f5fbf"))
		return
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(float(facing), 1.0))
	draw_texture_rect_region(tex, Rect2(-cell / 2.0, -cell + 1.0, cell, cell), Rect2(idx * cell, 0, cell, cell))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if umbrella:
		_gambar_payung(sh)


func _gambar_payung(sh: float) -> void:
	var y: float = -sh * 0.97
	var w: float = sh * 0.36
	var kubah := PackedVector2Array()
	for i in range(13):
		var a: float = PI + PI * float(i) / 12.0
		kubah.append(Vector2(cos(a) * w, y + sin(a) * w * 0.55))
	draw_colored_polygon(kubah, Color("#c8382f"))
	draw_line(Vector2(0, y), Vector2(0, y + sh * 0.3), Color("#3a2a20"), 1.0)
