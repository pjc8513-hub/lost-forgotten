# scratch/test_quest_dialogue.gd
extends SceneTree

const NPCComponent = preload("res://scripts/components/NPCComponent.gd")
const Quest = preload("res://resources/QuestData.gd")
const DialogueCondition = preload("res://resources/DialogueCondition.gd")
const DialogueReward = preload("res://scripts/components/DialogueReward.gd")
const DialogueNode = preload("res://scripts/components/DialogueNode.gd")

func _init() -> void:
	print("--- STARTING QUEST & DIALOGUE INTEGRATION TESTS ---")
	
	# Wait one frame to ensure autoloads are fully ready in the SceneTree
	call_deferred("run_tests")

func run_tests() -> void:
	test_quest_manager()
	test_dialogue_conditions()
	test_dialogue_rewards()
	test_npc_component()
	
	print("--- ALL TESTS COMPLETED SUCCESSFULLY ---")
	quit()

func test_quest_manager() -> void:
	print("\nTesting QuestManager...")
	
	# Create a mock Quest resource
	var quest = Quest.new()
	quest.quest_id = "test_quest_01"
	quest.quest_name = "Test Quest"
	quest.is_main_quest = true
	quest.stage_descriptions = {
		0: "Not Started",
		1: "Step One",
		2: "Step Two",
		3: "Completed"
	}
	
	# Register in QuestManager manually for this headless test
	QuestManager.quest_db[quest.quest_id] = quest
	
	# Connect signals
	var started_fired = false
	var stage_changed_fired = false
	var completed_fired = false
	
	QuestManager.quest_started.connect(func(id): if id == quest.quest_id: started_fired = true)
	QuestManager.quest_stage_changed.connect(func(id, stage): if id == quest.quest_id: stage_changed_fired = true)
	QuestManager.quest_completed.connect(func(id): if id == quest.quest_id: completed_fired = true)
	
	# Check initial state
	assert(QuestManager.get_quest_stage(quest.quest_id) == 0, "Quest stage should start at 0")
	assert(not QuestManager.is_quest_active(quest.quest_id), "Quest should not be active yet")
	assert(not QuestManager.is_quest_completed(quest.quest_id), "Quest should not be completed")
	
	# Start quest
	QuestManager.set_quest_stage(quest.quest_id, 1)
	assert(QuestManager.get_quest_stage(quest.quest_id) == 1, "Quest stage should be 1")
	assert(QuestManager.is_quest_active(quest.quest_id), "Quest should be active")
	assert(started_fired, "quest_started signal should have fired")
	
	# Advance stage
	QuestManager.set_quest_stage(quest.quest_id, 2)
	assert(QuestManager.get_quest_stage(quest.quest_id) == 2, "Quest stage should be 2")
	assert(stage_changed_fired, "quest_stage_changed signal should have fired")
	
	# Complete quest
	QuestManager.set_quest_stage(quest.quest_id, 3)
	assert(QuestManager.is_quest_completed(quest.quest_id), "Quest should be completed")
	assert(completed_fired, "quest_completed signal should have fired")
	
	# Check save/load
	var save_data = QuestManager.get_save_data()
	assert(save_data.get("quest_stages", {}).get(quest.quest_id) == 3, "Save data should record quest stage")
	
	QuestManager.load_save_data({"quest_stages": {quest.quest_id: 1}})
	assert(QuestManager.get_quest_stage(quest.quest_id) == 1, "Load data should restore quest stage")
	
	print("QuestManager tests passed!")

func test_dialogue_conditions() -> void:
	print("\nTesting DialogueConditions...")
	
	# Reset state
	PartyManager.gold = 100
	QuestManager.quest_stages = {"test_quest_01": 2}
	
	# 1. Gold greater than
	var gold_cond = DialogueCondition.new()
	gold_cond.type = DialogueCondition.ConditionType.GOLD_GREATER_THAN
	gold_cond.target_value = 50
	assert(gold_cond.is_met(), "Gold condition should be met (100 >= 50)")
	
	gold_cond.target_value = 150
	assert(not gold_cond.is_met(), "Gold condition should not be met (100 < 150)")
	
	# 2. Quest stage equal
	var quest_eq_cond = DialogueCondition.new()
	quest_eq_cond.type = DialogueCondition.ConditionType.QUEST_STAGE_EQUAL
	quest_eq_cond.target_id = "test_quest_01"
	quest_eq_cond.target_value = 2
	assert(quest_eq_cond.is_met(), "Quest equal condition should be met")
	
	quest_eq_cond.target_value = 3
	assert(not quest_eq_cond.is_met(), "Quest equal condition should not be met")
	
	# 3. Quest stage greater than
	var quest_gt_cond = DialogueCondition.new()
	quest_gt_cond.type = DialogueCondition.ConditionType.QUEST_STAGE_GREATER
	quest_gt_cond.target_id = "test_quest_01"
	quest_gt_cond.target_value = 1
	assert(quest_gt_cond.is_met(), "Quest greater condition should be met")
	
	quest_gt_cond.target_value = 2
	assert(not quest_gt_cond.is_met(), "Quest greater condition should not be met")
	
	print("DialogueConditions tests passed!")

func test_dialogue_rewards() -> void:
	print("\nTesting DialogueRewards...")
	
	# 1. Add gold
	var add_gold = DialogueReward.new()
	add_gold.type = DialogueReward.RewardType.ADD_GOLD
	add_gold.value = 50
	var prev_gold = PartyManager.gold
	add_gold.give_reward()
	assert(PartyManager.gold == prev_gold + 50, "Add gold reward failed")
	
	# 2. Remove gold
	var rem_gold = DialogueReward.new()
	rem_gold.type = DialogueReward.RewardType.REMOVE_GOLD
	rem_gold.value = 30
	prev_gold = PartyManager.gold
	rem_gold.give_reward()
	assert(PartyManager.gold == prev_gold - 30, "Remove gold reward failed")
	
	# 3. Set Quest Stage
	var set_quest = DialogueReward.new()
	set_quest.type = DialogueReward.RewardType.SET_QUEST_STAGE
	set_quest.target_id = "test_quest_01"
	set_quest.value = 3
	set_quest.give_reward()
	assert(QuestManager.get_quest_stage("test_quest_01") == 3, "Set quest stage reward failed")
	
	# 4. Add Exp
	var add_exp = DialogueReward.new()
	add_exp.type = DialogueReward.RewardType.ADD_EXP
	add_exp.value = 100
	add_exp.give_reward()
	
	print("DialogueRewards tests passed!")

func test_npc_component() -> void:
	print("\nTesting NPCComponent...")
	
	var npc = NPCComponent.new()
	
	# 1. Visible check
	var cond = DialogueCondition.new()
	cond.type = DialogueCondition.ConditionType.GOLD_GREATER_THAN
	cond.target_value = 1000 # We have ~120 gold, so this fails
	
	npc.npc_active_conditions.append(cond)
	assert(not npc.is_npc_active(), "NPC should not be active due to failed condition")
	
	npc.npc_active_conditions.clear()
	assert(npc.is_npc_active(), "NPC should be active with no conditions")
	
	# 2. Dialogue Selection
	var node1 = DialogueNode.new()
	node1.text = "Hello node 1"
	var cond_node = DialogueCondition.new()
	cond_node.type = DialogueCondition.ConditionType.QUEST_STAGE_EQUAL
	cond_node.target_id = "test_quest_01"
	cond_node.target_value = 3 # Current is 3
	node1.conditions.append(cond_node)
	
	var default_node = DialogueNode.new()
	default_node.text = "Hello default"
	
	npc.dialogue_nodes.append(node1)
	npc.default_dialogue = default_node
	
	var chosen = npc.get_current_dialogue_node()
	assert(chosen == node1, "Should select node1 because its conditions are met")
	
	# Change quest stage so cond fails
	QuestManager.set_quest_stage("test_quest_01", 1)
	chosen = npc.get_current_dialogue_node()
	assert(chosen == default_node, "Should fallback to default because node1 conditions fail")
	
	print("NPCComponent tests passed!")
