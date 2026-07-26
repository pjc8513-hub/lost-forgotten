class_name CampMenu
extends Control

const REST_DURATION_SECONDS: int = 6 * 60 * 60
const WAIT_DURATION_SECONDS: int = 4 * 60 * 60
const FADE_DURATION_SECONDS: float = 0.5
const BLACKOUT_HOLD_SECONDS: float = 0.25

# Signals to notify the rest of your game what the player chose
signal camp_confirmed
signal camp_cancelled

@onready var dialog_box: PanelContainer = $DialogBox
@onready var blackout: ColorRect = $TransitionCanvas/Blackout
@onready var food_label: Label = $DialogBox/PaperPanel/VBoxContainer/FoodLabel
@onready var camp_button: Button = $DialogBox/PaperPanel/VBoxContainer/HBoxContainer/CampButton
@onready var close_button: Button = $DialogBox/PaperPanel/VBoxContainer/HBoxContainer/CloseButton
@onready var wait_button: Button = $DialogBox/PaperPanel/VBoxContainer/HBoxContainer/WaitButton

var _is_transitioning: bool = false

func _ready() -> void:
	# Hide by default until open_dialogue() is called
	hide()
	
	# Connect button signals
	camp_button.pressed.connect(_on_camp_pressed)
	wait_button.pressed.connect(_on_wait_pressed)
	close_button.pressed.connect(_on_close_pressed)
	PartyManager.food_changed.connect(_on_food_changed)
	
	# Build the visual style dynamically matching your alert notification
	_apply_notification_style()

func open_dialogue() -> void:
	if _is_transitioning:
		return
	_refresh_food_display()
	dialog_box.show()
	show()
	if not camp_button.disabled:
		camp_button.grab_focus()
	else:
		close_button.grab_focus()

func _on_camp_pressed() -> void:
	if _is_transitioning or not PartyManager.spend_food(1):
		_refresh_food_display()
		return
	_is_transitioning = true
	camp_button.disabled = true
	close_button.disabled = true
	blackout.color = Color(0.0, 0.0, 0.0, 0.0)
	blackout.show()

	var fade_out := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	fade_out.tween_property(blackout, "color:a", 1.0, FADE_DURATION_SECONDS)
	await fade_out.finished

	for member in PartyManager.party:
		_rest_member(member)
	WorldManager.advance_time(REST_DURATION_SECONDS)
	camp_confirmed.emit()
	dialog_box.hide()
	await get_tree().create_timer(BLACKOUT_HOLD_SECONDS).timeout

	var fade_in := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	fade_in.tween_property(blackout, "color:a", 0.0, FADE_DURATION_SECONDS)
	await fade_in.finished

	blackout.hide()
	hide()
	dialog_box.show()
	close_button.disabled = false
	_is_transitioning = false
	_refresh_food_display()


func _on_wait_pressed() -> void:
	if _is_transitioning:
		return
	WorldManager.advance_time(WAIT_DURATION_SECONDS)

func _input(_event: InputEvent) -> void:
	if _is_transitioning:
		get_viewport().set_input_as_handled()

func _rest_member(member: PartyMember) -> void:
	if member == null:
		return
	var was_dead := not member.is_alive()
	var healing_blocked := _has_healing_blocker(member)
	var diseased := member.active_status_effects.has(StatusEffects.Effect.DISEASED)
	var effects_to_clear: Array[int] = []
	if not was_dead: member.reset_daily_skill_uses()
	for effect_id in member.active_status_effects:
		if StatusEffects.clears_on_rest(int(effect_id)):
			effects_to_clear.append(int(effect_id))
	for effect_id in effects_to_clear:
		member.active_status_effects.erase(effect_id)
	StatCalculator.recalculate(member)
	if not healing_blocked:
		member.current_hp = member.max_hp
	if not was_dead and not diseased:
		member.current_stamina = member.max_stamina

func _has_healing_blocker(member: PartyMember) -> bool:
	for effect_id in member.active_status_effects:
		if StatusEffects.blocks_healing(int(effect_id)):
			return true
	return false

func _on_food_changed(_total: int) -> void:
	_refresh_food_display()

func _refresh_food_display() -> void:
	food_label.text = "Current Food: %d" % PartyManager.food
	camp_button.disabled = PartyManager.food < 1

func _on_close_pressed() -> void:
	if _is_transitioning:
		return
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
