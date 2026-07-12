class_name TravelMenu
extends Control

@onready var travel_button: Button = $PanelContainer/MarginContainer/VBoxContainer/MarginContainer/HBoxContainer/OptionsContainer/VBoxContainer/TravelButton
@onready var close_button: Button = $PanelContainer/MarginContainer/VBoxContainer/MarginContainer/HBoxContainer/OptionsContainer/VBoxContainer/CloseButton

@onready var destination_list: ItemList = $PanelContainer/MarginContainer/VBoxContainer/MarginContainer/HBoxContainer/DestinationContainer/VBoxContainer/ScrollContainer/DestinationList

var _destinations: Array[Dictionary] = []

func _ready() -> void:
	hide()
	travel_button.pressed.connect(_on_travel_pressed)
	close_button.pressed.connect(close)
	destination_list.item_selected.connect(_on_destination_list_item_selected)
	QuestManager.travel_destinations_changed.connect(_on_travel_destinations_changed)
	_refresh()


func open() -> void:
	_refresh()
	show()


func close() -> void:
	hide()


func _refresh() -> void:
	_destinations = QuestManager.get_travel_destinations()
	destination_list.clear()
	travel_button.disabled = true

	if _destinations.is_empty():
		var index := destination_list.add_item("No destinations available")
		destination_list.set_item_disabled(index, true)
		return

	for destination in _destinations:
		destination_list.add_item(str(destination.get("display_name", "Unknown Destination")))


func _on_destination_list_item_activated(index: int) -> void:
	_travel_to_destination(index)


func _on_destination_list_item_selected(index: int) -> void:
	travel_button.disabled = index < 0 or index >= _destinations.size()


func _on_travel_pressed() -> void:
	var selected_items := destination_list.get_selected_items()
	if selected_items.is_empty():
		return
	_travel_to_destination(selected_items[0])


func _travel_to_destination(index: int) -> void:
	if index < 0 or index >= _destinations.size():
		return

	var destination := _destinations[index]
	var destination_map := str(destination.get("map", ""))
	var destination_spawn_id := StringName(destination.get("spawn_id", &"entrance"))
	if destination_map.is_empty():
		return

	close()
	MapManager.request_map_transition(destination_map, destination_spawn_id)


func _on_travel_destinations_changed() -> void:
	if visible:
		_refresh()
