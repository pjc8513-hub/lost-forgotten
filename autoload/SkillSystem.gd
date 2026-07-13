extends Node

signal execution_requested(caster: PartyMember, skill: SkillData)

const SKILL_DIRECTORY := "res://data/skills"
const PARTY_MENU_ARCHETYPES: Array[SkillData.Archetype] = [
	SkillData.Archetype.EXPLORATION,
	SkillData.Archetype.PARTY_SPELL,
]

var _skills: Dictionary[StringName, SkillData] = {}

func _ready() -> void:
	reload_catalog()

func reload_catalog() -> void:
	_skills.clear()
	var directory := DirAccess.open(SKILL_DIRECTORY)
	if directory == null:
		push_error("Could not open skill directory: %s" % SKILL_DIRECTORY)
		return
	for file_name in directory.get_files():
		if file_name.get_extension() != "tres":
			continue
		var resource := load(SKILL_DIRECTORY.path_join(file_name)) as SkillData
		if resource == null or resource.skill_id.is_empty():
			push_warning("Ignoring invalid skill resource: %s" % file_name)
			continue
		if _skills.has(resource.skill_id):
			push_error("Duplicate skill id: %s" % resource.skill_id)
			continue
		_skills[resource.skill_id] = resource

func get_skill(skill_id: StringName) -> SkillData:
	return _skills.get(skill_id) as SkillData

func get_all_skills() -> Array[SkillData]:
	var result: Array[SkillData] = []
	for raw_skill in _skills.values():
		var skill := raw_skill as SkillData
		if skill != null:
			result.append(skill)
	result.sort_custom(func(a: SkillData, b: SkillData) -> bool: return a.display_name.naturalnocasecmp_to(b.display_name) < 0)
	return result

func get_learned_skills(character: PartyMember, archetypes: Array[SkillData.Archetype] = []) -> Array[SkillData]:
	var result: Array[SkillData] = []
	if character == null:
		return result
	for raw_id in character.learned_skills.keys():
		var skill := get_skill(StringName(raw_id))
		if skill != null and (archetypes.is_empty() or skill.archetype in archetypes):
			result.append(skill)
	result.sort_custom(func(a: SkillData, b: SkillData) -> bool: return a.display_name.naturalnocasecmp_to(b.display_name) < 0)
	return result

func get_party_menu_skills(character: PartyMember) -> Array[SkillData]:
	return get_learned_skills(character, PARTY_MENU_ARCHETYPES)

func get_teacher_skills(character: PartyMember) -> Array[SkillData]:
	var result: Array[SkillData] = []
	if character == null:
		return result
	for skill in get_all_skills():
		if not is_skill_available_to_character(character, skill):
			continue
		if get_character_skill_rank(character, skill) >= _get_skill_maximum_rank(skill):
			continue
		result.append(skill)
	return result

func is_skill_available_to_character(character: PartyMember, skill: SkillData) -> bool:
	if character == null or skill == null:
		return false
	if skill.available_classes.is_empty():
		return true
	return character.get_class_id() in skill.available_classes

func get_character_skill_rank(character: PartyMember, skill: SkillData) -> int:
	if character == null or skill == null:
		return 0
	return int(character.learned_skills.get(skill.skill_id, 0))

func can_learn_skill(character: PartyMember, skill: SkillData) -> bool:
	return is_skill_available_to_character(character, skill) and get_character_skill_rank(character, skill) <= 0

func can_improve_skill(character: PartyMember, skill: SkillData) -> bool:
	if not is_skill_available_to_character(character, skill):
		return false
	var rank := get_character_skill_rank(character, skill)
	return rank > 0 and rank < _get_skill_maximum_rank(skill) and character.available_skill_points > 0

func learn_skill(character: PartyMember, skill: SkillData) -> bool:
	if not can_learn_skill(character, skill):
		return false
	character.learned_skills[skill.skill_id] = clampi(skill.starting_rank, 1, _get_skill_maximum_rank(skill))
	character.stats_changed.emit()
	return true

func improve_skill(character: PartyMember, skill: SkillData) -> bool:
	if not can_improve_skill(character, skill):
		return false
	var next_rank := mini(get_character_skill_rank(character, skill) + 1, _get_skill_maximum_rank(skill))
	character.learned_skills[skill.skill_id] = next_rank
	character.available_skill_points -= 1
	character.stats_changed.emit()
	return true

func request_execution(caster: PartyMember, skill_id: StringName) -> bool:
	var skill := get_skill(skill_id)
	if caster == null or skill == null or not caster.learned_skills.has(skill_id):
		return false
	execution_requested.emit(caster, skill)
	return true

func _get_skill_maximum_rank(skill: SkillData) -> int:
	return maxi(skill.maximum_rank, 1)
