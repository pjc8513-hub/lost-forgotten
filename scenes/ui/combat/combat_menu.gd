class_name CombatMenu
extends Control

signal action_requested(action: StringName)
@onready var attack_button: Button = $MarginContainer/VBoxContainer/HBoxContainer/AttackButton
@onready var defend_button: Button = $MarginContainer/VBoxContainer/HBoxContainer/DefendButton
@onready var cast_button: Button = $MarginContainer/VBoxContainer/HBoxContainer/CastButton
@onready var item_button: Button = $MarginContainer/VBoxContainer/HBoxContainer/ItemButton
@onready var wait_button: Button = $MarginContainer/VBoxContainer/HBoxContainer/WaitButton
@onready var run_button: Button = $MarginContainer/VBoxContainer/HBoxContainer/RunButton

# row targeting
@onready var row_container: HBoxContainer = $MarginContainer/VBoxContainer/RowContainer
@onready var first_row_button: Button = $MarginContainer/VBoxContainer/HBoxContainer2/FirstRowButton
@onready var second_row_button: Button = $MarginContainer/VBoxContainer/HBoxContainer2/SecondRowButton
@onready var third_row_button: Button = $MarginContainer/VBoxContainer/HBoxContainer2/ThirdRowButton



func _ready() -> void:
	attack_button.pressed.connect(action_requested.emit.bind(&"attack"))
	defend_button.pressed.connect(action_requested.emit.bind(&"defend"))
	cast_button.pressed.connect(action_requested.emit.bind(&"cast"))
	item_button.pressed.connect(action_requested.emit.bind(&"item"))
	wait_button.pressed.connect(action_requested.emit.bind(&"wait"))
	run_button.pressed.connect(action_requested.emit.bind(&"run"))

func set_interactable(enabled: bool) -> void:
	for button in [attack_button, defend_button, cast_button, item_button, wait_button, run_button]:
		button.disabled = not enabled
