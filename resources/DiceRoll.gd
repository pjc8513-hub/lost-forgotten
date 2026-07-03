class_name DiceRoll
extends RefCounted

var rolls: Array[int] = []
var modifier: int = 0
var total: int = 0

func _init(values: Array[int] = [], bonus: int = 0) -> void:
	rolls.assign(values)
	modifier = bonus
	total = modifier
	for value in rolls:
		total += value

func notation(sides: int) -> String:
	var suffix := ""
	if modifier != 0:
		suffix = "%+d" % modifier
	return "%dd%d%s" % [rolls.size(), sides, suffix]
