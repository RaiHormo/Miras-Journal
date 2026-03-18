extends Node


func sleep_home():
	await Event.take_control()
	Event.set_time(Event.TOD.MORNING)
	Event.remove_flag("eepy")
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
	Global.Party.reset_party()
	await Loader.travel_to("Pyrson;HomeBuilding-MyRoom", Vector2(106, 414))
	Global.Player.look_to("R")
	Event.give_control()


func return_home_pyrson():
	Global.Party.reset_party()
	Global.heal_party()
	await Loader.travel_to("Pyrson", Vector2(97, 157))
	await Global.textbox("interact_pyrson", "return_home_pyrson")
	Event.give_control()
