class_name RaceData
extends Resource

enum SelectedRace{
	UNKNOWN = -1,
	HUMAN,
	ELF,
	DWARF,
	GNOME
}
@export_group ("Race Bonus Stats")
@export var bonus_strength: int = 0
@export var bonus_endurance: int = 0
@export var bonus_dexterity: int = 0
@export var bonus_wisdom: int = 0
@export var bonus_willpower: int = 0
@export var bonus_piety: int = 0

@export_group("Race Starting Skills")
@export var starting_skills: Array[String] = []
