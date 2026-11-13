class_name UIMenu
extends Control
## Menu modal serbaguna: await choose(...) mengembalikan id pilihan. PgUp/PgDn menggulir teks panjang.

signal chosen(id: String)

@onready var _title: Label = %Judul
@onready var _scroll: ScrollContainer = %Gulir
@onready var _body: Label = %Badan
@onready var _opts: VBoxContainer = %Opsi
@onready var _hint: Label = %Petunjuk
@onready var _panel: PanelContainer = %Panel
var _cancel_id: String = ""
var _line: LineEdit = null


func _ready() -> void:
	visible = false


func _prepare(title: String, body: String) -> void:
	_title.text = title
	_title.visible = title != ""
	_body.text = body
	_scroll.visible = body != ""
	var lines: int = body.count("\n") + int(ceil(float(body.length()) / 52.0)) + 1
	_scroll.custom_minimum_size = Vector2(390, float(mini(lines * 13, 150)))
	_scroll.scroll_vertical = 0
	_hint.visible = lines * 13 > 150
	for c in _opts.get_children():
		_opts.remove_child(c)
		c.queue_free()
	_line = null


func _tampil() -> void:
	visible = true
	_panel.modulate.a = 0.0
	_panel.scale = Vector2(0.96, 0.96)
	_panel.pivot_offset = _panel.size * 0.5
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(_panel, "modulate:a", 1.0, 0.12)
	tw.tween_property(_panel, "scale", Vector2.ONE, 0.12)


func choose(title: String, body: String, options: Array, cancel_id: String = "") -> String:
	_prepare(title, body)
	_cancel_id = cancel_id
	var first: Button = null
	for o in options:
		var b := Button.new()
		b.text = str(o["label"])
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.disabled = not bool(o.get("enabled", true))
		var oid: String = str(o["id"])
		b.pressed.connect(func():
			Sfx.play("click")
			chosen.emit(oid))
		b.focus_entered.connect(func(): Sfx.play("tick", 0.6))
		_opts.add_child(b)
		if first == null and not b.disabled:
			first = b
	_tampil()
	if first != null:
		first.grab_focus()
	var r: String = await chosen
	visible = false
	return r


func ask_text(title: String, body: String, default_text: String) -> String:
	_prepare(title, body)
	_cancel_id = ""
	_line = LineEdit.new()
	_line.text = default_text
	_line.max_length = 16
	_opts.add_child(_line)
	var b := Button.new()
	b.text = "Oke"
	b.pressed.connect(func(): chosen.emit("ok"))
	_line.text_submitted.connect(func(_t): chosen.emit("ok"))
	_opts.add_child(b)
	_tampil()
	_line.grab_focus()
	await chosen
	var res: String = _line.text
	visible = false
	return res


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if _cancel_id != "" and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		chosen.emit(_cancel_id)
	elif event is InputEventKey and event.pressed:
		if event.keycode == KEY_PAGEDOWN:
			_scroll.scroll_vertical += 60
		elif event.keycode == KEY_PAGEUP:
			_scroll.scroll_vertical -= 60
