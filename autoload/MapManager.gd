# autoload/MapManager.gd
extends Node

var grid: Dictionary = {}
var actors: Dictionary = {}
var doors: Dictionary[StringName, DoorComponent] = {}
var doors_by_edge: Dictionary = {}
var door_states: Dictionary[StringName, Dictionary] = {}
var blockers: Dictionary[StringName, BlockerComponent] = {}
var blocker_states: Dictionary[StringName, Dictionary] = {}

func clear_grid() -> void:
	grid.clear()
	actors.clear()
	doors.clear()
	doors_by_edge.clear()
	blockers.clear()

func register_cell(pos: Vector3i, element: GridElement) -> void:
	if not grid.has(pos):
		grid[pos] = []
	grid[pos].append(element)

func unregister_cell(pos: Vector3i, element: GridElement) -> void:
	if grid.has(pos):
		grid[pos].erase(element)
		if grid[pos].is_empty():
			grid.erase(pos)

func get_elements(pos: Vector3i) -> Array:
	return grid.get(pos, [])

func is_edge_blocked(from: Vector3i, direction: Vector3i) -> bool:
	var target := from + direction
	if get_elements(target).is_empty():
		return true

	# A door replaces the static wall rule on its registered edge.
	var door := get_door_on_edge(from, direction)
	if door != null:
		return door.blocks_movement()

	for element in get_elements(from):
		if element.blocks_edge(direction):
			return true

	for element in get_elements(target):
		if element.blocks_edge(-direction):
			return true

	return false

func register_door(door: DoorComponent) -> void:
	if door.door_id.is_empty():
		push_error("DoorComponent requires a unique door_id: %s" % door.get_path())
		return
	if doors.has(door.door_id) and doors[door.door_id] != door:
		push_error("Duplicate door_id registered: %s" % door.door_id)
		return

	doors[door.door_id] = door
	var grid_pos := door.get_grid_pos()
	var edge := door.get_world_edge()
	doors_by_edge[_edge_key(grid_pos, edge)] = door
	doors_by_edge[_edge_key(grid_pos + edge, -edge)] = door

	if not door_states.has(door.door_id):
		door_states[door.door_id] = {
			"is_locked": door.starts_locked,
			"is_open": door.starts_open,
		}
	door.apply_state(door_states[door.door_id], true)

func unregister_door(door: DoorComponent) -> void:
	if doors.get(door.door_id) == door:
		doors.erase(door.door_id)
	var grid_pos := door.get_grid_pos()
	var edge := door.get_world_edge()
	doors_by_edge.erase(_edge_key(grid_pos, edge))
	doors_by_edge.erase(_edge_key(grid_pos + edge, -edge))

func get_door_on_edge(from: Vector3i, direction: Vector3i) -> DoorComponent:
	return doors_by_edge.get(_edge_key(from, direction)) as DoorComponent

func unlock_door(door_id: StringName) -> bool:
	if not door_states.has(door_id):
		push_warning("Cannot unlock unknown door_id: %s" % door_id)
		return false
	var state: Dictionary = door_states[door_id].duplicate()
	state["is_locked"] = false
	_set_door_state(door_id, state)
	return true

func open_door(door_id: StringName) -> bool:
	if not door_states.has(door_id) or door_states[door_id].get("is_locked", false):
		return false
	var state: Dictionary = door_states[door_id].duplicate()
	state["is_open"] = true
	_set_door_state(door_id, state)
	return true

func close_door(door_id: StringName) -> bool:
	if not door_states.has(door_id):
		return false
	var state: Dictionary = door_states[door_id].duplicate()
	state["is_open"] = false
	_set_door_state(door_id, state)
	return true

func register_blocker(blocker: BlockerComponent) -> void:
	if blocker.blocker_ID.is_empty():
		return
	if blockers.has(blocker.blocker_ID) and blockers[blocker.blocker_ID] != blocker:
		push_error("Duplicate blocker_ID registered: %s" % blocker.blocker_ID)
		return
	blockers[blocker.blocker_ID] = blocker
	if not blocker_states.has(blocker.blocker_ID):
		blocker_states[blocker.blocker_ID] = {"is_open": false}
	blocker.apply_state(blocker_states[blocker.blocker_ID], true)

func unregister_blocker(blocker: BlockerComponent) -> void:
	if blockers.get(blocker.blocker_ID) == blocker:
		blockers.erase(blocker.blocker_ID)

func open_blocker(blocker_id: StringName) -> bool:
	if not blocker_states.has(blocker_id):
		push_warning("Cannot open unknown blocker_ID: %s" % blocker_id)
		return false
	var state: Dictionary = blocker_states[blocker_id].duplicate()
	state["is_open"] = true
	blocker_states[blocker_id] = state
	var blocker: BlockerComponent = blockers.get(blocker_id)
	if blocker != null:
		blocker.apply_state(state)
	return true

func get_persistent_state() -> Dictionary:
	return {
		"doors": door_states.duplicate(true),
		"blockers": blocker_states.duplicate(true),
	}

func load_persistent_state(data: Dictionary) -> void:
	door_states.assign(data.get("doors", {}))
	blocker_states.assign(data.get("blockers", {}))
	for door_id in doors:
		if door_states.has(door_id):
			doors[door_id].apply_state(door_states[door_id], true)
	for blocker_id in blockers:
		if blocker_states.has(blocker_id):
			blockers[blocker_id].apply_state(blocker_states[blocker_id], true)

func reset_persistent_state() -> void:
	door_states.clear()
	blocker_states.clear()

func _set_door_state(door_id: StringName, state: Dictionary) -> void:
	door_states[door_id] = state
	var door: DoorComponent = doors.get(door_id)
	if door != null:
		door.apply_state(state)

func _edge_key(pos: Vector3i, direction: Vector3i) -> String:
	return "%d,%d,%d:%d,%d,%d" % [
		pos.x, pos.y, pos.z,
		direction.x, direction.y, direction.z,
	]

func register_actor(pos: Vector3i, actor: Node3D) -> void:
	actors[pos] = actor

func unregister_actor(pos: Vector3i) -> void:
	actors.erase(pos)

func get_actor(pos: Vector3i) -> Node3D:
	return actors.get(pos, null)
