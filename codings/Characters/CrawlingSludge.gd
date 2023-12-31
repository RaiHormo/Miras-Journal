extends NPC
var PinRange = false
@export var Battle: BattleSequence
@export var Defeated = false
var lock = false
var homepoints: Array[Vector2]

func default():
	Nav = $Nav
	if get_node_or_null("HomePoints") != null:
		for i in $HomePoints.get_children():
			homepoints.append(i.global_position)
	patrol()

func patrol():
	if not homepoints.is_empty():
		while not PinRange:
			await go_to_global(homepoints.pick_random())
			await Event.wait(randf_range(0,3))

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
		patrol()


func _on_catch_area_body_entered(body):
	if body == Global.Player and Global.Controllable and not lock:
		Global.Player.dashdir = Global.get_direction(Global.Player.to_local(global_position))
		Global.Player.get_node("Flame").energy = 0
		Global.Player.bump()
		begin_battle()

func begin_battle(advatage := 0):
	Loader.Attacker = self
	await Global.Player.dramatic_attack_pause()
	await Loader.start_battle(Battle, advatage)
	global_position = DefaultPos

func attacked():
	#Global.jump_to(self, position+Global.get_direction()*12, 5, 0.5)
	if PinRange: begin_battle()
	else: begin_battle(1)

func _on_catch_area_area_entered(area: Area2D) -> void:
	if area.name == "Attack": attacked()
