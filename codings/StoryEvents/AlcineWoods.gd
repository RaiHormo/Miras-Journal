extends NPC

func default() -> void:
	$"../Petrogon".hide()
	if Global.CameraInd == 1 and Event.check_flag("AlcineFollow1"): hide()
	else: $Sprite.play("IdleRight")
	if Global.CameraInd == 2 and not Event.check_flag("AlcineFollow2"):
		Event.add_flag("AlcineFollow1")
		Event.warp_to(Vector2(55, -44), "AlcineChase")
		await Event.wait(0.2)
		await move_dir(Vector2.UP)
		Global.passive("temple_woods_random", "hey_wait")
		await move_dir(Vector2.RIGHT*15)
		BodyState = CUSTOM
		$Sprite.stop()
		$Sprite.animation = &"Scared"
		$Sprite.frame = 0
		Event.add_flag("AlcineFollow2")
	elif Global.CameraInd == 2 and Event.f("AlcineFollow2") and not Event.f("AlcineFollow3"):
		Event.warp_to(Vector2(55+15, -45), "AlcineChase")
		BodyState = CUSTOM
		$Sprite.stop()
		$Sprite.animation = &"Scared"
		$Sprite.frame = 0


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body == Global.Player:
		if Event.check_flag("AlcineFollow1") and Event.check_flag("AlcineFollow2") and Global.CameraInd == 2:
			await Event.take_control()
			Global.Player.set_anim("IdleRight")
			Global.Player.camera_follow()
			Global.get_cam().position.x = 1650
			$Sprite.animation = &"Scared"
			$Sprite.frame = 0
			await Global.Player.go_to(Vector2(67, -45))
			await Event.wait(0.3)
			Global.Player.BodyState = CUSTOM
			Global.Player.set_anim("ReachOut")
			var t=create_tween()
			t.set_parallel()
			t.tween_property($Glow, "energy", 0.6, 2)
			t.tween_property($Glow, "texture_scale", 4, 2)
			Global.Player.get_node("Flame").flicker = false
			t.tween_property(Global.Player.get_node("Flame"), "energy", 0, 2)
			await t.finished
			Event.f("FlameActive", false)
			BodyState = CUSTOM
			$Sprite.play("Scared")
			await $Sprite.animation_finished
			await Event.wait(1)
			await Global.textbox("temple_woods_random", "im_not_gonna_harm_you")
			$Sprite.play("ScaredTurn")
			await Event.wait(1)
			await Global.textbox("temple_woods_random", "as_lost_as_you")
			look_to(Vector2.RIGHT)
			await bubble("Surprise")
			await move_dir(Vector2.LEFT*2)
			await move_dir(Vector2.UP)
			Event.remove_flag(&"FlameActive")
			Global.Player.bubble("Surprise")
			Global.Player.reset_sprite()
			await Event.wait()
			Global.Player.set_anim("EntrancePrep")
			$"../Petrogon".show()
			$"../Petrogon".play("Idle")
			Global.get_cam().position += Vector2(50, 0)
			await move_dir(Vector2.LEFT*2)
			await move_dir(Vector2.DOWN)
			BodyState = CUSTOM
			$Sprite.stop()
			$Sprite.animation = &"Scared"
			$Sprite.frame = 0
			await Global.textbox("temple_woods_random", "stay_back")
			Loader.Attacker = Global.Area.get_node("Petrogon")
			await Event.wait(0.1)
			Loader.start_battle("AlcineFollow1")
		elif Global.CameraInd == 1 and not Event.f(&"AlcineFollow1"):
			BodyState = IDLE
			await Event.take_control()
			Global.Player.set_anim("IdleUp")
			await Event.wait(0.5)
			look_to(Vector2.DOWN)
			$Bubble.play("Surprise")
			await $Bubble.animation_finished
			await move_dir(Vector2.UP*5)
			await Global.textbox("temple_woods_random", "was_that_a")
			await Event.give_control()
			Event.add_flag("AlcineFollow1")

#func _input(event: InputEvent) -> void:
	#if Event.check_flag("CantDashOnFlame"): return
	#if Event.check_flag(&"FlameActive") and event.is_action_pressed("Dash"):
		#Event.add_flag("CantDashOnFlame")
		#Global.passive("temple_woods_random", "cant_dash_on_flame")
