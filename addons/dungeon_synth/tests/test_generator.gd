extends SceneTree


func _init() -> void:
	var style := load("res://addons/dungeon_synth/presets/castle_dungeon.tres") as DungeonMusicStyle
	assert(style != null, "Castle Dungeon preset must load")
	var overrides := {"tempo": 52, "bars": 16}
	var first := DungeonMusicGenerator.generate(style, 123456, overrides)
	var second := DungeonMusicGenerator.generate(style, 123456, overrides)
	var different := DungeonMusicGenerator.generate(style, 654321, overrides)
	assert(first.midi_json == second.midi_json, "Same seed must produce identical MIDI")
	assert(first.midi_json != different.midi_json, "Different seeds should produce a different take")
	var midi := first.create_midi_resource()
	assert(midi != null, "Generated document must convert through Clef")
	assert(midi.tracks.size() == 4, "Generated song must have four layers")
	assert(midi.tempo == 52, "Tempo override must be preserved")
	assert(midi.get_duration_seconds() > 60.0, "Sixteen slow bars should exceed one minute")
	var note_count := 0
	for track in midi.tracks:
		for note in track.notes:
			assert(note.pitch >= 0 and note.pitch <= 127, "Pitches must remain in MIDI range")
			assert(note.duration_ticks > 0, "Every note must have positive duration")
			note_count += 1
	assert(note_count > 10, "Preset should generate a non-empty arrangement")
	var midi_bytes := MidiWriter.encode(midi.get_midi_data())
	assert(midi_bytes.size() > 64, "Encoded MIDI should contain events")
	assert(midi_bytes.slice(0, 4).get_string_from_ascii() == "MThd", "Encoded file must have a MIDI header")
	var integration_midi_path := "user://dungeon_synth_test.mid"
	var integration_midi := FileAccess.open(integration_midi_path, FileAccess.WRITE)
	assert(integration_midi != null, "Integration MIDI output should be writable")
	integration_midi.store_buffer(midi_bytes)
	integration_midi.close()
	var recipe_path := "user://dungeon_synth_test.tres"
	assert(ResourceSaver.save(first, recipe_path) == OK, "Song recipe should save as a Resource")
	var loaded_recipe := load(recipe_path) as DungeonSong
	assert(loaded_recipe != null and loaded_recipe.seed == first.seed, "Saved recipe should load with its seed intact")
	var presets := DungeonSoundFontCatalog.read_presets("res://assets/audio/music/Arachno SoundFont - Version 1.0.sf2")
	assert(presets.size() == 138, "Arachno catalog should expose 138 presets")
	assert(presets[0]["name"] == "Grand Piano", "SF2 preset names should not contain padding")
	print("Dungeon Synth tests passed: %d notes, %d MIDI bytes, %d SF2 presets" % [note_count, midi_bytes.size(), presets.size()])
	print("Integration MIDI: %s" % ProjectSettings.globalize_path(integration_midi_path))
	quit(0)
