class_name SecretComponent
extends Node3D

signal discovered(secret: SecretComponent)

@export var secret_ID : StringName = ""
@export var is_secret := true
@export var secret_type : String

func get_grid_pos() -> Vector3i:
	var grid_element := _find_grid_element()
	if grid_element != null:
		return grid_element.grid_pos
	return Vector3i.ZERO

func discover() -> bool:
	if not is_secret:
		return false
	is_secret = false
	var door := get_parent().get_node_or_null("DoorComponent") as DoorComponent
	if door != null:
		door.discover_door()
	var trap := get_parent().get_node_or_null("TrapComponent") as TrapComponent
	if trap != null:
		trap.discover_trap()
	discovered.emit(self)
	return true

func get_discovery_message() -> String:
	match secret_type.to_lower().strip_edges():
		"door": return "Found secret door"
		"trap": return "Found trap"
		var type_name when not type_name.is_empty(): return "Found %s" % type_name
		_: return "Found a secret"

func _find_grid_element() -> GridElement:
	var ancestor := get_parent()
	while ancestor != null:
		var element := ancestor.get_node_or_null("GridElement") as GridElement
		if element != null:
			return element
		ancestor = ancestor.get_parent()
	return null
