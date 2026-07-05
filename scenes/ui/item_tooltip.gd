# item_tooltip.gd
class_name ItemTooltip
extends PanelContainer

@onready var name_label: Label = get_node_or_null("VBoxContainer/NameLabel")
@onready var type_label: Label = get_node_or_null("VBoxContainer/TypeLabel")
@onready var bonuses_label: Label = get_node_or_null("VBoxContainer/BonusesLabel")
@onready var stat_label: Label = get_node_or_null("VBoxContainer/StatLabel")
@onready var definition_label: Label = get_node_or_null("VBoxContainer/DefinitionLabel")
@onready var description_label: Label = get_node_or_null("VBoxContainer/DescriptionLabel")

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	hide()

func display_item(inst: ItemInstance) -> void:
	if inst == null or inst.item_data == null:
		hide()
		return

	var item := inst.item_data
	_set_label(name_label, inst.get_display_name())
	_set_label(type_label, _get_type_text(item))
	_set_label(stat_label, _get_stat_text(inst))
	_set_label(bonuses_label, "\n".join(inst.tags))
	_set_label(definition_label, _get_definition_text(inst.tags))
	_set_label(description_label, _get_description_text(item))
	show()

func _process(_delta: float) -> void:
	if visible:
		_position_near_cursor()

func _set_label(label: Label, value: String) -> void:
	if label == null:
		return
	var text_value := value.strip_edges()
	label.text = text_value
	label.visible = not text_value.is_empty()

func _get_type_text(item: ItemData) -> String:
	if item is WeaponData:
		return "Weapon"
	if item is ArmorData:
		return "Armor"
	if item is ConsumableData:
		return "Consumable"
	if item.equip_slot == ItemData.Equip_Slot.RING:
		return "Ring"
	if item.equip_slot == ItemData.Equip_Slot.AMULET:
		return "Amulet"
	if item.item_type == ItemData.ItemType.QUEST:
		return "Quest Item"
	if item.item_type == ItemData.ItemType.JUNK:
		return "Junk"
	if item.item_type == ItemData.ItemType.EQUIPMENT:
		return ItemData.get_equip_slot_display_name(item.equip_slot)
	return ""

func _get_stat_text(inst: ItemInstance) -> String:
	var item := inst.item_data
	if item is WeaponData:
		var weapon := item as WeaponData
		var damage_bonus := weapon.bonus_damage_bonus + inst.get_bonus("bonus_damage_bonus")
		var bonus_text := " + %d" % damage_bonus if damage_bonus > 0 else ""
		return "%dd%d%s Damage" % [weapon.dice_rolls, weapon.dice_sides, bonus_text]
	if item is ArmorData:
		var armor := item as ArmorData
		var armor_class := armor.armor_class + armor.armor_class_bonus + inst.get_bonus("armor_class_bonus")
		return "%+d AC" % armor_class
	return ""

func _get_definition_text(tags: Array[String]) -> String:
	var definitions: Array[String] = []
	for tag in tags:
		var definition := GearAttributeRoller.get_definition(tag)
		if not definition.is_empty():
			definitions.append("%s: %s" % [tag, definition])
	return "\n".join(definitions)

func _get_description_text(item: ItemData) -> String:
	var lines: Array[String] = []
	if item is ConsumableData:
		var consumable := item as ConsumableData
		if consumable.hp_restore > 0:
			lines.append("Heals %d HP" % consumable.hp_restore)
		if consumable.mp_restore > 0:
			lines.append("Restores %d MP" % consumable.mp_restore)
	if not item.description.strip_edges().is_empty():
		lines.append(item.description)
	return "\n".join(lines)

func _position_near_cursor() -> void:
	var viewport_size := get_viewport_rect().size
	var desired_position := get_viewport().get_mouse_position() + Vector2(15, 15)
	var tooltip_size := size
	desired_position.x = clampf(desired_position.x, 0.0, maxf(0.0, viewport_size.x - tooltip_size.x))
	desired_position.y = clampf(desired_position.y, 0.0, maxf(0.0, viewport_size.y - tooltip_size.y))
	global_position = desired_position
