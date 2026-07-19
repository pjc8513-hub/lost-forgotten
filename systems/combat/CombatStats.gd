class_name CombatStats
extends RefCounted

static func ability_modifier(score: int) -> int:
	return floori((score - 10) / 2.0)

static func strength(actor: Resource) -> int:
	if actor is PartyMember:
		return StatCalculator.get_strength(actor)
	var enemy := actor as EnemyInstance
	return enemy.rolled_strength + enemy.enemy_data.base_strength + _status_bonus(enemy, "strength")

static func endurance(actor: Resource) -> int:
	if actor is PartyMember:
		return StatCalculator.get_endurance(actor)
	var enemy := actor as EnemyInstance
	return enemy.rolled_endurance + enemy.enemy_data.base_endurance + _status_bonus(enemy, "endurance")

static func wisdom(actor: Resource) -> int:
	if actor is PartyMember:
		return StatCalculator.get_wisdom(actor)
	var enemy := actor as EnemyInstance
	return enemy.rolled_wisdom + enemy.enemy_data.base_wisdom + _status_bonus(enemy, "wisdom")

static func dexterity(actor: Resource) -> int:
	if actor is PartyMember:
		return StatCalculator.get_dexterity(actor)
	var enemy := actor as EnemyInstance
	return enemy.rolled_dexterity + enemy.enemy_data.base_dexterity + _status_bonus(enemy, "dexterity")

static func willpower(actor: Resource) -> int:
	if actor is PartyMember:
		return StatCalculator.get_willpower(actor)
	var enemy := actor as EnemyInstance
	return enemy.rolled_willpower + enemy.enemy_data.base_willpower + _status_bonus(enemy, "willpower")

static func armor_class(actor: Resource) -> int:
	if actor is PartyMember:
		return StatCalculator.get_armor_class(actor)
	var enemy := actor as EnemyInstance
	return 10 + enemy.enemy_data.ac_bonus - ability_modifier(dexterity(enemy)) + _status_bonus(enemy, "armor_class") + _buff(enemy, "armor_class")

static func accuracy(actor: Resource) -> int:
	if actor is PartyMember:
		return StatCalculator.get_accuracy(actor)
	var enemy := actor as EnemyInstance
	return enemy.enemy_data.accuracy_bonus + ability_modifier(dexterity(enemy)) + _status_bonus(enemy, "accuracy") + _buff(enemy, "accuracy")

static func level(actor: Resource) -> int:
	if actor is PartyMember:
		return maxi(actor.level, 1)
	var enemy := actor as EnemyInstance
	return maxi(enemy.enemy_data.enemy_level, 1)

static func level_accuracy_modifier(attacker: Resource, target: Resource) -> int:
	return clampi(level(attacker) - level(target), -5, 5)

static func initiative(actor: Resource) -> int:
	if actor is PartyMember:
		return StatCalculator.get_initiative(actor)
	var enemy := actor as EnemyInstance
	return enemy.enemy_data.initiative_bonus + ability_modifier(dexterity(enemy)) + _status_bonus(enemy, "initiative")

static func damage_profile(actor: Resource, target: Resource = null) -> Dictionary:
	if actor is PartyMember:
		var profile := StatCalculator.get_damage_profile(actor)
		profile["bonus"] = int(profile.get("bonus", 0)) + _arms_master_bonus(actor, target)
		return profile
	var enemy := actor as EnemyInstance
	return {"dice_rolls": enemy.enemy_data.damage_dice_rolls, "dice_sides": enemy.enemy_data.damage_dice_sides, "bonus": enemy.enemy_data.bonus_damage_base + ability_modifier(strength(enemy))}

static func _arms_master_bonus(attacker: PartyMember, target: Resource) -> int:
	if target is not EnemyInstance or target.enemy_data == null:
		return 0
	var rank := int(attacker.learned_skills.get(&"ArmsMaster", 0))
	if rank <= 0:
		return 0
	var level_bonus := maxi(level(attacker) - level(target) + 1, 0)
	return mini(level_bonus, rank)

static func has_resistance(actor: Resource, element: String) -> bool:
	if actor is PartyMember:
		return StatCalculator.has_resistance(actor, element)
	var data := (actor as EnemyInstance).enemy_data
	match element.to_lower():
		"fire": return data.resist_fire
		"water": return data.resist_water
		"earth": return data.resist_earth
		"air", "electric": return data.resist_air
		"physical": return data.resist_physical
		"light", "holy": return data.resist_light
		"dark": return data.resist_dark
		"spirit": return data.resist_spirit
	return false

static func display_name(actor: Resource) -> String:
	return actor.member_name if actor is PartyMember else (actor as EnemyInstance).get_display_name()

static func _status_bonus(actor: Resource, key: String) -> int:
	var total := 0
	for effect_id in actor.active_status_effects:
		total += StatusEffects.stat_modifier(int(effect_id), key)
	return total

static func _buff(actor: Resource, key: String) -> int:
	var value = actor.active_combat_buffs.get(key, 0)
	return int(value.get("value", 0)) if value is Dictionary else int(value)
