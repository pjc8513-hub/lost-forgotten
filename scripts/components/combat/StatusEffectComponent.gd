# StatusEffectComponent.gd  (components/combat/status_effect_component.gd)
# Responsibility: Apply, tick, and clear status effects on one combat actor.
# Reads effect definitions from the StatusEffects autoload.
# Emits signals so UI and audio can react — never touches them directly.
# One instance lives on each PartyMember node.

class_name StatusEffectComponent
extends Node

# ---------------------------------------------------------------------------
# Signals
# ---------------------------------------------------------------------------

signal effect_applied(effect_id: int, data: Dictionary)
signal effect_cleared(effect_id: int)
signal effect_ticked(effect_id: int, damage_dealt: int)
signal all_effects_cleared

# ---------------------------------------------------------------------------
# References
# ---------------------------------------------------------------------------

@export var character_state: Resource

# ---------------------------------------------------------------------------
# Internal state structure stored in PartyMember.active_status_effects:
#   { effect_id: int: {
#       "remaining_rounds": int,
#       "save_dc": int,        # DC for Willpower save each round
#       "source": String,      # Who/what applied it (for UI tooltip)
#   } }
# We write to PartyMember so it persists with the save resource.
# ---------------------------------------------------------------------------

# ---------------------------------------------------------------------------
# Apply
# ---------------------------------------------------------------------------

## Apply an effect to this character.
## If the effect is already active, refreshes duration (does not stack).
func apply_effect(effect_id: int, save_dc: int = 0, source: String = "") -> void:
	if character_state == null:
		push_error("StatusEffectComponent: character_state not set on " + name)
		return

	if not StatusEffects.DEFINITIONS.has(effect_id):
		push_warning("StatusEffectComponent: unknown effect_id %d" % effect_id)
		return

	var entry := {
		"remaining_rounds": StatusEffects.duration_rounds(effect_id),
		"save_dc": save_dc,
		"source": source,
	}
	character_state.active_status_effects[effect_id] = entry
	effect_applied.emit(effect_id, entry)
	_recalculate_if_party_member()

# ---------------------------------------------------------------------------
# Tick — call once per combat round for this character
# ---------------------------------------------------------------------------

## Process one round of all active effects.
## Returns total DoT damage dealt this round (for combat log).
func tick_effects() -> int:
	if character_state == null:
		return 0

	var total_dot := 0
	var to_clear: Array[int] = []

	for effect_id in character_state.active_status_effects.keys():
		var entry: Dictionary = character_state.active_status_effects[effect_id]

		# --- DoT / HoT ---
		var dot := StatusEffects.dot_damage(effect_id)
		if dot != 0:
			if dot > 0:
				# Damage — respect resistance (future: pass through HealthComponent)
				character_state.take_damage(dot, &"dot")
				total_dot += dot
			else:
				# Healing
				character_state.heal(-dot)
			effect_ticked.emit(effect_id, dot)

		# --- Willpower save to shake negative effects ---
		if StatusEffects.can_be_shaken_off(effect_id) and entry.get("save_dc", 0) > 0:
			var wp := CombatStats.ability_modifier(_get_willpower())
			var roll := DiceRoller.d20(wp).total
			if roll >= entry["save_dc"]:
				to_clear.append(effect_id)
				continue

		# --- Countdown (negative means persistent until explicitly cleared) ---
		var remaining_rounds := int(entry.get("remaining_rounds", -1))
		if remaining_rounds > 0:
			remaining_rounds -= 1
			entry["remaining_rounds"] = remaining_rounds
			if remaining_rounds == 0:
				to_clear.append(effect_id)

	for effect_id in to_clear:
		clear_effect(effect_id)

	return total_dot

# ---------------------------------------------------------------------------
# Clear
# ---------------------------------------------------------------------------

## Remove one specific effect.
func clear_effect(effect_id: int) -> void:
	if character_state == null:
		return
	if character_state.active_status_effects.erase(effect_id):
		effect_cleared.emit(effect_id)
		_recalculate_if_party_member()

## Remove all effects matching a condition string.
## Condition options: "all", "negative", "positive", "dot", "cc"
func clear_by_condition(condition: String) -> void:
	if character_state == null:
		return
	var to_clear: Array[int] = []

	for effect_id in character_state.active_status_effects.keys():
		var should_clear := false
		match condition:
			"all":
				should_clear = true
			"negative":
				should_clear = StatusEffects.is_negative(effect_id)
			"positive":
				should_clear = not StatusEffects.is_negative(effect_id)
			"dot":
				should_clear = StatusEffects.dot_damage(effect_id) > 0
			"cc":
				should_clear = StatusEffects.blocks_action(effect_id) \
							or StatusEffects.blocks_move(effect_id)

		if should_clear:
			to_clear.append(effect_id)

	for effect_id in to_clear:
		clear_effect(effect_id)

	if to_clear.size() > 0:
		all_effects_cleared.emit()

## Remove all effects — used on rest, death, or dungeon exit.
func clear_all() -> void:
	clear_by_condition("all")

# ---------------------------------------------------------------------------
# Queries — used by combat system and UI
# ---------------------------------------------------------------------------

## Returns true if the character currently has this effect.
func has_effect(effect_id: int) -> bool:
	if character_state == null:
		return false
	return character_state.active_status_effects.has(effect_id)

## Returns remaining rounds for an effect, or 0 if not active.
func get_remaining_rounds(effect_id: int) -> int:
	if character_state == null:
		return 0
	var entry: Dictionary = character_state.active_status_effects.get(effect_id, {})
	return int(entry.get("remaining_rounds", 0))

## Returns true if this character can act this round.
func can_act() -> bool:
	if character_state == null:
		return true
	for effect_id in character_state.active_status_effects.keys():
		if StatusEffects.blocks_action(effect_id):
			return false
	return true

## Returns true if this character can move this round.
func can_move() -> bool:
	if character_state == null:
		return true
	for effect_id in character_state.active_status_effects.keys():
		if StatusEffects.blocks_move(effect_id):
			return false
	return true

## Called by HealthComponent when damage is taken — breaks Sleep etc.
func on_damaged() -> void:
	for effect_id in character_state.active_status_effects.keys():
		if StatusEffects.breaks_on_damage(effect_id):
			clear_effect(effect_id)

## Returns a display-ready list of active effect labels.
func get_active_labels() -> Array[String]:
	var labels: Array[String] = []
	if character_state == null:
		return labels
	for effect_id in character_state.active_status_effects.keys():
		labels.append(StatusEffects.get_label(effect_id))
	return labels

# ---------------------------------------------------------------------------
# Private
# ---------------------------------------------------------------------------

func _get_willpower() -> int:
	return CombatStats.willpower(character_state)

func _recalculate_if_party_member() -> void:
	if character_state is PartyMember:
		StatCalculator.recalculate(character_state)
