extends ItemData
class_name ConsumableData

const NOBEL_MAP_PATH := "res://scenes/maps/nobel/nobel.tscn"
const NOBEL_ENTRANCE_SPAWN := &"entrance"

@export var hp_restore: int = 0
@export var mp_restore: int = 0
@export var remove_status: Array[String] = []
@export var is_resurrection_scroll: bool = false
@export var is_teleport_scroll: bool = false


func apply_to_character(character: PartyMember) -> bool:
	if character == null:
		return false
	if is_teleport_scroll:
		if TurnManager.state != TurnManager.State.EXPLORATION:
			return false
		MapManager.request_map_transition(NOBEL_MAP_PATH, NOBEL_ENTRANCE_SPAWN)
		return true
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
