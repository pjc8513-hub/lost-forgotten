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
	COMBAT_PASSIVE
}

# identity
@export var skill_id: StringName = ""
@export var display_name:  String = ""
@export var available_classes: Array[ClassData.ClassName]
@export var icon: Texture2D
@export var archetype: Archetype = Archetype.UNKNOWN
@export var starting_rank: int = 1
@export var maximum_rank: int = 10

# cost
@export var stamina_cost: int = 0
@export var uses_per_day: int = -1 # -1 = unlimited
@export var charge_turns: int = 0

# difficulty check roll
@export var dc_stat: String
@export var dc_base: int = 12

# stat bonuses
@export var stat_deltas: Dictionary[String, int] # StatCalculator reads this per skill rank

@export var bonus_damage_per_rank: int = 0
@export var grants_crit: bool = false
