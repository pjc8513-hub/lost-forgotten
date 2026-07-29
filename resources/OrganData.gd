class_name OrganData
extends Resource

@export var organID: StringName
@export var display_name: String = "Pipe Organ"
@export var accepted_melody: MelodyData

@export_group("Keyboard")
@export var key_notes: Dictionary = {
	"a": "C4",
	"b": "D4",
	"e": "E4",
	"d": "F4",
	"f": "G4",
	"h": "A4",
	"j": "B4",
	"z": "C#4",
	"x": "D#4",
	"c": "F#4",
	"v": "G#4",
	"n": "A#4",
}

@export_group("Pipe Tone")
@export_range(-40.0, 6.0, 0.5) var volume_db: float = -10.0
@export_range(0.01, 1.0, 0.01) var attack_seconds: float = 0.08
@export_range(0.02, 2.0, 0.01) var release_seconds: float = 0.45
@export_range(0.0, 1.0, 0.01) var sub_octave_level: float = 0.28
@export_range(500.0, 12000.0, 100.0) var tone_cutoff_hz: float = 4800.0

@export_group("Cathedral Reverb")
@export var reverb_enabled: bool = true
@export_range(0.0, 1.0, 0.01) var reverb_room_size: float = 0.92
@export_range(0.0, 1.0, 0.01) var reverb_damping: float = 0.38
@export_range(0.0, 1.0, 0.01) var reverb_wet: float = 0.48


func get_note_for_key(key: String) -> String:
	return str(key_notes.get(key.to_lower(), ""))
