extends Node

signal transition_started
signal scene_changed(scene: PackedScene)
signal transition_finished

var is_transitioning := false

func change_scene(scene: PackedScene) -> bool:
	if scene == null or is_transitioning:
		return false

	is_transitioning = true
	transition_started.emit()

	var error := get_tree().change_scene_to_packed(scene)
	if error != OK:
		push_error("Could not change scene: %s" % error_string(error))
		is_transitioning = false
		return false

	await get_tree().process_frame
	scene_changed.emit(scene)
	transition_finished.emit()
	is_transitioning = false
	return true
