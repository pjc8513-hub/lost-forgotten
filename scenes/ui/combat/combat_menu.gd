class_name CombatMenu
extends Control

signal action_requested(action: StringName)
signal row_requested(row: int)
signal row_preview_requested(row: int)
signal row_preview_cleared
@onready var attack_button: Button = $MarginContainer/VBoxContainer/HBoxContainer/AttackButton
@onready var defend_button: Button = $MarginContainer/VBoxContainer/HBoxContainer/DefendButton
@onready var cast_button: Button = $MarginContainer/VBoxContainer/HBoxContainer/CastButton
@onready var item_button: Button = $MarginContainer/VBoxContainer/HBoxContainer/ItemButton
@onready var auto_button: Button = $MarginContainer/VBoxContainer/HBoxContainer/AutoButton
@onready var run_button: Button = $MarginContainer/VBoxContainer/HBoxContainer/RunButton

# row targeting
@onready var row_container: HBoxContainer = $MarginContainer/VBoxContainer/RowContainer
@onready var first_row_button: Button = $MarginContainer/VBoxContainer/RowContainer/FirstRowButton
@onready var second_row_button: Button = $MarginContainer/VBoxContainer/RowContainer/SecondRowButton
@onready var third_row_button: Button = $MarginContainer/VBoxContainer/RowContainer/ThirdRowButton



func _ready() -> void:
	attack_button.pressed.connect(action_requested.emit.bind(&"attack"))
	defend_button.pressed.connect(action_requested.emit.bind(&"defend"))
	cast_button.pressed.connect(action_requested.emit.bind(&"cast"))
	item_button.pressed.connect(action_requested.emit.bind(&"item"))
	auto_button.pressed.connect(action_requested.emit.bind(&"auto"))
	run_button.pressed.connect(action_requested.emit.bind(&"run"))
	first_row_button.pressed.connect(row_requested.emit.bind(0))
	second_row_button.pressed.connect(row_requested.emit.bind(1))
	third_row_button.pressed.connect(row_requested.emit.bind(2))
	first_row_button.mouse_entered.connect(row_preview_requested.emit.bind(0))
	second_row_button.mouse_entered.connect(row_preview_requested.emit.bind(1))
	third_row_button.mouse_entered.connect(row_preview_requested.emit.bind(2))
	first_row_button.mouse_exited.connect(row_preview_cleared.emit)
	second_row_button.mouse_exited.connect(row_preview_cleared.emit)
	third_row_button.mouse_exited.connect(row_preview_cleared.emit)
	first_row_button.pressed.connect(row_preview_cleared.emit)
	second_row_button.pressed.connect(row_preview_cleared.emit)
	third_row_button.pressed.connect(row_preview_cleared.emit)
	hide_row_targeting()

func set_interactable(enabled: bool) -> void:
	for button in [attack_button, defend_button, cast_button, item_button, auto_button, run_button]:
		button.disabled = not enabled
	if not enabled:
		hide_row_targeting()

func show_row_targeting(available_rows: Array[int]) -> void:
	row_container.show()
	for button in [attack_button, defend_button, cast_button, item_button, auto_button, run_button]:
		button.disabled = true
	var row_buttons: Array[Button] = [first_row_button, second_row_button, third_row_button]
	for row in row_buttons.size():
		row_buttons[row].disabled = row not in available_rows

func hide_row_targeting() -> void:
	row_preview_cleared.emit()
	row_container.hide()
