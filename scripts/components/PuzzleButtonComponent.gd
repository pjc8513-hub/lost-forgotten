class_name PuzzleButtonComponent
extends Node

@export var button_id: StringName
@export var puzzle_id: StringName

var is_enabled := true

func _ready() -> void:
	add_to_group(&"puzzle_buttons")
	var interactable := get_parent().get_node_or_null("InteractableComponent") as InteractableComponent
	if interactable == null:
		push_warning("PuzzleButtonComponent requires an InteractableComponent sibling.")
		return
	interactable.interacted.connect(_on_interacted)

func _on_interacted(_actor: Node) -> void:
	if not is_enabled:
		return

	for node in get_tree().get_nodes_in_group(&"button_order_puzzles"):
		var puzzle := node as ButtonOrderPuzzleComponent
		if puzzle != null and puzzle.puzzle_id == puzzle_id:
			puzzle.press(button_id)
			return
