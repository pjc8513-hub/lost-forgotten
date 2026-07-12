class_name QuestMenu
extends Control

@onready var tab_container: TabContainer = $PanelContainer/MarginContainer/HBoxContainer/TabContainer
@onready var in_progress_list: RichTextLabel = $PanelContainer/MarginContainer/HBoxContainer/TabContainer/InProgress/ScrollContainer/InProgressList
@onready var completed_list: RichTextLabel = $PanelContainer/MarginContainer/HBoxContainer/TabContainer/Completed/ScrollContainer/CompletedList
@onready var close_button: Button = $PanelContainer/MarginContainer/HBoxContainer/OptionsContainer/VBoxContainer/CloseButton


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.
