extends NPC
var PinRange = false
@export var Battle: BattleSequence
@export var Defeated = false
var lock = false

func default():
	Nav = $Nav
	while not PinRange:
		await move_dir(Vector2(randf_range(-3,3), randf_range(-3,3)), false)


func extended_process():
	if self.get_path in Loader.Defeated:
		hide()
		$CatchArea/CollisionShape2D.disabled = true
		return
#	if $DirectionMarker/Finder.get_overlapping_areas().is_empty():
#		PinRange = false


func _on_finder_area_entered(area):
	Nav.target_position = Global.Player.global_position
	if not PinRange and not Loader.chased and Nav.is_target_reachable():
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
			if Nav.is_target_reachable(): BodyState = CHASE
			else: BodyState = IDLE
			if $DirectionMarker/Finder.has_overlapping_areas() and Nav.is_target_reachable():
				if  tmr.time_left < 2:
					tmr.set_time_left(2)
			set_direction_to(Global.Player.coords)
			await Event.wait()
		Loader.battle_bars(0)
		speed = 20
		Loader.chased = false
		PinRange = false
		default()


func _on_catch_area_body_entered(body):
	if body == Global.Player and Global.Controllable and not lock:
		Global.Player.dashdir = Global.get_direction(Global.Player.to_local(global_position))
		Global.Player.get_node("Flame").energy = 0
		Global.Player.bump()
		Loader.Attacker = self
		await Loader.start_battle(Battle)
		global_position = DefaultPos

