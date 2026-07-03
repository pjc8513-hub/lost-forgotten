# TitleScene.gd
extends Control

const PARTY_SETUP := preload(
	"res://scenes/ui/CharacterFactory/PartySetupScreen.tscn"
)

func _ready():
	$VBoxContainer/new_game.pressed.connect(_on_new_game_pressed)
	MusicManager.play_music(
		preload("res://assets/audio/music/Title.wav"))
	
func _on_new_game_pressed():
	print("clicked new game")
	SceneFlow.change_scene(PARTY_SETUP)
