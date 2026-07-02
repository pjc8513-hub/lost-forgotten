class_name PartyMemberCard
extends PanelContainer

signal selection_requested(index: int)

@onready var portrait: TextureRect = $HBoxContainer/Portrait
@onready var status_overlay: TextureRect = $HBoxContainer/Portrait/combatFX/StatusOverlay
@onready var damage_label: Label = $HBoxContainer/Portrait/combatFX/DamageLabel
@onready var member_name: Label = $HBoxContainer/VBoxContainer/MemberName
@onready var h_pbar: ProgressBar = $HBoxContainer/VBoxContainer/HPbar

var party_index: int = -1
var member: ClassData

var _selected_style := StyleBoxFlat.new()

func _ready() -> void:
	_selected_style.bg_color = Color(0.2128, 0.1945, 0.1405, 0.84)
	_selected_style.border_color = Color(0.95, 0.76, 0.28)
	_selected_style.set_border_width_all(2)
	refresh()


func setup(member_data: ClassData, index: int) -> void:
	member = member_data
	party_index = index
	refresh()


func refresh() -> void:
	if not is_node_ready() or member == null:
		return
	portrait.texture = member.sprite_texture
	member_name.text = member.display_name
	tooltip_text = "%d: %s (%s)" % [
		party_index + 1,
		member.display_name,
		ClassData.get_display_name_for(member.class_id),
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
