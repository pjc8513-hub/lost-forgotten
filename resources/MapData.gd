extends Node3D
class_name MapData

@export var enable_torch: bool = true
@export var main_screen_filter_visible: bool = true
@export var is_underwater: bool = false
@export var main_shader_palette_texture: Texture2D
@export_range(1.0, 16.0, 0.1) var main_shader_pixel_size: float = 2.0
@export_range(0.0, 1.0, 0.001) var main_shader_dither_strength: float = 0.001
@export_range(0.5, 3.0, 0.01) var main_shader_contrast: float = 0.95

@export_group("Encounter Options")
@export var encounters_enabled: bool = false
@export var combat_scene: PackedScene
@export var enemy_ids: Array[StringName]
@export_range(0.0, 100.0, 0.5) var threat_per_step: float = 5.0
@export_range(0.0, 100.0, 0.5) var search_threat: float = 15.0
@export_range(0.0, 100.0, 0.5) var door_threat: float = 10.0
@export_range(1, 3, 1) var maximum_enemy_rows: int = 3
@export_range(1, 3, 1) var maximum_enemies_per_row: int = 3
