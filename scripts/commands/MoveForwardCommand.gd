extends Command
class_name MoveForwardCommand
var movement: GridMovementController
func execute():
	movement.try_move_forward()
	emit_signal("finished")
