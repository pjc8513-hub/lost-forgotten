# StatusEffects.gd  (Autoload — res://systems/StatusEffects.gd)
# Responsibility: Define every status effect in one place.
# Provides stat_modifier() so StatCalculator can query deltas without
# knowing anything about how effects are applied or removed.
# Never modifies CharacterState directly — that is StatusEffectComponent's job.

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
	STUN,
	SLEEP,
	PARALYSIS,
	CONFUSE,
	FEAR,
	# Stat debuffs
	WEAKEN,         # -Strength
	SLOW,           # -Dexterity / movement
	BLIND,          # -Accuracy / -Dexterity
	CURSE,          # -Willpower saves
	# Positive
	REGENERATE,     # HP per round
	HASTE,          # +initiative, +movement
	BLESS,          # +accuracy, +willpower saves
	STONE_SKIN,     # -AC (old-school: lower is better)
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
#   blocks_move   — true = character cannot move this round
# ---------------------------------------------------------------------------

const DEFINITIONS: Dictionary = {
	Effect.POISON: {
		"label": "Poison",
		"description": "Deals damage each round. Willpower may resist.",
		"is_negative": true,
		"dot_damage": 4,
		"stat_deltas": { "endurance": -1 },
		"blocks_action": false,
		"blocks_move": false,
	},
	Effect.BURN: {
		"label": "Burn",
		"description": "Fire damage each round. Reduces armor.",
		"is_negative": true,
		"dot_damage": 5,
		"stat_deltas": { "armor_class": 2 },  # +2 AC = worse in descending AC
		"blocks_action": false,
		"blocks_move": false,
	},
	Effect.BLEED: {
		"label": "Bleed",
		"description": "Physical damage each round. Clears on rest.",
		"is_negative": true,
		"dot_damage": 3,
		"stat_deltas": { "strength": -1 },
		"blocks_action": false,
		"blocks_move": false,
	},
	Effect.DECAY: {
		"label": "Decay",
		"description": "Drains magical resistance and Wisdom.",
		"is_negative": true,
		"dot_damage": 0,
		"stat_deltas": { "wisdom": -2, "magic_amp": -2 },
		"blocks_action": false,
		"blocks_move": false,
	},
	Effect.STUN: {
		"label": "Stun",
		"description": "Cannot act or move this round.",
		"is_negative": true,
		"dot_damage": 0,
		"stat_deltas": { "initiative": -10, "armor_class": 2 },
		"blocks_action": true,
		"blocks_move": true,
	},
	Effect.SLEEP: {
		"label": "Sleep",
		"description": "Cannot act. Breaks on damage.",
		"is_negative": true,
		"dot_damage": 0,
		"stat_deltas": { "initiative": -10, "armor_class": 4 },
		"blocks_action": true,
		"blocks_move": true,
	},
	Effect.PARALYSIS: {
		"label": "Paralysis",
		"description": "Completely immobile. Willpower save each round to break.",
		"is_negative": true,
		"dot_damage": 0,
		"stat_deltas": { "initiative": -10, "armor_class": 4, "dexterity": -4 },
		"blocks_action": true,
		"blocks_move": true,
	},
	Effect.CONFUSE: {
		"label": "Confuse",
		"description": "Actions may target random party members.",
		"is_negative": true,
		"dot_damage": 0,
		"stat_deltas": { "accuracy": -3 },
		"blocks_action": false,
		"blocks_move": false,
	},
	Effect.FEAR: {
		"label": "Fear",
		"description": "May flee instead of acting. -Initiative.",
		"is_negative": true,
		"dot_damage": 0,
		"stat_deltas": { "initiative": -3, "accuracy": -2 },
		"blocks_action": false,
		"blocks_move": false,
	},
	Effect.WEAKEN: {
		"label": "Weaken",
		"description": "Reduced Strength and bonus damage.",
		"is_negative": true,
		"dot_damage": 0,
		"stat_deltas": { "strength": -3, "bonus_damage": -2 },
		"blocks_action": false,
		"blocks_move": false,
	},
	Effect.SLOW: {
		"label": "Slow",
		"description": "Reduced Dexterity, initiative, and movement.",
		"is_negative": true,
		"dot_damage": 0,
		"stat_deltas": { "dexterity": -3, "initiative": -3, "movement": -1 },
		"blocks_action": false,
		"blocks_move": false,
	},
	Effect.BLIND: {
		"label": "Blind",
		"description": "Severe accuracy penalty. -Dexterity.",
		"is_negative": true,
		"dot_damage": 0,
		"stat_deltas": { "accuracy": -5, "dexterity": -2 },
		"blocks_action": false,
		"blocks_move": false,
	},
	Effect.CURSE: {
		"label": "Curse",
		"description": "Weakens Willpower saves against further effects.",
		"is_negative": true,
		"dot_damage": 0,
		"stat_deltas": { "willpower": -3 },
		"blocks_action": false,
		"blocks_move": false,
	},
	Effect.REGENERATE: {
		"label": "Regenerate",
		"description": "Recovers HP each round.",
		"is_negative": false,
		"dot_damage": -4,    # Negative = healing
		"stat_deltas": {},
		"blocks_action": false,
		"blocks_move": false,
	},
	Effect.HASTE: {
		"label": "Haste",
		"description": "+Initiative and +Movement.",
		"is_negative": false,
		"dot_damage": 0,
		"stat_deltas": { "initiative": 4, "movement": 1, "dexterity": 2 },
		"blocks_action": false,
		"blocks_move": false,
	},
	Effect.BLESS: {
		"label": "Bless",
		"description": "+Accuracy and +Willpower saves.",
		"is_negative": false,
		"dot_damage": 0,
		"stat_deltas": { "accuracy": 3, "willpower": 2 },
		"blocks_action": false,
		"blocks_move": false,
	},
	Effect.STONE_SKIN: {
		"label": "Stone Skin",
		"description": "Hardens AC. -2 AC (descending: lower is better).",
		"is_negative": false,
		"dot_damage": 0,
		"stat_deltas": { "armor_class": -2 },
		"blocks_action": false,
		"blocks_move": false,
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
