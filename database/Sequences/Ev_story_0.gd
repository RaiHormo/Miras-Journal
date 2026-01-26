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
	Event.add_flag("DisableVeinet")
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
	await Global.textbox(name, "morning")
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
	await Global.textbox(name, "what_happened_here")
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
		await Global.textbox(name, "rest_amberelm", true)
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
	await Global.textbox(name, "wake_amberelm", true)
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
	await Global.textbox(name, "oct0_afternoon")
	Global.Complimentaries.append("FluidBlast")

func oct0_night():
	await Loader.travel_to("WitheredLeaves", Vector2(775, -211), 0, -1, "none", false)
	Event.no_player()
	await Event.spawn("Mira", Vector2(750, -211), "L")
	await Event.spawn("Daze", Vector2(660, -211), "R")
	await Global.textbox(name, "daze_introduction")
	await Loader.travel_to("WitheredLeaves", Vector2(775, -211))
