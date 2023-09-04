extends NPC
var PinRange = false
@export var Battle: BattleSequence
@export var Defeated = false

func default():
	if Defeated: return
	while not PinRange:
		coords = Global.Tilemap.local_to_map(global_position)
		await go_to(coords + Vector2(randf_range(-3,3), randf_range(-3,3)))
		#await Event.wait(randf_range(0.5,3))


func _physics_process(delta):
	if Defeated: 
		hide()
		$CatchArea/CollisionShape2D.disabled = true
		return
	if Global.Player in $CatchArea.get_overlapping_bodies() and Global.Controllable:
		Loader.Attacker = self
		await Loader.start_battle(Battle)
		global_position = Global.Tilemap.map_to_local(DefaultPos)
	if $DirectionMarker/Finder.get_overlapping_areas().is_empty():
		PinRange = false
	elif not PinRange and not Loader.chased: 
		PinRange = true
		stop_going()
		Loader.chase_mode()
		Loader.battle_bars(1)
		$Bubble.play("Surprise")
		await $Bubble.animation_finished 
		move_to(Global.Player.coords)
		var tmr:SceneTreeTimer = get_tree().create_timer(3)
		while tmr.time_left != 0:
			if $DirectionMarker/Finder.has_overlapping_areas():
				if  tmr.time_left < 2:
					tmr.set_time_left(2)
				move_to(Global.Player.coords)
			await Event.wait()
		Loader.battle_bars(0)
		default()
		Loader.chased = false
		PinRange = false

