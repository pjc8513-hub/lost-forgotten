class_name NPC_Tile_Component
extends Node3D

@export var NPC_List: Array[NPCComponent] = [] # array of NPCs available from the tile

func get_active_npcs() -> Array[NPCComponent]:
	var active_npcs: Array[NPCComponent] = []
	for npc in NPC_List:
		if npc != null and npc.is_npc_active():
			active_npcs.append(npc)
	return active_npcs

func interact(_actor: Node) -> void:
	var active_npcs := get_active_npcs()
	if active_npcs.is_empty():
		MapManager.request_alert("No one is available.")
		return
	MapManager.request_dialogue(active_npcs, self)


func get_grid_pos() -> Vector3i:
	var grid_element := get_node_or_null("GridElement") as GridElement
	if grid_element != null:
		return grid_element.world_to_grid(grid_element.global_position)
	return Vector3i.ZERO


func _on_area_3d_input_event(_camera: Node, event: InputEvent, _event_position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	if CommandQueue.is_busy() or not TurnManager.can_player_move():
		return

	var movement := _get_interacting_movement()
	if movement == null:
		return

	var cmd := InteractCommand.new()
	cmd.actor = movement.actor
	cmd.movement = movement
	CommandQueue.add_command(cmd)


func _get_interacting_movement() -> GridMovementController:
	var grid_pos := get_grid_pos()
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


func _get_movement(player: Node3D) -> GridMovementController:
	if player == null:
		return null
	return player.get_node_or_null("GridMovementController") as GridMovementController
