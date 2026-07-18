class_name CombatSession
extends RefCounted

signal turn_started(actor: Resource)
signal action_resolved(result: Dictionary)
signal combat_finished(outcome: StringName)

var party: Array[PartyMember] = []
var enemies: Array[EnemyInstance] = []
var current_actor: Resource
var _turn_queue: Array[Resource] = []
var _finished := false

func _init(party_members: Array[PartyMember], enemy_members: Array[EnemyInstance]) -> void:
	party.assign(party_members)
	enemies.assign(enemy_members)

func start() -> void:
	_begin_round()

func perform_attack(target: Resource) -> void:
	if not _can_submit_action() or target == null or not target.is_alive():
		return
	action_resolved.emit(CombatRules.basic_attack(current_actor, target))
	_finish_turn()

func perform_skill(skill: SkillData, target: Resource) -> void:
	if not _can_submit_action() or target == null:
		return
	var result := CombatRules.use_skill(current_actor, target, skill)
	action_resolved.emit(result)
	if result.get("success", false):
		_finish_turn()

func defend() -> void:
	if not _can_submit_action():
		return
	current_actor.active_combat_buffs["armor_class"] = {"value": -2, "expires": &"next_turn"}
	action_resolved.emit({"kind": &"defend", "actor": current_actor})
	_finish_turn()

func wait() -> void:
	if not _can_submit_action():
		return
	action_resolved.emit({"kind": &"wait", "actor": current_actor})
	_finish_turn()

func attempt_run() -> void:
	if not _can_submit_action() or not current_actor is PartyMember:
		return
	var roll := DiceRoller.d20(CombatStats.ability_modifier(CombatStats.dexterity(current_actor))).total
	action_resolved.emit({"kind": &"run", "actor": current_actor, "roll": roll, "success": roll >= 12})
	if roll >= 12:
		_end(&"fled")
	else:
		_finish_turn()

func _finish_turn() -> void:
	if _finished or _check_finished():
		return
	current_actor = null
	_advance_turn()

func _advance_turn() -> void:
	while not _turn_queue.is_empty():
		var actor: Resource = _turn_queue.pop_front()
		if actor == null or not actor.is_alive():
			continue
		actor.active_combat_buffs.erase("armor_class")
		current_actor = actor
		if not CombatRules.can_act(actor):
			action_resolved.emit({"kind": &"skipped", "actor": actor})
			current_actor = null
			continue
		turn_started.emit(actor)
		return
	_begin_round()

func _begin_round() -> void:
	if _check_finished():
		return
	_turn_queue.clear()
	var initiative_scores: Dictionary = {}
	for actor in _living_party():
		CombatRules.tick_statuses(actor)
		_turn_queue.append(actor)
		initiative_scores[actor] = DiceRoller.d20(CombatStats.initiative(actor)).total
	for actor in _living_enemies():
		CombatRules.tick_statuses(actor)
		_turn_queue.append(actor)
		initiative_scores[actor] = DiceRoller.d20(CombatStats.initiative(actor)).total
	_turn_queue.sort_custom(func(a: Resource, b: Resource) -> bool:
		return int(initiative_scores[a]) > int(initiative_scores[b])
	)
	_advance_turn()

func _can_submit_action() -> bool:
	return not _finished and current_actor != null and current_actor.is_alive()

func _check_finished() -> bool:
	if _living_enemies().is_empty():
		_end(&"victory")
		return true
	if _living_party().is_empty():
		_end(&"defeat")
		return true
	return false

func _end(outcome: StringName) -> void:
	if _finished:
		return
	_finished = true
	current_actor = null
	combat_finished.emit(outcome)

func _living_party() -> Array[PartyMember]:
	var result: Array[PartyMember] = []
	for actor in party:
		if actor != null and actor.is_alive(): result.append(actor)
	return result

func _living_enemies() -> Array[EnemyInstance]:
	var result: Array[EnemyInstance] = []
	for actor in enemies:
		if actor != null and actor.is_alive(): result.append(actor)
	return result
