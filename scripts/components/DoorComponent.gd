class_name DoorComponent
extends Node3D

@export var door_id: StringName
@export var local_edge := Vector3i(0, 0, -1)
@export var starts_locked := false
@export var starts_open := false

var is_open := false
var is_locked := false

func _ready() -> void:
	MapManager.register_door(self)

func _exit_tree() -> void:
	MapManager.unregister_door(self)

func blocks_movement() -> bool:
	return not is_open

func unlock() -> void:
	MapManager.unlock_door(door_id)

func open() -> bool:
	return MapManager.open_door(door_id)

func close() -> bool:
	return MapManager.close_door(door_id)

func get_grid_pos() -> Vector3i:
	var grid_element := get_parent().get_node_or_null("GridElement") as GridElement
	if grid_element != null:
		return grid_element.world_to_grid(global_position)
	return Vector3i.ZERO

func get_world_edge() -> Vector3i:
	var rotated := global_basis * Vector3(local_edge)
	return Vector3i(roundi(rotated.x), 0, roundi(rotated.z))

func apply_state(state: Dictionary, instant := false) -> void:
	var was_open := is_open
	is_locked = state.get("is_locked", starts_locked)
	is_open = state.get("is_open", starts_open)
	if instant:
		call_deferred("_sync_visual")
	elif is_open and not was_open:
		_play_animation(&"open")
	elif not is_open and was_open:
		_play_animation(&"RESET")

func _sync_visual() -> void:
	var animation_player := _get_animation_player()
	if animation_player == null:
		return
	if is_open and animation_player.has_animation(&"open"):
		animation_player.play(&"open")
		animation_player.seek(animation_player.get_animation(&"open").length, true)
		animation_player.pause()
	elif animation_player.has_animation(&"RESET"):
		animation_player.play(&"RESET")
		animation_player.advance(0.0)
		animation_player.pause()

func _play_animation(animation_name: StringName) -> void:
	var animation_player := _get_animation_player()
	if animation_player != null and animation_player.has_animation(animation_name):
		animation_player.play(animation_name)

func _get_animation_player() -> AnimationPlayer:
	return get_parent().get_node_or_null("AnimationPlayer") as AnimationPlayer
