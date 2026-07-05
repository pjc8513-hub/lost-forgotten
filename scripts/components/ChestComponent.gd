class_name ChestComponent
extends Node

signal opened(actor: Node)
signal loot_requested(chest: ChestComponent, loot: Dictionary)

@export var chest_ID: StringName

@export var gold_roll_dice: int = 1
@export var gold_roll_sides: int = 20
@export var loot_table: LootManager.Loot_Table = LootManager.Loot_Table.EQUIP_1
@export var is_trapped: bool =  false
@export var trap_type: trap_data
@export var dc_rank: int = 0
@export var is_empty: bool = false
@export var trigger_encounter = false
@export var monster_id: Array[StringName] = []

var is_open: bool = false
var _trap: TrapComponent

func _ready() -> void:
	MapManager.register_chest(self)
	var interactable := get_parent().get_node_or_null("InteractableComponent") as InteractableComponent
	if interactable == null:
		push_warning("ChestComponent requires an InteractableComponent sibling.")
	else:
		interactable.interacted.connect(_on_interacted)

	if is_trapped:
		_trap = TrapComponent.new()
		_trap.name = "TrapComponent"
		_trap.trap_id = StringName("%s.trap" % chest_ID) if not chest_ID.is_empty() else &""
		_trap.trigger_on_step = false
		_trap.trap_type = trap_type
		var chest_mesh := get_parent().get_node_or_null("chest")
		if chest_mesh != null:
			chest_mesh.add_child(_trap)
		else:
			add_child(_trap)

func _exit_tree() -> void:
	MapManager.unregister_chest(self)

func _on_interacted(actor: Node) -> void:
	open(actor)

func open(actor: Node) -> bool:
	if is_open:
		return false

	if _trap != null and not _trap.disarmed:
		_trap.trigger(actor)

	is_open = true
	var animation_player := get_parent().get_node_or_null("AnimationPlayer") as AnimationPlayer
	if animation_player != null and animation_player.has_animation(&"open"):
		animation_player.play(&"open")

	opened.emit(actor)
	_distribute_loot()
	MapManager.set_chest_state(chest_ID, is_open, is_empty)
	return true

func apply_state(state: Dictionary, instant := false) -> void:
	is_open = bool(state.get("is_open", false))
	is_empty = bool(state.get("is_empty", false))
	if instant:
		call_deferred("_sync_visual")

func _sync_visual() -> void:
	if not is_open:
		return
	var animation_player := get_parent().get_node_or_null("AnimationPlayer") as AnimationPlayer
	if animation_player != null and animation_player.has_animation(&"open"):
		animation_player.play(&"open")
		animation_player.seek(animation_player.get_animation(&"open").length, true)
		animation_player.pause()

func _distribute_loot() -> void:
	if is_empty:
		MapManager.request_alert("The chest is empty")
		return

	var gold := 0
	if gold_roll_dice > 0 and gold_roll_sides > 0:
		gold = DiceRoller.roll(gold_roll_dice, gold_roll_sides).total
	var tables: Array[LootManager.Loot_Table] = [loot_table]
	var generated_items := LootManager.generate_loot(tables)
	var loot := {
		"chest_id": chest_ID,
		"gold": gold,
		"loot_table": loot_table,
		"items": generated_items,
	}
	is_empty = true
	var received_items := LootDistributor.distribute(loot, PartyManager.selected_party_member)
	loot_requested.emit(self, loot)
	_show_loot_message(gold, received_items)

func _show_loot_message(gold: int, items: Array[ItemInstance]) -> void:
	var rewards: Array[String] = []
	if gold > 0:
		rewards.append("%d gold" % gold)
	for item in items:
		rewards.append(item.get_display_name())
	MapManager.request_alert("The chest was empty" if rewards.is_empty() else "Found %s" % ", ".join(rewards))
