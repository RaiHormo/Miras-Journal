extends Area2D

func _on_body_entered(body):
	if not Event.f("DashTutorial0") and body == Global.Player:
		Event.pop_tutorial("dash")
		Event.f("DashTutorial0", true)
