class_name StatueComponent
extends Node3D

@export var puzzle_id: StringName

const NORTH := Vector3i(0, 0, -1)
const STATUE_FRONT := Vector3(0, 0, 1)
const ROTATION_STEP := PI / 2.0

var rotation_tween: Tween

func _ready() -> void:
	add_to_group(&"statues")
	var interactable := get_parent().get_node_or_null("InteractableComponent") as InteractableComponent
	if interactable == null:
		push_warning("StatueComponent requires an InteractableComponent sibling.")
	else:
		interactable.interacted.connect(_on_interacted)

func _exit_tree() -> void:
	if rotation_tween != null and rotation_tween.is_valid():
		rotation_tween.kill()
	rotation_tween = null

func _on_interacted(_actor: Node) -> void:
	rotate_statue()

func rotate_statue() -> void:
	if rotation_tween != null and rotation_tween.is_valid():
		return

	var statue := get_parent() as Node3D
	if statue == null:
		return

	# Statue1.glb faces south at its default rotation, so each interaction
	# turns it a quarter-turn clockwise around the vertical axis.
	statue.rotation.y = snappedf(statue.rotation.y, ROTATION_STEP)
	var target_rotation := statue.rotation.y + ROTATION_STEP
	rotation_tween = create_tween()
	rotation_tween.set_trans(Tween.TRANS_SINE)
	rotation_tween.set_ease(Tween.EASE_IN_OUT)
	rotation_tween.tween_property(statue, "rotation:y", target_rotation, 0.25)
	rotation_tween.finished.connect(func() -> void:
		rotation_tween = null
		var puzzle := _get_puzzle()
		if puzzle != null:
			puzzle.evaluate()
	)

func is_facing_north() -> bool:
	var statue := get_parent() as Node3D
	if statue == null:
		return false
	var world_front := statue.global_basis * STATUE_FRONT
	var facing := Vector3i(roundi(world_front.x), 0, roundi(world_front.z))
	return facing == NORTH

func _get_puzzle() -> StatuePuzzleComponent:
	if puzzle_id.is_empty():
		return null
	for node in get_tree().get_nodes_in_group(&"statue_puzzles"):
		var puzzle := node as StatuePuzzleComponent
		if puzzle != null and puzzle.puzzle_id == puzzle_id:
			return puzzle
	return null
