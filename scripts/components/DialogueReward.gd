class_name DialogueReward extends Resource

enum RewardType { ADD_GOLD, REMOVE_GOLD, ADD_ITEM, REMOVE_ITEM, ADD_EXP, SET_QUEST_STAGE, TELEPORT }

@export var type: RewardType
@export var target_id: String # item_id or quest_id
@export var value: int       # amount of gold, exp, or quest stage

@export_group("Teleportation Options")
@export_file("*.tscn") var destination_map: String
@export var destination_spawn_id: StringName

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
			var removed := false
			for member in PartyManager.party:
				for item in member.inventory:
					if item.item_data != null and item.item_data.item_id == target_id:
						member.drop_inventory_item(item)
						removed = true
						message = "Removed item %s from %s's inventory." % [item.item_data.name, member.member_name]
						MapManager.request_alert(message)
						break
				if removed:
					break
			if not removed:
				push_error("Error: Could not find item %s in party inventory to remove." % target_id)
		RewardType.ADD_EXP:
			for member in PartyManager.party:
				var leveled_up = member.add_xp(value)
				if leveled_up:
					MapManager.request_alert("%s leveled up to %d!" % [member.member_name, member.level])
			MapManager.request_alert("Party gained %d experience points." % value)
		RewardType.SET_QUEST_STAGE:
			QuestManager.set_quest_stage(target_id, value)
		RewardType.TELEPORT:
			if destination_map.is_empty():
				push_error("Error: Teleport destination map is empty.")
				return
			MapManager.request_map_transition(destination_map, destination_spawn_id)
