class_name FloatText
extends Label
## Teks yang naik pelan lalu memudar (perubahan uang, energi, hubungan).


static func spawn(parent: Node, teks: String, warna: Color, pos: Vector2) -> void:
	var l := FloatText.new()
	l.text = teks
	l.add_theme_color_override("font_color", warna)
	l.position = pos - Vector2(60.0, 0.0)
	parent.add_child(l)


func _ready() -> void:
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	custom_minimum_size = Vector2(120.0, 0.0)
	add_theme_font_size_override("font_size", 8)
	add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.95))
	add_theme_constant_override("outline_size", 3)
	z_index = 100
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	pivot_offset = Vector2(60.0, 5.0)
	scale = Vector2(0.6, 0.6)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(self, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "position:y", position.y - 24.0, 1.2)
	tw.tween_property(self, "modulate:a", 0.0, 0.35).set_delay(0.85)
	tw.chain().tween_callback(queue_free)
