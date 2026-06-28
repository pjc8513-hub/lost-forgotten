class_name TrapComponent
extends Node

@export var damage: int = 5
@export var trigger_once: bool = false
var triggered: bool = false

func trigger(actor: Node) -> void:
	if trigger_once and triggered:
		return

	triggered = true
	print("Trap triggered for ", actor.name)
