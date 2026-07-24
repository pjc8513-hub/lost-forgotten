class_name CombatArena
extends MapData

@onready var battle_camera: Camera3D = $BattleCamera
@onready var party_damage_overlay := get_node_or_null("canvaslayer/CanvasLayer/ColorRect") as ColorRect

const ROW_PIXEL_SIZES := [0.0044, 0.0045, 0.0045]
const ROW_SPACING := [1.2, 0.95, 0.8]
const ROW_ADVANCE_DURATION := 0.32
const CAMERA_ZOOM_FOV := 33.0
const CAMERA_TWEEN_DURATION := 0.16
const PARTY_DAMAGE_EFFECT_TIME := 0.42
const PARTY_CRITICAL_EFFECT_TIME := 0.62

var _enemy_row_tween: Tween
var _camera_focus_transform: Transform3D
var _camera_focus_fov := 0.0
var _camera_is_focused := false
var _camera_tween: Tween
var _party_damage_material: ShaderMaterial
var _party_damage_tween: Tween
var _camera_shake_tween: Tween
var _camera_shake_base_h_offset := 0.0
var _camera_shake_base_v_offset := 0.0
var _camera_shake_intensity := 0.0

func _ready() -> void:
	if party_damage_overlay != null and party_damage_overlay.material is ShaderMaterial:
		party_damage_overlay.material = party_damage_overlay.material.duplicate() as Material
		_party_damage_material = party_damage_overlay.material as ShaderMaterial
		_party_damage_material.set_shader_parameter("effect_strength", 0.0)

func _exit_tree() -> void:
	if _enemy_row_tween != null and _enemy_row_tween.is_valid():
		_enemy_row_tween.kill()
	_enemy_row_tween = null
	if _camera_tween != null and _camera_tween.is_valid():
		_camera_tween.kill()
	_camera_tween = null
	if _party_damage_tween != null and _party_damage_tween.is_valid():
		_party_damage_tween.kill()
	_party_damage_tween = null
	if _camera_shake_tween != null and _camera_shake_tween.is_valid():
		_camera_shake_tween.kill()
		_camera_shake_tween = null
	if battle_camera != null:
		battle_camera.h_offset = _camera_shake_base_h_offset
		battle_camera.v_offset = _camera_shake_base_v_offset
	if _party_damage_material != null:
		_party_damage_material.set_shader_parameter("effect_strength", 0.0)

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
	if visual.has_method("set_enemy_instance"):
		visual.set_enemy_instance(enemy)
	_apply_row_scale(visual, enemy.formation_row)
	return visual

## Centers each occupied row independently and gives the front row the widest
## silhouette. Logical formation slots are left untouched.
func layout_enemy_rows(
	enemies: Array[EnemyInstance],
	enemy_visuals: Dictionary,
	animate := false
) -> void:
	if _enemy_row_tween != null and _enemy_row_tween.is_valid():
		_enemy_row_tween.kill()
	_enemy_row_tween = null

	var enemies_by_row: Dictionary = {}
	for enemy in enemies:
		if enemy == null or not enemy.is_alive() or enemy.has_fled:
			continue
		if not enemies_by_row.has(enemy.formation_row):
			enemies_by_row[enemy.formation_row] = []
		(enemies_by_row[enemy.formation_row] as Array).append(enemy)

	var targets: Dictionary = {}
	for raw_row in enemies_by_row:
		var row := int(raw_row)
		var row_enemies: Array = enemies_by_row[raw_row]
		row_enemies.sort_custom(_sort_enemies_by_formation_slot)
		var origin := _get_row_origin(row)
		var spacing: float = ROW_SPACING[clampi(row, 0, ROW_SPACING.size() - 1)]
		var midpoint := float(row_enemies.size() - 1) * 0.5
		for index in row_enemies.size():
			var enemy := row_enemies[index] as EnemyInstance
			var visual := enemy_visuals.get(enemy) as Node3D
			if visual == null or not is_instance_valid(visual):
				continue
			var horizontal_offset := (float(index) - midpoint) * spacing
			targets[visual] = origin + Vector3(-horizontal_offset, 0.0, 0.0)
			_apply_row_scale(visual, row, animate)

	if not animate:
		for visual in targets:
			(visual as Node3D).global_position = targets[visual]
		return

	_enemy_row_tween = create_tween()
	_enemy_row_tween.set_parallel(true)
	_enemy_row_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	for visual in targets:
		_enemy_row_tween.tween_property(
			visual,
			"global_position",
			targets[visual],
			ROW_ADVANCE_DURATION
		)
	_enemy_row_tween.set_parallel(false)
	_enemy_row_tween.finished.connect(_clear_enemy_row_tween.bind(_enemy_row_tween))

func _sort_enemies_by_formation_slot(left: EnemyInstance, right: EnemyInstance) -> bool:
	return left.formation_slot < right.formation_slot

func _get_row_origin(row: int) -> Vector3:
	var origin := Vector3.ZERO
	var marker_count := 0
	for slot in 3:
		var marker := get_enemy_slot(row, slot)
		if marker == null:
			continue
		origin += marker.global_position
		marker_count += 1
	return origin / float(marker_count) if marker_count > 0 else global_position

func preview_enemy_row(row: int, enemy_visuals: Dictionary) -> void:
	for raw_enemy in enemy_visuals:
		var enemy := raw_enemy as EnemyInstance
		var visual := enemy_visuals[raw_enemy] as Node3D
		if enemy == null or visual == null or not is_instance_valid(visual):
			continue
		if not enemy.is_alive() or enemy.has_fled:
			continue
		_set_visual_row_preview(visual, enemy.formation_row == row, true)

func clear_enemy_row_preview(enemy_visuals: Dictionary) -> void:
	for visual_value in enemy_visuals.values():
		var visual := visual_value as Node3D
		if visual != null and is_instance_valid(visual):
			_set_visual_row_preview(visual, false, false)

func _set_visual_row_preview(visual: Node3D, selected: bool, preview_active: bool) -> void:
	if visual.has_method("set_row_preview"):
		visual.set_row_preview(selected, preview_active)
		return
	_set_sprite_modulate(
		visual,
		Color(1.0, 0.9, 0.7, 1.0) if selected else (
			Color(0.42, 0.44, 0.5, 1.0) if preview_active else Color.WHITE
		)
	)

func _set_sprite_modulate(node: Node, color: Color) -> void:
	if node is Sprite3D:
		(node as Sprite3D).modulate = color
	for child in node.get_children():
		_set_sprite_modulate(child, color)

func focus_camera_on_enemy(visual: Node3D) -> Tween:
	if battle_camera == null or visual == null or not is_instance_valid(visual):
		return null
	if not _camera_is_focused:
		_camera_focus_transform = battle_camera.global_transform
		_camera_focus_fov = battle_camera.fov
		_camera_is_focused = true
	battle_camera.look_at(visual.global_position + Vector3.UP * 0.4, Vector3.UP)
	battle_camera.rotate_object_local(Vector3.RIGHT, deg_to_rad(-10))
	if _camera_tween != null and _camera_tween.is_valid():
		_camera_tween.kill()
	_camera_tween = create_tween()
	_camera_tween.tween_property(battle_camera, "fov", CAMERA_ZOOM_FOV, CAMERA_TWEEN_DURATION)
	return _camera_tween

func restore_camera() -> Tween:
	if battle_camera == null or not _camera_is_focused:
		return null
	if _camera_tween != null and _camera_tween.is_valid():
		_camera_tween.kill()
	_camera_tween = create_tween()
	_camera_tween.set_parallel(true)
	_camera_tween.tween_property(battle_camera, "global_transform", _camera_focus_transform, CAMERA_TWEEN_DURATION)
	_camera_tween.tween_property(battle_camera, "fov", _camera_focus_fov, CAMERA_TWEEN_DURATION)
	_camera_tween.set_parallel(false)
	_camera_tween.finished.connect(_clear_camera_focus.bind(_camera_tween))
	return _camera_tween

func _clear_camera_focus(tween: Tween) -> void:
	if _camera_tween != tween:
		return
	_camera_tween = null
	_camera_is_focused = false

func play_party_damage_effect(critical: bool) -> float:
	if _party_damage_material == null:
		return 0.0
	if _party_damage_tween != null and _party_damage_tween.is_valid():
		_party_damage_tween.kill()
	var duration := PARTY_CRITICAL_EFFECT_TIME if critical else PARTY_DAMAGE_EFFECT_TIME
	_party_damage_material.set_shader_parameter("effect_progress", 0.0)
	_party_damage_material.set_shader_parameter("effect_strength", 1.0)
	_party_damage_material.set_shader_parameter("critical_strength", 1.0 if critical else 0.0)
	_party_damage_tween = create_tween()
	_party_damage_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_party_damage_tween.tween_method(_set_party_damage_effect_progress, 0.0, 1.0, duration)
	_party_damage_tween.finished.connect(_clear_party_damage_effect.bind(_party_damage_tween))
	return duration

func _set_party_damage_effect_progress(progress: float) -> void:
	if _party_damage_material != null:
		_party_damage_material.set_shader_parameter("effect_progress", progress)

func _clear_party_damage_effect(tween: Tween) -> void:
	if _party_damage_tween != tween:
		return
	_party_damage_tween = null
	if _party_damage_material != null:
		_party_damage_material.set_shader_parameter("effect_strength", 0.0)

func play_skill_presentation(skill: SkillData, target_visual: Node3D = null) -> float:
	if skill == null:
		return 0.0
	var effect_duration := _play_skill_effect(skill, target_visual)
	var shake_duration := play_screen_shake(skill.shake_intensity, skill.shake_decay) \
			if skill.shake_screen else 0.0
	return maxf(effect_duration, shake_duration)

func _play_skill_effect(skill: SkillData, target_visual: Node3D) -> float:
	if skill.AnimationScene == null:
		return 0.0
	var effect := skill.AnimationScene.instantiate() as Node3D
	if effect == null:
		return 0.0
	add_child(effect)
	if target_visual != null and is_instance_valid(target_visual):
		effect.global_position = target_visual.global_position
	elif battle_camera != null:
		effect.global_position = battle_camera.global_position - battle_camera.global_basis.z * 1.5

	var animation_player := effect.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if animation_player == null:
		effect.queue_free()
		return 0.0
	var animation_name: StringName = &"cast" if animation_player.has_animation(&"cast") else &""
	if animation_name.is_empty():
		for candidate in animation_player.get_animation_list():
			if candidate != &"RESET":
				animation_name = candidate
				break
	if animation_name.is_empty():
		effect.queue_free()
		return 0.0
	var animation := animation_player.get_animation(animation_name)
	var duration := animation.length if animation != null else 0.0
	animation_player.play(animation_name)
	if duration > 0.0:
		get_tree().create_timer(duration).timeout.connect(effect.queue_free)
	else:
		effect.queue_free()
	return duration

func play_screen_shake(intensity: float, decay: float) -> float:
	if battle_camera == null or intensity <= 0.0:
		return 0.0
	if _camera_shake_tween != null and _camera_shake_tween.is_valid():
		_camera_shake_tween.kill()
	_camera_shake_base_h_offset = battle_camera.h_offset
	_camera_shake_base_v_offset = battle_camera.v_offset
	_camera_shake_intensity = intensity
	var duration := maxf(0.1, 1.0 / maxf(decay, 0.1))
	_camera_shake_tween = create_tween()
	_camera_shake_tween.tween_method(_set_camera_shake, 0.0, 1.0, duration)
	_camera_shake_tween.finished.connect(_clear_camera_shake.bind(_camera_shake_tween))
	return duration

func _set_camera_shake(progress: float) -> void:
	if battle_camera == null:
		return
	var fade := pow(1.0 - progress, 2.0)
	battle_camera.h_offset = _camera_shake_base_h_offset + randf_range(-1.0, 1.0) * _camera_shake_intensity * fade
	battle_camera.v_offset = _camera_shake_base_v_offset + randf_range(-1.0, 1.0) * _camera_shake_intensity * fade

func _clear_camera_shake(tween: Tween) -> void:
	if _camera_shake_tween != tween:
		return
	_camera_shake_tween = null
	if battle_camera != null:
		battle_camera.h_offset = _camera_shake_base_h_offset
		battle_camera.v_offset = _camera_shake_base_v_offset

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

	for enemy in enemies:
		if enemy == null or not enemy.is_alive() or enemy.has_fled:
			continue
		var new_row: int = row_map[enemy.formation_row]
		if enemy.formation_row == new_row:
			continue
		enemy.formation_row = new_row
		var visual := enemy_visuals.get(enemy) as Node3D
		if visual != null and is_instance_valid(visual):
			var marker := get_enemy_slot(enemy.formation_row, enemy.formation_slot)
			if marker != null:
				visual.reparent(marker, true)

	# Layout runs even when no row shifted so survivors close gaps left by a
	# defeated or fleeing enemy.
	layout_enemy_rows(enemies, enemy_visuals, true)

func _clear_enemy_row_tween(tween: Tween) -> void:
	if _enemy_row_tween == tween:
		_enemy_row_tween = null

func _apply_row_scale(visual: Node3D, row: int, animate := false) -> void:
	var row_pixel_size: float = ROW_PIXEL_SIZES[
		clampi(row, 0, ROW_PIXEL_SIZES.size() - 1)
	]
	if visual.has_method("apply_formation_size"):
		visual.apply_formation_size(row_pixel_size, animate, ROW_ADVANCE_DURATION)
		return
	_apply_fallback_row_scale(visual, row_pixel_size)

func _apply_fallback_row_scale(node: Node, row_pixel_size: float) -> void:
	if node is Sprite3D:
		var sprite := node as Sprite3D
		sprite.pixel_size = row_pixel_size
	for child in node.get_children():
		_apply_fallback_row_scale(child, row_pixel_size)

func get_enemy_slot(row: int, slot: int) -> Marker3D:
	var marker_number := row * 3 + slot + 1
	var marker_path := "enemies/row_%d/EnemySlot_%d" % [row + 1, marker_number]
	var marker := get_node_or_null(marker_path) as Marker3D
	if marker == null:
		push_warning("Combat arena is missing enemy slot: %s" % marker_path)
	return marker
