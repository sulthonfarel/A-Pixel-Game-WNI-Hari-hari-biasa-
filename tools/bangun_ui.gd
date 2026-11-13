extends Node
## Membangkitkan scenes/ui/{tema.tres,hud.tscn,dialogue_box.tscn,ui_menu.tscn}.
##   godot --headless --path . res://tools/bangun_ui.tscn
## PERINGATAN: menimpa berkas-berkas itu. Setelah UI diedit di editor, jangan jalankan lagi.

var _owner: Node


func _ready() -> void:
	_tema()
	_hud()
	_dialog()
	_menu()
	print("UI selesai dibangun.")
	get_tree().quit()


func _add(induk: Node, anak: Node, nama: String, unik: bool = true) -> Node:
	anak.name = nama
	induk.add_child(anak)
	anak.owner = _owner
	if unik:
		anak.unique_name_in_owner = true
	return anak


func _label(induk: Node, nama: String, ukuran: int = 0, warna: Color = Color.WHITE, outline: int = 0) -> Label:
	var l := Label.new()
	_add(induk, l, nama)
	if ukuran > 0:
		l.add_theme_font_size_override("font_size", ukuran)
	if warna != Color.WHITE:
		l.add_theme_color_override("font_color", warna)
	if outline > 0:
		l.add_theme_color_override("font_outline_color", Color.BLACK)
		l.add_theme_constant_override("outline_size", outline)
	return l


func _simpan(root: Node, path: String) -> void:
	var ps := PackedScene.new()
	var err: int = ps.pack(root)
	if err == OK:
		err = ResourceSaver.save(ps, path)
	print(path, " -> ", err)
	root.free()


func _penuh(c: Control) -> void:
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _flat(bg: Color, border_w: int = 0, border: Color = Color.WHITE, radius: int = 2, margin: float = 3.0) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	if border_w > 0:
		sb.set_border_width_all(border_w)
		sb.border_color = border
	sb.set_corner_radius_all(radius)
	sb.set_content_margin_all(margin)
	return sb


# ---------------------------------------------------------------- tema
func _tema() -> void:
	var th := Theme.new()
	th.default_font_size = 10
	th.set_stylebox("panel", "PanelContainer", _flat(Color(0.09, 0.09, 0.14, 0.96), 2, Color(0.95, 0.78, 0.4), 2, 10.0))
	var names: Dictionary = {
		"normal": Color(0.18, 0.18, 0.27), "hover": Color(0.28, 0.28, 0.42),
		"pressed": Color(0.4, 0.34, 0.2), "disabled": Color(0.12, 0.12, 0.16),
	}
	for k in names.keys():
		th.set_stylebox(k, "Button", _flat(names[k]))
	th.set_stylebox("focus", "Button", _flat(Color(0.3, 0.28, 0.12, 0.6), 2, Color(0.95, 0.78, 0.4)))
	th.set_color("font_color", "Button", Color.WHITE)
	th.set_color("font_hover_color", "Button", Color.WHITE)
	th.set_color("font_focus_color", "Button", Color("#ffe9a0"))
	th.set_color("font_disabled_color", "Button", Color(0.5, 0.5, 0.55))
	print("tema -> ", ResourceSaver.save(th, "res://scenes/ui/tema.tres"))


# ---------------------------------------------------------------- HUD
func _bar(induk: Node, nama: String, mn: float, mx: float, lebar: float, tinggi: float, warna: Color) -> ProgressBar:
	var pb := ProgressBar.new()
	_add(induk, pb, nama)
	pb.min_value = mn
	pb.max_value = mx
	pb.show_percentage = false
	pb.custom_minimum_size = Vector2(lebar, tinggi)
	pb.add_theme_stylebox_override("background", _flat(Color(0.15, 0.15, 0.2), 0, Color.WHITE, 0, 0.0))
	pb.add_theme_stylebox_override("fill", _flat(warna, 0, Color.WHITE, 0, 0.0))
	return pb


func _hud() -> void:
	var r := Control.new()
	_owner = r
	r.name = "HUD"
	r.set_script(load("res://scripts/hud.gd"))
	_penuh(r)
	var panel := PanelContainer.new()
	_add(r, panel, "Panel")
	panel.position = Vector2(4, 4)
	panel.add_theme_stylebox_override("panel", _flat(Color(0.06, 0.06, 0.1, 0.74), 1, Color(0.95, 0.78, 0.4, 0.8), 2, 4.0))
	var vb := VBoxContainer.new()
	_add(panel, vb, "Isi", false)
	vb.add_theme_constant_override("separation", 1)
	var baris := HBoxContainer.new()
	_add(vb, baris, "BarisWaktu", false)
	baris.add_theme_constant_override("separation", 3)
	var ikon := HudIkon.new()
	_add(baris, ikon, "Ikon")
	_label(baris, "Top", 9)
	_bar(vb, "HariBar", 360.0, 1440.0, 96.0, 2.0, Color("#f5c76a"))
	_label(vb, "Uang", 9, Color("#9be37a"))
	var warna: Dictionary = {"Energi": Color("#6fcf6f"), "Kenyang": Color("#e8a24a"), "Mood": Color("#e87aa0")}
	for n in ["Energi", "Kenyang", "Mood"]:
		var h := HBoxContainer.new()
		_add(vb, h, "Baris" + n, false)
		var l := Label.new()
		_add(h, l, "Label" + n, false)
		l.text = n
		l.custom_minimum_size = Vector2(40, 0)
		l.add_theme_font_size_override("font_size", 8)
		var pb: ProgressBar = _bar(h, "Bar" + n, 0.0, 100.0, 56.0, 6.0, warna[n])
		pb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		pb.set_meta("warna", warna[n])
	_label(vb, "Tugas", 8, Color("#f5c76a"))
	_label(vb, "Listrik", 8, Color("#ffd84a"))
	var lok := _label(r, "Lokasi", 0, Color.WHITE, 4)
	lok.position = Vector2(480, 8)
	lok.size = Vector2(150, 20)
	lok.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var pr := _label(r, "Prompt", 0, Color.WHITE, 5)
	pr.size = Vector2(300, 22)
	pr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var ts := VBoxContainer.new()
	_add(r, ts, "Toasts")
	ts.custom_minimum_size = Vector2(230, 0)
	ts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bb := VBoxContainer.new()
	_add(r, bb, "BannerBox")
	bb.modulate.a = 0.0
	bb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var b1 := _label(bb, "Banner", 16, Color("#ffe9a0"), 6)
	b1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var b2 := _label(bb, "BannerSub", 9, Color.WHITE, 4)
	b2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_simpan(r, "res://scenes/ui/hud.tscn")


# ---------------------------------------------------------------- dialog
func _dialog() -> void:
	var r := Control.new()
	_owner = r
	r.name = "DialogueBox"
	r.set_script(load("res://scripts/dialogue_box.gd"))
	_penuh(r)
	r.visible = false
	var pot := TextureRect.new()
	_add(r, pot, "Potret")
	pot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pot.stretch_mode = TextureRect.STRETCH_KEEP
	pot.size = Vector2(56, 116)
	pot.visible = false
	var mc := MarginContainer.new()
	_add(r, mc, "Margin")
	_penuh(mc)
	for side in ["left", "right", "top", "bottom"]:
		mc.add_theme_constant_override("margin_" + side, 6)
	var luar := VBoxContainer.new()
	_add(mc, luar, "Luar", false)
	luar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var pengisi := Control.new()
	_add(luar, pengisi, "Pengisi", false)
	pengisi.size_flags_vertical = Control.SIZE_EXPAND_FILL
	pengisi.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var panel := PanelContainer.new()
	_add(luar, panel, "Panel", false)
	panel.custom_minimum_size = Vector2(0, 84)
	var vb := VBoxContainer.new()
	_add(panel, vb, "Isi", false)
	vb.add_theme_constant_override("separation", 2)
	_label(vb, "Pembicara", 0, Color("#f5c76a"))
	var teks := _label(vb, "Teks")
	teks.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	teks.custom_minimum_size = Vector2(100, 34)
	teks.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var pil := VBoxContainer.new()
	_add(vb, pil, "Pilihan")
	_simpan(r, "res://scenes/ui/dialogue_box.tscn")


# ---------------------------------------------------------------- menu
func _menu() -> void:
	var r := Control.new()
	_owner = r
	r.name = "UIMenu"
	r.set_script(load("res://scripts/ui_menu.gd"))
	r.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_STOP
	r.visible = false
	var dim := ColorRect.new()
	_add(r, dim, "Redup", false)
	dim.color = Color(0, 0, 0, 0.55)
	_penuh(dim)
	var tengah := CenterContainer.new()
	_add(r, tengah, "Tengah", false)
	_penuh(tengah)
	var panel := PanelContainer.new()
	_add(tengah, panel, "Panel")
	var vb := VBoxContainer.new()
	_add(panel, vb, "Susunan", false)
	vb.add_theme_constant_override("separation", 6)
	var judul := _label(vb, "Judul", 13, Color("#f5c76a"))
	judul.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var gulir := ScrollContainer.new()
	_add(vb, gulir, "Gulir")
	gulir.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var badan := _label(gulir, "Badan")
	badan.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	badan.custom_minimum_size = Vector2(380, 0)
	var hint := _label(vb, "Petunjuk", 7, Color(0.7, 0.7, 0.8))
	hint.text = "PgUp / PgDn atau roda mouse: gulir teks"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var opsi := VBoxContainer.new()
	_add(vb, opsi, "Opsi")
	_simpan(r, "res://scenes/ui/ui_menu.tscn")
