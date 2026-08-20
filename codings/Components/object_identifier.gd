extends Node

@export var ID := ""


func _ready() -> void:
	Event.Objects.set(ID, get_parent())

	DialogueManager.unregister_state_context(ID)
	var context := DialogueStateContext.new()
	context.target = get_parent()
	context.alias = ID
	add_child(context)
