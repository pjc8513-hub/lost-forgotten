extends Control

@onready var alert_text: Label = $AlertText

func show_message(message: String) -> void:
	alert_text.text = message
	show()

func dismiss() -> void:
	hide()
