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

func request_execution(caster: PartyMember, skill_id: StringName) -> bool:
	var skill := get_skill(skill_id)
	if caster == null or skill == null or not caster.learned_skills.has(skill_id):
		return false
	execution_requested.emit(caster, skill)
	return true
