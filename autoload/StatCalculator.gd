# StatCalculator.gd  (Autoload — res://systems/StatCalculator.gd)
# Responsibility: Compute derived stats from a PartyMember + its ClassData.
# Pure calculation only — reads state, returns values, never modifies anything.
# Call recalculate() after any stat change to push results back into PartyMember.

extends Node

# ---------------------------------------------------------------------------
# Public API — call these from UI, combat, and component code
# ---------------------------------------------------------------------------

func get_strength(state: PartyMember) -> int:
	return state.rolled_strength + _class_stat(state, "base_strength") + _race_stat(state, "bonus_strength") + state.bonus_strength + _status_modifier(state, "strength") + _combat_bonus(state, "strength") + _equipment_bonus(state, ["strength", "strength_bonus", "might_bonus"])

func get_endurance(state: PartyMember) -> int:
	return state.rolled_endurance + _class_stat(state, "base_endurance") + _race_stat(state, "bonus_endurance") + state.bonus_endurance + _status_modifier(state, "endurance") + _combat_bonus(state, "endurance") + _equipment_bonus(state, ["endurance", "endurance_bonus"])

func get_wisdom(state: PartyMember) -> int:
	return state.rolled_wisdom + _class_stat(state, "base_wisdom") + _race_stat(state, "bonus_wisdom") + state.bonus_wisdom + _status_modifier(state, "wisdom") + _combat_bonus(state, "wisdom") + _equipment_bonus(state, ["wisdom", "wisdom_bonus"])

func get_dexterity(state: PartyMember) -> int:
	return state.rolled_dexterity + _class_stat(state, "base_dexterity") + _race_stat(state, "bonus_dexterity") + state.bonus_dexterity + _status_modifier(state, "dexterity") + _combat_bonus(state, "dexterity") + _equipment_bonus(state, ["dexterity", "dexterity_bonus"])

func get_piety(state: PartyMember) -> int:
	return state.rolled_piety + _class_stat(state, "base_piety") + _race_stat(state, "bonus_piety") + state.bonus_piety + _status_modifier(state, "piety") + _combat_bonus(state, "piety") + _equipment_bonus(state, ["piety", "piety_bonus"])

func get_willpower(state: PartyMember) -> int:
	return state.rolled_willpower + _class_stat(state, "base_willpower") + _race_stat(state, "bonus_willpower") + state.bonus_willpower + _status_modifier(state, "willpower") + _combat_bonus(state, "willpower") + _equipment_bonus(state, ["willpower", "willpower_bonus"])

func get_ability_modifier(ability_score: int) -> int:
	return floori((ability_score - 10) / 2.0)

func get_max_hp(state: PartyMember) -> int:
	var cd := state.class_data
	if cd == null:
		return state.max_hp
	var str_modifier := get_ability_modifier(get_strength(state))
	var end_modifier := get_ability_modifier(get_endurance(state))
	return cd.hp_base \
		+ (cd.hp_per_level * state.level) \
		+ floori(str_modifier * cd.hp_str_scale) \
		+ floori(end_modifier * cd.hp_end_scale)

func get_max_stamina(state: PartyMember) -> int:
	var cd := state.class_data
	if cd == null:
		return state.max_stamina
	return cd.stamina \
		+ (cd.stamina_per_level * state.level) \
		+ floori(get_ability_modifier(get_endurance(state)) * cd.stamina_end_scale)

func get_armor_class(state: PartyMember) -> int:
	var cd := state.class_data
	if cd == null:
		return 10
	var dex_modifier := get_ability_modifier(get_dexterity(state))
	return 10 \
		+ cd.ac_bonus \
		- floori(dex_modifier * cd.ac_dex_scale) \
		+ _equipped_armor_class(state) \
		+ _status_modifier(state, "armor_class") \
		+ _combat_bonus(state, "armor_class")

func get_accuracy(state: PartyMember) -> int:
	var cd := state.class_data
	if cd == null:
		return 0
	var str_modifier := get_ability_modifier(get_strength(state))
	var dex_modifier := get_ability_modifier(get_dexterity(state))
	var wis_modifier := get_ability_modifier(get_wisdom(state))
	return cd.accuracy_base \
		+ floori(str_modifier * cd.accuracy_str_scale) \
		+ floori(dex_modifier * cd.accuracy_dex_scale) \
		+ floori(wis_modifier * cd.accuracy_wis_scale) \
		+ _equipped_accuracy(state) \
		+ _weapon_mastery_accuracy_bonus(state) \
		+ _status_modifier(state, "accuracy") \
		+ _combat_bonus(state, "accuracy")

func get_critical_chance(state: PartyMember) -> int:
	var cd := state.class_data
	if cd == null:
		return 1
	var dex_modifier := get_ability_modifier(get_dexterity(state))
	var wis_modifier := get_ability_modifier(get_wisdom(state))
	return cd.crit_base \
		+ floori(dex_modifier * cd.crit_dex_scale) \
		+ floori(wis_modifier * cd.crit_wis_scale) \
		+ _combat_bonus(state, "critical_chance")

func get_initiative(state: PartyMember) -> int:
	var cd := state.class_data
	if cd == null:
		return 0
	var dex_modifier := get_ability_modifier(get_dexterity(state))
	var wis_modifier := get_ability_modifier(get_wisdom(state))
	return cd.initiative_base \
		+ floori(dex_modifier * cd.initiative_dex_scale) \
		+ floori(wis_modifier * cd.initiative_wis_scale) \
		+ _equipment_bonus(state, ["initiative", "initiative_bonus"]) \
		+ _status_modifier(state, "initiative") \
		+ _combat_bonus(state, "initiative")

func get_attack_speed(state: PartyMember) -> int:
	var cd := state.class_data
	if cd == null:
		return 0
	var dex_modifier := get_ability_modifier(get_dexterity(state))
	return cd.attack_speed_base \
		+ floori(dex_modifier * cd.attack_speed_dex_scale) \
		+ _combat_bonus(state, "attack_speed")

func get_bonus_damage(state: PartyMember) -> int:
	var cd := state.class_data
	if cd == null:
		return 0
	var str_modifier := get_ability_modifier(get_strength(state))
	var dex_modifier := get_ability_modifier(get_dexterity(state))
	var wis_modifier := get_ability_modifier(get_wisdom(state))
	return cd.bonus_damage_base \
		+ floori(str_modifier * cd.damage_str_scale) \
		+ floori(dex_modifier * cd.damage_dex_scale) \
		+ floori(wis_modifier * cd.damage_wis_scale) \
		+ _equipped_bonus_damage(state) \
		+ _status_modifier(state, "bonus_damage") \
		+ _combat_bonus(state, "bonus_damage")

func get_damage_profile(state: PartyMember) -> Dictionary:
	for item in state.inventory:
		if item.is_equipped and item.item_data is WeaponData:
			var weapon := item.item_data as WeaponData
			return {
				"dice_rolls": weapon.dice_rolls,
				"dice_sides": weapon.dice_sides,
				"bonus": get_bonus_damage(state),
			}
	return {"dice_rolls": 0, "dice_sides": 0, "bonus": get_bonus_damage(state)}

func get_magic_amp(state: PartyMember) -> int:
	var cd := state.class_data
	if cd == null:
		return 0
	var wis_modifier := get_ability_modifier(get_wisdom(state))
	return cd.magic_amp_base \
		+ floori(wis_modifier * cd.magic_amp_wis_scale) \
		+ _combat_bonus(state, "magic_amp")

func get_movement(state: PartyMember) -> int:
	var cd := state.class_data
	if cd == null:
		return 4
	return cd.base_movement \
		+ _status_modifier(state, "movement") \
		+ _combat_bonus(state, "movement")

func has_resistance(state: PartyMember, element: String) -> bool:
	var key := element.to_lower().strip_edges()
	if key.is_empty():
		return false
	return _innate_resistance(state, key) \
		or _combat_resistance(state, key) \
		or _skill_resistance(state, key) \
		or _equipment_resistance(state, key)

func get_resistance(state: PartyMember, element: String) -> bool:
	return has_resistance(state, element)

# ---------------------------------------------------------------------------
# Recalculate — writes cached maximums back into PartyMember.
# Call this after leveling up, spending stat points, equipping items, etc.
# Does NOT reset current HP/MP unless reset_vitals is true.
# ---------------------------------------------------------------------------

func recalculate(state: PartyMember, reset_vitals: bool = false) -> void:
	state.max_hp = get_max_hp(state)
	state.max_stamina = get_max_stamina(state)

	if reset_vitals:
		state.current_hp = state.max_hp
		state.current_stamina = state.max_stamina
	else:
		state.current_hp = clampi(state.current_hp, 0, state.max_hp)
		state.current_stamina = clampi(state.current_stamina, 0, state.max_stamina)

	state.stats_changed.emit()

# ---------------------------------------------------------------------------
# Private helpers — read from active_combat_buffs / active_status_effects
# ---------------------------------------------------------------------------

func _combat_bonus(state: PartyMember, key: String) -> int:
	var entry = state.active_combat_buffs.get(key, {})
	if entry is Dictionary:
		return int(entry.get("value", 0))
	return int(entry)

func _status_modifier(state: PartyMember, stat: String) -> int:
	# StatusEffects autoload provides per-status stat deltas.
	# This keeps StatCalculator decoupled from status logic.
	var total := 0
	for status_id in state.active_status_effects.keys():
		total += StatusEffects.stat_modifier(status_id, stat)
	return total

func _equipment_bonus(state: PartyMember, keys: Array[String]) -> int:
	var total := 0
	for item in state.inventory:
		if not item.is_equipped:
			continue
		for key in keys:
			total += item.get_bonus(key)
	return total

func _equipped_armor_class(state: PartyMember) -> int:
	var total := _equipment_bonus(state, ["armor_class", "armor_class_bonus"])
	for item in state.inventory:
		if not item.is_equipped or item.item_data == null:
			continue
		if item.item_data is ArmorData:
			var armor := item.item_data as ArmorData
			total += armor.armor_class + armor.armor_class_bonus
		elif item.item_data is AccessoryData:
			total += (item.item_data as AccessoryData).armor_class
	return total

func _equipped_accuracy(state: PartyMember) -> int:
	var total := _equipment_bonus(state, ["accuracy", "accuracy_bonus"])
	for item in state.inventory:
		if item.is_equipped and item.item_data is WeaponData:
			total += (item.item_data as WeaponData).accuracy_bonus
	return total

func _weapon_mastery_accuracy_bonus(state: PartyMember) -> int:
	var equipped_weapon_type := WeaponData.Weapon_Type.NONE
	for item in state.inventory:
		if item.is_equipped and item.item_data is WeaponData:
			equipped_weapon_type = (item.item_data as WeaponData).weapon_type
			break
	if equipped_weapon_type == WeaponData.Weapon_Type.NONE:
		return 0

	var total := 0
	for raw_skill_id in state.learned_skills:
		var skill := SkillSystem.get_skill(StringName(raw_skill_id))
		if skill == null \
				or skill.archetype != SkillData.Archetype.PASSIVE \
				or skill.weapon_type != equipped_weapon_type:
			continue
		var rank := int(state.learned_skills.get(raw_skill_id, 0))
		if rank <= 0:
			continue
		rank = mini(rank, maxi(skill.maximum_rank, 1))
		total += rank * skill.bonus_accuracy_per_rank
	return total

func _equipped_bonus_damage(state: PartyMember) -> int:
	var total := _equipment_bonus(state, ["bonus_damage", "bonus_damage_bonus"])
	for item in state.inventory:
		if item.is_equipped and item.item_data is WeaponData:
			total += (item.item_data as WeaponData).bonus_damage_bonus
	return total

func _innate_resistance(state: PartyMember, element: String) -> bool:
	match element:
		"fire": return state.resist_fire
		"water": return state.resist_water
		"earth": return state.resist_earth
		"electric": return state.resist_electric
		"light": return state.resist_light
		"dark": return state.resist_dark
	return false

func _combat_resistance(state: PartyMember, element: String) -> bool:
	var entry = state.active_combat_buffs.get("resist_" + element)
	if entry is Dictionary:
		return int(entry.get("value", 0)) != 0
	return entry != null and bool(entry)

func _skill_resistance(state: PartyMember, element: String) -> bool:
	for skill_id in state.learned_skills:
		var skill := SkillSystem.get_skill(StringName(skill_id))
		if skill != null and _skill_resistance_key(skill.resist_element) == element:
			return true
	return false

func _skill_resistance_key(element: SkillData.Element) -> String:
	match element:
		SkillData.Element.FIRE: return "fire"
		SkillData.Element.EARTH: return "earth"
		SkillData.Element.AIR: return "electric"
		SkillData.Element.WATER: return "water"
		SkillData.Element.PHYSICAL: return "physical"
		SkillData.Element.SPIRIT: return "spirit"
		SkillData.Element.HOLY: return "light"
		SkillData.Element.DARK: return "dark"
	return ""

func _equipment_resistance(state: PartyMember, element: String) -> bool:
	for item in state.inventory:
		if item.is_equipped and item.has_resistance(element):
			return true
	return false

func _class_stat(state: PartyMember, property: StringName) -> int:
	return 0 if state.class_data == null else int(state.class_data.get(property))

func _race_stat(state: PartyMember, property: StringName) -> int:
	return 0 if state.race_data == null else int(state.race_data.get(property))
