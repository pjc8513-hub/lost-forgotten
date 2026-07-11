class_name DialogueReward extends Resource

enum RewardType { ADD_GOLD, REMOVE_GOLD, ADD_ITEM, REMOVE_ITEM, ADD_EXP, SET_QUEST_STAGE }

@export var type: RewardType
@export var target_id: String # item_id or quest_id
@export var value: int       # amount of gold, exp, or quest stage

func give_reward() -> void:
	var message: String
	match type:
		RewardType.ADD_GOLD:
			PartyManager.add_gold(value)
		RewardType.REMOVE_GOLD:
			PartyManager.spend_gold(value)
		RewardType.ADD_ITEM:
			var member = PartyManager.selected_party_member
			if member == null:
				push_error("Error: No selected party member.")
				return
			var instance = LootManager.create_item_instance(target_id)
			if instance == null or instance.item_data == null:
				push_error("Error: Item database could not find or create item: %s" % target_id)
			else:
				var success = member.add_inventory_item(instance)
				if success:
					message = "Added item %s to %s's inventory." % [target_id, member.member_name]
					MapManager.request_alert(message)
				else:
					push_error("Failed to item item %s to %s's inventory." % [target_id, member.member_name])
		RewardType.REMOVE_ITEM:
			pass
			# find the character holding the quest item and then remove it using member drop inventory item
			# member.drop_inventory_item(target_id)
		RewardType.ADD_EXP:
			pass
			#give xp to every party member
			# member.add_xp(value)
		RewardType.SET_QUEST_STAGE:
			pass
			# Update quest status if multi-stage quest (ie. main quest)
