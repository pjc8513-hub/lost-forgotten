extends Node

func check(dc: int, modifier: int = 0) -> DCCheckResult:
	return DCCheckResult.new(DiceRoller.d20(modifier), dc)

func check_character(character: PartyMember, stat_name: String, dc: int, bonus: int = 0) -> DCCheckResult:
	return check(dc, get_stat_modifier(character, stat_name) + bonus)

func get_stat_modifier(character: PartyMember, stat_name: String) -> int:
	if character == null:
		return 0
	var stat_value := _get_stat_value(character, stat_name)
	return StatCalculator.get_ability_modifier(stat_value)

func _get_stat_value(character: PartyMember, stat_name: String) -> int:
	match stat_name.to_lower().strip_edges():
		"strength": return StatCalculator.get_strength(character)
		"endurance": return StatCalculator.get_endurance(character)
		"wisdom": return StatCalculator.get_wisdom(character)
		"dexterity": return StatCalculator.get_dexterity(character)
		"piety": return StatCalculator.get_piety(character)
		"willpower": return StatCalculator.get_willpower(character)
		_:
			push_warning("Unknown DC check stat: %s" % stat_name)
			return 10
