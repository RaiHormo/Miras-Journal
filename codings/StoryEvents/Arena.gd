extends Room

func default():
	Global.reset_all_members()
	Global.Party.reset_party()
	await Event.wait(1)
	for i in range(1, 3):
		await start_round(i)
	Global.Party.add("Alcine")
	$Bg.texture = preload("res://art/Backgrounds/ArenaBg/TempleRoadBg.png")
	for i in range(3, 4):
		await start_round(i)

func start_round(i: int):
	$Round.text = "ROUND "+ str(i)
	await Event.wait(0.1)
	await Loader.start_battle("ArenaBattles/Round" + str(i))
	await Loader.battle_end
