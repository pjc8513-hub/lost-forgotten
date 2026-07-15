class_name HealingSkill
extends RefCounted

static func execute(caster: PartyMember, skill: SkillData, targets: Array) -> String:
	if caster == null or skill == null:
		return "Spell could not be used"
	if targets.is_empty():
		return "No valid target"
	if caster.get_skill_uses_remaining(skill) == 0:
		return "No uses of %s remaining until you rest" % skill.display_name

	var heal_targets := _get_healable_targets(targets)
	if heal_targets.is_empty():
		return "No one needs healing"
	if not caster.spend_stamina(skill.stamina_cost):
		return "Not enough Stamina"
	if not caster.consume_skill_use(skill):
		caster.restore_stamina(skill.stamina_cost)
		return "No uses of %s remaining until you rest" % skill.display_name

	var rank := maxi(int(caster.learned_skills.get(skill.skill_id, 0)), skill.starting_rank)
	var heal_amount := _roll_heal_amount(skill, rank)
	var healed_entries: Array[String] = []
	for target in heal_targets:
		var hp_before := target.current_hp
		target.heal(heal_amount)
		var recovered := target.current_hp - hp_before
		if recovered > 0:
			healed_entries.append("%s for %d HP" % [target.member_name, recovered])

	if healed_entries.is_empty():
		return "No one needs healing"
	return "%s cast %s: %s" % [
		caster.member_name,
		skill.display_name,
		", ".join(healed_entries),
	]

static func _get_healable_targets(targets: Array) -> Array[PartyMember]:
	var result: Array[PartyMember] = []
	for target in targets:
		var member := target as PartyMember
		if member == null or not member.is_alive():
			continue
		if member.current_hp >= member.max_hp or _has_healing_blocker(member):
			continue
		result.append(member)
	return result

static func _roll_heal_amount(skill: SkillData, rank: int) -> int:
	var rolled_amount := 0
	if skill.heal_amount_dice > 0 and skill.heal_amount_sides > 0:
		rolled_amount = DiceRoller.roll(skill.heal_amount_dice, skill.heal_amount_sides).total
	return rolled_amount + skill.bonus_res_per_rank * rank

static func _has_healing_blocker(member: PartyMember) -> bool:
	for effect_id in member.active_status_effects:
		if StatusEffects.blocks_healing(int(effect_id)):
			return true
	return false
