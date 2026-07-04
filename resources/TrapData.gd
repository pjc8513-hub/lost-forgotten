class_name trap_data
extends Resource

@export var disarm_rank: int = 0
@export var status_effect: StatusEffects.Effect
@export var dice_rolls: int = 1
@export var dice_sides: int = 4
@export var target_stamina: bool = false

@export_group("Saving Throw")
@export var save_stat: String = "dexterity"
@export var save_dc: int = 12
