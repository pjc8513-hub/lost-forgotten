extends Control

@onready var messages: VBoxContainer = $Messages

func show_message(message: String) -> void:
	if message.is_empty():
		return
	if not visible:
		_clear_messages()
		
	var box := PanelContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# 1. Create the StyleBoxTexture
	var style_box := StyleBoxTexture.new()
	
	# 2. Load your exported PNG image directly into the texture property
	style_box.texture = preload("res://assets/materials/paper_albedo.png")
	
	# (Optional) If your image stretches weirdly, you can configure 9-patch margins here:
	box.add_theme_constant_override("margin_left", 12)
	box.add_theme_constant_override("margin_right", 12)
	box.add_theme_constant_override("margin_top", 8)
	box.add_theme_constant_override("margin_bottom", 8)
	style_box.texture_margin_left = 5
	style_box.texture_margin_right = 5
	style_box.texture_margin_top = 5
	style_box.texture_margin_bottom = 5
	#style_box.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_TILE
	
	box.add_theme_stylebox_override("panel", style_box)
	
	var label := Label.new()
	label.add_theme_color_override("font_color", Color("2b2621"))
	label.text = message
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	
	box.add_child(label)
	messages.add_child(box)
	show()

func dismiss() -> void:
	hide()
	_clear_messages()

func _clear_messages() -> void:
	for child in messages.get_children():
		child.queue_free()
