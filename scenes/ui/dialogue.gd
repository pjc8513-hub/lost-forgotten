extends Control
@onready var options_container: VBoxContainer = $VBoxContainer/HBoxContainer/OptionsPanel/MarginContainer/OptionsContainer
@onready var npc_list: ItemList = $VBoxContainer/HBoxContainer/PanelContainer/MarginContainer/NPCListContainer/NPCList
@onready var dialogue_label: RichTextLabel = $VBoxContainer/HBoxContainer/PanelContainer2/ScrollContainer/DialogueLabel

var _npcs: Array[NPCComponent] = []
var _source_tile: NPC_Tile_Component
var _selected_npc: NPCComponent
var _current_node: DialogueNode

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	hide()
	npc_list.item_selected.connect(_on_npc_selected)

func open(npcs: Array[NPCComponent], source_tile: NPC_Tile_Component = null) -> void:
	_npcs = npcs
	_source_tile = source_tile
	_selected_npc = null
	_current_node = null
	npc_list.clear()
	_clear_options()
	dialogue_label.clear()

	show()
	_refresh_npc_list(null, true)

func close() -> void:
	hide()
	_npcs.clear()
	_source_tile = null
	_selected_npc = null
	_current_node = null
	npc_list.clear()
	_clear_options()
	dialogue_label.clear()

func _on_npc_selected(index: int) -> void:
	var selected_npc := _npcs[index] if index >= 0 and index < _npcs.size() else null
	var refreshed_index := _refresh_npc_list(selected_npc, false)
	_select_npc(refreshed_index)

func _select_npc(index: int) -> void:
	if index < 0 or index >= _npcs.size():
		return
	_selected_npc = _npcs[index]
	_current_node = null
	dialogue_label.text = _selected_npc.npc_name
	_show_npc_actions()

func _show_npc_actions() -> void:
	_clear_options()
	if _selected_npc == null:
		return

	_add_option(_get_dialogue_action_label(_selected_npc), _start_dialogue)

	for quest in _selected_npc.quests_offered:
		if quest != null and QuestManager.get_quest_stage(quest.quest_id) == 0:
			var quest_ref := quest
			_add_option("Quest: %s" % quest.quest_name, func(): _accept_quest(quest_ref))

	if _selected_npc.is_shop_available():
		var label := _selected_npc.shop_name
		if label.is_empty():
			label = "Shop"
		_add_option(label, _open_shop)

	if _selected_npc.is_travel_available():
		_add_option(_selected_npc.destination_label, Callable(_selected_npc, "trigger_travel"))

	_add_option("Leave", close)

func _start_dialogue() -> void:
	if _selected_npc == null:
		return
	_show_dialogue_node(_selected_npc.get_current_dialogue_node())

func _show_dialogue_node(node: DialogueNode) -> void:
	_current_node = node
	_clear_options()

	if node == null:
		dialogue_label.text = ""
		_add_option("Back", _show_npc_actions)
		return

	dialogue_label.text = node.text
	for reward in node.immediate_rewards:
		if reward != null:
			reward.give_reward()
	_refresh_npc_list(_selected_npc, false)

	for edge in node.choices:
		if edge == null:
			continue
		var available := edge.is_choice_available()
		if not available and edge.hide_if_locked:
			continue
		var edge_ref := edge
		var button := _add_option(edge.choice_string, func(): _choose_dialogue_edge(edge_ref))
		button.disabled = not available

	_add_option("Back", _show_npc_actions)

func _choose_dialogue_edge(edge: DialogueEdge) -> void:
	for reward in edge.choice_rewards:
		if reward != null:
			reward.give_reward()
	_refresh_npc_list(_selected_npc, false)
	_show_dialogue_node(edge.next_node)

func _accept_quest(quest: Quest) -> void:
	QuestManager.quest_db[quest.quest_id] = quest
	QuestManager.set_quest_stage(quest.quest_id, 1)
	dialogue_label.text = quest.description
	_refresh_npc_list(_selected_npc, false)
	_show_npc_actions()

func _open_shop() -> void:
	var shop_label := _selected_npc.shop_name if _selected_npc != null else "Shop"
	if shop_label.is_empty():
		shop_label = "Shop"
	dialogue_label.text = "%s is not implemented yet." % shop_label
	_show_npc_actions()

func _add_option(label: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = label
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.pressed.connect(callback)
	options_container.add_child(button)
	return button

func _refresh_npc_list(preferred_npc: NPCComponent = null, update_selection_view: bool = true) -> int:
	if _source_tile != null:
		_npcs = _source_tile.get_active_npcs()

	var selection := -1
	npc_list.clear()
	for index in _npcs.size():
		var npc := _npcs[index]
		npc_list.add_item(npc.npc_name)
		if npc == preferred_npc:
			selection = index

	if selection == -1 and not _npcs.is_empty():
		selection = 0

	if selection != -1:
		npc_list.select(selection)
		if update_selection_view:
			_select_npc(selection)
	elif update_selection_view:
		_selected_npc = null
		_current_node = null
		dialogue_label.clear()
		_clear_options()
	return selection

func _get_dialogue_action_label(npc: NPCComponent) -> String:
	if npc == null or npc.dialogue_label.strip_edges().is_empty():
		return "Dialogue"
	return npc.dialogue_label

func _clear_options() -> void:
	for child in options_container.get_children():
		child.queue_free()
