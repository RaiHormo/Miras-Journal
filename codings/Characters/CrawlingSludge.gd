extends NPC
var PinRange = false
@export var Battle: BattleSequence
@export var Defeated = false
var lock = false

func default():
	while not PinRange:
		await move_dir(Vector2(randf_range(-3,3), randf_range(-3,3)), false)


func extended_process():
	if self.get_path in Loader.Defeated: 
		hide()
		$CatchArea/CollisionShape2D.disabled = true
		return
	if Global.Player in $CatchArea.get_overlapping_bodies() and Global.Controllable and not lock:
		lock = true
		Loader.Attacker = self
		#$CatchArea/CollisionShape2D.disabled = true
		await Loader.start_battle(Battle)
		global_position = Global.Tilemap.map_to_local(DefaultPos)
#	if $DirectionMarker/Finder.get_overlapping_areas().is_empty():
#		PinRange = false


func _on_finder_area_entered(area):
	if not PinRange and not Loader.chased: 
		PinRange = true
		await stop_going()
		Loader.chase_mode()
		speed = 40
		Loader.battle_bars(1)
		BodyState = IDLE
		$Bubble.play("Surprise")
		look_to(to_local(Global.Player.global_position))
		await $Bubble.animation_finished 
		#go_to(Global.Player.coords)
		var tmr:SceneTreeTimer = get_tree().create_timer(3)
		while tmr.time_left != 0:
			BodyState=CHASE
			if $DirectionMarker/Finder.has_overlapping_areas():
				if  tmr.time_left < 2:
					tmr.set_time_left(2)
			set_direction_to(Global.Player.coords)
			await Event.wait()
		Loader.battle_bars(0)
		speed = 20
		Loader.chased = false
		PinRange = false
		default()
