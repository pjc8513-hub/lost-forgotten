extends CharacterBody3D

@onready var movement: GridMovementController = $GridMovementController

const VISION_BLOCKER_SHADER := preload("res://scripts/shaders/vision_blocker.gdshader")

var _vision_blockers: Dictionary = {}
var _vision_overlay: ColorRect

func rotate_left() -> void:
	movement.rotate_left()

func rotate_right() -> void:
	movement.rotate_right()
	
func turn_around() -> void:
	movement.turn_around()

func _ready() -> void:
	_create_vision_overlay()

func set_vision_blocked(source: Object, blocked: bool) -> void:
	if blocked:
		_vision_blockers[source] = true
	else:
		_vision_blockers.erase(source)
	if _vision_overlay != null:
		_vision_overlay.visible = not _vision_blockers.is_empty()

func _create_vision_overlay() -> void:
	var canvas_layer := CanvasLayer.new()
	canvas_layer.layer = 20
	add_child(canvas_layer)

	_vision_overlay = ColorRect.new()
	_vision_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_vision_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vision_overlay.visible = false
	var material := ShaderMaterial.new()
	material.shader = VISION_BLOCKER_SHADER
	material.set_shader_parameter("darkness", 0.94)
	material.set_shader_parameter("reveal_radius", 0.20)
	material.set_shader_parameter("edge_softness", 0.07)
	_vision_overlay.material = material
	canvas_layer.add_child(_vision_overlay)
