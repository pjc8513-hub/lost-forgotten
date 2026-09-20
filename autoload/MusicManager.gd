extends Node

@onready var player: AudioStreamPlayer = $Music
var current_track: AudioStream
var _playback_id: int = 0

func _ready() -> void:
	player.bus = "Dungeon"
	player.volume_db = -30

func play_music(stream: AudioStream, fade := 0.0, loops := false, loop_delay := 0.0, loop_count := 0) -> void:
	if stream == null:
		stop_music()
		return

	if current_track == stream:
		return

	_playback_id += 1
	var playback_id := _playback_id
	current_track = stream
	player.stream = stream

	# Fade in only the first playback of the track.
	if fade > 0.0:
		player.volume_db = -80.0
		var tween := create_tween()
		tween.tween_property(player, "volume_db", 0.0, fade)
	else:
		player.volume_db = -25.0

	player.play()
	_play_remaining_loops(playback_id, loops, max(0.0, loop_delay), maxi(0, loop_count))


func play_map_music(map_data: MapData) -> void:
	if map_data == null or map_data.music_song == null:
		stop_music()
		return

	play_music(
		map_data.music_song,
		map_data.music_fade_in,
		map_data.music_loops,
		map_data.music_loop_delay,
		map_data.music_loop_count
	)


func _play_remaining_loops(playback_id: int, loops: bool, loop_delay: float, loop_count: int) -> void:
	if not loops or loop_count <= 0:
		return

	await player.finished
	if playback_id != _playback_id:
		return

	if loop_delay > 0.0:
		await get_tree().create_timer(loop_delay).timeout
		if playback_id != _playback_id:
			return

	player.play()
	_play_remaining_loops(playback_id, true, loop_delay, loop_count - 1)

func stop_music(fade := 0.0) -> void:
	_playback_id += 1
	if fade > 0.0:
		var tween := create_tween()
		tween.tween_property(player, "volume_db", -80.0, fade)
		await tween.finished
	
	player.stop()
	current_track = null
