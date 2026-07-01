extends Node3D

@export var initial_map: PackedScene
@export var initial_spawn_id: StringName = &"entrance"
@export var player_scene: PackedScene

@onready var level_root: Node = $World/LevelRoot
@onready var entity_root: Node = $World/EntityRoot
@onready var effect_root: Node = $World/EffectRoot
@onready var automap: Automap = $HudLayer/HudRoot/CanvasLayer/AutomapControl

func _ready() -> void:
	if initial_map == null or player_scene == null:
		push_error("Main requires both an initial_map and player_scene.")
		return

	var player := player_scene.instantiate() as Node3D
	entity_root.add_child(player)
	StageManager.configure(level_root, entity_root, effect_root, player)
	StageManager.load_map_scene(initial_map, initial_spawn_id)
	var movement := player.get_node_or_null("GridMovementController") as GridMovementController
	if movement != null:
		automap.setup(movement)
