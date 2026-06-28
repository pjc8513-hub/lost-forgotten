class_name InteractableComponent
extends Node

signal interacted(actor)

@export var interaction_text: String = "Interact"

func interact(actor: Node) -> void:
	interacted.emit(actor)
