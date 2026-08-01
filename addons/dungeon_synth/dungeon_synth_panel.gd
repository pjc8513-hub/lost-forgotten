@tool
class_name DungeonSynthPanel
extends Control

const DEFAULT_SOUNDFONT := "res://assets/audio/music/Arachno SoundFont - Version 1.0.sf2"
const DEFAULT_OUTPUT_DIR := "res://assets/audio/music/generated"
const PRESET_PATHS := [
	"res://addons/dungeon_synth/presets/city_haven.tres",
	"res://addons/dungeon_synth/presets/fairy_world.tres",
	"res://addons/dungeon_synth/presets/combat.tres",
	"res://addons/dungeon_synth/presets/castle_dungeon.tres",
	"res://addons/dungeon_synth/presets/desert.tres",
	"res://addons/dungeon_synth/presets/mountains.tres",
]
const MODE_NAMES := ["aeolian", "dorian", "phrygian", "locrian", "mixolydian", "lydian", "ionian"]
const KEY_NAMES := ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]

var _styles: Array[DungeonMusicStyle] = []
var _current_song: DungeonSong
var _midi_resource: MidiResource
var _preview_player: MidiStreamPlayer
var _loaded_soundfont_path := ""
var _render_thread: Thread
var _render_wav_path := ""

var _environment_option: OptionButton
var _description_label: Label
var _seed_spin: SpinBox
var _tempo_spin: SpinBox
var _bars_spin: SpinBox
var _key_option: OptionButton
var _mode_option: OptionButton
var _program_options: Dictionary = {}
var _density_sliders: Dictionary = {}
var _soundfont_edit: LineEdit
var _fluidsynth_edit: LineEdit
var _output_edit: LineEdit
var _song_name_edit: LineEdit
var _generate_button: Button
var _play_button: Button
var _stop_button: Button
var _save_button: Button
var _export_button: Button
var _status_label: Label
var _progress_bar: ProgressBar


func _ready() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	custom_minimum_size = Vector2(640, 480)
	set_process(true)
	_build_interface()
	_load_styles()
	_populate_tonal_options()
	_populate_instrument_options()
	_create_preview_player()
	if not _styles.is_empty():
		_apply_style(0)
	_set_status("Ready. Generate a take, audition it through Clef, then save or export it.")


func _exit_tree() -> void:
	_stop_preview()
	if _render_thread != null:
		_render_thread.wait_to_finish()
		_render_thread = null


func _process(_delta: float) -> void:
	if _render_thread != null and not _render_thread.is_alive():
		var result: Dictionary = _render_thread.wait_to_finish()
		_render_thread = null
		_set_busy(false)
		if int(result.get("code", -1)) == 0 and FileAccess.file_exists(_render_wav_path):
			_set_status("Exported soundtrack WAV: %s" % _render_wav_path)
			EditorInterface.get_resource_filesystem().scan_sources()
		else:
			var detail := str(result.get("output", "FluidSynth did not return diagnostic output."))
			_set_status("FluidSynth export failed (exit %d). %s" % [int(result.get("code", -1)), detail])


func _build_interface() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var background := ColorRect.new()
	background.color = Color("14110f")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 32)
	margin.add_theme_constant_override("margin_right", 32)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 32)
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(margin)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 14)
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_child(root)

	var title := Label.new()
	title.text = "DUNGEON SYNTH"
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color("d98a3d"))
	root.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "Seeded environment music · Arachno SF2 preview · MIDI and WAV export"
	subtitle.add_theme_color_override("font_color", Color("a6997f"))
	root.add_child(subtitle)

	var composition := _make_section(root, "Composition")
	var composition_grid := GridContainer.new()
	composition_grid.columns = 4
	composition_grid.add_theme_constant_override("h_separation", 12)
	composition_grid.add_theme_constant_override("v_separation", 8)
	composition.add_child(composition_grid)
	_environment_option = OptionButton.new()
	_environment_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_add_grid_field(composition_grid, "Environment", _environment_option)
	_environment_option.item_selected.connect(_on_environment_selected)
	_seed_spin = _make_spin(1, 999999999, 1)
	_add_grid_field(composition_grid, "Seed", _seed_spin)
	_key_option = OptionButton.new()
	_add_grid_field(composition_grid, "Key", _key_option)
	_mode_option = OptionButton.new()
	_add_grid_field(composition_grid, "Mode", _mode_option)
	_tempo_spin = _make_spin(30, 220, 1)
	_tempo_spin.suffix = " BPM"
	_add_grid_field(composition_grid, "Tempo", _tempo_spin)
	_bars_spin = _make_spin(4, 128, 4)
	_bars_spin.value = 16
	_bars_spin.suffix = " bars"
	_add_grid_field(composition_grid, "Length", _bars_spin)
	_description_label = Label.new()
	_description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_description_label.add_theme_color_override("font_color", Color("c8b99e"))
	composition.add_child(_description_label)

	var layers := _make_section(root, "Layers and SoundFont programs")
	var layer_grid := GridContainer.new()
	layer_grid.columns = 3
	layer_grid.add_theme_constant_override("h_separation", 14)
	layer_grid.add_theme_constant_override("v_separation", 8)
	layers.add_child(layer_grid)
	for layer in ["drone", "melody", "arp", "percussion"]:
		var label := Label.new()
		label.text = layer.capitalize()
		layer_grid.add_child(label)
		var program_option := OptionButton.new()
		program_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_program_options[layer] = program_option
		layer_grid.add_child(program_option)
		var density := HSlider.new()
		density.min_value = 0.0
		density.max_value = 1.0
		density.step = 0.01
		density.custom_minimum_size.x = 180
		density.tooltip_text = "Event density"
		_density_sliders[layer] = density
		layer_grid.add_child(density)

	var paths := _make_section(root, "SoundFont and export")
	var path_grid := GridContainer.new()
	path_grid.columns = 2
	path_grid.add_theme_constant_override("h_separation", 12)
	path_grid.add_theme_constant_override("v_separation", 8)
	paths.add_child(path_grid)
	_soundfont_edit = LineEdit.new()
	_soundfont_edit.text = str(ProjectSettings.get_setting("clef/default_soundfont", DEFAULT_SOUNDFONT))
	if _soundfont_edit.text.is_empty():
		_soundfont_edit.text = DEFAULT_SOUNDFONT
	_add_grid_field(path_grid, "SoundFont", _soundfont_edit)
	_fluidsynth_edit = LineEdit.new()
	_fluidsynth_edit.text = str(ProjectSettings.get_setting("dungeon_synth/fluidsynth_path", "fluidsynth"))
	_add_grid_field(path_grid, "FluidSynth", _fluidsynth_edit)
	_output_edit = LineEdit.new()
	_output_edit.text = DEFAULT_OUTPUT_DIR
	_add_grid_field(path_grid, "Output folder", _output_edit)
	_song_name_edit = LineEdit.new()
	_song_name_edit.text = "dungeon_song"
	_add_grid_field(path_grid, "Song name", _song_name_edit)

	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 10)
	root.add_child(actions)
	_generate_button = _make_button("Generate Take", _on_generate_pressed)
	actions.add_child(_generate_button)
	var new_take := _make_button("New Take", _on_new_take_pressed)
	actions.add_child(new_take)
	_play_button = _make_button("Play", _on_play_pressed)
	actions.add_child(_play_button)
	_stop_button = _make_button("Stop", _stop_preview)
	actions.add_child(_stop_button)
	_save_button = _make_button("Save Song + MIDI", _on_save_pressed)
	actions.add_child(_save_button)
	_export_button = _make_button("Export WAV", _on_export_pressed)
	actions.add_child(_export_button)
	var test_fluid := _make_button("Test FluidSynth", _on_test_fluidsynth_pressed)
	actions.add_child(test_fluid)

	_progress_bar = ProgressBar.new()
	_progress_bar.min_value = 0.0
	_progress_bar.max_value = 1.0
	_progress_bar.value = 0.0
	_progress_bar.show_percentage = false
	root.add_child(_progress_bar)
	_status_label = Label.new()
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_label.custom_minimum_size.y = 44
	_status_label.add_theme_color_override("font_color", Color("d98a3d"))
	root.add_child(_status_label)


func _make_section(parent: VBoxContainer, title_text: String) -> VBoxContainer:
	var panel := PanelContainer.new()
	var style_box := StyleBoxFlat.new()
	style_box.bg_color = Color("242019")
	style_box.border_color = Color("4a4030")
	style_box.set_border_width_all(1)
	style_box.set_corner_radius_all(5)
	style_box.content_margin_left = 16
	style_box.content_margin_right = 16
	style_box.content_margin_top = 12
	style_box.content_margin_bottom = 14
	panel.add_theme_stylebox_override("panel", style_box)
	parent.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)
	var heading := Label.new()
	heading.text = title_text
	heading.add_theme_font_size_override("font_size", 17)
	heading.add_theme_color_override("font_color", Color("e8ddc8"))
	box.add_child(heading)
	return box


func _add_grid_field(grid: GridContainer, label_text: String, control: Control) -> void:
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size.x = 110
	grid.add_child(label)
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_child(control)


func _make_spin(minimum: float, maximum: float, step_value: float) -> SpinBox:
	var spin := SpinBox.new()
	spin.min_value = minimum
	spin.max_value = maximum
	spin.step = step_value
	spin.allow_greater = false
	spin.allow_lesser = false
	return spin


func _make_button(text_value: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text_value
	button.pressed.connect(callback)
	return button


func _load_styles() -> void:
	_styles.clear()
	_environment_option.clear()
	for path in PRESET_PATHS:
		var style := load(path) as DungeonMusicStyle
		if style != null:
			_styles.append(style)
			_environment_option.add_item(style.display_name)


func _populate_tonal_options() -> void:
	for index in range(KEY_NAMES.size()):
		_key_option.add_item(KEY_NAMES[index], index)
	for mode_name in MODE_NAMES:
		_mode_option.add_item(mode_name.capitalize())


func _populate_instrument_options() -> void:
	var presets := DungeonSoundFontCatalog.read_presets(_soundfont_edit.text)
	var melodic: Array[Dictionary] = []
	var drums: Array[Dictionary] = []
	for preset in presets:
		if int(preset["bank"]) == 0:
			melodic.append(preset)
		elif int(preset["bank"]) == 128:
			drums.append(preset)
	if melodic.is_empty():
		for program in range(128):
			melodic.append({"program": program, "name": "GM Program %03d" % program})
	if drums.is_empty():
		drums.append({"program": 0, "name": "Standard Drum Kit"})
	for layer in ["drone", "melody", "arp"]:
		var option: OptionButton = _program_options[layer]
		for preset in melodic:
			var program := int(preset["program"])
			option.add_item("%03d · %s" % [program, str(preset["name"])], program)
	var drum_option: OptionButton = _program_options["percussion"]
	for preset in drums:
		var program := int(preset["program"])
		drum_option.add_item("%03d · %s" % [program, str(preset["name"])], program)


func _create_preview_player() -> void:
	_preview_player = MidiStreamPlayer.new()
	_preview_player.enable_editor_preview()
	add_child(_preview_player)
	_preview_player.volume_db = -12.0
	_preview_player.max_polyphony = 64
	_preview_player.progress_updated.connect(_on_preview_progress)
	_preview_player.finished.connect(_on_preview_finished)


func _apply_style(index: int) -> void:
	if index < 0 or index >= _styles.size():
		return
	var style := _styles[index]
	_description_label.text = style.description
	_seed_spin.value = randi_range(1, 999999999)
	_tempo_spin.value = roundi((style.tempo_min + style.tempo_max) * 0.5)
	_select_option_id(_key_option, style.root_pitch % 12)
	_select_option_text(_mode_option, style.mode.capitalize())
	_select_option_id(_program_options["drone"], style.drone_program)
	_select_option_id(_program_options["melody"], style.melody_program)
	_select_option_id(_program_options["arp"], style.arp_program)
	_select_option_id(_program_options["percussion"], style.percussion_program)
	_density_sliders["drone"].value = style.drone_density
	_density_sliders["melody"].value = style.melody_density
	_density_sliders["arp"].value = style.arp_density
	_density_sliders["percussion"].value = style.percussion_density
	_current_song = null
	_midi_resource = null
	_update_song_name()


func _on_environment_selected(index: int) -> void:
	_stop_preview()
	_apply_style(index)


func _on_generate_pressed() -> void:
	_generate_current_take()


func _on_new_take_pressed() -> void:
	_seed_spin.value = randi_range(1, 999999999)
	_update_song_name()
	_generate_current_take()


func _generate_current_take() -> bool:
	_stop_preview()
	if _styles.is_empty():
		_set_status("No environment presets could be loaded.")
		return false
	var style := _styles[_environment_option.selected]
	var base_octave := floori(float(style.root_pitch) / 12.0) * 12
	var overrides := {
		"tempo": int(_tempo_spin.value),
		"bars": int(_bars_spin.value),
		"root_pitch": base_octave + _key_option.get_selected_id(),
		"mode": _mode_option.get_item_text(_mode_option.selected).to_lower(),
		"programs": {
			"drone": _program_options["drone"].get_selected_id(),
			"melody": _program_options["melody"].get_selected_id(),
			"arp": _program_options["arp"].get_selected_id(),
			"percussion": _program_options["percussion"].get_selected_id(),
		},
		"densities": {
			"drone": _density_sliders["drone"].value,
			"melody": _density_sliders["melody"].value,
			"arp": _density_sliders["arp"].value,
			"percussion": _density_sliders["percussion"].value,
		},
	}
	_current_song = DungeonMusicGenerator.generate(style, int(_seed_spin.value), overrides)
	_current_song.soundfont_path = _soundfont_edit.text
	_midi_resource = _current_song.create_midi_resource()
	if _midi_resource == null:
		_set_status("Generation failed: Clef could not convert the generated MIDI document.")
		return false
	var note_count := 0
	for track in _midi_resource.tracks:
		note_count += track.notes.size()
	_set_status("Generated %s · seed %d · %d notes · %.1f seconds" % [
		style.display_name, _current_song.seed, note_count, _current_song.get_duration_seconds()
	])
	return true


func _on_play_pressed() -> void:
	if _current_song == null and not _generate_current_take():
		return
	if not FileAccess.file_exists(_soundfont_edit.text):
		_set_status("SoundFont not found: %s" % _soundfont_edit.text)
		return
	_stop_preview()
	_set_status("Loading the SoundFont for preview…")
	await get_tree().process_frame
	var style := _styles[_environment_option.selected]
	_preview_player.reverb_room_size = style.reverb
	_preview_player.reverb_wet = minf(style.reverb, 0.65)
	_preview_player.chorus_wet = style.chorus
	_preview_player.midi_resource = _midi_resource
	if _loaded_soundfont_path != _soundfont_edit.text:
		_preview_player.soundfont = _soundfont_edit.text
		_loaded_soundfont_path = _soundfont_edit.text
	_preview_player.start_playback()
	_set_status("Playing %s (seed %d)." % [_current_song.title, _current_song.seed])


func _stop_preview() -> void:
	if is_instance_valid(_preview_player):
		_preview_player.stop()
	if is_instance_valid(_progress_bar):
		_progress_bar.value = 0.0


func _on_preview_progress(position: float, duration: float) -> void:
	_progress_bar.value = position / duration if duration > 0.0 else 0.0


func _on_preview_finished() -> void:
	_progress_bar.value = 0.0
	_set_status("Preview finished.")


func _on_save_pressed() -> void:
	var result := _save_current_assets()
	if result.get("ok", false):
		_set_status("Saved song recipe and MIDI: %s" % result["midi_path"])


func _on_export_pressed() -> void:
	if _render_thread != null:
		_set_status("A FluidSynth render is already running.")
		return
	var saved := _save_current_assets()
	if not saved.get("ok", false):
		return
	if not FileAccess.file_exists(_soundfont_edit.text):
		_set_status("SoundFont not found: %s" % _soundfont_edit.text)
		return
	var executable := _fluidsynth_edit.text.strip_edges()
	if executable.is_empty():
		executable = "fluidsynth"
	ProjectSettings.set_setting("dungeon_synth/fluidsynth_path", executable)
	ProjectSettings.save()
	_render_wav_path = str(saved["base_path"]) + ".wav"
	var arguments := PackedStringArray([
		"-ni", "-F", ProjectSettings.globalize_path(_render_wav_path),
		"-T", "wav", "-O", "s16", "-r", "48000", "-g", "0.65",
		"-R", "1", "-C", "1",
		ProjectSettings.globalize_path(_soundfont_edit.text),
		ProjectSettings.globalize_path(str(saved["midi_path"])),
	])
	_set_busy(true)
	_set_status("Rendering WAV with FluidSynth…")
	_render_thread = Thread.new()
	var error := _render_thread.start(_run_fluidsynth.bind(executable, arguments))
	if error != OK:
		_render_thread = null
		_set_busy(false)
		_set_status("Could not start the FluidSynth render thread (error %d)." % error)


func _on_test_fluidsynth_pressed() -> void:
	var executable := _fluidsynth_edit.text.strip_edges()
	if executable.is_empty():
		executable = "fluidsynth"
	var output: Array = []
	var exit_code := OS.execute(executable, PackedStringArray(["--version"]), output, true, false)
	if exit_code == 0:
		_set_status("FluidSynth is available. %s" % " ".join(output).strip_edges())
	else:
		_set_status("FluidSynth was not found (exit %d). Restart Godot after changing PATH, or enter the full fluidsynth.exe path." % exit_code)


func _save_current_assets() -> Dictionary:
	# Rebuild from the visible controls so Save/Export can never use stale settings.
	# Since generation is seeded, this produces the same take that was auditioned.
	if not _generate_current_take():
		return {"ok": false}
	var output_dir := _output_edit.text.strip_edges().trim_suffix("/").trim_suffix("\\")
	if output_dir.is_empty():
		_set_status("Choose an output folder first.")
		return {"ok": false}
	var global_dir := ProjectSettings.globalize_path(output_dir)
	var dir_error := DirAccess.make_dir_recursive_absolute(global_dir)
	if dir_error != OK and dir_error != ERR_ALREADY_EXISTS:
		_set_status("Could not create output folder: %s" % output_dir)
		return {"ok": false}
	var slug := _sanitize_filename(_song_name_edit.text)
	if slug.is_empty():
		slug = "dungeon_song_%d" % _current_song.seed
	var base_path := output_dir + "/" + slug
	var resource_path := base_path + ".tres"
	var midi_path := base_path + ".mid"
	var json_path := base_path + ".json"
	var save_error := ResourceSaver.save(_current_song, resource_path)
	if save_error != OK:
		_set_status("Could not save song resource (error %d): %s" % [save_error, resource_path])
		return {"ok": false}
	var midi_file := FileAccess.open(midi_path, FileAccess.WRITE)
	if midi_file == null:
		_set_status("Could not write MIDI: %s" % midi_path)
		return {"ok": false}
	midi_file.store_buffer(MidiWriter.encode(_midi_resource.get_midi_data()))
	var json_file := FileAccess.open(json_path, FileAccess.WRITE)
	if json_file != null:
		json_file.store_string(_current_song.midi_json)
	EditorInterface.get_resource_filesystem().scan_sources()
	return {
		"ok": true,
		"base_path": base_path,
		"resource_path": resource_path,
		"midi_path": midi_path,
		"json_path": json_path,
	}


func _run_fluidsynth(executable: String, arguments: PackedStringArray) -> Dictionary:
	var output: Array = []
	var exit_code := OS.execute(executable, arguments, output, true, false)
	return {"code": exit_code, "output": "\n".join(output)}


func _set_busy(busy: bool) -> void:
	_generate_button.disabled = busy
	_play_button.disabled = busy
	_save_button.disabled = busy
	_export_button.disabled = busy
	if busy:
		_progress_bar.value = 0.5


func _set_status(message: String) -> void:
	_status_label.text = message


func _update_song_name() -> void:
	if _styles.is_empty():
		return
	var style := _styles[_environment_option.selected]
	_song_name_edit.text = "%s_seed_%d" % [str(style.style_id), int(_seed_spin.value)]


func _sanitize_filename(value: String) -> String:
	var result := value.strip_edges().to_lower().replace(" ", "_")
	for character in ["<", ">", ":", "\"", "/", "\\", "|", "?", "*"]:
		result = result.replace(character, "")
	return result


func _select_option_id(option: OptionButton, wanted_id: int) -> void:
	for index in range(option.item_count):
		if option.get_item_id(index) == wanted_id:
			option.select(index)
			return


func _select_option_text(option: OptionButton, wanted_text: String) -> void:
	for index in range(option.item_count):
		if option.get_item_text(index) == wanted_text:
			option.select(index)
			return
