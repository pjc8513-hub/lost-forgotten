# SkillData.gd
# This is a read-only data resource — no logic, no calculations, no game state.
# One .tres file per skill lives in res://data/skills/

class_name SkillData
extends Resource

enum Archetype {
	UNKNOWN = -1,
	EXPLORATION,
	PASSIVE,
	COMBAT_ACTIVE,
	COMBAT_PASSIVE,
	PARTY_SPELL
}

enum Element {
	NONE = -1,
	FIRE,
	EARTH,
	AIR,
	WATER,
	PHYSICAL,
	SPIRIT,
	HOLY,
	DARK
}

enum Status_effect {
	NONE = -1,
	STUN,
	FEAR,
	POISON,
	BURN,
	FREEZE,
	PARALYZE,
	BLIND,
	WEAK,
	SILENCE
}

# identity
@export var skill_id: StringName = ""
@export var display_name:  String = ""
@export var available_classes: Array[ClassData.ClassName]
@export var icon: Texture2D
@export var archetype: Archetype = Archetype.UNKNOWN
@export var element: Element = Element.NONE

@export var starting_rank: int = 1
@export var maximum_rank: int = 10

@export var target_self: bool = false
@export var is_AOE: bool = false

# cost
@export var stamina_cost: int = 0
@export var uses_per_day: int = -1 # -1 = unlimited
@export var charge_turns: int = 0

# difficulty check roll
@export var dc_stat: String
@export var dc_base: int = 12

@export_group("damage and Status Effect")
@export var  damage_amount_dice: int = 0
@export var damage_amount_rolls: int = 0
@export var status_effect: Status_effect = Status_effect.NONE

# heal and remove effect
@export_group("Heal and remove effect")
@export var heal_amount_dice: int = 0
@export var heal_amount_sides: int = 0
@export var stamina_restore_sides: int = 0
@export var bonus_res_per_rank: int = 0
@export var remove_effect: Array[String]

# stat bonuses
@export var stat_deltas: Dictionary[String, int] # StatCalculator reads this per skill rank
@export var resist_element: Element = Element.NONE
@export var resist_status: Status_effect = Status_effect.NONE

@export var bonus_damage_per_rank: int = 0
@export var grants_crit: bool = false
