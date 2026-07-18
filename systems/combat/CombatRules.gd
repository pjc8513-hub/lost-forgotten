class_name CombatRules
extends RefCounted

const RESISTANCE_DC := 12

static func basic_attack(attacker: Resource, target: Resource) -> Dictionary:
	var attack_roll := DiceRoller.d20(CombatStats.accuracy(attacker))
	# Descending AC: lower AC raises the number the attacker must reach.
	var target_number := 20 - CombatStats.armor_class(target)
	var hit := attack_roll.total >= target_number
	var damage := 0
	if hit:
		var profile := CombatStats.damage_profile(attacker)
		var count := maxi(int(profile.get("dice_rolls", 0)), 0)
		var sides := maxi(int(profile.get("dice_sides", 0)), 1)
		damage = maxi(DiceRoller.roll(count, sides, int(profile.get("bonus", 0))).total, 1)
		target.take_damage(damage)
	return {"kind": &"attack", "actor": attacker, "target": target, "roll": attack_roll.total, "target_number": target_number, "hit": hit, "damage": damage}

static func use_skill(caster: Resource, target: Resource, skill: SkillData) -> Dictionary:
	if skill == null or not caster.learned_skills.has(skill.skill_id):
		return {"kind": &"skill", "success": false, "message": "Skill is not known."}
	if not caster.spend_stamina(skill.stamina_cost):
		return {"kind": &"skill", "success": false, "message": "Not enough stamina."}
	var element := _element_key(skill.element)
	var resisted := false
	var resist_roll := 0
	if not element.is_empty() and CombatStats.has_resistance(target, element):
		resist_roll = DiceRoller.d20(CombatStats.ability_modifier(CombatStats.willpower(target))).total
		resisted = resist_roll >= RESISTANCE_DC
	if resisted:
		return {"kind": &"skill", "success": true, "resisted": true, "resist_roll": resist_roll, "damage": 0, "actor": caster, "target": target, "skill": skill}
	var damage := 0
	if skill.damage_amount_rolls > 0 and skill.damage_amount_dice > 0:
		damage = maxi(DiceRoller.roll(skill.damage_amount_dice, skill.damage_amount_rolls).total, 0)
		target.take_damage(damage, StringName(element if not element.is_empty() else "damage"))
	var effect_id := _status_effect_id(skill.status_effect)
	if effect_id != StatusEffects.Effect.NONE:
		apply_status(target, effect_id, skill.dc_base, CombatStats.display_name(caster))
	return {"kind": &"skill", "success": true, "resisted": false, "damage": damage, "actor": caster, "target": target, "skill": skill}

static func apply_status(target: Resource, effect_id: int, save_dc: int = 0, source: String = "") -> void:
	if not StatusEffects.DEFINITIONS.has(effect_id):
		return
	target.active_status_effects[effect_id] = {"remaining_rounds": StatusEffects.duration_rounds(effect_id), "save_dc": save_dc, "source": source}
	if target is PartyMember:
		StatCalculator.recalculate(target)

static func tick_statuses(actor: Resource) -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	var to_clear: Array[int] = []
	for raw_id in actor.active_status_effects.keys():
		var effect_id := int(raw_id)
		var entry: Dictionary = actor.active_status_effects[raw_id]
		var dot := StatusEffects.dot_damage(effect_id)
		if dot > 0:
			actor.take_damage(dot, &"dot")
		elif dot < 0:
			actor.heal(-dot)
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
	for effect_id in to_clear:
		actor.active_status_effects.erase(effect_id)
	return results

static func can_act(actor: Resource) -> bool:
	for effect_id in actor.active_status_effects:
		if StatusEffects.blocks_action(int(effect_id)):
			return false
	return actor.is_alive()

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
	return StatusEffects.Effect.NONE
