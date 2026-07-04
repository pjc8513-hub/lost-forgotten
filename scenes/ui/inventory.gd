extends Control


@onready var next_button: Button = $MarginContainer/PanelContainer/VBoxContainer/MarginContainer2/HBoxContainer/options/MarginContainer/VBoxContainer/NextButton
@onready var previous_button: Button = $MarginContainer/PanelContainer/VBoxContainer/MarginContainer2/HBoxContainer/options/MarginContainer/VBoxContainer/PreviousButton
@onready var close_button: Button = $MarginContainer/PanelContainer/VBoxContainer/MarginContainer2/HBoxContainer/options/MarginContainer/VBoxContainer/CloseButton
@onready var strength_label: Label = $MarginContainer/PanelContainer/VBoxContainer/MarginContainer2/HBoxContainer/StatsPanel/MarginContainer/StatsContainer/StrengthLabel
@onready var endurance_label: Label = $MarginContainer/PanelContainer/VBoxContainer/MarginContainer2/HBoxContainer/StatsPanel/MarginContainer/StatsContainer/EnduranceLabel
@onready var wisdom_label: Label = $MarginContainer/PanelContainer/VBoxContainer/MarginContainer2/HBoxContainer/StatsPanel/MarginContainer/StatsContainer/WisdomLabel
@onready var dexterity_label: Label = $MarginContainer/PanelContainer/VBoxContainer/MarginContainer2/HBoxContainer/StatsPanel/MarginContainer/StatsContainer/DexterityLabel
@onready var piety_label: Label = $MarginContainer/PanelContainer/VBoxContainer/MarginContainer2/HBoxContainer/StatsPanel/MarginContainer/StatsContainer/PietyLabel
@onready var willpower: Label = $MarginContainer/PanelContainer/VBoxContainer/MarginContainer2/HBoxContainer/StatsPanel/MarginContainer/StatsContainer/Willpower
@onready var description_label: Label = $MarginContainer/PanelContainer/VBoxContainer/MarginContainer2/HBoxContainer/PanelContainer/MarginContainer/VBoxContainer/DescriptionLabel
@onready var character_name: Label = $MarginContainer/PanelContainer/VBoxContainer/CharacterName
