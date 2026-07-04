class_name ChestComponent
extends Node

@export var chest_ID: StringName

@export var gold_roll_dice: int = 1
@export var gold_roll_sides: int = 20
@export var loot_table: String
@export var is_trapped: bool =  false
@export var trap_type: trap_data
@export var dc_rank: int = 0
@export var is_empty: bool = false
@export var trigger_encounter = false
@export var monster_id: Array[StringName] = []
