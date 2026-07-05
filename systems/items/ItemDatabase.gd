class_name ItemDatabase
extends RefCounted

static var _items: Dictionary = {}
static var _loaded: bool = false
const ITEM_ROOT := "res://data/items/"

# Public API to get an item by its ID
static func get_item(item_id: String) -> ItemData:
	if not _loaded:
		_load_items()
	
	if item_id == "":
		return null
		
	# Try direct match
	if _items.has(item_id):
		return _items[item_id]
	
	# Try lowercase
	var lower_id = item_id.to_lower()
	if _items.has(lower_id):
		return _items[lower_id]
		
	# Try snake_case
	var snake_id = item_id.to_snake_case()
	if _items.has(snake_id):
		return _items[snake_id]
		
	push_warning("ItemDatabase: Item not found: '%s'" % item_id)
	return null

# Scans the directory and loads every ItemData resource into memory
static func _load_items() -> void:
	_loaded = true
	_items.clear()
	
	if not DirAccess.dir_exists_absolute(ITEM_ROOT):
		push_error("ItemDatabase: Directory not found at %s" % ITEM_ROOT)
		return

	var loaded_count := _load_items_from_directory(ITEM_ROOT)
	print("ItemDatabase: Successfully loaded %d item resources from %s." % [loaded_count, ITEM_ROOT])


static func _load_items_from_directory(dir_path: String) -> int:
	var dir = DirAccess.open(dir_path)
	if dir == null:
		push_error("ItemDatabase: Failed to open directory at %s" % dir_path)
		return 0

	var loaded_count := 0
	dir.list_dir_begin()
	var file_name = dir.get_next()

	while file_name != "":
		var full_path = dir_path.path_join(file_name)

		if dir.current_is_dir():
			loaded_count += _load_items_from_directory(full_path)
		elif file_name.ends_with(".tres"):
			var resource = ResourceLoader.load(full_path)
			if resource is ItemData:
				_register_item(resource, file_name)
				loaded_count += 1

		file_name = dir.get_next()

	dir.list_dir_end()
	return loaded_count


static func _register_item(resource: ItemData, file_name: String) -> void:
	var id = resource.item_id
	if id == "":
		# Fallback to filename without extension
		id = file_name.get_basename()

	# Register using various forms for bulletproof matching
	_items[id] = resource
	_items[id.to_lower()] = resource
	_items[id.to_snake_case()] = resource

	var file_basename = file_name.get_basename()
	_items[file_basename] = resource
	_items[file_basename.to_lower()] = resource
	_items[file_basename.to_snake_case()] = resource
