extends Control
@onready var portrait: TextureRect = $PanelContainer/VBoxContainer/MarginContainer/HBoxContainer/PortraitContainer/Portrait
@onready var name_edit: LineEdit = $PanelContainer/VBoxContainer/MarginContainer/HBoxContainer/PanelContainer2/VBoxContainer/NameEdit
@onready var race_select: OptionButton = $PanelContainer/VBoxContainer/MarginContainer/HBoxContainer/PanelContainer2/VBoxContainer/RaceSelect
@onready var class_select: OptionButton = $PanelContainer/VBoxContainer/MarginContainer/HBoxContainer/PanelContainer2/VBoxContainer/ClassSelect
@onready var endurance_label: Label = $PanelContainer/VBoxContainer/Container/HBoxContainer/StatsContainer/EnduranceLabel
@onready var wisdom_label: Label = $PanelContainer/VBoxContainer/Container/HBoxContainer/StatsContainer/WisdomLabel
@onready var dexterity_label: Label = $PanelContainer/VBoxContainer/Container/HBoxContainer/StatsContainer/DexterityLabel
@onready var piety_label: Label = $PanelContainer/VBoxContainer/Container/HBoxContainer/StatsContainer/PietyLabel
@onready var willpower: Label = $PanelContainer/VBoxContainer/Container/HBoxContainer/StatsContainer/Willpower
@onready var strength_label: Label = $PanelContainer/VBoxContainer/Container/HBoxContainer/StatsContainer/StrengthLabel
@onready var race_skills: Label = $PanelContainer/VBoxContainer/Container/HBoxContainer/SkillContainer/RaceSkills
@onready var class_skills: Label = $PanelContainer/VBoxContainer/Container/HBoxContainer/SkillContainer/ClassSkills

@onready var reroll_button: Button = $PanelContainer/VBoxContainer/Container/HBoxContainer/OptionsContainer/RerollButton
@onready var accept_button: Button = $PanelContainer/VBoxContainer/Container/HBoxContainer/OptionsContainer/AcceptButton
@onready var return_button: Button = $PanelContainer/VBoxContainer/Container/HBoxContainer/OptionsContainer/ReturnButton
