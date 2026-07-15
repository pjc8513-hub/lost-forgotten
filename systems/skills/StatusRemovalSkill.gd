class_name StatusRemovalSkill
extends RefCounted

static func execute(caster: PartyMember, skill: SkillData, targets: Array) -> String:
	if caster == null or skill == null:
		return "Spell could not be used"
	if targets.is_empty():
		return "No valid target"
	if caster.get_skill_uses_remaining(skill) == 0:
		return "No uses of %s remaining until you rest" % skill.display_name
	if not caster.spend_stamina(skill.stamina_cost):
		return "Not enough Stamina"

	var effect_ids := _get_effect_ids(skill)
	var cleared_names: Array[String] = []
	for target in targets:
		if target == null:
			continue
		for effect_id in effect_ids:
			if target.active_status_effects.erase(effect_id):
				StatCalculator.recalculate(target)
				cleared_names.append(target.member_name)

	if cleared_names.is_empty():
		caster.restore_stamina(skill.stamina_cost)
		return "No matching status effects to remove"
	if not caster.consume_skill_use(skill):
		caster.restore_stamina(skill.stamina_cost)
		return "No uses of %s remaining until you rest" % skill.display_name

	return "%s cast %s on %s" % [
		caster.member_name,
		skill.display_name,
		", ".join(cleared_names),
	]

static func _get_effect_ids(skill: SkillData) -> Array[int]:
	var result: Array[int] = []
	for effect_name in skill.remove_effect:
		var effect_id := StatusEffects.normalize_id(effect_name)
		if effect_id != StatusEffects.Effect.NONE and not result.has(effect_id):
			result.append(effect_id)
	return result
