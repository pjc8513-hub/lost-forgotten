class_name TeleportTileComponent
extends Node

## Teleports the player to one of the configured spawn points on the current map
## when the tile is stepped on.
@export var teleport_id: StringName
@export var spawn_location_ids: Array[StringName] = []
@export var is_activated: bool = true

func trigger(actor: Node) -> void:
	if actor == null or actor != StageManager.player:
		return
	var actor_3d := actor as Node3D
	if actor_3d == null:
		return

	var spawn_points := _get_matching_spawn_points()
	if spawn_points.is_empty():
		push_warning("TeleportTileComponent has no valid spawn locations: %s" % get_path())
		return

	var destination := spawn_points.pick_random() as MapSpawnPoint
	var movement := actor_3d.get_node_or_null("GridMovementController") as GridMovementController
	if movement == null:
		push_error("TeleportTileComponent requires the player to have a GridMovementController.")
		return

	var main := get_tree().current_scene
	if main != null and main.has_method("run_teleport_transition"):
		await main.run_teleport_transition(destination.global_transform)
	else:
		actor_3d.global_transform = destination.global_transform
		movement.sync_to_actor()

func _get_matching_spawn_points() -> Array[MapSpawnPoint]:
	var matches: Array[MapSpawnPoint] = []
	if StageManager.current_level == null:
		return matches

	for spawn_id in spawn_location_ids:
		var spawn_point := _find_spawn_point(StageManager.current_level, spawn_id)
		if spawn_point != null and spawn_point not in matches:
			matches.append(spawn_point)
		elif spawn_point == null:
			push_warning("TeleportTileComponent could not find spawn location '%s' on the current map." % spawn_id)
	return matches

func _find_spawn_point(node: Node, spawn_id: StringName) -> MapSpawnPoint:
	if node is MapSpawnPoint and node.spawn_id == spawn_id:
		return node as MapSpawnPoint
	for child in node.get_children():
		var result := _find_spawn_point(child, spawn_id)
		if result != null:
			return result
	return null
