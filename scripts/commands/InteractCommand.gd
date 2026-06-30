class_name InteractCommand
extends Command

var movement: GridMovementController

func execute() -> void:
	movement.interact_forward()
	finished.emit()
