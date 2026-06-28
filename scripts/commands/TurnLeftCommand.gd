extends Command
class_name TurnLeftCommand

func execute():
	actor.rotate_left()
	emit_signal("finished")
