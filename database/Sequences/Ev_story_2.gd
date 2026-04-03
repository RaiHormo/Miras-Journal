extends Node


func nov3_morning():
	Item.add_item("LightweightAxe", "Key", false, false)
	Event.add_flag("LampInMirasRoom", false)
	await Loader.travel_to("Pyrson;HomeBuilding-MyRoom", Vector2(98, 424), 0, -1, "", false)
	Event.no_player()
	Event.npc("RoomMira").BodyState = NPC.CUSTOM
	Event.npc("RoomMira").show()
	Event.npc("RoomMira").position = Vector2(84, 424)
	Event.npc("RoomMira").set_anim("Sleep")
	await Event.wait(2)
	await Global.textbox(name, "nov3_morning", false)
	Global.Party.set_to(["Mira", "Alcine"])
	Event.ToDay = 3
	Event.ToTime = 2
	Event.time_transition()
	#await Loader.travel_to("Pyrson;HomeBuilding-MyRoom", Vector2(102, 440))


func nov3_afternoon():
	await Loader.travel_to("Pyrson;HomeBuilding-MyRoom", Vector2(98, 424), 0, -1, "", false)
	Event.no_player()
	Event.npc("RoomMira").BodyState = NPC.CUSTOM
	Event.npc("RoomMira").show()
	Event.npc("RoomMira").position = Vector2(90, 412)
	Event.npc("RoomMira").set_anim("SitRight")
	await Event.wait(2)
	await Global.textbox(name, "nov3_afternoon", false)
	await Loader.travel_to("Pyrson;HomeBuilding-MyRoom", Vector2(102, 440))
	Global.Player.Facing = Vector2.RIGHT


func nov3_enterSG():
	await Loader.travel_to("ShardGardens", Vector2(26, 84), 0, -1, "", false)
	Global.heal_party()
	Global.Party.reset_party()
	Global.Party.add("Alcine")
	Global.Party.add("Asteria")
	Global.Party.add("Daze")
	Global.Player.camera_follow(false)
	Global.location_name("Shard Gardens")
	Global.Camera.position = Vector2(663, 241)
	var t = create_tween().set_ease(Tween.EASE_IN_OUT)
	t.tween_property(Global.Camera, "position", Vector2(190, 84), 6)
	await Event.wait(4)
	Global.Player.collision(false)
	await Event.take_control(false, true)
	await Global.Player.move_dir(Vector2(6, 0))
	await Global.textbox(name, "nov3_sg_enter")
	Event.give_control(true)
	Event.add_flag("Nov3_WentToSG")
	await Event.wait(2)
	Global.passive(name, "very_shiny")


func sg_bunker_entrance():
	if Event.f("DefeatedLazuliteHeart"):
		await Event.take_control()
		await Global.textbox(name, "enter_bunker_2")
		Event.give_control()
	elif Global.Party.check_member(3):
		await Event.take_control()
		Global.textbox(name, "lazulite_warning")
	else:
		await Global.textbox(name, "sg_find_bunker")
		await Event.give_control()


func lazulite_boss():
	await Global.Player.bubble("Surprise")
	await Loader.start_battle("LazuliteHeartBoss")
	await Loader.battle_end
	print("battle done")
	Loader.ungray.emit()
	await Global.textbox(name, "lazulite_heart_after")
	Loader.white_fadeout(0.5, 0.3, 0.5)
	Event.add_flag("DefeatedLazuliteHeart")
	Event.progress_by_time(1)
	Event.time_transition()
