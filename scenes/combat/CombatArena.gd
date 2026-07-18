class_name CombatArena
extends MapData

@onready var battle_camera: Camera3D = $BattleCamera

func activate_camera() -> bool:
	if battle_camera == null:
		push_error("Combat arena requires a BattleCamera node.")
		return false
	battle_camera.make_current()
	return true

## Content-facing adapter for a battle scene. CombatPresenter never needs to
## know marker names or how an enemy scene is attached to the arena.
func spawn_enemy(enemy: EnemyInstance) -> Node3D:
	if enemy == null or enemy.enemy_data == null or enemy.enemy_data.enemy_scene == null:
		return null
	var marker := get_enemy_slot(enemy.formation_row, enemy.formation_slot)
	if marker == null:
		return null
	var visual := enemy.enemy_data.enemy_scene.instantiate() as Node3D
	if visual == null:
		return null
	marker.add_child(visual)
	visual.transform = Transform3D.IDENTITY
	return visual

func get_enemy_slot(row: int, slot: int) -> Marker3D:
	var marker_number := row * 3 + slot + 1
	var marker_path := "enemies/row_%d/EnemySlot_%d" % [row + 1, marker_number]
	var marker := get_node_or_null(marker_path) as Marker3D
	if marker == null:
		push_warning("Combat arena is missing enemy slot: %s" % marker_path)
	return marker
