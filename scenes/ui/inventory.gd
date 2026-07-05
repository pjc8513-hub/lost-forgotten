class_name InventoryMenu
extends Control

# options
@onready var next_button: Button = $MarginContainer/PanelContainer/VBoxContainer/MarginContainer2/HBoxContainer/options/MarginContainer/VBoxContainer/NextButton
@onready var previous_button: Button = $MarginContainer/PanelContainer/VBoxContainer/MarginContainer2/HBoxContainer/options/MarginContainer/VBoxContainer/PreviousButton
@onready var close_button: Button = $MarginContainer/PanelContainer/VBoxContainer/MarginContainer2/HBoxContainer/options/MarginContainer/VBoxContainer/CloseButton

# Character info and stats
@onready var strength_label: Label = $MarginContainer/PanelContainer/VBoxContainer/MarginContainer2/HBoxContainer/StatsPanel/MarginContainer/StatsContainer/StrengthLabel
@onready var endurance_label: Label = $MarginContainer/PanelContainer/VBoxContainer/MarginContainer2/HBoxContainer/StatsPanel/MarginContainer/StatsContainer/EnduranceLabel
@onready var wisdom_label: Label = $MarginContainer/PanelContainer/VBoxContainer/MarginContainer2/HBoxContainer/StatsPanel/MarginContainer/StatsContainer/WisdomLabel
@onready var dexterity_label: Label = $MarginContainer/PanelContainer/VBoxContainer/MarginContainer2/HBoxContainer/StatsPanel/MarginContainer/StatsContainer/DexterityLabel
@onready var piety_label: Label = $MarginContainer/PanelContainer/VBoxContainer/MarginContainer2/HBoxContainer/StatsPanel/MarginContainer/StatsContainer/PietyLabel
@onready var willpower_label: Label = $MarginContainer/PanelContainer/VBoxContainer/MarginContainer2/HBoxContainer/StatsPanel/MarginContainer/StatsContainer/Willpower
@onready var description_label: Label = $MarginContainer/PanelContainer/VBoxContainer/MarginContainer2/HBoxContainer/DescriptionContainer/MarginContainer/VBoxContainer/DescriptionLabel
@onready var character_name: Label = $MarginContainer/PanelContainer/VBoxContainer/PanelContainer/CharacterName


# Inventory slots
@onready var weapon_slot: Label = $MarginContainer/PanelContainer/VBoxContainer/MarginContainer/HBoxContainer/Equipped/VBoxContainer/HBoxContainer/PanelContainer2/VBoxContainer/WeaponSlot
@onready var shield_slot: Label = $MarginContainer/PanelContainer/VBoxContainer/MarginContainer/HBoxContainer/Equipped/VBoxContainer/HBoxContainer/PanelContainer2/VBoxContainer/ShieldSlot
@onready var helmet_slot: Label = $MarginContainer/PanelContainer/VBoxContainer/MarginContainer/HBoxContainer/Equipped/VBoxContainer/HBoxContainer/PanelContainer2/VBoxContainer/HelmetSlot
@onready var armor_slot: Label = $MarginContainer/PanelContainer/VBoxContainer/MarginContainer/HBoxContainer/Equipped/VBoxContainer/HBoxContainer/PanelContainer2/VBoxContainer/ArmorSlot
@onready var gloves_slot: Label = $MarginContainer/PanelContainer/VBoxContainer/MarginContainer/HBoxContainer/Equipped/VBoxContainer/HBoxContainer/PanelContainer2/VBoxContainer/GlovesSlot
@onready var boots_slot: Label = $MarginContainer/PanelContainer/VBoxContainer/MarginContainer/HBoxContainer/Equipped/VBoxContainer/HBoxContainer/PanelContainer2/VBoxContainer/BootsSlot
@onready var ring_slot: Label = $MarginContainer/PanelContainer/VBoxContainer/MarginContainer/HBoxContainer/Equipped/VBoxContainer/HBoxContainer/PanelContainer2/VBoxContainer/RingSlot
@onready var amulet_slot: Label = $MarginContainer/PanelContainer/VBoxContainer/MarginContainer/HBoxContainer/Equipped/VBoxContainer/HBoxContainer/PanelContainer2/VBoxContainer/AmuletSlot
@onready var item_list: InventoryItemList = $MarginContainer/PanelContainer/VBoxContainer/MarginContainer/HBoxContainer/Bag/ScrollContainer/VBoxContainer/ItemList
@onready var item_popup: PopupMenu = $MarginContainer/PanelContainer/VBoxContainer/MarginContainer/HBoxContainer/Bag/ScrollContainer/VBoxContainer/PopupMenu
@onready var trade_popup: PopupMenu = $MarginContainer/PanelContainer/VBoxContainer/MarginContainer/HBoxContainer/Bag/ScrollContainer/VBoxContainer/PopupMenu/TradeMenu

enum ItemAction { EQUIP, UNEQUIP, USE, DROP }

var _displayed_member: PartyMember
var _context_item: ItemInstance
var _trade_recipients: Array[PartyMember] = []

func _ready() -> void:
	next_button.pressed.connect(_show_next_character)
	previous_button.pressed.connect(_show_previous_character)
	close_button.pressed.connect(close)
	PartyManager.selected_party_member_changed.connect(_on_selected_party_member_changed)
	item_list.context_menu_requested.connect(_show_item_menu)
	item_list.equip_requested.connect(_equip_item)
	item_popup.id_pressed.connect(_on_item_action_pressed)
	trade_popup.id_pressed.connect(_on_trade_recipient_pressed)
	hide()

func open() -> void:
	if PartyManager.party.is_empty():
		return
	show()
	_refresh(PartyManager.selected_party_member)
	close_button.grab_focus()

func close() -> void:
	item_popup.hide()
	trade_popup.hide()
	item_list._hide_item_tooltip()
	hide()

func _input(event: InputEvent) -> void:
	if not visible or not event is InputEventKey:
		return
	if event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()
		return
	for action in [&"ui_up", &"ui_down", &"ui_left", &"ui_right", &"interact"]:
		if event.is_action(action):
			get_viewport().set_input_as_handled()
			return

func _show_next_character() -> void:
	_select_relative_character(1)

func _show_previous_character() -> void:
	_select_relative_character(-1)

func _select_relative_character(offset: int) -> void:
	if PartyManager.party.is_empty():
		return
	var next_index := wrapi(
		PartyManager.selected_party_member_index + offset,
		0,
		PartyManager.party.size()
	)
	PartyManager.select_party_member(next_index)

func _on_selected_party_member_changed(_index: int, member: PartyMember) -> void:
	if visible:
		_refresh(member)

func _refresh(member: PartyMember) -> void:
	if _displayed_member != null and _displayed_member.stats_changed.is_connected(_refresh_displayed_member):
		_displayed_member.stats_changed.disconnect(_refresh_displayed_member)
	if _displayed_member != null and _displayed_member.inventory_changed.is_connected(_refresh_displayed_inventory):
		_displayed_member.inventory_changed.disconnect(_refresh_displayed_inventory)
	_displayed_member = member
	if member == null:
		return
	member.stats_changed.connect(_refresh_displayed_member)
	member.inventory_changed.connect(_refresh_displayed_inventory)

	character_name.text = member.member_name
	var class_name_number := member.class_data.class_id
	var class_name_text := member.class_data.get_display_name_for(class_name_number) if member.class_data != null else "Adventurer"
	description_label.text = "Level %d %s" % [member.level, class_name_text]
	strength_label.text = "Strength: %d" % StatCalculator.get_strength(member)
	endurance_label.text = "Endurance: %d" % StatCalculator.get_endurance(member)
	wisdom_label.text = "Wisdom: %d" % StatCalculator.get_wisdom(member)
	dexterity_label.text = "Dexterity: %d" % StatCalculator.get_dexterity(member)
	piety_label.text = "Piety: %d" % StatCalculator.get_piety(member)
	willpower_label.text = "Willpower: %d" % StatCalculator.get_willpower(member)
	_refresh_displayed_inventory()

	var multiple_members := PartyManager.party.size() > 1
	next_button.disabled = not multiple_members
	previous_button.disabled = not multiple_members

func _refresh_displayed_member() -> void:
	_refresh(_displayed_member)

func _refresh_displayed_inventory() -> void:
	if _displayed_member == null:
		item_list.set_inventory([])
		return
	item_list.set_inventory(_displayed_member.inventory)
	_refresh_equipped_slots()

func _refresh_equipped_slots() -> void:
	var labels := {
		ItemData.Equip_Slot.WEAPON: weapon_slot,
		ItemData.Equip_Slot.ARMOR: armor_slot,
		ItemData.Equip_Slot.HELMET: helmet_slot,
		ItemData.Equip_Slot.BOOTS: boots_slot,
		ItemData.Equip_Slot.GLOVES: gloves_slot,
		ItemData.Equip_Slot.RING: ring_slot,
		ItemData.Equip_Slot.AMULET: amulet_slot,
	}
	shield_slot.text = "<Empty>"
	for label in labels.values():
		label.text = "<Empty>"
	if _displayed_member == null:
		return
	for item in _displayed_member.inventory:
		if item.is_equipped and item.item_data != null and labels.has(item.item_data.equip_slot):
			(labels[item.item_data.equip_slot] as Label).text = item.get_display_name()

func _show_item_menu(item: ItemInstance, screen_position: Vector2i) -> void:
	_context_item = item
	item_popup.clear()
	if item.is_equipped:
		item_popup.add_item("Unequip", ItemAction.UNEQUIP)
	elif item.item_data.item_type == ItemData.ItemType.EQUIPMENT:
		item_popup.add_item("Equip", ItemAction.EQUIP)
	if item.item_data is ConsumableData:
		item_popup.add_item("Use", ItemAction.USE)
	item_popup.add_item("Drop", ItemAction.DROP)
	item_popup.set_item_disabled(item_popup.get_item_index(ItemAction.DROP), item.item_data.item_type == ItemData.ItemType.QUEST)
	_populate_trade_menu()
	if not _trade_recipients.is_empty():
		item_popup.add_submenu_item("Trade", trade_popup.name)
	item_popup.position = screen_position
	item_popup.popup()

func _populate_trade_menu() -> void:
	trade_popup.clear()
	_trade_recipients.clear()
	for member in PartyManager.party:
		if member == _displayed_member:
			continue
		var id := _trade_recipients.size()
		_trade_recipients.append(member)
		trade_popup.add_item(member.member_name, id)

func _on_item_action_pressed(action_id: int) -> void:
	if _displayed_member == null or _context_item == null:
		return
	match action_id:
		ItemAction.EQUIP:
			_equip_item(_context_item)
		ItemAction.UNEQUIP:
			_displayed_member.unequip_inventory_item(_context_item)
		ItemAction.USE:
			if not _displayed_member.use_inventory_item(_context_item):
				MapManager.request_alert("That item cannot be used right now")
		ItemAction.DROP:
			if not _displayed_member.drop_inventory_item(_context_item):
				MapManager.request_alert("Quest items cannot be dropped")

func _equip_item(item: ItemInstance) -> void:
	if _displayed_member != null and not _displayed_member.equip_inventory_item(item):
		MapManager.request_alert("This character cannot equip that item")

func _on_trade_recipient_pressed(recipient_id: int) -> void:
	if _displayed_member == null or _context_item == null:
		return
	if recipient_id >= 0 and recipient_id < _trade_recipients.size():
		_displayed_member.trade_inventory_item(_context_item, _trade_recipients[recipient_id])
