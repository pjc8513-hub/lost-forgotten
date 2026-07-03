extends Node

const CHARACTER_STAT_NAMES: Array[String] = [
	"strength",
	"endurance",
	"wisdom",
	"dexterity",
	"piety",
	"willpower",
]

var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	_rng.randomize()

func roll(dice_count: int, sides: int, modifier: int = 0) -> DiceRoll:
	assert(dice_count >= 0, "Dice count cannot be negative.")
	assert(sides > 0, "Dice must have at least one side.")
	var values: Array[int] = []
	for _die in dice_count:
		values.append(_rng.randi_range(1, sides))
	return DiceRoll.new(values, modifier)

func d20(modifier: int = 0) -> DiceRoll:
	return roll(1, 20, modifier)

func roll_character_stats() -> Dictionary:
	var stats: Dictionary = {}
	for stat_name in CHARACTER_STAT_NAMES:
		stats[stat_name] = roll(3, 6).total
	return stats

# Useful for deterministic tests, replays, and debugging.
func set_seed(value: int) -> void:
	_rng.seed = value

func randomize() -> void:
	_rng.randomize()
