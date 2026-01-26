extends Node2D

@export var hide_instead:= false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if hide_instead: hide()
	else: queue_free()
