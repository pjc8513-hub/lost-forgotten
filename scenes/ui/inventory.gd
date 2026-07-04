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
@onready var description_label: Label = $MarginContainer/PanelContainer/VBoxContainer/MarginContainer2/HBoxContainer/PanelContainer/MarginContainer/VBoxContainer/DescriptionLabel
@onready var character_name: Label = $MarginContainer/PanelContainer/VBoxContainer/CharacterName


# Inventory slots
@onready var weapon_slot: Label = $MarginContainer/PanelContainer/VBoxContainer/MarginContainer/HBoxContainer/Equipped/VBoxContainer/HBoxContainer/PanelContainer2/VBoxContainer/WeaponSlot
@onready var shield_slot: Label = $MarginContainer/PanelContainer/VBoxContainer/MarginContainer/HBoxContainer/Equipped/VBoxContainer/HBoxContainer/PanelContainer2/VBoxContainer/ShieldSlot
@onready var helmet_slot: Label = $MarginContainer/PanelContainer/VBoxContainer/MarginContainer/HBoxContainer/Equipped/VBoxContainer/HBoxContainer/PanelContainer2/VBoxContainer/HelmetSlot
@onready var armor_slot: Label = $MarginContainer/PanelContainer/VBoxContainer/MarginContainer/HBoxContainer/Equipped/VBoxContainer/HBoxContainer/PanelContainer2/VBoxContainer/ArmorSlot
@onready var gloves_slot: Label = $MarginContainer/PanelContainer/VBoxContainer/MarginContainer/HBoxContainer/Equipped/VBoxContainer/HBoxContainer/PanelContainer2/VBoxContainer/GlovesSlot
@onready var boots_slot: Label = $MarginContainer/PanelContainer/VBoxContainer/MarginContainer/HBoxContainer/Equipped/VBoxContainer/HBoxContainer/PanelContainer2/VBoxContainer/BootsSlot
@onready var ring_slot: Label = $MarginContainer/PanelContainer/VBoxContainer/MarginContainer/HBoxContainer/Equipped/VBoxContainer/HBoxContainer/PanelContainer2/VBoxContainer/RingSlot
@onready var amulet_slot: Label = $MarginContainer/PanelContainer/VBoxContainer/MarginContainer/HBoxContainer/Equipped/VBoxContainer/HBoxContainer/PanelContainer2/VBoxContainer/AmuletSlot

var _displayed_member: PartyMember

func _ready() -> void:
	next_button.pressed.connect(_show_next_character)
	previous_button.pressed.connect(_show_previous_character)
	close_button.pressed.connect(close)
	PartyManager.selected_party_member_changed.connect(_on_selected_party_member_changed)
	hide()

func open() -> void:
	if PartyManager.party.is_empty():
		return
	show()
	_refresh(PartyManager.selected_party_member)
	close_button.grab_focus()

func close() -> void:
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
	_displayed_member = member
	if member == null:
		return
	member.stats_changed.connect(_refresh_displayed_member)

	character_name.text = member.member_name
	var class_name_text := member.class_data.display_name if member.class_data != null else "Adventurer"
	description_label.text = "Level %d %s" % [member.level, class_name_text]
	strength_label.text = "Strength: %d" % StatCalculator.get_strength(member)
	endurance_label.text = "Endurance: %d" % StatCalculator.get_endurance(member)
	wisdom_label.text = "Wisdom: %d" % StatCalculator.get_wisdom(member)
	dexterity_label.text = "Dexterity: %d" % StatCalculator.get_dexterity(member)
	piety_label.text = "Piety: %d" % StatCalculator.get_piety(member)
	willpower_label.text = "Willpower: %d" % StatCalculator.get_willpower(member)

	var multiple_members := PartyManager.party.size() > 1
	next_button.disabled = not multiple_members
	previous_button.disabled = not multiple_members

func _refresh_displayed_member() -> void:
	_refresh(_displayed_member)
