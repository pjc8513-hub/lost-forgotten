extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var host := Control.new()
	host.size = Vector2(1280, 720)
	root.add_child(host)
	var panel := DungeonSynthPanel.new()
	host.add_child(panel)
	await process_frame
	print("Panel layout: visible=%s size=%s children=%d" % [panel.visible, panel.size, panel.get_child_count()])
	for child in panel.get_children():
		if child is Control:
			print("  %s size=%s visible=%s" % [child.get_class(), child.size, child.visible])
	assert(panel.size.x >= 1200 and panel.size.y >= 700, "Panel should fill its editor host")
	assert(panel.size_flags_vertical == Control.SIZE_EXPAND_FILL, "Panel must request vertical editor space")
	assert(panel.get_child_count() >= 3, "Panel should build its complete UI")
	quit(0)
