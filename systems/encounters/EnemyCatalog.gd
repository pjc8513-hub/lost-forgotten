class_name EnemyCatalog
extends RefCounted

const ENEMY_DIRECTORY := "res://data/enemies"
var _entries: Dictionary[StringName, EnemyData] = {}

func _init() -> void:
	reload()

func reload() -> void:
	_entries.clear()
	var directory := DirAccess.open(ENEMY_DIRECTORY)
	if directory == null:
		push_error("Enemy directory is missing: %s" % ENEMY_DIRECTORY)
		return
	for file_name in directory.get_files():
		if file_name.get_extension() != "tres":
			continue
		var data := load(ENEMY_DIRECTORY.path_join(file_name)) as EnemyData
		if data == null or data.enemy_id.is_empty():
			push_warning("Ignoring invalid enemy resource: %s" % file_name)
			continue
		if _entries.has(data.enemy_id):
			push_error("Duplicate enemy id: %s" % data.enemy_id)
			continue
		_entries[data.enemy_id] = data

func get_enemy(enemy_id: StringName) -> EnemyData:
	return _entries.get(enemy_id) as EnemyData
