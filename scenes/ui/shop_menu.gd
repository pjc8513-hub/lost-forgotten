extends Control

@onready var shop_list: ItemList = $MarginContainer/PanelContainer/HBoxContainer/TabContainer/Shop/ShopList
@onready var inventory_list: ItemList = $MarginContainer/PanelContainer/HBoxContainer/TabContainer/Inventory/InventoryList
@onready var buy_sell_button: Button = $MarginContainer/PanelContainer/HBoxContainer/OptionsContainer/MarginContainer/VBoxContainer/BuySellButton
@onready var close_button: Button = $MarginContainer/PanelContainer/HBoxContainer/OptionsContainer/MarginContainer/VBoxContainer/CloseButton

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.
