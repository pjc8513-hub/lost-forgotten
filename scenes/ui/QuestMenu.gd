class_name QuestMenu
extends Control

@onready var tab_container: TabContainer = $PanelContainer/MarginContainer/HBoxContainer/TabContainer
@onready var in_progress_list: RichTextLabel = $PanelContainer/MarginContainer/HBoxContainer/TabContainer/InProgress/ScrollContainer/InProgressList
@onready var completed_list: RichTextLabel = $PanelContainer/MarginContainer/HBoxContainer/TabContainer/Completed/ScrollContainer/CompletedList
@onready var close_button: Button = $PanelContainer/MarginContainer/HBoxContainer/OptionsContainer/VBoxContainer/CloseButton


func _ready() -> void:
	hide()
	in_progress_list.bbcode_enabled = true
	completed_list.bbcode_enabled = true
	close_button.pressed.connect(close)
	QuestManager.quest_started.connect(_on_quest_changed)
	QuestManager.quest_stage_changed.connect(_on_quest_stage_changed)
	QuestManager.quest_completed.connect(_on_quest_changed)
	_refresh()


func open() -> void:
	_refresh()
	show()


func close() -> void:
	hide()


func _refresh() -> void:
	var in_progress_quests := _get_quests(false)
	var completed_quests := _get_quests(true)

	in_progress_list.text = _build_quest_list_text(
		in_progress_quests,
		"No quests are currently in progress."
	)
	completed_list.text = _build_quest_list_text(
		completed_quests,
		"No quests have been completed yet."
	)


func _get_quests(completed: bool) -> Array[Quest]:
	var quests: Array[Quest] = []
	for quest_id in QuestManager.quest_stages.keys():
		if QuestManager.get_quest_stage(quest_id) <= 0:
			continue
		var quest := QuestManager.quest_db.get(quest_id) as Quest
		if quest == null:
			continue
		if QuestManager.is_quest_completed(quest.quest_id) == completed:
			quests.append(quest)
	quests.sort_custom(_sort_quests)
	return quests


func _sort_quests(a: Quest, b: Quest) -> bool:
	if a.is_main_quest != b.is_main_quest:
		return a.is_main_quest
	return a.quest_name.naturalnocasecmp_to(b.quest_name) < 0


func _build_quest_list_text(quests: Array[Quest], empty_text: String) -> String:
	if quests.is_empty():
		return _bbcode_escape(empty_text)

	var entries: Array[String] = []
	for quest in quests:
		entries.append(_build_quest_entry(quest))
	return "\n\n".join(entries)


func _build_quest_entry(quest: Quest) -> String:
	var stage := QuestManager.get_quest_stage(quest.quest_id)
	var max_stage := _get_max_stage(quest)
	var lines: Array[String] = []
	var quest_name := quest.quest_name if not quest.quest_name.is_empty() else quest.quest_id

	var quest_type := "Main Quest" if quest.is_main_quest else "Side Quest"
	lines.append("[b]%s[/b] [i]%s[/i]" % [
		_bbcode_escape(quest_name),
		_bbcode_escape(quest_type),
	])

	if not quest.description.is_empty():
		lines.append(_bbcode_escape(quest.description))

	lines.append("[b]Progress:[/b] %s" % _bbcode_escape(_get_stage_description(quest, stage)))

	if max_stage > 0:
		lines.append("[b]Stage:[/b] %d/%d" % [min(stage, max_stage), max_stage])

	if not quest.quest_giver.is_empty():
		lines.append("[b]Quest Giver:[/b] %s" % _bbcode_escape(quest.quest_giver))

	if not quest.return_location.is_empty():
		lines.append("[b]Return To:[/b] %s" % _bbcode_escape(quest.return_location))

	if quest.suggested_level > 0:
		lines.append("[b]Suggested Level:[/b] %d" % quest.suggested_level)

	var reward_text := _get_reward_text(quest)
	if not reward_text.is_empty():
		lines.append("[b]Reward:[/b] %s" % _bbcode_escape(reward_text))

	return "\n".join(lines)


func _get_stage_description(quest: Quest, stage: int) -> String:
	if quest.stage_descriptions.has(stage):
		return str(quest.stage_descriptions[stage])

	var best_stage := -1
	var best_key
	for key in quest.stage_descriptions.keys():
		var key_stage := int(key)
		if key_stage <= stage and key_stage > best_stage:
			best_stage = key_stage
			best_key = key

	if best_stage >= 0:
		return str(quest.stage_descriptions[best_key])
	return "Stage %d" % stage


func _get_max_stage(quest: Quest) -> int:
	var max_stage := 0
	for key in quest.stage_descriptions.keys():
		max_stage = max(max_stage, int(key))
	return max_stage


func _get_reward_text(quest: Quest) -> String:
	var reward := quest.quest_rewards
	if reward == null:
		return ""

	match reward.type:
		DialogueReward.RewardType.ADD_GOLD:
			return "%d gold" % reward.value
		DialogueReward.RewardType.ADD_EXP:
			return "%d experience" % reward.value
		DialogueReward.RewardType.ADD_ITEM:
			return reward.target_id
		_:
			return ""


func _bbcode_escape(value: String) -> String:
	return value.replace("[", "[lb]").replace("]", "[rb]")


func _on_quest_changed(_quest_id: String) -> void:
	if visible:
		_refresh()


func _on_quest_stage_changed(_quest_id: String, _stage: int) -> void:
	if visible:
		_refresh()
