# DropEntry.gd
# Place this file at: res://resources/DropEntry.gd
# Sub-resource used inside EnemyData.tres drop arrays
extends Resource
class_name DropEntry

@export var item: String = ""
@export var chance: int = 10
