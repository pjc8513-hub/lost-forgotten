class_name CampMenu
extends Control

# Signals to notify the rest of your game what the player chose
signal camp_confirmed
signal camp_cancelled

@onready var food_label: Label = $DialogBox/PaperPanel/VBoxContainer/FoodLabel
@onready var camp_button: Button = $DialogBox/PaperPanel/VBoxContainer/HBoxContainer/CampButton
@onready var close_button: Button = $DialogBox/PaperPanel/VBoxContainer/HBoxContainer/CloseButton

func _ready() -> void:
	# Hide by default until open_dialogue() is called
	hide()
	
	# Connect button signals
	camp_button.pressed.connect(_on_camp_pressed)
	close_button.pressed.connect(_on_close_pressed)
	
	# Build the visual style dynamically matching your alert notification
	_apply_notification_style()

func open_dialogue() -> void:
	# Fetch the current food from your PartyManager autoload
	var current_food = PartyManager.food # Adjust this to match your actual variable
	food_label.text = "Current Food: %d" % current_food
	
	# Optional: Disable the camp button if they don't have enough food
	# camp_button.disabled = current_food <= 0
	
	show()

func _on_camp_pressed() -> void:
	camp_confirmed.emit()
	hide()

func _on_close_pressed() -> void:
	camp_cancelled.emit()
	hide()

func _apply_notification_style() -> void:
	# 1. Setup the outer frame
	var box = $DialogBox
	var frame := StyleBoxFlat.new()
	frame.bg_color = Color("6f4825")
	frame.border_color = Color("3f2817")
	frame.set_border_width_all(1)
	frame.set_content_margin_all(2)
	frame.shadow_color = Color(0.08, 0.04, 0.02, 0.55)
	frame.shadow_size = 4
	frame.shadow_offset = Vector2(0, 3)
	box.add_theme_stylebox_override("panel", frame)

	# 2. Setup the inner paper texture
	var paper = $DialogBox/PaperPanel
	var style_box := StyleBoxTexture.new()

	var paper_gradient := Gradient.new()
	paper_gradient.offsets = [0.0, 0.025, 0.07, 0.14, 0.5, 0.86, 0.93, 0.975, 1.0]
	paper_gradient.colors = [
		Color("70471f"), Color("9d6d32"), Color("c18b45"), 
		Color("d6a555"), Color("e1b86c"), Color("d6a555"), 
		Color("c18b45"), Color("9d6d32"), Color("70471f")
	]

	var gradient_tex := GradientTexture2D.new()
	gradient_tex.gradient = paper_gradient
	gradient_tex.fill_from = Vector2(0, 0)
	gradient_tex.fill_to = Vector2(1, 0)

	style_box.texture = gradient_tex
	style_box.texture_margin_left = 30
	style_box.texture_margin_right = 30
	style_box.texture_margin_top = 12
	style_box.texture_margin_bottom = 12
	paper.add_theme_stylebox_override("panel", style_box)
