extends Node

signal party_changed
signal selected_party_member_changed(index: int, member: CharacterState)

const MAX_PARTY_SIZE: int = 5
const DEFAULT_PARTY: Array[ClassData] = [
	preload("res://data/classes/knight.tres"),
	preload("res://data/classes/monk.tres"),
	preload("res://data/classes/cleric.tres"),
	preload("res://data/classes/rogue.tres"),
	preload("res://data/classes/sorcerer.tres"),
]

var party: Array[CharacterState] = []
var selected_party_member_index: int = -1
var selected_party_member: CharacterState:
	get:
		if selected_party_member_index < 0 or selected_party_member_index >= party.size():
			return null
		return party[selected_party_member_index]


func _ready() -> void:
	var default_members: Array[CharacterState] = []
	for class_data in DEFAULT_PARTY:
		var member := CharacterState.create(class_data, class_data.display_name)
		StatCalculator.recalculate(member, true)
		default_members.append(member)
	set_party(default_members)


func set_party(members: Array[CharacterState]) -> void:
	party.assign(members.slice(0, MAX_PARTY_SIZE))
	selected_party_member_index = 0 if not party.is_empty() else -1
	party_changed.emit()
	selected_party_member_changed.emit(selected_party_member_index, selected_party_member)


func select_party_member(index: int) -> bool:
	if index < 0 or index >= party.size():
		return false
	if index == selected_party_member_index:
		return true

	selected_party_member_index = index
	selected_party_member_changed.emit(index, selected_party_member)
	return true


func add_party_member(member: CharacterState) -> bool:
	if member == null or party.size() >= MAX_PARTY_SIZE:
		return false
	party.append(member)
	if selected_party_member_index == -1:
		selected_party_member_index = 0
	party_changed.emit()
	selected_party_member_changed.emit(selected_party_member_index, selected_party_member)
	return true


func remove_party_member(index: int) -> bool:
	if index < 0 or index >= party.size():
		return false
	party.remove_at(index)
	selected_party_member_index = mini(selected_party_member_index, party.size() - 1)
	party_changed.emit()
	selected_party_member_changed.emit(selected_party_member_index, selected_party_member)
	return true


func spend_party_stamina(amount: int) -> void:
	for member in party:
		member.spend_stamina(amount)

# Call this from the eventual rest flow after the rest has completed.
func reset_daily_skill_uses() -> void:
	for member in party:
		member.reset_daily_skill_uses()
