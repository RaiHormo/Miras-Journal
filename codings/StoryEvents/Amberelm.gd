extends Room

func default():
	if Global.CameraInd == 0 and not Event.f("EnteredAmberelm", 2):
		await Event.wait(0.3)
		await Event.take_control(false, true)
		await Global.Player.move_dir(Vector2.UP * 2)
		Event.remove_flag("FlameActive")
		Event.f("EnteredAmberelm2", true)
		Event.give_control(true)
		Loader.save()

func skip():
	await Event.wait(0.3)
	Loader.travel_to("Amberelm", Vector2.ZERO, 0, -1, "U")
	Event.f("EnteredAmberelm2", true)
