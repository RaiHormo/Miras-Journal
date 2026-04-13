extends Node

@export var ID := ""


func _ready() -> void:
	Event.Objects.set(ID, get_parent())
