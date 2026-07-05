class_name InventoryItemList
extends ItemList

signal context_menu_requested(item: ItemInstance, screen_position: Vector2i)
signal equip_requested(item: ItemInstance)

const ITEM_TOOLTIP_SCENE = preload ("res://scenes/ui/item_tooltip.tscn")
var item_tooltip: ItemTooltip
var hovered_item_index := -1
@onready var item_list: ItemList = $"."

func _ready() -> void:
	item_tooltip = ITEM_TOOLTIP_SCENE.instantiate()
	var tooltip_host: Node = self
	while tooltip_host.get_parent() != null and not tooltip_host is InventoryMenu:
		tooltip_host = tooltip_host.get_parent()
	tooltip_host.add_child.call_deferred(item_tooltip)
	item_tooltip.z_index = 100
	
func set_inventory(items: Array[ItemInstance]):
	_hide_item_tooltip()
	item_list.clear()

	var sorted = sort_inventory(items)

	for inst in sorted:
		if inst == null or inst.item_data == null:
			continue
			
		var item = inst.item_data
		var equip_slot_string = _equip_slot_to_string(item.equip_slot)
		var inventory_name = "%s: %s" % [equip_slot_string, inst.get_display_name()]
		var idx = item_list.add_item(inventory_name, item.icon)
		item_list.set_item_tooltip_enabled(idx, false)

		if inst.is_equipped:
			item_list.set_item_custom_bg_color(idx, Color(0.5, 0.1, 0.1))

		if inst.is_marked_junk:
			item_list.set_item_custom_fg_color(idx, Color(0.5, 0.5, 0.5))

		item_list.set_item_metadata(idx, inst)
		
func get_sort_value(inst: ItemInstance) -> int:
	if inst == null or inst.item_data == null:
		return 999
		
	var item := inst.item_data

	# Junk always at bottom
	if inst.is_marked_junk:
		return 100

	match item.item_type:
		ItemData.ItemType.EQUIPMENT:
			return 0 if inst.is_equipped else 1
		ItemData.ItemType.CONSUMABLE:
			return 2
		ItemData.ItemType.QUEST:
			return 3
		ItemData.ItemType.JUNK:
			return 100

	return 999

func sort_inventory(items: Array[ItemInstance]) -> Array:
	var sorted = items.duplicate()

	sorted.sort_custom(func(a: ItemInstance, b: ItemInstance):
		return get_sort_value(a) < get_sort_value(b)
	)

	return sorted
	
func _equip_slot_to_string(equip_slot: ItemData.Equip_Slot) -> String:
	return ItemData.get_equip_slot_display_name(equip_slot)
	
func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_update_item_tooltip(event.position)
		return
		
func _update_item_tooltip(mouse_position: Vector2) -> void:
	var idx := item_list.get_item_at_position(mouse_position, true)
	if idx == hovered_item_index:
		return
	hovered_item_index = idx
	if idx < 0:
		_hide_item_tooltip()
		return
	var inst := item_list.get_item_metadata(idx) as ItemInstance
	if inst == null:
		_hide_item_tooltip()
		return
	if is_instance_valid(item_tooltip):
		item_tooltip.display_item(inst)
		
func _on_mouse_exited() -> void:
	_hide_item_tooltip()

func _hide_item_tooltip() -> void:
	hovered_item_index = -1
	if is_instance_valid(item_tooltip):
		item_tooltip.hide()


func _on_item_clicked(index: int, at_position: Vector2, mouse_button_index: int) -> void:
	if mouse_button_index != MOUSE_BUTTON_RIGHT:
		return
	var inst := get_item_metadata(index) as ItemInstance
	if inst != null:
		var screen_position := Vector2i(get_screen_transform() * at_position)
		context_menu_requested.emit(inst, screen_position)


func _on_item_activated(index: int) -> void:
	var inst := get_item_metadata(index) as ItemInstance
	if inst != null and inst.item_data != null \
			and inst.item_data.item_type == ItemData.ItemType.EQUIPMENT:
		equip_requested.emit(inst)
