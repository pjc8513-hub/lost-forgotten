class_name OrganComponent
extends Node

const ORGAN_INTERFACE_SCENE := preload("res://scenes/ui/organ_interface.tscn")
const MIX_RATE := 44100.0
const TAU_FLOAT := TAU
const MAX_SEQUENCE_NOTES := 16
const MELODY_SUCCESS_DELAY := 0.75

@export var organ_data: OrganData

var _active := false
var _previous_turn_state: TurnManager.State
var _interface: OrganInterface
var _audio_player: AudioStreamPlayer
var _generator_playback: AudioStreamGeneratorPlayback
var _bus_name: StringName
var _voices: Dictionary = {}
var _played_notes := PackedStringArray()
var _melody_pending := false
var _pending_melody_name := ""
var _remove_on_close := false


func _ready() -> void:
	var interactable := get_parent().get_node_or_null("InteractableComponent") as InteractableComponent
	if interactable != null:
		interactable.interaction_text = "Play organ"
		interactable.interacted.connect(_on_interacted)
	_setup_audio()
	set_process_unhandled_input(false)
	set_process(false)


func _exit_tree() -> void:
	_close_interface()
	if _audio_player != null:
		_audio_player.stop()
	if not _bus_name.is_empty():
		var bus_index := AudioServer.get_bus_index(_bus_name)
		if bus_index >= 0:
			AudioServer.remove_bus(bus_index)


func _process(_delta: float) -> void:
	if _generator_playback == null:
		return
	_fill_audio_buffer()


func _unhandled_input(event: InputEvent) -> void:
	if not _active or not (event is InputEventKey):
		return

	var key_event := event as InputEventKey
	if key_event.pressed and key_event.keycode == KEY_ESCAPE:
		_close_interface()
		get_viewport().set_input_as_handled()
		return
	if _melody_pending:
		get_viewport().set_input_as_handled()
		return

	var key := _event_key(key_event)
	var note := organ_data.get_note_for_key(key) if organ_data != null else ""
	if note.is_empty():
		return

	if key_event.pressed:
		if not key_event.echo and not _voices.has(key):
			_start_note(key, note)
	else:
		_release_note(key, note)
	get_viewport().set_input_as_handled()


func _on_interacted(_actor: Node) -> void:
	if _active or organ_data == null:
		return
	_open_interface()


func open_for_data(data: OrganData, remove_on_close: bool = true) -> void:
	if _active or data == null:
		return
	organ_data = data
	_remove_on_close = remove_on_close
	if _audio_player == null:
		_setup_audio()
	_open_interface()


func _open_interface() -> void:
	_active = true
	_melody_pending = false
	_pending_melody_name = ""
	_previous_turn_state = TurnManager.state
	TurnManager.set_state(TurnManager.State.PAUSED)
	_played_notes.clear()
	_interface = ORGAN_INTERFACE_SCENE.instantiate() as OrganInterface
	get_tree().root.add_child(_interface)
	_interface.configure(organ_data)
	_interface.close_requested.connect(_close_interface)
	set_process_unhandled_input(true)


func _close_interface() -> void:
	if not _active and _interface == null:
		return
	_active = false
	_melody_pending = false
	_pending_melody_name = ""
	set_process_unhandled_input(false)
	for key in _voices:
		var voice: Dictionary = _voices[key]
		voice["releasing"] = true
		_voices[key] = voice
	if _interface != null:
		_interface.queue_free()
		_interface = null
	if TurnManager.state == TurnManager.State.PAUSED:
		TurnManager.set_state(_previous_turn_state)
	if _remove_on_close:
		queue_free()


func _start_note(key: String, note: String) -> void:
	_voices[key] = {
		"frequency": _note_frequency(note),
		"phase": 0.0,
		"level": 0.0,
		"releasing": false,
	}
	_ensure_audio_playing()
	if _interface != null:
		_interface.show_key(key, note, true)

	var normalized_note := MelodyData.normalize_note(note)
	_played_notes.append(normalized_note)
	if _interface != null:
		_interface.show_sequence(_played_notes)
	if _check_melody():
		return
	if _played_notes.size() >= MAX_SEQUENCE_NOTES:
		_played_notes.clear()
		if _interface != null:
			_interface.show_sequence(_played_notes)


func _release_note(key: String, note: String) -> void:
	if _voices.has(key):
		var voice: Dictionary = _voices[key]
		voice["releasing"] = true
		_voices[key] = voice
	if _interface != null:
		_interface.show_key(key, note, false)


func _check_melody() -> bool:
	var melody := organ_data.accepted_melody
	if melody == null or not melody.matches(_played_notes):
		return false
	_pending_melody_name = melody.display_name
	if _pending_melody_name.is_empty():
		_pending_melody_name = str(melody.melodyID)
	_melody_pending = true
	get_tree().create_timer(MELODY_SUCCESS_DELAY).timeout.connect(_complete_melody, CONNECT_ONE_SHOT)
	return true


func _complete_melody() -> void:
	if not _melody_pending:
		return
	var melody_name := _pending_melody_name
	_close_interface()
	MapManager.request_alert("You played the %s melody" % melody_name)


func _setup_audio() -> void:
	if organ_data == null:
		return

	_bus_name = StringName("Organ_%s" % get_instance_id())
	AudioServer.add_bus()
	var bus_index := AudioServer.bus_count - 1
	AudioServer.set_bus_name(bus_index, _bus_name)
	AudioServer.set_bus_send(bus_index, &"Master")
	AudioServer.set_bus_volume_db(bus_index, organ_data.volume_db)

	var low_pass := AudioEffectLowPassFilter.new()
	low_pass.cutoff_hz = organ_data.tone_cutoff_hz
	AudioServer.add_bus_effect(bus_index, low_pass)

	if organ_data.reverb_enabled:
		var reverb := AudioEffectReverb.new()
		reverb.room_size = organ_data.reverb_room_size
		reverb.damping = organ_data.reverb_damping
		reverb.wet = organ_data.reverb_wet
		reverb.dry = 1.0
		AudioServer.add_bus_effect(bus_index, reverb)

	var generator := AudioStreamGenerator.new()
	generator.mix_rate = MIX_RATE
	generator.buffer_length = 0.12
	_audio_player = AudioStreamPlayer.new()
	_audio_player.stream = generator
	_audio_player.bus = _bus_name
	add_child(_audio_player)


func _ensure_audio_playing() -> void:
	if _audio_player == null:
		return
	if not _audio_player.playing:
		_audio_player.play()
		_generator_playback = _audio_player.get_stream_playback() as AudioStreamGeneratorPlayback
	set_process(_generator_playback != null)


func _fill_audio_buffer() -> void:
	var frames_available := _generator_playback.get_frames_available()
	for _frame in frames_available:
		var sample := 0.0
		var finished_keys: Array[String] = []
		for key_value in _voices:
			var key := str(key_value)
			var voice: Dictionary = _voices[key_value]
			var level: float = voice["level"]
			var releasing: bool = voice["releasing"]
			if releasing:
				level = maxf(0.0, level - 1.0 / (MIX_RATE * organ_data.release_seconds))
			else:
				level = minf(1.0, level + 1.0 / (MIX_RATE * organ_data.attack_seconds))
			if level <= 0.0 and releasing:
				finished_keys.append(key)
				continue

			var phase: float = voice["phase"]
			var frequency: float = voice["frequency"]
			var pipe_tone := (
				sin(phase) * 0.56
				+ sin(phase * 2.0) * 0.22
				+ sin(phase * 3.0) * 0.11
				+ sin(phase * 4.0) * 0.05
				+ sin(phase * 0.5) * organ_data.sub_octave_level
				+ sin(phase * 1.003 + 0.7) * 0.06
			)
			sample += pipe_tone * level * 0.16
			phase = fmod(phase + TAU_FLOAT * frequency / MIX_RATE, TAU_FLOAT)
			voice["phase"] = phase
			voice["level"] = level
			_voices[key_value] = voice

		for key in finished_keys:
			_voices.erase(key)
		sample = clampf(sample, -0.92, 0.92)
		_generator_playback.push_frame(Vector2(sample, sample))
	if _voices.is_empty():
		_audio_player.stop()
		_generator_playback = null
		set_process(false)


func _event_key(event: InputEventKey) -> String:
	var keycode := event.keycode
	if keycode == 0:
		keycode = event.physical_keycode
	return OS.get_keycode_string(keycode).to_lower()


func _note_frequency(note: String) -> float:
	var normalized := note.strip_edges().to_upper()
	var octave := 4
	if not normalized.is_empty() and normalized[-1].is_valid_int():
		octave = int(normalized.right(1))
		normalized = normalized.left(-1)
	var semitone_lookup := {
		"C": 0, "C#": 1, "DB": 1, "D": 2, "D#": 3, "EB": 3,
		"E": 4, "F": 5, "F#": 6, "GB": 6, "G": 7, "G#": 8,
		"AB": 8, "A": 9, "A#": 10, "BB": 10, "B": 11,
	}
	var semitone := int(semitone_lookup.get(normalized, 0))
	var midi_note := (octave + 1) * 12 + semitone
	return 440.0 * pow(2.0, (midi_note - 69) / 12.0)
