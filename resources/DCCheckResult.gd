class_name DCCheckResult
extends RefCounted

var roll: DiceRoll
var dc: int = 0
var succeeded: bool = false
var margin: int = 0

func _init(dice_roll: DiceRoll = null, difficulty: int = 0) -> void:
	roll = dice_roll
	dc = difficulty
	if roll != null:
		succeeded = roll.total >= dc
		margin = roll.total - dc
