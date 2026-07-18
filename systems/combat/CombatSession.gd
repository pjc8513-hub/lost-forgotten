class_name CombatSession
extends RefCounted

signal planning_started(eligible_actors: Array[PartyMember])
signal command_requested(actor: PartyMember, command_index: int, command_count: int)
signal resolution_started
signal turn_started(actor: Resource)
signal action_resolved(result: Dictionary)
signal combat_finished(outcome: StringName, rewards: Dictionary)

var party: Array[PartyMember] = []
var enemies: Array[EnemyInstance] = []
var planning_actor: PartyMember
var current_actor: Resource

var _eligible_party: Array[PartyMember] = []
var _planned_commands: Dictionary = {}
var _planning_index := 0
var _turn_queue: Array[Resource] = []
var _finished := false

func _init(party_members: Array[PartyMember], enemy_members: Array[EnemyInstance]) -> void:
	party.assign(party_members)
	enemies.assign(enemy_members)

func start() -> void:
	_begin_round()

func queue_player_command(command: CombatCommand) -> bool:
	if _finished or planning_actor == null or command == null or command.actor != planning_actor:
		return false
	if not _is_supported_action(command.action):
		return false
	_planned_commands[planning_actor] = command
	_planning_index += 1
	planning_actor = null
	_request_next_command()
	return true

func queue_auto_attack_commands() -> int:
	if _finished or planning_actor == null:
		return 0
	var queued_count := 0
	while _planning_index < _eligible_party.size():
		var actor := _eligible_party[_planning_index]
		if actor != null and actor.is_alive() and CombatRules.can_act(actor):
			_planned_commands[actor] = _create_auto_attack_command(actor)
			queued_count += 1
		_planning_index += 1
	planning_actor = null
	_request_next_command()
	return queued_count

func get_targetable_enemy_rows(attacker: Resource) -> Array[int]:
	return CombatTargeting.enemy_rows_for(attacker, enemies)

func get_enemy_targets_in_row(attacker: Resource, row: int) -> Array[EnemyInstance]:
	return CombatTargeting.enemies_in_row(attacker, enemies, row)

func get_party_targets_for(attacker: Resource) -> Array[PartyMember]:
	return CombatTargeting.party_targets_for(attacker, party)

func perform_enemy_attack(target: PartyMember) -> void:
	if not _can_enemy_act():
		_finish_current_turn({"kind": &"skipped", "actor": current_actor, "message": "No valid target."})
		return
	var valid_targets := get_party_targets_for(current_actor)
	if target not in valid_targets:
		if valid_targets.is_empty():
			_finish_current_turn({"kind": &"skipped", "actor": current_actor, "message": "No valid target."})
			return
		target = valid_targets.pick_random()
	_finish_current_turn(CombatRules.basic_attack(current_actor, target))

func perform_enemy_skill(skill: SkillData, target: PartyMember) -> void:
	if not _can_enemy_act():
		_finish_current_turn({"kind": &"skipped", "actor": current_actor, "message": "No valid target."})
		return
	var valid_targets := get_party_targets_for(current_actor)
	if target not in valid_targets:
		if valid_targets.is_empty():
			_finish_current_turn({"kind": &"skipped", "actor": current_actor, "message": "No valid target."})
			return
		target = valid_targets.pick_random()
	_finish_current_turn(CombatRules.use_skill(current_actor, target, skill))

func perform_enemy_wait() -> void:
	if _can_enemy_act():
		_finish_current_turn({"kind": &"wait", "actor": current_actor})

func _begin_round() -> void:
	if _check_finished():
		return
	current_actor = null
	planning_actor = null
	_turn_queue.clear()
	_planned_commands.clear()
	_eligible_party.clear()
	_planning_index = 0

	for actor in _living_party():
		CombatRules.tick_statuses(actor)
		if CombatRules.can_act(actor):
			_eligible_party.append(actor)
	for actor in _active_enemies():
		CombatRules.tick_statuses(actor)

	if _check_finished():
		return
	planning_started.emit(_eligible_party)
	_request_next_command()

func _request_next_command() -> void:
	if _planning_index < _eligible_party.size():
		planning_actor = _eligible_party[_planning_index]
		command_requested.emit(planning_actor, _planning_index, _eligible_party.size())
		return
	_begin_resolution()

func _begin_resolution() -> void:
	planning_actor = null
	var initiative_scores: Dictionary = {}
	for actor in _living_party():
		_turn_queue.append(actor)
		initiative_scores[actor] = DiceRoller.d20(CombatStats.initiative(actor)).total
	for actor in _active_enemies():
		_turn_queue.append(actor)
		initiative_scores[actor] = DiceRoller.d20(CombatStats.initiative(actor)).total
	_turn_queue.sort_custom(func(a: Resource, b: Resource) -> bool:
		return int(initiative_scores[a]) > int(initiative_scores[b])
	)
	resolution_started.emit()
	_advance_resolution()

func _advance_resolution() -> void:
	if _finished or _check_finished():
		return
	while not _turn_queue.is_empty():
		var actor: Resource = _turn_queue.pop_front()
		if actor == null or not actor.is_alive() or (actor is EnemyInstance and actor.has_fled):
			continue
		actor.active_combat_buffs.erase("armor_class")
		current_actor = actor
		if not CombatRules.can_act(actor):
			action_resolved.emit({"kind": &"skipped", "actor": actor, "message": "%s cannot act." % CombatStats.display_name(actor)})
			current_actor = null
			continue
		if actor is PartyMember:
			var command := _planned_commands.get(actor) as CombatCommand
			if command == null:
				action_resolved.emit({"kind": &"skipped", "actor": actor, "message": "%s has no command." % CombatStats.display_name(actor)})
				current_actor = null
				continue
			_execute_player_command(command)
			if _finished:
				return
			current_actor = null
			if _check_finished():
				return
			continue

		var enemy := actor as EnemyInstance
		if _enemy_flees(enemy):
			enemy.has_fled = true
			action_resolved.emit({"kind": &"enemy_fled", "actor": enemy})
			current_actor = null
			if _check_finished():
				return
			continue
		turn_started.emit(enemy)
		return
	_begin_round()

func _execute_player_command(command: CombatCommand) -> void:
	var result: Dictionary
	match command.action:
		CombatCommand.ATTACK:
			var attack_target := _resolve_enemy_target(command.actor, command.target, command.target_row)
			if attack_target != null:
				result = CombatRules.basic_attack(command.actor, attack_target)
			else:
				result = _invalid_command_result(command, "The target is no longer available.")
		CombatCommand.DEFEND:
			command.actor.active_combat_buffs["armor_class"] = {"value": -2, "expires": &"next_turn"}
			result = {"kind": &"defend", "actor": command.actor}
		CombatCommand.CAST:
			var spell_target := _resolve_enemy_target(command.actor, command.target, command.target_row)
			if spell_target != null and command.skill != null:
				result = CombatRules.use_skill(command.actor, spell_target, command.skill)
			else:
				result = _invalid_command_result(command, "The spell target is no longer available.")
		CombatCommand.ITEM:
			if command.item != null and command.actor.inventory.has(command.item) and command.actor.use_inventory_item(command.item):
				result = {"kind": &"item", "actor": command.actor, "item_name": command.item.item_data.name}
			else:
				result = _invalid_command_result(command, "The item is no longer available.")
		CombatCommand.RUN:
			var roll := DiceRoller.d20(CombatStats.ability_modifier(CombatStats.dexterity(command.actor))).total
			var escaped := roll >= 12
			result = {"kind": &"run", "actor": command.actor, "roll": roll, "success": escaped}
			if escaped:
				action_resolved.emit(result)
				_end(&"fled")
				return
		_:
			result = _invalid_command_result(command, "That command is no longer available.")
	action_resolved.emit(result)

func _finish_current_turn(result: Dictionary) -> void:
	if current_actor == null:
		return
	action_resolved.emit(result)
	current_actor = null
	if not _check_finished():
		_advance_resolution()

func _enemy_flees(enemy: EnemyInstance) -> bool:
	var chance := enemy.get_current_flee_chance()
	return chance > 0.0 and DiceRoller.roll(1, 10000).total <= roundi(chance * 10000.0)

func _check_finished() -> bool:
	if _living_party().is_empty():
		_end(&"defeat")
		return true
	if _active_enemies().is_empty():
		_end(&"victory")
		return true
	return false

func _end(outcome: StringName) -> void:
	if _finished:
		return
	_finished = true
	planning_actor = null
	current_actor = null
	combat_finished.emit(outcome, _build_rewards() if outcome == &"victory" else _empty_rewards())

func _build_rewards() -> Dictionary:
	var rewards := _empty_rewards()
	for enemy in enemies:
		if enemy == null or enemy.has_fled or enemy.is_alive() or enemy.enemy_data == null:
			continue
		rewards.xp += maxi(enemy.enemy_data.xp, 0)
		rewards.gold += maxi(enemy.enemy_data.gold, 0)
		var probability := clampf(enemy.enemy_data.loot_probability, 0.0, 1.0)
		if probability > 0.0 and DiceRoller.roll(1, 10000).total <= roundi(probability * 10000.0):
			var tables: Array[LootManager.Loot_Table] = [enemy.enemy_data.loot_table]
			rewards.items.append_array(LootManager.generate_loot(tables))
	return rewards

func _empty_rewards() -> Dictionary:
	return {"xp": 0, "gold": 0, "items": []}

func _is_valid_enemy_target(target: Resource) -> bool:
	return target is EnemyInstance and target.is_alive() and not target.has_fled

func _resolve_enemy_target(
	attacker: Resource,
	preferred_target: Resource,
	preferred_row: int
) -> EnemyInstance:
	var legal_rows := get_targetable_enemy_rows(attacker)
	if preferred_row in legal_rows:
		var preferred_row_targets := get_enemy_targets_in_row(attacker, preferred_row)
		if preferred_target in preferred_row_targets:
			return preferred_target as EnemyInstance
		if not preferred_row_targets.is_empty():
			return preferred_row_targets[0]
	if _is_valid_enemy_target(preferred_target) and preferred_target.formation_row in legal_rows:
		return preferred_target as EnemyInstance
	if legal_rows.is_empty():
		return null
	var targets := get_enemy_targets_in_row(attacker, legal_rows[0])
	return null if targets.is_empty() else targets[0]

func _invalid_command_result(command: CombatCommand, message: String) -> Dictionary:
	return {"kind": &"skipped", "actor": command.actor, "message": message}

func _create_auto_attack_command(actor: PartyMember) -> CombatCommand:
	var rows := get_targetable_enemy_rows(actor)
	var target: EnemyInstance = null
	var target_row := -1
	if not rows.is_empty():
		target_row = rows[0]
		var targets := get_enemy_targets_in_row(actor, target_row)
		if not targets.is_empty():
			target = targets[0]
	var command := CombatCommand.create(actor, CombatCommand.ATTACK, target)
	command.target_row = target_row
	return command

func _can_enemy_act() -> bool:
	return not _finished and current_actor is EnemyInstance and current_actor.is_alive() and not current_actor.has_fled

func _is_supported_action(action: StringName) -> bool:
	return action in [CombatCommand.ATTACK, CombatCommand.DEFEND, CombatCommand.CAST, CombatCommand.ITEM, CombatCommand.RUN]

func _living_party() -> Array[PartyMember]:
	var result: Array[PartyMember] = []
	for actor in party:
		if actor != null and actor.is_alive():
			result.append(actor)
	return result

func _active_enemies() -> Array[EnemyInstance]:
	var result: Array[EnemyInstance] = []
	for actor in enemies:
		if actor != null and actor.is_alive() and not actor.has_fled:
			result.append(actor)
	return result
