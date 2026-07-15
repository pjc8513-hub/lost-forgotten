extends Node3D

const PARTY_MEMBER_CARD_SCENE := preload("res://scenes/ui/PartyMemberCards.tscn")
const INVENTORY_SCENE := preload("res://scenes/ui/inventory/inventory.tscn")
const CHARACTER_SCENE := preload("res://scenes/ui/character.tscn")
const CAMP_SCENE := preload("res://scenes/ui/camp_control.tscn")
const SKILL_SCENE := preload("res://scenes/ui/skill_menu.tscn")
const QUEST_SCENE := preload("res://scenes/ui/QuestMenu.tscn")
const TRAVEL_SCENE := preload("res://scenes/ui/travel_menu.tscn")
const DIALOGUE_SCENE := preload("res://scenes/ui/dialogue.tscn")
const SHOP_SCENE := preload("res://scenes/ui/shop_menu.tscn")
const CAST_TARGET_INPUT_CURSOR := Input.CURSOR_HELP
const NORMAL_INPUT_CURSOR := Input.CURSOR_ARROW
const CAST_TARGET_CONTROL_CURSOR := Control.CURSOR_HELP
const NORMAL_PARTY_CARD_CURSOR := Control.CURSOR_POINTING_HAND
const MAP_TRANSITION_FADE_TIME := 0.3
const MAP_TRANSITION_HOLD_TIME := 0.08
const INN_WAKE_TIME_SECONDS := 9 * 60 * 60

@export var initial_map: PackedScene
@export var initial_spawn_id: StringName = &"entrance"
@export var player_scene: PackedScene
@onready var blackout: ColorRect = $TransitionLayer/TransitionRoot/TransitionCanvas/Blackout

@onready var level_root: Node = $World/LevelRoot
@onready var entity_root: Node = $World/EntityRoot
@onready var effect_root: Node = $World/EffectRoot
@onready var screen_filter: ColorRect = $HudLayer/HudRoot/CanvasLayer/ScreenFilter
@onready var automap: Automap = $HudLayer/HudRoot/CanvasLayer/AutomapControl
@onready var party_cards: VBoxContainer = $HudLayer/HudRoot/MarginContainer/PartyCards
@onready var alert: Control = $HudLayer/HudRoot/Alert
@onready var inventory_button: TextureButton = $HudLayer/HudRoot/MarginContainer2/VBoxContainer/inventoryButton
@onready var character_button: TextureButton = $HudLayer/HudRoot/MarginContainer2/VBoxContainer/CharacterButton
@onready var camp_button: TextureButton = $HudLayer/HudRoot/MarginContainer2/VBoxContainer/CampButton
@onready var skills_button: TextureButton = $HudLayer/HudRoot/MarginContainer2/VBoxContainer/SkillsButton
@onready var quest_button: TextureButton = $HudLayer/HudRoot/MarginContainer2/VBoxContainer/QuestButton


var player_movement: GridMovementController
var inventory_menu: InventoryMenu
var character_menu: CharacterMenu
var camp_menu: CampMenu
var skill_menu: skill_menu
var dialogue_menu: Control
var shop_menu: ShopMenu
var quest_menu: QuestMenu
var travel_menu: TravelMenu
var _pending_target_skill: SkillData
var _pending_target_caster: PartyMember
var _map_transition_running := false
var _inn_rest_running := false
var _main_shader_defaults: Dictionary = {}

func _ready() -> void:
	blackout.visible = false
	blackout.color.a = 0.0
	if screen_filter.material != null:
		screen_filter.material = screen_filter.material.duplicate() as Material
		_cache_main_shader_defaults()
	PartyManager.party_changed.connect(_rebuild_party_cards)
	PartyManager.selected_party_member_changed.connect(_on_selected_party_member_changed)
	WorldManager.stamina_cost_due.connect(PartyManager.spend_party_stamina)
	SkillSystem.execution_requested.connect(_on_skill_execution_requested)
	MapManager.alert_requested.connect(alert.show_message)
	MapManager.dialogue_requested.connect(_on_dialogue_requested)
	MapManager.dialogue_close_requested.connect(_on_dialogue_close_requested)
	MapManager.shop_requested.connect(_on_shop_requested)
	MapManager.travel_menu_requested.connect(_on_travel_menu_requested)
	MapManager.map_transition_requested.connect(_on_map_transition_requested)
	MapManager.inn_rest_requested.connect(_on_inn_rest_requested)
	inventory_menu = INVENTORY_SCENE.instantiate() as InventoryMenu
	character_menu = CHARACTER_SCENE.instantiate() as CharacterMenu
	camp_menu = CAMP_SCENE.instantiate()as CampMenu
	skill_menu = SKILL_SCENE.instantiate()as skill_menu
	quest_menu = QUEST_SCENE.instantiate()as QuestMenu
	travel_menu = TRAVEL_SCENE.instantiate() as TravelMenu
	dialogue_menu = DIALOGUE_SCENE.instantiate() as Control
	shop_menu = SHOP_SCENE.instantiate() as ShopMenu
	$HudLayer/HudRoot/CanvasLayer.add_child(inventory_menu)
	$HudLayer/HudRoot/CanvasLayer.add_child(character_menu)
	$HudLayer/HudRoot/CanvasLayer.add_child(camp_menu)
	$HudLayer/HudRoot/CanvasLayer.add_child(skill_menu)
	$HudLayer/HudRoot/CanvasLayer.add_child(quest_menu)
	$HudLayer/HudRoot/CanvasLayer.add_child(travel_menu)
	$HudLayer/HudRoot/CanvasLayer.add_child(dialogue_menu)
	$HudLayer/HudRoot/CanvasLayer.add_child(shop_menu)
	inventory_button.pressed.connect(inventory_menu.open)
	character_button.pressed.connect(character_menu.open)
	camp_button.pressed.connect(camp_menu.open_dialogue)
	skills_button.pressed.connect(skill_menu.open)
	quest_button.pressed.connect(quest_menu.open)
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
		movement.step_taken.connect(PartyManager.tick_exploration_status_effects)
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
		_apply_main_shader_settings(current_level)
	else:
		_apply_main_shader_settings(null)

	var player = StageManager.player
	if player != null and player.has_node("OmniLight3D"):
		var torch = player.get_node("OmniLight3D")
		if torch.has_method("set_torch_enabled"):
			torch.set_torch_enabled(enable_torch)

func _apply_main_shader_settings(map_data: MapData) -> void:
	if screen_filter == null:
		return
	screen_filter.visible = map_data == null or map_data.main_screen_filter_visible

	var shader_material := screen_filter.material as ShaderMaterial
	if shader_material == null:
		return
	if map_data == null:
		_apply_default_main_shader_settings(shader_material)
		return

	var palette_texture: Texture2D = map_data.main_shader_palette_texture
	if palette_texture == null:
		palette_texture = _main_shader_defaults.get("palette_texture", null) as Texture2D
	shader_material.set_shader_parameter("palette_texture", palette_texture)
	shader_material.set_shader_parameter("pixel_size", map_data.main_shader_pixel_size)
	shader_material.set_shader_parameter("dither_strength", map_data.main_shader_dither_strength)
	shader_material.set_shader_parameter("contrast", map_data.main_shader_contrast)

func _cache_main_shader_defaults() -> void:
	var shader_material := screen_filter.material as ShaderMaterial
	if shader_material == null:
		return
	_main_shader_defaults = {
		"palette_texture": shader_material.get_shader_parameter("palette_texture"),
		"pixel_size": shader_material.get_shader_parameter("pixel_size"),
		"dither_strength": shader_material.get_shader_parameter("dither_strength"),
		"contrast": shader_material.get_shader_parameter("contrast"),
	}

func _apply_default_main_shader_settings(shader_material: ShaderMaterial) -> void:
	for parameter_name in _main_shader_defaults:
		shader_material.set_shader_parameter(parameter_name, _main_shader_defaults[parameter_name])

func _on_dialogue_requested(npcs: Array[NPCComponent], source_tile: NPC_Tile_Component) -> void:
	if dialogue_menu != null and dialogue_menu.has_method("open"):
		dialogue_menu.call("open", npcs, source_tile)

func _on_dialogue_close_requested() -> void:
	if dialogue_menu != null and dialogue_menu.has_method("close"):
		dialogue_menu.call("close")

func _on_shop_requested(npc: NPCComponent) -> void:
	if shop_menu != null:
		shop_menu.open(npc)

func _on_travel_menu_requested() -> void:
	if travel_menu != null:
		travel_menu.open()

func _on_map_transition_requested(map_path: String, spawn_id: StringName) -> void:
	if _map_transition_running:
		return
	_run_map_transition(map_path, spawn_id)

func _on_inn_rest_requested() -> void:
	if _inn_rest_running:
		return
	_run_inn_rest_transition()

func _run_map_transition(map_path: String, spawn_id: StringName) -> void:
	_map_transition_running = true
	blackout.visible = true
	blackout.color.a = 0.0

	var fade_out := create_tween()
	fade_out.tween_property(blackout, "color:a", 1.0, MAP_TRANSITION_FADE_TIME)
	await fade_out.finished

	StageManager.change_map(map_path, spawn_id)
	await get_tree().create_timer(MAP_TRANSITION_HOLD_TIME).timeout

	var fade_in := create_tween()
	fade_in.tween_property(blackout, "color:a", 0.0, MAP_TRANSITION_FADE_TIME)
	await fade_in.finished

	blackout.visible = false
	_map_transition_running = false

func _run_inn_rest_transition() -> void:
	_inn_rest_running = true
	blackout.visible = true
	blackout.color.a = 0.0

	var fade_out := create_tween()
	fade_out.tween_property(blackout, "color:a", 1.0, MAP_TRANSITION_FADE_TIME)
	await fade_out.finished

	for member in PartyManager.party:
		_rest_member(member)
	WorldManager.set_time_of_day_seconds(INN_WAKE_TIME_SECONDS)
	await get_tree().create_timer(MAP_TRANSITION_HOLD_TIME).timeout

	var fade_in := create_tween()
	fade_in.tween_property(blackout, "color:a", 0.0, MAP_TRANSITION_FADE_TIME)
	await fade_in.finished

	blackout.visible = false
	_inn_rest_running = false
	MapManager.notify_inn_rest_finished()

func _rest_member(member: PartyMember) -> void:
	if member == null:
		return
	var was_dead := not member.is_alive()
	var healing_blocked := _has_healing_blocker(member)
	var diseased := member.active_status_effects.has(StatusEffects.Effect.DISEASED)
	var effects_to_clear: Array[int] = []
	if not was_dead:
		member.reset_daily_skill_uses()
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
		_:
			if _is_healing_skill(skill):
				if skill.is_AOE:
					alert.show_message(HealingSkill.execute(caster, skill, PartyManager.party))
				else:
					_begin_targeted_cast(caster, skill)
			elif not skill.remove_effect.is_empty():
				if skill.is_AOE:
					alert.show_message(StatusRemovalSkill.execute(caster, skill, PartyManager.party))
				else:
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
	if _is_healing_skill(skill):
		alert.show_message(HealingSkill.execute(caster, skill, [target]))
	elif not skill.remove_effect.is_empty():
		alert.show_message(StatusRemovalSkill.execute(caster, skill, [target]))


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

func _is_healing_skill(skill: SkillData) -> bool:
	return skill != null and skill.heal_amount_dice > 0 and skill.heal_amount_sides > 0
