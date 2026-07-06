class_name skill_menu

extends Control

@onready var character_name: Label = $PanelContainer/MarginContainer/VBoxContainer/CharacterName
@onready var skill_list: ItemList = $PanelContainer/MarginContainer/VBoxContainer/MarginContainer/HBoxContainer/SkillContainer/VBoxContainer/ScrollContainer/SkillList
@onready var next_button: Button = $PanelContainer/MarginContainer/VBoxContainer/MarginContainer/HBoxContainer/OptionsContainer/VBoxContainer/NextButton
@onready var previous_button: Button = $PanelContainer/MarginContainer/VBoxContainer/MarginContainer/HBoxContainer/OptionsContainer/VBoxContainer/PreviousButton
@onready var close_button: Button = $PanelContainer/MarginContainer/VBoxContainer/MarginContainer/HBoxContainer/OptionsContainer/VBoxContainer/CloseButton


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.
