class_name Quest extends Resource

@export var quest_id: String = ""
@export var quest_name: String = ""
@export var is_main_quest: bool = false
@export_multiline var description: String

@export_group("Availability")
@export var availability_conditions: Array[DialogueCondition] = []

# Mapping stage numbers to a short log description
@export var stage_descriptions: Dictionary = {
	0: "Not Started",
	1: "Find the emblem in the dungeon basement.",
	2: "Return the emblem to the old man.",
	3: "Quest Completed"
}

# Dialogue shown by the quest action for each current quest stage.
# Keys are stage numbers and values are DialogueNode resources.
@export var stage_dialogue: Dictionary = {}

func get_stage_dialogue(stage: int) -> DialogueNode:
	var node = stage_dialogue.get(stage, stage_dialogue.get(str(stage), null))
	return node as DialogueNode

func is_available() -> bool:
	for condition in availability_conditions:
		if condition != null and not condition.is_met():
			return false
	return true

@export_group("Quest Description")
# information to be used in the quest log
@export var quest_giver: String = ""
@export var return_location: String = "Nobel"
@export var suggested_level: int = 0

@export_group("Quest Location")
# information to be used for unlocking locations for the travel gate
@export var display_name: String = ""
@export_file("*.tscn") var destination_map: String
@export var destination_spawn_id: StringName = "entrance"

@export_group("Quest Reward")
@export var quest_rewards: DialogueReward
