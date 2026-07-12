extends Node

signal queue_empty

var queue: Array = []
var is_running := false
var current_command = null

func add_command(cmd):
	#print("[CommandQueue] add_command:", cmd, " actor=", cmd.actor, " running=", is_running, " queued=", queue.size())
	queue.append(cmd)
	_try_run()

func _try_run():
	if is_running or queue.is_empty():
		#print("[CommandQueue] _try_run skipped running=", is_running, " queued=", queue.size())
		return

	is_running = true
	current_command = queue.pop_front()
	var cmd = current_command
	#print("[CommandQueue] executing:", cmd, " actor=", cmd.actor, " remaining_queue=", queue.size())

	cmd.connect("finished", Callable(self, "_on_command_finished"), CONNECT_ONE_SHOT)
	cmd.execute()

func _on_command_finished():
	#print("[CommandQueue] command finished. queued=", queue.size())
	_release_command_refs(current_command)
	is_running = false
	current_command = null

	if queue.is_empty():
		#print("[CommandQueue] queue empty -> emit queue_empty")
		emit_signal("queue_empty")

	_try_run()

func is_busy() -> bool:
	return is_running or not queue.is_empty()

func clear_queue() -> void:
	if current_command != null:
		var finished_callback := Callable(self, "_on_command_finished")
		if current_command.is_connected("finished", finished_callback):
			current_command.disconnect("finished", finished_callback)
		_release_command_refs(current_command)
		current_command = null
	for cmd in queue:
		_release_command_refs(cmd)
	queue.clear()
	is_running = false
	queue_empty.emit()

func _exit_tree() -> void:
	clear_queue()

func _release_command_refs(cmd) -> void:
	if cmd == null:
		return
	for property in cmd.get_property_list():
		var property_name: StringName = property.get("name", &"")
		if property_name == &"actor" or property_name == &"movement":
			cmd.set(property_name, null)
