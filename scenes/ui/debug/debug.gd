extends Control

@onready var messages: RichTextLabel = $PanelContainer/ScrollContainer/Messages

const STAT_FIELDS: Array[Dictionary] = [
	{"label": "Strength", "rolled": &"rolled_strength", "class": &"base_strength", "race": &"bonus_strength"},
	{"label": "Endurance", "rolled": &"rolled_endurance", "class": &"base_endurance", "race": &"bonus_endurance"},
	{"label": "Wisdom", "rolled": &"rolled_wisdom", "class": &"base_wisdom", "race": &"bonus_wisdom"},
	{"label": "Dexterity", "rolled": &"rolled_dexterity", "class": &"base_dexterity", "race": &"bonus_dexterity"},
	{"label": "Piety", "rolled": &"rolled_piety", "class": &"base_piety", "race": &"bonus_piety"},
	{"label": "Willpower", "rolled": &"rolled_willpower", "class": &"base_willpower", "race": &"bonus_willpower"},
]

func _ready() -> void:
	PartyManager.selected_party_member_changed.connect(_on_selected_party_member_changed)
	visibility_changed.connect(_on_visibility_changed)
	_refresh(PartyManager.selected_party_member)

func _on_selected_party_member_changed(_index: int, member: PartyMember) -> void:
	_refresh(member)

func _on_visibility_changed() -> void:
	if visible:
		_refresh(PartyManager.selected_party_member)

func _refresh(member: PartyMember) -> void:
	if not is_node_ready():
		return
	if member == null:
		messages.text = "No party member selected."
		return

	var class_data := member.class_data
	var race_data := member.race_data
	var lines: Array[String] = [
		"Selected Character",
		"Name: %s" % member.member_name,
		"Row: %s (%d)" % [member.get_row_display_name(), member.row],
		"Class: %s" % _class_name(class_data),
		"Class resource: %s" % (class_data.resource_path if class_data != null else "<null>"),
		"Race: %s" % member.get_race_display_name(),
		"Race resource: %s" % (race_data.resource_path if race_data != null else "<null>"),
		"Race display_name: %s" % (race_data.display_name if race_data != null else "<null>"),
		"",
		"Rolled / Class / Race / Total",
	]

	for fields in STAT_FIELDS:
		var rolled := int(member.get(fields.rolled))
		var class_bonus := int(class_data.get(fields["class"])) if class_data != null else 0
		var race_bonus := int(race_data.get(fields.race)) if race_data != null else 0
		lines.append("%s: %d + %d + %d = %d" % [fields.label, rolled, class_bonus, race_bonus, _calculated_stat(member, fields.label)])

	lines.append("")
	lines.append("Class starting skills: %s" % _format_skills(class_data.starting_skills if class_data != null else []))
	lines.append("Race starting skills: %s" % _format_skills(race_data.starting_skills if race_data != null else []))
	lines.append("Learned skills: %s" % _format_learned_skills(member.learned_skills))
	messages.text = "\n".join(lines)

func _class_name(class_data: ClassData) -> String:
	if class_data == null:
		return "Unknown"
	return ClassData.get_display_name_for(class_data.class_id)

func _calculated_stat(member: PartyMember, stat_label: String) -> int:
	match stat_label:
		"Strength": return StatCalculator.get_strength(member)
		"Endurance": return StatCalculator.get_endurance(member)
		"Wisdom": return StatCalculator.get_wisdom(member)
		"Dexterity": return StatCalculator.get_dexterity(member)
		"Piety": return StatCalculator.get_piety(member)
		"Willpower": return StatCalculator.get_willpower(member)
	return 0

func _format_skills(skill_ids: Array) -> String:
	if skill_ids.is_empty():
		return "None"
	var names: Array[String] = []
	for skill_id in skill_ids:
		var skill := SkillSystem.get_skill(StringName(skill_id))
		names.append(skill.display_name if skill != null else String(skill_id).capitalize())
	return ", ".join(names)

func _format_learned_skills(learned_skills: Dictionary) -> String:
	if learned_skills.is_empty():
		return "None"
	var entries: Array[String] = []
	for skill_id in learned_skills:
		var skill := SkillSystem.get_skill(StringName(skill_id))
		var skill_name: String = skill.display_name if skill != null else String(skill_id).capitalize()
		entries.append("%s (rank %d)" % [skill_name, int(learned_skills[skill_id])])
	entries.sort()
	return ", ".join(entries)
