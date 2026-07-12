class_name Quest extends Resource

@export var quest_id: String = ""
@export var quest_name: String = ""
@export var is_main_quest: bool = false
@export_multiline var description: String

# Mapping stage numbers to a short log description
@export var stage_descriptions: Dictionary = {
	0: "Not Started",
	1: "Find the emblem in the dungeon basement.",
	2: "Return the emblem to the old man.",
	3: "Quest Completed"
}

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
