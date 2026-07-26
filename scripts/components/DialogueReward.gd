class_name DialogueReward extends Resource

enum RewardType { ADD_GOLD, REMOVE_GOLD, ADD_ITEM, REMOVE_ITEM, ADD_EXP, SET_QUEST_STAGE, TELEPORT, START_COMBAT, ADVANCE_QUEST_STAGE, REMOVE_SOURCE_NPC }

@export var type: RewardType
@export var target_id: String # item_id or quest_id
@export var value: int       # amount of gold, exp, or quest stage

@export_group("Combat Options")
@export var combat_scene: PackedScene
@export var enemy_ids: Array[StringName] = []
@export var enemy_counts: Array[int] = []
@export var victory_rewards: Array[DialogueReward] = []
@export var defeat_rewards: Array[DialogueReward] = []
@export var flee_rewards: Array[DialogueReward] = []

@export_group("Teleportation Options")
@export_file("*.tscn") var destination_map: String
@export var destination_spawn_id: StringName

func give_reward(context: Dictionary = {}) -> void:
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
				member.add_xp(value)
			MapManager.request_alert("Party gained %d experience points." % value)
		RewardType.SET_QUEST_STAGE:
			QuestManager.set_quest_stage(target_id, value)
		RewardType.TELEPORT:
			if destination_map.is_empty():
				push_error("Error: Teleport destination map is empty.")
				return
			MapManager.request_map_transition(destination_map, destination_spawn_id)
		RewardType.START_COMBAT:
			_start_combat(context)
		RewardType.ADVANCE_QUEST_STAGE:
			QuestManager.advance_quest_stage(target_id, value if value > 0 else 1)
		RewardType.REMOVE_SOURCE_NPC:
			var source_tile := context.get("source_tile") as NPC_Tile_Component
			var source_npc := context.get("source_npc") as NPCComponent
			if source_tile == null or source_npc == null:
				push_error("Error: Remove-source-NPC reward requires dialogue source context.")
				return
			source_tile.remove_npc(source_npc)

func _start_combat(context: Dictionary) -> void:
	if combat_scene == null:
		push_error("Error: Dialogue combat scene is empty.")
		return
	if enemy_ids.is_empty():
		push_error("Error: Dialogue combat has no enemies configured.")
		return
	if enemy_ids.size() > 3:
		push_error("Error: Dialogue combat supports at most 3 enemy rows.")
		return

	var catalog := EnemyCatalog.new()
	var encounter := CombatEncounter.new()
	encounter.combat_scene = combat_scene
	encounter.victory_rewards = victory_rewards.duplicate()
	encounter.defeat_rewards = defeat_rewards.duplicate()
	encounter.flee_rewards = flee_rewards.duplicate()
	encounter.reward_context = context.duplicate()

	for row_index in enemy_ids.size():
		var enemy_id := enemy_ids[row_index]
		var enemy_data := catalog.get_enemy(enemy_id)
		if enemy_data == null:
			push_error("Error: Unknown dialogue combat enemy ID '%s'." % enemy_id)
			return

		var enemy_count := 1
		if row_index < enemy_counts.size():
			enemy_count = enemy_counts[row_index]
		if enemy_count < 1 or enemy_count > 3:
			push_error("Error: Dialogue combat enemy count for '%s' must be from 1 to 3." % enemy_id)
			return

		var row: Array[EnemyInstance] = []
		for slot_index in enemy_count:
			row.append(EnemyInstance.create(enemy_data, row_index, slot_index))
		encounter.enemy_rows.append(row)

	var scene_tree := Engine.get_main_loop() as SceneTree
	var main_scene := scene_tree.current_scene if scene_tree != null else null
	if main_scene == null or not main_scene.has_method("_on_encounter_requested"):
		push_error("Error: Main scene is not ready for dialogue combat.")
		return
	main_scene.call("_on_encounter_requested", encounter)
