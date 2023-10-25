extends Area2D

func _on_body_entered(body):
	print(body, "oi")
	if body == Global.Player:
		Global.Player.flame_active = true
