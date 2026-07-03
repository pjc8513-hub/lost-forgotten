# QuickStart.gd
extends Control

const CHARACTER_CREATION := preload(
	"res://scenes/ui/CharacterFactory/PartySetupScreen.tscn"
)
@onready var quick_start: Button = $VBoxContainer/quick_start
@onready var create_character_button: Button = $VBoxContainer/CreateCharacterButton
@onready var manage_party_button: Button = $VBoxContainer/ManagePartyButton
@onready var begin_button: Button = $VBoxContainer/BeginButton


func _ready() -> void:
	quick_start.pressed.connect(_on_quick_start_pressed)
	create_character_button.pressed.connect(_on_CreateCharacterButton_pressed)
	manage_party_button.pressed.connect(_on_manage_party_pressed)
	begin_button.pressed.connect(_on_begin_pressed)
	
func _on_quick_start_pressed():
	# ROLL stats for default party 
	SceneFlow.change_scene(SceneIndex.MAIN_SCENE)

func _on_CreateCharacterButton_pressed():
	SceneFlow.change_scene(CHARACTER_CREATION)

func _on_manage_party_pressed():
	SceneFlow.change_scene(SceneIndex.PARTY_MEMBER_SELECTION)

func _on_begin_pressed():
	pass
