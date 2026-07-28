class_name TravelMenu
extends Control

@onready var travel_button: Button = $PanelContainer/MarginContainer/VBoxContainer/MarginContainer/HBoxContainer/OptionsContainer/VBoxContainer/TravelButton
@onready var close_button: Button = $PanelContainer/MarginContainer/VBoxContainer/MarginContainer/HBoxContainer/OptionsContainer/VBoxContainer/CloseButton

@onready var destination_list: ItemList = $PanelContainer/MarginContainer/VBoxContainer/MarginContainer/HBoxContainer/DestinationContainer/VBoxContainer/ScrollContainer/DestinationList

var _destinations: Array[Dictionary] = []

const NOBEL_DESTINATION := {
	"display_name": "Nobel",
	"map": "res://scenes/maps/nobel/nobel.tscn",
	"map_id": &"Nobel",
	"spawn_id": &"entrance",
}

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
	_destinations = _get_available_destinations()
	destination_list.clear()
	travel_button.disabled = true

	if _destinations.is_empty():
		var index := destination_list.add_item("No destinations available")
		destination_list.set_item_disabled(index, true)
		return

	for destination in _destinations:
		destination_list.add_item(str(destination.get("display_name", "Unknown Destination")))


func _get_available_destinations() -> Array[Dictionary]:
	var current_map_id := _get_current_map_id()
	var destinations: Array[Dictionary] = [NOBEL_DESTINATION.duplicate()]
	destinations.append_array(QuestManager.get_travel_destinations())

	var filtered: Array[Dictionary] = []
	var seen_maps: Dictionary = {}
	for destination in destinations:
		var map_path := str(destination.get("map", ""))
		if map_path.is_empty():
			continue
		var map_id := StringName(destination.get("map_id", &""))
		if map_id.is_empty():
			map_id = _get_map_id(map_path)
		if map_id == current_map_id or seen_maps.has(map_id):
			continue
		seen_maps[map_id] = true
		destination["map_id"] = map_id
		filtered.append(destination)

	filtered.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return str(a.get("display_name", "")).naturalnocasecmp_to(str(b.get("display_name", ""))) < 0
	)
	return filtered


func _get_current_map_id() -> StringName:
	var current_map := StageManager.current_level as MapData
	return current_map.Map_ID if current_map != null else StringName()


func _get_map_id(map_path: String) -> StringName:
	var map_scene := load(map_path) as PackedScene
	if map_scene == null:
		return StringName(map_path)
	var map_instance := map_scene.instantiate()
	var map_data := map_instance as MapData
	var map_id := map_data.Map_ID if map_data != null else StringName(map_path)
	map_instance.free()
	return map_id


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
