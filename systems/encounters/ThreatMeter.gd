class_name ThreatMeter
extends RefCounted

var value: float = 0.0
var maximum: float = 100.0

func add(amount: float) -> float:
	value = clampf(value + maxf(amount, 0.0), 0.0, maximum)
	return value

func reset() -> void:
	value = 0.0

func roll() -> bool:
	return value > 0.0 and DiceRoller.roll(1, 100).total <= value
