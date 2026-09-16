class_name StepLimitPuzzleComponent
extends Node

## Limits the number of successful movement steps made while this map is active.
## When the limit is reached, the player is sent through the normal map
## transition flow to the configured destination.
@export_range(1, 100000, 1) var step_limit: int = 30
@export_range(0, 100000, 1) var warning_steps: int = 10

@export_group("Timeout Destination")
@export_file("*.tscn") var destination_map: String
@export var destination_spawn_id: StringName

@export_group("Messages")
@export var warning_message: String = "You have %d steps remaining."
@export var timeout_message: String = "Time is up."

var _steps_at_map_entry: int = 0
var _warning_shown := false
var _timeout_triggered := false


func _ready() -> void:
	if step_limit <= 0:
		push_error("StepLimitPuzzleComponent requires a step_limit greater than zero.")
		return
	if destination_map.is_empty() or destination_spawn_id.is_empty():
		push_error("StepLimitPuzzleComponent requires both a destination_map and destination_spawn_id.")
		return

	_steps_at_map_entry = WorldManager.dungeon_steps
	WorldManager.steps_changed.connect(_on_steps_changed)


func _exit_tree() -> void:
	if WorldManager.steps_changed.is_connected(_on_steps_changed):
		WorldManager.steps_changed.disconnect(_on_steps_changed)


func get_steps_remaining() -> int:
	return maxi(step_limit - (WorldManager.dungeon_steps - _steps_at_map_entry), 0)


func _on_steps_changed(_total_steps: int) -> void:
	if _timeout_triggered:
		return

	var steps_remaining := get_steps_remaining()
	if steps_remaining <= 0:
		_timeout_triggered = true
		if not timeout_message.is_empty():
			# The normal movement handler dismisses alerts after step_taken. Defer
			# this until the current movement signal has finished so the expulsion
			# message is not immediately cleaned up.
			_show_alert_deferred(timeout_message)
		MapManager.request_map_transition(destination_map, destination_spawn_id)
		return

	if not _warning_shown and warning_steps > 0 and steps_remaining <= warning_steps:
		_warning_shown = true
		_show_alert_deferred(warning_message % steps_remaining)


func _show_alert_deferred(message: String) -> void:
	call_deferred("_show_alert", message)


func _show_alert(message: String) -> void:
	if not is_inside_tree():
		return
	MapManager.request_alert(message)
