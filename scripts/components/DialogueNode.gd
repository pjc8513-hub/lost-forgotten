class_name DialogueNode extends Resource

@export_multiline var text: String
@export var speaker_portrait: Texture2D

# Rewards triggered immediately when this specific text node is reached
@export var immediate_rewards: Array[DialogueReward]

# The branching choices available from this node
@export var choices: Array[DialogueEdge]
