extends ItemData
class_name ConsumableData

@export var hp_restore: int = 0
@export var mp_restore: int = 0
@export var remove_status: Array[String] = []
@export var is_resurrection_scroll: bool = false


func apply_to_character(character: PartyMember) -> bool:
	if character == null:
		return false
	if is_resurrection_scroll:
		return ResurrectionSkill.revive_target(character, "Resurrection Scroll")
	var changed := false
	if hp_restore > 0 and character.current_hp < character.max_hp:
		character.heal(hp_restore)
		changed = true
	for status in remove_status:
		var status_id: int = StatusEffects.normalize_id(status)
		if status_id != StatusEffects.Effect.NONE and character.active_status_effects.erase(status_id):
			changed = true
	if changed:
		StatCalculator.recalculate(character)
	return changed
