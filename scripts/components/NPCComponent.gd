class_name npc_component
extends Node

enum Shop_Type {
	NONE = -1,
	EQUIPMENT_SHOP = 0,
	CONSUMABLE_SHOP = 1,
	INN = 2,
	TEMPLE = 3,
	TRAINER = 4
}

@export_category("dialogue")

@export_category("quests")

@export_category("shop")
@export var shop_type: Shop_Type = Shop_Type.NONE

@export_category("MapExit")
@export_file("*.tscn") var destination_map: String
@export var destination_spawn_id: StringName
