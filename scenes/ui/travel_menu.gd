extends Control

@onready var travel_button: Button = $PanelContainer/MarginContainer/VBoxContainer/MarginContainer/HBoxContainer/OptionsContainer/VBoxContainer/TravelButton
@onready var close_button: Button = $PanelContainer/MarginContainer/VBoxContainer/MarginContainer/HBoxContainer/OptionsContainer/VBoxContainer/CloseButton

@onready var destination_list: ItemList = $PanelContainer/MarginContainer/VBoxContainer/MarginContainer/HBoxContainer/DestinationContainer/VBoxContainer/ScrollContainer/DestinationList


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func _on_destination_list_item_activated(index: int) -> void:
	pass # Replace with function body.
