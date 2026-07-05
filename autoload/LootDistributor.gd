# LootDistributor - autoload
# Handles distributing loot, not rolling it

extends Node

signal gold_changed(total: int)
signal food_changed(total: int)
signal items_distributed(recipient: PartyMember, items: Array[ItemInstance])

var gold: int = 0
var food: int = 0


func distribute(loot: Dictionary, recipient: PartyMember = null) -> Array[ItemInstance]:
	add_gold(int(loot.get("gold", 0)))
	add_food(int(loot.get("food", 0)))

	var distributed_items: Array[ItemInstance] = []
	if recipient != null:
		for value in loot.get("items", []):
			var item := value as ItemInstance
			if item != null and recipient.add_inventory_item(item):
				distributed_items.append(item)
	if not distributed_items.is_empty():
		items_distributed.emit(recipient, distributed_items)
	return distributed_items


func add_gold(amount: int) -> void:
	if amount <= 0:
		return
	gold += amount
	gold_changed.emit(gold)


func add_food(amount: int) -> void:
	if amount <= 0:
		return
	food += amount
	food_changed.emit(food)
