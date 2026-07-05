class_name ItemInstance
extends Resource

@export var item_data: ItemData
@export var is_equipped: bool = false
@export var is_marked_junk: bool = false
@export var tags: Array[String] = []
@export var rolled_bonuses: Dictionary = {}
@export var resistances: Dictionary = {}
@export var status_immunities: Array[String] = []

func add_tag(tag_name: String) -> void:
	if not tag_name.is_empty() and not tags.has(tag_name):
		tags.append(tag_name)

func has_tag(tag_name: String) -> bool:
	return tags.has(tag_name)

func add_bonus(stat_name: String, value: int) -> void:
	rolled_bonuses[stat_name] = int(rolled_bonuses.get(stat_name, 0)) + value

func get_bonus(stat_name: String) -> int:
	return int(rolled_bonuses.get(stat_name, 0))

func add_resistance(element: String, value: int) -> void:
	resistances[element] = int(resistances.get(element, 0)) + value

func get_resistance(element: String) -> int:
	return int(resistances.get(element.to_lower(), 0))

func get_display_name() -> String:
	if item_data == null:
		return ""
	if tags.is_empty():
		return item_data.name
	return "%s [%s]" % [item_data.name, ", ".join(tags)]
