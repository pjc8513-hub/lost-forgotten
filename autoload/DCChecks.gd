extends Node

func check(dc: int, modifier: int = 0) -> DCCheckResult:
	return DCCheckResult.new(DiceRoller.d20(modifier), dc)

func check_character(character: CharacterState, stat_name: String, dc: int, bonus: int = 0) -> DCCheckResult:
	return check(dc, get_stat_modifier(character, stat_name) + bonus)

func get_stat_modifier(character: CharacterState, stat_name: String) -> int:
	if character == null:
		return 0
	var stat_value := _get_stat_value(character, stat_name)
	# Standard ability modifier: 10-11 = +0, 12-13 = +1, etc.
	return floori((stat_value - 10) / 2.0)

func _get_stat_value(character: CharacterState, stat_name: String) -> int:
	match stat_name.to_lower().strip_edges():
		"strength": return StatCalculator.get_strength(character)
		"endurance": return StatCalculator.get_endurance(character)
		"wisdom": return StatCalculator.get_wisdom(character)
		"dexterity": return StatCalculator.get_dexterity(character)
		"willpower": return StatCalculator.get_willpower(character)
		_:
			push_warning("Unknown DC check stat: %s" % stat_name)
			return 10
