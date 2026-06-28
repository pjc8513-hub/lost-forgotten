extends Node

signal queue_empty

var queue: Array = []
var is_running := false
var current_command: Command = null

func add_command(cmd):
	print("[CommandQueue] add_command:", cmd, " actor=", cmd.actor, " running=", is_running, " queued=", queue.size())
	queue.append(cmd)
	_try_run()

func _try_run():
	if is_running or queue.is_empty():
		print("[CommandQueue] _try_run skipped running=", is_running, " queued=", queue.size())
		return

	is_running = true
	current_command = queue.pop_front()
	var cmd = current_command
	print("[CommandQueue] executing:", cmd, " actor=", cmd.actor, " remaining_queue=", queue.size())

	cmd.connect("finished", Callable(self, "_on_command_finished"), CONNECT_ONE_SHOT)
	cmd.execute()

func _on_command_finished():
	print("[CommandQueue] command finished. queued=", queue.size())
	is_running = false
	current_command = null

	if queue.is_empty():
		print("[CommandQueue] queue empty -> emit queue_empty")
		emit_signal("queue_empty")

	_try_run()

func is_busy() -> bool:
	return is_running or not queue.is_empty()
