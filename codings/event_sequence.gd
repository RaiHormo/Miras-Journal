extends Node

func bag_seq():
	Global.Party.Leader.OV = "res://art/OV/Mira/MiraOVBag.tres"
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

func first_battle():
	Loader.save()
	Loader.gray_out(1)
	Event.add_flag("EvFirstBattle")
	#await Global.Player.move_dir(Vector2.RIGHT)
	await Loader.travel_to("TempleWoods", Vector2(1220, 461), 1)
	Loader.start_battle("FirstBattle")
	Event.f("DisableMenus", false)
	PartyUI.disabled = false

func TWflame():
	await Event.take_control()
	Global.Player.set_anim("IdleRight")
	await Global.textbox("interactions", "getting_dark")
	await Global.Player.activate_flame()
	await Event.wait(0.5)
	await Global.textbox("interactions", "that_should_do_it")
	Event.give_control()
	Event.add_flag("TWflame")
	Loader.save()

func sleep_home():
	await Event.take_control()
	Event.set_time(Event.TOD.MORNING)
	#await Event.next_day
	#Loader.travel_to("Pyrson;HomeBuilding-MyRoom", Vector2(178, 482), 0, 2, "")

func enter_amberelm():
	await Loader.travel_to("Amberelm", Vector2.ZERO, 1, -2, "U", false)
	var mira: NPC = Global.Area.get_node("EvEntranceCutscene/MiraCut")
	var alcine: NPC = Global.Area.get_node("EvEntranceCutscene/AlcineCut")
	mira.speed = 50
	alcine.speed = 50
	get_tree().paused = false
	alcine.go_to(Vector2(12, 50), true, false)
	await mira.go_to(Vector2(12, 49), true, false)
	await Event.wait(0.2)
	mira.look_to(Vector2.RIGHT)
	await Event.wait(0.2)
	alcine.look_to(Vector2.RIGHT)
	await Event.wait(0.3)
	alcine.speed = 75
	Event.TimeOfDay = Event.TOD.MORNING
	Event.Day = 1
	await Global.textbox("story_events", "morning")
	mira.speed = 75
	mira.move_dir(Vector2.UP*5)
	alcine.chain_moves([Vector2.RIGHT, Vector2.UP*5])
	await Event.wait(0.8)
	Loader.travel_to("Amberelm", Vector2.ZERO, 0, -1, "U")

func enter_amberelm_2():
	await Event.take_control()
	Global.Player.camera_follow(false)
	var t = create_tween()
	Global.Player.set_anim("IdleUp")
	t.tween_property(Global.get_cam(), "position", Vector2(150, 252), 7)
	await Event.wait(1)
	Global.location_name("Amberelm")
	await Event.wait(5)
	Loader.gray_out(1, 1)
	await Event.wait(2)
	Event.give_control(true)
	Global.Player.position = Vector2(222, 429)
	Event.take_control(false, true)
	await Event.wait(1)
	Global.Area.Followers[0].position = Global.Player.position + Vector2(0, 24)
	Loader.ungray.emit()
	await Global.textbox("story_events", "what_happened_here")
	await Loader.transition("R")
	Global.Player.position = Vector2(150, 345)
	Loader.detransition()
	Event.give_control(true)
	Global.Player.set_anim("IdleRight")

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
	Event.ToTime = Event.TOD.DAYTIME
	await Event.time_transition()
	Global.heal_party()

func oct0_daytime():
	await Loader.detransition()
	await Global.textbox("story_events", "wake_amberelm", true)
	await Loader.transition("R")
	Global.get_cam().zoom = Vector2(4,4)
	var cut = Global.Area.get_node("EvRestAmberelm")
	cut.hide()
	Global.Player.show()
	Loader.detransition()
	Event.give_control(true)
	Event.f("EvRestAmberelm", true)
	Global.check_party.emit()
	Loader.save()

func jump_playtest():
	await Global.textbox("testbush", "jump_playtest")
	Event.Day = 3
	Event.ToTime = Event.TOD.AFTERNOON
	Event.remove_flag("HideDate")
	Event.time_transition()

func waste_time():
	await Event.take_control()
	await Loader.transition("")
	Event.progress_by_time(1)
	await Event.time_transition()
	Loader.detransition()
	Event.give_control()

func hurt_1():
	Global.Party.Leader.Health -= 1
	Global.ui_sound("Crunch")
	PartyUI.hit_partybox(0, 4, 3)
	if Global.Party.Leader.Health < 10:
		if not Event.f("ShardsLowHP") and Global.Party.has_member("Asteria"):
			Event.take_control(false, true, true)
			Event.add_flag("ShardsLowHP")
			await Global.textbox("interactions", "shards_low_hp")
			Event.give_control()
		Global.Party.Leader.Health += 1
	Global.check_party.emit()

func wake_home():
	await Loader.travel_to("Pyrson;HomeBuilding-MyRoom", Vector2(106, 414))
	Global.Player.look_to("R")
	Event.give_control()

#func nov3_morning():
	#Loader.travel_to("Pyrson;HomeBuilding-MyRoom", Vector2(124, 469))

func nov3_afternoon():
	await Loader.travel_to("Pyrson;HomeBuilding-MyRoom", Vector2(98, 424), 0, -1, "", false)
	await Event.wait(0.3)
	Global.Player.hide()
	Event.npc("RoomMira").BodyState = NPC.CUSTOM
	Event.npc("RoomMira").show()
	Event.npc("RoomMira").position = Vector2(166, 412)
	Event.npc("RoomMira").set_anim("SitRight")
	await Event.wait(2)
	await Global.textbox("story_events", "nov3_afternoon", false)
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
	await Global.textbox("story_events", "nov3_sg_enter")
	Event.give_control(true)
	Event.add_flag("Nov3_WentToSG")
	await Event.wait(2)
	Global.passive("story_events", "very_shiny")

#############################################################

func sl_maple_1():
	await Loader.travel_to("Pyrson", Vector2(362, 778), 0 , -1, "wait")
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
	await Loader.travel_to("Pyrson", Vector2(490, 680), 0 , -1, "wait")
	Event.no_player()
	
	var mira: NPC = await Event.spawn("Mira:MiraOV", Vector2(506, 680), "R")
	var asteria: NPC = Event.npc("Asteria")
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

func sg_bunker_entrance():
	if Event.f("DefeatedLazuliteHeart"):
		await Event.take_control()
		await Global.textbox("story_events", "enter_bunker_2")
		Event.give_control()
	else:
		await Event.take_control()
		await Global.Player.bubble("Surprise")
		await Loader.start_battle("LazuliteHeartBoss")
		await Loader.battle_end
		print("done")
		Loader.ungray.emit()
		await Global.textbox("story_events", "lazulite_heart_after")
		Loader.white_fadeout(0.5, 0.3, 0.5)
		await Event.wait(1)
		Event.add_flag("DefeatedLazuliteHeart")
		Event.give_control()

func amberelm_guardian():
	Loader.start_battle("StoneGuardianBoss")
