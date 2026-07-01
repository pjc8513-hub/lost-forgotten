class_name SwitchComponent
extends Node3D

@export var target_door_ids: Array[StringName]
@export var target_blocker_ids: Array[StringName]
@export var local_edge := Vector3i(0, 0, -1)

func activate() -> void:
	for door_id in target_door_ids:
		if MapManager.unlock_door(door_id):
			MapManager.open_door(door_id)
	for blocker_id in target_blocker_ids:
		MapManager.open_blocker(blocker_id)

func can_interact(player_grid_pos: Vector3i, player_facing: Vector3i) -> bool:
	return player_grid_pos == get_grid_pos() and player_facing == get_world_edge()

func get_grid_pos() -> Vector3i:
	var grid_element := get_parent().get_node_or_null("GridElement") as GridElement
	if grid_element != null:
		return grid_element.world_to_grid(global_position)
	return Vector3i.ZERO

func get_world_edge() -> Vector3i:
	var rotated := global_basis * Vector3(local_edge)
	return Vector3i(roundi(rotated.x), 0, roundi(rotated.z))


func _on_area_3d_input_event(_camera: Node, event: InputEvent, _event_position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	if CommandQueue.is_busy():
		return

	var player := MapManager.get_actor(get_grid_pos())
	if player == null:
		return
	var movement := player.get_node_or_null("GridMovementController") as GridMovementController
	if movement == null or not can_interact(movement.grid_pos, movement.facing):
		return

	var cmd := InteractCommand.new()
	cmd.actor = player
	cmd.movement = movement
	CommandQueue.add_command(cmd)
