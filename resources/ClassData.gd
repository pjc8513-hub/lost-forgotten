# ClassData.gd
# Responsibility: Class identity, base stats, and scaling constants for one class template.
# This is a read-only data resource — no logic, no calculations, no game state.
# One .tres file per class lives in res://data/classes/.

class_name ClassData
extends Resource

# ---------------------------------------------------------------------------
# Enum
# ---------------------------------------------------------------------------

enum ClassName {
	UNKNOWN = -1,
	KNIGHT,
	BARBARIAN,
	ROGUE,
	CLERIC,
	SORCERER,
	DRUID,
	MONK
}

# ---------------------------------------------------------------------------
# Identity
# ---------------------------------------------------------------------------

@export var class_id: ClassName = ClassName.UNKNOWN
@export var display_name: String = ""
@export var sprite_texture: Texture2D

# ---------------------------------------------------------------------------
# Base Stats
# Stats stored here are the class starting values before any bonuses.
# ---------------------------------------------------------------------------

@export_group("Base Stats")
@export var base_strength: int = 5
@export var base_endurance: int = 5
@export var base_wisdom: int = 5
@export var base_dexterity: int = 5
@export var base_piety: int = 2
@export var base_willpower: int = 1
@export var base_movement: int = 4

# ---------------------------------------------------------------------------
# HP / Stamina Modifiers
# Used by StatCalculator to derive max HP and Stamina at any level.
# Formula: base + (per_level * level) + floor(ability_modifier * scale)
# ---------------------------------------------------------------------------

@export_group("HP Modifier")
@export var hp_base: int = 10
@export var hp_per_level: int = 5
@export var hp_str_scale: float = 0.5
@export var hp_end_scale: float = 1.0

@export_group("Stamina Modifier")
@export var stamina: int = 25
@export var stamina_per_level: int = 1
@export var stamina_end_scale: float = 0.5

# ---------------------------------------------------------------------------
# Combat Stat Modifiers
# Each derived combat stat = base + floor(ability_modifier * scale).
# StatCalculator reads these; ClassData never calls them itself.
# ---------------------------------------------------------------------------

@export_group("Armor Class Modifier")
@export var ac_bonus: int = 0          # Flat class AC modifier (negative = better in old-school convention)
@export var ac_dex_scale: float = 0.5

@export_group("Accuracy Modifier")
@export var accuracy_base: int = 0
@export var accuracy_str_scale: float = 0.0
@export var accuracy_dex_scale: float = 0.5
@export var accuracy_wis_scale: float = 0.0

@export_group("Critical Modifier")
@export var crit_base: int = 1
@export var crit_dex_scale: float = 0.5
@export var crit_wis_scale: float = 0.0

@export_group("Initiative Modifier")
@export var initiative_base: int = 0
@export var initiative_dex_scale: float = 0.5
@export var initiative_wis_scale: float = 0.0

@export_group("Attack Speed Modifier")
@export var attack_speed_base: int = 0
@export var attack_speed_dex_scale: float = 0.25

@export_group("Damage Modifier")
@export var bonus_damage_base: int = 0
@export var damage_str_scale: float = 0.5
@export var damage_dex_scale: float = 0.0
@export var damage_wis_scale: float = 0.0

@export_group("Magic Modifier")
@export var wisdom_modifier: float = 0.5
@export var magic_amp_base: int = 0
@export var magic_amp_wis_scale: float = 0.0

# ---------------------------------------------------------------------------
# Equipment
# ---------------------------------------------------------------------------

@export_group("Armor")
@export var allowed_armor_types: Array[ArmorData.Armor_Type] = []  # ArmorData.Armor_Type values

# ---------------------------------------------------------------------------
# Starting Skills
# Skill IDs unlocked at rank 1 when the character is first created.
# ---------------------------------------------------------------------------

@export_group("Starting Skills")
@export var starting_skills: Array[String] = []

# ---------------------------------------------------------------------------
# Skill Bonuses
# Flat bonuses to non-combat skills (lockpicking, lore, medicine, etc.)
# Read by the SkillComponent when calculating skill check totals.
# ---------------------------------------------------------------------------

@export_group("Skill Bonuses")
@export var skill_bonuses: Dictionary = {}  # { "lore": 2, "medicine": 1 }

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

static func get_display_name_for(class_id_value: ClassName) -> String:
	for key in ClassName.keys():
		if ClassName[key] == class_id_value:
			return String(key).capitalize()
	return "Unknown"
