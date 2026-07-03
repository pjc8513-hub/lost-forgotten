class_name PartyMemberCard
extends PanelContainer

signal selection_requested(index: int)

@onready var portrait: TextureRect = $HBoxContainer/Portrait
@onready var status_overlay: TextureRect = $HBoxContainer/Portrait/combatFX/StatusOverlay
@onready var damage_label: Label = $HBoxContainer/Portrait/combatFX/DamageLabel
@onready var member_name: Label = $HBoxContainer/VBoxContainer/MemberName
@onready var h_pbar: ProgressBar = $HBoxContainer/VBoxContainer/HPbar
@onready var stamina_bar: ProgressBar = $HBoxContainer/VBoxContainer/StaminaBar

var party_index: int = -1
var member: CharacterState

var _selected_style := StyleBoxFlat.new()

func _ready() -> void:
	_selected_style.bg_color = Color(0.2128, 0.1945, 0.1405, 0.84)
	_selected_style.border_color = Color(0.95, 0.76, 0.28)
	_selected_style.set_border_width_all(2)
	refresh()


func setup(member_data: CharacterState, index: int) -> void:
	if member != null and member.stats_changed.is_connected(refresh):
		member.stats_changed.disconnect(refresh)
	member = member_data
	party_index = index
	member.stats_changed.connect(refresh)
	refresh()


func refresh() -> void:
	if not is_node_ready() or member == null:
		return
	portrait.texture = member.class_data.sprite_texture
	member_name.text = member.member_name
	h_pbar.max_value = member.max_hp
	h_pbar.value = member.current_hp
	stamina_bar.max_value = member.max_stamina
	stamina_bar.value = member.current_stamina
	tooltip_text = "%d: %s (%s)" % [
		party_index + 1,
		member.member_name,
		ClassData.get_display_name_for(member.class_data.class_id),
	]


func set_selected(is_selected: bool) -> void:
	if is_selected:
		add_theme_stylebox_override("panel", _selected_style)
	else:
		remove_theme_stylebox_override("panel")


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		selection_requested.emit(party_index)
		accept_event()
