extends Control

const PARTY_MEMBER_CARD_SCENE := preload("res://scenes/ui/CharacterFactory/PartyMemberCard.tscn")

@onready var party_list_container: VBoxContainer = $VBoxContainer/ScrollContainer/PartyListContainer
@onready var empty_label: Label = $VBoxContainer/EmptyLabel
@onready var party_status_label: Label = $VBoxContainer/PartyStatusLabel
@onready var create_character_button: Button = $VBoxContainer/ButtonRow/CreateCharacterButton
@onready var set_out_button: Button = $VBoxContainer/ButtonRow/SetOutButton
@onready var return_button: Button = $VBoxContainer/ReturnButton


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	create_character_button.pressed.connect(_on_create_character_button_pressed)
	set_out_button.pressed.connect(_on_set_out_button_pressed)
	return_button.pressed.connect(_on_return_button_pressed)
	PartyManager.roster_changed.connect(_rebuild_party_list)
	PartyManager.active_party_changed.connect(_rebuild_party_list)
	_rebuild_party_list()

func _rebuild_party_list() -> void:
	for child in party_list_container.get_children():
		child.queue_free()

	var roster := PartyManager.get_roster()
	empty_label.visible = roster.is_empty()
	party_status_label.text = "Current Party: %d/%d" % [PartyManager.get_active_party().size(), PartyManager.MAX_PARTY_SIZE]
	set_out_button.disabled = not PartyManager.can_set_out()

	for member in roster:
		var card = PARTY_MEMBER_CARD_SCENE.instantiate()
		party_list_container.add_child(card)
		card.setup(member)
		card.add_to_party_requested.connect(_on_add_to_party_requested)
		card.remove_from_party_requested.connect(_on_remove_from_party_requested)
		card.delete_requested.connect(_on_delete_requested)

func _on_add_to_party_requested(member: PartyMember) -> void:
	PartyManager.add_member_to_party(member)

func _on_remove_from_party_requested(member: PartyMember) -> void:
	PartyManager.remove_member_from_party(member)

func _on_delete_requested(member: PartyMember) -> void:
	PartyManager.delete_roster_member(member)

func _on_create_character_button_pressed() -> void:
	SceneFlow.change_scene(load("res://scenes/ui/CharacterFactory/CharacterCreation.tscn") as PackedScene)

func _on_set_out_button_pressed() -> void:
	if PartyManager.can_set_out():
		SceneFlow.change_scene(load("res://scenes/main/Main.tscn") as PackedScene)

func _on_return_button_pressed():
	SceneFlow.change_scene(load("res://scenes/ui/CharacterFactory/PartySetupScreen.tscn") as PackedScene)
