extends Command
class_name TurnAroundCommand

func execute():
	actor.turn_around()
	emit_signal("finished")
