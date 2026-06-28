# autoload/TurnManager.gd
extends Node

enum State {
	EXPLORATION,
	PLAYER_TURN,
	ENEMY_TURN,
	COMBAT_MENU,
	TRANSITION,
	PAUSED
}

var state: State = State.EXPLORATION

func set_state(new_state: State) -> void:
	state = new_state

func can_player_move() -> bool:
	return state == State.EXPLORATION or state == State.PLAYER_TURN
