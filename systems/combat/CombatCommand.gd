class_name CombatCommand
extends RefCounted

const ATTACK := &"attack"
const DEFEND := &"defend"
const CAST := &"cast"
const ITEM := &"item"
const AUTO := &"auto"
const RUN := &"run"

var actor: Resource
var action: StringName
var target: Resource
var target_row: int = -1
var skill: SkillData
var item: ItemInstance

static func create(
	command_actor: Resource,
	command_action: StringName,
	command_target: Resource = null
) -> CombatCommand:
	var command := CombatCommand.new()
	command.actor = command_actor
	command.action = command_action
	command.target = command_target
	return command
