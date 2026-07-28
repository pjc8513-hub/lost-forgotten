class_name AutomapView
extends Control
## Responsibility: draw the automap. Owns no visited-cell state — reads it
## from an injected AutomapComponent and redraws only when that component
## says a cell was newly revealed. Never mutates AutomapComponent's data.

@export var automap: AutomapComponent
@export var cell_pixels := 12.0
@export var background_color := Color(0.03, 0.035, 0.04, 0.82)
@export var visited_color := Color(0.72, 0.76, 0.72, 0.9)
## Near-black instead of the old mid-gray so wall lines read clearly against
## both the light cell fill and the dark background.
@export var wall_color := Color(0.05, 0.05, 0.06, 1.0)
@export var wall_thickness := 2.5
@export var player_color := Color(1.0, 0.72, 0.25, 1.0)
## When true, the map rotates so "forward" is always up instead of a fixed
## north-up orientation.
@export var rotate_to_facing := false

@onready var compass: Label = $Compass

var movement: GridMovementController
var current_map_path := ""
var current_grid_pos := Vector3i.ZERO
var current_facing := Vector3i(0, 0, -1)

## Must match AutomapComponent.DIRECTIONS order — N, E, S, W.
const DIRECTIONS: Array[Vector3i] = [
	Vector3i(0, 0, -1),
	Vector3i(1, 0, 0),
	Vector3i(0, 0, 1),
	Vector3i(-1, 0, 0),
]
const FACING_ANGLES := {
	Vector3i(0, 0, -1): 0.0,
	Vector3i(1, 0, 0): PI / 2.0,
	Vector3i(0, 0, 1): PI,
	Vector3i(-1, 0, 0): -PI / 2.0,
}


func setup(new_movement: GridMovementController) -> void:
	# The component normally lives beside this view in automap.tscn. Keep the
	# export for callers that want to inject a shared component, but resolve
	# the local child when the export has not been assigned in the inspector.
	if automap == null:
		automap = get_node_or_null("AutomapComponent") as AutomapComponent
	if automap == null:
		push_error("AutomapView requires an AutomapComponent.")
		return
	movement = new_movement
	if not movement.grid_state_changed.is_connected(_on_grid_state_changed):
		movement.grid_state_changed.connect(_on_grid_state_changed)
	if not StageManager.map_changed.is_connected(_on_map_changed):
		StageManager.map_changed.connect(_on_map_changed)
	if not automap.cell_revealed.is_connected(_on_cell_revealed):
		automap.cell_revealed.connect(_on_cell_revealed)
	if not automap.map_data_loaded.is_connected(_on_map_data_loaded):
		automap.map_data_loaded.connect(_on_map_data_loaded)
	current_map_path = StageManager.current_map_path
	_on_grid_state_changed(movement.grid_pos, movement.facing)


func _on_map_changed(map_path: String, _spawn_id: StringName) -> void:
	current_map_path = map_path
	queue_redraw()


func _on_cell_revealed(map_path: String, _pos: Vector3i) -> void:
	if map_path == current_map_path:
		queue_redraw()


func _on_map_data_loaded() -> void:
	queue_redraw()


func _on_grid_state_changed(grid_pos: Vector3i, facing: Vector3i) -> void:
	if automap == null:
		return
	current_grid_pos = grid_pos
	current_facing = facing
	automap.reveal(current_map_path, grid_pos)
	compass.text = _facing_label(facing)
	queue_redraw()


func _draw() -> void:
	var map_rect := Rect2(Vector2(5, 5), Vector2(size.x - 10, size.y - 30))
	draw_rect(map_rect, background_color, true)
	if automap == null:
		return

	var visited := automap.get_visited(current_map_path)
	if visited.is_empty():
		return

	var center := map_rect.get_center()
	var rot := (-_facing_angle(current_facing)) if rotate_to_facing else 0.0

	for pos in visited.keys():
		var local := Vector2(pos.x - current_grid_pos.x, pos.z - current_grid_pos.z) * cell_pixels
		if rot != 0.0:
			local = local.rotated(rot)
		var tile_center := center + local
		var tile_rect := Rect2(tile_center - Vector2.ONE * cell_pixels * 0.5, Vector2.ONE * cell_pixels)
		if not map_rect.intersects(tile_rect):
			continue
		draw_rect(tile_rect.grow(-1.0), visited_color, true)
		_draw_walls(tile_rect, visited[pos], rot)

	_draw_player_marker(center, rot)


func _draw_walls(tile_rect: Rect2, wall_mask: int, rot: float) -> void:
	var tl := tile_rect.position
	var tr := tile_rect.position + Vector2(tile_rect.size.x, 0)
	var br := tile_rect.end
	var bl := tile_rect.position + Vector2(0, tile_rect.size.y)

	if rot != 0.0:
		var c := tile_rect.get_center()
		tl = c + (tl - c).rotated(rot)
		tr = c + (tr - c).rotated(rot)
		br = c + (br - c).rotated(rot)
		bl = c + (bl - c).rotated(rot)

	# Rotating all four corners together keeps edge i pointing the same
	# world direction regardless of rot, so this stays index-aligned with
	# DIRECTIONS / the wall_mask bits even when rotate_to_facing is on.
	var edges := [[tl, tr], [tr, br], [br, bl], [bl, tl]]
	for i in DIRECTIONS.size():
		if (wall_mask & (1 << i)) != 0:
			draw_line(edges[i][0], edges[i][1], wall_color, wall_thickness)


func _draw_player_marker(center: Vector2, rot: float) -> void:
	# Arrow instead of a dot so facing reads at a glance, not just from the
	# compass label. Points straight up when rotate_to_facing is on, since
	# the map itself has already been rotated to put "forward" at the top.
	var angle: float = 0.0 if rotate_to_facing else _facing_angle(current_facing)
	var r := maxf(4.0, cell_pixels * 0.4)
	var tip := center + Vector2.UP.rotated(angle) * r
	var left := center + Vector2.UP.rotated(angle + 2.6) * (r * 0.6)
	var right := center + Vector2.UP.rotated(angle - 2.6) * (r * 0.6)
	draw_colored_polygon(PackedVector2Array([tip, left, right]), player_color)


func _facing_angle(facing: Vector3i) -> float:
	return FACING_ANGLES.get(facing, 0.0)


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
