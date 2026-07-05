extends ItemData
class_name WeaponData

enum Weapon_Type{
	BLADE,
	BOW,
	POLEARM,
	AXE,
	CUDGEL,
	Staff
}

#enum Loot_Table { EQUIP_1, EQUIP_2, EQUIP_3 }

@export var dice_sides: int
@export var dice_rolls: int
@export var bonus_damage_bonus: int
@export var attack_speed: float
@export var loot_table: LootManager.Loot_Table
@export var is_ranged: bool = false
@export var has_reach: bool = false
@export var weapon_type: Weapon_Type
