extends Control

@onready var messages: RichTextLabel = $PanelContainer/VBoxContainer/ScrollContainer/Messages
@onready var enter_button: Button = $PanelContainer/VBoxContainer/HBoxContainer/EnterButton
@onready var clear_button: Button = $PanelContainer/VBoxContainer/HBoxContainer/ClearButton
@onready var line_edit: LineEdit = $PanelContainer/VBoxContainer/HBoxContainer/LineEdit

const MAX_SWITCH_DEBUG_LINES := 8
const GRID_DEBUG_DIRECTIONS: Array[Dictionary] = [
	{"label": "N", "value": Vector3i(0, 0, -1)},
	{"label": "E", "value": Vector3i(1, 0, 0)},
	{"label": "S", "value": Vector3i(0, 0, 1)},
	{"label": "W", "value": Vector3i(-1, 0, 0)},
]
const STAT_FIELDS: Array[Dictionary] = [
	{"label": "Strength", "rolled": &"rolled_strength", "class": &"base_strength", "race": &"bonus_strength"},
	{"label": "Endurance", "rolled": &"rolled_endurance", "class": &"base_endurance", "race": &"bonus_endurance"},
	{"label": "Wisdom", "rolled": &"rolled_wisdom", "class": &"base_wisdom", "race": &"bonus_wisdom"},
	{"label": "Dexterity", "rolled": &"rolled_dexterity", "class": &"base_dexterity", "race": &"bonus_dexterity"},
	{"label": "Piety", "rolled": &"rolled_piety", "class": &"base_piety", "race": &"bonus_piety"},
	{"label": "Willpower", "rolled": &"rolled_willpower", "class": &"base_willpower", "race": &"bonus_willpower"},
]

@export var grid_debug_enabled := false

var switch_debug_lines: Array[String] = []
var console_log: Array[String] = []
var inspected_grid_pos := Vector3i.ZERO
var _movement_debug_source: GridMovementController

func _ready() -> void:
	messages.bbcode_enabled = true
	PartyManager.selected_party_member_changed.connect(_on_selected_party_member_changed)
	visibility_changed.connect(_on_visibility_changed)
	clear_button.pressed.connect(_clear_messages)
	line_edit.text_submitted.connect(_on_text_submitted)
	enter_button.pressed.connect(_on_enter_pressed)
	_refresh(PartyManager.selected_party_member)

func _clear_messages()->void:
	messages.clear()
	switch_debug_lines.clear()
	console_log.clear()

func _on_text_submitted(new_text: String) -> void:
	_execute_command(new_text)

func _on_enter_pressed() -> void:
	_execute_command(line_edit.text)

func _on_selected_party_member_changed(_index: int, member: PartyMember) -> void:
	_refresh(member)

func _on_visibility_changed() -> void:
	if visible:
		_refresh(PartyManager.selected_party_member)

func add_switch_interaction(
	switch: SwitchComponent,
	exported_data: Dictionary,
	results: Array,
	success: bool,
	signal_result: int,
	signal_exists: bool,
	signal_connection_count: int
) -> void:
	var target_door_ids: Array = exported_data.get("target_door_ids", [])
	var target_blocker_ids: Array = exported_data.get("target_blocker_ids", [])
	var lines: Array[String] = [
		"Switch: %s" % switch.get_path(),
		"Targets: doors=%s blockers=%s" % [
			_format_string_names(target_door_ids),
			_format_string_names(target_blocker_ids),
		],
		"Signal: %s, exists=%s, connections=%d" % [
			_error_name(signal_result),
			signal_exists,
			signal_connection_count,
		],
		"Success: %s" % success,
		"Results: %s" % _format_results(results),
	]
	switch_debug_lines.push_front("\n".join(lines))
	if switch_debug_lines.size() > MAX_SWITCH_DEBUG_LINES:
		switch_debug_lines.resize(MAX_SWITCH_DEBUG_LINES)
	_refresh(PartyManager.selected_party_member)

func _refresh(member: PartyMember) -> void:
	if not is_node_ready():
		return
	if member == null:
		var no_member_lines: Array[String] = ["No party member selected."]
		_append_switch_debug(no_member_lines)
		messages.text = "\n".join(no_member_lines)
		return

	var class_data := member.class_data
	var race_data := member.race_data
	var lines: Array[String] = [
		"Selected Character",
		"Name: %s" % member.member_name,
		"Row: %s (%d)" % [member.get_row_display_name(), member.row],
		"Class: %s" % _class_name(class_data),
		"Level: %d" % member.level,
		"XP: %d / %d%s" % [
			member.xp,
			member.xp_to_next_level,
			" (ready to train)" if member.can_level_up() else "",
		],
		"Class resource: %s" % (class_data.resource_path if class_data != null else "<null>"),
		"Race: %s" % member.get_race_display_name(),
		"Race resource: %s" % (race_data.resource_path if race_data != null else "<null>"),
		"Race display_name: %s" % (race_data.display_name if race_data != null else "<null>"),
		"",
		"Rolled / Class / Race / Total",
	]

	for fields in STAT_FIELDS:
		var rolled := int(member.get(fields.rolled))
		var class_bonus := int(class_data.get(fields["class"])) if class_data != null else 0
		var race_bonus := int(race_data.get(fields.race)) if race_data != null else 0
		lines.append("%s: %d + %d + %d = %d" % [fields.label, rolled, class_bonus, race_bonus, _calculated_stat(member, fields.label)])

	lines.append("")
	lines.append("Class starting skills: %s" % _format_skills(class_data.starting_skills if class_data != null else []))
	lines.append("Race starting skills: %s" % _format_skills(race_data.starting_skills if race_data != null else []))
	lines.append("Learned skills: %s" % _format_learned_skills(member.learned_skills))
	_append_grid_debug(lines)
	_append_switch_debug(lines)
	_append_console_log(lines)
	messages.text = "\n".join(lines)

func _class_name(class_data: ClassData) -> String:
	if class_data == null:
		return "Unknown"
	return ClassData.get_display_name_for(class_data.class_id)

func _calculated_stat(member: PartyMember, stat_label: String) -> int:
	match stat_label:
		"Strength": return StatCalculator.get_strength(member)
		"Endurance": return StatCalculator.get_endurance(member)
		"Wisdom": return StatCalculator.get_wisdom(member)
		"Dexterity": return StatCalculator.get_dexterity(member)
		"Piety": return StatCalculator.get_piety(member)
		"Willpower": return StatCalculator.get_willpower(member)
	return 0

func _format_skills(skill_ids: Array) -> String:
	if skill_ids.is_empty():
		return "None"
	var names: Array[String] = []
	for skill_id in skill_ids:
		var skill := SkillSystem.get_skill(StringName(skill_id))
		names.append(skill.display_name if skill != null else String(skill_id).capitalize())
	return ", ".join(names)

func _format_learned_skills(learned_skills: Dictionary) -> String:
	if learned_skills.is_empty():
		return "None"
	var entries: Array[String] = []
	for skill_id in learned_skills:
		var skill := SkillSystem.get_skill(StringName(skill_id))
		var skill_name: String = skill.display_name if skill != null else String(skill_id).capitalize()
		entries.append("%s (rank %d)" % [skill_name, int(learned_skills[skill_id])])
	entries.sort()
	return ", ".join(entries)

func _append_switch_debug(lines: Array[String]) -> void:
	if switch_debug_lines.is_empty():
		return
	lines.append("")
	lines.append("Switch Interactions")
	lines.append_array(switch_debug_lines)

func _format_string_names(values: Array) -> String:
	if values.is_empty():
		return "None"
	var names: Array[String] = []
	for value in values:
		names.append(String(value))
	return ", ".join(names)

func _format_results(results: Array) -> String:
	if results.is_empty():
		return "No targets"
	var lines: Array[String] = []
	for result in results:
		lines.append(String(result))
	return "; ".join(lines)

func _error_name(error_code: int) -> String:
	if error_code == OK:
		return "OK"
	return "Error %d" % error_code

func _append_console_log(lines: Array[String]) -> void:
	if console_log.is_empty():
		return
	lines.append("")
	lines.append("Console Log:")
	lines.append_array(console_log)

func _append_grid_debug(lines: Array[String]) -> void:
	if not grid_debug_enabled:
		return

	lines.append("")
	lines.append("Grid Debug")
	var player := _get_player()
	if player == null:
		lines.append("Player: <not registered>")
		lines.append_array(_format_cell_inspection(inspected_grid_pos, "Inspect"))
		return

	var movement := player.get_node_or_null("GridMovementController") as GridMovementController
	if movement == null:
		lines.append("GridMovementController: <missing>")
		lines.append_array(_format_cell_inspection(inspected_grid_pos, "Inspect"))
		return

	_watch_movement(movement)
	var forward_target := movement.grid_pos + movement.facing
	lines.append("Player grid: %s  world: %s" % [_format_grid_pos(movement.grid_pos), _format_world_pos(player.global_position)])
	lines.append("Facing: %s %s" % [_direction_label(movement.facing), _format_grid_pos(movement.facing)])
	lines.append("Forward edge blocked: %s" % MapManager.is_edge_blocked(movement.grid_pos, movement.facing))
	lines.append("Forward target blocked: %s" % movement.is_blocked(forward_target))
	lines.append_array(_format_cell_inspection(movement.grid_pos, "Current"))
	lines.append_array(_format_cell_inspection(forward_target, "Forward"))
	lines.append_array(_format_cell_inspection(inspected_grid_pos, "Inspect"))

func _watch_movement(movement: GridMovementController) -> void:
	if _movement_debug_source == movement:
		return
	if _movement_debug_source != null and _movement_debug_source.grid_state_changed.is_connected(_on_grid_state_changed):
		_movement_debug_source.grid_state_changed.disconnect(_on_grid_state_changed)
	_movement_debug_source = movement
	if not _movement_debug_source.grid_state_changed.is_connected(_on_grid_state_changed):
		_movement_debug_source.grid_state_changed.connect(_on_grid_state_changed)

func _on_grid_state_changed(_grid_pos: Vector3i, _facing: Vector3i) -> void:
	if grid_debug_enabled:
		_refresh(PartyManager.selected_party_member)

func _format_cell_inspection(pos: Vector3i, label: String) -> Array[String]:
	var lines: Array[String] = []
	var elements := MapManager.get_elements(pos)
	var actor := MapManager.get_actor(pos)
	lines.append("%s cell %s: elements=%d actor=%s" % [
		label,
		_format_grid_pos(pos),
		elements.size(),
		actor.get_path() if actor != null else "None",
	])
	lines.append("%s edges: %s" % [label, _format_edge_summary(pos)])

	if elements.is_empty():
		lines.append("%s element: <none>" % label)
		return lines

	for element in elements:
		lines.append("%s element: %s" % [label, _format_grid_element(element)])
		var tile = element.get_parent()
		if tile != null:
			var blockers := _format_blockers(tile)
			if not blockers.is_empty():
				lines.append("%s blockers: %s" % [label, blockers])
			var doors := _format_doors(tile)
			if not doors.is_empty():
				lines.append("%s doors: %s" % [label, doors])
	return lines

func _format_edge_summary(pos: Vector3i) -> String:
	var parts: Array[String] = []
	for direction_data in GRID_DEBUG_DIRECTIONS:
		var direction: Vector3i = direction_data.value
		var blocked := MapManager.is_edge_blocked(pos, direction)
		var door = MapManager.get_door_on_edge(pos, direction)
		var detail := "door %s" % _format_door_state(door) if door != null else "static"
		parts.append("%s=%s (%s)" % [direction_data.label, "blocked" if blocked else "open", detail])
	return ", ".join(parts)

func _format_grid_element(element: Node) -> String:
	var grid_element := element as GridElement
	var tile := element.get_parent()
	var tile_path := tile.get_path() if tile != null else element.get_path()
	if grid_element == null:
		return "%s via %s" % [tile_path, element.get_path()]

	var shape_name = GridElement.CellShape.keys()[grid_element.cell_shape]
	var blocked_edges: Array[String] = []
	for direction_data in GRID_DEBUG_DIRECTIONS:
		var direction: Vector3i = direction_data.value
		if grid_element.blocks_edge(direction):
			blocked_edges.append(direction_data.label)
	return "%s shape=%s registered=%s y_rot=%.1f blocked_edges=%s" % [
		tile_path,
		shape_name,
		_format_grid_pos(grid_element.grid_pos),
		rad_to_deg(grid_element.global_rotation.y),
		", ".join(blocked_edges) if not blocked_edges.is_empty() else "None",
	]

func _format_blockers(tile: Node) -> String:
	var blockers: Array[String] = []
	for component in tile.get_children():
		if component is BlockerComponent:
			blockers.append("%s blocks=%s open=%s" % [
				String(component.blocker_ID) if not component.blocker_ID.is_empty() else component.name,
				component.blocks_movement,
				component.is_open,
			])
	return "; ".join(blockers)

func _format_doors(tile: Node) -> String:
	var doors: Array[String] = []
	for component in tile.get_children():
		if component is DoorComponent:
			doors.append("%s edge=%s state=%s" % [
				String(component.door_id) if not component.door_id.is_empty() else component.name,
				_direction_label(component.get_world_edge()),
				_format_door_state(component),
			])
	return "; ".join(doors)

func _format_door_state(door: DoorComponent) -> String:
	return "%s locked=%s open=%s blocks=%s" % [
		String(door.door_id) if not door.door_id.is_empty() else door.name,
		door.is_locked,
		door.is_open,
		door.blocks_movement(),
	]

func _format_grid_pos(pos: Vector3i) -> String:
	return "(%d, %d, %d)" % [pos.x, pos.y, pos.z]

func _format_world_pos(pos: Vector3) -> String:
	return "(%.2f, %.2f, %.2f)" % [pos.x, pos.y, pos.z]

func _direction_label(direction: Vector3i) -> String:
	for direction_data in GRID_DEBUG_DIRECTIONS:
		if direction_data.value == direction:
			return direction_data.label
	return "?"

func _log_message(msg: String) -> void:
	console_log.append(msg)
	if console_log.size() > 10:
		console_log.remove_at(0)
	_refresh(PartyManager.selected_party_member)

func _get_player() -> Node3D:
	for actor in MapManager.actors.values():
		if actor != null and (actor.name == "PlayerPawn" or actor.has_node("GridMovementController")):
			return actor
	return null

func _execute_command(input: String) -> void:
	var text := input.strip_edges()
	if text.is_empty():
		return
	line_edit.clear()
	
	_log_message("> " + text)
	
	var parts := text.split(" ", false)
	if parts.is_empty():
		return
		
	var cmd := parts[0].to_lower()
	var args := parts.slice(1)
	
	match cmd:
		"help":
			_log_message("Commands: help, gold <amt>, food <amt>, xp [all] <amt>, heal [all], stamina [all/full] <amt>, damage [all] <amt>, kill [all], status <status>, additem <id>, tp <x> <z>, griddebug [on/off], cell <x> <z>")
		"griddebug":
			if args.is_empty():
				grid_debug_enabled = not grid_debug_enabled
			else:
				var value := args[0].to_lower()
				if value in ["on", "true", "1", "yes"]:
					grid_debug_enabled = true
				elif value in ["off", "false", "0", "no"]:
					grid_debug_enabled = false
				else:
					_log_message("Error: griddebug expects on or off.")
					return
			_log_message("Grid debug %s." % ("enabled" if grid_debug_enabled else "disabled"))
			_refresh(PartyManager.selected_party_member)
		"cell":
			if args.size() < 2:
				_log_message("Error: cell requires x and z coordinates (e.g. cell 0 0)")
				return
			inspected_grid_pos = Vector3i(int(args[0]), 0, int(args[1]))
			grid_debug_enabled = true
			_log_message("Inspecting grid cell %s." % _format_grid_pos(inspected_grid_pos))
			_refresh(PartyManager.selected_party_member)
		"gold":
			if args.is_empty():
				_log_message("Error: gold requires an amount (e.g. gold 100)")
				return
			var amt := int(args[0])
			if amt > 0:
				PartyManager.add_gold(amt)
				_log_message("Added %d gold. Total: %d" % [amt, PartyManager.gold])
			elif amt < 0:
				var success := PartyManager.spend_gold(-amt)
				if success:
					_log_message("Spent %d gold. Total: %d" % [-amt, PartyManager.gold])
				else:
					_log_message("Failed to spend %d gold. Total: %d" % [-amt, PartyManager.gold])
			else:
				_log_message("Gold unchanged. Total: %d" % PartyManager.gold)
		"food":
			if args.is_empty():
				_log_message("Error: food requires an amount (e.g. food 10)")
				return
			var amt := int(args[0])
			if amt > 0:
				PartyManager.add_food(amt)
				_log_message("Added %d food. Total: %d" % [amt, PartyManager.food])
			elif amt < 0:
				var success := PartyManager.spend_food(-amt)
				if success:
					_log_message("Spent %d food. Total: %d" % [-amt, PartyManager.food])
				else:
					_log_message("Failed to spend %d food. Total: %d" % [-amt, PartyManager.food])
			else:
				_log_message("Food unchanged. Total: %d" % PartyManager.food)
		"xp":
			if args.is_empty():
				_log_message("Error: xp requires an amount (e.g. xp 100 or xp all 100)")
				return
			var is_all := false
			var amt_str := args[0]
			if args[0].to_lower() == "all":
				is_all = true
				if args.size() < 2:
					_log_message("Error: xp all requires an amount (e.g. xp all 100)")
					return
				amt_str = args[1]
			var amt := int(amt_str)
			if amt <= 0:
				_log_message("Error: XP must be positive.")
				return
			
			if is_all:
				for member in PartyManager.get_active_party():
					member.add_xp(amt)
				_log_message("Added %d XP to all active party members." % amt)
			else:
				var member := PartyManager.selected_party_member
				if member == null:
					_log_message("Error: No selected party member.")
				else:
					member.add_xp(amt)
					var ready_text := " Ready to train." if member.can_level_up() else ""
					_log_message("Added %d XP to %s. Total: %d.%s" % [amt, member.member_name, member.xp, ready_text])
		"heal":
			var is_all := false
			if not args.is_empty() and args[0].to_lower() == "all":
				is_all = true
			
			if is_all:
				for member in PartyManager.get_active_party():
					member.heal(member.max_hp)
				_log_message("Healed all active party members.")
			else:
				var member := PartyManager.selected_party_member
				if member == null:
					_log_message("Error: No selected party member.")
				else:
					member.heal(member.max_hp)
					_log_message("Healed %s." % member.member_name)
		"stamina":
			if args.is_empty():
				_log_message("Error: stamina requires an amount or 'full' (e.g. stamina 20, stamina all 20, stamina full)")
				return
			var first_arg := args[0].to_lower()
			if first_arg == "full":
				for member in PartyManager.get_active_party():
					member.restore_stamina(member.max_stamina)
				_log_message("Restored all active party members to full stamina.")
				return
			
			var is_all := false
			var amt_str := args[0]
			if first_arg == "all":
				is_all = true
				if args.size() < 2:
					_log_message("Error: stamina all requires an amount (e.g. stamina all 20)")
					return
				amt_str = args[1]
			var amt := int(amt_str)
			if amt <= 0:
				_log_message("Error: stamina amount must be positive.")
				return
				
			if is_all:
				for member in PartyManager.get_active_party():
					member.restore_stamina(amt)
				_log_message("Restored %d stamina to all active party members." % amt)
			else:
				var member := PartyManager.selected_party_member
				if member == null:
					_log_message("Error: No selected party member.")
				else:
					member.restore_stamina(amt)
					_log_message("Restored %d stamina to %s. Total: %d" % [amt, member.member_name, member.current_stamina])
		"damage":
			if args.is_empty():
				_log_message("Error: damage requires an amount (e.g. damage 10 or damage all 10)")
				return
			var is_all := false
			var amt_str := args[0]
			if args[0].to_lower() == "all":
				is_all = true
				if args.size() < 2:
					_log_message("Error: damage all requires an amount (e.g. damage all 10)")
					return
				amt_str = args[1]
			var amt := int(amt_str)
			if amt <= 0:
				_log_message("Error: damage amount must be positive.")
				return
				
			if is_all:
				for member in PartyManager.get_active_party():
					member.take_damage(amt)
				_log_message("Dealt %d damage to all active party members." % amt)
			else:
				var member := PartyManager.selected_party_member
				if member == null:
					_log_message("Error: No selected party member.")
				else:
					member.take_damage(amt)
					_log_message("Dealt %d damage to %s. HP: %d/%d" % [amt, member.member_name, member.current_hp, member.max_hp])
		"kill":
			var is_all := false
			if not args.is_empty() and args[0].to_lower() == "all":
				is_all = true
			
			if is_all:
				for member in PartyManager.get_active_party():
					member.current_hp = 0
				_log_message("Killed all active party members.")
			else:
				var member := PartyManager.selected_party_member
				if member == null:
					_log_message("Error: No selected party member.")
				else:
					member.current_hp = 0
					_log_message("Killed %s." % member.member_name)
		"status":
			if args.is_empty():
				_log_message("Error: status requires a status name (e.g. status poison)")
				return
			var member := PartyManager.selected_party_member
			if member == null:
				_log_message("Error: No selected party member.")
				return
			var status_name := " ".join(args)
			var status_id := StatusEffects.normalize_id(status_name)
			if status_id == StatusEffects.Effect.NONE or not StatusEffects.DEFINITIONS.has(status_id):
				_log_message("Error: Unknown status '%s'." % status_name)
				return
			member.active_status_effects[status_id] = {
				"remaining_rounds": StatusEffects.duration_rounds(status_id),
				"save_dc": 0,
				"source": "debug",
			}
			if status_id == StatusEffects.Effect.DEAD:
				member.current_hp = 0
			StatCalculator.recalculate(member)
			_log_message("Applied %s to %s." % [StatusEffects.get_label(status_id), member.member_name])
		"additem":
			if args.is_empty():
				_log_message("Error: additem requires an item ID (e.g. additem health_potion)")
				return
			var item_id := args[0]
			var member = PartyManager.selected_party_member
			if member == null:
				_log_message("Error: No selected party member.")
				return
			var instance = LootManager.create_item_instance(item_id)
			if instance == null or instance.item_data == null:
				_log_message("Error: Item database could not find or create item: %s" % item_id)
			else:
				var success = member.add_inventory_item(instance)
				if success:
					_log_message("Added item %s to %s's inventory." % [item_id, member.member_name])
				else:
					_log_message("Failed to add item %s to %s." % [item_id, member.member_name])
		"tp", "teleport":
			if args.size() < 2:
				_log_message("Error: teleport/tp requires x and z coordinates (e.g. tp 4 -2)")
				return
			var x := int(args[0])
			var z := int(args[1])
			var player := _get_player()
			if player == null:
				_log_message("Error: Player actor not found in registered actors.")
				return
			var movement := player.get_node_or_null("GridMovementController") as GridMovementController
			if movement == null:
				_log_message("Error: GridMovementController not found on player.")
				return
			
			MapManager.unregister_actor(movement.grid_pos)
			movement.grid_pos = Vector3i(x, 0, z)
			player.global_position = movement.grid_to_world(movement.grid_pos)
			MapManager.register_actor(movement.grid_pos, player)
			movement.grid_state_changed.emit(movement.grid_pos, movement.facing)
			_log_message("Teleported player to (%d, 0, %d)." % [x, z])
		_:
			_log_message("Unknown command: %s. Type 'help' for options." % cmd)
