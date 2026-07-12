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

@export_group("Quest Reward")
@export var quest_rewards: DialogueReward
