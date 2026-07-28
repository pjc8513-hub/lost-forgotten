class_name BumpComponent
extends Node

## Emitted whenever the player bumps the wall edge this component belongs to.
signal bumped(actor: Node3D, direction: Vector3i)

## The first bump behavior. Leave this enabled for map edges that return to town.
@export var opens_travel_menu: bool = true

func bump(actor: Node3D, direction: Vector3i) -> void:
	bumped.emit(actor, direction)
	if opens_travel_menu:
		MapManager.request_travel_menu()
