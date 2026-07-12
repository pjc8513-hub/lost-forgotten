extends Control
@onready var options_container: VBoxContainer = $VBoxContainer/HBoxContainer/OptionsPanel/MarginContainer/OptionsContainer
@onready var npc_list: ItemList = $VBoxContainer/HBoxContainer/PanelContainer/MarginContainer/NPCListContainer/NPCList
@onready var dialogue_label: RichTextLabel = $VBoxContainer/HBoxContainer/PanelContainer2/ScrollContainer/DialogueLabel


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.
