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
			for member in PartyManager.party:
				for item in member.inventory:
					if item.item_data != null and item.item_data.item_id == target_id:
						return true
			return false
		ConditionType.QUEST_STAGE_EQUAL:
			# check if player's quest stage is at a target value
			return QuestManager.get_quest_stage(target_id) == target_value
		ConditionType.QUEST_STAGE_GREATER:
			# check if payer's quest stage is beyond a target value
			return QuestManager.get_quest_stage(target_id) > target_value
	return true
