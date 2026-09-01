class_name ButtonOrderPuzzleComponent
extends Node

@export var puzzle_id: StringName
@export var button_order: Array[StringName] = []
@export var target_door_ids: Array[StringName] = []

var solved := false
var _progress := 0

func _ready() -> void:
	add_to_group(&"button_order_puzzles")

func press(button_id: StringName) -> void:
	if solved or button_order.is_empty():
		return

	if button_id != button_order[_progress]:
		_progress = 0
		MapManager.request_alert("An unpleasant sound is heard")
		return

	_progress += 1
	if _progress < button_order.size():
		MapManager.request_alert("A pleasant noise is heard")
		return

	solved = true
	for door_id in target_door_ids:
		MapManager.unlock_door(door_id)
	_disable_buttons()
	MapManager.request_alert("A loud noise is heard in the distance")

func _disable_buttons() -> void:
	for node in get_tree().get_nodes_in_group(&"puzzle_buttons"):
		var button := node as PuzzleButtonComponent
		if button != null and button.puzzle_id == puzzle_id:
			button.is_enabled = false
