@tool
class_name DungeonSong
extends Resource

const GENERATOR_VERSION := "0.1.0"

@export_category("Identity")
@export var title: String = "Dungeon Song"
@export var style_id: StringName
@export var seed: int
@export var generator_version: String = GENERATOR_VERSION

@export_category("Composition")
@export_range(1, 999, 1) var tempo: int = 70
@export_range(1, 256, 1) var bars: int = 16
@export_range(0, 127, 1) var root_pitch: int = 48
@export var mode: String = "dorian"
@export var layer_programs: Dictionary = {}

@export_category("Rendering")
@export_file("*.sf2") var soundfont_path: String
@export_multiline var midi_json: String


func create_midi_resource() -> MidiResource:
	var resource := MidiResource.new()
	if not resource.from_json_string(midi_json):
		return null
	return resource


func get_duration_seconds() -> float:
	return float(bars * 4) * 60.0 / float(maxi(tempo, 1))

