extends ItemData
class_name ArmorData

enum Armor_Type {
	LIGHT,
	MEDIUM,
	HEAVY
}

@export var armor_class: int
@export var loot_table: LootManager.Loot_Table
@export var armor_type: Armor_Type
