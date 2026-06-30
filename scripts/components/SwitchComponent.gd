class_name SwitchComponent
extends Node

@export var target_door_ids: Array[StringName]

func activate() -> void:
	for door_id in target_door_ids:
		MapManager.unlock_door(door_id)
