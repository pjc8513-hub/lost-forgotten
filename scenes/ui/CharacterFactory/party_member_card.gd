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
@onready var row_label: Label = $HBoxContainer/VBoxContainer/RowLabel

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
	class_label.text = ClassData.get_display_name_for(member_data.class_data.class_id) if member_data.class_data != null else "Unknown"
	level_label.text = "Level %d" % member_data.level
	row_label.text = "Front Row" if member_data.row == 0 else "Back Row"
	var is_active := PartyManager.get_active_party().has(member_data)
	add_button.visible = not is_active
	remove_button.visible = is_active

func _on_add_pressed() -> void:
	add_to_party_requested.emit(member_data)

func _on_remove_pressed() -> void:
	remove_from_party_requested.emit(member_data)

func _on_delete_pressed() -> void:
	delete_requested.emit(member_data)
