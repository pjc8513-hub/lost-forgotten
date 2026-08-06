class_name SecretComponent
extends Node3D

signal discovered(secret: SecretComponent)

@export var secret_ID : StringName = ""
@export var is_secret := true
@export var secret_type : String
@export var visibible_object : MeshInstance3D
@export var secret_object : MeshInstance3D

func _ready() -> void:
	MapManager.register_secret(self)

func _exit_tree() -> void:
	MapManager.unregister_secret(self)

func get_grid_pos() -> Vector3i:
	var grid_element := _find_grid_element()
	if grid_element != null:
		return grid_element.grid_pos
	return Vector3i.ZERO

func discover() -> bool:
	if not is_secret:
		return false
	if not secret_ID.is_empty():
		return MapManager.discover_secret(secret_ID)
	apply_state({"discovered": true})
	return true

func apply_state(state: Dictionary, _instant: bool = false) -> void:
	var was_secret := is_secret
	is_secret = not bool(state.get("discovered", false))
	if is_secret:
		return
	var door := get_parent().get_node_or_null("DoorComponent") as DoorComponent
	if door != null:
		door.discover_door()
	var trap := get_parent().get_node_or_null("TrapComponent") as TrapComponent
	if trap != null:
		trap.discover_trap()
	if was_secret:
		discovered.emit(self)

func get_discovery_message() -> String:
	match secret_type.to_lower().strip_edges():
		"door": return "Found secret door"
		"trap": return "Found trap"
		"npc": return "Found %s" % _get_npc_name()
		var type_name when not type_name.is_empty(): return "Found %s" % type_name
		_: return "Found a secret"

func _get_npc_name() -> String:
	var npc_tile := get_parent() as NPC_Tile_Component
	if npc_tile != null:
		for npc in npc_tile.NPC_List:
			if npc != null and not npc.npc_name.strip_edges().is_empty():
				return npc.npc_name
	return "NPC"

func _find_grid_element() -> GridElement:
	var ancestor := get_parent()
	while ancestor != null:
		var element := ancestor.get_node_or_null("GridElement") as GridElement
		if element != null:
			return element
		ancestor = ancestor.get_parent()
	return null
