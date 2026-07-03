extends Control
signal add_to_party_requested(member: PartyMember)
signal remove_from_party_requested(member: PartyMember)
signal delete_requested(member: PartyMember)

@onready var portrait_one: TextureRect = $HBoxContainer/PortraitOne
@onready var name_label: Label = $HBoxContainer/VBoxContainer/NameLabel
@onready var class_label: Label = $HBoxContainer/VBoxContainer/ClassLabel
@onready var level_label: Label = $HBoxContainer/VBoxContainer/LevelLabel
@onready var add_button: Button = $HBoxContainer/VBoxContainer2/AddButton
@onready var remove_button: Button = $HBoxContainer/VBoxContainer2/RemoveButton
@onready var delete_button_button: Button = $HBoxContainer/VBoxContainer2/DeleteButtonButton

var member_data: PartyMember

func _ready() -> void:
	add_button.pressed.connect(_on_add_pressed)
	remove_button.pressed.connect(_on_remove_pressed)
	delete_button_button.pressed.connect(_on_delete_pressed)

func setup(member: PartyMember) -> void:
	member_data = member
	if member_data == null:
		return

	portrait_one.texture = member_data.portrait
	name_label.text = member_data.member_name
	class_label.text = member_data.class_data.display_name if member_data.class_data != null else "Unknown"
	level_label.text = "Level %d" % member_data.level

func _on_add_pressed() -> void:
	add_to_party_requested.emit(member_data)

func _on_remove_pressed() -> void:
	remove_from_party_requested.emit(member_data)

func _on_delete_pressed() -> void:
	delete_requested.emit(member_data)
