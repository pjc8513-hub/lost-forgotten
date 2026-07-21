class_name PartyMember
extends Resource

## The canonical mutable state for one party member. ClassData and RaceData are
## immutable templates; rolled stats, progression, vitals, and learned skills
## belong to this resource.

signal stats_changed
signal health_changed(amount: int, feedback_type: StringName)
signal inventory_changed
signal died
signal leveled_up(new_level: int)
signal xp_changed(total_xp: int)

enum CombatRow {
	FRONT,
	BACK,
}

const TRAINING_BASE_GOLD_COST := 100
const TRAINING_LEVEL_GOLD_STEP := 50

@export_group("Identity")
@export var member_name: String = ""
@export var portrait: Texture2D
@export var class_data: ClassData
@export var race_data: RaceData
@export var row: CombatRow = CombatRow.FRONT

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
@export var resist_fire: bool = false
@export var resist_water: bool = false
@export var resist_earth: bool = false
@export var resist_electric: bool = false
@export var resist_light: bool = false
@export var resist_dark: bool = false

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

func take_damage(amount: int, feedback_type: StringName = &"damage") -> void:
	var hp_before := current_hp
	current_hp = clampi(current_hp - maxi(amount, 0), 0, max_hp)
	var damage_taken := hp_before - current_hp
	if damage_taken > 0:
		health_changed.emit(damage_taken, feedback_type)
		var status_cleared := false
		for raw_effect_id in active_status_effects.keys():
			if StatusEffects.breaks_on_damage(int(raw_effect_id)):
				active_status_effects.erase(raw_effect_id)
				status_cleared = true
		if status_cleared:
			StatCalculator.recalculate(self)

func heal(amount: int, feedback_type: StringName = &"healing") -> void:
	var hp_before := current_hp
	current_hp = clampi(current_hp + maxi(amount, 0), 0, max_hp)
	var recovered := current_hp - hp_before
	if recovered > 0:
		health_changed.emit(recovered, feedback_type)

func spend_stamina(amount: int) -> bool:
	if amount <= 0:
		return true
	if current_stamina < amount:
		return false
	current_stamina -= amount
	return true

func restore_stamina(amount: int) -> void:
	current_stamina = clampi(current_stamina + maxi(amount, 0), 0, max_stamina)

func add_inventory_item(item: ItemInstance) -> bool:
	if item == null or item.item_data == null:
		return false
	inventory.append(item)
	inventory_changed.emit()
	return true

func can_equip_item(item: ItemInstance) -> bool:
	if item == null or item.item_data == null:
		return false
	if item.item_data.item_type != ItemData.ItemType.EQUIPMENT:
		return false
	if item.item_data.equip_slot == ItemData.Equip_Slot.NONE:
		return false
	if item.item_data is ArmorData:
		var armor := item.item_data as ArmorData
		return class_data != null and class_data.allowed_armor_types.has(armor.armor_type)
	return true

func equip_inventory_item(item: ItemInstance) -> bool:
	if not inventory.has(item) or not can_equip_item(item):
		return false
	for equipped_item in inventory:
		if equipped_item != item and equipped_item.is_equipped \
				and equipped_item.item_data != null \
				and equipped_item.item_data.equip_slot == item.item_data.equip_slot:
			equipped_item.is_equipped = false
	item.is_equipped = true
	inventory_changed.emit()
	StatCalculator.recalculate(self)
	return true

func unequip_inventory_item(item: ItemInstance) -> bool:
	if not inventory.has(item) or not item.is_equipped:
		return false
	item.is_equipped = false
	inventory_changed.emit()
	StatCalculator.recalculate(self)
	return true

func use_inventory_item(item: ItemInstance) -> bool:
	if not inventory.has(item) or not item.item_data is ConsumableData:
		return false
	var consumable := item.item_data as ConsumableData
	if not consumable.apply_to_character(self):
		return false
	inventory.erase(item)
	inventory_changed.emit()
	return true

func drop_inventory_item(item: ItemInstance) -> bool:
	if not inventory.has(item) or item.item_data == null:
		return false
	if item.item_data.item_type == ItemData.ItemType.QUEST:
		return false
	item.is_equipped = false
	inventory.erase(item)
	inventory_changed.emit()
	StatCalculator.recalculate(self)
	return true

func trade_inventory_item(item: ItemInstance, recipient: PartyMember) -> bool:
	if recipient == null or recipient == self or not inventory.has(item):
		return false
	item.is_equipped = false
	inventory.erase(item)
	if not recipient.add_inventory_item(item):
		inventory.append(item)
		return false
	inventory_changed.emit()
	StatCalculator.recalculate(self)
	return true

func get_skill_uses_remaining(skill: SkillData) -> int:
	if skill == null or skill.uses_per_day < 0:
		return -1
	return maxi(get_skill_uses_per_day(skill) - int(daily_skill_uses_spent.get(skill.skill_id, 0)), 0)

func get_skill_uses_per_day(skill: SkillData) -> int:
	if skill == null or skill.uses_per_day < 0:
		return -1
	var rank := maxi(int(learned_skills.get(skill.skill_id, skill.starting_rank)), skill.starting_rank)
	var bonus_ranks := maxi(rank - skill.starting_rank, 0)
	return skill.uses_per_day + bonus_ranks * maxi(skill.bonus_uses_per_rank, 0)

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

func get_race_display_name() -> String:
	if race_data == null:
		return "Unknown"
	if not race_data.display_name.strip_edges().is_empty():
		return race_data.display_name
	if not race_data.resource_path.is_empty():
		return race_data.resource_path.get_file().get_basename().capitalize()
	return "Unknown"

func get_row_display_name() -> String:
	return "Back" if row == CombatRow.BACK else "Front"

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
	var gained := maxi(amount, 0)
	if gained <= 0:
		return false
	xp += gained
	xp_changed.emit(xp)
	stats_changed.emit()
	return can_level_up()

func can_level_up() -> bool:
	return xp >= xp_to_next_level

func get_training_gold_cost() -> int:
	return TRAINING_BASE_GOLD_COST + (maxi(level, 1) - 1) * TRAINING_LEVEL_GOLD_STEP

func level_up() -> bool:
	if not can_level_up():
		return false
	level += 1
	xp_to_next_level += maxi(int(round(xp_to_next_level * 1.35)), 1)
	available_stat_points += randi_range(1, 3)
	available_skill_points += 1
	StatCalculator.recalculate(self)
	leveled_up.emit(level)
	return true

static func create(
	class_resource: ClassData,
	race_resource: RaceData,
	name_value: String,
	rolled_stats: Dictionary = {},
	row_value: CombatRow = CombatRow.FRONT
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
