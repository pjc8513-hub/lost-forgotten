class_name GearAttributeRoller
extends RefCounted

const ATTRIBUTE_CHANCE := 0.35
const SECOND_CATEGORY_CHANCE := 0.10

const WEAPON_TAGS := [
	{"name": "Vorpal", "weight": 5, "definition": "Increases critical hit threshold"},
	{"name": "Viper", "weight": 15, "definition": "Adds chance to poison target"},
	{"name": "Frost", "weight": 15, "definition": "Adds chance to freeze target"},
	{"name": "Crushing", "weight": 12, "definition": "Adds chance to stun target"},
	{"name": "Enhanced", "weight": 25, "definition": "Adds bonus damage"},
	{"name": "Blessed", "weight": 18, "definition": "Adds accuracy"},
	{"name": "Slaying", "weight": 3, "definition": "Bonus damage against dragons"},
	{"name": "Holy", "weight": 4, "definition": "Bonus damage against undead"},
	{"name": "Hunting", "weight": 8, "definition": "Bonus damage against beasts"},
]

const ARMOR_CLASS_TAGS := [
	{"name": "Hardened", "weight": 50, "armor_class_bonus": 1, "definition": "-1 AC"},
	{"name": "Magic", "weight": 25, "armor_class_bonus": 2, "definition": "-2 AC"},
	{"name": "Golem", "weight": 13, "armor_class_bonus": 3, "definition": "-3 AC"},
	{"name": "Dwarven", "weight": 8, "armor_class_bonus": 4, "definition": "-4 AC"},
	{"name": "Divine", "weight": 4, "armor_class_bonus": 5, "definition": "-5 AC"},
]

const ARMOR_UTILITY_TAGS := [
	{"name": "Nimble", "weight": 50, "dexterity_save_bonus": 1, "definition": "Bonus to avoiding trap damage"},
	{"name": "Fortitude", "weight": 50, "willpower_save_bonus": 1, "definition": "Bonus to resisting status effects"},
]

const ARMOR_RESIST_TAGS := [
	{"name": "Fire", "resistance": "fire", "definition": "Grants Fire resistance"},
	{"name": "Electric", "resistance": "electric", "definition": "Grants Electric resistance"},
	{"name": "Water", "resistance": "water", "definition": "Grants Water resistance"},
	{"name": "Earth", "resistance": "earth", "definition": "Grants Earth resistance"},
	{"name": "Dark", "resistance": "dark", "definition": "Grants Dark resistance"},
	{"name": "Light", "resistance": "light", "definition": "Grants Light resistance"},
	{"name": "Physical", "resistance": "physical", "definition": "Grants Physical resistance"},
]

const ACCESSORY_IMMUNITY_TAGS := [
	"Burn", "Freeze", "Paralyze", "Confusion", "Blind",
	"Poison", "Disease", "Fear", "Curse",
]

const ACCESSORY_STAT_TAGS := [
	{"name": "Might", "stat": "might_bonus", "min": 1, "max": 5, "definition": "Might bonus"},
	{"name": "Dexterity", "stat": "dexterity_bonus", "min": 1, "max": 5, "definition": "Dexterity bonus"},
	{"name": "Endurance", "stat": "endurance_bonus", "min": 1, "max": 5, "definition": "Endurance bonus"},
	{"name": "Wisdom", "stat": "wisdom_bonus", "min": 1, "max": 3, "definition": "Wisdom bonus"},
	{"name": "Willpower", "stat": "willpower_bonus", "min": 1, "max": 3, "definition": "Willpower bonus"},
	{"name": "Arcane", "stat": "magic_amp_bonus", "min": 1, "max": 5, "definition": "Bonus to Magic Amp"},
]

static func roll_for_item(instance: ItemInstance) -> void:
	if instance == null or instance.item_data == null:
		return
	if randf() > ATTRIBUTE_CHANCE:
		return

	var item := instance.item_data
	if item is WeaponData:
		_roll_weapon(instance)
	elif item is ArmorData:
		_roll_armor(instance)
	elif item.equip_slot == ItemData.Equip_Slot.RING or item.equip_slot == ItemData.Equip_Slot.AMULET:
		_roll_accessory(instance)

static func _roll_weapon(instance: ItemInstance) -> void:
	var tag: Dictionary = _weighted_pick(WEAPON_TAGS)
	var tag_name := String(tag.get("name", ""))
	instance.add_tag(tag_name)
	match tag_name:
		"Enhanced":
			instance.add_bonus("bonus_damage_bonus", randi_range(1, 8))
		"Blessed":
			instance.add_bonus("accuracy_bonus", randi_range(1, 3))

static func _roll_armor(instance: ItemInstance) -> void:
	var categories := ["defense", "resistance"]
	var first_category: String = categories.pick_random()
	_roll_armor_category(instance, first_category)
	if randf() <= SECOND_CATEGORY_CHANCE:
		_roll_armor_category(instance, "resistance" if first_category == "defense" else "defense")

static func _roll_armor_category(instance: ItemInstance, category: String) -> void:
	if category == "resistance":
		var resist_tag: Dictionary = ARMOR_RESIST_TAGS.pick_random()
		instance.add_tag(String(resist_tag["name"]))
		instance.add_resistance(String(resist_tag["resistance"]), 1)
		return

	var defense_pool := ARMOR_CLASS_TAGS + ARMOR_UTILITY_TAGS
	var tag: Dictionary = _weighted_pick(defense_pool)
	instance.add_tag(String(tag["name"]))
	for bonus_name in ["armor_class_bonus", "dexterity_save_bonus", "willpower_save_bonus"]:
		var value := int(tag.get(bonus_name, 0))
		if value != 0:
			instance.add_bonus(bonus_name, value)

static func _roll_accessory(instance: ItemInstance) -> void:
	var first_category := "immunity" if randf() < 0.5 else "stat"
	_roll_accessory_category(instance, first_category)
	if randf() <= SECOND_CATEGORY_CHANCE:
		_roll_accessory_category(instance, "stat" if first_category == "immunity" else "immunity")

static func _roll_accessory_category(instance: ItemInstance, category: String) -> void:
	if category == "immunity":
		var immunity: String = ACCESSORY_IMMUNITY_TAGS.pick_random()
		instance.add_tag(immunity)
		instance.status_immunities.append(StatusEffects.normalize_id(immunity))
		return

	var tag: Dictionary = ACCESSORY_STAT_TAGS.pick_random()
	var value := randi_range(int(tag["min"]), int(tag["max"]))
	instance.add_tag("%s +%d" % [tag["name"], value])
	instance.add_bonus(String(tag["stat"]), value)

static func _weighted_pick(entries: Array) -> Dictionary:
	var total_weight := 0
	for entry in entries:
		total_weight += int(entry.get("weight", 1))
	var roll := randi_range(1, total_weight)
	for entry in entries:
		roll -= int(entry.get("weight", 1))
		if roll <= 0:
			return entry
	return entries.back()

static func get_definition(tag_name: String) -> String:
	var base_name := tag_name.strip_edges()
	var bonus_separator := base_name.find(" +")
	if bonus_separator >= 0:
		base_name = base_name.left(bonus_separator)

	for pool in [WEAPON_TAGS, ARMOR_CLASS_TAGS, ARMOR_UTILITY_TAGS, ARMOR_RESIST_TAGS, ACCESSORY_STAT_TAGS]:
		for entry in pool:
			if String(entry.get("name", "")) == base_name:
				return String(entry.get("definition", ""))
	return ""
