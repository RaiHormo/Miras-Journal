extends Node

func nov3_afternoon():
	await Loader.travel_to("Pyrson;HomeBuilding-MyRoom", Vector2(98, 424), 0, -1, "", false)
	await Event.wait(0.3)
	Global.Player.hide()
	Event.npc("RoomMira").BodyState = NPC.CUSTOM
	Event.npc("RoomMira").show()
	Event.npc("RoomMira").position = Vector2(166, 412)
	Event.npc("RoomMira").set_anim("SitRight")
	await Event.wait(2)
	await Global.textbox(name, "nov3_afternoon", false)
	Event.add_flag("Nov3_Afternoon")
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
