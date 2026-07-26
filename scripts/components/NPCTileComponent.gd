class_name NPC_Tile_Component
extends Node3D

@export var npc_tile_id: StringName
@export var NPC_List: Array[NPCComponent] = [] # array of NPCs available from the tile
var _removed_npc_ids: Dictionary = {}

func _ready() -> void:
	MapManager.register_npc_tile(self)

func _exit_tree() -> void:
	MapManager.unregister_npc_tile(self)

func get_active_npcs() -> Array[NPCComponent]:
	var active_npcs: Array[NPCComponent] = []
	for npc in NPC_List:
		if npc != null and not _removed_npc_ids.has(npc.get_persistent_id()) and npc.is_npc_active():
			active_npcs.append(npc)
	return active_npcs

func remove_npc(npc: NPCComponent) -> bool:
	if npc == null or npc_tile_id.is_empty():
		push_error("NPC removal requires both an NPC and a persistent npc_tile_id.")
		return false
	return MapManager.remove_npc(npc_tile_id, npc.get_persistent_id())

func apply_persistent_state(state: Dictionary) -> void:
	_removed_npc_ids.clear()
	for npc_id in state.get("removed_npc_ids", []):
		_removed_npc_ids[StringName(npc_id)] = true
	if not NPC_List.is_empty() and _removed_npc_ids.size() >= NPC_List.size():
		queue_free()

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
