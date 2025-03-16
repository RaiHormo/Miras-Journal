extends Node

func bag_seq():
	Global.Player.BodyState = NPC.CUSTOM
	Global.Player.direction = Vector2.ZERO
	await Global.Player.set_anim("BagGet", true)
	Global.Player.set_anim("IdleRight")
	Global.item_sound()
	var bag_ico = preload("res://art/Icons/Items.tres")
	bag_ico.region = Rect2(90, 90, 18, 18)
	Item.get_animation(bag_ico, "Flimsy bag", false)
	Event.f(&"HasBag", true)
	Event.give_control()
	Global.Player._check_party()

func axe_seq():
	Item.add_item("LightweightAxe", &"Key")
	Event.pop_tutorial("ov_attack")

func TWflame():
	await Event.take_control()
	Global.Player.set_anim("IdleRight")
	await Global.textbox("interactions", "getting_dark")
	await Global.Player.activate_flame()
	await Event.wait(0.5)
	await Global.textbox("interactions", "that_should_do_it")
	Event.give_control()
	Event.add_flag("TWflame")

func sleep_home():
	if Event.TimeOfDay == Event.TOD.MORNING:
		await Loader.detransition()
		await Global.textbox("interactions", "just_woke_up")
		Event.give_control()
		return
	await Event.take_control()
	Event.set_time(Event.TOD.MORNING)
	await Event.next_day
	Loader.travel_to("Pyrson;HomeBuilding-MyRoom", Vector2(178, 482), 0, 2, "")

func rest_amberelm():
	Event.take_control()
	await Loader.save()
	Global.check_party.emit()
	Loader.detransition()
	var cut = Global.Area.get_node("EvRestAmberelm")
	cut.show()
	get_tree().paused = false
	Global.Area.Followers[0].hide()
	cut.get_node("Mira").BodyState = NPC.NONE
	cut.get_node("Alcine").BodyState = NPC.NONE
	cut.get_node("Mira").set_anim("SitDown")
	cut.get_node("Alcine").set_anim("IdleDown")
	Global.Player.hide()
	Global.Player.camera_follow(false)
	Global.get_cam().zoom = Vector2(6,6)
	Global.get_cam().position = Vector2(85,360)
	await Event.wait(1)
	await Global.textbox("story_events", "rest_amberelm", true)
	await Loader.transition("")
	await Event.wait(1)
	Global.heal_party()
	Event.TimeOfDay = Event.TOD.AFTERNOON
	Global.heal_party()
	await Loader.detransition()
	await Global.textbox("story_events", "wake_amberelm", true)
	await Loader.transition("R")
	Global.get_cam().zoom = Vector2(4,4)
	cut.hide()
	Global.Player.show()
	Loader.detransition()
	Event.give_control()
	Event.f("EvRestAmberelm", true)
	Loader.save()

func waste_time():
	await Event.take_control()
	Event.progress_by_time(1)
	Loader.detransition()
	Event.give_control()

func gather_pyrson():
	Global.textbox("interactions", "gather_pyrson")

#############################################################

func sl_maple_1():
	await Loader.travel_to("Pyrson", Vector2(362, 778), 0 , -1, "wait")
	Event.no_player()
	Event.zoom(5)
	var mira: NPC = await Event.spawn("Mira:MiraOVBag", Vector2(300, 778), "R")
	var maple: NPC = await Event.spawn("Maple", Vector2(350, 778), "L")
	Loader.detransition("")
	await Event.wait(1)
	Global.textbox("sl_maple", "rank1_1")
