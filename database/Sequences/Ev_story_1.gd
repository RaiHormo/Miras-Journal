extends Node

func nov1_morning():
	Loader.gray_out(1)
	await Global.textbox(name, "nov1_dream")
	await Loader.travel_to("WitheredLeaves", Vector2(-96, -384), 1)
	Loader.ungray.emit()
	Event.no_player()
	await Global.textbox(name, "nov1_morning")
	await Loader.travel_to("WitheredLeaves", Vector2(775, -211), 0, -1, "D", false)
	Event.no_player()
	await Event.spawn("Mira", Vector2(750, -211), "L")
	await Event.spawn("Daze", Vector2(660, -211), "R")
	await Global.textbox(name, "nov1_daytime")
	Global.Party.set_to_strarr(["Mira", 'Daze'])
	Item.remove_item("LightweightAxe", &"Key")
	await Loader.travel_to("WitheredLeaves", Vector2(775, -211))

func daze_enemy_1():
	if Event.Day == 1 and Query.check_member("Mira") and Query.check_member("Daze"):
		Global.passive(name, "daze_enemy_1")
		await Event.wait(2)
		await Event.spawn("Daze", Global.Area.Followers[0].position, "L")
		Global.Area.Followers[0].dont_follow = true
		Global.Area.Followers[0].hide()
		Event.npc("Daze").speed = 150
		await Event.npc("Daze").go_to(Event.npc("EnemyFlowent1").position, false, false, Vector2.LEFT, 10)
		await Event.npc("EnemyFlowent1").attacked()
		Event.npc("Daze").hide()
	else: Event.give_control()

func daze_enemy_2():
	if Event.Day == 1 and Query.check_member("Mira") and Query.check_member("Daze"):
		await Event.npc("P").bubble("Surprise")
		Loader.start_battle("SkritcherRootDaze", 2)
	else: Event.give_control()

func where_is_alcine_1():
	await Loader.transition()
	Event.remove_flag("HasBag")
	Event.add_flag("AlcineAlone")
	Global.Party.reset_party()
	Global.Party.Leader = Query.find_member("Alcine")
	Global.Party.Leader.Controllable = true
	await Loader.detransition()
	Event.give_control()

func WL_alcine_slide():
	await Event.take_control()
	Global.Player.collision(false)
	Global.Player.set_anim("IdleDown")
	Global.Player.BodyState = NPC.NONE
	await Global.jump_to_global(Global.Player, Vector2(-104, 250), 8, 0)
	Global.Player.set_anim("IdleUp")
	await Event.wait(1)
	await Global.jump_to_global(Global.Player, Vector2(-110, 198), 5, 0.5)
	Event.give_control()

func amberelm_reunion():
	Global.Player.camera_follow(false)
	await Event.take_control()
	await Event.wait(0.3)
	await Global.Player.look_to("L")
	await Global.Player.bubble("Surprise")
	await Event.spawn("Mira", Vector2(2224, -157), "SitDown", true, 7)
	await Event.spawn("Daze", Vector2(2200, -157), "SitDown", true, 7)
	Global.Camera.position = Vector2(2247, -157)
	await Event.wait(0.3)
	Global.Player.chain_moves([Vector2.LEFT*2, Vector2.DOWN, Vector2.LEFT*2])
	await Event.wait(1)
	await Event.npc("Mira").move_dir(Vector2.DOWN)
	await Event.npc("Mira").look_to("R")
	await Event.npc("Mira").bubble("Surprise")
	await Global.textbox(name, "amberelm_reunion")
	await Loader.transition("R")
	Event.add_flag("HasBag")
	Event.remove_flag("AlcineAlone")
	Global.Party.set_to_strarr(["Mira"])
	Event.ToDay = 1
	Event.ToTime = 5
	await Event.time_transition()

func nov1_night():
	Event.add_flag("InCamp")
	Event.add_flag("HasBag")
	Query.find_member("Mira").OV = "Bag"
	await Loader.travel_to("WitheredLeaves", Vector2(777, -218))
	Loader.detransition()
	await Global.textbox(name, "nov1_night")
	Event.give_control()
	Loader.save()

func nov2_morning():
	Loader.gray_out(1)
	await Loader.travel_to("WitheredLeaves", Vector2(-96, -384), 1)
	Loader.ungray.emit()
	Event.npc("DazeTent").hide()
	Event.no_player()
	await Global.textbox(name, "nov2_morning")
	await Loader.travel_to("WitheredLeaves", Vector2(775, -211), 0, -1, "D", false)
	Global.Party.set_to_strarr(["Alcine"])
	Event.remove_flag("HasBag")
	Event.remove_flag("InCamp")
	Event.add_flag("AlcineAlone")
	Event.add_flag("WLLeftSideOpen")
	Event.remove_flag("HideDate")
	await Loader.travel_to("WitheredLeaves", Vector2(775, -211))

func nov2_daytime():
	await Loader.travel_to("WitheredLeaves", Vector2(-96, -384), 1, -1, "none", false)
	Event.no_player()
	Event.npc("DazeTent").hide()
	Loader.ungray.emit()
	await Global.textbox(name, "nov2_daytime")
	Global.Party.set_to_strarr(["Mira"])
	Event.add_flag("HasBag")
	Event.remove_flag("AlcineAlone")
	Event.remove_flag("HideDate")
	await Loader.travel_to("WitheredLeaves", Vector2(775, -211))

func WL_bunker_switch():
	await Loader.transition()
	await Loader.travel_to("WitheredLeaves", Vector2(-250, -1010), 0, -1, "none", false)
	await Event.no_player()
	await Event.spawn("Mira:MiraOVBag", Vector2(-250, -1000), "U")
	await Event.spawn("Daze", Vector2(-275, -1010), "U")
	await Event.spawn("Alcine", Vector2(-275, -990), "U")
	await Loader.detransition("U")
	await Global.textbox(name, "WL_bunker_switch")
	await Loader.travel_to("WitheredLeaves", Vector2(-275, -986), 0, -1, "U")

func asteria_boss():
	await Event.take_control()
	await Global.textbox(name, "asteria_boss")
	await Event.spawn("Asteria", Vector2(-286, 308), "L")
	await Event.wait(1)
	await Loader.start_battle("AsteriaBoss")
	Event.npc("Asteria").hide()
	await Loader.battle_end
	if Loader.BattleResult == 1:
		Event.npc("Asteria").show()
		Event.add_flag("AsteriaBoss", 5)
		Event.take_control()
		Event.npc("F1").move_dir(Vector2(1, 0))
		await Global.textbox(name, "asteria_boss_after")
		Event.ToDay = 2
		Event.ToTime = 4
		Event.add_flag("InCamp")
		Event.time_transition()

func nov2_evening():
	Global.Party.set_to_strarr(["Mira"])
	await Loader.travel_to("WitheredLeaves", Vector2(774, -202), 0, -1, "R", false)
	Event.npc("AlcineCamp").position = Vector2(746, -232)
	Event.npc("P").look_to("L")
	await Global.textbox(name, "asteria_joins")
	Event.give_control(true)
	Event.add_flag("VeinetDisabled")
	Loader.save()

func enter_pyrson():
	await Loader.travel_to("Pyrson", Vector2(0,0), 0, -1, "R", false)
	Global.Player.hide()
	Global.Player.camera_follow(false)
	Loader.ungray.emit()
	Event.camera_move(Vector2(568, 669))
	Event.camera_move(Vector2(214, 172), 5)
	Global.location_name("Pyrson")
	await Event.wait(5)
	Event.spawn("Asteria", Vector2i(214, 182), "R")
	await Global.textbox(name, "enter_pyrson")
	Global.Party.set_to_strarr(["Mira", "Alcine", "Daze"])
	Global.check_party.emit()
	Global.Player.show()
	Event.teleport_followers()
	Event.give_control(true)
	await Event.npc("Asteria").go_to(Vector2(372, 227), false)
	await Event.npc("Asteria").move_dir(Vector2.UP)
	Event.npc("Asteria").queue_free()
