extends Control

@onready var messages: VBoxContainer = $Messages

func show_message(message: String) -> void:
	if message.is_empty():
		return
	if not visible:
		_clear_messages()
		
	var box := PanelContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# A narrow frame gives the paper a crisp silhouette against busy scenes.
	var frame := StyleBoxFlat.new()
	frame.bg_color = Color("6f4825")
	frame.border_color = Color("3f2817")
	frame.set_border_width_all(1)
	frame.set_content_margin_all(2)
	frame.shadow_color = Color(0.08, 0.04, 0.02, 0.55)
	frame.shadow_size = 4
	frame.shadow_offset = Vector2(0, 3)
	box.add_theme_stylebox_override("panel", frame)

	var paper := PanelContainer.new()
	paper.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var style_box := StyleBoxTexture.new()

	# Keep the center quiet and use several close stops for softer worn edges.
	var paper_gradient := Gradient.new()
	paper_gradient.offsets = [0.0, 0.025, 0.07, 0.14, 0.5, 0.86, 0.93, 0.975, 1.0]
	paper_gradient.colors = [
		Color("70471f"),
		Color("9d6d32"),
		Color("c18b45"),
		Color("d6a555"),
		Color("e1b86c"),
		Color("d6a555"),
		Color("c18b45"),
		Color("9d6d32"),
		Color("70471f")
	]

	var gradient_tex := GradientTexture2D.new()
	gradient_tex.gradient = paper_gradient
	gradient_tex.fill_from = Vector2(0, 0)
	gradient_tex.fill_to = Vector2(1, 0)

	style_box.texture = gradient_tex
	style_box.texture_margin_left = 30
	style_box.texture_margin_right = 30
	style_box.texture_margin_top = 12
	style_box.texture_margin_bottom = 12
	paper.add_theme_stylebox_override("panel", style_box)

	var label := Label.new()
	label.text = message
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_color", Color("2b190e"))
	label.add_theme_color_override("font_shadow_color", Color(1.0, 0.82, 0.5, 0.35))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)

	paper.add_child(label)
	box.add_child(paper)
	messages.add_child(box)
	show()

func dismiss() -> void:
	hide()
	_clear_messages()

func _clear_messages() -> void:
	for child in messages.get_children():
		child.queue_free()
