class_name PianoKeyboardComponent
extends Control
## Single responsibility: lay out and render a piano-style keyboard from a
## key->note mapping, and expose visual press state. Knows nothing about
## input handling or game logic — OrganInterface drives it.

const WHITE_KEY_WIDTH := 46.0
const WHITE_KEY_HEIGHT := 160.0
const BLACK_KEY_WIDTH := 30.0
const BLACK_KEY_HEIGHT := 100.0

const NORMAL_KEY_COLOR := Color("f4ecd8")
const SHARP_KEY_COLOR := Color("1a1512")
const PRESSED_WHITE_COLOR := Color("d9a552")
const PRESSED_BLACK_COLOR := Color("a36b2c")
const KEY_BORDER_COLOR := Color("6b5638")
const LABEL_WHITE_COLOR := Color("3a2e1f")
const LABEL_BLACK_COLOR := Color("d8c9a3")

# Where each white key sits within its octave, in white-key-widths.
const WHITE_STEPS := {"C": 0, "D": 1, "E": 2, "F": 3, "G": 4, "A": 5, "B": 6}
# Where each black key's center sits within its octave, in white-key-widths.
# (No black key between E-F or B-C, which is why the gaps aren't even.)
const BLACK_OFFSETS := {"C": 0.65, "D": 1.75, "F": 3.55, "G": 4.6, "A": 5.7}

var _key_panels: Dictionary = {}   # input key -> PanelContainer
var _key_notes: Dictionary = {}    # input key -> note string, for show_key()

func build(key_notes: Dictionary) -> void:
	for child in get_children():
		child.queue_free()
	_key_panels.clear()
	_key_notes.clear()

	var parsed: Dictionary = {}
	for key_value in key_notes:
		var key := str(key_value).to_lower()
		var note := str(key_notes[key_value])
		_key_notes[key] = note
		parsed[key] = _parse_note(note)

	if parsed.is_empty():
		custom_minimum_size = Vector2.ZERO
		return

	var min_slot := INF
	var max_slot := -INF
	var ordered_keys: Array = parsed.keys()
	ordered_keys.sort_custom(func(a: String, b: String) -> bool:
		return _white_slot(parsed[a]) < _white_slot(parsed[b])
	)

	for key in ordered_keys:
		var slot: float = _white_slot(parsed[key])
		min_slot = min(min_slot, floor(slot))
		max_slot = max(max_slot, ceil(slot))

	# White keys added first so black keys naturally draw on top of them.
	for key in ordered_keys:
		if not parsed[key].sharp:
			_add_white_key(key, parsed[key], min_slot)
	for key in ordered_keys:
		if parsed[key].sharp:
			_add_black_key(key, parsed[key], min_slot)

	custom_minimum_size = Vector2((max_slot - min_slot + 1) * WHITE_KEY_WIDTH, WHITE_KEY_HEIGHT)

func show_key(key: String, pressed: bool) -> void:
	var normalized := key.to_lower()
	var panel := _key_panels.get(normalized) as PanelContainer
	if panel == null:
		return
	var sharp := "#" in str(_key_notes.get(normalized, ""))
	var color: Color
	if pressed:
		color = PRESSED_BLACK_COLOR if sharp else PRESSED_WHITE_COLOR
	else:
		color = SHARP_KEY_COLOR if sharp else NORMAL_KEY_COLOR
	panel.add_theme_stylebox_override("panel", _make_style(color))

func _white_slot(parsed: Dictionary) -> float:
	if parsed.sharp:
		return parsed.octave * 7 + BLACK_OFFSETS[parsed.letter]
	return parsed.octave * 7 + WHITE_STEPS[parsed.letter]

func _add_white_key(key: String, parsed: Dictionary, min_slot: float) -> void:
	var slot: float = _white_slot(parsed) - min_slot
	var panel := PanelContainer.new()
	panel.position = Vector2(slot * WHITE_KEY_WIDTH, 0)
	panel.size = Vector2(WHITE_KEY_WIDTH - 2, WHITE_KEY_HEIGHT)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", _make_style(NORMAL_KEY_COLOR))
	_add_key_label(panel, key, _key_notes[key], LABEL_WHITE_COLOR)
	add_child(panel)
	_key_panels[key] = panel

func _add_black_key(key: String, parsed: Dictionary, min_slot: float) -> void:
	var slot: float = _white_slot(parsed) - min_slot
	var panel := PanelContainer.new()
	panel.position = Vector2(slot * WHITE_KEY_WIDTH - BLACK_KEY_WIDTH * 0.5, 0)
	panel.size = Vector2(BLACK_KEY_WIDTH, BLACK_KEY_HEIGHT)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.z_index = 1
	panel.add_theme_stylebox_override("panel", _make_style(SHARP_KEY_COLOR))
	_add_key_label(panel, key, _key_notes[key], LABEL_BLACK_COLOR)
	add_child(panel)
	_key_panels[key] = panel

func _add_key_label(panel: PanelContainer, key: String, note: String, color: Color) -> void:
	var labels := VBoxContainer.new()
	labels.alignment = BoxContainer.ALIGNMENT_END
	labels.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var key_label := Label.new()
	key_label.text = key.to_upper()
	key_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	key_label.add_theme_font_size_override("font_size", 15)
	key_label.add_theme_color_override("font_color", color)
	labels.add_child(key_label)
	var note_label := Label.new()
	note_label.text = note.replace("#", "♯")
	note_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note_label.add_theme_font_size_override("font_size", 10)
	note_label.add_theme_color_override("font_color", color)
	labels.add_child(note_label)
	panel.add_child(labels)

func _make_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = KEY_BORDER_COLOR
	style.set_border_width_all(1)
	style.set_corner_radius_all(2)
	return style

func _parse_note(note: String) -> Dictionary:
	var normalized := note.strip_edges().to_upper()
	var sharp := "#" in normalized
	var letter := normalized.substr(0, 1)
	var octave_str := normalized.substr(2 if sharp else 1)
	var octave := int(octave_str) if octave_str.is_valid_int() else 4
	if (sharp and not BLACK_OFFSETS.has(letter)) or (not sharp and not WHITE_STEPS.has(letter)):
		letter = "C"
	return {"letter": letter, "sharp": sharp, "octave": octave}
