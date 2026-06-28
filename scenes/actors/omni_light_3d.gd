extends OmniLight3D

@export var base_energy: float = 1.4
@export var flicker_amount: float = 0.35
@export var noise_speed: float = 1.5
@export var noise_scale: float = 0.8

var noise := FastNoiseLite.new()
var time: float = 0.0

func _ready() -> void:
	visible = true
	set_process(true)

	# Configure noise for smooth but lively fire motion
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise.fractal_octaves = 3
	noise.frequency = 0.9

func _process(delta: float) -> void:
	time += delta * noise_speed

	# Sample noise in 1D by moving through 3D space diagonally
	var n = noise.get_noise_3d(time, time * 0.5, time * 0.25)

	# Keep noise in a comfortable range
	var flicker = n * flicker_amount

	light_energy = base_energy + flicker
