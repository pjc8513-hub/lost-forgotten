class_name MinorHealSkill
extends RefCounted

static func execute(caster: PartyMember, skill: SkillData, target: PartyMember) -> String:
	return HealingSkill.execute(caster, skill, [target])
