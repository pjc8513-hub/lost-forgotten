extends Node

@onready var player: AudioStreamPlayer = $Music
var current_track: AudioStream

func _ready() -> void:
	player.bus = "Dungeon"
	player.volume_db = -30

func play_music(stream: AudioStream, fade := 0.0) -> void:
	if current_track == stream:
		return

	current_track = stream
	player.stream = stream
	
	# Optional: fade in example
	if fade > 0.0:
		player.volume_db = -80.0
		player.play()
		var tween := create_tween()
		tween.tween_property(player, "volume_db", 0.0, fade)
	else:
		player.volume_db = -25.0
		player.play()

func stop_music(fade := 0.0) -> void:
	if fade > 0.0:
		var tween := create_tween()
		tween.tween_property(player, "volume_db", -80.0, fade)
		await tween.finished
	
	player.stop()
	current_track = null
