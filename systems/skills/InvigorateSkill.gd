class_name InvigorateSkill
extends RefCounted

const NO_USES_MESSAGE := "No uses of Invigorate remaining until you rest"

static func execute(caster: CharacterState, skill: SkillData) -> String:
	if caster == null or skill == null:
		return "Invigorate could not be used"
	if caster.get_skill_uses_remaining(skill) == 0:
		return NO_USES_MESSAGE
	if not caster.spend_stamina(skill.stamina_cost):
		return "Not enough Stamina"
	if not caster.consume_skill_use(skill):
		# Defensive fallback if another caller consumed the final use this frame.
		caster.restore_stamina(skill.stamina_cost)
		return NO_USES_MESSAGE

	var rank := maxi(int(caster.learned_skills.get(skill.skill_id, 0)), 1)
	var rolled_amount := 0
	if skill.stamina_restore_sides > 0:
		rolled_amount = DiceRoller.roll(1, skill.stamina_restore_sides).total
	var restore_amount := rolled_amount + skill.bonus_res_per_rank * rank
	var stamina_before := caster.current_stamina
	caster.restore_stamina(restore_amount)
	var recovered := caster.current_stamina - stamina_before
	return "%s recovered %d Stamina" % [caster.member_name, recovered]
