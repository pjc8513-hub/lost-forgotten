# autoload/MapManager.gd
extends Node

var grid: Dictionary = {}
var actors: Dictionary = {}

func clear_grid() -> void:
	grid.clear()
	actors.clear()

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

	for element in get_elements(from):
		if element.blocks_edge(direction):
			return true

	for element in get_elements(target):
		if element.blocks_edge(-direction):
			return true

	return false

func register_actor(pos: Vector3i, actor: Node3D) -> void:
	actors[pos] = actor

func unregister_actor(pos: Vector3i) -> void:
	actors.erase(pos)

func get_actor(pos: Vector3i) -> Node3D:
	return actors.get(pos, null)
