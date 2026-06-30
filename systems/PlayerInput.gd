#PlayerInput.gd

extends Node

const MELEE_RANGE: int = 1

@export var actor: Node3D
@export var movement: GridMovementController

func _ready() -> void:
	if actor == null:
		actor = get_parent() as Node3D
	if movement == null and actor != null:
		movement = actor.get_node_or_null("GridMovementController") as GridMovementController

func _unhandled_input(event):
	if not TurnManager.can_player_move():
		return

	if event.is_action_pressed("ui_up"):
		_queue_player_move()

	if event.is_action_pressed("ui_left"):
		_queue_player_turn(TurnLeftCommand.new())

	if event.is_action_pressed("ui_right"):
		_queue_player_turn(TurnRightCommand.new())

	if event.is_action_pressed("interact"):
		_queue_player_interaction()
		
	if event.is_action_pressed("interact"):
		pass
	
func _queue_player_turn(cmd: Command) -> void:
	if CommandQueue.is_busy():
		return

	cmd.actor = actor
	CommandQueue.add_command(cmd)

func _queue_player_move() -> void:
	if CommandQueue.is_busy() or movement == null:
		return

	var cmd := MoveForwardCommand.new()
	cmd.actor = actor
	cmd.movement = movement
	CommandQueue.add_command(cmd)

func _queue_player_interaction() -> void:
	if CommandQueue.is_busy() or movement == null:
		return

	var cmd := InteractCommand.new()
	cmd.actor = actor
	cmd.movement = movement
	CommandQueue.add_command(cmd)
