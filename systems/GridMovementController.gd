class_name GridMovementController
extends Node

@export var actor: Node3D
@export var tile_size: float = 2.0
@export var move_time: float = 0.15

var grid_pos: Vector3i
var facing: Vector3i = Vector3i(0, 0, -1)
var is_moving: bool = false

func _ready() -> void:
	if actor == null:
		actor = get_parent() as Node3D
	sync_to_actor()

func sync_to_actor() -> void:
	MapManager.unregister_actor(grid_pos)
	var world_forward := actor.global_basis * Vector3.FORWARD
	facing = Vector3i(roundi(world_forward.x), 0, roundi(world_forward.z))
	grid_pos = world_to_grid(actor.global_position)
	MapManager.register_actor(grid_pos, actor)

func _exit_tree() -> void:
	MapManager.unregister_actor(grid_pos)

func try_move_forward() -> bool:
	return try_move(facing)

func try_move(direction: Vector3i) -> bool:
	if is_moving:
		return false

	var target := grid_pos + direction

	if MapManager.is_edge_blocked(grid_pos, direction) or is_blocked(target):
		return false

	MapManager.unregister_actor(grid_pos)
	grid_pos = target
	MapManager.register_actor(grid_pos, actor)

	var target_world := grid_to_world(grid_pos)
	actor.global_position = target_world

	trigger_tile_effects(target)

	return true

func rotate_left() -> void:
	facing = Vector3i(facing.z, 0, -facing.x)
	actor.rotate_y(PI / 2.0)

func rotate_right() -> void:
	facing = Vector3i(-facing.z, 0, facing.x)
	actor.rotate_y(-PI / 2.0)

func interact_forward() -> bool:
	for element in MapManager.get_elements(grid_pos):
		for component in element.get_parent().get_children():
			if component is SwitchComponent and component.can_interact(grid_pos, facing):
				component.activate()
				return true

	var door := MapManager.get_door_on_edge(grid_pos, facing)
	if door != null:
		return door.open()
	return false

func is_blocked(pos: Vector3i) -> bool:
	if MapManager.get_actor(pos) != null:
		return true

	for element in MapManager.get_elements(pos):
		for component in element.get_parent().get_children():
			if component is BlockerComponent and component.blocks_movement:
				return true

	return false

func trigger_tile_effects(pos: Vector3i) -> void:
	for element in MapManager.get_elements(pos):
		for component in element.get_parent().get_children():
			if component is TrapComponent:
				component.trigger(actor)

func world_to_grid(world_pos: Vector3) -> Vector3i:
	return Vector3i(
		roundi(world_pos.x / tile_size),
		roundi(world_pos.y / tile_size),
		roundi(world_pos.z / tile_size)
	)

func grid_to_world(pos: Vector3i) -> Vector3:
	return Vector3(pos.x * tile_size, pos.y * tile_size, pos.z * tile_size)
