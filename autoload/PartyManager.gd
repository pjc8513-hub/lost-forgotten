extends Node

signal party_changed
signal roster_changed
signal active_party_changed
signal selected_party_member_changed(index: int, member: PartyMember)

const MAX_PARTY_SIZE: int = 5
const DEFAULT_RACE: RaceData = preload("res://data/races/human.tres")
const DEFAULT_PARTY: Array[ClassData] = [
	preload("res://data/classes/knight.tres"),
	preload("res://data/classes/monk.tres"),
	preload("res://data/classes/cleric.tres"),
	preload("res://data/classes/rogue.tres"),
	preload("res://data/classes/sorcerer.tres"),
]

var default_party: Array[PartyMember] = []
var roster: Array[PartyMember] = []
var party: Array[PartyMember] = []
var selected_party_member_index: int = -1
var selected_party_member: PartyMember:
	get:
		if selected_party_member_index < 0 or selected_party_member_index >= party.size():
			return null
		return party[selected_party_member_index]


func _ready() -> void:
	var default_members: Array[PartyMember] = []
	for class_data in DEFAULT_PARTY:
		var member := PartyMember.create(
			class_data,
			DEFAULT_RACE,
			class_data.display_name,
			DiceRoller.roll_character_stats()
		)
		StatCalculator.recalculate(member, true)
		default_members.append(member)
	default_party.assign(default_members)
	roster.assign(default_members)
	set_party(default_members)
	roster_changed.emit()


func use_default_party() -> void:
	set_party(default_party)


func set_party(members: Array[PartyMember]) -> void:
	party.assign(members.slice(0, MAX_PARTY_SIZE))
	selected_party_member_index = 0 if not party.is_empty() else -1
	party_changed.emit()
	active_party_changed.emit()
	selected_party_member_changed.emit(selected_party_member_index, selected_party_member)


func select_party_member(index: int) -> bool:
	if index < 0 or index >= party.size():
		return false
	if index == selected_party_member_index:
		return true

	selected_party_member_index = index
	selected_party_member_changed.emit(index, selected_party_member)
	return true


func add_party_member(member: PartyMember) -> bool:
	if member == null or party.has(member) or party.size() >= MAX_PARTY_SIZE:
		return false
	party.append(member)
	if selected_party_member_index == -1:
		selected_party_member_index = 0
	party_changed.emit()
	active_party_changed.emit()
	selected_party_member_changed.emit(selected_party_member_index, selected_party_member)
	return true


func remove_party_member(index: int) -> bool:
	if index < 0 or index >= party.size():
		return false
	party.remove_at(index)
	selected_party_member_index = mini(selected_party_member_index, party.size() - 1)
	party_changed.emit()
	active_party_changed.emit()
	selected_party_member_changed.emit(selected_party_member_index, selected_party_member)
	return true


func spend_party_stamina(amount: int) -> void:
	for member in party:
		member.spend_stamina(amount)

# Call this from the eventual rest flow after the rest has completed.
func reset_daily_skill_uses() -> void:
	for member in party:
		member.reset_daily_skill_uses()

func get_roster() -> Array[PartyMember]:
	return roster.duplicate()

func get_active_party() -> Array[PartyMember]:
	return party.duplicate()

func can_set_out() -> bool:
	return not party.is_empty()

func add_member_to_party(member: PartyMember) -> bool:
	return add_party_member(member)

func remove_member_from_party(member: PartyMember) -> bool:
	var index := party.find(member)
	return remove_party_member(index) if index >= 0 else false

func delete_roster_member(member: PartyMember) -> bool:
	var index := roster.find(member)
	if index < 0:
		return false
	remove_member_from_party(member)
	roster.remove_at(index)
	roster_changed.emit()
	return true

func add_roster_member(member: PartyMember) -> bool:
	if member == null or roster.has(member):
		return false
	roster.append(member)
	roster_changed.emit()
	return true
