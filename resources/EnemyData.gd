class_name EnemyData
extends Resource

enum EnemyType {
	NONE = -1,
	BEAST = 0,
	HUMANOID = 1,
	UNDEAD = 2,
	DEMON = 3,
	DRAGON = 4,
	ELEMENTAL = 5,
}

@export_group("Identity")
@export var enemy_id: StringName = ""
@export var display_name: String = ""
@export var sprite_texture: Texture2D
@export var enemytype: EnemyType = EnemyType.NONE
@export var enemy_scene: PackedScene

@export_group("rewards")
@export var xp: int = 20
@export var gold: int = 10
@export var loot_probability: float = 0.03 # 3%
@export var loot_table: LootManager.Loot_Table = LootManager.Loot_Table.ITEM_1

@export_group("Base Stats")
@export var base_strength: int = 3
@export var base_endurance: int = 3
@export var base_wisdom: int = 3
@export var base_dexterity: int = 3
@export var base_piety: int = 0
@export var base_willpower: int = 0
@export var damage_dice_rolls: int = 1
@export var damage_dice_sides: int = 3
@export var hp_base: int = 5

@export_group("bonuses and penalties")
@export var ac_bonus: int = 0          # Flat class AC modifier (negative = better in old-school convention)
@export var accuracy_bonus: int = 0
@export var initiative_bonus: int = 0
@export var bonus_damage_base: int = 0
@export var magic_amp_base: int = 0

@export_group("Resistances")
@export var resist_fire: bool = false
@export var resist_water: bool = false
@export var resist_earth: bool = false
@export var resist_air: bool = false
@export var resist_physical: bool = false
@export var resist_light: bool = false
@export var resist_dark: bool = false
@export var resist_spirit: bool = false

@export_group("skills and behavior")
@export var skills: Array[StringName] #skill ids
@export var flee_chance: float = 0.05 # starts at 5%

@export_group("Starting Status Effects")
@export var starting_status_effects: Array[int]


# helper functions
static func get_display_name_for(enemy_type_value: EnemyType) -> String:
	for key in EnemyType.keys():
		if EnemyType[key] == enemy_type_value:
			return String(key).capitalize()
	return "None"
