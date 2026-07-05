# LootDistributor - autoload
# Handles distributing loot, not rolling it

extends Node

signal gold_changed(total: int)
signal food_changed(total: int)

var gold: int = 0
var food: int = 0


func distribute(loot: Dictionary) -> void:
	add_gold(int(loot.get("gold", 0)))
	add_food(int(loot.get("food", 0)))


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
