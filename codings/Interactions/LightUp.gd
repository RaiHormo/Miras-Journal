extends Area2D

func _on_body_entered(body):
	if Event.check_flag("TWflame"): return
	if body == Global.Player:
		await Global.Player.stop_dash()
		Global.Controllable = false
		Global.Player.set_anim("IdleRight")
		await DialogueManager.textbox("temple_woods_random", "getting_dark")
		Global.Player.flame_active = true
		await Global.Player.activate_flame()
		await Event.wait(0.5)
		await DialogueManager.textbox("temple_woods_random", "that_should_do_it")
		PartyUI.UIvisible = true
		Global.Controllable = true
		Event.add_flag("TWflame")
