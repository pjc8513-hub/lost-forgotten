class_name MinorHealSkill
extends RefCounted

const NO_USES_MESSAGE := "No uses of Minor Heal remaining until you rest"

static func execute(caster: PartyMember, skill: SkillData, target: PartyMember) -> String:
	if caster == null or skill == null or target == null:
		return "Minor Heal could not be used"
	if target.current_hp >= target.max_hp:
		return "%s is already at full HP" % target.member_name
	if caster.get_skill_uses_remaining(skill) == 0:
		return NO_USES_MESSAGE
	if not caster.spend_stamina(skill.stamina_cost):
		return "Not enough Stamina"
	if not caster.consume_skill_use(skill):
		caster.restore_stamina(skill.stamina_cost)
		return NO_USES_MESSAGE

	var rank := maxi(int(caster.learned_skills.get(skill.skill_id, 0)), 1)
	var rolled_amount := 0
	if skill.heal_amount_dice > 0 and skill.heal_amount_sides > 0:
		rolled_amount = DiceRoller.roll(skill.heal_amount_dice, skill.heal_amount_sides).total
	var heal_amount := rolled_amount + skill.bonus_res_per_rank * rank
	var hp_before := target.current_hp
	target.heal(heal_amount)
	var recovered := target.current_hp - hp_before
	return "%s healed %s for %d HP" % [caster.member_name, target.member_name, recovered]
