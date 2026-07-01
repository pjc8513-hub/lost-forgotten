class_name InteractableComponent
extends Node

signal interacted(actor)

@export var interaction_text: String = "Interact"

func interact(actor: Node) -> void:
	interacted.emit(actor)

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
	var player := MapManager.get_actor(grid_pos)
	if player == null:
		return
	var movement := player.get_node_or_null("GridMovementController") as GridMovementController
	if movement == null:
		return

	var cmd := InteractCommand.new()
	cmd.actor = player
	cmd.movement = movement
	CommandQueue.add_command(cmd)
