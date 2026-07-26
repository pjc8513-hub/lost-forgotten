extends Node3D
class_name MapData

@export var has_daynight: bool = false
@export var enable_torch: bool = true
@export var main_screen_filter_visible: bool = true
@export var is_underwater: bool = false
@export var main_shader_palette_texture: Texture2D
@export_range(1.0, 16.0, 0.1) var main_shader_pixel_size: float = 2.0
@export_range(0.0, 1.0, 0.001) var main_shader_dither_strength: float = 0.001
@export_range(0.5, 3.0, 0.01) var main_shader_contrast: float = 0.95

const SECONDS_PER_DAY := 24.0 * 60.0 * 60.0
const DAY_START_SECONDS := 6.0 * 60.0 * 60.0

@onready var _daynight_light: DirectionalLight3D = get_node_or_null("DirectionalLight3D") as DirectionalLight3D
@onready var _daynight_world_environment: WorldEnvironment = get_node_or_null("WorldEnvironment") as WorldEnvironment

var _daynight_sky_material: ShaderMaterial


func _ready() -> void:
	if not has_daynight:
		return

	if _daynight_light == null or _daynight_world_environment == null or _daynight_world_environment.environment == null:
		push_warning("Map '%s' has_daynight enabled but is missing a DirectionalLight3D or environment." % name)
		return

	if _daynight_world_environment.environment != null and _daynight_world_environment.environment.sky != null:
		_daynight_sky_material = _daynight_world_environment.environment.sky.sky_material as ShaderMaterial

	WorldManager.dungeon_time_changed.connect(_on_daynight_time_changed)
	_on_daynight_time_changed(WorldManager.dungeon_elapsed_time)


func _exit_tree() -> void:
	if WorldManager.dungeon_time_changed.is_connected(_on_daynight_time_changed):
		WorldManager.dungeon_time_changed.disconnect(_on_daynight_time_changed)


func _on_daynight_time_changed(elapsed_seconds: int) -> void:
	if not has_daynight or _daynight_light == null or _daynight_world_environment == null:
		return

	var time_of_day := fmod(float(WorldManager.DUNGEON_START_TIME_SECONDS + elapsed_seconds), SECONDS_PER_DAY)
	var sun_height := sin((time_of_day - DAY_START_SECONDS) / (12.0 * 60.0 * 60.0) * PI)
	var daylight := smoothstep(-0.12, 0.25, sun_height)
	var twilight := smoothstep(-0.35, 0.15, sun_height) * (1.0 - smoothstep(0.2, 0.75, sun_height))

	# Keep the light moving continuously, while dimming it below the horizon.
	var elevation := rad_to_deg(asin(clampf(sun_height, -1.0, 1.0)))
	_daynight_light.rotation_degrees = Vector3(-elevation, -35.0, 0.0)
	_daynight_light.light_energy = lerpf(0.04, 1.15, daylight)
	_daynight_light.light_color = Color(0.52, 0.65, 1.0).lerp(Color(1.0, 0.91, 0.72), daylight)

	var environment := _daynight_world_environment.environment
	environment.ambient_light_color = Color(0.08, 0.12, 0.28).lerp(Color(0.65, 0.75, 0.91), daylight)
	environment.ambient_light_energy = lerpf(0.18, 1.0, daylight)
	environment.fog_light_color = Color(0.08, 0.12, 0.26).lerp(Color(0.39, 0.58, 0.69), daylight)
	environment.volumetric_fog_albedo = Color(0.16, 0.2, 0.38).lerp(Color(0.65, 0.75, 0.91), daylight)
	environment.volumetric_fog_emission_energy = lerpf(0.12, 0.5, daylight)
	environment.volumetric_fog_density = lerpf(0.055, 0.04, daylight) + twilight * 0.012

	if _daynight_sky_material != null:
		_daynight_sky_material.set_shader_parameter("zenith_color", Color(0.025, 0.045, 0.14).lerp(Color(0.2, 0.45, 0.85), daylight))
		_daynight_sky_material.set_shader_parameter("horizon_color", Color(0.08, 0.1, 0.24).lerp(Color(0.55, 0.75, 0.9), daylight))
		_daynight_sky_material.set_shader_parameter("sun_color", Color(0.3, 0.42, 0.85).lerp(Color(1.0, 0.95, 0.8), twilight))
		_daynight_sky_material.set_shader_parameter("sun_visibility", smoothstep(-0.08, 0.05, sun_height))

@export_group("Encounter Options")
@export var encounters_enabled: bool = false
@export var combat_scene: PackedScene
@export var enemy_ids: Array[StringName]
@export_range(0.0, 100.0, 0.5) var threat_per_step: float = 5.0
@export_range(0.0, 100.0, 0.5) var search_threat: float = 15.0
@export_range(0.0, 100.0, 0.5) var door_threat: float = 10.0
@export_range(1, 3, 1) var maximum_enemy_rows: int = 3
@export_range(1, 3, 1) var maximum_enemies_per_row: int = 3
