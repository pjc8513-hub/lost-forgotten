extends Node3D

const PARTY_MEMBER_CARD_SCENE := preload("res://scenes/ui/PartyMemberCards.tscn")
const INVENTORY_SCENE := preload("res://scenes/ui/inventory/inventory.tscn")
const CHARACTER_SCENE := preload("res://scenes/ui/character.tscn")
const CAMP_SCENE := preload("res://scenes/ui/camp_control.tscn")
const SKILL_SCENE := preload("res://scenes/ui/skill_menu.tscn")
const CAST_TARGET_INPUT_CURSOR := Input.CURSOR_HELP
const NORMAL_INPUT_CURSOR := Input.CURSOR_ARROW
const CAST_TARGET_CONTROL_CURSOR := Control.CURSOR_HELP
const NORMAL_PARTY_CARD_CURSOR := Control.CURSOR_POINTING_HAND

@export var initial_map: PackedScene
@export var initial_spawn_id: StringName = &"entrance"
@export var player_scene: PackedScene

@onready var level_root: Node = $World/LevelRoot
@onready var entity_root: Node = $World/EntityRoot
@onready var effect_root: Node = $World/EffectRoot
@onready var automap: Automap = $HudLayer/HudRoot/CanvasLayer/AutomapControl
@onready var party_cards: VBoxContainer = $HudLayer/HudRoot/MarginContainer/PartyCards
@onready var alert: Control = $HudLayer/HudRoot/Alert
@onready var inventory_button: TextureButton = $HudLayer/HudRoot/MarginContainer2/VBoxContainer/inventoryButton
@onready var character_button: TextureButton = $HudLayer/HudRoot/MarginContainer2/VBoxContainer/CharacterButton
@onready var camp_button: TextureButton = $HudLayer/HudRoot/MarginContainer2/VBoxContainer/CampButton
@onready var skills_button: TextureButton = $HudLayer/HudRoot/MarginContainer2/VBoxContainer/SkillsButton


var player_movement: GridMovementController
var inventory_menu: InventoryMenu
var character_menu: CharacterMenu
var camp_menu: CampMenu
var skill_menu: skill_menu
var _pending_target_skill: SkillData
var _pending_target_caster: PartyMember

func _ready() -> void:
	PartyManager.party_changed.connect(_rebuild_party_cards)
	PartyManager.selected_party_member_changed.connect(_on_selected_party_member_changed)
	WorldManager.stamina_cost_due.connect(PartyManager.spend_party_stamina)
	SkillSystem.execution_requested.connect(_on_skill_execution_requested)
	MapManager.alert_requested.connect(alert.show_message)
	inventory_menu = INVENTORY_SCENE.instantiate() as InventoryMenu
	character_menu = CHARACTER_SCENE.instantiate() as CharacterMenu
	camp_menu = CAMP_SCENE.instantiate()as CampMenu
	skill_menu = SKILL_SCENE.instantiate()as skill_menu
	$HudLayer/HudRoot/CanvasLayer.add_child(inventory_menu)
	$HudLayer/HudRoot/CanvasLayer.add_child(character_menu)
	$HudLayer/HudRoot/CanvasLayer.add_child(camp_menu)
	$HudLayer/HudRoot/CanvasLayer.add_child(skill_menu)
	inventory_button.pressed.connect(inventory_menu.open)
	character_button.pressed.connect(character_menu.open)
	camp_button.pressed.connect(camp_menu.open_dialogue)
	skills_button.pressed.connect(skill_menu.open)
	_rebuild_party_cards()

	if initial_map == null or player_scene == null:
		push_error("Main requires both an initial_map and player_scene.")
		return

	var player := player_scene.instantiate() as Node3D
	entity_root.add_child(player)
	StageManager.configure(level_root, entity_root, effect_root, player)
	WorldManager.begin_dungeon()
	StageManager.map_changed.connect(_on_map_changed)
	StageManager.load_map_scene(initial_map, initial_spawn_id)
	var movement := player.get_node_or_null("GridMovementController") as GridMovementController
	if movement != null:
		player_movement = movement
		movement.step_taken.connect(WorldManager.record_step)
		movement.step_taken.connect(alert.dismiss)
		automap.setup(movement)


func _rebuild_party_cards() -> void:
	for child in party_cards.get_children():
		child.queue_free()

	for index in PartyManager.party.size():
		var card := PARTY_MEMBER_CARD_SCENE.instantiate() as PartyMemberCard
		party_cards.add_child(card)
		card.setup(PartyManager.party[index], index)
		card.selection_requested.connect(_on_party_member_card_selection_requested)
		card.skill_requested.connect(SkillSystem.request_execution)
		card.set_selected(index == PartyManager.selected_party_member_index)
	_refresh_targeting_cursor()


func _on_map_changed(_map_path: String, _spawn_id: StringName) -> void:
	var enable_torch: bool = true
	var current_level = StageManager.current_level
	if current_level is MapData:
		enable_torch = current_level.enable_torch

	var player = StageManager.player
	if player != null and player.has_node("OmniLight3D"):
		var torch = player.get_node("OmniLight3D")
		if torch.has_method("set_torch_enabled"):
			torch.set_torch_enabled(enable_torch)


func _on_selected_party_member_changed(index: int, _member: PartyMember) -> void:
	for child_index in party_cards.get_child_count():
		var card := party_cards.get_child(child_index) as PartyMemberCard
		if card != null:
			card.set_selected(child_index == index)

func _unhandled_input(event: InputEvent) -> void:
	if _pending_target_skill == null:
		return
	if event.is_action_pressed("cancel_cast"):
		_cancel_pending_cast()
		get_viewport().set_input_as_handled()


func _on_party_member_card_selection_requested(index: int) -> void:
	if _pending_target_skill != null:
		_execute_pending_target_skill(index)
		return
	PartyManager.select_party_member(index)


func _on_skill_execution_requested(caster: PartyMember, skill: SkillData) -> void:
	match skill.skill_id:
		&"search":
			if player_movement != null:
				alert.show_message(SearchSkill.execute(caster, skill, player_movement.grid_pos))
		&"invigorate":
			alert.show_message(InvigorateSkill.execute(caster, skill))
		&"disarm_trap":
			if player_movement != null:
				alert.show_message(DisarmTrapSkill.execute(caster, skill, player_movement.grid_pos))
		&"minor_heal":
			_begin_targeted_cast(caster, skill)


func _begin_targeted_cast(caster: PartyMember, skill: SkillData) -> void:
	_pending_target_caster = caster
	_pending_target_skill = skill
	_refresh_targeting_cursor()
	alert.show_message("Select a party member to cast %s" % skill.display_name)


func _execute_pending_target_skill(target_index: int) -> void:
	if target_index < 0 or target_index >= PartyManager.party.size():
		return
	var caster := _pending_target_caster
	var skill := _pending_target_skill
	var target := PartyManager.party[target_index]
	_clear_pending_cast()
	match skill.skill_id:
		&"minor_heal":
			alert.show_message(MinorHealSkill.execute(caster, skill, target))


func _cancel_pending_cast() -> void:
	var skill_name := _pending_target_skill.display_name if _pending_target_skill != null else "Cast"
	_clear_pending_cast()
	alert.show_message("%s cancelled" % skill_name)


func _clear_pending_cast() -> void:
	_pending_target_caster = null
	_pending_target_skill = null
	_refresh_targeting_cursor()


func _refresh_targeting_cursor() -> void:
	var input_cursor_shape := CAST_TARGET_INPUT_CURSOR if _pending_target_skill != null else NORMAL_INPUT_CURSOR
	var control_cursor_shape := CAST_TARGET_CONTROL_CURSOR if _pending_target_skill != null else NORMAL_PARTY_CARD_CURSOR
	Input.set_default_cursor_shape(input_cursor_shape)
	for child in party_cards.get_children():
		var card := child as Control
		if card != null:
			card.mouse_default_cursor_shape = control_cursor_shape
