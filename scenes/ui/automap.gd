class_name Automap
extends Control

@export var cell_pixels := 12.0
@export var background_color := Color(0.03, 0.035, 0.04, 0.82)
@export var visited_color := Color(0.72, 0.76, 0.72, 0.9)
@export var wall_color := Color(0.2, 0.23, 0.22, 1.0)
@export var player_color := Color(1.0, 0.72, 0.25, 1.0)

@onready var compass: Label = $Compass

var movement: GridMovementController
var current_map_path := ""
var current_grid_pos := Vector3i.ZERO
var current_facing := Vector3i(0, 0, -1)
var visited_by_map: Dictionary = {}

const DIRECTIONS: Array[Vector3i] = [
	Vector3i(0, 0, -1),
	Vector3i(1, 0, 0),
	Vector3i(0, 0, 1),
	Vector3i(-1, 0, 0),
]

func setup(new_movement: GridMovementController) -> void:
	movement = new_movement
	if not movement.grid_state_changed.is_connected(_on_grid_state_changed):
		movement.grid_state_changed.connect(_on_grid_state_changed)
	if not StageManager.map_changed.is_connected(_on_map_changed):
		StageManager.map_changed.connect(_on_map_changed)
	if not MapManager.navigation_changed.is_connected(queue_redraw):
		MapManager.navigation_changed.connect(queue_redraw)
	current_map_path = StageManager.current_map_path
	_on_grid_state_changed(movement.grid_pos, movement.facing)

func _on_map_changed(map_path: String, _spawn_id: StringName) -> void:
	current_map_path = map_path
	if movement != null:
		_on_grid_state_changed(movement.grid_pos, movement.facing)

func _on_grid_state_changed(grid_pos: Vector3i, facing: Vector3i) -> void:
	current_map_path = StageManager.current_map_path
	current_grid_pos = grid_pos
	current_facing = facing
	if not visited_by_map.has(current_map_path):
		visited_by_map[current_map_path] = {}
	visited_by_map[current_map_path][grid_pos] = true
	compass.text = _facing_label(facing)
	queue_redraw()

func _draw() -> void:
	var map_rect := Rect2(Vector2(5, 5), Vector2(size.x - 10, size.y - 30))
	draw_rect(map_rect, background_color, true)
	if not visited_by_map.has(current_map_path):
		return

	var center := map_rect.get_center()
	for value in visited_by_map[current_map_path].keys():
		var pos: Vector3i = value
		var offset := Vector2(pos.x - current_grid_pos.x, pos.z - current_grid_pos.z) * cell_pixels
		var tile_rect := Rect2(center + offset - Vector2.ONE * cell_pixels * 0.5, Vector2.ONE * cell_pixels)
		if not map_rect.intersects(tile_rect):
			continue
		draw_rect(tile_rect.grow(-1.0), visited_color, true)
		_draw_walls(pos, tile_rect)

	draw_circle(center, maxf(2.0, cell_pixels * 0.2), player_color)

func _draw_walls(pos: Vector3i, tile_rect: Rect2) -> void:
	var thickness := 2.0
	for direction in DIRECTIONS:
		if not MapManager.is_edge_blocked(pos, direction):
			continue
		if direction == Vector3i(0, 0, -1):
			draw_line(tile_rect.position, tile_rect.position + Vector2(tile_rect.size.x, 0), wall_color, thickness)
		elif direction == Vector3i(1, 0, 0):
			draw_line(tile_rect.position + Vector2(tile_rect.size.x, 0), tile_rect.end, wall_color, thickness)
		elif direction == Vector3i(0, 0, 1):
			draw_line(tile_rect.position + Vector2(0, tile_rect.size.y), tile_rect.end, wall_color, thickness)
		elif direction == Vector3i(-1, 0, 0):
			draw_line(tile_rect.position, tile_rect.position + Vector2(0, tile_rect.size.y), wall_color, thickness)

func _facing_label(facing: Vector3i) -> String:
	if facing == Vector3i(0, 0, -1):
		return "N"
	if facing == Vector3i(1, 0, 0):
		return "E"
	if facing == Vector3i(0, 0, 1):
		return "S"
	if facing == Vector3i(-1, 0, 0):
		return "W"
	return "?"
