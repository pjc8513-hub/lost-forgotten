# StatusEffects.gd  (Autoload — res://systems/StatusEffects.gd)
# Responsibility: Define every status effect in one place.
# Provides stat_modifier() so StatCalculator can query deltas without
# knowing anything about how effects are applied or removed.
# Never modifies PartyMember directly — that is StatusEffectComponent's job.

extends Node

# ---------------------------------------------------------------------------
# Enum — canonical IDs for every status effect in the game
# ---------------------------------------------------------------------------

enum Effect {
	NONE = 0,
	# Damage-over-time
	POISON,
	BURN,
	BLEED,
	DECAY,          # Wisdom / magic resistance drain
	# Crowd control
	STUN,			# Can't act. Ends at end of turn (or combat)
	SLEEP,			# Can't act. Ends on taking damage (or combat)
	FREEZE,			# Can't act. Chance to roll out every turn (clears after combat)
	PARALYSIS,		# Can't act.
	CONFUSE,		# Can't cast. -Willpower
	# Stat debuffs
	FEAR,			# Lowers initiative and accuracy
	WEAKEN,         # -Strength
	SLOW,           # -Accuracy /-Initiative
	BLIND,          # -Accuracy / -Dexterity
	CURSE,          # -Willpower saves / -Dexterity / Cannot cast
	DISEASED,		# Cannot gain HP from healing or resting
	DEAD,           # Member is dead
	# Positive
	REGENERATE,     # HP per round
	HASTE,          # +initiative, +dexterity
	BLESS,          # +accuracy, +willpower saves
	STONE_SKIN,     # AC bonus ( negative AC system low AC = good )
}

# Canonical lifetime for timed effects. Effects omitted from this table persist
# until explicitly cleared by rest, death, a temple, an item, or a spell.
# A value of -1 from duration_rounds() means indefinite.
const DURATION_ROUNDS: Dictionary = {
	Effect.STUN: 1,
	Effect.POISON: -1,
	Effect.BURN: -1,
	Effect.BLEED: -1,
	Effect.SLEEP: -1,
	Effect.FREEZE: -1,
	Effect.DECAY: -1,
	Effect.PARALYSIS: -1,
	Effect.WEAKEN: -1,
	Effect.FEAR: -1,
	Effect.CONFUSE: -1,
	Effect.BLIND: -1,
	Effect.CURSE: -1,
	Effect.DISEASED: -1,
}

# ---------------------------------------------------------------------------
# Effect definitions
# Each entry:
#   label        — display name
#   description  — tooltip text
#   is_negative  — whether Willpower saves can resist it
#   dot_damage   — HP dealt per round (negative = healing)
#   stat_deltas  — flat modifiers applied to derived stats while active
#   blocks_action — true = character cannot act this round
#	blocks_healing - true = character cannot receive healing
#   blocks_move   — true = character cannot move this round
#	blocks_casting - true = character cannot cast this round
#	end_of_comnbat - true = clears at end of combat
#	clear_on_rest  - true = clears when party rests
#	cost_to_remove - Cost to remove status at temple
# ---------------------------------------------------------------------------

const DEFINITIONS: Dictionary = {
	Effect.POISON: {
		"label": "Poison",
		"description": "Deals damage each round. Willpower may resist.",
		"is_negative": true,
		"dot_damage": 4,
		"stat_deltas": { "endurance": -1 },
		"blocks_action": false,
		"blocks_healing": false,
		"blocks_move": false,
		"blocks_casting": false,
		"end_of_combat": false,
		"clear_on_rest": false,
		"cost_to_remove": 50,
	},
	Effect.BURN: {
		"label": "Burn",
		"description": "Fire damage each round. Reduces armor.",
		"is_negative": true,
		"dot_damage": 5,
		"stat_deltas": { "armor_class": 2 },
		"blocks_action": false,
		"blocks_healing": false,
		"blocks_move": false,
		"blocks_casting": false,
		"end_of_combat": false,
		"clear_on_rest": true,
		"cost_to_remove": 30,
	},
	Effect.BLEED: {
		"label": "Bleed",
		"description": "Physical damage each round. Clears on rest.",
		"is_negative": true,
		"dot_damage": 3,
		"stat_deltas": { "strength": -1 },
		"blocks_action": false,
		"blocks_healing": false,
		"blocks_move": false,
		"blocks_casting": false,
		"end_of_combat": false,
		"clear_on_rest": true,
		"cost_to_remove": 20,
	},
	Effect.DECAY: {
		"label": "Decay",
		"description": "Drains magical power and Wisdom. Blocks healing effects",
		"is_negative": true,
		"dot_damage": 0,
		"stat_deltas": { "wisdom": -5, "magic_amp": -2 },
		"blocks_action": false,
		"blocks_healing": true,
		"blocks_move": false,
		"blocks_casting": false,
		"end_of_combat": false,
		"clear_on_rest": true,
		"cost_to_remove": 60,
	},
	Effect.STUN: {
		"label": "Stun",
		"description": "Cannot act or move this round.",
		"is_negative": true,
		"dot_damage": 0,
		"stat_deltas": { "initiative": -10, "armor_class": 2 },
		"blocks_action": true,
		"blocks_healing": false,
		"blocks_move": true,
		"blocks_casting": true,
		"end_of_combat": true,
		"clear_on_rest": false,
		"cost_to_remove": 0,
	},
	Effect.SLEEP: {
		"label": "Sleep",
		"description": "Cannot act. Breaks on damage.",
		"is_negative": true,
		"dot_damage": 0,
		"stat_deltas": { "initiative": -10, "armor_class": 4 },
		"blocks_action": true,
		"blocks_healing": false,
		"blocks_move": true,
		"blocks_casting": true,
		"end_of_combat": true,
		"clear_on_rest": false,
		"cost_to_remove": 10,
	},
	Effect.PARALYSIS: {
		"label": "Paralysis",
		"description": "Completely immobile.",
		"is_negative": true,
		"dot_damage": 0,
		"stat_deltas": { "initiative": -10, "armor_class": 4, "dexterity": -4 },
		"blocks_action": true,
		"blocks_healing": false,
		"blocks_move": true,
		"blocks_casting": true,
		"end_of_combat": false,
		"clear_on_rest": false,
		"cost_to_remove": 70,
	},
	Effect.FREEZE: {
		"label": "Freeze",
		"description": "Completely immobile. Willpower DC each round to break.",
		"is_negative": true,
		"dot_damage": 0,
		"stat_deltas": { "initiative": -10, "dexterity": -4 },
		"blocks_action": true,
		"blocks_healing": false,
		"blocks_move": true,
		"blocks_casting": true,
		"end_of_combat": true,
		"clear_on_rest": false,
		"cost_to_remove": 50,
	},
	Effect.CONFUSE: {
		"label": "Confuse",
		"description": "Cannot cast spells and willpower penalty.",
		"is_negative": true,
		"dot_damage": 0,
		"stat_deltas": { "willpower": -2 },
		"blocks_action": false,
		"blocks_healing": false,
		"blocks_move": false,
		"blocks_casting": true,
		"end_of_combat": false,
		"clear_on_rest": true,
		"cost_to_remove": 60,
	},
	Effect.FEAR: {
		"label": "Fear",
		"description": "Penalty to initiative and accuracy.",
		"is_negative": true,
		"dot_damage": 0,
		"stat_deltas": { "initiative": -3, "accuracy": -2 },
		"blocks_action": false,
		"blocks_healing": false,
		"blocks_move": false,
		"end_of_combat": true,
		"clear_on_rest": true,
		"cost_to_remove": 40,
	},
	Effect.WEAKEN: {
		"label": "Weakness",
		"description": "Reduced Strength and bonus damage.",
		"is_negative": true,
		"dot_damage": 0,
		"stat_deltas": { "strength": -5, "bonus_damage": -5 },
		"blocks_action": false,
		"blocks_healing": false,
		"blocks_move": false,
		"blocks_casting": false,
		"end_of_combat": false,
		"clear_on_rest": true,
		"cost_to_remove": 20,
	},
	Effect.SLOW: {
		"label": "Slow",
		"description": "Reduced Dexterity and initiative",
		"is_negative": true,
		"dot_damage": 0,
		"stat_deltas": { "dexterity": -5, "initiative": -3 },
		"blocks_action": false,
		"blocks_healing": false,
		"blocks_move": false,
		"blocks_casting": false,
		"end_of_combat": true,
		"clear_on_rest": true,
		"cost_to_remove": 20,
	},
	Effect.BLIND: {
		"label": "Blind",
		"description": "Severe accuracy penalty. -Dexterity.",
		"is_negative": true,
		"dot_damage": 0,
		"stat_deltas": { "accuracy": -5, "dexterity": -2 },
		"blocks_action": false,
		"blocks_healing": false,
		"blocks_move": false,
		"blocks_casting": false,
		"end_of_combat": false,
		"clear_on_rest": false,
		"cost_to_remove": 40,
	},
	Effect.CURSE: {
		"label": "Curse",
		"description": "Weakens Willpower saves against further effects and lowers Dexterity.\nBlocks casting.",
		"is_negative": true,
		"dot_damage": 0,
		"stat_deltas": { "willpower": -3, "dexterity": -2 },
		"blocks_action": false,
		"blocks_healing": false,
		"blocks_move": false,
		"blocks_casting": true,
		"end_of_combat": false,
		"clear_on_rest": false,
		"cost_to_remove": 50,
	},
	Effect.DISEASED: {
		"label": "Diseased",
		"description": "Cannot receive healing. Strength and Willpower penalty",
		"is_negative": true,
		"dot_damage": 0,
		"stat_deltas": { "willpower": -2, "strength": -2, "armor_class": 2 },
		"blocks_action": false,
		"blocks_healing": true,
		"blocks_move": false,
		"blocks_casting": true,
		"end_of_combat": false,
		"clear_on_rest": false,
		"cost_to_remove": 70,
	},
	Effect.DEAD: {
		"label": "Dead",
		"description": "Cannot act",
		"is_negative": true,
		"dot_damage": 0,
		"stat_deltas": {},
		"blocks_action": true,
		"blocks_healing": true,
		"blocks_move": true,
		"blocks_casting": true,
		"end_of_combat": false,
		"clear_on_rest": false,
		"cost_to_remove": 50,
	},
	Effect.REGENERATE: {
		"label": "Regenerate",
		"description": "Recovers HP each round.",
		"is_negative": false,
		"dot_damage": -4,    # Negative = healing
		"stat_deltas": {},
		"blocks_action": false,
		"blocks_healing": false,
		"blocks_move": false,
		"blocks_casting": false,
		"end_of_combat": true,
		"clear_on_rest": false,
		"cost_to_remove": 0,
	},
	Effect.HASTE: {
		"label": "Haste",
		"description": "+Initiative and dexterity",
		"is_negative": false,
		"dot_damage": 0,
		"stat_deltas": { "initiative": 4, "dexterity": 2 },
		"blocks_action": false,
		"blocks_healing": false,
		"blocks_move": false,
		"blocks_casting": false,
		"end_of_combat": true,
		"clear_on_rest": false,
		"cost_to_remove": 0,
	},
	Effect.BLESS: {
		"label": "Bless",
		"description": "+Accuracy and +Willpower saves.",
		"is_negative": false,
		"dot_damage": 0,
		"stat_deltas": { "accuracy": 3, "willpower": 2 },
		"blocks_action": false,
		"blocks_healing": false,
		"blocks_move": false,
		"blocks_casting": false,
		"end_of_combat": true,
		"clear_on_rest": false,
		"cost_to_remove": 0,
	},
	Effect.STONE_SKIN: {
		"label": "Stone Skin",
		"description": "Hardens AC. -2 AC",
		"is_negative": false,
		"dot_damage": 0,
		"stat_deltas": { "armor_class": -2 },
		"blocks_action": false,
		"blocks_healing": false,
		"blocks_move": false,
		"blocks_casting": false,
		"end_of_combat": true,
		"clear_on_rest": false,
		"cost_to_remove": 0,
	},
}

# ---------------------------------------------------------------------------
# Public API — called by StatCalculator and StatusEffectComponent
# ---------------------------------------------------------------------------

## Returns the flat stat delta for one effect on one stat key.
## StatCalculator calls this without knowing any effect internals.
func stat_modifier(effect_id: int, stat: String) -> int:
	var def: Dictionary = DEFINITIONS.get(effect_id, {})
	var deltas: Dictionary = def.get("stat_deltas", {})
	return int(deltas.get(stat, 0))

## Returns DoT damage per round (negative = healing).
func dot_damage(effect_id: int) -> int:
	var def: Dictionary = DEFINITIONS.get(effect_id, {})
	return int(def.get("dot_damage", 0))

## Returns true if this effect prevents the character from acting.
func blocks_action(effect_id: int) -> bool:
	var def: Dictionary = DEFINITIONS.get(effect_id, {})
	return bool(def.get("blocks_action", false))

## Returns true if this effect prevents healing or rest-based HP recovery.
func blocks_healing(effect_id: int) -> bool:
	var def: Dictionary = DEFINITIONS.get(effect_id, {})
	return bool(def.get("blocks_healing", false))

## Returns true if this effect is removed when the party rests.
func clears_on_rest(effect_id: int) -> bool:
	var def: Dictionary = DEFINITIONS.get(effect_id, {})
	return bool(def.get("clear_on_rest", false))

## Returns true if this effect prevents movement.
func blocks_move(effect_id: int) -> bool:
	var def: Dictionary = DEFINITIONS.get(effect_id, {})
	return bool(def.get("blocks_move", false))

## Returns true if Willpower saves can potentially resist or end this effect.
func is_negative(effect_id: int) -> bool:
	var def: Dictionary = DEFINITIONS.get(effect_id, {})
	return bool(def.get("is_negative", false))

## Returns the display label for an effect ID.
func get_label(effect_id: int) -> String:
	var def: Dictionary = DEFINITIONS.get(effect_id, {})
	return str(def.get("label", "Unknown"))

## Converts data-facing names into the canonical Effect enum value.
func normalize_id(effect_name: String) -> int:
	var key := effect_name.strip_edges().to_upper().replace(" ", "_")
	match key:
		"PARALYZE": key = "PARALYSIS"
		"CONFUSION": key = "CONFUSE"
	return int(Effect.get(key, Effect.NONE))

## Returns the canonical lifetime assigned to an effect.
func duration_rounds(effect_id: int) -> int:
	return int(DURATION_ROUNDS.get(effect_id, -1))

## Returns the full definition dict (read-only).
func get_definition(effect_id: int) -> Dictionary:
	return DEFINITIONS.get(effect_id, {})

## Checks whether an effect breaks on damage (e.g. Sleep).
func breaks_on_damage(effect_id: int) -> bool:
	return effect_id == Effect.SLEEP

## Returns all currently defined negative effect IDs.
func all_negative_effects() -> Array[int]:
	var result: Array[int] = []
	for id in DEFINITIONS:
		if DEFINITIONS[id].get("is_negative", false):
			result.append(id)
	return result
