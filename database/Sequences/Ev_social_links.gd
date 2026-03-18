extends Node


func sl_maple_1():
	await Loader.travel_to("Pyrson", Vector2(362, 778), 0, -1, "wait")
	Event.no_player()
	var mira: NPC = await Event.spawn("Mira:MiraOVBag", Vector2(300, 778), "R")
	var maple: NPC = await Event.spawn("Maple", Vector2(350, 778), "L")
	Event.zoom(5)
	Loader.detransition("")
	await Event.wait(1)
	await Global.textbox("sl_maple", "rank1_1")
	Event.progress_by_time(1)
	Event.time_transition()


func sl_asteria_1():
	await Loader.travel_to("Pyrson", Vector2(490, 680), 0, -1, "wait")
	Event.no_player()
	var mira: NPC = await Event.spawn("Mira:MiraOV", Vector2(506, 680), "R")
	var asteria: NPC = Event.npc("AsteriaPlaza")
	asteria.position = Vector2(506, 640)
	asteria.look_to("R")
	await Loader.detransition("")
	mira.BodyState = NPC.CUSTOM
	mira.set_anim("SitRight")
	asteria.set_anim("IdleRight")
	Event.zoom(5, true)
	await Event.wait(2)
	await Global.textbox("sl_asteria", "rank1_1")
	Event.add_flag("sl_asteria_1")
	Event.progress_by_time(1)
	Event.time_transition()
