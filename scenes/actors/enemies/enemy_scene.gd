extends Node3D
@onready var enemy_sprite: Sprite3D = $EnemySprite
@onready var damage_label: Label = $Node/CanvasLayer/HitAnimation/DamageLabel
@onready var hit_animation: Sprite2D = $Node/CanvasLayer/HitAnimation
@onready var health_bar: ProgressBar = $Node/CanvasLayer/HealthBar
@onready var ui_anchor: Marker3D = $UIAnchor


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.
