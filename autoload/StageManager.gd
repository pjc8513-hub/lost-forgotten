extends Node

signal map_changed(map_path: String, spawn_id: StringName)

var level_root: Node
var entity_root: Node
var effect_root: Node
var player: Node3D
var current_level: Node
var current_map_path := ""

func configure(
	new_level_root: Node,
	new_entity_root: Node,
	new_effect_root: Node,
	new_player: Node3D
) -> void:
	level_root = new_level_root
	entity_root = new_entity_root
	effect_root = new_effect_root
	player = new_player

func change_map(map_path: String, spawn_id: StringName) -> bool:
	var map_scene := load(map_path) as PackedScene
	if map_scene == null:
		push_error("Could not load map: %s" % map_path)
		return false
	return load_map_scene(map_scene, spawn_id)

func load_map_scene(map_scene: PackedScene, spawn_id: StringName) -> bool:
	if level_root == null or player == null:
		push_error("StageManager must be configured by Main before loading a map.")
		return false

	TurnManager.set_state(TurnManager.State.TRANSITION)
	if current_level != null:
		current_level.free()
	MapManager.clear_grid()

	current_level = map_scene.instantiate()
	level_root.add_child(current_level)
	current_map_path = map_scene.resource_path

	var spawn_point := _find_spawn_point(current_level, spawn_id)
	if spawn_point == null:
		push_error("Spawn point '%s' was not found in %s" % [spawn_id, current_map_path])
		TurnManager.set_state(TurnManager.State.EXPLORATION)
		return false

	player.global_transform = spawn_point.global_transform
	var movement := player.get_node_or_null("GridMovementController") as GridMovementController
	if movement != null:
		movement.sync_to_actor()

	TurnManager.set_state(TurnManager.State.EXPLORATION)
	map_changed.emit(current_map_path, spawn_id)
	return true

func _find_spawn_point(node: Node, spawn_id: StringName) -> MapSpawnPoint:
	var spawn_point := node as MapSpawnPoint
	if spawn_point != null and spawn_point.spawn_id == spawn_id:
		return spawn_point
	for child in node.get_children():
		var result := _find_spawn_point(child, spawn_id)
		if result != null:
			return result
	return null
