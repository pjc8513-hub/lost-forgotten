extends ItemData
class_name ConsumableData

@export var hp_restore: int = 0
@export var mp_restore: int = 0
@export var remove_status: Array[String] = []


func apply_to_character(character: ClassData) -> void:
	if hp_restore > 0 and not character.blocks_hp_healing():
		character.current_hp = min(character.current_hp + hp_restore, character.get_max_hp())
	if mp_restore > 0:
		character.current_mp = min(character.current_mp + mp_restore, character.get_max_mp())
	for status in remove_status:
		if status.to_lower().strip_edges() == "item":
			character.clear_statuses_by_condition("item")
		else:
			character.clear_status_effect(status)
