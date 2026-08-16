# res://autoloads/LootManager.gd
extends Node

enum Loot_Table {
	EQUIP_1, EQUIP_2, EQUIP_3,
	ITEM_1, ITEM_2, ITEM_3
	# Later: WEAPON_1, ARMOR_1, ACCESSORY_1, etc
}

# Each table maps to actual items. Weight = drop chance if you want.
# For now: just arrays of item_id strings or Resource paths
const LOOT_POOLS = {
	Loot_Table.EQUIP_1: {
		"items": ["RustyDagger", "Club", "Staff", "ShortSword", "Spear", "HandAxe", "SimpleBow", "ClothRobe", "LeatherArmor", "RingMail", "RustyPlate", "LeatherCap"],
		"rolls": 1, # how many times to roll this table when selected
		"chance": 1.0 # 100% chance to get something if this table is rolled
	},
	Loot_Table.EQUIP_2: {
		"items": ["IronSword", "GoldRing", "Lance", "Flail", "BattleAxe", "BreastPlate", "ChainMail", "SteelHelm"],
		"rolls": 1,
		"chance": 0.75
	},
	Loot_Table.EQUIP_3: {
		"items": ["MithrilBlade", "PlateArmor", "DragonHelm"],
		"rolls": 1,
		"chance": 0.5
	},
	Loot_Table.ITEM_1: {
		"items": ["minor_health_potion"],
		"rolls": 2, # tier 1 items drop more often
		"chance": 1.0
	},
	Loot_Table.ITEM_2: {
		"items": ["health_potion", "antidote", "resurrection_scroll"],
		"rolls": 2,
		"chance": 0.8
	},
	Loot_Table.ITEM_3: {
		"items": ["elixir", "phoenix_down", "scroll_teleport"],
		"rolls": 1,
		"chance": 0.6
	}
}

# Main function both chests and enemies call
func roll_loot(tables: Array[Loot_Table], bonus_luck: int = 0) -> Array[String]:
	var results: Array[String] = []
	
	if tables.is_empty():
		return results
	
	for table in tables:
		if not LOOT_POOLS.has(table):
			push_warning("LootManager: No pool defined for %s" % Loot_Table.keys()[table])
			continue
			
		var pool = LOOT_POOLS[table]
		var chance: float = pool.chance + (bonus_luck * 0.05) # +5% per luck
		chance = clampf(chance, 0.0, 1.0)
		
		for i in pool.rolls:
			if randf() <= chance:
				var item = pool.items.pick_random()
				results.append(item)
				
	return results

# Helper if you want to convert item_id -> ItemData resource later
func get_item_data(item_id: String) -> Resource:
	var item_data = ItemDatabase.get_item(item_id)
	if item_data != null:
		return item_data
	push_warning("LootManager: ItemData not found: %s" % item_id)
	return null


func create_item_instance(item_id: String) -> ItemInstance:
	var item_data := get_item_data(item_id)
	if item_data == null:
		return null

	var item_instance := ItemInstance.new()
	item_instance.item_data = item_data

	GearAttributeRoller.roll_for_item(item_instance)
	return item_instance


func generate_loot(tables: Array[Loot_Table], bonus_luck: int = 0) -> Array[ItemInstance]:
	var instances: Array[ItemInstance] = []
	for item_id in roll_loot(tables, bonus_luck):
		var instance := create_item_instance(item_id)
		if instance != null:
			instances.append(instance)
	return instances

# Debug helper
func table_name(table: Loot_Table) -> String:
	return Loot_Table.keys()[table]
