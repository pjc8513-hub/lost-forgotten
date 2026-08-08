class_name NPCComponent
extends Resource

enum Shop_Type {
	NONE = -1,
	EQUIPMENT_SHOP = 0,
	CONSUMABLE_SHOP = 1,
	INN = 2,
	TEMPLE = 3,
	TRAINER = 4,
	TEACHER = 5,
}

@export_category("Dialogue")
@export var persistent_id: StringName
@export var npc_name: String = "NPC"
@export var dialogue_nodes: Array[DialogueNode] = []
@export var default_dialogue: DialogueNode
@export var npc_active_conditions: Array[DialogueCondition] = []
@export var dialogue_label: String = "Dialogue"

@export_category("Quests")
@export var quests_offered: Array[Quest] = []
@export var quests_related: Array[Quest] = []

@export_category("Shop")
@export var shop_type: Shop_Type = Shop_Type.NONE
@export var shop_name: String = ""
@export var shop_items: Array[ItemData] = []
@export var price_markup: float = 0.10
@export var shop_conditions: Array[DialogueCondition] = []

@export_category("MapExit")
@export_file("*.tscn") var destination_map: String
@export var destination_spawn_id: StringName
@export var destination_label: String = "Enter"
@export var travel_conditions: Array[DialogueCondition] = []


## Returns whether this NPC is visible/active based on active conditions
func is_npc_active() -> bool:
	for condition in npc_active_conditions:
		if condition != null and not condition.is_met():
			return false
	return true

## Returns the first dialogue node whose conditions are met, or the default fallback.
func get_current_dialogue_node() -> DialogueNode:
	for node in dialogue_nodes:
		if node != null and node.is_available():
			return node
	return default_dialogue

## Returns offered and related quests once each. Related quests let an NPC
## participate in or receive a quest without also being able to offer it.
func get_quests() -> Array[Quest]:
	var result: Array[Quest] = []
	var seen_ids: Dictionary = {}
	for quest in quests_offered + quests_related:
		if quest == null or seen_ids.has(quest.quest_id):
			continue
		seen_ids[quest.quest_id] = true
		result.append(quest)
	return result

func offers_quest(quest: Quest) -> bool:
	return quest != null and quests_offered.has(quest)

## Checks if the shop is currently open/available to the player.
func is_shop_available() -> bool:
	if shop_type == Shop_Type.NONE:
		return false
	for condition in shop_conditions:
		if condition != null and not condition.is_met():
			return false
	return true

## Checks if this map exit is currently unlocked/accessible.
func is_travel_available() -> bool:
	if destination_map.is_empty():
		return false
	for condition in travel_conditions:
		if condition != null and not condition.is_met():
			return false
	return true

## Triggers travel to the destination map
func trigger_travel() -> void:
	if not is_travel_available():
		push_error("Error: Cannot travel to destination, requirements not met or destination empty.")
		return
	MapManager.request_map_transition(destination_map, destination_spawn_id)

func get_persistent_id() -> StringName:
	if not persistent_id.is_empty():
		return persistent_id
	if not resource_path.is_empty():
		return StringName(resource_path)
	return StringName(npc_name)
