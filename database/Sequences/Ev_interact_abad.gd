extends Node

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

func sleep_home():
	await Event.take_control()
	Event.set_time(Event.TOD.MORNING)
	#await Event.next_day
	#Loader.travel_to("Pyrson;HomeBuilding-MyRoom", Vector2(178, 482), 0, 2, "")

func WL_void():
	await Event.take_control(false, true, true)
	await Global.textbox("interact_abad", "WL_void")
	Event.give_control()

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
