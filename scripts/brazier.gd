extends Node3D

var brazier_data: BrazierData
var grid_position: Vector2i

var _light: OmniLight3D
var _noise := FastNoiseLite.new()
var _time: float = 0.0

@export var _base_energy: float = 1.2
@export var _base_range: float = 8.0
@export var _flicker_speed: float = 1.5
@export var _flicker_amount: float = 0.3
@export var _flicker_enabled: bool = true

func _ready() -> void:
	_light = $OmniLight3D

	# Configure noise for smooth fire-like motion
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	_noise.fractal_octaves = 3
	_noise.frequency = 0.9

func configure() -> void:
	# Use brazier_data directly (no theme fallback)
	_light.light_color = brazier_data.light_color

	_base_energy     = brazier_data.base_energy
	_base_range      = brazier_data.omni_range
	_flicker_speed   = brazier_data.flicker_speed
	_flicker_amount  = brazier_data.flicker_amount
	_flicker_enabled = brazier_data.enable_flicker

	_light.light_energy = _base_energy
	_light.omni_range   = _base_range

	set_process(_flicker_enabled)

func _process(delta: float) -> void:
	if not _flicker_enabled:
		return

	_time += delta * _flicker_speed

	# Sample 3D noise for organic flame motion
	var n = _noise.get_noise_3d(_time, _time * 0.5, _time * 0.25)

	# Apply flicker to energy and range
	_light.light_energy = _base_energy + n * _flicker_amount
	_light.omni_range   = _base_range  + n * 0.15
