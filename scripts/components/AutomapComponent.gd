class_name AutomapComponent
extends Node
## Responsibility: remember which cells have been visited per map, and cache
## the wall layout for each visited cell. No drawing, no UI. Safe to attach
## anywhere in the scene tree (e.g. alongside GridMovementController) and to
## save/load independently of whether an AutomapView even exists.

signal cell_revealed(map_path: String, pos: Vector3i)
signal map_data_loaded

## Direction order used everywhere a wall bitmask is read or written.
## Bit i in a cell's mask corresponds to DIRECTIONS[i].
const DIRECTIONS: Array[Vector3i] = [
	Vector3i(0, 0, -1), # N - bit 0
	Vector3i(1, 0, 0),  # E - bit 1
	Vector3i(0, 0, 1),  # S - bit 2
	Vector3i(-1, 0, 0), # W - bit 3
]

# map_path -> { Vector3i pos -> int wall_bitmask }
var _visited_by_map: Dictionary = {}


## Marks a cell as visited on the given map and caches its wall layout the
## first time it's seen. No-op (and no signal) if already visited — walls
## don't change after the fact, so there's nothing to recompute.
func reveal(map_path: String, pos: Vector3i) -> void:
	if not _visited_by_map.has(map_path):
		_visited_by_map[map_path] = {}
	var cells: Dictionary = _visited_by_map[map_path]
	if cells.has(pos):
		return
	cells[pos] = _compute_wall_mask(pos)
	cell_revealed.emit(map_path, pos)


func is_visited(map_path: String, pos: Vector3i) -> bool:
	return _visited_by_map.has(map_path) and _visited_by_map[map_path].has(pos)


## Returns { Vector3i pos -> int wall_bitmask } for the given map. Callers
## should treat this as read-only.
func get_visited(map_path: String) -> Dictionary:
	return _visited_by_map.get(map_path, {})


func get_wall_mask(map_path: String, pos: Vector3i) -> int:
	var cells: Dictionary = _visited_by_map.get(map_path, {})
	return cells.get(pos, 0)


func is_wall_blocked(map_path: String, pos: Vector3i, direction_index: int) -> bool:
	return (get_wall_mask(map_path, pos) & (1 << direction_index)) != 0


func _compute_wall_mask(pos: Vector3i) -> int:
	var mask := 0
	for i in DIRECTIONS.size():
		if MapManager.is_edge_blocked(pos, DIRECTIONS[i]):
			mask |= (1 << i)
	return mask


## --- Save / Load ---------------------------------------------------------
## Vector3i keys aren't JSON-serializable, so cells are flattened to
## "x,y,z" string keys. Plug the returned Dictionary straight into your
## existing save-file Dictionary under an "automap" key.

func get_save_data() -> Dictionary:
	var out := {}
	for map_path in _visited_by_map.keys():
		var cells: Dictionary = _visited_by_map[map_path]
		var serialized := {}
		for pos in cells.keys():
			serialized["%d,%d,%d" % [pos.x, pos.y, pos.z]] = cells[pos]
		out[map_path] = serialized
	return out


func load_save_data(data: Dictionary) -> void:
	_visited_by_map.clear()
	for map_path in data.keys():
		var cells := {}
		var serialized: Dictionary = data[map_path]
		for key in serialized.keys():
			var parts := String(key).split(",")
			if parts.size() != 3:
				continue
			var pos := Vector3i(int(parts[0]), int(parts[1]), int(parts[2]))
			cells[pos] = int(serialized[key])
		_visited_by_map[map_path] = cells
	map_data_loaded.emit()
