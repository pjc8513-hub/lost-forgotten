class_name skill_menu

extends Control

const ARCHETYPE_ORDER: Array[SkillData.Archetype] = [
	SkillData.Archetype.PARTY_SPELL,
	SkillData.Archetype.EXPLORATION,
	SkillData.Archetype.COMBAT_ACTIVE,
	SkillData.Archetype.COMBAT_PASSIVE,
	SkillData.Archetype.PASSIVE,
]

@onready var character_name: Label = $PanelContainer/MarginContainer/VBoxContainer/CharacterName
@onready var skill_list: ItemList = $PanelContainer/MarginContainer/VBoxContainer/MarginContainer/HBoxContainer/SkillContainer/VBoxContainer/ScrollContainer/SkillList
@onready var next_button: Button = $PanelContainer/MarginContainer/VBoxContainer/MarginContainer/HBoxContainer/OptionsContainer/VBoxContainer/NextButton
@onready var previous_button: Button = $PanelContainer/MarginContainer/VBoxContainer/MarginContainer/HBoxContainer/OptionsContainer/VBoxContainer/PreviousButton
@onready var close_button: Button = $PanelContainer/MarginContainer/VBoxContainer/MarginContainer/HBoxContainer/OptionsContainer/VBoxContainer/CloseButton

var _displayed_member_index: int = -1
var _displayed_member: PartyMember

func _ready() -> void:
	hide()
	next_button.pressed.connect(_on_next_pressed)
	previous_button.pressed.connect(_on_previous_pressed)
	close_button.pressed.connect(close)
	PartyManager.selected_party_member_changed.connect(_on_selected_party_member_changed)
	_refresh(PartyManager.selected_party_member_index, PartyManager.selected_party_member)


func open() -> void:
	_refresh(PartyManager.selected_party_member_index, PartyManager.selected_party_member)
	show()


func close() -> void:
	hide()


func _refresh(member_index: int, member: PartyMember) -> void:
	_displayed_member_index = member_index
	_displayed_member = member
	skill_list.clear()

	var party_size := PartyManager.party.size()
	previous_button.disabled = party_size <= 1
	next_button.disabled = party_size <= 1

	if member == null:
		character_name.text = "No character"
		skill_list.add_item("No active party member")
		skill_list.set_item_disabled(0, true)
		return

	character_name.text = member.member_name
	var skills := _get_ordered_skills(member)
	if skills.is_empty():
		skill_list.add_item("No learned skills")
		skill_list.set_item_disabled(0, true)
		return

	for skill in skills:
		var item_index := skill_list.add_item(skill.display_name, skill.icon)
		skill_list.set_item_tooltip(item_index, _get_skill_tooltip(member, skill))


func _get_ordered_skills(member: PartyMember) -> Array[SkillData]:
	var skills := SkillSystem.get_learned_skills(member)
	skills.sort_custom(_sort_skills)
	return skills


func _sort_skills(a: SkillData, b: SkillData) -> bool:
	var a_order := _get_archetype_order(a)
	var b_order := _get_archetype_order(b)
	if a_order != b_order:
		return a_order < b_order
	return a.display_name.naturalnocasecmp_to(b.display_name) < 0


func _get_archetype_order(skill: SkillData) -> int:
	if skill == null:
		return ARCHETYPE_ORDER.size()
	var index := ARCHETYPE_ORDER.find(skill.archetype)
	return index if index >= 0 else ARCHETYPE_ORDER.size()


func _get_skill_tooltip(member: PartyMember, skill: SkillData) -> String:
	var uses_remaining := member.get_skill_uses_remaining(skill)
	var uses_text := "Unlimited" if uses_remaining < 0 else str(uses_remaining)
	return "Uses per day remaining: %s\nStamina cost: %d\n%s" % [
		uses_text,
		skill.stamina_cost,
		skill.description,
	]


func _on_selected_party_member_changed(index: int, member: PartyMember) -> void:
	if visible:
		_refresh(index, member)


func _on_next_pressed() -> void:
	_select_relative_member(1)


func _on_previous_pressed() -> void:
	_select_relative_member(-1)


func _select_relative_member(offset: int) -> void:
	var party_size := PartyManager.party.size()
	if party_size <= 0:
		return
	var next_index := posmod(_displayed_member_index + offset, party_size)
	if not PartyManager.select_party_member(next_index):
		_refresh(next_index, PartyManager.party[next_index])


func _on_skill_list_item_activated(index: int) -> void:
	pass # Replace with function body.
