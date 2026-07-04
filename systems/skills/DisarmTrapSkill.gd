class_name DisarmTrapSkill
extends RefCounted

const FAILURE_MESSAGE := "Failed to disarm trap"

static func execute(caster: PartyMember, skill: SkillData, origin: Vector3i) -> String:
	if caster == null or skill == null:
		return FAILURE_MESSAGE
	if not caster.spend_stamina(skill.stamina_cost):
		return "Not enough Stamina"
	var rank := maxi(int(caster.learned_skills.get(skill.skill_id, 0)), 1)
	var trap := _find_nearest_discovered_trap(origin, 3)
	if trap == null or trap.trap_type == null:
		return "No discovered trap nearby"
	var class_bonus := int(caster.class_data.skill_bonuses.get(skill.skill_id, 0)) if caster.class_data != null else 0
	var rank_bonus := rank
	var total_bonus := class_bonus + rank_bonus
	var target_dc := skill.dc_base + trap.trap_type.disarm_rank
	
	var check := DCChecks.check_character(caster, skill.dc_stat, target_dc, total_bonus)
	if not check.succeeded or not trap.disarm():
		return FAILURE_MESSAGE
	return "Disarmed trap"

static func _find_nearest_discovered_trap(origin: Vector3i, radius: int) -> TrapComponent:
	var nearest: TrapComponent
	var nearest_distance := radius + 1
	for x_offset in range(-radius, radius + 1):
		for z_offset in range(-radius, radius + 1):
			var distance := absi(x_offset) + absi(z_offset)
			if distance > radius or distance >= nearest_distance:
				continue
			var position := origin + Vector3i(x_offset, 0, z_offset)
			for element in MapManager.get_elements(position):
				for child in element.get_parent().find_children("*", "TrapComponent", true, false):
					var trap := child as TrapComponent
					if trap != null and trap.is_discovered() and not trap.disarmed and not trap.triggered:
						nearest = trap
						nearest_distance = distance
	return nearest
