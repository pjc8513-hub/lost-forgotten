extends Command
class_name TurnRightCommand

func execute():
	actor.rotate_right()
	emit_signal("finished")
