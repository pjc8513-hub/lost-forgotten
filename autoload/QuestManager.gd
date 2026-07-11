# autoload/QuestManager.gd
extends Node

signal quest_started(quest_id: String)
signal quest_stage_changed(quest_id: String, stage: int)
signal quest_completed(quest_id: String)

# Stores the current stage of quests.
# key: quest_id (String), value: stage (int)
var quest_stages: Dictionary = {}

# A dictionary to hold all loaded Quest data resources.
# key: quest_id (String), value: Quest (resource)
var quest_db: Dictionary = {}

const QUEST_ROOT := "res://data/quests/"

func _ready() -> void:
	_load_quests()

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
		quest_started.emit(quest_id)
		MapManager.request_alert("Started Quest: %s" % get_quest_name(quest_id))
	
	quest_stage_changed.emit(quest_id, stage)
	
	if is_quest_completed(quest_id):
		quest_completed.emit(quest_id)
		MapManager.request_alert("Completed Quest: %s" % get_quest_name(quest_id))

# Checks if a quest is active (started and not completed)
func is_quest_active(quest_id: String) -> bool:
	var stage = get_quest_stage(quest_id)
	return stage > 0 and not is_quest_completed(quest_id)

# Checks if a quest is completed.
func is_quest_completed(quest_id: String) -> bool:
	var stage = get_quest_stage(quest_id)
	var quest = quest_db.get(quest_id)
	if quest == null:
		return false
	# Check the highest stage key in stage_descriptions.
	var max_stage = 0
	for key in quest.stage_descriptions.keys():
		if int(key) > max_stage:
			max_stage = int(key)
	return stage >= max_stage

func get_quest_name(quest_id: String) -> String:
	var quest = quest_db.get(quest_id)
	if quest != null:
		return quest.quest_name
	return quest_id

# Save and load compatibility
func get_save_data() -> Dictionary:
	return {
		"quest_stages": quest_stages
	}

func load_save_data(data: Dictionary) -> void:
	quest_stages.assign(data.get("quest_stages", {}))
