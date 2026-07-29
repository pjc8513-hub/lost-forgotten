class_name OrganInterface
extends CanvasLayer

signal close_requested

@onready var title_label: Label = $Root/Center/Panel/Margin/Content/Title
@onready var current_key_label: Label = $Root/Center/Panel/Margin/Content/CurrentKey
@onready var sequence_label: Label = $Root/Center/Panel/Margin/Content/Sequence
@onready var key_grid: PianoKeyboardComponent = $Root/Center/Panel/Margin/Content/KeyBoard
@onready var close_button: Button = $Root/Center/Panel/Margin/Content/Close

func _ready() -> void:
	close_button.pressed.connect(close_requested.emit)


func configure(data: OrganData) -> void:
	title_label.text = data.display_name
	current_key_label.text = "Press a key"
	sequence_label.text = "Melody: —"
	key_grid.build(data.key_notes)

func show_key(key: String, note: String, pressed: bool) -> void:
	var normalized_key := key.to_lower()
	key_grid.show_key(normalized_key, pressed)
	current_key_label.text = (
		"%s  →  %s" % [normalized_key.to_upper(), _display_note(note)]
		if pressed
		else "Release: %s" % normalized_key.to_upper()
	)


func show_sequence(notes: PackedStringArray) -> void:
	sequence_label.text = "Melody: %s" % (" — " if notes.is_empty() else "  ".join(notes))


func _display_note(note: String) -> String:
	return note.replace("#", "♯")
