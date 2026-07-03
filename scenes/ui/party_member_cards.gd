class_name PartyMemberCard
extends PanelContainer

signal selection_requested(index: int)
signal skill_requested(member: CharacterState, skill_id: StringName)

@onready var portrait: TextureRect = $HBoxContainer/Portrait
@onready var status_overlay: TextureRect = $HBoxContainer/Portrait/combatFX/StatusOverlay
@onready var damage_label: Label = $HBoxContainer/Portrait/combatFX/DamageLabel
@onready var member_name: Label = $HBoxContainer/VBoxContainer/MemberName
@onready var h_pbar: ProgressBar = $HBoxContainer/VBoxContainer/HPbar
@onready var stamina_bar: ProgressBar = $HBoxContainer/VBoxContainer/StaminaBar
@onready var popup_menu: PopupMenu = $PopupMenu

var party_index: int = -1
var member: CharacterState

var _selected_style := StyleBoxFlat.new()
var _popup_skill_ids: Array[StringName] = []

func _ready() -> void:
	_selected_style.bg_color = Color(0.2128, 0.1945, 0.1405, 0.84)
	_selected_style.border_color = Color(0.95, 0.76, 0.28)
	_selected_style.set_border_width_all(2)
	popup_menu.id_pressed.connect(_on_popup_menu_id_pressed)
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
	h_pbar.tooltip_text = "HP: %d / %d" % [member.current_hp, member.max_hp]
	stamina_bar.max_value = member.max_stamina
	stamina_bar.value = member.current_stamina
	stamina_bar.tooltip_text = "Stamina: %d / %d" % [
		member.current_stamina,
		member.max_stamina,
	]
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
	if not event is InputEventMouseButton or not event.pressed:
		return
	if event.button_index == MOUSE_BUTTON_LEFT:
		selection_requested.emit(party_index)
		accept_event()
	elif event.button_index == MOUSE_BUTTON_RIGHT:
		_show_skill_menu()
		accept_event()

func _show_skill_menu() -> void:
	popup_menu.clear()
	_popup_skill_ids.clear()
	var skills := SkillSystem.get_party_menu_skills(member)
	if skills.is_empty():
		popup_menu.add_item("No exploration skills or party spells")
		popup_menu.set_item_disabled(0, true)
	else:
		for skill in skills:
			var item_id := _popup_skill_ids.size()
			_popup_skill_ids.append(skill.skill_id)
			popup_menu.add_item(skill.display_name, item_id)
			popup_menu.set_item_tooltip(item_id, "Rank %d" % int(member.learned_skills[skill.skill_id]))
	popup_menu.position = Vector2i(get_screen_transform() * get_local_mouse_position())
	popup_menu.popup()

func _on_popup_menu_id_pressed(item_id: int) -> void:
	if item_id >= 0 and item_id < _popup_skill_ids.size():
		skill_requested.emit(member, _popup_skill_ids[item_id])
