extends Node3D
@onready var enemy_sprite: Sprite3D = $EnemySprite
@onready var progress_bar: ProgressBar = $Node/CanvasLayer/ProgressBar
@onready var hit_animation: ColorRect = $Node/CanvasLayer/HitAnimation
@onready var damage_label: Label = $Node/CanvasLayer/HitAnimation/DamageLabel


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.
