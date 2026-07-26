extends Node3D

const LIGHTS_ON_TIME_SECONDS := 17 * 60 * 60
const LIGHTS_OFF_TIME_SECONDS := 7 * 60 * 60

@onready var omni_light_3d: OmniLight3D = $OmniLight3D
@onready var mesh_instance_3d_3: MeshInstance3D = $MeshInstance3D3


func _ready() -> void:
	WorldManager.dungeon_time_changed.connect(_on_dungeon_time_changed)
	_on_dungeon_time_changed(WorldManager.dungeon_elapsed_time)


func _exit_tree() -> void:
	if WorldManager.dungeon_time_changed.is_connected(_on_dungeon_time_changed):
		WorldManager.dungeon_time_changed.disconnect(_on_dungeon_time_changed)


func _on_dungeon_time_changed(_elapsed_seconds: int) -> void:
	var time_of_day := WorldManager.get_time_of_day_seconds() % WorldManager.SECONDS_PER_DAY
	var should_be_lit := time_of_day >= LIGHTS_ON_TIME_SECONDS or time_of_day < LIGHTS_OFF_TIME_SECONDS
	_set_lit(should_be_lit)


func _set_lit(lit: bool) -> void:
	omni_light_3d.visible = lit
	mesh_instance_3d_3.visible = lit
