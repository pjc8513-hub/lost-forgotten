extends Node

signal dungeon_time_changed(elapsed_seconds: int)
signal steps_changed(steps: int)
signal stamina_cost_due(amount: int)

const STEPS_PER_STAMINA: int = 10
const SECONDS_PER_STEP: int = 60
const DUNGEON_START_TIME_SECONDS: int = 9 * 60 * 60

var dungeon_elapsed_time: int = 0
var dungeon_steps: int = 0
var _is_tracking: bool = false


func begin_dungeon() -> void:
	dungeon_elapsed_time = 0
	dungeon_steps = 0
	_is_tracking = true
	dungeon_time_changed.emit(0)
	steps_changed.emit(0)


func end_dungeon() -> void:
	_is_tracking = false


func record_step() -> void:
	if not _is_tracking:
		return
	dungeon_steps += 1
	dungeon_elapsed_time += SECONDS_PER_STEP
	steps_changed.emit(dungeon_steps)
	dungeon_time_changed.emit(dungeon_elapsed_time)
	if dungeon_steps % STEPS_PER_STAMINA == 0:
		stamina_cost_due.emit(1)


func advance_time(seconds: int) -> void:
	if seconds <= 0:
		return
	dungeon_elapsed_time += seconds
	dungeon_time_changed.emit(dungeon_elapsed_time)


func get_time_of_day_seconds() -> int:
	return DUNGEON_START_TIME_SECONDS + dungeon_elapsed_time
