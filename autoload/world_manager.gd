extends Node

signal dungeon_time_changed(elapsed_seconds: int)
signal steps_changed(steps: int)
signal stamina_cost_due(amount: int)

const STEPS_PER_STAMINA: int = 10

var dungeon_elapsed_time: float = 0.0
var dungeon_steps: int = 0
var _last_reported_second: int = -1
var _is_tracking: bool = false


func _process(delta: float) -> void:
	if not _is_tracking:
		return
	dungeon_elapsed_time += delta
	var elapsed_seconds := floori(dungeon_elapsed_time)
	if elapsed_seconds != _last_reported_second:
		_last_reported_second = elapsed_seconds
		dungeon_time_changed.emit(elapsed_seconds)


func begin_dungeon() -> void:
	dungeon_elapsed_time = 0.0
	dungeon_steps = 0
	_last_reported_second = 0
	_is_tracking = true
	dungeon_time_changed.emit(0)
	steps_changed.emit(0)


func end_dungeon() -> void:
	_is_tracking = false


func record_step() -> void:
	if not _is_tracking:
		return
	dungeon_steps += 1
	steps_changed.emit(dungeon_steps)
	if dungeon_steps % STEPS_PER_STAMINA == 0:
		stamina_cost_due.emit(1)
