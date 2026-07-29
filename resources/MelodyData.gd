class_name MelodyData
extends Resource

@export var melodyID: StringName
@export var display_name: String = "Unknown"
@export var notes: String


func get_notes() -> PackedStringArray:
	var parsed_notes := PackedStringArray()
	var normalized_source := notes.replace(",", " ")
	for raw_note in normalized_source.split(" ", false):
		var note := normalize_note(raw_note)
		if not note.is_empty():
			parsed_notes.append(note)
	return parsed_notes


func matches(played_notes: PackedStringArray) -> bool:
	var expected := get_notes()
	if expected.is_empty() or played_notes.size() < expected.size():
		return false

	var offset := played_notes.size() - expected.size()
	for index in expected.size():
		if normalize_note(played_notes[offset + index]) != expected[index]:
			return false
	return true


static func normalize_note(note: String) -> String:
	var normalized := note.strip_edges().to_upper().replace("♯", "#").replace("♭", "B")
	while not normalized.is_empty() and normalized[-1].is_valid_int():
		normalized = normalized.left(-1)
	return normalized
