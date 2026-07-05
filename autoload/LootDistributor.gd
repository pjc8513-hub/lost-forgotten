# LootDistributor - autoload
# Handles distributing loot, not rolling it

extends Node

signal items_distributed(recipient: PartyMember, items: Array[ItemInstance])


func distribute(loot: Dictionary, recipient: PartyMember = null) -> Array[ItemInstance]:
	PartyManager.add_gold(int(loot.get("gold", 0)))
	PartyManager.add_food(int(loot.get("food", 0)))

	var distributed_items: Array[ItemInstance] = []
	if recipient != null:
		for value in loot.get("items", []):
			var item := value as ItemInstance
			if item != null and recipient.add_inventory_item(item):
				distributed_items.append(item)
	if not distributed_items.is_empty():
		items_distributed.emit(recipient, distributed_items)
	return distributed_items
