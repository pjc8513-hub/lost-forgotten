@tool
class_name DungeonMusicStyle
extends Resource

@export var style_id: StringName
@export var display_name: String
@export_multiline var description: String
@export_range(0, 127, 1) var root_pitch: int = 48
@export_enum("aeolian", "dorian", "phrygian", "locrian", "mixolydian", "lydian", "ionian") var mode: String = "dorian"
@export_range(30, 220, 1) var tempo_min: int = 60
@export_range(30, 220, 1) var tempo_max: int = 75

@export_group("Layer density")
@export_range(0.0, 1.0, 0.01) var drone_density: float = 0.7
@export_range(0.0, 1.0, 0.01) var melody_density: float = 0.35
@export_range(0.0, 1.0, 0.01) var arp_density: float = 0.25
@export_range(0.0, 1.0, 0.01) var percussion_density: float = 0.1
@export_range(0.0, 1.0, 0.01) var rest_probability: float = 0.35
@export_range(0.0, 1.0, 0.01) var leap_probability: float = 0.15

@export_group("Arachno programs")
@export_range(0, 127, 1) var drone_program: int = 89
@export_range(0, 127, 1) var melody_program: int = 73
@export_range(0, 127, 1) var arp_program: int = 46
@export_range(0, 127, 1) var percussion_program: int = 0
@export var percussion_notes: PackedInt32Array = PackedInt32Array([36, 38, 42])

@export_group("Mix")
@export_range(0, 127, 1) var drone_volume: int = 78
@export_range(0, 127, 1) var melody_volume: int = 104
@export_range(0, 127, 1) var arp_volume: int = 82
@export_range(0, 127, 1) var percussion_volume: int = 88
@export_range(0.0, 1.0, 0.01) var reverb: float = 0.35
@export_range(0.0, 1.0, 0.01) var chorus: float = 0.1

