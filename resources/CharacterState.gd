# CharacterState.gd
# Responsibility: Store the mutable runtime state of one party member.
# Holds current HP/MP, XP, level, stat bonuses, and references the class template.
# No derived stat calculation happens here — that is StatCalculator's job.
# This resource is what gets saved and loaded per character.

class_name CharacterState
extends Resource

# ---------------------------------------------------------------------------
# Signals
# ---------------------------------------------------------------------------

signal stats_changed
signal died
signal leveled_up(new_level: int)

# ---------------------------------------------------------------------------
# Identity
# ---------------------------------------------------------------------------

@export var member_name: String = ""
@export var class_data: ClassData          # The read-only class template
@export var row: int = 0                   # 0 = front, 1 = back

# ---------------------------------------------------------------------------
# Vitals (current values, clamped on set)
# ---------------------------------------------------------------------------

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

# Cached maximums — set by StatCalculator after any stat change.
@export var max_hp: int = 0
@export var max_stamina: int = 0

# ---------------------------------------------------------------------------
# Progression
# ---------------------------------------------------------------------------

@export_group("Progression")
@export var level: int = 1
@export var xp: int = 0
@export var xp_to_next_level: int = 100
@export var available_stat_points: int = 0
@export var available_skill_points: int = 0

# ---------------------------------------------------------------------------
# Stat Bonuses
# Applied on top of ClassData base stats (equipment, permanent buffs, etc.)
# Temporary modifiers (combat buffs, status effects) are NOT stored here —
# they live in CombatBuffComponent and StatusEffectComponent respectively.
# ---------------------------------------------------------------------------

@export_group("Stat Bonuses")
@export var bonus_strength: int = 0
@export var bonus_endurance: int = 0
@export var bonus_wisdom: int = 0
@export var bonus_dexterity: int = 0
@export var bonus_willpower: int = 0

# ---------------------------------------------------------------------------
# Base Stat Overrides
# The actual per-character base stats, initialised from ClassData on creation
# and incremented when the player spends stat points.
# ---------------------------------------------------------------------------

@export_group("Base Stats")
@export var base_strength: int = 10
@export var base_endurance: int = 10
@export var base_wisdom: int = 10
@export var base_dexterity: int = 10
@export var base_willpower: int = 2

# ---------------------------------------------------------------------------
# Resistances (base values; equipment adds on top via EquipmentComponent)
# ---------------------------------------------------------------------------

@export_group("Resistances")
@export var resist_fire: int = 0
@export var resist_water: int = 0
@export var resist_earth: int = 0
@export var resist_electric: int = 0
@export var resist_light: int = 0
@export var resist_dark: int = 0

# ---------------------------------------------------------------------------
# Skills
# { "skill_id": rank_int }  — rank 0 means known but not yet leveled.
# Populated by SkillComponent; stored here so it persists with the character.
# ---------------------------------------------------------------------------

@export_group("Skills")
@export var learned_skills: Dictionary = {}
# Limited-use skills store uses spent rather than uses remaining, so changing a
# skill's configured maximum does not require migrating save data.
@export var daily_skill_uses_spent: Dictionary = {}

# ---------------------------------------------------------------------------
# Status & Buffs (runtime only — not exported, not saved between combats)
# Owned and managed by StatusEffectComponent and CombatBuffComponent.
# Stored here as plain data so those components can read/write it cleanly.
# ---------------------------------------------------------------------------

var active_status_effects: Dictionary = {}  # { "poison": { remaining_rounds, save_dc, ... } }
var active_combat_buffs: Dictionary = {}    # { "strength": { value, remaining_rounds } }

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

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
	if class_data == null:
		return ClassData.ClassName.UNKNOWN
	return class_data.class_id

func spend_stat_point(stat: String) -> bool:
	if available_stat_points <= 0:
		return false
	match stat.to_lower():
		"strength":   base_strength   += 1
		"endurance":  base_endurance  += 1
		"wisdom":     base_wisdom     += 1
		"dexterity":  base_dexterity  += 1
		"willpower":  base_willpower  += 1
		_:
			return false
	available_stat_points -= 1
	stats_changed.emit()
	return true

func add_xp(amount: int) -> bool:
	xp += amount
	if xp >= xp_to_next_level:
		xp -= xp_to_next_level
		level += 1
		xp_to_next_level = int(round(xp_to_next_level * 1.35))
		available_stat_points += randi_range(1, 3)
		available_skill_points += 1
		leveled_up.emit(level)
		return true
	return false

# ---------------------------------------------------------------------------
# Factory
# ---------------------------------------------------------------------------

static func create(class_res: ClassData, name_value: String, row_value: int = 0) -> CharacterState:
	var state := CharacterState.new()
	state.class_data       = class_res
	state.member_name      = name_value.strip_edges()
	state.row              = row_value
	state.level            = 1
	state.xp               = 0
	state.xp_to_next_level = 100

	# Copy base stats from class template
	state.base_strength   = class_res.base_strength
	state.base_endurance  = class_res.base_endurance
	state.base_wisdom     = class_res.base_wisdom
	state.base_dexterity  = class_res.base_dexterity
	state.base_willpower  = class_res.base_willpower

	# Grant starting skills at rank 1
	for skill_id in class_res.starting_skills:
		state.learned_skills[skill_id] = 1

	return state
