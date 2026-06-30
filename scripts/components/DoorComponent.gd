class_name DoorComponent
extends Node3D

@export var door_id: StringName
@export var local_edge := Vector3.LEFT
@export var starts_locked := false

var is_open := false
var is_locked := false

func _ready() -> void:
	is_locked = starts_locked
	MapManager.register_door(self)

func blocks_movement() -> bool:
	return not is_open

func unlock() -> void:
	is_locked = false

func open() -> bool:
	if is_locked:
		return false
	is_open = true
	return true
