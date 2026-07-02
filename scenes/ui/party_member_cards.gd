extends PanelContainer
@onready var portrait: TextureRect = $HBoxContainer/Portrait
@onready var status_overlay: TextureRect = $HBoxContainer/Portrait/combatFX/StatusOverlay
@onready var damage_label: Label = $HBoxContainer/Portrait/combatFX/DamageLabel
@onready var member_name: Label = $HBoxContainer/VBoxContainer/MemberName
@onready var h_pbar: ProgressBar = $HBoxContainer/VBoxContainer/HPbar



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_gui_input(event: InputEvent) -> void:
	pass # Replace with function body.
