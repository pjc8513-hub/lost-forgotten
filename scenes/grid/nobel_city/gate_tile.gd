extends Node3D

@onready var interactable: InteractableComponent = $InteractableComponent


func _ready() -> void:
	if interactable == null:
		push_error("Gate tile requires an InteractableComponent: %s" % get_path())
		return
	interactable.interaction_text = "Travel"
	interactable.interacted.connect(_on_interacted)


func _on_interacted(_actor: Node) -> void:
	if QuestManager.get_travel_destinations().is_empty():
		MapManager.request_alert("No travel destinations are available.")
		return
	MapManager.request_travel_menu()
