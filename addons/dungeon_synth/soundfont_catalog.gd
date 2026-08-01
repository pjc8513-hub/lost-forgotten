@tool
class_name DungeonSoundFontCatalog
extends RefCounted

static func read_presets(path: String) -> Array[Dictionary]:
	var presets: Array[Dictionary] = []
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return presets
	file.big_endian = false
	if _read_id(file) != "RIFF":
		return presets
	file.get_32()
	if _read_id(file) != "sfbk":
		return presets
	while file.get_position() + 8 <= file.get_length():
		var chunk_id := _read_id(file)
		var chunk_size := file.get_32()
		var chunk_start := file.get_position()
		if chunk_id == "LIST" and chunk_size >= 4:
			var list_type := _read_id(file)
			if list_type == "pdta":
				_read_pdta(file, chunk_start + chunk_size, presets)
		file.seek(chunk_start + chunk_size + (chunk_size % 2))
	return presets


static func _read_pdta(file: FileAccess, list_end: int, presets: Array[Dictionary]) -> void:
	while file.get_position() + 8 <= list_end:
		var chunk_id := _read_id(file)
		var chunk_size := file.get_32()
		var chunk_start := file.get_position()
		if chunk_id == "phdr":
			var record_count := chunk_size / 38
			for index in range(maxi(record_count - 1, 0)):
				var name := file.get_buffer(20).get_string_from_ascii()
				var program := file.get_16()
				var bank := file.get_16()
				file.seek(file.get_position() + 14)
				presets.append({"name": name, "program": program, "bank": bank})
			return
		file.seek(chunk_start + chunk_size + (chunk_size % 2))


static func _read_id(file: FileAccess) -> String:
	return file.get_buffer(4).get_string_from_ascii()
