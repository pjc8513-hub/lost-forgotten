class_name MapExit
extends Node3D

signal destination_selection_requested(map_exit: MapExit, actor: Node3D)

@export_file("*.tscn") var destination_map: String
@export var destination_spawn_id: StringName
@export var destination_label := "Use lift"
@export var animation_name: StringName
@export var player_travel_offset := Vector3.ZERO

var is_travelling := false

func _ready() -> void:
	var interactable := get_node_or_null("InteractableComponent") as InteractableComponent
	if interactable == null:
		push_error("MapExit requires an InteractableComponent: %s" % get_path())
		return
	interactable.interacted.connect(_on_interacted)

func get_destination_options() -> Array[Dictionary]:
	if destination_map.is_empty():
		return []
	return [{
		"label": destination_label,
		"map": destination_map,
		"spawn_id": destination_spawn_id,
		"animation": animation_name,
		"player_offset": player_travel_offset,
	}]

func activate_destination(index: int, actor: Node3D) -> void:
	var options := get_destination_options()
	if is_travelling or index < 0 or index >= options.size():
		return
	is_travelling = true
	_travel(options[index], actor)

func _on_interacted(actor: Node) -> void:
	var player := actor as Node3D
	if player == null or is_travelling:
		return
	var options := get_destination_options()
	if options.size() == 1:
		activate_destination(0, player)
	elif options.size() > 1:
		destination_selection_requested.emit(self, player)

func _travel(destination: Dictionary, actor: Node3D) -> void:
	TurnManager.set_state(TurnManager.State.TRANSITION)
	var animation_player := get_node_or_null("AnimationPlayer") as AnimationPlayer
	var selected_animation: StringName = destination["animation"]
	var duration := 0.0
	if animation_player != null and animation_player.has_animation(selected_animation):
		duration = animation_player.get_animation(selected_animation).length
		animation_player.play(selected_animation)

	var offset: Vector3 = destination["player_offset"]
	if duration > 0.0 and not offset.is_zero_approx():
		var tween := create_tween()
		tween.set_trans(Tween.TRANS_LINEAR)
		tween.tween_property(actor, "global_position", actor.global_position + offset, duration)
		await tween.finished
	elif duration > 0.0:
		await get_tree().create_timer(duration).timeout

	StageManager.call_deferred(
		"change_map",
		destination["map"],
		destination["spawn_id"]
	)
