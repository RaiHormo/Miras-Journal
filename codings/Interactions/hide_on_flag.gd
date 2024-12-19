extends Node2D

@export var flag: String = ""
@export var hide_if: bool = true

func _ready() -> void:
	check()

func check():
	if flag == "": return
	if Event.f(flag) == hide_if:
		get_parent().hide()
		for i in get_parent().get_children():
			if i is CollisionShape2D: i.disabled = true
	else:
		get_parent().show()
		for i in get_parent().get_children():
			if i is CollisionShape2D: i.disabled = false
