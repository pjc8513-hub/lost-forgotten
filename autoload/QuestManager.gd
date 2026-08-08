# autoload/QuestManager.gd
extends Node

signal quest_started(quest_id: String)
signal quest_stage_changed(quest_id: String, stage: int)
signal quest_completed(quest_id: String)
signal travel_destinations_changed

# Stores the current stage of quests.
# key: quest_id (String), value: stage (int)
var quest_stages: Dictionary = {}

# A dictionary to hold all loaded Quest data resources.
# key: quest_id (String), value: Quest (resource)
var quest_db: Dictionary = {}

# key: destination map and spawn, value: Dictionary with display_name, map, and spawn_id
var travel_destinations: Dictionary = {}

var _is_turning_in_quest := false

const QUEST_ROOT := "res://data/quests/"

func _ready() -> void:
	_load_quests()
	PartyManager.active_party_changed.connect(_on_active_party_changed)
	_connect_party_inventory_signals()

# Scans the quests folder and loads Quest resources
func _load_quests() -> void:
	quest_db.clear()
	if not DirAccess.dir_exists_absolute(QUEST_ROOT):
		DirAccess.make_dir_recursive_absolute(QUEST_ROOT)
		return

	var dir = DirAccess.open(QUEST_ROOT)
	if dir == null:
		push_error("QuestManager: Failed to open directory at %s" % QUEST_ROOT)
		return

	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		var full_path = QUEST_ROOT.path_join(file_name)
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var res = ResourceLoader.load(full_path)
			if res is Quest:
				var q_id = res.quest_id
				if q_id.is_empty():
					q_id = file_name.get_basename()
				quest_db[q_id] = res
		file_name = dir.get_next()
	dir.list_dir_end()
	print("QuestManager: Loaded %d quests." % quest_db.size())

# Returns the current stage of a quest. If not started, returns 0.
func get_quest_stage(quest_id: String) -> int:
	return quest_stages.get(quest_id, 0)

# Sets the current stage of a quest.
func set_quest_stage(quest_id: String, stage: int) -> void:
	var prev_stage = get_quest_stage(quest_id)
	if prev_stage == stage:
		return
	
	quest_stages[quest_id] = stage
	
	if prev_stage == 0 and stage > 0:
		unlock_quest_travel_destination(quest_id)
		quest_started.emit(quest_id)
		MapManager.request_alert("Started Quest: %s" % get_quest_name(quest_id))
	
	quest_stage_changed.emit(quest_id, stage)
	MapManager.request_alert("Quest %s updated" % get_quest_name(quest_id))
	
	if is_quest_completed(quest_id):
		quest_completed.emit(quest_id)
		MapManager.request_alert(_get_quest_completed_alert(quest_id))
	elif stage > 0:
		_refresh_item_quest_stage(quest_id)

func advance_quest_stage(quest_id: String, amount: int = 1) -> void:
	if amount <= 0:
		push_error("Quest stage advance amount must be positive.")
		return
	set_quest_stage(quest_id, get_quest_stage(quest_id) + amount)

# Checks if a quest is active (started and not completed)
func is_quest_active(quest_id: String) -> bool:
	var stage = get_quest_stage(quest_id)
	return stage > 0 and not is_quest_completed(quest_id)

# Checks if a quest is completed.
func is_quest_completed(quest_id: String) -> bool:
	var stage = get_quest_stage(quest_id)
	var quest := quest_db.get(quest_id) as Quest
	if quest == null:
		return false
	return stage >= quest.get_completion_stage()

func has_required_items(quest: Quest) -> bool:
	if quest == null or quest.required_items.is_empty():
		return false
	var required_counts := _get_required_item_counts(quest)
	if required_counts.is_empty():
		return false
	for item_id in required_counts.keys():
		if DialogueCondition.get_party_item_count(item_id) < int(required_counts[item_id]):
			return false
	return true

func is_quest_ready_to_turn_in(quest_id: String) -> bool:
	var quest := quest_db.get(quest_id) as Quest
	if quest == null or not is_quest_active(quest_id):
		return false
	return get_quest_stage(quest_id) >= quest.get_turn_in_stage() and has_required_items(quest)

func turn_in_quest(quest_id: String, context: Dictionary = {}) -> bool:
	if not is_quest_ready_to_turn_in(quest_id):
		return false
	var quest := quest_db.get(quest_id) as Quest
	_is_turning_in_quest = true
	var removed := _remove_required_items(quest)
	_is_turning_in_quest = false
	if not removed:
		push_error("QuestManager: Failed to remove required items for quest %s." % quest_id)
		return false
	set_quest_stage(quest_id, quest.get_completion_stage())
	if quest.quest_rewards != null:
		quest.quest_rewards.give_reward(context)
	return true

func get_quest_name(quest_id: String) -> String:
	var quest = quest_db.get(quest_id)
	if quest != null:
		return quest.quest_name
	return quest_id

func _get_quest_completed_alert(quest_id: String) -> String:
	var alert := "Completed Quest: %s" % get_quest_name(quest_id)
	var quest := quest_db.get(quest_id) as Quest
	if quest == null or quest.quest_rewards == null:
		return alert

	var reward := quest.quest_rewards
	var reward_text := ""
	match reward.type:
		DialogueReward.RewardType.ADD_GOLD:
			reward_text = "%d gold" % reward.value
		DialogueReward.RewardType.ADD_ITEM:
			reward_text = reward.target_id
		DialogueReward.RewardType.ADD_EXP:
			reward_text = "%d XP" % reward.value

	if not reward_text.is_empty():
		alert += "\nReward: %s" % reward_text
	return alert

func unlock_quest_travel_destination(quest_id: String) -> bool:
	var quest := quest_db.get(quest_id) as Quest
	if quest == null:
		return false
	return unlock_travel_destination(
		quest.display_name,
		quest.destination_map,
		quest.destination_spawn_id
	)

func unlock_travel_destination(display_name: String, destination_map: String, destination_spawn_id: StringName) -> bool:
	if destination_map.is_empty():
		return false

	var key := _get_travel_destination_key(destination_map, destination_spawn_id)
	if travel_destinations.has(key):
		return false

	var resolved_display_name := display_name
	if resolved_display_name.is_empty():
		resolved_display_name = destination_map.get_file().get_basename().capitalize()

	travel_destinations[key] = {
		"display_name": resolved_display_name,
		"map": destination_map,
		"spawn_id": destination_spawn_id,
	}
	travel_destinations_changed.emit()
	return true

func get_travel_destinations() -> Array[Dictionary]:
	var destinations: Array[Dictionary] = []
	for destination in travel_destinations.values():
		destinations.append(destination.duplicate())
	destinations.sort_custom(_sort_travel_destinations)
	return destinations

func _sort_travel_destinations(a: Dictionary, b: Dictionary) -> bool:
	return str(a.get("display_name", "")).naturalnocasecmp_to(str(b.get("display_name", ""))) < 0

# Save and load compatibility
func get_save_data() -> Dictionary:
	return {
		"quest_stages": quest_stages,
		"travel_destinations": travel_destinations,
	}

func load_save_data(data: Dictionary) -> void:
	quest_stages.assign(data.get("quest_stages", {}))
	travel_destinations.assign(data.get("travel_destinations", {}))
	for quest_id in quest_stages.keys():
		if get_quest_stage(quest_id) > 0:
			unlock_quest_travel_destination(quest_id)
	travel_destinations_changed.emit()
	_connect_party_inventory_signals()
	_refresh_item_quest_stages()

func _get_travel_destination_key(destination_map: String, destination_spawn_id: StringName) -> String:
	return "%s:%s" % [destination_map, str(destination_spawn_id)]

func _on_active_party_changed() -> void:
	_connect_party_inventory_signals()
	_refresh_item_quest_stages()

func _connect_party_inventory_signals() -> void:
	for member in PartyManager.party:
		if member != null and not member.inventory_changed.is_connected(_on_party_inventory_changed):
			member.inventory_changed.connect(_on_party_inventory_changed)

func _on_party_inventory_changed() -> void:
	if not _is_turning_in_quest:
		_refresh_item_quest_stages()

func _refresh_item_quest_stages() -> void:
	for quest_id in quest_stages.keys():
		_refresh_item_quest_stage(str(quest_id))

func _refresh_item_quest_stage(quest_id: String) -> void:
	var quest := quest_db.get(quest_id) as Quest
	if quest == null or quest.required_items.is_empty() or not is_quest_active(quest_id):
		return
	var turn_in_stage := quest.get_turn_in_stage()
	if get_quest_stage(quest_id) < turn_in_stage and has_required_items(quest):
		set_quest_stage(quest_id, turn_in_stage)

func _get_required_item_counts(quest: Quest) -> Dictionary:
	var counts: Dictionary = {}
	for item in quest.required_items:
		if item == null or item.item_id.is_empty():
			continue
		counts[item.item_id] = int(counts.get(item.item_id, 0)) + 1
	return counts

func _remove_required_items(quest: Quest) -> bool:
	var remaining := _get_required_item_counts(quest)
	for member in PartyManager.party:
		var inventory_changed := false
		for item in member.inventory.duplicate():
			if item.item_data == null:
				continue
			var item_id: String = item.item_data.item_id
			if int(remaining.get(item_id, 0)) <= 0:
				continue
			member.inventory.erase(item)
			remaining[item_id] = int(remaining[item_id]) - 1
			inventory_changed = true
		if inventory_changed:
			member.inventory_changed.emit()
	for count in remaining.values():
		if int(count) > 0:
			return false
	return true
