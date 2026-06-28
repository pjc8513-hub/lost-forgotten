class_name GridElement
extends Node3D

enum CellShape { FLOOR, WALL, HALL, CORNER, DEAD_END }

@export var tile_size: float = 2.0
@export var cell_shape: CellShape = CellShape.FLOOR
var grid_pos: Vector3i

const NORTH := Vector3i(0, 0, -1)
const EAST := Vector3i(1, 0, 0)
const SOUTH := Vector3i(0, 0, 1)
const WEST := Vector3i(-1, 0, 0)

func _ready() -> void:
	grid_pos = world_to_grid(global_position)
	MapManager.register_cell(grid_pos, self)

func _exit_tree() -> void:
	MapManager.unregister_cell(grid_pos, self)

func world_to_grid(world_pos: Vector3) -> Vector3i:
	return Vector3i(
		roundi(world_pos.x / tile_size),
		roundi(world_pos.y / tile_size),
		roundi(world_pos.z / tile_size)
	)

func blocks_edge(world_direction: Vector3i) -> bool:
	for local_direction in _local_blocked_edges():
		var rotated := global_basis * Vector3(local_direction)
		var world_edge := Vector3i(roundi(rotated.x), 0, roundi(rotated.z))
		if world_edge == world_direction:
			return true
	return false

func _local_blocked_edges() -> Array[Vector3i]:
	match cell_shape:
		CellShape.WALL:
			return [WEST]
		CellShape.HALL:
			return [EAST, WEST]
		CellShape.CORNER:
			return [NORTH, WEST]
		CellShape.DEAD_END:
			return [NORTH, EAST, WEST]
		_:
			return []
