class_name OrganInterface
extends CanvasLayer

signal close_requested

const NORMAL_KEY_COLOR := Color("261c1a")
const SHARP_KEY_COLOR := Color("100d10")
const PRESSED_KEY_COLOR := Color("a36b2c")
const KEY_BORDER_COLOR := Color("b58a4a")

@onready var title_label: Label = $Root/Center/Panel/Margin/Content/Title
@onready var current_key_label: Label = $Root/Center/Panel/Margin/Content/CurrentKey
@onready var sequence_label: Label = $Root/Center/Panel/Margin/Content/Sequence
@onready var key_grid: GridContainer = $Root/Center/Panel/Margin/Content/KeyGrid
@onready var close_button: Button = $Root/Center/Panel/Margin/Content/Close

var _key_panels: Dictionary = {}


func _ready() -> void:
	close_button.pressed.connect(close_requested.emit)


func configure(data: OrganData) -> void:
	title_label.text = data.display_name
	current_key_label.text = "Press a key"
	sequence_label.text = "Melody: —"

	for child in key_grid.get_children():
		child.queue_free()
	_key_panels.clear()

	for key_value in data.key_notes:
		var key := str(key_value).to_lower()
		var note := str(data.key_notes[key_value])
		var panel := _create_key_panel(key, note)
		key_grid.add_child(panel)
		_key_panels[key] = panel


func show_key(key: String, note: String, pressed: bool) -> void:
	var normalized_key := key.to_lower()
	var panel := _key_panels.get(normalized_key) as PanelContainer
	if panel != null:
		panel.add_theme_stylebox_override(
			"panel",
			_make_key_style(PRESSED_KEY_COLOR if pressed else _key_color(note))
		)
	current_key_label.text = (
		"%s  →  %s" % [normalized_key.to_upper(), _display_note(note)]
		if pressed
		else "Release: %s" % normalized_key.to_upper()
	)


func show_sequence(notes: PackedStringArray) -> void:
	sequence_label.text = "Melody: %s" % (" — " if notes.is_empty() else "  ".join(notes))


func _create_key_panel(key: String, note: String) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(72, 54)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", _make_key_style(_key_color(note)))

	var labels := VBoxContainer.new()
	labels.alignment = BoxContainer.ALIGNMENT_CENTER
	labels.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var key_label := Label.new()
	key_label.text = key.to_upper()
	key_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	key_label.add_theme_font_size_override("font_size", 18)
	key_label.add_theme_color_override("font_color", Color("f4dba6"))

	var note_label := Label.new()
	note_label.text = _display_note(note)
	note_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note_label.add_theme_font_size_override("font_size", 12)
	note_label.add_theme_color_override("font_color", Color("c8b58d"))

	labels.add_child(key_label)
	labels.add_child(note_label)
	panel.add_child(labels)
	return panel


func _make_key_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = KEY_BORDER_COLOR
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	style.set_content_margin_all(5)
	return style


func _key_color(note: String) -> Color:
	return SHARP_KEY_COLOR if "#" in note else NORMAL_KEY_COLOR


func _display_note(note: String) -> String:
	return note.replace("#", "♯")
