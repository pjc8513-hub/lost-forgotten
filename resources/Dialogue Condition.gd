class_name DialogueCondition extends Resource

enum ConditionType { GOLD_GREATER_THAN, HAS_ITEM, QUEST_STAGE_EQUAL, QUEST_STAGE_GREATER }

@export var type: ConditionType
@export var target_id: String # Used for item_id or quest_id
@export var target_value: int # Used for gold count or quest stage number

func is_met() -> bool:
	match type:
		ConditionType.GOLD_GREATER_THAN:
			return PartyManager.gold >= target_value
		ConditionType.HAS_ITEM:
			# check if any party member has target_id
			pass
		ConditionType.QUEST_STAGE_EQUAL:
			# check if player's quest stage is at a target value
			pass
		ConditionType.QUEST_STAGE_GREATER:
			# check if payer's quest stage is beyond a target value
			pass
	return true
