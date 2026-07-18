class_name CombatArena
extends MapData

@onready var battle_camera: Camera3D = $BattleCamera

const ROW_PIXEL_SIZES := [0.0035, 0.0045, 0.0055]
const ROW_FADE_DURATION := 0.18

var _enemy_row_tween: Tween
var _enemy_row_transition_id := 0

func _exit_tree() -> void:
	if _enemy_row_tween != null and _enemy_row_tween.is_valid():
		_enemy_row_tween.kill()
	_enemy_row_tween = null

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
	_apply_row_pixel_size(visual, enemy.formation_row)
	return visual

## Removes empty gaps in the enemy formation after a row has been defeated.
## The EnemyInstance rows are updated before the visual transition starts so
## targeting can use the new formation immediately.
func compact_enemy_rows(enemies: Array[EnemyInstance], enemy_visuals: Dictionary) -> void:
	var occupied_rows: Array[int] = []
	for enemy in enemies:
		if enemy != null and enemy.is_alive() and not enemy.has_fled and enemy.formation_row not in occupied_rows:
			occupied_rows.append(enemy.formation_row)
	occupied_rows.sort()

	var row_map: Dictionary = {}
	for new_row in occupied_rows.size():
		row_map[occupied_rows[new_row]] = new_row

	var shifted_enemies: Array[EnemyInstance] = []
	var shifted_visuals: Array[Node3D] = []
	for enemy in enemies:
		if enemy == null or not enemy.is_alive() or enemy.has_fled:
			continue
		var new_row: int = row_map[enemy.formation_row]
		if enemy.formation_row == new_row:
			continue
		enemy.formation_row = new_row
		var visual := enemy_visuals.get(enemy) as Node3D
		if visual != null and is_instance_valid(visual):
			shifted_enemies.append(enemy)
			shifted_visuals.append(visual)

	if shifted_enemies.is_empty():
		return

	_enemy_row_transition_id += 1
	if _enemy_row_tween != null and _enemy_row_tween.is_valid():
		_enemy_row_tween.kill()

	var transition_id := _enemy_row_transition_id
	var fade_out := create_tween()
	_enemy_row_tween = fade_out
	fade_out.set_parallel(true)
	for visual in shifted_visuals:
		_set_visual_transparency(visual, 0.0)
		fade_out.tween_method(_set_visual_transparency_for_tween.bind(visual), 0.0, 1.0, ROW_FADE_DURATION)
	fade_out.set_parallel(false)
	fade_out.tween_callback(_complete_enemy_row_transition.bind(transition_id, shifted_enemies, shifted_visuals))

func _complete_enemy_row_transition(
	transition_id: int,
	shifted_enemies: Array[EnemyInstance],
	shifted_visuals: Array[Node3D]
) -> void:
	if transition_id != _enemy_row_transition_id:
		return
	_enemy_row_tween = null
	for index in shifted_enemies.size():
		var enemy := shifted_enemies[index]
		var visual := shifted_visuals[index] if index < shifted_visuals.size() else null
		if visual == null or not is_instance_valid(visual):
			continue
		var marker := get_enemy_slot(enemy.formation_row, enemy.formation_slot)
		if marker == null:
			continue
		visual.reparent(marker, false)
		visual.transform = Transform3D.IDENTITY
		visual.visible = true
		_apply_row_pixel_size(visual, enemy.formation_row)
		_set_visual_transparency(visual, 1.0)

	var fade_in := create_tween()
	_enemy_row_tween = fade_in
	fade_in.set_parallel(true)
	for visual in shifted_visuals:
		if visual != null and is_instance_valid(visual):
			fade_in.tween_method(_set_visual_transparency_for_tween.bind(visual), 1.0, 0.0, ROW_FADE_DURATION)
	fade_in.set_parallel(false)
	fade_in.finished.connect(_clear_enemy_row_tween.bind(fade_in))

func _clear_enemy_row_tween(tween: Tween) -> void:
	if _enemy_row_tween == tween:
		_enemy_row_tween = null

func _apply_row_pixel_size(visual: Node3D, row: int) -> void:
	var pixel_size: float = ROW_PIXEL_SIZES[clampi(row, 0, ROW_PIXEL_SIZES.size() - 1)]
	_set_sprite_pixel_size(visual, pixel_size)

func _set_sprite_pixel_size(node: Node, pixel_size: float) -> void:
	if node is Sprite3D:
		(node as Sprite3D).pixel_size = pixel_size
	for child in node.get_children():
		_set_sprite_pixel_size(child, pixel_size)

func _set_visual_transparency(visual: Node3D, transparency: float) -> void:
	if visual == null or not is_instance_valid(visual):
		return
	_set_node_transparency(visual, transparency)

func _set_visual_transparency_for_tween(transparency: float, visual: Node3D) -> void:
	_set_visual_transparency(visual, transparency)

func _set_node_transparency(node: Node, transparency: float) -> void:
	if node is GeometryInstance3D:
		(node as GeometryInstance3D).transparency = transparency
	for child in node.get_children():
		_set_node_transparency(child, transparency)

func get_enemy_slot(row: int, slot: int) -> Marker3D:
	var marker_number := row * 3 + slot + 1
	var marker_path := "enemies/row_%d/EnemySlot_%d" % [row + 1, marker_number]
	var marker := get_node_or_null(marker_path) as Marker3D
	if marker == null:
		push_warning("Combat arena is missing enemy slot: %s" % marker_path)
	return marker
