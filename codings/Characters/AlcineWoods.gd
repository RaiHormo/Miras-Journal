extends NPC

func _on_area_2d_body_entered(body: Node2D) -> void:
	if Event.check_flag("AlcineFollow1"): return
	if body == Global.Player:
		BodyState = IDLE
		PartyUI.UIvisible = false
		Global.Controllable = false
		Global.Player.set_anim("IdleUp")
		await Event.wait(0.5)
		look_to(Vector2.DOWN)
		$Bubble.play("Surprise")
		await $Bubble.animation_finished
		await move_dir(Vector2.UP*5)
		await DialogueManager.textbox("temple_woods_random", "was_that_a")
		Global.Controllable = true
		Event.add_flag("AlcineFollow1")
		PartyUI.UIvisible = true

func _input(event: InputEvent) -> void:
	if Event.check_flag("CantDashOnFlame"): return
	if Global.Player.flame_active and event.is_action_pressed("Dash"):
		Event.add_flag("CantDashOnFlame")
		DialogueManager.passive("temple_woods_random", "cant_dash_on_flame")
