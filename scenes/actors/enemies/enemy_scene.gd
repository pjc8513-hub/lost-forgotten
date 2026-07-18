extends Node3D
@onready var enemy_sprite: Sprite3D = $EnemySprite
@onready var canvas_layer: CanvasLayer = $Node/CanvasLayer
@onready var damage_label: Label = $Node/CanvasLayer/HitAnimation/DamageLabel
@onready var hit_animation: Sprite2D = $Node/CanvasLayer/HitAnimation
@onready var health_bar: ProgressBar = $Node/CanvasLayer/HealthBar
@onready var ui_anchor: Marker3D = $UIAnchor

const FEEDBACK_DISPLAY_TIME := 0.7
const HEALTH_TWEEN_TIME := 0.22
const FLEE_DISPLAY_TIME := 0.18
const FLEE_FADE_TIME := 0.45

var _feedback_tween: Tween
var _feedback_generation := 0

func _exit_tree() -> void:
	if _feedback_tween != null and _feedback_tween.is_valid():
		_feedback_tween.kill()
	_feedback_generation += 1
	_feedback_tween = null

func _ready() -> void:
	canvas_layer.hide()
	health_bar.size = Vector2(100.0, 18.0)
	health_bar.position = Vector2(-50.0, -42.0)
	hit_animation.hide()
	damage_label.position = Vector2(-20.0, -12.0)
	damage_label.size = Vector2(40.0, 24.0)
	damage_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	damage_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

func _process(_delta: float) -> void:
	var camera := get_viewport().get_camera_3d()
	if camera == null or not canvas_layer.visible:
		return
	var screen_position := camera.unproject_position(ui_anchor.global_position)
	health_bar.position = screen_position + Vector2(-50.0, -42.0)
	hit_animation.position = screen_position + Vector2(0.0, -10.0)

func show_health_feedback(current_hp: int, max_hp: int, amount: int, hit: bool) -> void:
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
	damage_label.text = str(amount) if hit else "MISS"
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
	hit_animation.hide()
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
	if animation_player == null or not animation_player.has_animation(&"attack"):
		return 0.0
	var animation := animation_player.get_animation(&"attack")
	var duration := animation.length if animation != null else 0.0
	animation_player.play(&"attack")
	return duration
