class_name skill_menu

extends Control

const ARCHETYPE_ORDER: Array[SkillData.Archetype] = [
	SkillData.Archetype.PARTY_SPELL,
	SkillData.Archetype.EXPLORATION,
	SkillData.Archetype.COMBAT_ACTIVE,
	SkillData.Archetype.COMBAT_PASSIVE,
	SkillData.Archetype.PASSIVE,
]
const EXECUTABLE_ARCHETYPES: Array[SkillData.Archetype] = [
	SkillData.Archetype.PARTY_SPELL,
	SkillData.Archetype.EXPLORATION,
]

@onready var character_name: Label = $PanelContainer/MarginContainer/VBoxContainer/CharacterName
@onready var skill_list: ItemList = $PanelContainer/MarginContainer/VBoxContainer/MarginContainer/HBoxContainer/SkillContainer/VBoxContainer/ScrollContainer/SkillList
@onready var next_button: Button = $PanelContainer/MarginContainer/VBoxContainer/MarginContainer/HBoxContainer/OptionsContainer/VBoxContainer/NextButton
@onready var previous_button: Button = $PanelContainer/MarginContainer/VBoxContainer/MarginContainer/HBoxContainer/OptionsContainer/VBoxContainer/PreviousButton
@onready var close_button: Button = $PanelContainer/MarginContainer/VBoxContainer/MarginContainer/HBoxContainer/OptionsContainer/VBoxContainer/CloseButton
@onready var cast_button: Button = $PanelContainer/MarginContainer/VBoxContainer/MarginContainer/HBoxContainer/OptionsContainer/VBoxContainer/CastButton

var _displayed_member_index: int = -1
var _displayed_member: PartyMember
var _listed_skills: Array[SkillData] = []

func _ready() -> void:
	hide()
	next_button.pressed.connect(_on_next_pressed)
	previous_button.pressed.connect(_on_previous_pressed)
	close_button.pressed.connect(close)
	cast_button.pressed.connect(_on_cast_pressed)
	skill_list.item_selected.connect(_on_skill_list_item_selected)
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
	_listed_skills.clear()
	skill_list.clear()

	var party_size := PartyManager.party.size()
	previous_button.disabled = party_size <= 1
	next_button.disabled = party_size <= 1
	cast_button.disabled = true

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
		_listed_skills.append(skill)
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
	var use_line := "Passive" if skill.archetype == SkillData.Archetype.PASSIVE else "Uses per day remaining: %s" % ("Unlimited" if uses_remaining < 0 else str(uses_remaining))
	return "%s\nStamina cost: %d\n%s" % [
		use_line,
		skill.stamina_cost,
		skill.description,
	]


func _is_castable_skill(skill: SkillData) -> bool:
	return skill != null and skill.archetype in EXECUTABLE_ARCHETYPES


func _attempt_cast(index: int) -> void:
	if _displayed_member == null or index < 0 or index >= _listed_skills.size():
		return
	var skill := _listed_skills[index]
	if not _is_castable_skill(skill):
		return
	close()
	SkillSystem.request_execution(_displayed_member, skill.skill_id)


func _update_cast_button() -> void:
	var selected_items := skill_list.get_selected_items()
	if selected_items.is_empty():
		cast_button.disabled = true
		return
	var selected_index := selected_items[0]
	cast_button.disabled = selected_index < 0 \
			or selected_index >= _listed_skills.size() \
			or not _is_castable_skill(_listed_skills[selected_index])


func _on_selected_party_member_changed(index: int, member: PartyMember) -> void:
	if visible:
		_refresh(index, member)


func _on_next_pressed() -> void:
	_select_relative_member(1)


func _on_previous_pressed() -> void:
	_select_relative_member(-1)


func _on_cast_pressed() -> void:
	var selected_items := skill_list.get_selected_items()
	if selected_items.is_empty():
		return
	_attempt_cast(selected_items[0])


func _on_skill_list_item_selected(_index: int) -> void:
	_update_cast_button()


func _select_relative_member(offset: int) -> void:
	var party_size := PartyManager.party.size()
	if party_size <= 0:
		return
	var next_index := posmod(_displayed_member_index + offset, party_size)
	if not PartyManager.select_party_member(next_index):
		_refresh(next_index, PartyManager.party[next_index])


func _on_skill_list_item_activated(index: int) -> void:
	_attempt_cast(index)
