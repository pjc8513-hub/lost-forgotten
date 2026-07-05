extends Resource
class_name ItemData

enum ItemType {
	EQUIPMENT,
	CONSUMABLE,
	QUEST,
	JUNK
}

enum Equip_Slot {
	NONE = 0,
	WEAPON = 1,
	ARMOR = 3,
	HELMET = 5,
	BOOTS = 6,
	GLOVES = 7,
	RING = 8,
	AMULET = 9
}

@export var item_id: String
@export var name: String
@export var icon: Texture2D
@export var item_type: ItemType
@export var is_stackable: bool = false
@export var sell_value: int = 0
@export var equip_slot: Equip_Slot
@export var description: String = ""
@export var status_immunities: Array[String] = []

var value: int:
	get:
		return sell_value
	set(val):
		sell_value = val

static func get_item(item_id: String) -> ItemData:
	return ItemDatabase.get_item(item_id)

static func get_equip_slot_key(equip_slot_value: int) -> String:
	for slot_key in Equip_Slot.keys():
		if int(Equip_Slot[slot_key]) == equip_slot_value:
			return String(slot_key)
	return "UNKNOWN"

static func get_equip_slot_display_name(equip_slot_value: int) -> String:
	var slot_key := get_equip_slot_key(equip_slot_value)
	if slot_key == "UNKNOWN":
		return "Unknown"
	return slot_key.to_lower().capitalize()
