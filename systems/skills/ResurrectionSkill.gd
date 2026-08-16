class_name ResurrectionSkill
extends RefCounted

static func execute(caster: PartyMember, skill: SkillData, targets: Array) -> String:
	if caster == null or skill == null or not caster.is_alive():
		return "Spell could not be used"
	if targets.is_empty():
		return "No valid target"
	if caster.get_skill_uses_remaining(skill) == 0:
		return "No uses of %s remaining until you rest" % skill.display_name

	var valid_targets: Array[PartyMember] = []
	for value in targets:
		var target := value as PartyMember
		if target != null and target.active_status_effects.has(StatusEffects.Effect.DEAD):
			valid_targets.append(target)
	if valid_targets.is_empty():
		return "Resurrection can only target dead characters"
	if not caster.spend_stamina(skill.stamina_cost):
		return "Not enough Stamina"
	if not caster.consume_skill_use(skill):
		caster.restore_stamina(skill.stamina_cost)
		return "No uses of %s remaining until you rest" % skill.display_name

	var revived_names: Array[String] = []
	for target in valid_targets:
		if revive_target(target, caster.member_name):
			revived_names.append(target.member_name)

	if revived_names.is_empty():
		caster.restore_stamina(skill.stamina_cost)
		return "Resurrection failed"
	return "%s cast %s on %s" % [caster.member_name, skill.display_name, ", ".join(revived_names)]

static func revive_target(target: PartyMember, source: String = "") -> bool:
	if target == null or not target.active_status_effects.has(StatusEffects.Effect.DEAD):
		return false
	target.active_status_effects.erase(StatusEffects.Effect.DEAD)
	target.current_hp = 1
	target.active_status_effects[StatusEffects.Effect.WEAKEN] = {
		"remaining_rounds": StatusEffects.duration_rounds(StatusEffects.Effect.WEAKEN),
		"save_dc": 0,
		"source": source,
		"awaiting_blocked_turn": false,
	}
	StatCalculator.recalculate(target)
	return true
