class_name BrazierData
extends Resource

@export var scene_path: String = ""

# Light properties — if left at 0 / Color.BLACK the brazier
# falls back to whatever theme.torch_* values are set
@export var light_color: Color = Color.BLACK      # BLACK = use theme default
@export var base_energy: float = 0.0              # 0 = use theme default
@export var omni_range:  float = 0.0              # 0 = use theme default
@export var flicker_speed:  float = 0.0
@export var flicker_amount: float = 0.0
@export var enable_flicker: bool  = true
