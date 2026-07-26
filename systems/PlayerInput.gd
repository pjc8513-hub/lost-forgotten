#PlayerInput.gd

extends Node

const MELEE_RANGE: int = 1

@export var actor: Node3D
@export var movement: GridMovementController

func _ready() -> void:
	# PlayerInput is inside the exploration world, which is disabled during
	# combat. Keep this node alive so global debug input remains available.
	process_mode = Node.PROCESS_MODE_ALWAYS
	if actor == null:
		actor = get_parent() as Node3D
	if movement == null and actor != null:
		movement = actor.get_node_or_null("GridMovementController") as GridMovementController

func _unhandled_input(event):
	if event.is_action_pressed("toggle_debug"):
		var debug_overlay := get_tree().get_first_node_in_group("debug_overlay") as CanvasItem
		if debug_overlay != null:
			debug_overlay.visible = not debug_overlay.visible
		get_viewport().set_input_as_handled()
		return

	# The remaining actions are exploration-only, as they were before this
	# node was made always-active for the debug toggle.
	if not TurnManager.can_player_move():
		return

	for index in PartyManager.MAX_PARTY_SIZE:
		if event.is_action_pressed("select_member_%d" % (index + 1)):
			PartyManager.select_party_member(index)
			get_viewport().set_input_as_handled()
			return

	if event.is_action_pressed("toggle_torch") or (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F):
		if actor != null and actor.has_node("OmniLight3D"):
			var torch = actor.get_node("OmniLight3D")
			if torch.has_method("toggle"):
				torch.toggle()
				get_viewport().set_input_as_handled()
				return


	if not TurnManager.can_player_move():
		return

	if event.is_action_pressed("ui_up"):
		_queue_player_move()

	if event.is_action_pressed("ui_left"):
		_queue_player_turn(TurnLeftCommand.new())

	if event.is_action_pressed("ui_right"):
		_queue_player_turn(TurnRightCommand.new())
		
	if event.is_action_pressed("ui_down"):
		_queue_player_turn(TurnAroundCommand.new())

	if event.is_action_pressed("interact"):
		_queue_player_interaction()
		
	if event.is_action_pressed("cancel_cast"):
		pass

func _queue_player_turn(cmd: Command) -> void:
	if CommandQueue.is_busy():
		return

	cmd.actor = actor
	CommandQueue.add_command(cmd)

func _queue_player_move() -> void:
	if CommandQueue.is_busy() or movement == null:
		return

	MapManager.request_dialogue_close()
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
