extends Node


func new_game() -> void:
	Global.first_start_time = Time.get_unix_time_from_system()

	# Hide any UI
	if get_tree().root.has_node("/root/Textbox"): $"/root/Textbox"._on_close()
	if get_tree().root.has_node("/root/Initializer"): $"/root/Initializer".queue_free()
	PartyUI.hide_all()
	# Initial flags
	Event.Flags.clear()
	Event.add_flag("Started")
	Event.add_flag("HasBag", false)
	Event.add_flag("DisableMenus", true)
	Event.add_flag("HideDate", true)
	Event.add_flag("DisableVeinet")
	Event.add_flag("time", Event.TOD.NIGHT)
	Event.add_flag("day", 0)
	Event.Day = 0
	Event.TimeOfDay = Event.TOD.NIGHT
	# Initial Items
	Item.Inventory.clear()
	Item.add_item("Wallet", &"Key", false)
	Item.add_item("PenCase", &"Key", false)
	Item.add_item("FoldedPaper", &"Key", false)
	Loader.defeated.clear()
	# Reset Party
	Global.Party.reset_party()
	Global.reset_all_members()
	Global.init_party(Global.Party)
	Global.check.emit()

	# Now start the transition
	Loader.white_fadeout(7, 1, 0, 1)
	await Loader.travel_to("TempleWoods", Vector2.ZERO, 0, -1, null, false)
	get_tree().paused = false
	# Skip intro shortcut
	if Input.is_action_pressed("Dash"):
		Global.refresh()
		return

	Global.Player.set_anim("OnFloor", false, true)
	Global.Player.shadow(false)
	var t := create_tween()
	t.set_ease(Tween.EASE_OUT)
	t.set_trans(Tween.TRANS_QUART)
	PartyUI.UIvisible = false
	t.tween_property(Global.Camera, "zoom", Vector2(6, 6), 6).from(Vector2(2, 2))
	Loader.save()
	await t.finished
	t = create_tween()
	t.set_ease(Tween.EASE_OUT)
	t.set_trans(Tween.TRANS_QUART)
	t.set_parallel()
	var getup: Button = Global.Area.get_node("GetUp")
	var options: Button = Global.Area.get_node("Options")
	getup.show()
	options.show()
	options.position = Vector2(15, 600)
	t.tween_property(getup, "position", Vector2(100, 512), 0.2).from(Vector2(120, 512))
	t.tween_property(getup, "modulate", Color.WHITE, 0.2).from(Color.TRANSPARENT)
	t.tween_property(getup, "size", Vector2(120, 33), 0.2).from(Vector2(41, 33))
	t.tween_property(options, "position", Vector2(15, 583), 0.3).set_delay(1.5)
	while not getup.button_pressed or get_tree().root.has_node("Options"):
		if not is_instance_valid(getup): return
		options.icon = Controller.get_scheme().Start

		if options.button_pressed and not get_tree().root.has_node("Options"):
			await Global.options()
			options.button_pressed = false

		await Event.wait()
		if not is_instance_valid(getup): return

	getup.button_pressed = false
	t = create_tween()
	t.set_ease(Tween.EASE_OUT)
	t.set_trans(Tween.TRANS_QUART)
	t.set_parallel()
	PartyUI.disabled = true
	t.tween_property(options, "position", Vector2(15, 600), 0.3)
	t.tween_property(getup, "size", Vector2(41, 33), 0.1)
	t.tween_property(getup, "modulate", Color.TRANSPARENT, 0.1)
	t.tween_property(options, "modulate", Color.TRANSPARENT, 0.1)
	t.tween_property(Global.Camera, "zoom", Vector2(5, 5), 5)
	t.tween_property(Global.Player.get_node("%Shadow"), "modulate", Color.WHITE, 3).from(Color.TRANSPARENT).set_delay(3)
	await Global.Player.set_anim("GetUp", true)
	Global.Player.set_anim("IdleUp")
	Global.Controllable = true
	Event.pop_tutorial("walk")
	options.hide()
	getup.hide()


func bag_seq() -> void:
	Global.Party.Leader.OV = "Bag"
	Global.Player.state = NPC.S.CUSTOM
	Global.Player.direction = Vector2.ZERO
	await Global.Player.set_anim("BagGet", true)
	Global.Player.set_anim("IdleRight")
	Audio.item_sound()
	var bag_ico: Texture = await Loader.load_res("res://art/Icons/Items.tres") as Texture
	bag_ico.region = Rect2(90, 90, 18, 18)
	Item.get_animation(bag_ico, "Flimsy bag", false)
	Event.add_flag(&"HasBag", true)
	Event.give_control()
	Global.Player._check_party()


func axe_seq() -> void:
	Item.add_item("LightweightAxe", &"Key")
	Event.pop_tutorial("ov_attack")
	Loader.save()


func first_battle() -> void:
	Global.Player.move_dir(Vector2.RIGHT * 2)
	Loader.travel_to("TempleWoods", Vector2(1220, 461), 1, -1, Direction.RIGHT, false)
	await Event.wait(0.2)
	Loader.gray_out(1)
	await Event.wait(0.5)
	Event.take_control()
	Global.Player.camera_follow(false)
	Event.camera_move(Vector2(1446, -605), 0)
	Loader.ungray.emit()
	Event.camera_move(Vector2(1486, -300), 5, Tween.EASE_IN_OUT, Tween.TRANS_LINEAR)
	await Event.wait(0.5)
	Global.location_name("Temple Woods")
	await Event.wait(4.5)
	Event.camera_move(Vector2(1558, 318), 0)
	Global.Player.hide()
	await Event.camera_move(Vector2(1429, 450), 4, Tween.EASE_OUT)
	Loader.gray_out(1)
	Loader.start_battle("FirstBattle")
	Event.add_flag("EvFirstBattle")
	Event.add_flag("DisableMenus", false)
	PartyUI.disabled = false


func AlcineFollow1() -> void:
	var Alcine: NPC = Event.npc("EvAlcineBelow")
	Alcine.show()
	Alcine.state = NPC.S.IDLE
	await Event.take_control()
	Global.Player.set_anim("IdleUp")
	await Event.wait(0.5)
	Alcine.look_to(Vector2.DOWN)
	await Alcine.bubble("Surprise")
	await Alcine.move_dir(Vector2.UP * 5)
	await Textbox.open("story_0", "was_that_a")
	Event.flag_progress("AlcineFollow", 1)
	Event.give_control(true)


func AlcineFollow2() -> void:
	var Alcine: NPC = Event.npc("Alcine")
	Event.flag_progress("AlcineFollow", 2)
	Event.obj("Pterogon").hide()
	Alcine.position = Vector2(1282, -990)
	Global.Player.can_dash = false
	Passive.open("story_0", "hey_wait")
	await Alcine.go_to(Vector2(1334, -1060))
	await Alcine.go_to(Vector2(1681, -1070))
	Alcine.state = NPC.S.CUSTOM
	Alcine.set_anim("Scared")
	Alcine.get_node("Sprite").stop()
	Global.Player.can_dash = true
	Loader.save()


func AlcineFollow3() -> void:
	var Alcine: NPC = Event.npc("Alcine")
	await Event.take_control()
	Global.Party.Leader.ClutchDmg = true
	Global.Player.set_anim("IdleRight")
	Global.Player.camera_follow(false)
	var t := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)
	t.tween_property(Global.Camera, "position:x", 1650, 1)
	Alcine.set_anim("Scared", false, true)
	await t.finished

	Event.wait(0.5)
	await Textbox.open("story_0", "approach")

	Global.Player.collision(false)
	await Global.Player.go_to(Vector2(67, -45), true)
	await Event.wait(0.3)

	if not Input.is_action_pressed(&"Dash"):

		Global.Player.state = NPC.S.CUSTOM
		Global.Player.set_anim("ReachOut")
		Global.Player.position = round(Global.Player.position)
		t = create_tween().set_parallel().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)
		t.tween_property(Alcine.get_node("Glow"), "energy", 0.6, 2)
		t.tween_property(Alcine.get_node("Glow"), "texture_scale", 3, 2)
		Global.Player.get_node("Flame").flicker = false
		t.tween_property(Global.Player.get_node("Flame"), "energy", 0, 2)

		await t.finished

		Event.f_past("FlameActive", false)
		await Textbox.open("story_0", "you_ok")

		Alcine.set_anim("ScaredTurn2", false, true)
		await Event.wait(0.5)
		await Alcine.go_to(Global.Player.position + Vector2(12, 0))
		t = create_tween()
		t.tween_property(Alcine, "position", Global.Player.position + Vector2(2, 4), 0.1)
		Alcine.state = NPC.S.CUSTOM
		Alcine.set_anim("Hug")
		Global.Player.bubble("Surprise")
		await Event.wait(1.5)

		await Textbox.open("story_0", "haha")

		Alcine.look_to(Vector2.RIGHT)
		await Alcine.bubble("Surprise")
		Event.obj("Pterogon").show()
		Event.obj("Pterogon").play("Fly")
		t = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)
		t.tween_property(Event.obj("Pterogon"), "position", Vector2(1731, -1080), 2).from(Vector2(1805, -1183))
		Global.Player.bubble("Surprise")
		Global.Player.reset_sprite()
		await Event.wait()
		Global.Player.set_anim("EntrancePrep")
		Global.Camera.position += Vector2(50, 0)
		Alcine.z_index = -1
		await Alcine.go_to(Global.Player.position + Vector2(-24, -24), false)
		Alcine.state = NPC.S.CUSTOM
		Alcine.set_anim("Scared")
		await Event.wait(1)
		Event.obj("Pterogon").play("Idle")

		await Textbox.open("story_0", "stay_back")

		Loader.attacker = Event.obj("Pterogon")
		await Event.wait(0.1)
		Global.Party.Leader.Health = max(Global.Party.Leader.Health, 30)
		Global.Party.Leader.ClutchDmg = true

	Event.flag_progress("AlcineFollow", 3)
	Loader.start_battle("AlcineFollow1")


func AlcineFollowHelp() -> void:
	var Alcine: NPC = Event.npc("Alcine")
	Alcine.set_anim("IdleRight")
	await Alcine.bubble("Surprise")
	#PartyUI.disabled = true
	#PartyUI.hide_all()
	var hp: int = max(Global.Bt.get_actor("Pterogon").Health, 5)
	Alcine.z_index = 9
	Loader.white_fadeout(2, 3, 0.5)
	await Alcine.jump_to(Vector2(1660, -1068), 7, 0.5)
	Global.Bt.end_battle()
	await Loader.battle_end
	Global.Party.add("Alcine")
	Global.Party.Member1.FirstName = "Spirit"
	Alcine.hide()
	await Event.wait(0.5, false)
	await Loader.start_battle("AlcineFollow2")
	await Event.wait(1)
	Global.Bt.get_actor("Pterogon", true).Health = hp
	await Loader.battle_end
	AlcineFollow4()


func AlcineFollow4() -> void:
	var Alcine: NPC = Event.npc("Alcine")
	Global.check.emit()
	Event.take_control()
	while Loader.in_battle: await Event.wait(0.1)
	Event.take_control()
	Global.Party.Member1.FirstName = "Alcine"
	Alcine.z_index = 0
	Query.find_member("Mira").OV = "Bag"
	Alcine.position = Global.Area.followers[0].position
	await Global.Player.go_to(Vector2(67, -45), true)
	Global.Area.followers[0].dont_follow = true
	Global.Area.followers[0].hide()
	Alcine.show()
	await Alcine.go_to(Vector2(66, -45), true)
	await Event.wait(0.3)
	Alcine.look_to(Vector2.RIGHT)
	Global.Camera.position = Global.Player.position - Vector2(18, 0)
	Event.take_control()
	Global.Player.look_to(Vector2.LEFT)
	Global.Player.position = Vector2(1619, -1068)
	await Textbox.open("story_0", "got_through_that")
	await Global.alcine_naming()
	await Textbox.open("story_0", "use_name")
	await Loader.transition(Direction.RIGHT)
	Event.flag_progress("AlcineFollow", 4)
	Alcine.hide()
	Global.Camera.zoom = Vector2(4, 4)
	PartyUI.disabled = false
	PartyUI.UIvisible = true
	Event.add_flag("FlameActive")
	Global.Area.followers[0].dont_follow = false
	Loader.detransition()
	PartyUI._on_shrink()
	Event.give_control(true)
	Event.pop_tutorial("party")
	Alcine.default()
	Loader.save()


func enter_amberelm() -> void:
	Global.Player.move_dir(Vector2(0, -2))
	await Loader.travel_to("Amberelm", Vector2.ZERO, 1, -2, Direction.UP, false)
	var mira: NPC = Event.npc("MiraCut")
	var alcine: NPC = Event.npc("AlcineCut")
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
	Event.Day = 0
	await Textbox.open(name, "morning")
	Event.npc("MiraCut").speed = 75
	Event.npc("MiraCut").move_dir(Vector2.UP * 5)
	Event.npc("AlcineCut").chain_moves([Vector2.RIGHT, Vector2.UP * 5])
	await Event.wait(0.8)
	Loader.travel_to("Amberelm", Vector2.ZERO, 0, -1, Direction.UP)
	Event.add_flag("EnterAmberelm")


func enter_amberelm_2() -> void:
	await Event.take_control()
	Global.Player.camera_follow(false)
	var t := create_tween()
	Global.Player.set_anim("IdleUp")
	t.tween_property(Global.Camera, "position", Vector2(150, 252), 7)
	await Event.wait(1)
	Global.location_name("Amberelm")
	await Event.wait(5)
	Loader.gray_out(1, 1)
	await Event.wait(2)
	Event.give_control(true)
	Global.Player.position = Vector2(222, 429)
	Event.take_control(false, true)
	await Event.wait(1)
	Global.Area.followers[0].position = Global.Player.position + Vector2(0, 24)
	Loader.ungray.emit()
	await Textbox.open(name, "what_happened_here")
	await Loader.transition(Direction.RIGHT)
	Global.Player.position = Vector2(150, 345)
	Loader.detransition()
	Event.give_control(true)
	Global.Player.set_anim("IdleRight")


func amberelm_guardian() -> void:
	Loader.start_battle("StoneGuardianBoss")
	await Loader.battle_end
	if Loader.battle_result == 1:
		Global.Party.set_to_strarr(["Mira"])
		Loader.ungray.emit()
		Event.ToDay = 0
		Event.ToTime = 5
		Event.add_flag("BeatStoneGuardian")
		Event.time_transition()


func oct31_night() -> void:
	Event.add_flag("BeatStoneGuardian")
	await Loader.travel_to("WitheredLeaves", Vector2(750, -211), 0, -1, "none", false)
	await Event.no_player()
	#Loader.detransition()
	await Event.spawn("Mira", Vector2(770, -211), Direction.LEFT)
	await Event.spawn("Daze", Vector2(670, -211), Direction.RIGHT)
	await Textbox.open(name, "daze_introduction")
	Item.remove_item("LightweightAxe", &"Key")
	Event.add_flag("DisableVeinet")
	Event.remove_flag("HideDate")
	Global.Party.set_to(["Mira"])
	Global.Party.Leader.ClutchDmg = false
	await Loader.travel_to("WitheredLeaves", Vector2(775, -211))
