class_name BlockerComponent
extends Node

@export var blocker_ID: StringName
@export var blocks_movement: bool = true
@export var blocks_vision: bool = false

var is_open := false
var _initial_blocks_movement := true
var _initial_blocks_vision := false

func _ready() -> void:
	_initial_blocks_movement = blocks_movement
	_initial_blocks_vision = blocks_vision
	if not blocker_ID.is_empty():
		MapManager.register_blocker(self)

func _exit_tree() -> void:
	if not blocker_ID.is_empty():
		MapManager.unregister_blocker(self)

func open() -> bool:
	return MapManager.open_blocker(blocker_ID)

func apply_state(state: Dictionary, instant := false) -> void:
	var was_open := is_open
	is_open = state.get("is_open", false)
	blocks_movement = _initial_blocks_movement and not is_open
	blocks_vision = _initial_blocks_vision and not is_open

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
