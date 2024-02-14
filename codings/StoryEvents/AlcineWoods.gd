extends NPC

func default() -> void:
	if Global.CameraInd == 1 and Event.f("AlcineFollow", 1): hide()
	else:
		$Sprite.play("IdleRight")
		show()
	if Global.CameraInd == 2 and not Event.f("AlcineFollow", 2):
		$"../Petrogon".hide()
		Event.flag_progress("AlcineFollow", 1)
		Event.warp_to(Vector2(55, -44), "Alcine")
		await Event.wait(0.2)
		Global.Player.can_dash = false
		await move_dir(Vector2.UP)
		Global.passive("temple_woods_random", "hey_wait")
		await move_dir(Vector2.RIGHT*15)
		BodyState = CUSTOM
		$Sprite.stop()
		$Sprite.animation = &"Scared"
		$Sprite.frame = 0
		Event.flag_progress("AlcineFollow", 2)
		Global.Player.can_dash = true
	elif (Global.CameraInd == 2 and Event.f("AlcineFollow", 2)
	and not Event.f("AlcineFollow", 3)):
		$"../Petrogon".hide()
		Event.warp_to(Vector2(55+15, -45), "Alcine")
		BodyState = CUSTOM
		$Sprite.stop()
		$Sprite.animation = &"Scared"
		$Sprite.frame = 0
	elif Global.CameraInd == 2 and Event.f("AlcineFollow", 4):
		position = Vector2(1963, -1312)
		hide()


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body == Global.Player:
		if (Event.f("AlcineFollow", 1) and Event.f("AlcineFollow", 2) and
		Global.CameraInd == 2 and not Event.f("AlcineFollow", 3)):
			Global.Party.Leader.ClutchDmg = true
			Event.CutsceneHandler = self
			await Event.take_control()
			Global.Player.set_anim("IdleRight")
			Global.Player.camera_follow()
			var t = create_tween()
			t.set_ease(Tween.EASE_OUT)
			t.set_trans(Tween.TRANS_QUART)
			t.tween_property(Global.get_cam(), "position:x", 1650, 1)
			$Sprite.animation = &"Scared"
			$Sprite.frame = 0
			await t.finished
			Event.wait(0.5)
			await Global.textbox("temple_woods_random", "approach")
			await Global.Player.go_to(Vector2(67, -45))
			await Event.wait(0.3)
			Global.Player.BodyState = CUSTOM
			Global.Player.set_anim("ReachOut")
			t = create_tween()
			t.set_parallel()
			t.tween_property($Glow, "energy", 0.6, 2)
			t.tween_property($Glow, "texture_scale", 4, 2)
			Global.Player.get_node("Flame").flicker = false
			t.tween_property(Global.Player.get_node("Flame"), "energy", 0, 2)
			await t.finished
			Event.f("FlameActive", false)
			await Event.wait(0.5)
			BodyState = CUSTOM
			$Sprite.play("Scared")
			await $Sprite.animation_finished
			await bubble("Question")
			await Event.wait(1)
			await Global.textbox("temple_woods_random", "im_not_gonna_harm_you")
			$Sprite.play("ScaredTurn")
			await Event.wait(1)
			await Global.textbox("temple_woods_random", "as_lost_as_you")
			await move_dir(Vector2(-2, 0))
			await bubble("Ellipsis")
			await Global.Player.bubble("Question")
			Global.jump_to_global(self, position, 1, 0.5)
			await Global.textbox("temple_woods_random", "haha")
			look_to(Vector2.RIGHT)
			await bubble("Surprise")
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
			Event.flag_progress("AlcineFollow", 3)
			Loader.start_battle("AlcineFollow1")
		elif Global.CameraInd == 1 and not Event.f("AlcineFollow", 1):
			print("a")
			show()
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
			Event.flag_progress("AlcineFollow", 1)
		elif Global.CameraInd == 2 and Event.f("AlcineFollow", 4):
			await Event.take_control()
			Event.give_control()
			Global.Player.can_dash = false
			Global.Player.speed = 50
			await Global.passive("temple_woods_random", "a_bridge")
			Global.Player.can_dash = true
			Global.Player.speed = 75


func skip():
	if (Event.f("AlcineFollow", 1) and Event.f("AlcineFollow", 2) and
	Global.CameraInd == 2 and not Event.f("AlcineFollow4")):
		Event.flag_progress("AlcineFollow", 3)
		$"../Petrogon".hide()
		$"../Petrogon".play("Idle")
		BodyState = CUSTOM
		Global.Player.BodyState = CUSTOM
		Global.Player.set_anim("EntrancePrep")
		$Sprite.stop()
		Event.remove_flag(&"FlameActive")
		$Sprite.animation = &"Scared"
		$Sprite.frame = 0
		Global.Player.position = Global.globalize(Vector2(67, -45))
		global_position = Global.globalize(Vector2(66, -45))
		Loader.Attacker = Global.Area.get_node("Petrogon")
		Loader.start_battle("AlcineFollow1")

func alcine_helps():
	$Sprite.play("IdleRight")
	await bubble("Surprise")
	PartyUI.only_current()
	var hp := Global.Bt.get_actor("Petrogon").Health
	await move_dir(Vector2.UP)
	await move_dir(Vector2.RIGHT)
	z_index = 9
	Global.jump_to_global(self, Vector2(1660, -1068), 7, 0.5)
	Loader.white_fadeout(2, 3, 0.5)
	await Event.wait(0.5)
	Global.Bt.end_battle()
	hide()
	Global.Party.add("Alcine")
	await Event.wait(1)
	await Loader.start_battle("AlcineFollow2")
	Global.Bt.get_node("Act/Actor1").global_position = Vector2(1660, -1068)
	Global.Bt.get_actor("Petrogon").Health = hp

func after_battle():
	while Loader.InBattle: await Event.wait(0.1)
	z_index = 0
	show()
	Global.Player.get_node("%Base").sprite_frames = Global.find_member("Mira").OV
	Global.Area.Followers[0].hide()
	position = Global.Area.Followers[0].position
	await Global.Player.go_to(Vector2(67, -45), true)
	await go_to(Vector2(66, -45), true)
	await Event.wait(0.3)
	look_to(Vector2.RIGHT)
	var t = create_tween()
	t.set_ease(Tween.EASE_OUT)
	t.set_trans(Tween.TRANS_QUART)
	t.tween_property(Global.get_cam(), "position", Global.Player.position - Vector2(18, 0), 1)
	Event.take_control()
	Global.Player.look_to(Vector2.LEFT)
	await Global.textbox("temple_woods_random", "got_through_that")
	await Loader.transition("R")
	hide()
	Global.get_cam().zoom = Vector2(4, 4)
	await Loader.detransition()
	Event.give_control()
	default()
