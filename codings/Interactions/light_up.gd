extends Area2D

func _on_body_entered(body):
	if Event.check_flag("TWflame"): return
	if body == Global.Player:
		await Event.take_control()
		Global.Player.set_anim("IdleRight")
		await Global.textbox("temple_woods_random", "getting_dark")
		await Global.Player.activate_flame()
		await Event.wait(0.5)
		await Global.textbox("temple_woods_random", "that_should_do_it")
		Event.give_control()
		Event.add_flag("TWflame")
