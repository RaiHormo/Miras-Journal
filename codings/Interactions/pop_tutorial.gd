extends Area2D
@export var flag: String
@export var tutorial: String

func _on_body_entered(body):
	if not Event.f(flag) and body == Global.Player:
		Event.pop_tutorial(tutorial)
		Event.f(flag, true)
