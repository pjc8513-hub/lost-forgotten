class_name CombatEncounter
extends Resource

var combat_scene: PackedScene
var enemy_rows: Array[Array] = []

func get_enemies() -> Array[EnemyInstance]:
	var result: Array[EnemyInstance] = []
	for row in enemy_rows:
		for enemy in row:
			if enemy is EnemyInstance:
				result.append(enemy)
	return result
