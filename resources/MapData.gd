extends Node3D
class_name MapData

@export var enable_torch: bool = true
@export var main_screen_filter_visible: bool = true
@export var main_shader_palette_texture: Texture2D
@export_range(1.0, 16.0, 0.1) var main_shader_pixel_size: float = 2.0
@export_range(0.0, 1.0, 0.001) var main_shader_dither_strength: float = 0.001
@export_range(0.5, 3.0, 0.01) var main_shader_contrast: float = 0.95
