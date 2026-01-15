extends Node

func new_game() -> void:
	if get_tree().root.has_node("/root/Textbox"): $"/root/Textbox"._on_close()
	if get_tree().root.has_node("/root/Initializer"): $"/root/Initializer".queue_free()
	Global.init_party(Global.Party)
	Global.FirstStartTime = Time.get_unix_time_from_system()
	Event.Flags.clear()
	Event.add_flag("Started")
	Event.f("HasBag", false)
	PartyUI.hide_all()
	Event.f("DisableMenus", true)
	Event.f("HideDate", true)
	Item.KeyInv.clear()
	Item.ConInv.clear()
	Item.MatInv.clear()
	Item.BtiInv.clear()
	Item.add_item("Wallet", &"Key", false)
	Item.add_item("PenCase", &"Key", false)
	Item.add_item("FoldedPaper", &"Key", false)
	#Item.add_item("SmallPotion", &"Con", false)
	Loader.Defeated.clear()
	Global.Party.reset_party()
	Global.reset_all_members()
	Event.TimeOfDay = Event.TOD.NIGHT
	Event.Day = 0
	Loader.white_fadeout()
	Loader.travel_to("TempleWoods", Vector2.ZERO, 0, -1, "none", false)
	await Global.area_initialized
	await Event.take_control()
	if Input.is_action_pressed("Dash"):
		Global.refresh()
		return
	Global.Player.BodyState = NPC.CUSTOM
	Global.Player.set_anim("OnFloor")
	Global.Player.get_node("%Shadow").modulate = Color.TRANSPARENT
	Global.Player._check_party()
	var t = create_tween()
	t.set_ease(Tween.EASE_OUT)
	t.set_trans(Tween.TRANS_QUART)
	PartyUI.UIvisible = false
	t.tween_property(Global.Camera, "zoom", Vector2(6,6), 6).from(Vector2(2, 2))
	Loader.save()
	await t.finished
	t = create_tween()
	t.set_ease(Tween.EASE_OUT)
	t.set_trans(Tween.TRANS_QUART)
	t.set_parallel()
	t.tween_property(Global.Area.get_node("GetUp"), "position", Vector2(100,512), 0.2).from(Vector2(120,512))
	t.tween_property(Global.Area.get_node("GetUp"), "modulate", Color.WHITE, 0.2).from(Color.TRANSPARENT)
	t.tween_property(Global.Area.get_node("GetUp"), "size", Vector2(120,33), 0.2).from(Vector2(41, 33))
	Global.Area.get_node("GetUp").show()
	await Global.Area.get_node("GetUp").pressed
	t = create_tween()
	t.set_ease(Tween.EASE_OUT)
	t.set_trans(Tween.TRANS_QUART)
	t.set_parallel()
	PartyUI.disabled = true
	t.tween_property(Global.Area.get_node("GetUp"), "size", Vector2(41, 33), 0.1)
	t.tween_property(Global.Area.get_node("GetUp"), "modulate", Color.TRANSPARENT, 0.1)
	t.tween_property(Global.Camera, "zoom", Vector2(5,5), 5)
	t.tween_property(Global.Player.get_node("%Shadow"), "modulate", Color.WHITE, 3).from(Color.TRANSPARENT).set_delay(3)
	await Global.Player.set_anim("GetUp", true)
	Global.Player.set_anim("IdleUp")
	Global.Controllable = true
	Event.pop_tutorial("walk")

func bag_seq():
	Global.Party.Leader.OV = "Bag"
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
	await Global.textbox("interact_abad", "getting_dark")
	Event.give_control()
	Event.add_flag("TWflame")
	Loader.save()

func sleep_home():
	await Event.take_control()
	Event.set_time(Event.TOD.MORNING)
	#await Event.next_day
	#Loader.travel_to("Pyrson;HomeBuilding-MyRoom", Vector2(178, 482), 0, 2, "")

func enter_amberelm():
	Global.Player.move_dir(Vector2(0, -2))
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
	await Global.textbox("story_0", "morning")
	mira.speed = 75
	mira.move_dir(Vector2.UP*5)
	alcine.chain_moves([Vector2.RIGHT, Vector2.UP*5])
	await Event.wait(0.8)
	Loader.travel_to("Amberelm", Vector2.ZERO, 0, -1, "U")
	Event.add_flag("EnterAmberelm")

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
	await Global.textbox("story_0", "what_happened_here")
	await Loader.transition("R")
	Global.Player.position = Vector2(150, 345)
	Loader.detransition()
	Event.give_control(true)
	Global.Player.set_anim("IdleRight")

func rest_amberelm():
	Event.progress_by_time(1)
	if await PartyUI.confirm_time_passage("Rest", "Fully recover Health."):
		await Loader.save()
		Event.no_player()
		Global.check_party.emit()
		get_tree().paused = false
		Global.Area.Followers[0].hide() 
		var mira = await Event.spawn("Mira:MiraOVBag", Vector2(80, 354), "D", true, 8)
		var alcine = await Event.spawn("Alcine", Vector2(100, 340), "D", true, 8)
		mira.BodyState = NPC.NONE
		alcine.BodyState = NPC.NONE
		mira.set_anim("SitDown")
		alcine.set_anim("IdleDown")
		Loader.detransition()
		Global.get_cam().zoom = Vector2(6,6)
		Global.get_cam().position = Vector2(85,360)
		await Event.wait(1)
		await Global.textbox("story_0", "rest_amberelm", true)
		await Loader.transition("")
		await Event.wait(1)
		Global.heal_party()
		Event.ToDay = 0
		Event.ToTime = Event.TOD.DAYTIME
		await Event.time_transition()
		Global.heal_party()
	else: Event.give_control()

func oct0_daytime():
	Event.no_player()
	await Loader.detransition()
	await Loader.transition("R")
	Global.get_cam().zoom = Vector2(4,4)
	var mira = Event.npc("Mira")
	var alcine = Event.npc("Alcine")
	mira.set_anim("SitDown")
	alcine.set_anim("IdleDown")
	await Global.textbox("story_0", "wake_amberelm", true)
	Event.f("EvRestAmberelm", true)
	await Loader.travel_to("Amberelm", Vector2(120, 360), 0, 7)
	Loader.save()

func amberelm_guardian():
	Loader.start_battle("StoneGuardianBoss")
	await Loader.battle_end
	if Loader.BattleResult == 1:
		Global.Party.set_to_strarr(["Mira"])
		Loader.ungray.emit()
		Event.ToDay = 0
		Event.ToTime = 5
		Event.add_flag("BeatStoneGuardian")
		Event.time_transition()

func oct0_afternoon():
	await Global.textbox("interact_abad", "oct0_afternoon")
	Global.Complimentaries.append("FluidBlast")

func oct0_night():
	await Loader.travel_to("WitheredLeaves", Vector2(775, -211), 0, -1, "none", false)
	Event.no_player()
	await Event.spawn("Mira", Vector2(750, -211), "L")
	await Event.spawn("Daze", Vector2(660, -211), "R")
	await Global.textbox("story_0", "daze_introduction")
	await Loader.travel_to("WitheredLeaves", Vector2(775, -211))

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

func nov1_morning():
	Loader.gray_out(1)
	await Global.textbox("story_1", "nov1_dream")
	await Loader.travel_to("WitheredLeaves", Vector2(-96, -384), 1)
	Loader.ungray.emit()
	Event.no_player()
	await Global.textbox("story_1", "nov1_morning")
	await Loader.travel_to("WitheredLeaves", Vector2(775, -211), 0, -1, "D", false)
	Event.no_player()
	await Event.spawn("Mira", Vector2(750, -211), "L")
	await Event.spawn("Daze", Vector2(660, -211), "R")
	await Global.textbox("story_1", "nov1_daytime")
	Global.Party.set_to_strarr(["Mira", 'Daze'])
	Item.remove_item("LightweightAxe", &"Key")
	await Loader.travel_to("WitheredLeaves", Vector2(775, -211))

func daze_enemy_1():
	if Event.Day == 1 and Query.check_member("Mira") and Query.check_member("Daze"):
		Global.passive("story_1", "daze_enemy_1")
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

func WL_void():
	await Event.take_control(false, true, true)
	await Global.textbox("interact_abad", "WL_void")
	Event.give_control()

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
	await Global.textbox("story_1", "amberelm_reunion")
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
	await Global.textbox("story_1", "nov1_night")
	Event.give_control()
	Loader.save()

func nov2_morning():
	Loader.gray_out(1)
	await Loader.travel_to("WitheredLeaves", Vector2(-96, -384), 1)
	Loader.ungray.emit()
	Event.npc("DazeTent").hide()
	Event.no_player()
	await Global.textbox("story_1", "nov2_morning")
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
	await Global.textbox("story_1", "nov2_daytime")
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
	await Global.textbox("story_1", "WL_bunker_switch")
	await Loader.travel_to("WitheredLeaves", Vector2(-275, -986), 0, -1, "U")

func asteria_boss():
	await Event.take_control()
	await Global.textbox("story_1", "asteria_boss")
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
		await Global.textbox("story_1", "asteria_boss_after")
		Event.ToDay = 2
		Event.ToTime = 4
		Event.add_flag("InCamp")
		Event.time_transition()

func nov2_evening():
	Global.Party.set_to_strarr(["Mira"])
	await Loader.travel_to("WitheredLeaves", Vector2(774, -202), 0, -1, "R", false)
	Event.npc("AlcineCamp").position = Vector2(746, -232)
	Event.npc("P").look_to("L")
	await Global.textbox("story_1", "asteria_joins")
	Event.give_control(true)
	Event.add_flag("FreeTravelOnce")
	Loader.save()

func enter_pyrson():
	await Loader.travel_to("Pyrson")
	Loader.ungray.emit()

func hurt_1():
	Global.Party.Leader.Health -= 1
	Global.ui_sound("Crunch")
	PartyUI.hit_partybox(0, 4, 3)
	if Global.Party.Leader.Health < 10:
		if not Event.f("ShardsLowHP") and Global.Party.has_member("Asteria"):
			Event.take_control(false, true, true)
			Event.add_flag("ShardsLowHP")
			await Global.textbox("interact_abad", "shards_low_hp")
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
	await Global.textbox("story_2", "nov3_afternoon", false)
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
	await Global.textbox("story_2", "nov3_sg_enter")
	Event.give_control(true)
	Event.add_flag("Nov3_WentToSG")
	await Event.wait(2)
	Global.passive("story_2", "very_shiny")

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
		await Global.textbox("story_1", "enter_bunker_2")
		Event.give_control()
	else:
		await Event.take_control()
		await Global.Player.bubble("Surprise")
		await Loader.start_battle("LazuliteHeartBoss")
		await Loader.battle_end
		print("done")
		Loader.ungray.emit()
		await Global.textbox("story_1", "lazulite_heart_after")
		Loader.white_fadeout(0.5, 0.3, 0.5)
		await Event.wait(1)
		Event.add_flag("DefeatedLazuliteHeart")
		Event.give_control()
