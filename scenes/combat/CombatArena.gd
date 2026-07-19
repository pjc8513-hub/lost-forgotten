class_name CombatArena
extends MapData

@onready var battle_camera: Camera3D = $BattleCamera
@onready var party_damage_overlay := get_node_or_null("canvaslayer/CanvasLayer/ColorRect") as ColorRect

const ROW_PIXEL_SIZES := [0.0035, 0.0045, 0.0055]
const ROW_FADE_DURATION := 0.18
const CAMERA_ZOOM_FOV := 33.0
const CAMERA_TWEEN_DURATION := 0.16
const PARTY_DAMAGE_EFFECT_TIME := 0.42
const PARTY_CRITICAL_EFFECT_TIME := 0.62

var _enemy_row_tween: Tween
var _enemy_row_transition_id := 0
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
	_apply_row_pixel_size(visual, enemy.formation_row)
	return visual

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
