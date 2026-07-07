extends CharacterBody3D

@onready var movement: GridMovementController = $GridMovementController

func rotate_left() -> void:
	movement.rotate_left()

func rotate_right() -> void:
	movement.rotate_right()
	
func turn_around() -> void:
	movement.turn_around()
