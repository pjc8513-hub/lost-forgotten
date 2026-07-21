class_name EnemyInstance
extends Resource

signal stats_changed
signal health_changed(amount: int, feedback_type: StringName)
signal died

var enemy_data: EnemyData
var current_hp := 0
var max_hp := 0
var current_stamina := 0
var max_stamina := 0
var rolled_strength := 0
var rolled_endurance := 0
var rolled_wisdom := 0
var rolled_dexterity := 0
var rolled_piety := 0
var rolled_willpower := 0
var learned_skills: Dictionary = {}
var active_status_effects: Dictionary = {}
var active_combat_buffs: Dictionary = {}
var formation_row := 0
var formation_slot := 0
var has_fled := false

static func create(template: EnemyData, row: int, slot: int) -> EnemyInstance:
	var instance := EnemyInstance.new()
	instance.enemy_data = template
	instance.formation_row = row
	instance.formation_slot = slot
	var rolls := DiceRoller.roll_character_stats()
	instance.rolled_strength = int(rolls.get("strength", 0))
	instance.rolled_endurance = int(rolls.get("endurance", 0))
	instance.rolled_wisdom = int(rolls.get("wisdom", 0))
	instance.rolled_dexterity = int(rolls.get("dexterity", 0))
	instance.rolled_piety = int(rolls.get("piety", 0))
	instance.rolled_willpower = int(rolls.get("willpower", 0))
	for skill_id in template.skills:
		instance.learned_skills[skill_id] = 1
	for effect_name in template.starting_status_effects:
		var effect_id := StatusEffects.normalize_id(String(effect_name))
		if effect_id == StatusEffects.Effect.NONE:
			push_warning("Unknown starting status effect '%s' for %s." % [effect_name, template.display_name])
			continue
		instance.active_status_effects[effect_id] = {
			"remaining_rounds": StatusEffects.duration_rounds(effect_id),
			"save_dc": 0,
			"source": template.display_name,
			"awaiting_blocked_turn": StatusEffects.blocks_action(effect_id),
		}
	instance.max_hp = maxi(template.hp_base + CombatStats.ability_modifier(CombatStats.endurance(instance)), 1)
	instance.current_hp = instance.max_hp
	instance.max_stamina = maxi(10 + CombatStats.ability_modifier(CombatStats.endurance(instance)), 1)
	instance.current_stamina = instance.max_stamina
	return instance

func get_display_name() -> String:
	return enemy_data.display_name if enemy_data != null else "Enemy"

func is_alive() -> bool:
	return current_hp > 0

func is_conscious() -> bool:
	return is_alive()

func take_damage(amount: int, feedback_type: StringName = &"damage") -> void:
	var before := current_hp
	current_hp = clampi(current_hp - maxi(amount, 0), 0, max_hp)
	if before != current_hp:
		health_changed.emit(before - current_hp, feedback_type)
		stats_changed.emit()
		_clear_statuses_broken_by_damage()
	if current_hp == 0:
		died.emit()

func _clear_statuses_broken_by_damage() -> void:
	for raw_effect_id in active_status_effects.keys():
		if StatusEffects.breaks_on_damage(int(raw_effect_id)):
			active_status_effects.erase(raw_effect_id)

func heal(amount: int, feedback_type: StringName = &"healing") -> void:
	var before := current_hp
	current_hp = clampi(current_hp + maxi(amount, 0), 0, max_hp)
	if before != current_hp:
		health_changed.emit(current_hp - before, feedback_type)
		stats_changed.emit()

func spend_stamina(amount: int) -> bool:
	if amount > current_stamina:
		return false
	current_stamina -= maxi(amount, 0)
	return true

func get_current_flee_chance() -> float:
	if enemy_data == null or not enemy_data.can_flee or max_hp <= 0:
		return 0.0
	var base_chance := clampf(enemy_data.flee_chance, 0.0, 1.0)
	var missing_health_ratio := 1.0 - float(current_hp) / float(max_hp)
	return clampf(base_chance + missing_health_ratio * 0.5, 0.0, 0.95)
