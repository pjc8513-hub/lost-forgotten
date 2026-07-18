class_name CombatPresenter
extends Node

signal message_requested(message: String)
signal clear_messages_requested
signal combat_ended(outcome: StringName, rewards: Dictionary)

var _level_root: Node
var _player: Node3D
var _menu: CombatMenu
var _exploration_level: Node3D
var _exploration_camera: Camera3D
var _arena: CombatArena
var _session: CombatSession
var _enemy_visuals: Dictionary = {}

func configure(level_root: Node, player: Node3D, menu: CombatMenu) -> void:
	_level_root = level_root
	_player = player
	_menu = menu
	if not _menu.action_requested.is_connected(_on_action_requested):
		_menu.action_requested.connect(_on_action_requested)

func start_encounter(encounter: CombatEncounter) -> bool:
	if encounter == null or encounter.combat_scene == null or _session != null:
		return false
	var arena_instance := encounter.combat_scene.instantiate()
	if not arena_instance is CombatArena:
		push_error("Combat scene root must extend CombatArena: %s" % encounter.combat_scene.resource_path)
		arena_instance.queue_free()
		return false

	_exploration_level = StageManager.current_level as Node3D
	_exploration_camera = get_viewport().get_camera_3d()
	_arena = arena_instance as CombatArena
	if _exploration_level != null:
		_exploration_level.visible = false
	if _player != null:
		_player.visible = false
	_level_root.add_child(_arena)
	if not _arena.activate_camera():
		_level_root.remove_child(_arena)
		_arena.queue_free()
		_arena = null
		if _exploration_level != null:
			_exploration_level.visible = true
		if _player != null:
			_player.visible = true
		return false
	_spawn_enemy_visuals(encounter)

	_session = CombatSession.new(PartyManager.get_active_party(), encounter.get_enemies())
	_session.planning_started.connect(_on_planning_started)
	_session.command_requested.connect(_on_command_requested)
	_session.resolution_started.connect(_on_resolution_started)
	_session.turn_started.connect(_on_turn_started)
	_session.action_resolved.connect(_on_action_resolved)
	_session.combat_finished.connect(_on_combat_finished)
	_menu.visible = true
	_menu.set_interactable(false)
	_session.start()
	return true

func close_encounter(_outcome: StringName) -> void:
	_menu.visible = false
	_menu.set_interactable(false)
	if _arena != null:
		_level_root.remove_child(_arena)
		_arena.queue_free()
	if _exploration_level != null:
		_exploration_level.visible = true
	if _player != null:
		_player.visible = true
	if _exploration_camera != null and is_instance_valid(_exploration_camera):
		_exploration_camera.make_current()
	_session = null
	_arena = null
	_exploration_level = null
	_exploration_camera = null
	_enemy_visuals.clear()

func get_arena_map_data() -> MapData:
	return _arena

func _spawn_enemy_visuals(encounter: CombatEncounter) -> void:
	_enemy_visuals.clear()
	for enemy in encounter.get_enemies():
		var visual := _arena.spawn_enemy(enemy)
		if visual != null:
			_enemy_visuals[enemy] = visual

func _on_planning_started(eligible_actors: Array[PartyMember]) -> void:
	TurnManager.set_state(TurnManager.State.COMBAT_MENU)
	for enemy in _session.enemies:
		if not enemy.is_alive() or enemy.has_fled:
			_hide_enemy_visual(enemy)
	if eligible_actors.is_empty():
		_menu.set_interactable(false)

func _on_command_requested(actor: PartyMember, command_index: int, command_count: int) -> void:
	TurnManager.set_state(TurnManager.State.COMBAT_MENU)
	_menu.set_interactable(true)
	var party_index := PartyManager.party.find(actor)
	if party_index >= 0:
		PartyManager.select_party_member(party_index)
	message_requested.emit("Choose %s's command (%d/%d)." % [actor.member_name, command_index + 1, command_count])

func _on_resolution_started() -> void:
	TurnManager.set_state(TurnManager.State.TRANSITION)
	_menu.set_interactable(false)
	message_requested.emit("Commands locked. Resolving initiative.")

func _on_turn_started(actor: Resource) -> void:
	if not actor is EnemyInstance:
		return
	TurnManager.set_state(TurnManager.State.ENEMY_TURN)
	call_deferred("_perform_enemy_turn", actor)

func _perform_enemy_turn(enemy: EnemyInstance) -> void:
	if _session == null or enemy != _session.current_actor:
		return
	var targets: Array[PartyMember] = []
	for member in PartyManager.get_active_party():
		if member != null and member.is_alive():
			targets.append(member)
	if targets.is_empty():
		_session.perform_enemy_wait()
		return
	var target: PartyMember = targets.pick_random()
	var skill := _first_combat_skill(enemy)
	if skill != null:
		_session.perform_enemy_skill(skill, target)
	else:
		_session.perform_enemy_attack(target)

func _on_action_requested(action: StringName) -> void:
	clear_messages_requested.emit()
	if _session == null or _session.planning_actor == null:
		return
	var actor := _session.planning_actor
	var command := CombatCommand.create(actor, action)
	match action:
		CombatCommand.ATTACK:
			command.target = _first_active_enemy()
		CombatCommand.CAST:
			command.skill = _first_combat_skill(actor)
			command.target = _first_active_enemy()
			if command.skill == null or command.target == null:
				message_requested.emit("No usable combat skill or target is available.")
				return
		CombatCommand.ITEM:
			command.item = _first_usable_item(actor)
			if command.item == null:
				message_requested.emit("No usable combat item is available.")
				return
	if not _session.queue_player_command(command):
		message_requested.emit("That command could not be queued.")

func _on_action_resolved(result: Dictionary) -> void:
	var actor := result.get("actor") as Resource
	var target := result.get("target") as Resource
	match result.get("kind", &""):
		&"attack":
			if result.get("hit", false):
				message_requested.emit("%s hits %s for %d." % [CombatStats.display_name(actor), CombatStats.display_name(target), result.get("damage", 0)])
			else:
				message_requested.emit("%s misses %s." % [CombatStats.display_name(actor), CombatStats.display_name(target)])
		&"skill":
			if result.get("resisted", false):
				message_requested.emit("%s resists %s." % [CombatStats.display_name(target), result.skill.display_name])
			elif result.get("success", false):
				message_requested.emit("%s uses %s." % [CombatStats.display_name(actor), result.skill.display_name])
			else:
				message_requested.emit(result.get("message", "The skill failed."))
		&"defend": message_requested.emit("%s defends." % CombatStats.display_name(actor))
		&"item": message_requested.emit("%s uses %s." % [CombatStats.display_name(actor), result.get("item_name", "an item")])
		&"run": message_requested.emit("The party escapes!" if result.get("success", false) else "%s fails to escape." % CombatStats.display_name(actor))
		&"enemy_fled": message_requested.emit("%s flees from battle!" % CombatStats.display_name(actor))
		&"skipped": message_requested.emit(result.get("message", "%s cannot act." % CombatStats.display_name(actor)))
	if target is EnemyInstance and not target.is_alive():
		_hide_enemy_visual(target)
	if result.get("kind", &"") == &"enemy_fled" and actor is EnemyInstance:
		_hide_enemy_visual(actor)

func _on_combat_finished(outcome: StringName, rewards: Dictionary) -> void:
	_menu.set_interactable(false)
	combat_ended.emit(outcome, rewards)

func _hide_enemy_visual(enemy: EnemyInstance) -> void:
	var visual := _enemy_visuals.get(enemy) as Node3D
	if visual != null:
		visual.visible = false

func _first_active_enemy() -> EnemyInstance:
	if _session == null:
		return null
	for enemy in _session.enemies:
		if enemy.is_alive() and not enemy.has_fled:
			return enemy
	return null

func _first_combat_skill(actor: Resource) -> SkillData:
	for skill_id in actor.learned_skills:
		var skill := SkillSystem.get_skill(StringName(skill_id))
		if skill != null and skill.archetype == SkillData.Archetype.COMBAT_ACTIVE:
			return skill
	return null

func _first_usable_item(actor: PartyMember) -> ItemInstance:
	for item in actor.inventory:
		if item != null and item.item_data is ConsumableData:
			return item
	return null
