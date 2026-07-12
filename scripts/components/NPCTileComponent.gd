class_name NPC_Tile_Component
extends Node3D

@export var NPC_List: Array[NPCComponent] = [] # array of NPCs available from the tile

func get_active_npcs() -> Array[NPCComponent]:
	var active_npcs: Array[NPCComponent] = []
	for npc in NPC_List:
		if npc != null and npc.is_npc_active():
			active_npcs.append(npc)
	return active_npcs

func interact(_actor: Node) -> void:
	var active_npcs := get_active_npcs()
	if active_npcs.is_empty():
		MapManager.request_alert("No one is available.")
		return
	MapManager.request_dialogue(active_npcs)
