class_name DialogueNode extends Resource

@export_multiline var text: String
@export var speaker_portrait: Texture2D

# Conditions that must be met to access/show this dialogue node
@export var conditions: Array[DialogueCondition] = []

# Rewards triggered immediately when this specific text node is reached
@export var immediate_rewards: Array[DialogueReward]

# The branching choices available from this node
@export var choices: Array[DialogueEdge]

func is_available() -> bool:
	for condition in conditions:
		if condition != null and not condition.is_met():
			return false
	return true
