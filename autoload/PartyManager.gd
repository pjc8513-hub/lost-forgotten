extends Node

signal party_changed
signal selected_party_member_changed(index: int, member: ClassData)

const MAX_PARTY_SIZE: int = 5
const DEFAULT_PARTY: Array[ClassData] = [
	preload("res://data/classes/knight.tres"),
	preload("res://data/classes/monk.tres"),
	preload("res://data/classes/cleric.tres"),
	preload("res://data/classes/rogue.tres"),
	preload("res://data/classes/sorcerer.tres"),
]

var party: Array[ClassData] = []
var selected_party_member_index: int = -1
var selected_party_member: ClassData:
	get:
		if selected_party_member_index < 0 or selected_party_member_index >= party.size():
			return null
		return party[selected_party_member_index]


func _ready() -> void:
	set_party(DEFAULT_PARTY)


func set_party(members: Array[ClassData]) -> void:
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


func add_party_member(member: ClassData) -> bool:
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
