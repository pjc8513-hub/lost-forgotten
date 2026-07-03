extends Control

const RACES: Array[RaceData] = [
	preload("res://data/races/human.tres"),
	preload("res://data/races/elf.tres"),
	preload("res://data/races/dwarf.tres"),
	preload("res://data/races/gnome.tres"),
]
const RACE_NAMES: Array[String] = ["Human", "Elf", "Dwarf", "Gnome"]
const CLASSES: Array[ClassData] = [
	preload("res://data/classes/knight.tres"),
	preload("res://data/classes/barbarian.tres"),
	preload("res://data/classes/monk.tres"),
	preload("res://data/classes/cleric.tres"),
	preload("res://data/classes/rogue.tres"),
	preload("res://data/classes/sorcerer.tres"),
	preload("res://data/classes/druid.tres"),
]
const CLASS_NAMES: Array[String] = ["Knight", "Barbarian", "Monk", "Cleric", "Rogue", "Sorcerer", "Druid"]

@onready var portrait: TextureRect = $MarginContainer/PanelContainer/VBoxContainer/MarginContainer/HBoxContainer/PortraitContainer/Portrait
@onready var name_edit: LineEdit = $MarginContainer/PanelContainer/VBoxContainer/MarginContainer/HBoxContainer/PanelContainer2/VBoxContainer/NameEdit
@onready var race_select: OptionButton = $MarginContainer/PanelContainer/VBoxContainer/MarginContainer/HBoxContainer/PanelContainer2/VBoxContainer/RaceSelect
@onready var class_select: OptionButton = $MarginContainer/PanelContainer/VBoxContainer/MarginContainer/HBoxContainer/PanelContainer2/VBoxContainer/ClassSelect
@onready var row_select: OptionButton = $MarginContainer/PanelContainer/VBoxContainer/MarginContainer/HBoxContainer/PanelContainer2/VBoxContainer/RowSelect
@onready var strength_label: Label = $MarginContainer/PanelContainer/VBoxContainer/Container/HBoxContainer/StatsContainer/StrengthLabel
@onready var endurance_label: Label = $MarginContainer/PanelContainer/VBoxContainer/Container/HBoxContainer/StatsContainer/EnduranceLabel
@onready var wisdom_label: Label = $MarginContainer/PanelContainer/VBoxContainer/Container/HBoxContainer/StatsContainer/WisdomLabel
@onready var dexterity_label: Label = $MarginContainer/PanelContainer/VBoxContainer/Container/HBoxContainer/StatsContainer/DexterityLabel
@onready var piety_label: Label = $MarginContainer/PanelContainer/VBoxContainer/Container/HBoxContainer/StatsContainer/PietyLabel
@onready var willpower_label: Label = $MarginContainer/PanelContainer/VBoxContainer/Container/HBoxContainer/StatsContainer/Willpower
@onready var race_skills: Label = $MarginContainer/PanelContainer/VBoxContainer/Container/HBoxContainer/SkillContainer/RaceSkills
@onready var class_skills: Label = $MarginContainer/PanelContainer/VBoxContainer/Container/HBoxContainer/SkillContainer/ClassSkills
@onready var reroll_button: Button = $MarginContainer/PanelContainer/VBoxContainer/Container/HBoxContainer/OptionsContainer/RerollButton
@onready var accept_button: Button = $MarginContainer/PanelContainer/VBoxContainer/Container/HBoxContainer/OptionsContainer/AcceptButton
@onready var return_button: Button = $MarginContainer/PanelContainer/VBoxContainer/Container/HBoxContainer/OptionsContainer/ReturnButton

var rolled_stats: Dictionary = {}

func _ready() -> void:
	_populate_choices()
	name_edit.text_changed.connect(_on_name_changed)
	race_select.item_selected.connect(_on_template_changed)
	class_select.item_selected.connect(_on_template_changed)
	reroll_button.pressed.connect(_roll_stats)
	accept_button.pressed.connect(_on_accept_pressed)
	return_button.pressed.connect(_on_return_pressed)
	_roll_stats()
	_refresh_preview()
	name_edit.grab_focus()

func _populate_choices() -> void:
	race_select.clear()
	for race_name in RACE_NAMES:
		race_select.add_item(race_name)
	class_select.clear()
	for class_name_value in CLASS_NAMES:
		class_select.add_item(class_name_value)

func _roll_stats() -> void:
	rolled_stats = DiceRoller.roll_character_stats()
	_refresh_preview()

func _refresh_preview(_selected_index: int = 0) -> void:
	var race := _selected_race()
	var character_class := _selected_class()
	if race == null or character_class == null:
		return
	portrait.texture = character_class.sprite_texture
	_set_stat_label(strength_label, "Strength", "strength", character_class.base_strength, race.bonus_strength)
	_set_stat_label(endurance_label, "Endurance", "endurance", character_class.base_endurance, race.bonus_endurance)
	_set_stat_label(wisdom_label, "Wisdom", "wisdom", character_class.base_wisdom, race.bonus_wisdom)
	_set_stat_label(dexterity_label, "Dexterity", "dexterity", character_class.base_dexterity, race.bonus_dexterity)
	_set_stat_label(piety_label, "Piety", "piety", character_class.base_piety, race.bonus_piety)
	_set_stat_label(willpower_label, "Willpower", "willpower", character_class.base_willpower, race.bonus_willpower)
	race_skills.text = "Race: %s" % _format_skills(race.starting_skills)
	class_skills.text = "Class: %s" % _format_skills(character_class.starting_skills)
	accept_button.disabled = name_edit.text.strip_edges().is_empty()

func _set_stat_label(label: Label, title: String, stat_name: String, class_bonus: int, race_bonus: int) -> void:
	var roll := int(rolled_stats.get(stat_name, 0))
	label.text = "%s: %d + %d + %d = %d" % [title, roll, class_bonus, race_bonus, roll + class_bonus + race_bonus]
	label.tooltip_text = "3d6 roll + class + race"

func _format_skills(skill_ids: Array[String]) -> String:
	if skill_ids.is_empty():
		return "None"
	var names: Array[String] = []
	for skill_id in skill_ids:
		var skill := SkillSystem.get_skill(StringName(skill_id))
		names.append(skill.display_name if skill != null else skill_id.capitalize())
	return ", ".join(names)

func _selected_race() -> RaceData:
	return RACES[race_select.selected] if race_select.selected >= 0 and race_select.selected < RACES.size() else null

func _selected_class() -> ClassData:
	return CLASSES[class_select.selected] if class_select.selected >= 0 and class_select.selected < CLASSES.size() else null

func _on_name_changed(_new_text: String) -> void:
	accept_button.disabled = name_edit.text.strip_edges().is_empty()

func _on_template_changed(_selected_index: int) -> void:
	_refresh_preview()

func _on_accept_pressed() -> void:
	var member := PartyMember.create(
		_selected_class(),
		_selected_race(),
		name_edit.text,
		rolled_stats,
		row_select.selected
	)
	StatCalculator.recalculate(member, true)
	if PartyManager.add_roster_member(member):
		SceneFlow.change_scene(load("res://scenes/ui/CharacterFactory/PartyMemberSelection.tscn") as PackedScene)

func _on_return_pressed() -> void:
	SceneFlow.change_scene(load("res://scenes/ui/CharacterFactory/PartyMemberSelection.tscn") as PackedScene)
