class_name FakeChestComponent
extends Node

## Opens the chest once, then teleports the player to a configured random spawn.
@export var spawn_location_ids: Array[StringName] = []

var is_open: bool = false

@onready var _teleporter: TeleportTileComponent = $TeleportTileComponent

func _ready() -> void:
	var interactable := get_parent().get_node_or_null("InteractableComponent") as InteractableComponent
	if interactable == null:
		push_warning("FakeChestComponent requires an InteractableComponent sibling.")
		return
	interactable.interaction_text = "Open"
	interactable.interacted.connect(_on_interacted)
	_teleporter.spawn_location_ids = spawn_location_ids

func _on_interacted(actor: Node) -> void:
	if is_open:
		return

	is_open = true
	var animation_player := get_parent().get_node_or_null("AnimationPlayer") as AnimationPlayer
	if animation_player != null and animation_player.has_animation(&"open"):
		animation_player.play(&"open")

	_teleporter.trigger(actor)
