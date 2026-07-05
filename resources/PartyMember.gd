class_name PartyMember
extends Resource

## The canonical mutable state for one party member. ClassData and RaceData are
## immutable templates; rolled stats, progression, vitals, and learned skills
## belong to this resource.

signal stats_changed
signal inventory_changed
signal died
signal leveled_up(new_level: int)

@export_group("Identity")
@export var member_name: String = ""
@export var portrait: Texture2D
@export var class_data: ClassData
@export var race_data: RaceData
@export var row: int = 0

@export_group("Vitals")
@export var current_hp: int = 0:
	set(value):
		current_hp = clampi(value, 0, max_hp)
		stats_changed.emit()
		if current_hp == 0:
			died.emit()
@export var current_stamina: int = 0:
	set(value):
		current_stamina = clampi(value, 0, max_stamina)
		stats_changed.emit()
@export var max_hp: int = 0
@export var max_stamina: int = 0

@export_group("Progression")
@export var level: int = 1
@export var xp: int = 0
@export var xp_to_next_level: int = 100
@export var available_stat_points: int = 0
@export var available_skill_points: int = 0

## Values produced by character creation. Template contributions stay in their
## ClassData/RaceData resources and are composed by StatCalculator.
@export_group("Rolled Stats")
@export var rolled_strength: int = 0
@export var rolled_endurance: int = 0
@export var rolled_wisdom: int = 0
@export var rolled_dexterity: int = 0
@export var rolled_piety: int = 0
@export var rolled_willpower: int = 0

## Permanent/equipment bonuses. Temporary combat modifiers live below.
@export_group("Stat Bonuses")
@export var bonus_strength: int = 0
@export var bonus_endurance: int = 0
@export var bonus_wisdom: int = 0
@export var bonus_dexterity: int = 0
@export var bonus_piety: int = 0
@export var bonus_willpower: int = 0

@export_group("Resistances")
@export var resist_fire: int = 0
@export var resist_water: int = 0
@export var resist_earth: int = 0
@export var resist_electric: int = 0
@export var resist_light: int = 0
@export var resist_dark: int = 0

@export_group("Skills")
@export var learned_skills: Dictionary = {}
@export var daily_skill_uses_spent: Dictionary = {}

@export_group("Inventory")
@export var inventory: Array[ItemInstance] = []

var active_status_effects: Dictionary = {}
var active_combat_buffs: Dictionary = {}

func is_alive() -> bool:
	return current_hp > 0

func is_conscious() -> bool:
	return current_hp > 0

func take_damage(amount: int) -> void:
	current_hp -= maxi(amount, 0)

func heal(amount: int) -> void:
	current_hp += maxi(amount, 0)

func spend_stamina(amount: int) -> bool:
	if amount <= 0:
		return true
	if current_stamina < amount:
		return false
	current_stamina -= amount
	return true

func restore_stamina(amount: int) -> void:
	current_stamina += maxi(amount, 0)

func add_inventory_item(item: ItemInstance) -> bool:
	if item == null or item.item_data == null:
		return false
	inventory.append(item)
	inventory_changed.emit()
	return true

func get_skill_uses_remaining(skill: SkillData) -> int:
	if skill == null or skill.uses_per_day < 0:
		return -1
	return maxi(skill.uses_per_day - int(daily_skill_uses_spent.get(skill.skill_id, 0)), 0)

func consume_skill_use(skill: SkillData) -> bool:
	if skill == null:
		return false
	if skill.uses_per_day < 0:
		return true
	if get_skill_uses_remaining(skill) <= 0:
		return false
	daily_skill_uses_spent[skill.skill_id] = int(daily_skill_uses_spent.get(skill.skill_id, 0)) + 1
	return true

func reset_daily_skill_uses() -> void:
	daily_skill_uses_spent.clear()

func get_class_id() -> ClassData.ClassName:
	return ClassData.ClassName.UNKNOWN if class_data == null else class_data.class_id

func spend_stat_point(stat: String) -> bool:
	if available_stat_points <= 0:
		return false
	match stat.to_lower():
		"strength": rolled_strength += 1
		"endurance": rolled_endurance += 1
		"wisdom": rolled_wisdom += 1
		"dexterity": rolled_dexterity += 1
		"piety": rolled_piety += 1
		"willpower": rolled_willpower += 1
		_: return false
	available_stat_points -= 1
	stats_changed.emit()
	return true

func add_xp(amount: int) -> bool:
	xp += maxi(amount, 0)
	if xp < xp_to_next_level:
		return false
	xp -= xp_to_next_level
	level += 1
	xp_to_next_level = int(round(xp_to_next_level * 1.35))
	available_stat_points += randi_range(1, 3)
	available_skill_points += 1
	leveled_up.emit(level)
	return true

static func create(
	class_resource: ClassData,
	race_resource: RaceData,
	name_value: String,
	rolled_stats: Dictionary = {},
	row_value: int = 0
) -> PartyMember:
	var member := PartyMember.new()
	member.class_data = class_resource
	member.race_data = race_resource
	member.member_name = name_value.strip_edges()
	member.row = row_value
	member.portrait = class_resource.sprite_texture if class_resource != null else null
	member.rolled_strength = int(rolled_stats.get("strength", 0))
	member.rolled_endurance = int(rolled_stats.get("endurance", 0))
	member.rolled_wisdom = int(rolled_stats.get("wisdom", 0))
	member.rolled_dexterity = int(rolled_stats.get("dexterity", 0))
	member.rolled_piety = int(rolled_stats.get("piety", 0))
	member.rolled_willpower = int(rolled_stats.get("willpower", 0))
	if class_resource != null:
		member._grant_starting_skills(class_resource.starting_skills)
	if race_resource != null:
		member._grant_starting_skills(race_resource.starting_skills)
	return member

func _grant_starting_skills(skill_ids: Array[String]) -> void:
	for skill_id in skill_ids:
		var key := StringName(skill_id)
		learned_skills[key] = maxi(int(learned_skills.get(key, 0)), 1)
