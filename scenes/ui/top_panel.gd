extends Control


@onready var gold_label: Label = $PanelContainer/HBoxContainer/GoldLabel
@onready var food_label: Label = $PanelContainer/HBoxContainer/FoodLabel
@onready var time_label: Label = $PanelContainer/HBoxContainer/TimeLabel


func _ready() -> void:
	LootDistributor.gold_changed.connect(_on_gold_changed)
	LootDistributor.food_changed.connect(_on_food_changed)
	WorldManager.dungeon_time_changed.connect(_on_dungeon_time_changed)
	_on_gold_changed(LootDistributor.gold)
	_on_food_changed(LootDistributor.food)
	_on_dungeon_time_changed(WorldManager.dungeon_elapsed_time)


func _on_gold_changed(total: int) -> void:
	gold_label.text = str(total)


func _on_food_changed(total: int) -> void:
	food_label.text = str(total)


func _on_dungeon_time_changed(_elapsed_seconds: int) -> void:
	var time_of_day := WorldManager.get_time_of_day_seconds()
	var hour_24 := int(time_of_day / 3600.0) % 24
	var minute := int(time_of_day / 60.0) % 60
	var period := "AM" if hour_24 < 12 else "PM"
	var hour_12 := hour_24 % 12
	if hour_12 == 0:
		hour_12 = 12
	time_label.text = "%d:%02d %s" % [hour_12, minute, period]
