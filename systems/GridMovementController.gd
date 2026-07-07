class_name GridMovementController
extends Node

signal grid_state_changed(grid_pos: Vector3i, facing: Vector3i)
signal step_taken

@export var actor: Node3D
@export var tile_size: float = 2.0
@export var move_time: float = 0.15
@export var turn_time: float = 0.2

var grid_pos: Vector3i
var facing: Vector3i = Vector3i(0, 0, -1)
var is_moving: bool = false
var is_rotating := false
var move_tween: Tween
var rotate_tween: Tween

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
	grid_state_changed.emit(grid_pos, facing)

func _exit_tree() -> void:
	MapManager.unregister_actor(grid_pos)

func try_move_forward() -> bool:
	return try_move(facing)

func try_move(direction: Vector3i) -> bool:
	if is_moving or is_rotating:
		return false

	var target := grid_pos + direction

	if MapManager.is_edge_blocked(grid_pos, direction) or is_blocked(target):
		return false

	# Update grid state immediately
	MapManager.unregister_actor(grid_pos)
	grid_pos = target
	MapManager.register_actor(grid_pos, actor)

	var target_world := grid_to_world(grid_pos)

	# Kill any existing tween cleanly
	if move_tween and move_tween.is_running():
		move_tween.kill()

	is_moving = true

	# Create tween
	move_tween = create_tween()
	move_tween.set_trans(Tween.TRANS_SINE)
	move_tween.set_ease(Tween.EASE_OUT)

	move_tween.tween_property(actor, "global_position", target_world, move_time)

	move_tween.finished.connect(func():
		is_moving = false
		grid_state_changed.emit(grid_pos, facing)
		step_taken.emit()
		trigger_tile_effects(grid_pos)
	)

	return true

func rotate_left() -> void:
	if is_rotating or is_moving:
		return
	facing = Vector3i(facing.z, 0, -facing.x)
	grid_state_changed.emit(grid_pos, facing)
	_start_rotation_tween(PI / 2.0)

func turn_around() -> void:
	if is_rotating or is_moving:
		return
	facing = -facing
	grid_state_changed.emit(grid_pos, facing)
	_start_rotation_tween(PI)

func rotate_right() -> void:
	if is_rotating or is_moving:
		return
	facing = Vector3i(-facing.z, 0, facing.x)
	grid_state_changed.emit(grid_pos, facing)
	_start_rotation_tween(-PI / 2.0)
	
func _start_rotation_tween(amount: float) -> void:
	_snap_rotation()

	if rotate_tween and rotate_tween.is_running():
		rotate_tween.kill()

	is_rotating = true

	rotate_tween = create_tween()
	rotate_tween.set_trans(Tween.TRANS_SINE)
	rotate_tween.set_ease(Tween.EASE_OUT)

	var start_rot := actor.rotation.y
	var end_rot := start_rot + amount

	rotate_tween.tween_property(actor, "rotation:y", end_rot, turn_time)

	rotate_tween.finished.connect(func():
		is_rotating = false
	)
	
func _snap_rotation() -> void:
	var y = actor.rotation.y
	var snapped = round(y / (PI/2)) * (PI/2)
	actor.rotation.y = snapped

func interact_forward() -> bool:
	if is_moving or is_rotating:
		return false
	for element in MapManager.get_elements(grid_pos):
		for component in element.get_parent().get_children():
			if component is SwitchComponent and component.can_interact(grid_pos):
				component.activate()
				return true
			if component is InteractableComponent:
				component.interact(actor)
				return true

	var door := MapManager.get_door_on_edge(grid_pos, facing)
	if door != null:
		return door.open()

	var target := grid_pos + facing
	for element in MapManager.get_elements(target):
		for component in element.get_parent().get_children():
			if component is InteractableComponent:
				component.interact(actor)
				return true
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
		for component in element.get_parent().find_children("*", "TrapComponent", true, false):
			var trap := component as TrapComponent
			if trap != null and trap.trigger_on_step:
				trap.trigger(actor)

func world_to_grid(world_pos: Vector3) -> Vector3i:
	return Vector3i(
		roundi(world_pos.x / tile_size),
		roundi(world_pos.y / tile_size),
		roundi(world_pos.z / tile_size)
	)

func grid_to_world(pos: Vector3i) -> Vector3:
	return Vector3(pos.x * tile_size, pos.y * tile_size, pos.z * tile_size)
