# StatCalculator.gd  (Autoload — res://systems/StatCalculator.gd)
# Responsibility: Compute derived stats from a CharacterState + its ClassData.
# Pure calculation only — reads state, returns values, never modifies anything.
# Call recalculate() after any stat change to push results back into CharacterState.

extends Node

# ---------------------------------------------------------------------------
# Public API — call these from UI, combat, and component code
# ---------------------------------------------------------------------------

func get_strength(state: CharacterState) -> int:
	return state.base_strength + state.bonus_strength + _combat_bonus(state, "strength")

func get_endurance(state: CharacterState) -> int:
	return state.base_endurance + state.bonus_endurance + _combat_bonus(state, "endurance")

func get_wisdom(state: CharacterState) -> int:
	return state.base_wisdom + state.bonus_wisdom + _combat_bonus(state, "wisdom")

func get_dexterity(state: CharacterState) -> int:
	return state.base_dexterity + state.bonus_dexterity + _combat_bonus(state, "dexterity")

func get_willpower(state: CharacterState) -> int:
	return state.base_willpower + state.bonus_willpower + _combat_bonus(state, "willpower")

func get_max_hp(state: CharacterState) -> int:
	var cd := state.class_data
	if cd == null:
		return state.max_hp
	var str_val := get_strength(state)
	var end_val := get_endurance(state)
	return cd.hp_base \
		+ (cd.hp_per_level * state.level) \
		+ floori(str_val * cd.hp_str_scale) \
		+ floori(end_val * cd.hp_end_scale) \
		+ state.bonus_willpower  # Willpower grants minor HP buffer

func get_max_mp(state: CharacterState) -> int:
	var cd := state.class_data
	if cd == null:
		return state.max_mp
	var wis_val := get_wisdom(state)
	return cd.mp_base \
		+ (cd.mp_per_level * state.level) \
		+ floori(wis_val * cd.mp_wis_scale)

func get_armor_class(state: CharacterState) -> int:
	var cd := state.class_data
	if cd == null:
		return 10
	var dex_val := get_dexterity(state)
	return 10 \
		+ cd.ac_bonus \
		+ floori(dex_val * cd.ac_dex_scale) \
		+ _status_modifier(state, "armor_class") \
		+ _combat_bonus(state, "armor_class")

func get_accuracy(state: CharacterState) -> int:
	var cd := state.class_data
	if cd == null:
		return 0
	var str_val := get_strength(state)
	var dex_val := get_dexterity(state)
	var wis_val := get_wisdom(state)
	return cd.accuracy_base \
		+ floori(str_val * cd.accuracy_str_scale) \
		+ floori(dex_val * cd.accuracy_dex_scale) \
		+ floori(wis_val * cd.accuracy_wis_scale) \
		+ _status_modifier(state, "accuracy") \
		+ _combat_bonus(state, "accuracy")

func get_critical_chance(state: CharacterState) -> int:
	var cd := state.class_data
	if cd == null:
		return 1
	var dex_val := get_dexterity(state)
	var wis_val := get_wisdom(state)
	return cd.crit_base \
		+ floori(dex_val * cd.crit_dex_scale) \
		+ floori(wis_val * cd.crit_wis_scale) \
		+ _combat_bonus(state, "critical_chance")

func get_initiative(state: CharacterState) -> int:
	var cd := state.class_data
	if cd == null:
		return 0
	var dex_val := get_dexterity(state)
	var wis_val := get_wisdom(state)
	return cd.initiative_base \
		+ floori(dex_val * cd.initiative_dex_scale) \
		+ floori(wis_val * cd.initiative_wis_scale) \
		+ _status_modifier(state, "initiative") \
		+ _combat_bonus(state, "initiative")

func get_attack_speed(state: CharacterState) -> int:
	var cd := state.class_data
	if cd == null:
		return 0
	var dex_val := get_dexterity(state)
	return cd.attack_speed_base \
		+ floori(dex_val * cd.attack_speed_dex_scale) \
		+ _combat_bonus(state, "attack_speed")

func get_bonus_damage(state: CharacterState) -> int:
	var cd := state.class_data
	if cd == null:
		return 0
	var str_val := get_strength(state)
	var dex_val := get_dexterity(state)
	var wis_val := get_wisdom(state)
	return cd.bonus_damage_base \
		+ floori(str_val * cd.damage_str_scale) \
		+ floori(dex_val * cd.damage_dex_scale) \
		+ floori(wis_val * cd.damage_wis_scale) \
		+ _combat_bonus(state, "bonus_damage")

func get_magic_amp(state: CharacterState) -> int:
	var cd := state.class_data
	if cd == null:
		return 0
	var wis_val := get_wisdom(state)
	return cd.magic_amp_base \
		+ floori(wis_val * cd.magic_amp_wis_scale) \
		+ _combat_bonus(state, "magic_amp")

func get_movement(state: CharacterState) -> int:
	var cd := state.class_data
	if cd == null:
		return 4
	return cd.base_movement \
		+ _status_modifier(state, "movement") \
		+ _combat_bonus(state, "movement")

func get_resistance(state: CharacterState, element: String) -> int:
	match element.to_lower().strip_edges():
		"fire":     return state.resist_fire     + _combat_bonus(state, "resist_fire")
		"water":    return state.resist_water    + _combat_bonus(state, "resist_water")
		"earth":    return state.resist_earth    + _combat_bonus(state, "resist_earth")
		"electric": return state.resist_electric + _combat_bonus(state, "resist_electric")
		"light":    return state.resist_light    + _combat_bonus(state, "resist_light")
		"dark":     return state.resist_dark     + _combat_bonus(state, "resist_dark")
	return 0

# ---------------------------------------------------------------------------
# Recalculate — writes cached maximums back into CharacterState.
# Call this after leveling up, spending stat points, equipping items, etc.
# Does NOT reset current HP/MP unless reset_vitals is true.
# ---------------------------------------------------------------------------

func recalculate(state: CharacterState, reset_vitals: bool = false) -> void:
	state.max_hp = get_max_hp(state)
	state.max_mp = get_max_mp(state)

	if reset_vitals:
		state.current_hp = state.max_hp
		state.current_mp = state.max_mp
	else:
		state.current_hp = clampi(state.current_hp, 0, state.max_hp)
		state.current_mp = clampi(state.current_mp, 0, state.max_mp)

	state.stats_changed.emit()

# ---------------------------------------------------------------------------
# Private helpers — read from active_combat_buffs / active_status_effects
# ---------------------------------------------------------------------------

func _combat_bonus(state: CharacterState, key: String) -> int:
	var entry = state.active_combat_buffs.get(key, {})
	if entry is Dictionary:
		return int(entry.get("value", 0))
	return int(entry)

func _status_modifier(state: CharacterState, stat: String) -> int:
	# StatusEffects autoload provides per-status stat deltas.
	# This keeps StatCalculator decoupled from status logic.
	if not Engine.has_singleton("StatusEffects"):
		return 0
	var total := 0
	for status_id in state.active_status_effects.keys():
		total += StatusEffects.stat_modifier(status_id, stat)
	return total
