class_name CombatMenu
extends Control

signal action_requested(action: StringName)
@onready var attack_button: Button = $MarginContainer/HBoxContainer/AttackButton
@onready var defend_button: Button = $MarginContainer/HBoxContainer/DefendButton
@onready var cast_button: Button = $MarginContainer/HBoxContainer/CastButton
@onready var item_button: Button = $MarginContainer/HBoxContainer/ItemButton
@onready var wait_button: Button = $MarginContainer/HBoxContainer/WaitButton
@onready var run_button: Button = $MarginContainer/HBoxContainer/RunButton



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
