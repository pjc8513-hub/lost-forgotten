extends Node

signal threat_changed(value: float)
signal encounter_requested(encounter: CombatEncounter)

var _meter := ThreatMeter.new()
var _catalog: EnemyCatalog
var _generator: EncounterGenerator
var _map_data: MapData
var _encounter_active := false

func _ready() -> void:
	_catalog = EnemyCatalog.new()
	_generator = EncounterGenerator.new(_catalog)

func configure_map(map_data: MapData) -> void:
	_map_data = map_data
	_encounter_active = false
	reset_threat()

func on_party_step() -> void:
	if not _is_enabled():
		return
	if _meter.roll():
		var encounter := _generator.generate(_map_data)
		if encounter != null:
			_encounter_active = true
			encounter_requested.emit(encounter)
			return
	add_threat(_map_data.threat_per_step)

func add_search_threat() -> void:
	if _is_enabled():
		add_threat(_map_data.search_threat)

func add_door_threat() -> void:
	if _is_enabled():
		add_threat(_map_data.door_threat)

func add_threat(amount: float) -> void:
	_meter.add(amount)
	threat_changed.emit(_meter.value)

func complete_encounter() -> void:
	_encounter_active = false
	reset_threat()

func reset_threat() -> void:
	_meter.reset()
	threat_changed.emit(_meter.value)

func get_threat() -> float:
	return _meter.value

func _is_enabled() -> bool:
	return not _encounter_active and _map_data != null and _map_data.encounters_enabled
