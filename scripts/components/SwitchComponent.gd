class_name SwitchComponent
extends Node3D

signal activated(switch: SwitchComponent, exported_data: Dictionary, results: Array, success: bool)

@export var target_door_ids: Array[StringName]
@export var target_blocker_ids: Array[StringName]
@export var target_teleporter_ids: Array[StringName]

func activate() -> void:
	var results: Array[String] = []
	var success := false

	for door_id in target_door_ids:
		var unlocked := MapManager.unlock_door(door_id)
		var opened := MapManager.open_door(door_id) if unlocked else false
		success = success or opened
		results.append("door %s: unlock=%s open=%s" % [door_id, unlocked, opened])
	for blocker_id in target_blocker_ids:
		var opened := MapManager.open_blocker(blocker_id)
		success = success or opened
		results.append("blocker %s: open=%s" % [blocker_id, opened])
	for teleporter_id in target_teleporter_ids:
		var activated := MapManager.activate_teleporter(teleporter_id)
		success = success or activated
		results.append("teleporter %s: activate=%s" % [teleporter_id, activated])

	var exported_data := {
		"target_door_ids": target_door_ids.duplicate(),
		"target_blocker_ids": target_blocker_ids.duplicate(),
		"target_teleporter_ids": target_teleporter_ids.duplicate(),
	}
	var signal_exists := has_signal(&"activated")
	var signal_connection_count := get_signal_connection_list(&"activated").size() if signal_exists else 0
	var signal_result := emit_signal(&"activated", self, exported_data, results, success)
	
	# Send an alert via MapManager (main listens to MapManager.alert_requested)
	var message: String = "The button clicks." if success else "The button doesn't seem to do anything."
	MapManager.request_alert(message)
	
	_report_debug_interaction(exported_data, results, success, signal_result, signal_exists, signal_connection_count)

func can_interact(player_grid_pos: Vector3i, player_facing := Vector3i.ZERO) -> bool:
	var switch_grid_pos := get_grid_pos()
	if player_grid_pos == switch_grid_pos:
		return true
	return player_grid_pos + player_facing == switch_grid_pos

func get_grid_pos() -> Vector3i:
	var grid_element := get_parent().get_node_or_null("GridElement") as GridElement
	if grid_element != null:
		return grid_element.world_to_grid(grid_element.global_position)
	return Vector3i.ZERO

func _on_area_3d_input_event(_camera: Node, event: InputEvent, _event_position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	if CommandQueue.is_busy():
		return

	var movement := InteractableComponent.find_interacting_movement(get_grid_pos())
	if movement == null or not can_interact(movement.grid_pos, movement.facing):
		return

	var cmd := InteractCommand.new()
	cmd.actor = movement.actor
	cmd.movement = movement
	CommandQueue.add_command(cmd)

func _report_debug_interaction(
	exported_data: Dictionary,
	results: Array,
	success: bool,
	signal_result: int,
	signal_exists: bool,
	signal_connection_count: int
) -> void:
	for node in get_tree().get_nodes_in_group(&"debug_overlay"):
		if node.has_method(&"add_switch_interaction"):
			node.add_switch_interaction(self, exported_data, results, success, signal_result, signal_exists, signal_connection_count)
