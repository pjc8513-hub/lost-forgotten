class_name DialogueNode extends Resource

@export_multiline var text: String
@export var speaker_portrait: Texture2D

# Optional label used when this node is presented as a top-level NPC choice.
# Child dialogue choices continue to use DialogueEdge.choice_string.
@export var choice_string: String = ""

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
