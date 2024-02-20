extends Room

func default():
	if Global.CameraInd == 1:
		Event.CutsceneHandler = self
		await Event.take_control(true, true)
		Event.npc("MiraCut").speed = 50
		Event.npc("AlcineCut").speed = 50
		Event.npc("AlcineCut").go_to(Vector2(12, 50))
		await Event.npc("MiraCut").go_to(Vector2(12, 49))
		await Event.wait(0.2)
		Event.npc("MiraCut").look_to(Vector2.RIGHT)
		await Event.wait(0.2)
		Event.npc("AlcineCut").look_to(Vector2.RIGHT)
		await Event.wait(0.3)
		Event.npc("AlcineCut").speed = 75
		await Global.textbox("amberelm_txt", "morning")
		Event.npc("MiraCut").speed = 75
		Event.npc("MiraCut").move_dir(Vector2.UP*5)
		Event.npc("AlcineCut").chain_moves([Vector2.RIGHT, Vector2.UP*5])
		await Event.wait(0.8)
		Loader.travel_to("Amberelm", Vector2.ZERO, 0, -1, "U")
	if Global.CameraInd == 0 and not Event.f("EnteredAmberelm", 1):
		await Event.wait(0.3)
		await Event.take_control(false, true)
		await Global.Player.move_dir(Vector2.UP * 2)
		Event.flag_progress("EnteredAmberelm", 1)
		Event.give_control()

func skip():
	await Event.wait(0.3)
	Loader.travel_to("Amberelm", Vector2.ZERO, 0, -1, "U")