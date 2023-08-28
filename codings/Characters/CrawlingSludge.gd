extends NPC
var PinRange = false
@export var Battle: String

func default():
	while not PinRange:
		coords = Global.Tilemap.local_to_map(global_position)
		await go_to(coords + Vector2(randf_range(-3,3), randf_range(-3,3)))
		await Event.wait(randf_range(0.5,3))


func _physics_process(delta):
#	print($CatchArea.get_overlapping_bodies())
	if Global.Player in $CatchArea.get_overlapping_bodies() and Global.Controllable:
		await Loader.StartBattle(Battle)
		global_position = Global.Tilemap.map_to_local(DefaultPos)
	if $DirectionMarker/Finder.get_overlapping_areas().is_empty():
		PinRange = false
	elif not PinRange: 
		PinRange = true
		move_to(Global.Player.coords)
		while not $DirectionMarker/Finder.has_overlapping_areas():
			move_to(Global.Player.coords)
			await Event.wait()
		default()
		PinRange = false
