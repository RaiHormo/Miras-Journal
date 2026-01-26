extends NPC

func default() -> void:
	if Global.CameraInd == 1 and Event.f("AlcineFollow", 1): hide()
	elif Global.CameraInd == 2 and not Event.f("AlcineFollow", 2):
		$"../EvPetrogon".hide()
		Event.flag_progress("AlcineFollow", 1)
		Event.warp_to(Vector2(55, -44), "Alcine")
		await Event.wait(0.2)
		Global.Player.can_dash = false
		await move_dir(Vector2.UP)
		Global.passive("story_0", "hey_wait")
		await move_dir(Vector2.RIGHT*15)
		BodyState = CUSTOM
		$Sprite.play("Scared")
		$Sprite.stop()
		$Sprite.frame = 0
		Event.flag_progress("AlcineFollow", 2)
		Global.Player.can_dash = true
		Loader.save()
		if Global.Player in $Area2D.get_overlapping_bodies():
			_on_area_2d_body_entered(Global.Player)
	elif (Global.CameraInd == 2 and Event.f("AlcineFollow", 2)
	and not Event.f("AlcineFollow", 3)):
		$"../EvPetrogon".hide()
		Event.warp_to(Vector2(55+15, -45), "Alcine")
		BodyState = CUSTOM
		set_anim("Scared")
		$Sprite.stop()
	elif Global.CameraInd == 2 and Event.f("AlcineFollow", 4):
		position = Vector2(1963, -1312)
		hide()
		$"../EvPetrogon".hide()
		#Global.passive()
	else:
		$Sprite.play("IdleRight")
		show()


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body == Global.Player and self != Event.CutsceneHandler:
		if (Event.f("AlcineFollow", 1) and Event.f("AlcineFollow", 2) and
		Global.CameraInd == 2 and not Event.f("AlcineFollow", 3)):
			Global.Party.Leader.ClutchDmg = true
			Event.CutsceneHandler = self
			await Event.take_control()
			Global.Player.set_anim("IdleRight")
			Global.Player.camera_follow(false)
			var t = create_tween()
			t.set_ease(Tween.EASE_OUT)
			t.set_trans(Tween.TRANS_QUART)
			t.tween_property(Global.get_cam(), "position:x", 1650, 1)
			$Sprite.animation = &"Scared"
			$Sprite.frame = 0
			await t.finished
			Event.wait(0.5)
			await Global.textbox("story_0", "approach")
			Global.Player.collision(false)
			await Global.Player.go_to(Vector2(67, -45), true)
			await Event.wait(0.3)
			Global.Player.BodyState = CUSTOM
			Global.Player.set_anim("ReachOut")
			Global.Player.position = round(Global.Player.position)
			t = create_tween()
			t.set_parallel()
			t.set_ease(Tween.EASE_OUT)
			t.set_trans(Tween.TRANS_QUART)
			t.tween_property($Glow, "energy", 0.6, 2)
			t.tween_property($Glow, "texture_scale", 3, 2)
			Global.Player.get_node("Flame").flicker = false
			t.tween_property(Global.Player.get_node("Flame"), "energy", 0, 2)
			await t.finished
			Event.f("FlameActive", false)
			await Global.textbox("story_0", "you_ok")
			await Event.wait(0.5)
			BodyState = CUSTOM
			$Sprite.play("Scared")
			position = round(position)
			await $Sprite.animation_finished
			#await bubble("Question")
			await Event.wait(1)
			round(position)
			await Global.textbox("story_0", "no_harm")
			$Sprite.play("ScaredTurn")
			await Event.wait(0.5)
			await move_dir(Vector2(-2, 0))
			t = create_tween()
			t.tween_property(self, "position", Global.Player.position+Vector2(2, 4), 0.1)
			BodyState = CUSTOM
			$Sprite.play("Hug")
			Global.Player.bubble("Surprise")
			await Event.wait(1.5)
			await Global.textbox("story_0", "haha")
			t = create_tween()
			t.tween_property(self, "position:y", -10, 0.1).as_relative()
			t.tween_property(self, "position:y", 10, 0.1).as_relative()
			$Sprite.sprite_frames = preload("res://art/OV/Alcine/AlcineOV.tres")
			await Event.wait(1)
			Global.Player.set_anim("IdleRight")
			await Global.textbox("story_0", "good_on_you")
			look_to(Vector2.RIGHT)
			await bubble("Surprise")
			await go_to(Vector2(1630, -1081), false)
			Event.remove_flag(&"FlameActive")
			$"../EvPetrogon".show()
			$"../EvPetrogon".play("Fly")
			t = create_tween()
			t.set_ease(Tween.EASE_OUT)
			t.set_trans(Tween.TRANS_QUART)
			t.tween_property($"../EvPetrogon", "position", Vector2(1731, -1080), 2).from(Vector2(1805, -1183))
			Global.Player.bubble("Surprise")
			Global.Player.reset_sprite()
			await Event.wait()
			Global.Player.set_anim("EntrancePrep")
			Global.get_cam().position += Vector2(50, 0)
			await go_to(Vector2(1607, -1081), false)
			await go_to(Vector2(1607, -1100), false)
			BodyState = CUSTOM
			$Sprite.stop()
			$Sprite.animation = &"Scared"
			$Sprite.frame = 0
			await Event.wait(1)
			$"../EvPetrogon".play("Idle")
			await Global.textbox("story_0", "stay_back")
			Loader.Attacker = Global.Area.get_node("EvPetrogon")
			await Event.wait(0.1)
			Global.Party.Leader.add_health(30)
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
			await Global.textbox("story_0", "was_that_a")
			await Event.give_control(true)
			Event.flag_progress("AlcineFollow", 1)
		#elif Global.CameraInd == 2 and Event.f("AlcineFollow", 4) and not Event.f("AlcineFollow", 5):
			#await Event.take_control()
			#Event.give_control(true)
			#Global.Player.can_dash = false
			#Global.Player.speed = 50
			#await Global.passive("story_0", "a_bridge")
			#Global.Player.can_dash = true
			#Global.Player.speed = 75
			#Event.flag_progress("AlcineFollow", 5)


#func skip():
	#if (Event.f("AlcineFollow", 1) and Event.f("AlcineFollow", 2) and
	#Global.CameraInd == 2 and not Event.f("AlcineFollow4")):
		#Event.flag_progress("AlcineFollow", 3)
		#$"../EvPetrogon".hide()
		#$"../EvPetrogon".play("Idle")
		#BodyState = CUSTOM
		#Global.Player.BodyState = CUSTOM
		#Global.Player.set_anim("EntrancePrep")
		#$Sprite.stop()
		#Event.remove_flag(&"FlameActive")
		#$Sprite.animation = &"Scared"
		#$Sprite.frame = 0
		#Global.Player.position = Global.globalize(Vector2(67, -45))
		#global_position = Global.globalize(Vector2(66, -45))
		#Loader.Attacker = Global.Area.get_node("Petrogon")
		#Loader.start_battle("AlcineFollow1")

func alcine_helps():
	$Sprite.play("IdleRight")
	await bubble("Surprise")
	PartyUI.disabled = true
	PartyUI.hide_all()
	var hp: int = max(Global.Bt.get_actor("Pterogon").Health, 5)
	z_index = 9
	Global.jump_to_global(self, Vector2(1660, -1068), 7, 0.5)
	Loader.white_fadeout(2, 3, 0.5)
	await Event.wait(0.5, false)
	Global.Bt.end_battle()
	hide()
	Global.Party.add("Alcine")
	await Event.wait(1, false)
	Global.Party.Member1.FirstName = "Spirit"
	await Loader.start_battle("AlcineFollow2")
	Global.Bt.get_actor("Pterogon").Health = hp
	await Loader.battle_end
	after_battle()

func after_battle():
	Global.check_party.emit()
	Event.take_control()
	while Loader.InBattle: await Event.wait(0.1)
	Event.take_control()
	Global.Party.Member1.FirstName = "Alcine"
	z_index = 0
	Event.allow_skipping = false
	Event.flag_progress("AlcineFollow", 4)
	Query.find_member("Mira").OV = "Bag"
	position = Global.Area.Followers[0].position
	await Global.Player.go_to(Vector2(67, -45), true)
	Global.Area.Followers[0].dont_follow = true
	Global.Area.Followers[0].hide()
	show()
	await go_to(Vector2(66, -45), true)
	await Event.wait(0.3)
	look_to(Vector2.RIGHT)
	Global.Camera.position =  Global.Player.position - Vector2(18, 0)
	Event.take_control()
	Global.Player.look_to(Vector2.LEFT)
	Global.Player.position = Vector2(1619, -1068)
	await Global.textbox("story_0", "got_through_that")
	await Global.alcine_naming()
	await Global.textbox("story_0", "use_name")
	await Loader.transition("R")
	hide()
	Global.get_cam().zoom = Vector2(4, 4)
	PartyUI.disabled = false
	PartyUI.UIvisible = true
	Event.allow_skipping = true
	Event.add_flag("FlameActive")
	Global.Area.Followers[0].dont_follow = false
	Loader.detransition()
	PartyUI._on_shrink()
	Event.give_control(true)
	Event.pop_tutorial("party")
	default()
	Loader.save()
