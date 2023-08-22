extends NPC
var PinRange = false

func default():
	while not PinRange:
		await Event.walk(Vector2.RIGHT, 300, ID)
		await Event.walk(Vector2.LEFT, 300, ID)

func _physics_process(delta):
	if $DirectionMarker/Finder.get_overlapping_areas().is_empty():
		PinRange = false
	elif not PinRange: 
		PinRange = true
		await go_to(Global.Player.coords)
		while not $EscapeArea.get_overlapping_areas().is_empty():
			go_to(Global.Player.coords)
			await Event.wait()
		default()
		PinRange = false
