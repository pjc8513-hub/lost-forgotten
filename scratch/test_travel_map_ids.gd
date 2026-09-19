extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var menu = load("res://scenes/ui/travel_menu.gd").new()
	var expected := {
		"res://scenes/maps/nobel/nobel.tscn": &"Nobel",
		"res://scenes/maps/farms/farms.tscn": &"farm",
		"res://scenes/maps/farms/thieves.tscn": &"thieveshq",
		"res://scenes/maps/forest/forest.tscn": &"forest",
		"res://scenes/maps/forest/fairy/fairyland.tscn": &"fairyland",
	}
	for iteration in range(3):
		for map_path in expected:
			assert(menu._get_map_id(map_path) == expected[map_path], map_path)
		await process_frame
	var no_id_path := "res://scenes/grid/castle/stone_wall_3_door.tscn"
	assert(menu._get_map_id(no_id_path) == StringName(no_id_path))
	menu.free()
	await process_frame
	print("PASS: repeated travel map ID lookups and missing-ID fallback")
	quit()
