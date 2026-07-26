class_name InteractableComponent
extends Node

signal interacted(actor)

@export var interaction_text: String = "Interact"

func interact(actor: Node) -> void:
	interacted.emit(actor)

static func find_interacting_movement(grid_pos: Vector3i) -> GridMovementController:
	var player := MapManager.get_actor(grid_pos)
	var movement := _get_movement(player)
	if movement != null:
		return movement

	for direction in [
		Vector3i(0, 0, -1),
		Vector3i(1, 0, 0),
		Vector3i(0, 0, 1),
		Vector3i(-1, 0, 0),
	]:
		player = MapManager.get_actor(grid_pos - direction)
		movement = _get_movement(player)
		if movement != null and movement.facing == direction:
			return movement

	return null

static func _get_movement(player: Node3D) -> GridMovementController:
	if player == null:
		return null
	return player.get_node_or_null("GridMovementController") as GridMovementController

func _on_area_3d_input_event(
	_camera: Node,
	event: InputEvent,
	_event_position: Vector3,
	_normal: Vector3,
	_shape_idx: int
) -> void:
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	if CommandQueue.is_busy():
		return

	var grid_element := get_parent().get_node_or_null("GridElement") as GridElement
	if grid_element == null:
		return
	var grid_pos := grid_element.world_to_grid(grid_element.global_position)
	var movement := find_interacting_movement(grid_pos)
	if movement == null:
		return

	var cmd := InteractCommand.new()
	cmd.actor = movement.actor
	cmd.movement = movement
	CommandQueue.add_command(cmd)
