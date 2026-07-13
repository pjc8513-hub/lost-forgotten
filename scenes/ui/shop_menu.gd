class_name ShopMenu
extends Control

const SHOP_TAB := 0
const INVENTORY_TAB := 1

@onready var tab_container: TabContainer = $MarginContainer/PanelContainer/HBoxContainer/TabContainer
@onready var shop_list: ItemList = $MarginContainer/PanelContainer/HBoxContainer/TabContainer/Shop/ShopList
@onready var inventory_list: ItemList = $MarginContainer/PanelContainer/HBoxContainer/TabContainer/Inventory/InventoryList
@onready var buy_sell_button: Button = $MarginContainer/PanelContainer/HBoxContainer/OptionsContainer/MarginContainer/VBoxContainer/BuySellButton
@onready var close_button: Button = $MarginContainer/PanelContainer/HBoxContainer/OptionsContainer/MarginContainer/VBoxContainer/CloseButton
@onready var next_button: Button = $MarginContainer/PanelContainer/HBoxContainer/OptionsContainer/MarginContainer/VBoxContainer/NextButton
@onready var previous_button: Button = $MarginContainer/PanelContainer/HBoxContainer/OptionsContainer/MarginContainer/VBoxContainer/PreviousButton
@onready var character_name: Label = $MarginContainer/PanelContainer/HBoxContainer/OptionsContainer/MarginContainer/CharacterName

var _shop_npc: NPCComponent
var _shop_items: Array[ItemData] = []
var _inventory_items: Array[ItemInstance] = []

func _ready() -> void:
	hide()
	tab_container.tab_changed.connect(_on_tab_changed)
	shop_list.item_selected.connect(_on_shop_item_selected)
	shop_list.item_activated.connect(_on_shop_item_activated)
	inventory_list.item_selected.connect(_on_inventory_item_selected)
	inventory_list.item_activated.connect(_on_inventory_item_activated)
	buy_sell_button.pressed.connect(_on_buy_sell_pressed)
	close_button.pressed.connect(close)
	PartyManager.selected_party_member_changed.connect(_on_selected_party_member_changed)
	PartyManager.gold_changed.connect(_on_gold_changed)

func open(npc: NPCComponent) -> void:
	if npc == null:
		return
	_shop_npc = npc
	tab_container.current_tab = SHOP_TAB
	show()
	_refresh()
	close_button.grab_focus()

func close() -> void:
	hide()
	_shop_npc = null
	_shop_items.clear()
	_inventory_items.clear()
	shop_list.clear()
	inventory_list.clear()

func _input(event: InputEvent) -> void:
	if not visible or not event is InputEventKey:
		return
	if event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()
		return
	for action in [&"ui_up", &"ui_down", &"ui_left", &"ui_right", &"interact"]:
		if event.is_action(action):
			get_viewport().set_input_as_handled()
			return

func _refresh() -> void:
	_refresh_shop_list()
	_refresh_inventory_list()
	_update_action_button()

func _refresh_shop_list() -> void:
	_shop_items.clear()
	shop_list.clear()
	if _shop_npc == null:
		return
	for item in _shop_npc.shop_items:
		if item == null:
			continue
		var price := _get_buy_price(item)
		var item_index := shop_list.add_item("%s - %d gold" % [item.name, price], item.icon)
		shop_list.set_item_tooltip(item_index, _get_item_tooltip(item, price, "Buy"))
		shop_list.set_item_disabled(item_index, PartyManager.selected_party_member == null or PartyManager.gold < price)
		shop_list.set_item_metadata(item_index, item)
		_shop_items.append(item)
	if _shop_items.is_empty():
		shop_list.add_item("No items for sale")
		shop_list.set_item_disabled(0, true)

func _refresh_inventory_list() -> void:
	_inventory_items.clear()
	inventory_list.clear()
	var member := PartyManager.selected_party_member
	if member == null:
		inventory_list.add_item("No member selected")
		inventory_list.set_item_disabled(0, true)
		return
	for item_instance in member.inventory:
		if item_instance == null or item_instance.item_data == null:
			continue
		var item := item_instance.item_data
		var price := _get_sell_price(item)
		var label := "%s - %d gold" % [item_instance.get_display_name(), price]
		if item_instance.is_equipped:
			label += " (equipped)"
		var item_index := inventory_list.add_item(label, item.icon)
		inventory_list.set_item_tooltip(item_index, _get_item_tooltip(item, price, "Sell"))
		inventory_list.set_item_disabled(item_index, item_instance.is_equipped or item.item_type == ItemData.ItemType.QUEST)
		inventory_list.set_item_metadata(item_index, item_instance)
		_inventory_items.append(item_instance)
	if _inventory_items.is_empty():
		inventory_list.add_item("No items to sell")
		inventory_list.set_item_disabled(0, true)

func _update_action_button() -> void:
	if tab_container.current_tab == SHOP_TAB:
		var item := _get_selected_shop_item()
		var price := _get_buy_price(item)
		buy_sell_button.text = "Buy"
		buy_sell_button.disabled = item == null or PartyManager.selected_party_member == null or PartyManager.gold < price
	else:
		var item_instance := _get_selected_inventory_item()
		buy_sell_button.text = "Sell"
		buy_sell_button.disabled = item_instance == null \
				or item_instance.item_data == null \
				or item_instance.is_equipped \
				or item_instance.item_data.item_type == ItemData.ItemType.QUEST

func _buy_selected_item() -> void:
	var member := PartyManager.selected_party_member
	var item := _get_selected_shop_item()
	if member == null or item == null:
		_refresh()
		return
	var price := _get_buy_price(item)
	if not PartyManager.spend_gold(price):
		MapManager.request_alert("Not enough gold.")
		_refresh()
		return
	var item_instance := ItemInstance.new()
	item_instance.item_data = item
	if not member.add_inventory_item(item_instance):
		PartyManager.add_gold(price)
		MapManager.request_alert("Could not add item to inventory.")
	_refresh()

func _sell_selected_item() -> void:
	var member := PartyManager.selected_party_member
	var item_instance := _get_selected_inventory_item()
	if member == null or item_instance == null or item_instance.item_data == null:
		_refresh()
		return
	if item_instance.is_equipped:
		MapManager.request_alert("Unequip that item before selling it.")
		_refresh()
		return
	if item_instance.item_data.item_type == ItemData.ItemType.QUEST:
		MapManager.request_alert("Quest items cannot be sold.")
		_refresh()
		return
	var price := _get_sell_price(item_instance.item_data)
	if not member.drop_inventory_item(item_instance):
		_refresh()
		return
	PartyManager.add_gold(price)
	_refresh()

func _get_selected_shop_item() -> ItemData:
	var selected := shop_list.get_selected_items()
	if selected.is_empty():
		return null
	return shop_list.get_item_metadata(selected[0]) as ItemData

func _get_selected_inventory_item() -> ItemInstance:
	var selected := inventory_list.get_selected_items()
	if selected.is_empty():
		return null
	return inventory_list.get_item_metadata(selected[0]) as ItemInstance

func _get_buy_price(item: ItemData) -> int:
	if item == null:
		return 0
	var markup := maxf(_shop_npc.price_markup if _shop_npc != null else 0.0, 0.0)
	return maxi(int(ceil(float(item.value) * (1.0 + markup))), 0)

func _get_sell_price(item: ItemData) -> int:
	return maxi(item.value if item != null else 0, 0)

func _get_item_tooltip(item: ItemData, price: int, action: String) -> String:
	if item == null:
		return ""
	var lines: Array[String] = [
		item.name,
		_get_item_type_text(item),
		"%s price: %d gold" % [action, price],
	]
	if item is WeaponData:
		var weapon := item as WeaponData
		lines.append("Damage: %dd%d" % [weapon.dice_rolls, weapon.dice_sides])
	elif item is ArmorData:
		var armor := item as ArmorData
		lines.append("AC: %+d" % (armor.armor_class + armor.armor_class_bonus))
	elif item is ConsumableData:
		lines.append_array(_get_consumable_tooltip_lines(item as ConsumableData))
	if not item.description.strip_edges().is_empty():
		lines.append(item.description)
	return "\n".join(lines)

func _get_consumable_tooltip_lines(item: ConsumableData) -> Array[String]:
	var lines: Array[String] = []
	if item.hp_restore > 0:
		lines.append("Heals %d HP" % item.hp_restore)
	if item.mp_restore > 0:
		lines.append("Restores %d MP" % item.mp_restore)
	if not item.remove_status.is_empty():
		lines.append("Removes: %s" % ", ".join(item.remove_status))
	return lines

func _get_item_type_text(item: ItemData) -> String:
	if item is WeaponData:
		return "Weapon"
	if item is ArmorData:
		return "Armor"
	if item is ConsumableData:
		return "Consumable"
	if item.item_type == ItemData.ItemType.QUEST:
		return "Quest Item"
	if item.item_type == ItemData.ItemType.JUNK:
		return "Junk"
	if item.item_type == ItemData.ItemType.EQUIPMENT:
		return ItemData.get_equip_slot_display_name(item.equip_slot)
	return ""

func _on_buy_sell_pressed() -> void:
	if tab_container.current_tab == SHOP_TAB:
		_buy_selected_item()
	else:
		_sell_selected_item()

func _on_tab_changed(_tab: int) -> void:
	_update_action_button()

func _on_shop_item_selected(_index: int) -> void:
	_update_action_button()

func _on_inventory_item_selected(_index: int) -> void:
	_update_action_button()

func _on_shop_item_activated(_index: int) -> void:
	if tab_container.current_tab == SHOP_TAB and not buy_sell_button.disabled:
		_buy_selected_item()

func _on_inventory_item_activated(_index: int) -> void:
	if tab_container.current_tab == INVENTORY_TAB and not buy_sell_button.disabled:
		_sell_selected_item()

func _on_selected_party_member_changed(_index: int, _member: PartyMember) -> void:
	if visible:
		_refresh()

func _on_gold_changed(_total: int) -> void:
	if visible:
		_refresh()
