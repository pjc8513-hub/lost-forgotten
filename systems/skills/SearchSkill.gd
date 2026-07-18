class_name SearchSkill
extends RefCounted

const FAILURE_MESSAGE := "Failed to find anything here"
const NO_STAMINA_MESSAGE := "Not enough Stamina"

static func execute(caster: PartyMember, skill: SkillData, origin: Vector3i) -> String:
	if caster == null or skill == null:
		return FAILURE_MESSAGE
	EncounterManager.add_search_threat()
	if not caster.spend_stamina(skill.stamina_cost):
		return NO_STAMINA_MESSAGE

	var rank := maxi(int(caster.learned_skills.get(skill.skill_id, 0)), 1)
	var secrets := _find_secrets(origin, rank + 2)
	var class_bonus := int(caster.class_data.skill_bonuses.get(skill.skill_id, 0)) if caster.class_data != null else 0
	var check := DCChecks.check_character(caster, skill.dc_stat, skill.dc_base, class_bonus)
	if not check.succeeded or secrets.is_empty():
		return FAILURE_MESSAGE

	var messages: Array[String] = []
	for secret in secrets:
		if secret.discover():
			var message := secret.get_discovery_message()
			if message not in messages:
				messages.append(message)
	return FAILURE_MESSAGE if messages.is_empty() else "\n".join(messages)

static func _find_secrets(origin: Vector3i, radius: int) -> Array[SecretComponent]:
	var result: Array[SecretComponent] = []
	for x_offset in range(-radius, radius + 1):
		for z_offset in range(-radius, radius + 1):
			if absi(x_offset) + absi(z_offset) > radius:
				continue
			var position := origin + Vector3i(x_offset, 0, z_offset)
			for element in MapManager.get_elements(position):
				for child in element.get_parent().find_children("*", "SecretComponent", true, false):
					var secret := child as SecretComponent
					if secret != null and secret.is_secret and secret not in result:
						result.append(secret)
	return result
