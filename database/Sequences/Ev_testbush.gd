extends Node


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


func demo_credits():
	await Event.take_control()
	var scene: PackedScene = await Loader.load_res("res://UI/Misc/CreditsRoll.tscn")
	get_tree().root.add_child(scene.instantiate())
