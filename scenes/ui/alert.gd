extends Control

@onready var messages: VBoxContainer = $Messages

func show_message(message: String) -> void:
	if message.is_empty():
		return
	if not visible:
		_clear_messages()
	var label := Label.new()
	label.text = message
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	messages.add_child(label)
	show()

func dismiss() -> void:
	hide()
	_clear_messages()

func _clear_messages() -> void:
	for child in messages.get_children():
		child.queue_free()
