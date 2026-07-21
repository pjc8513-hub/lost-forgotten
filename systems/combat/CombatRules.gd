class_name CombatRules
extends RefCounted

const RESISTANCE_DC := 12

static func basic_attack(attacker: Resource, target: Resource) -> Dictionary:
	var attack_roll := DiceRoller.d20(CombatStats.accuracy(attacker) + CombatStats.level_accuracy_modifier(attacker, target))
	# Descending AC: lower AC raises the number the attacker must reach.
	var target_number := 20 - CombatStats.armor_class(target)
	var hit := attack_roll.total >= target_number
	var critical := hit and not attack_roll.rolls.is_empty() and attack_roll.rolls[0] == 20
	var damage := 0
	if hit:
		var profile := CombatStats.damage_profile(attacker, target)
		var count := maxi(int(profile.get("dice_rolls", 0)), 0)
		var sides := maxi(int(profile.get("dice_sides", 0)), 1)
		damage = maxi(DiceRoller.roll(count, sides, int(profile.get("bonus", 0))).total, 1)
		target.take_damage(damage)
	return {"kind": &"attack", "actor": attacker, "target": target, "roll": attack_roll.total, "target_number": target_number, "hit": hit, "critical": critical, "damage": damage}

static func can_cast(caster: Resource) -> bool:
	if caster == null or not caster.is_alive():
		return false
	for effect_id in caster.active_status_effects:
		if StatusEffects.blocks_casting(int(effect_id)):
			return false
	return true

## Resolves one cast against every supplied target. Costs are paid once and
## target_results contains the independent resistance/effect result per target.
static func use_skill(caster: Resource, targets: Array, skill: SkillData) -> Dictionary:
	var result := {"kind": &"skill", "success": false, "actor": caster, "skill": skill, "target_results": []}
	if skill == null or caster == null or not caster.learned_skills.has(skill.skill_id):
		result.message = "Skill is not known."
		return result
	if not can_cast(caster):
		result.message = "%s cannot cast." % CombatStats.display_name(caster)
		return result
	if caster is PartyMember and caster.get_skill_uses_remaining(skill) == 0:
		result.message = "No uses of %s remaining until you rest." % skill.display_name
		return result

	var valid_targets := _valid_skill_targets(targets)
	if valid_targets.is_empty():
		result.message = "No valid target."
		return result
	if _is_healing_skill(skill):
		valid_targets = _healable_targets(valid_targets)
		if valid_targets.is_empty():
			result.message = "No one needs healing."
			return result
	elif not skill.remove_effect.is_empty():
		valid_targets = _removable_targets(valid_targets, skill)
		if valid_targets.is_empty():
			result.message = "No matching status effects to remove."
			return result
	if not caster.spend_stamina(skill.stamina_cost):
		result.message = "Not enough stamina."
		return result
	if caster is PartyMember and not caster.consume_skill_use(skill):
		caster.restore_stamina(skill.stamina_cost)
		result.message = "No uses of %s remaining until you rest." % skill.display_name
		return result

	var shared_heal := _roll_heal(skill, caster) if _is_healing_skill(skill) else 0
	for target in valid_targets:
		result.target_results.append(_apply_skill_to_target(caster, target, skill, shared_heal))
	result.success = true
	if not result.target_results.is_empty():
		result.target = result.target_results[0].get("target")
	return result

static func apply_status(target: Resource, effect_id: int, save_dc: int = 0, source: String = "") -> bool:
	if target == null or not StatusEffects.DEFINITIONS.has(effect_id):
		return false
	target.active_status_effects[effect_id] = {
		"remaining_rounds": StatusEffects.duration_rounds(effect_id),
		"save_dc": save_dc,
		"source": source,
		"awaiting_blocked_turn": StatusEffects.blocks_action(effect_id),
	}
	if target is PartyMember:
		StatCalculator.recalculate(target)
	return true

static func tick_statuses(actor: Resource) -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	var to_clear: Array[int] = []
	for raw_id in actor.active_status_effects.keys():
		var effect_id := int(raw_id)
		var entry: Dictionary = actor.active_status_effects[raw_id]
		if StatusEffects.blocks_action(effect_id) \
				and int(entry.get("remaining_rounds", -1)) > 0 \
				and not entry.has("awaiting_blocked_turn"):
			entry.awaiting_blocked_turn = true
		var dot := StatusEffects.dot_damage(effect_id)
		if dot > 0:
			var hp_before: int = actor.current_hp
			actor.take_damage(dot, &"dot")
			var damage_dealt := hp_before - int(actor.current_hp)
			if damage_dealt > 0:
				results.append({"effect_id": effect_id, "damage": damage_dealt})
		elif dot < 0 and not _has_healing_blocker(actor):
			var healing_hp_before: int = actor.current_hp
			actor.heal(-dot)
			var healing_done := int(actor.current_hp) - healing_hp_before
			if healing_done > 0:
				results.append({"effect_id": effect_id, "healing": healing_done})
		# A new action blocker cannot expire before denying its promised turn.
		if bool(entry.get("awaiting_blocked_turn", false)):
			continue
		if StatusEffects.is_negative(effect_id) and int(entry.get("save_dc", 0)) > 0:
			var save := DiceRoller.d20(CombatStats.ability_modifier(CombatStats.willpower(actor))).total
			if save >= int(entry.save_dc):
				to_clear.append(effect_id)
				results.append({"effect_id": effect_id, "saved": true, "roll": save})
				continue
		var rounds := int(entry.get("remaining_rounds", -1))
		if rounds > 0:
			entry.remaining_rounds = rounds - 1
			if entry.remaining_rounds == 0:
				to_clear.append(effect_id)
				results.append({"effect_id": effect_id, "expired": true})
	for effect_id in to_clear:
		actor.active_status_effects.erase(effect_id)
	if actor is PartyMember and not to_clear.is_empty():
		StatCalculator.recalculate(actor)
	return results

## Called only when an actor reaches a turn it cannot take. A one-turn stun is
## removed here, after it has actually skipped that turn.
static func consume_blocked_turn(actor: Resource) -> Array[int]:
	var consumed: Array[int] = []
	for raw_id in actor.active_status_effects.keys():
		var effect_id := int(raw_id)
		if not StatusEffects.blocks_action(effect_id):
			continue
		var entry: Dictionary = actor.active_status_effects[raw_id]
		if not bool(entry.get("awaiting_blocked_turn", false)):
			continue
		entry.awaiting_blocked_turn = false
		var rounds := int(entry.get("remaining_rounds", -1))
		if rounds > 0:
			entry.remaining_rounds = rounds - 1
			if entry.remaining_rounds == 0:
				actor.active_status_effects.erase(raw_id)
		consumed.append(effect_id)
	if actor is PartyMember and not consumed.is_empty():
		StatCalculator.recalculate(actor)
	return consumed

static func can_act(actor: Resource) -> bool:
	for effect_id in actor.active_status_effects:
		if StatusEffects.blocks_action(int(effect_id)):
			return false
	return actor.is_alive()

static func _apply_skill_to_target(caster: Resource, target: Resource, skill: SkillData, shared_heal: int) -> Dictionary:
	var outcome := {"target": target, "resisted": false, "resist_roll": 0, "damage": 0, "healing": 0, "stamina_restored": 0, "status_applied": StatusEffects.Effect.NONE, "status_resisted": false, "status_save_roll": 0, "removed_effects": []}
	var element := _element_key(skill.element)
	if _is_hostile_skill(skill) and not element.is_empty() and CombatStats.has_resistance(target, element):
		outcome.resist_roll = DiceRoller.d20(CombatStats.ability_modifier(CombatStats.willpower(target))).total
		outcome.resisted = outcome.resist_roll >= RESISTANCE_DC
	if outcome.resisted:
		return outcome
	if skill.damage_amount_rolls > 0 and skill.damage_amount_dice > 0:
		outcome.damage = maxi(DiceRoller.roll(skill.damage_amount_dice, skill.damage_amount_rolls).total, 0)
		target.take_damage(outcome.damage, StringName(element if not element.is_empty() else "damage"))
	if shared_heal > 0 and target.has_method("heal") and target.is_alive() and not _has_healing_blocker(target):
		var hp_before: int = target.current_hp
		target.heal(shared_heal, &"healing")
		outcome.healing = target.current_hp - hp_before
	if skill.stamina_restore_sides > 0 and target.has_method("restore_stamina"):
		var restore := DiceRoller.roll(1, skill.stamina_restore_sides).total + skill.bonus_res_per_rank * _skill_rank(caster, skill)
		var stamina_before: int = target.current_stamina
		target.restore_stamina(restore)
		outcome.stamina_restored = target.current_stamina - stamina_before
	for effect_id in _removal_effect_ids(skill):
		if target.active_status_effects.erase(effect_id):
			outcome.removed_effects.append(effect_id)
	if target is PartyMember and not outcome.removed_effects.is_empty():
		StatCalculator.recalculate(target)
	var applied_effect := _status_effect_id(skill.status_effect)
	if applied_effect != StatusEffects.Effect.NONE and target.is_alive():
		if StatusEffects.is_negative(applied_effect):
			outcome.status_resisted = _has_status_resistance(target, skill.status_effect)
			if not outcome.status_resisted and skill.dc_base > 0:
				outcome.status_save_roll = DiceRoller.d20(CombatStats.ability_modifier(CombatStats.willpower(target))).total
				outcome.status_resisted = outcome.status_save_roll >= skill.dc_base
		if not outcome.status_resisted and apply_status(target, applied_effect, skill.dc_base, CombatStats.display_name(caster)):
			outcome.status_applied = applied_effect
	return outcome

static func _valid_skill_targets(targets: Array) -> Array[Resource]:
	var result: Array[Resource] = []
	for value in targets:
		var target := value as Resource
		if target != null and target.has_method("is_alive") and target.is_alive():
			result.append(target)
	return result

static func _is_healing_skill(skill: SkillData) -> bool:
	return skill.heal_amount_dice > 0 and skill.heal_amount_sides > 0

static func _is_hostile_skill(skill: SkillData) -> bool:
	var status_id := _status_effect_id(skill.status_effect)
	return skill.damage_amount_dice > 0 \
			or (status_id != StatusEffects.Effect.NONE and StatusEffects.is_negative(status_id))

static func _roll_heal(skill: SkillData, caster: Resource) -> int:
	return DiceRoller.roll(skill.heal_amount_dice, skill.heal_amount_sides).total + skill.bonus_res_per_rank * _skill_rank(caster, skill)

static func _skill_rank(caster: Resource, skill: SkillData) -> int:
	return maxi(int(caster.learned_skills.get(skill.skill_id, skill.starting_rank)), skill.starting_rank)

static func _healable_targets(targets: Array[Resource]) -> Array[Resource]:
	var result: Array[Resource] = []
	for target in targets:
		if target.has_method("heal") and target.current_hp < target.max_hp and not _has_healing_blocker(target):
			result.append(target)
	return result

static func _has_healing_blocker(target: Resource) -> bool:
	for effect_id in target.active_status_effects:
		if StatusEffects.blocks_healing(int(effect_id)):
			return true
	return false

static func _has_status_resistance(target: Resource, status_effect: SkillData.Status_effect) -> bool:
	for skill_id in target.learned_skills:
		var known_skill := SkillSystem.get_skill(StringName(skill_id))
		if known_skill != null and known_skill.resist_status == status_effect:
			return true
	return false

static func _removable_targets(targets: Array[Resource], skill: SkillData) -> Array[Resource]:
	var result: Array[Resource] = []
	var ids := _removal_effect_ids(skill)
	for target in targets:
		for effect_id in ids:
			if target.active_status_effects.has(effect_id):
				result.append(target)
				break
	return result

static func _removal_effect_ids(skill: SkillData) -> Array[int]:
	var result: Array[int] = []
	for effect_name in skill.remove_effect:
		var effect_id := StatusEffects.normalize_id(effect_name)
		if effect_id != StatusEffects.Effect.NONE and effect_id not in result:
			result.append(effect_id)
	return result

static func _element_key(element: SkillData.Element) -> String:
	match element:
		SkillData.Element.FIRE: return "fire"
		SkillData.Element.EARTH: return "earth"
		SkillData.Element.AIR: return "air"
		SkillData.Element.WATER: return "water"
		SkillData.Element.PHYSICAL: return "physical"
		SkillData.Element.SPIRIT: return "spirit"
		SkillData.Element.HOLY: return "light"
		SkillData.Element.DARK: return "dark"
	return ""

static func _status_effect_id(effect: SkillData.Status_effect) -> int:
	match effect:
		SkillData.Status_effect.STUN: return StatusEffects.Effect.STUN
		SkillData.Status_effect.FEAR: return StatusEffects.Effect.FEAR
		SkillData.Status_effect.POISON: return StatusEffects.Effect.POISON
		SkillData.Status_effect.BURN: return StatusEffects.Effect.BURN
		SkillData.Status_effect.FREEZE: return StatusEffects.Effect.FREEZE
		SkillData.Status_effect.PARALYZE: return StatusEffects.Effect.PARALYSIS
		SkillData.Status_effect.BLIND: return StatusEffects.Effect.BLIND
		SkillData.Status_effect.WEAK: return StatusEffects.Effect.WEAKEN
		SkillData.Status_effect.BLEED: return StatusEffects.Effect.BLEED
		SkillData.Status_effect.DECAY: return StatusEffects.Effect.DECAY
		SkillData.Status_effect.SLEEP: return StatusEffects.Effect.SLEEP
		SkillData.Status_effect.CONFUSE: return StatusEffects.Effect.CONFUSE
		SkillData.Status_effect.SLOW: return StatusEffects.Effect.SLOW
		SkillData.Status_effect.CURSE: return StatusEffects.Effect.CURSE
		SkillData.Status_effect.DISEASED: return StatusEffects.Effect.DISEASED
		SkillData.Status_effect.DROWNING: return StatusEffects.Effect.DROWNING
		SkillData.Status_effect.REGENERATE: return StatusEffects.Effect.REGENERATE
		SkillData.Status_effect.HASTE: return StatusEffects.Effect.HASTE
		SkillData.Status_effect.BLESS: return StatusEffects.Effect.BLESS
		SkillData.Status_effect.STONE_SKIN: return StatusEffects.Effect.STONE_SKIN
	return StatusEffects.Effect.NONE
