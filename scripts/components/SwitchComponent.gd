class_name SwitchComponent
extends Node3D

@export var target_door_ids: Array[StringName]
@export var local_edge := Vector3i(0, 0, -1)

func activate() -> void:
	for door_id in target_door_ids:
		if MapManager.unlock_door(door_id):
			MapManager.open_door(door_id)

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
