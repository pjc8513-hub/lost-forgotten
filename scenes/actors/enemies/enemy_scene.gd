extends Node3D
@export_range(0.5, 2.0, 0.05) var combat_size_multiplier := 1.0
@onready var enemy_sprite: Sprite3D = $EnemySprite
@onready var canvas_layer: CanvasLayer = $Node/CanvasLayer
@onready var damage_label: Label = $Node/CanvasLayer/HitAnimation/DamageLabel
@onready var hit_animation: Sprite2D = $Node/CanvasLayer/HitAnimation
@onready var health_bar: ProgressBar = $Node/CanvasLayer/HealthBar
@onready var ui_anchor: Marker3D = $UIAnchor
@onready var hover_target: Control = $Node/TooltipLayer/HoverTarget

const FEEDBACK_DISPLAY_TIME := 0.7
const HEALTH_TWEEN_TIME := 0.22
const FLEE_DISPLAY_TIME := 0.18
const FLEE_FADE_TIME := 0.45
const FORMATION_PREVIEW_TIME := 0.12
const FALLBACK_ATTACK_FLASH_COUNT := 3
const FALLBACK_ATTACK_FLASH_TIME := 0.08

var _feedback_tween: Tween
var _feedback_generation := 0
var _formation_scale_tween: Tween
var _formation_preview_tween: Tween
var _attack_tween: Tween
var _authored_sprite_scale := Vector3.ONE
var enemy_instance: EnemyInstance

func _exit_tree() -> void:
	if _feedback_tween != null and _feedback_tween.is_valid():
		_feedback_tween.kill()
	if _formation_scale_tween != null and _formation_scale_tween.is_valid():
		_formation_scale_tween.kill()
	if _formation_preview_tween != null and _formation_preview_tween.is_valid():
		_formation_preview_tween.kill()
	if _attack_tween != null and _attack_tween.is_valid():
		_attack_tween.kill()
	_feedback_generation += 1
	_feedback_tween = null
	_formation_scale_tween = null
	_formation_preview_tween = null
	_attack_tween = null

func _ready() -> void:
	_authored_sprite_scale = enemy_sprite.scale
	canvas_layer.hide()
	hover_target.size = Vector2(100.0, 100.0)
	health_bar.size = Vector2(100.0, 18.0)
	health_bar.position = Vector2(-50.0, -42.0)
	hit_animation.hide()
	damage_label.position = Vector2(-45.0, -14.0)
	damage_label.size = Vector2(90.0, 28.0)
	damage_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	damage_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

func _process(_delta: float) -> void:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return
	var screen_position := camera.unproject_position(ui_anchor.global_position)
	if canvas_layer.visible:
		health_bar.position = screen_position + Vector2(-50.0, -42.0)
		hit_animation.position = screen_position + Vector2(0.0, -10.0)
	hover_target.position = screen_position - hover_target.size * 0.5
	hover_target.visible = visible and enemy_instance != null and enemy_instance.is_alive() and not enemy_instance.has_fled
	if hover_target.visible:
		hover_target.tooltip_text = _tooltip_text()

func set_enemy_instance(instance: EnemyInstance) -> void:
	enemy_instance = instance
	hover_target.tooltip_text = _tooltip_text()

## Applies the row's presentation size with an enemy-specific multiplier. The
## dedicated multiplier avoids inheriting legacy pixel sizes that predate the
## current combat camera.
func apply_formation_size(row_pixel_size: float, animate := false, duration := 0.0) -> void:
	var target_pixel_size := row_pixel_size * combat_size_multiplier
	if _formation_scale_tween != null and _formation_scale_tween.is_valid():
		_formation_scale_tween.kill()
	_formation_scale_tween = null
	if not animate or duration <= 0.0:
		enemy_sprite.pixel_size = target_pixel_size
		return
	_formation_scale_tween = create_tween()
	_formation_scale_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	_formation_scale_tween.tween_property(enemy_sprite, "pixel_size", target_pixel_size, duration)
	_formation_scale_tween.finished.connect(_clear_formation_scale_tween.bind(_formation_scale_tween))

func _clear_formation_scale_tween(tween: Tween) -> void:
	if _formation_scale_tween == tween:
		_formation_scale_tween = null

## Keeps the full formation readable while drawing attention to the row under
## the player's cursor.
func set_row_preview(selected: bool, preview_active: bool) -> void:
	if _formation_preview_tween != null and _formation_preview_tween.is_valid():
		_formation_preview_tween.kill()
	var target_color := Color.WHITE
	var target_scale := _authored_sprite_scale
	if preview_active:
		if selected:
			target_color = Color(1.0, 0.9, 0.7, 1.0)
			target_scale = _authored_sprite_scale * 1.06
		else:
			target_color = Color(0.42, 0.44, 0.5, 1.0)
	_formation_preview_tween = create_tween()
	_formation_preview_tween.set_parallel(true)
	_formation_preview_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_formation_preview_tween.tween_property(
		enemy_sprite,
		"modulate",
		target_color,
		FORMATION_PREVIEW_TIME
	)
	_formation_preview_tween.tween_property(
		enemy_sprite,
		"scale",
		target_scale,
		FORMATION_PREVIEW_TIME
	)
	_formation_preview_tween.set_parallel(false)
	_formation_preview_tween.finished.connect(
		_clear_formation_preview_tween.bind(_formation_preview_tween)
	)

func _clear_formation_preview_tween(tween: Tween) -> void:
	if _formation_preview_tween == tween:
		_formation_preview_tween = null

func _tooltip_text() -> String:
	if enemy_instance == null:
		return ""
	var text := "%s\nHP: %d / %d" % [
		enemy_instance.get_display_name(),
		enemy_instance.current_hp,
		enemy_instance.max_hp,
	]
	if enemy_instance.active_status_effects.is_empty():
		return text + "\nStatus Effects: None"
	var labels: Array[String] = []
	for raw_effect_id in enemy_instance.active_status_effects:
		labels.append(StatusEffects.get_label(int(raw_effect_id)))
	return text + "\nStatus Effects: " + ", ".join(labels)

func show_health_feedback(current_hp: int, max_hp: int, amount: int, hit: bool, feedback_text: String = "") -> void:
	if _feedback_tween != null and _feedback_tween.is_valid():
		_feedback_tween.kill()
	_feedback_generation += 1
	var feedback_generation := _feedback_generation

	canvas_layer.show()
	health_bar.show()
	health_bar.max_value = maxi(max_hp, 1)
	var displayed_hp := clampi(current_hp + (amount if hit else 0), 0, maxi(max_hp, 1))
	health_bar.value = displayed_hp
	hit_animation.show()
	damage_label.show()
	damage_label.text = feedback_text if not feedback_text.is_empty() else (str(amount) if hit else "MISS")
	damage_label.add_theme_color_override("font_color", Color.WHITE if hit else Color(1.0, 0.86, 0.25, 1.0))

	if hit:
		_feedback_tween = create_tween()
		_feedback_tween.tween_property(health_bar, "value", current_hp, HEALTH_TWEEN_TIME)
	var feedback_duration := FEEDBACK_DISPLAY_TIME + (HEALTH_TWEEN_TIME if hit else 0.0)
	await get_tree().create_timer(feedback_duration).timeout
	if feedback_generation == _feedback_generation:
		_hide_health_feedback()

func _hide_health_feedback() -> void:
	hit_animation.hide()
	damage_label.hide()
	health_bar.hide()
	canvas_layer.hide()
	_feedback_tween = null

func show_flee_feedback() -> void:
	if _feedback_tween != null and _feedback_tween.is_valid():
		_feedback_tween.kill()
	_feedback_generation += 1
	var feedback_generation := _feedback_generation

	canvas_layer.show()
	health_bar.hide()
	hit_animation.show()
	damage_label.show()
	damage_label.text = "Flees!"
	damage_label.add_theme_color_override("font_color", Color(1.0, 0.86, 0.25, 1.0))
	damage_label.modulate.a = 1.0
	enemy_sprite.transparency = 0.0

	_feedback_tween = create_tween()
	_feedback_tween.tween_interval(FLEE_DISPLAY_TIME)
	_feedback_tween.set_parallel(true)
	_feedback_tween.tween_property(enemy_sprite, "transparency", 1.0, FLEE_FADE_TIME)
	_feedback_tween.tween_property(damage_label, "modulate:a", 0.0, FLEE_FADE_TIME)
	_feedback_tween.set_parallel(false)
	await get_tree().create_timer(FLEE_DISPLAY_TIME + FLEE_FADE_TIME).timeout
	if feedback_generation == _feedback_generation:
		canvas_layer.hide()
		_feedback_tween = null

func play_attack_animation() -> float:
	var animation_player := find_child("AnimationPlayer", true, false) as AnimationPlayer
	if animation_player != null and animation_player.has_animation(&"attack"):
		var animation := animation_player.get_animation(&"attack")
		var duration := animation.length if animation != null else 0.0
		animation_player.play(&"attack")
		return duration
	return _play_fallback_attack_animation()

func _play_fallback_attack_animation() -> float:
	if _attack_tween != null and _attack_tween.is_valid():
		_attack_tween.kill()

	var base_modulate := enemy_sprite.modulate
	var attack_modulate := Color(1.0, 0.1, 0.1, base_modulate.a)
	var total_duration := FALLBACK_ATTACK_FLASH_COUNT * FALLBACK_ATTACK_FLASH_TIME * 2.0
	_attack_tween = create_tween()
	for _flash_index in FALLBACK_ATTACK_FLASH_COUNT:
		_attack_tween.tween_property(enemy_sprite, "modulate", attack_modulate, FALLBACK_ATTACK_FLASH_TIME)
		_attack_tween.tween_property(enemy_sprite, "modulate", base_modulate, FALLBACK_ATTACK_FLASH_TIME)
	_attack_tween.finished.connect(_clear_attack_tween.bind(_attack_tween))
	return total_duration

func _clear_attack_tween(tween: Tween) -> void:
	if _attack_tween == tween:
		_attack_tween = null
