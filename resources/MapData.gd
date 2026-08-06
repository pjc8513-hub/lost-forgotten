extends Node3D
class_name MapData

@export var Map_ID: StringName
@export var has_daynight: bool = false
## Visual time in 24-hour HHMM format for maps without a day/night cycle.
## This does not change WorldManager's tracked time.
@export_range(0, 2359, 1) var time_of_day: int = 1730
@export var enable_torch: bool = true
@export var main_screen_filter_visible: bool = true
@export var is_underwater: bool = false
@export var main_shader_palette_texture: Texture2D
@export_range(1.0, 16.0, 0.1) var main_shader_pixel_size: float = 2.0
@export_range(0.0, 1.0, 0.001) var main_shader_dither_strength: float = 0.001
@export_range(0.5, 3.0, 0.01) var main_shader_contrast: float = 0.95

@export_group("Day/Night Cycle")
@export_range(0.0, 2.0, 0.01) var night_ambient_energy: float = 0.4
@export_range(0.0, 2.0, 0.01) var night_directional_energy: float = 0.12
@export var night_ambient_color: Color = Color(0.16, 0.22, 0.42)
@export var night_directional_color: Color = Color(0.52, 0.65, 1.0)
@export var night_fog_color: Color = Color(0.12, 0.17, 0.32)
@export var night_volumetric_fog_albedo: Color = Color(0.2, 0.26, 0.46)
@export_range(0.0, 1.0, 0.001) var night_volumetric_fog_density: float = 0.04
@export_range(0.0, 2.0, 0.01) var night_volumetric_fog_emission_energy: float = 0.25
@export var night_sky_zenith_color: Color = Color(0.045, 0.075, 0.2)
@export var night_sky_horizon_color: Color = Color(0.12, 0.16, 0.34)

const SECONDS_PER_DAY := 24.0 * 60.0 * 60.0
const DAY_START_SECONDS := 6.0 * 60.0 * 60.0

@onready var _daynight_light: DirectionalLight3D = get_node_or_null("DirectionalLight3D") as DirectionalLight3D
@onready var _daynight_world_environment: WorldEnvironment = get_node_or_null("WorldEnvironment") as WorldEnvironment

var _daynight_sky_material: ShaderMaterial
var _day_directional_energy: float
var _day_directional_color: Color
var _day_ambient_energy: float
var _day_ambient_color: Color
var _day_fog_color: Color
var _day_volumetric_fog_albedo: Color
var _day_volumetric_fog_density: float
var _day_volumetric_fog_emission_energy: float
var _day_sky_zenith_color: Color = Color(0.2, 0.45, 0.85)
var _day_sky_horizon_color: Color = Color(0.55, 0.75, 0.9)
var _day_sun_color: Color = Color(1.0, 0.95, 0.8)


func _ready() -> void:
	if _daynight_light == null or _daynight_world_environment == null or _daynight_world_environment.environment == null:
		if has_daynight:
			push_warning("Map '%s' has_daynight enabled but is missing a DirectionalLight3D or environment." % name)
		return

	if _daynight_world_environment.environment != null and _daynight_world_environment.environment.sky != null:
		_daynight_sky_material = _daynight_world_environment.environment.sky.sky_material as ShaderMaterial

	_cache_daynight_day_values()
	if has_daynight:
		WorldManager.dungeon_time_changed.connect(_on_daynight_time_changed)
		_on_daynight_time_changed(WorldManager.dungeon_elapsed_time)
	else:
		_apply_visual_time(_hhmm_to_seconds(time_of_day))


func _exit_tree() -> void:
	if WorldManager.dungeon_time_changed.is_connected(_on_daynight_time_changed):
		WorldManager.dungeon_time_changed.disconnect(_on_daynight_time_changed)


func _cache_daynight_day_values() -> void:
	_day_directional_energy = _daynight_light.light_energy
	_day_directional_color = _daynight_light.light_color

	var environment := _daynight_world_environment.environment
	_day_ambient_energy = environment.ambient_light_energy
	_day_ambient_color = environment.ambient_light_color
	_day_fog_color = environment.fog_light_color
	_day_volumetric_fog_albedo = environment.volumetric_fog_albedo
	_day_volumetric_fog_density = environment.volumetric_fog_density
	_day_volumetric_fog_emission_energy = environment.volumetric_fog_emission_energy

	if _daynight_sky_material == null:
		return
	var zenith_color = _daynight_sky_material.get_shader_parameter("zenith_color")
	var horizon_color = _daynight_sky_material.get_shader_parameter("horizon_color")
	var sun_color = _daynight_sky_material.get_shader_parameter("sun_color")
	if zenith_color is Color:
		_day_sky_zenith_color = zenith_color
	if horizon_color is Color:
		_day_sky_horizon_color = horizon_color
	if sun_color is Color:
		_day_sun_color = sun_color


func _on_daynight_time_changed(elapsed_seconds: int) -> void:
	if not has_daynight or _daynight_light == null or _daynight_world_environment == null:
		return

	var world_time_of_day := fmod(float(WorldManager.DUNGEON_START_TIME_SECONDS + elapsed_seconds), SECONDS_PER_DAY)
	_apply_visual_time(world_time_of_day)


func _hhmm_to_seconds(hhmm: int) -> float:
	var hour := hhmm / 100
	var minute := hhmm % 100
	if hour > 23 or minute > 59:
		push_warning("Map '%s' has invalid time_of_day %04d; expected 24-hour HHMM." % [name, hhmm])
		hour = clampi(hour, 0, 23)
		minute = clampi(minute, 0, 59)
	return float(hour * 60 * 60 + minute * 60)


func _apply_visual_time(visual_time_seconds: float) -> void:
	var sun_height := sin((visual_time_seconds - DAY_START_SECONDS) / (12.0 * 60.0 * 60.0) * PI)
	var daylight := smoothstep(-0.12, 0.25, sun_height)
	var twilight := smoothstep(-0.35, 0.15, sun_height) * (1.0 - smoothstep(0.2, 0.75, sun_height))

	# Keep the light moving continuously, while dimming it below the horizon.
	var elevation := rad_to_deg(asin(clampf(sun_height, -1.0, 1.0)))
	_daynight_light.rotation_degrees = Vector3(-elevation, -35.0, 0.0)
	_daynight_light.light_energy = lerpf(night_directional_energy, _day_directional_energy, daylight)
	_daynight_light.light_color = night_directional_color.lerp(_day_directional_color, daylight)

	var environment := _daynight_world_environment.environment
	environment.ambient_light_color = night_ambient_color.lerp(_day_ambient_color, daylight)
	environment.ambient_light_energy = lerpf(night_ambient_energy, _day_ambient_energy, daylight)
	environment.fog_light_color = night_fog_color.lerp(_day_fog_color, daylight)
	environment.volumetric_fog_albedo = night_volumetric_fog_albedo.lerp(_day_volumetric_fog_albedo, daylight)
	environment.volumetric_fog_emission_energy = lerpf(
		night_volumetric_fog_emission_energy,
		_day_volumetric_fog_emission_energy,
		daylight
	)
	environment.volumetric_fog_density = lerpf(
		night_volumetric_fog_density,
		_day_volumetric_fog_density,
		daylight
	) + twilight * 0.012

	if _daynight_sky_material != null:
		_daynight_sky_material.set_shader_parameter("zenith_color", night_sky_zenith_color.lerp(_day_sky_zenith_color, daylight))
		_daynight_sky_material.set_shader_parameter("horizon_color", night_sky_horizon_color.lerp(_day_sky_horizon_color, daylight))
		_daynight_sky_material.set_shader_parameter("sun_color", _day_sun_color.lerp(Color(1.0, 0.5, 0.28), twilight))
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
