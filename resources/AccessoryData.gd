extends ItemData
class_name AccessoryData

enum Accessory_Type {
	Ring,
	AMULET,
	BRACELET
}

@export var armor_class: int=0
@export var loot_table: LootManager.Loot_Table
@export var armor_type: Accessory_Type
