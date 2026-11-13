class_name DialogueBox
extends Control
## Kotak dialog dengan efek mengetik, potret tokoh, dan pilihan (klik, panah+Enter, atau tombol angka).
## run() mengembalikan nama aksi (atau "").

signal typing_done
signal picked(idx: int)

const CPS := 70.0
const POTRET_W := 56
const POTRET_H := 116
@onready var _potret: TextureRect = %Potret
@onready var _mc: MarginContainer = %Margin
@onready var _speaker: Label = %Pembicara
@onready var _text: Label = %Teks
@onready var _choices: VBoxContainer = %Pilihan
var _typing: bool = false
var _chars: float = 0.0
var _blip_acc: int = 0
var _pitch: float = 1.0
var _jumlah_pilihan: int = 0
var _tunggu_pilih: bool = false
var _sisi_kanan: bool = false


func _ready() -> void:
	visible = false


func _clear_choices() -> void:
	for c in _choices.get_children():
		_choices.remove_child(c)
		c.queue_free()


func _add_choice(label: String, idx: int) -> void:
	var b := Button.new()
	b.text = label
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.pressed.connect(func():
		Sfx.play("click")
		picked.emit(idx))
	b.focus_entered.connect(func(): Sfx.play("tick", 0.6))
	_choices.add_child(b)
	if _choices.get_child_count() == 1:
		b.grab_focus()


## Cari id tokoh dari nama pembicara ("" bila narasi tanpa potret).
func _id_tokoh(nama: String) -> String:
	if nama == "":
		return ""
	if nama == GameState.player_name or nama == "Dimas":
		return "dimas"
	for k in GameData.NPC.keys():
		if str(GameData.NPC[k]["nama"]) == nama:
			return str(k)
	return ""


func _set_potret(nama: String) -> void:
	var id: String = _id_tokoh(nama)
	var path: String = "res://assets/chars/%s_100.png" % id
	if id == "" or not ResourceLoader.exists(path):
		_potret.visible = false
		_sisi_kanan = false
		_mc.add_theme_constant_override("margin_left", 6)
		_mc.add_theme_constant_override("margin_right", 6)
		return
	var tex: Texture2D = load(path) as Texture2D
	var cell: int = tex.get_height()
	var at := AtlasTexture.new()
	at.atlas = tex
	at.region = Rect2(float(cell - POTRET_W) / 2.0, float(cell - POTRET_H), float(POTRET_W), float(POTRET_H))
	_potret.texture = at
	_sisi_kanan = id == "dimas"
	_potret.flip_h = _sisi_kanan
	_potret.visible = true
	_mc.add_theme_constant_override("margin_left", 6 if _sisi_kanan else 70)
	_mc.add_theme_constant_override("margin_right", 70 if _sisi_kanan else 6)
	var vs: Vector2 = get_viewport_rect().size
	var x: float = vs.x - 6.0 - float(POTRET_W) if _sisi_kanan else 8.0
	_potret.position = Vector2(x, vs.y - 6.0 - float(POTRET_H))
	var warna: Color = Color(str(GameData.NPC[id]["badan"])).lightened(0.45)
	_speaker.add_theme_color_override("font_color", warna)


func _process(delta: float) -> void:
	if not _typing:
		return
	_chars += delta * CPS
	var n: int = int(_chars)
	_text.visible_characters = n
	if n - _blip_acc >= 3:
		_blip_acc = n
		Sfx.play("blip", 0.7, _pitch * randf_range(0.95, 1.05))
	if n >= _text.text.length():
		_finish()


func _finish() -> void:
	_typing = false
	_text.visible_characters = -1
	typing_done.emit()


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if _typing:
		if event.is_action_pressed("ui_accept") or (event is InputEventMouseButton and event.pressed):
			get_viewport().set_input_as_handled()
			_finish()
	elif _tunggu_pilih and event is InputEventKey and event.pressed and not event.echo:
		var idx: int = event.keycode - KEY_1
		if idx >= 0 and idx < mini(_jumlah_pilihan, 9) and _jumlah_pilihan > 1:
			get_viewport().set_input_as_handled()
			picked.emit(idx)


func run(start_id: String) -> String:
	visible = true
	var id: String = start_id
	var act: String = ""
	while id != "":
		var node: Dictionary = DialogueDB.ambil(id)
		if node.is_empty():
			break
		if node.has("eff"):
			GameState.apply_effects(node["eff"])
		var nama: String = DialogueDB.fill(str(node.get("s", "")))
		_speaker.text = nama
		_speaker.visible = nama != ""
		_speaker.add_theme_color_override("font_color", Color("#f5c76a"))
		_set_potret(nama)
		_pitch = 0.8 + float(absi(nama.hash()) % 50) / 100.0
		_text.text = DialogueDB.fill(str(node["t"]))
		_text.visible_characters = 0
		_chars = 0.0
		_blip_acc = 0
		_clear_choices()
		if _text.text.length() > 0:
			_typing = true
			await typing_done
		var chs: Array = node.get("ch", [])
		_jumlah_pilihan = chs.size()
		if chs.is_empty():
			_add_choice("Lanjut ▶" if node.has("next") else "Tutup ▶", 0)
		else:
			for i in range(chs.size()):
				_add_choice(DialogueDB.fill(str(chs[i]["t"])), i)
		_tunggu_pilih = true
		var idx: int = await picked
		_tunggu_pilih = false
		_clear_choices()
		if chs.is_empty():
			if node.has("aksi"):
				act = str(node["aksi"])
				id = ""
			else:
				id = str(node.get("next", ""))
		else:
			var c: Dictionary = chs[idx]
			if c.has("eff"):
				GameState.apply_effects(c["eff"])
			if c.has("aksi"):
				act = str(c["aksi"])
				id = ""
			else:
				id = str(c.get("n", ""))
	_potret.visible = false
	visible = false
	return act
