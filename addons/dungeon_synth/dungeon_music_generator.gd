@tool
class_name DungeonMusicGenerator
extends RefCounted

const MODES := {
	"aeolian": [0, 2, 3, 5, 7, 8, 10],
	"dorian": [0, 2, 3, 5, 7, 9, 10],
	"phrygian": [0, 1, 3, 5, 7, 8, 10],
	"locrian": [0, 1, 3, 5, 6, 8, 10],
	"mixolydian": [0, 2, 4, 5, 7, 9, 10],
	"lydian": [0, 2, 4, 6, 7, 9, 11],
	"ionian": [0, 2, 4, 5, 7, 9, 11],
}


static func generate(style: DungeonMusicStyle, seed_value: int, overrides: Dictionary = {}) -> DungeonSong:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var tempo := int(overrides.get("tempo", rng.randi_range(style.tempo_min, style.tempo_max)))
	var bars := int(overrides.get("bars", 16))
	var root_pitch := int(overrides.get("root_pitch", style.root_pitch))
	var mode := str(overrides.get("mode", style.mode))
	if not MODES.has(mode):
		mode = style.mode
	var programs: Dictionary = overrides.get("programs", {})
	var densities: Dictionary = overrides.get("densities", {})
	var total_beats := bars * 4
	var scale := _get_scale(root_pitch, mode, 3)
	var intervals: Array = MODES[mode]
	var third := root_pitch + int(intervals[2])
	var fifth := root_pitch + int(intervals[4])

	var drone_notes := _generate_drone(
		rng, root_pitch, third, fifth, total_beats,
		float(densities.get("drone", style.drone_density))
	)
	var melody_notes := _generate_melody(
		rng, scale, root_pitch, total_beats,
		float(densities.get("melody", style.melody_density)),
		style.rest_probability, style.leap_probability
	)
	var arp_notes := _generate_arp(
		rng, [root_pitch + 12, third + 12, fifth + 12, root_pitch + 24],
		total_beats, float(densities.get("arp", style.arp_density))
	)
	var percussion_notes := _generate_percussion(
		rng, style.percussion_notes, total_beats,
		float(densities.get("percussion", style.percussion_density))
	)

	var tracks: Array[Dictionary] = [
		_make_track("Drone", 0, int(programs.get("drone", style.drone_program)), drone_notes, style.drone_volume, 54, style),
		_make_track("Melody", 1, int(programs.get("melody", style.melody_program)), melody_notes, style.melody_volume, 74, style),
		_make_track("Arpeggio", 2, int(programs.get("arp", style.arp_program)), arp_notes, style.arp_volume, 44, style),
		_make_track("Percussion", 9, int(programs.get("percussion", style.percussion_program)), percussion_notes, style.percussion_volume, 64, style),
	]
	var document := {
		"format_version": "2.0",
		"title": style.display_name,
		"tempo": tempo,
		"timebase": 480,
		"tracks": tracks,
	}
	var song := DungeonSong.new()
	song.title = style.display_name
	song.style_id = style.style_id
	song.seed = seed_value
	song.tempo = tempo
	song.bars = bars
	song.root_pitch = root_pitch
	song.mode = mode
	song.layer_programs = {
		"drone": int(programs.get("drone", style.drone_program)),
		"melody": int(programs.get("melody", style.melody_program)),
		"arp": int(programs.get("arp", style.arp_program)),
		"percussion": int(programs.get("percussion", style.percussion_program)),
	}
	song.midi_json = JSON.stringify(document, "  ")
	return song


static func _get_scale(root_pitch: int, mode: String, octaves: int) -> Array[int]:
	var notes: Array[int] = []
	for octave in range(octaves):
		for interval in MODES[mode]:
			notes.append(root_pitch + int(interval) + octave * 12)
	return notes


static func _generate_drone(rng: RandomNumberGenerator, root: int, third: int, fifth: int, total_beats: int, density: float) -> Array[Dictionary]:
	var notes: Array[Dictionary] = []
	for start in range(0, total_beats, 8):
		if start > 0 and rng.randf() > density:
			continue
		var duration := minf(8.25, float(total_beats - start))
		_add_note(notes, root, start, duration, rng.randi_range(50, 66))
		_add_note(notes, fifth, start, duration, rng.randi_range(46, 62))
		if rng.randf() < 0.4:
			_add_note(notes, third + 12, start, duration, rng.randi_range(38, 54))
	return notes


static func _generate_melody(rng: RandomNumberGenerator, scale: Array[int], root: int, total_beats: int, density: float, rest_probability: float, leap_probability: float) -> Array[Dictionary]:
	var notes: Array[Dictionary] = []
	var last_note := scale[scale.size() / 2]
	var motif: Array[Dictionary] = []
	var recalled_motif: Array[Dictionary] = []
	var recall_index := 0
	for beat in range(total_beats):
		var phrase_density := density * _phrase_multiplier(beat, total_beats)
		if rng.randf() > phrase_density or rng.randf() < rest_probability:
			continue
		var pitch: int
		var duration: float
		if recall_index < recalled_motif.size():
			pitch = int(recalled_motif[recall_index]["pitch"])
			duration = float(recalled_motif[recall_index]["duration"])
			recall_index += 1
		else:
			recalled_motif.clear()
			recall_index = 0
			var step := 1 if rng.randf() > 0.5 else -1
			if rng.randf() < leap_probability:
				step *= [2, 3, 4][rng.randi_range(0, 2)]
			var scale_index := clampi(scale.find(last_note) + step, 0, scale.size() - 1)
			pitch = scale[scale_index]
			last_note = pitch
			duration = [0.5, 1.0, 2.0][rng.randi_range(0, 2)]
			motif.append({"pitch": pitch, "duration": duration})
			if motif.size() > 5:
				motif.pop_front()
			if motif.size() >= 3 and rng.randf() < 0.12:
				recalled_motif = motif.duplicate(true)
		_add_note(notes, pitch, beat, minf(duration, total_beats - beat), rng.randi_range(72, 108))
	if total_beats >= 2:
		_add_note(notes, root + 12, total_beats - 2, 1.9, 82)
	return notes


static func _generate_arp(rng: RandomNumberGenerator, chord: Array, total_beats: int, density: float) -> Array[Dictionary]:
	var notes: Array[Dictionary] = []
	var chord_index := 0
	for half_beat in range(total_beats * 2):
		var start := float(half_beat) * 0.5
		if rng.randf() > density * _phrase_multiplier(half_beat, total_beats * 2):
			continue
		_add_note(notes, int(chord[chord_index % chord.size()]), start, 0.22, rng.randi_range(48, 78))
		chord_index += 1
	return notes


static func _generate_percussion(rng: RandomNumberGenerator, drum_notes: PackedInt32Array, total_beats: int, density: float) -> Array[Dictionary]:
	var notes: Array[Dictionary] = []
	if drum_notes.is_empty():
		return notes
	for half_beat in range(total_beats * 2):
		var start := float(half_beat) * 0.5
		var accent := 1.35 if half_beat % 8 == 0 else 1.0
		if rng.randf() > density * accent * _phrase_multiplier(half_beat, total_beats * 2):
			continue
		var note_index := 0 if half_beat % 8 == 0 else rng.randi_range(0, drum_notes.size() - 1)
		_add_note(notes, drum_notes[note_index], start, 0.12, rng.randi_range(58, 100))
	return notes


static func _make_track(name: String, channel: int, program: int, notes: Array[Dictionary], volume: int, pan: int, style: DungeonMusicStyle) -> Dictionary:
	return {
		"name": name,
		"channel": channel,
		"instrument": program,
		"notes": notes,
		"cc_events": [
			{"time": 0.0, "controller": 7, "value": volume},
			{"time": 0.0, "controller": 10, "value": pan},
			{"time": 0.0, "controller": 91, "value": roundi(style.reverb * 127.0)},
			{"time": 0.0, "controller": 93, "value": roundi(style.chorus * 127.0)},
		],
	}


static func _add_note(notes: Array[Dictionary], pitch: int, start: float, duration: float, velocity: int) -> void:
	if duration <= 0.0:
		return
	notes.append({
		"pitch": clampi(pitch, 0, 127),
		"start": snappedf(start, 0.001),
		"duration": snappedf(duration, 0.001),
		"velocity": clampi(velocity, 1, 127),
	})


static func _phrase_multiplier(position: int, total: int) -> float:
	if total <= 0:
		return 1.0
	var progress := float(position) / float(total)
	if progress < 0.125:
		return 0.65
	if progress > 0.875:
		return 0.72
	if progress > 0.45 and progress < 0.72:
		return 1.18
	return 1.0

