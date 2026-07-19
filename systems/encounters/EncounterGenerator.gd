class_name EncounterGenerator
extends RefCounted

var _catalog: EnemyCatalog

func _init(catalog: EnemyCatalog) -> void:
	_catalog = catalog

func generate(map_data: MapData) -> CombatEncounter:
	if map_data == null or map_data.combat_scene == null or map_data.enemy_ids.is_empty():
		return null
	var available: Array[EnemyData] = []
	for enemy_id in map_data.enemy_ids:
		var data := _catalog.get_enemy(enemy_id)
		if data != null:
			available.append(data)
		else:
			push_warning("Map references unknown enemy id: %s" % enemy_id)
	if available.is_empty():
		return null
	var encounter := CombatEncounter.new()
	encounter.combat_scene = map_data.combat_scene
	var row_count := randi_range(1, clampi(map_data.maximum_enemy_rows, 1, 3))
	for row_index in row_count:
		var row: Array[EnemyInstance] = []
		var enemy_count := randi_range(1, clampi(map_data.maximum_enemies_per_row, 1, 3))
		var template: EnemyData = available.pick_random()
		for slot_index in enemy_count:
			row.append(EnemyInstance.create(template, row_index, slot_index))
		encounter.enemy_rows.append(row)
	return encounter
