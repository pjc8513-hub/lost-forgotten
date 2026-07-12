extends Control
const TEMPLE_MEMBER_COST_CAP := 2000

@onready var options_container: VBoxContainer = $VBoxContainer/HBoxContainer/OptionsPanel/MarginContainer/OptionsContainer
@onready var npc_list: ItemList = $VBoxContainer/HBoxContainer/PanelContainer/MarginContainer/NPCListContainer/NPCList
@onready var dialogue_label: RichTextLabel = $VBoxContainer/HBoxContainer/PanelContainer2/ScrollContainer/DialogueLabel

var _npcs: Array[NPCComponent] = []
var _source_tile: NPC_Tile_Component
var _selected_npc: NPCComponent
var _current_node: DialogueNode
var _is_temple_shop_open := false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	hide()
	npc_list.item_selected.connect(_on_npc_selected)
	PartyManager.selected_party_member_changed.connect(_on_party_member_selected)

func open(npcs: Array[NPCComponent], source_tile: NPC_Tile_Component = null) -> void:
	_npcs = npcs
	_source_tile = source_tile
	_selected_npc = null
	_current_node = null
	_is_temple_shop_open = false
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
	_is_temple_shop_open = false
	npc_list.clear()
	_clear_options()
	dialogue_label.clear()

func _on_party_member_selected(_index: int, _member: PartyMember) -> void:
	if visible and _is_temple_shop_open:
		_open_temple_shop()

func _on_npc_selected(index: int) -> void:
	var selected_npc := _npcs[index] if index >= 0 and index < _npcs.size() else null
	var refreshed_index := _refresh_npc_list(selected_npc, false)
	_select_npc(refreshed_index)

func _select_npc(index: int) -> void:
	if index < 0 or index >= _npcs.size():
		return
	_selected_npc = _npcs[index]
	_current_node = null
	_is_temple_shop_open = false
	dialogue_label.text = _selected_npc.npc_name
	_show_npc_actions()

func _show_npc_actions() -> void:
	_is_temple_shop_open = false
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
		_add_option(_selected_npc.destination_label, _trigger_npc_travel)

	_add_option("Leave", close)

func _start_dialogue() -> void:
	if _selected_npc == null:
		return
	_show_dialogue_node(_selected_npc.get_current_dialogue_node())

func _show_dialogue_node(node: DialogueNode) -> void:
	_is_temple_shop_open = false
	_current_node = node
	_clear_options()

	if node == null:
		dialogue_label.text = ""
		_add_option("Back", _show_npc_actions)
		return

	dialogue_label.text = node.text
	var will_teleport := _rewards_will_teleport(node.immediate_rewards)
	if will_teleport:
		close()
	for reward in node.immediate_rewards:
		if reward != null:
			reward.give_reward()
	if will_teleport:
		return
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
	var will_teleport := _rewards_will_teleport(edge.choice_rewards)
	if will_teleport:
		close()
	for reward in edge.choice_rewards:
		if reward != null:
			reward.give_reward()
	if will_teleport:
		return
	_refresh_npc_list(_selected_npc, false)
	_show_dialogue_node(edge.next_node)

func _accept_quest(quest: Quest) -> void:
	QuestManager.quest_db[quest.quest_id] = quest
	QuestManager.set_quest_stage(quest.quest_id, 1)
	dialogue_label.text = quest.description
	_refresh_npc_list(_selected_npc, false)
	_show_npc_actions()

func _open_shop() -> void:
	if _selected_npc != null and _selected_npc.shop_type == NPCComponent.Shop_Type.TEMPLE:
		_open_temple_shop()
		return

	var shop_label := _selected_npc.shop_name if _selected_npc != null else "Shop"
	if shop_label.is_empty():
		shop_label = "Shop"
	dialogue_label.text = "%s is not implemented yet." % shop_label
	_show_npc_actions()

func _open_temple_shop() -> void:
	_is_temple_shop_open = true
	_clear_options()
	var member := PartyManager.selected_party_member
	var member_cost := _get_member_cure_cost(member)
	var party_cost := _get_party_cure_cost()

	dialogue_label.text = _get_temple_status_text(member, member_cost, party_cost)
	var member_button := _add_option("Cure Member (%d gold)" % member_cost, _cure_selected_member)
	member_button.disabled = member == null or not _member_has_curable_effects(member) or PartyManager.gold < member_cost

	var party_button := _add_option("Cure Party (%d gold)" % party_cost, _cure_party)
	party_button.disabled = not _party_has_curable_effects() or PartyManager.gold < party_cost

	_add_option("Return", _start_dialogue)
	_add_option("Leave", close)

func _trigger_npc_travel() -> void:
	var npc := _selected_npc
	if npc == null:
		return
	close()
	npc.trigger_travel()

func _cure_selected_member() -> void:
	var member := PartyManager.selected_party_member
	var cost := _get_member_cure_cost(member)
	if member == null or not _member_has_curable_effects(member):
		_open_temple_shop()
		return
	if not PartyManager.spend_gold(cost):
		dialogue_label.text = "You do not have enough gold."
		_open_temple_shop()
		return
	_cure_member(member)
	_open_temple_shop()

func _cure_party() -> void:
	var cost := _get_party_cure_cost()
	if not _party_has_curable_effects():
		_open_temple_shop()
		return
	if not PartyManager.spend_gold(cost):
		dialogue_label.text = "You do not have enough gold."
		_open_temple_shop()
		return
	for member in PartyManager.party:
		_cure_member(member)
	_open_temple_shop()

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

func _get_temple_status_text(member: PartyMember, member_cost: int, party_cost: int) -> String:
	var shop_label := _selected_npc.shop_name if _selected_npc != null else "Temple"
	if shop_label.is_empty():
		shop_label = "Temple"
	var member_name := "No member selected"
	if member != null:
		member_name = member.member_name
	return "%s\nSelected: %s\nGold: %d\nMember cure: %d gold\nParty cure: %d gold" % [
		shop_label,
		member_name,
		PartyManager.gold,
		member_cost,
		party_cost,
	]

func _get_member_cure_cost(member: PartyMember) -> int:
	if member == null:
		return 0
	var base_cost := 0
	for effect_id in member.active_status_effects.keys():
		var id := int(effect_id)
		if StatusEffects.is_negative(id):
			base_cost += StatusEffects.cost_to_remove(id)
	if base_cost <= 0:
		return 0
	var level := maxi(member.level, 1)
	return mini(base_cost * level * level, TEMPLE_MEMBER_COST_CAP)

func _get_party_cure_cost() -> int:
	var total := 0
	for member in PartyManager.party:
		total += _get_member_cure_cost(member)
	return total

func _member_has_curable_effects(member: PartyMember) -> bool:
	if member == null:
		return false
	for effect_id in member.active_status_effects.keys():
		if StatusEffects.is_negative(int(effect_id)):
			return true
	return false

func _party_has_curable_effects() -> bool:
	for member in PartyManager.party:
		if _member_has_curable_effects(member):
			return true
	return false

func _cure_member(member: PartyMember) -> void:
	if member == null:
		return
	var was_dead := member.active_status_effects.has(StatusEffects.Effect.DEAD)
	var effects_to_remove: Array[int] = []
	for effect_id in member.active_status_effects.keys():
		var id := int(effect_id)
		if StatusEffects.is_negative(id):
			effects_to_remove.append(id)
	for effect_id in effects_to_remove:
		member.active_status_effects.erase(effect_id)
	if was_dead:
		member.current_hp = 1
	StatCalculator.recalculate(member)

func _rewards_will_teleport(rewards: Array[DialogueReward]) -> bool:
	for reward in rewards:
		if reward != null and reward.type == DialogueReward.RewardType.TELEPORT:
			return true
	return false

func _clear_options() -> void:
	for child in options_container.get_children():
		child.queue_free()
