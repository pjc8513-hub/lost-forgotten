@tool
extends EditorPlugin

const PANEL_SCRIPT := preload("res://addons/dungeon_synth/dungeon_synth_panel.gd")

var _panel: Control


func _enter_tree() -> void:
	_register_project_settings()
	_panel = PANEL_SCRIPT.new()
	_panel.name = "DungeonSynth"
	_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_panel.custom_minimum_size = Vector2(640, 480)
	EditorInterface.get_editor_main_screen().add_child(_panel)
	_make_visible(false)


func _exit_tree() -> void:
	if is_instance_valid(_panel):
		_panel.queue_free()
	_panel = null


func _has_main_screen() -> bool:
	return true


func _make_visible(visible: bool) -> void:
	if is_instance_valid(_panel):
		_panel.visible = visible


func _get_plugin_name() -> String:
	return "Dungeon Synth"


func _get_plugin_icon() -> Texture2D:
	return EditorInterface.get_editor_theme().get_icon("AudioStreamPlayer", "EditorIcons")


func _register_project_settings() -> void:
	var setting_name := "dungeon_synth/fluidsynth_path"
	if not ProjectSettings.has_setting(setting_name):
		ProjectSettings.set_setting(setting_name, "fluidsynth")
	ProjectSettings.set_initial_value(setting_name, "fluidsynth")
	ProjectSettings.add_property_info({
		"name": setting_name,
		"type": TYPE_STRING,
		"hint": PROPERTY_HINT_GLOBAL_FILE,
		"hint_string": "*.exe",
	})
