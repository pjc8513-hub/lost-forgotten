class_name DialogueEdge extends Resource

@export var choice_string: String
@export var next_node: DialogueNode # Your typo fix 'DialougeNode' -> 'DialogueNode'



@export_group("Visibility Control")
# If true, the choice disappears completely if conditions aren't met. 
# If false, it shows up greyed out/unclickable.
@export var hide_if_locked: bool = false
@export var conditions: Array[DialogueCondition]

@export_group("Execution Rewards")
# Rewards triggered only if the player actually selects this choice
@export var choice_rewards: Array[DialogueReward]

## Helper to check if all conditions pass
func is_choice_available() -> bool:
	for condition in conditions:
		if not condition.is_met():
			return false
	return true
