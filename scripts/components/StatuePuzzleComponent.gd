class_name StatuePuzzleComponent
extends Node

@export var puzzle_id: StringName
@export var target_door_ids: Array[StringName] = []
@export var target_blocker_ids: Array[StringName] = []

var solved := false

func _ready() -> void:
	add_to_group(&"statue_puzzles")
	call_deferred("evaluate")

func evaluate() -> void:
	if solved or puzzle_id.is_empty():
		return

	var statues := _get_statues()
	if statues.is_empty():
		return
	for statue in statues:
		if not statue.is_facing_north():
			return

	solved = true
	var opened_any := false
	for door_id in target_door_ids:
		var unlocked := MapManager.unlock_door(door_id)
		var opened := MapManager.open_door(door_id) if unlocked else false
		opened_any = opened_any or opened
	for blocker_id in target_blocker_ids:
		opened_any = MapManager.open_blocker(blocker_id) or opened_any

	if opened_any:
		MapManager.request_alert("The statues turn, and the door opens.")

func _get_statues() -> Array[StatueComponent]:
	var statues: Array[StatueComponent] = []
	for node in get_tree().get_nodes_in_group(&"statues"):
		var statue := node as StatueComponent
		if statue != null and statue.puzzle_id == puzzle_id:
			statues.append(statue)
	return statues
