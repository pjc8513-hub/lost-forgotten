extends Node3D

const PARTY_MEMBER_CARD_SCENE := preload("res://scenes/ui/PartyMemberCards.tscn")

@export var initial_map: PackedScene
@export var initial_spawn_id: StringName = &"entrance"
@export var player_scene: PackedScene

@onready var level_root: Node = $World/LevelRoot
@onready var entity_root: Node = $World/EntityRoot
@onready var effect_root: Node = $World/EffectRoot
@onready var automap: Automap = $HudLayer/HudRoot/CanvasLayer/AutomapControl
@onready var party_cards: VBoxContainer = $HudLayer/HudRoot/MarginContainer/PartyCards
@onready var alert: Control = $HudLayer/HudRoot/Alert

var player_movement: GridMovementController

func _ready() -> void:
	PartyManager.party_changed.connect(_rebuild_party_cards)
	PartyManager.selected_party_member_changed.connect(_on_selected_party_member_changed)
	WorldManager.stamina_cost_due.connect(PartyManager.spend_party_stamina)
	SkillSystem.execution_requested.connect(_on_skill_execution_requested)
	_rebuild_party_cards()

	if initial_map == null or player_scene == null:
		push_error("Main requires both an initial_map and player_scene.")
		return

	var player := player_scene.instantiate() as Node3D
	entity_root.add_child(player)
	StageManager.configure(level_root, entity_root, effect_root, player)
	WorldManager.begin_dungeon()
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
		card.selection_requested.connect(PartyManager.select_party_member)
		card.skill_requested.connect(SkillSystem.request_execution)
		card.set_selected(index == PartyManager.selected_party_member_index)


func _on_selected_party_member_changed(index: int, _member: CharacterState) -> void:
	for child_index in party_cards.get_child_count():
		var card := party_cards.get_child(child_index) as PartyMemberCard
		if card != null:
			card.set_selected(child_index == index)

func _on_skill_execution_requested(caster: CharacterState, skill: SkillData) -> void:
	if skill.skill_id == &"search" and player_movement != null:
		alert.show_message(SearchSkill.execute(caster, skill, player_movement.grid_pos))
