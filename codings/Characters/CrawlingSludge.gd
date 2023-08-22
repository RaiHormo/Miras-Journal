extends NPC

func default():
	speed = 10
	while true:
		await Event.walk(Vector2.RIGHT, 300, ID)
		await Event.walk(Vector2.LEFT, 300, ID)
