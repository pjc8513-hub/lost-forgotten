# QuickStart.gd
extends Control

const CHARACTER_CREATION := preload(
	"res://scenes/ui/CharacterFactory/CharacterCreation.tscn"
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
	PartyManager.use_default_party()
	SceneFlow.change_scene(load("res://scenes/main/Main.tscn") as PackedScene)

func _on_CreateCharacterButton_pressed():
	SceneFlow.change_scene(CHARACTER_CREATION)

func _on_manage_party_pressed():
	SceneFlow.change_scene(load("res://scenes/ui/CharacterFactory/PartyMemberSelection.tscn") as PackedScene)

func _on_begin_pressed():
	if PartyManager.can_set_out():
		SceneFlow.change_scene(load("res://scenes/main/Main.tscn") as PackedScene)
