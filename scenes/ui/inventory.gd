extends Control

# options
@onready var next_button: Button = $MarginContainer/PanelContainer/VBoxContainer/MarginContainer2/HBoxContainer/options/MarginContainer/VBoxContainer/NextButton
@onready var previous_button: Button = $MarginContainer/PanelContainer/VBoxContainer/MarginContainer2/HBoxContainer/options/MarginContainer/VBoxContainer/PreviousButton
@onready var close_button: Button = $MarginContainer/PanelContainer/VBoxContainer/MarginContainer2/HBoxContainer/options/MarginContainer/VBoxContainer/CloseButton

# Character info and stats
@onready var strength_label: Label = $MarginContainer/PanelContainer/VBoxContainer/MarginContainer2/HBoxContainer/StatsPanel/MarginContainer/StatsContainer/StrengthLabel
@onready var endurance_label: Label = $MarginContainer/PanelContainer/VBoxContainer/MarginContainer2/HBoxContainer/StatsPanel/MarginContainer/StatsContainer/EnduranceLabel
@onready var wisdom_label: Label = $MarginContainer/PanelContainer/VBoxContainer/MarginContainer2/HBoxContainer/StatsPanel/MarginContainer/StatsContainer/WisdomLabel
@onready var dexterity_label: Label = $MarginContainer/PanelContainer/VBoxContainer/MarginContainer2/HBoxContainer/StatsPanel/MarginContainer/StatsContainer/DexterityLabel
@onready var piety_label: Label = $MarginContainer/PanelContainer/VBoxContainer/MarginContainer2/HBoxContainer/StatsPanel/MarginContainer/StatsContainer/PietyLabel
@onready var willpower: Label = $MarginContainer/PanelContainer/VBoxContainer/MarginContainer2/HBoxContainer/StatsPanel/MarginContainer/StatsContainer/Willpower
@onready var description_label: Label = $MarginContainer/PanelContainer/VBoxContainer/MarginContainer2/HBoxContainer/PanelContainer/MarginContainer/VBoxContainer/DescriptionLabel
@onready var character_name: Label = $MarginContainer/PanelContainer/VBoxContainer/CharacterName


# Inventory slots
@onready var weapon_slot: Label = $MarginContainer/PanelContainer/VBoxContainer/MarginContainer/HBoxContainer/Equipped/VBoxContainer/HBoxContainer/PanelContainer2/VBoxContainer/WeaponSlot
@onready var shield_slot: Label = $MarginContainer/PanelContainer/VBoxContainer/MarginContainer/HBoxContainer/Equipped/VBoxContainer/HBoxContainer/PanelContainer2/VBoxContainer/ShieldSlot
@onready var helmet_slot: Label = $MarginContainer/PanelContainer/VBoxContainer/MarginContainer/HBoxContainer/Equipped/VBoxContainer/HBoxContainer/PanelContainer2/VBoxContainer/HelmetSlot
@onready var armor_slot: Label = $MarginContainer/PanelContainer/VBoxContainer/MarginContainer/HBoxContainer/Equipped/VBoxContainer/HBoxContainer/PanelContainer2/VBoxContainer/ArmorSlot
@onready var gloves_slot: Label = $MarginContainer/PanelContainer/VBoxContainer/MarginContainer/HBoxContainer/Equipped/VBoxContainer/HBoxContainer/PanelContainer2/VBoxContainer/GlovesSlot
@onready var boots_slot: Label = $MarginContainer/PanelContainer/VBoxContainer/MarginContainer/HBoxContainer/Equipped/VBoxContainer/HBoxContainer/PanelContainer2/VBoxContainer/BootsSlot
@onready var ring_slot: Label = $MarginContainer/PanelContainer/VBoxContainer/MarginContainer/HBoxContainer/Equipped/VBoxContainer/HBoxContainer/PanelContainer2/VBoxContainer/RingSlot
@onready var amulet_slot: Label = $MarginContainer/PanelContainer/VBoxContainer/MarginContainer/HBoxContainer/Equipped/VBoxContainer/HBoxContainer/PanelContainer2/VBoxContainer/AmuletSlot
