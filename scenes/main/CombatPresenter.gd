class_name CombatPresenter
extends Node

signal message_requested(message: String)
signal combat_closed(outcome: StringName)

var _level_root: Node
var _player: Node3D
var _menu: CombatMenu
var _exploration_level: Node3D
var _arena: Node3D
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
	_exploration_level = StageManager.current_level as Node3D
	if _exploration_level != null:
		_exploration_level.visible = false
	if _player != null:
		_player.visible = false
	_arena = encounter.combat_scene.instantiate() as Node3D
	_level_root.add_child(_arena)
	_spawn_enemy_visuals(encounter)
	_session = CombatSession.new(PartyManager.get_active_party(), encounter.get_enemies())
	_session.turn_started.connect(_on_turn_started)
	_session.action_resolved.connect(_on_action_resolved)
	_session.combat_finished.connect(_on_combat_finished)
	_menu.visible = true
	_menu.set_interactable(false)
	TurnManager.set_state(TurnManager.State.TRANSITION)
	_session.start()
	return true

func _spawn_enemy_visuals(encounter: CombatEncounter) -> void:
	_enemy_visuals.clear()
	for enemy in encounter.get_enemies():
		if enemy.enemy_data == null or enemy.enemy_data.enemy_scene == null:
			continue
		var marker_path := "enemies/row_%d/EnemySlot_%d" % [enemy.formation_row + 1, enemy.formation_row * 3 + enemy.formation_slot + 1]
		var marker := _arena.get_node_or_null(marker_path) as Marker3D
		if marker == null:
			push_warning("Combat scene is missing marker: %s" % marker_path)
			continue
		var visual := enemy.enemy_data.enemy_scene.instantiate() as Node3D
		marker.add_child(visual)
		visual.position = Vector3.ZERO
		_enemy_visuals[enemy] = visual

func _on_turn_started(actor: Resource) -> void:
	if actor is PartyMember:
		TurnManager.set_state(TurnManager.State.COMBAT_MENU)
		_menu.set_interactable(true)
		message_requested.emit("%s's turn" % CombatStats.display_name(actor))
	else:
		TurnManager.set_state(TurnManager.State.ENEMY_TURN)
		_menu.set_interactable(false)
		call_deferred("_perform_enemy_turn", actor)

func _perform_enemy_turn(enemy: EnemyInstance) -> void:
	if _session == null or enemy != _session.current_actor:
		return
	var targets: Array[PartyMember] = PartyManager.get_active_party().filter(func(member: PartyMember) -> bool: return member.is_alive())
	if targets.is_empty():
		_session.wait()
		return
	var target: PartyMember = targets.pick_random()
	var skill := _first_combat_skill(enemy)
	if skill != null:
		_session.perform_skill(skill, target)
	else:
		_session.perform_attack(target)

func _on_action_requested(action: StringName) -> void:
	if _session == null or not _session.current_actor is PartyMember:
		return
	_menu.set_interactable(false)
	match action:
		&"attack":
			var target := _first_living_enemy()
			if target != null: _session.perform_attack(target)
		&"defend": _session.defend()
		&"cast":
			var skill := _first_combat_skill(_session.current_actor)
			var target := _first_living_enemy()
			if skill != null and target != null:
				_session.perform_skill(skill, target)
			else:
				message_requested.emit("No usable combat skill is available.")
				_menu.set_interactable(true)
		&"item":
			if not _use_first_combat_item(_session.current_actor as PartyMember):
				message_requested.emit("No usable combat item is available.")
				_menu.set_interactable(true)
		&"wait": _session.wait()
		&"run": _session.attempt_run()

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
		&"run": message_requested.emit("The party escapes!" if result.get("success", false) else "The escape attempt fails.")
	if target is EnemyInstance and not target.is_alive():
		var visual := _enemy_visuals.get(target) as Node3D
		if visual != null: visual.visible = false

func _on_combat_finished(outcome: StringName) -> void:
	_menu.visible = false
	_menu.set_interactable(false)
	if _arena != null:
		_level_root.remove_child(_arena)
		_arena.queue_free()
	if _exploration_level != null:
		_exploration_level.visible = true
	if _player != null:
		_player.visible = true
	_session = null
	_arena = null
	_enemy_visuals.clear()
	TurnManager.set_state(TurnManager.State.EXPLORATION if outcome != &"defeat" else TurnManager.State.PAUSED)
	combat_closed.emit(outcome)

func _first_living_enemy() -> EnemyInstance:
	for enemy in _session.enemies:
		if enemy.is_alive(): return enemy
	return null

func _first_combat_skill(actor: Resource) -> SkillData:
	for skill_id in actor.learned_skills:
		var skill := SkillSystem.get_skill(StringName(skill_id))
		if skill != null and skill.archetype == SkillData.Archetype.COMBAT_ACTIVE:
			return skill
	return null

func _use_first_combat_item(actor: PartyMember) -> bool:
	if actor == null:
		return false
	for item in actor.inventory:
		if item != null and item.item_data is ConsumableData:
			var item_name := item.item_data.name
			if not actor.use_inventory_item(item):
				continue
			message_requested.emit("%s uses %s." % [actor.member_name, item_name])
			_session.wait()
			return true
	return false
