class_name CharacterMenu
extends Control

@onready var character_name: Label = $MarginContainer/PanelContainer/MarginContainer/VBoxContainer/CharacterName

# Description container
@onready var description_label: Label = $MarginContainer/PanelContainer/MarginContainer/VBoxContainer/MarginContainer/HBoxContainer/DescriptionContainer/MarginContainer/VBoxContainer/DescriptionLabel
@onready var row_option: OptionButton = $MarginContainer/PanelContainer/MarginContainer/VBoxContainer/MarginContainer/HBoxContainer/DescriptionContainer/MarginContainer/VBoxContainer/RowOption
@onready var status_container: VBoxContainer = $MarginContainer/PanelContainer/MarginContainer/VBoxContainer/MarginContainer/HBoxContainer/DescriptionContainer/MarginContainer/VBoxContainer/ScrollContainer/StatusContainer
@onready var race_label: Label = $MarginContainer/PanelContainer/MarginContainer/VBoxContainer/MarginContainer/HBoxContainer/DescriptionContainer/MarginContainer/VBoxContainer/RaceLabel

# Stats container
@onready var strength_label: Label = $MarginContainer/PanelContainer/MarginContainer/VBoxContainer/MarginContainer/HBoxContainer/StatsPanel/MarginContainer/StatsContainer/StrengthLabel
@onready var endurance_label: Label = $MarginContainer/PanelContainer/MarginContainer/VBoxContainer/MarginContainer/HBoxContainer/StatsPanel/MarginContainer/StatsContainer/EnduranceLabel
@onready var wisdom_label: Label = $MarginContainer/PanelContainer/MarginContainer/VBoxContainer/MarginContainer/HBoxContainer/StatsPanel/MarginContainer/StatsContainer/WisdomLabel
@onready var dexterity_label: Label = $MarginContainer/PanelContainer/MarginContainer/VBoxContainer/MarginContainer/HBoxContainer/StatsPanel/MarginContainer/StatsContainer/DexterityLabel
@onready var piety_label: Label = $MarginContainer/PanelContainer/MarginContainer/VBoxContainer/MarginContainer/HBoxContainer/StatsPanel/MarginContainer/StatsContainer/PietyLabel
@onready var willpower_label: Label = $MarginContainer/PanelContainer/MarginContainer/VBoxContainer/MarginContainer/HBoxContainer/StatsPanel/MarginContainer/StatsContainer/WillpowerLabel

# More Stats container
@onready var ac_label: Label = $MarginContainer/PanelContainer/MarginContainer/VBoxContainer/MarginContainer/HBoxContainer/MoreStatsContainer/MarginContainer/VBoxContainer/ACLabel
@onready var accuracy_label: Label = $MarginContainer/PanelContainer/MarginContainer/VBoxContainer/MarginContainer/HBoxContainer/MoreStatsContainer/MarginContainer/VBoxContainer/AccuracyLabel
@onready var initiative_label: Label = $MarginContainer/PanelContainer/MarginContainer/VBoxContainer/MarginContainer/HBoxContainer/MoreStatsContainer/MarginContainer/VBoxContainer/InitiativeLabel
@onready var damage_label: Label = $MarginContainer/PanelContainer/MarginContainer/VBoxContainer/MarginContainer/HBoxContainer/MoreStatsContainer/MarginContainer/VBoxContainer/DamageLabel

# Resist container
@onready var resistance_container: VBoxContainer = $MarginContainer/PanelContainer/MarginContainer/VBoxContainer/MarginContainer/HBoxContainer/ResistContainer/VBoxContainer/ScrollContainer/ResistanceList

# Options
@onready var next_button: Button = $MarginContainer/PanelContainer/MarginContainer/VBoxContainer/VBoxContainer/PanelContainer/MarginContainer/VBoxContainer/NextButton
@onready var previous_button: Button = $MarginContainer/PanelContainer/MarginContainer/VBoxContainer/VBoxContainer/PanelContainer/MarginContainer/VBoxContainer/PreviousButton
@onready var close_button: Button = $MarginContainer/PanelContainer/MarginContainer/VBoxContainer/VBoxContainer/PanelContainer/MarginContainer/VBoxContainer/CloseButton

var _displayed_member: PartyMember

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	PartyManager.selected_party_member_changed.connect(_on_selected_party_member_changed)
	next_button.pressed.connect(_show_next_character)
	previous_button.pressed.connect(_show_previous_character)
	row_option.item_selected.connect(_on_row_selected)
	close_button.pressed.connect(close)
	hide()

func open() -> void:
	if PartyManager.party.is_empty():
		return
	show()
	_refresh(PartyManager.selected_party_member)
	close_button.grab_focus()

func close() -> void:
	hide()
	
func _refresh(member: PartyMember) -> void:
	if _displayed_member != null and _displayed_member.stats_changed.is_connected(_refresh_displayed_member):
		_displayed_member.stats_changed.disconnect(_refresh_displayed_member)
	_displayed_member = member
	if member == null:
		return
	member.stats_changed.connect(_refresh_displayed_member)

	character_name.text = member.member_name
	var class_name_text := "Adventurer"
	if member.class_data != null:
		class_name_text = member.class_data.get_display_name_for(member.class_data.class_id)
	description_label.text = "Level %d %s" % [member.level, class_name_text]
	race_label.text = "Race: %s" % member.get_race_display_name()
	row_option.select(int(member.row))
	strength_label.text = "Strength: %d" % StatCalculator.get_strength(member)
	endurance_label.text = "Endurance: %d" % StatCalculator.get_endurance(member)
	wisdom_label.text = "Wisdom: %d" % StatCalculator.get_wisdom(member)
	dexterity_label.text = "Dexterity: %d" % StatCalculator.get_dexterity(member)
	piety_label.text = "Piety: %d" % StatCalculator.get_piety(member)
	willpower_label.text = "Willpower: %d" % StatCalculator.get_willpower(member)
	_refresh_derived_stats(member)
	_refresh_statuses(member)
	_refresh_resistances(member)

	var multiple_members := PartyManager.party.size() > 1
	next_button.disabled = not multiple_members
	previous_button.disabled = not multiple_members

func _refresh_displayed_member() -> void:
	_refresh(_displayed_member)

func _refresh_derived_stats(member: PartyMember) -> void:
	var damage := StatCalculator.get_damage_profile(member)
	var dice_rolls := int(damage.get("dice_rolls", 0))
	var dice_sides := int(damage.get("dice_sides", 0))
	var damage_bonus := int(damage.get("bonus", 0))
	if dice_rolls > 0 and dice_sides > 0:
		damage_label.text = "%dd%d %+d" % [dice_rolls, dice_sides, damage_bonus]
	else:
		damage_label.text = "Unarmed %+d" % damage_bonus
	ac_label.text = "AC: %d" % StatCalculator.get_armor_class(member)
	accuracy_label.text = "Accuracy: %d" % StatCalculator.get_accuracy(member)
	initiative_label.text = "Initiative: %d" % StatCalculator.get_initiative(member)

func _refresh_statuses(member: PartyMember) -> void:
	for child in status_container.get_children():
		child.free()
	if member.active_status_effects.is_empty() and member.active_combat_buffs.is_empty():
		_add_status_label("None")
		return
	for effect_id in member.active_status_effects:
		var definition := StatusEffects.get_definition(int(effect_id))
		var text := StatusEffects.get_label(int(effect_id))
		var entry: Dictionary = member.active_status_effects[effect_id]
		var rounds := int(entry.get("remaining_rounds", -1))
		if rounds >= 0:
			text += " (%d rounds)" % rounds
		_add_status_label(text, String(definition.get("description", "")))
	for buff_name in member.active_combat_buffs:
		var entry = member.active_combat_buffs[buff_name]
		var value := int(entry.get("value", 0)) if entry is Dictionary else int(entry)
		_add_status_label("%s: %+d" % [String(buff_name).capitalize(), value])

func _add_status_label(text: String, tooltip: String = "") -> void:
	var label := Label.new()
	label.text = text
	label.tooltip_text = tooltip
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_container.add_child(label)
	
func _refresh_resistances(member: PartyMember) -> void:
	for child in resistance_container.get_children():
		child.queue_free()
	for element in [&"fire", &"water", &"earth", &"electric", &"light", &"dark"]:
		var label := Label.new()
		label.text = "%s: %d" % [String(element).capitalize(), StatCalculator.get_resistance(member, element)]
		resistance_container.add_child(label)
func _on_selected_party_member_changed(_index: int, member: PartyMember) -> void:
	if visible:
		_refresh(member)
		
func _show_next_character() -> void:
	_select_relative_character(1)

func _show_previous_character() -> void:
	_select_relative_character(-1)

func _on_row_selected(index: int) -> void:
	if _displayed_member == null or index < 0 or index >= PartyMember.CombatRow.size():
		return
	_displayed_member.row = index as PartyMember.CombatRow


func _select_relative_character(offset: int) -> void:
	if PartyManager.party.is_empty():
		return
	var next_index := wrapi(
		PartyManager.selected_party_member_index + offset,
		0,
		PartyManager.party.size()
	)
	PartyManager.select_party_member(next_index)
	
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
