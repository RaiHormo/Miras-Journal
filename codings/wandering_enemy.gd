extends NPC
var PinRange = false
@export var Battle: BattleSequence
@export var Defeated = false
var lock = false
var homepoints: Array[Vector2]
@export var give_up_after := 3
var tmr: SceneTreeTimer

func default():
	Nav = $Nav
	Loader.battle_start.connect(func(): hide())
	Loader.battle_end.connect(func(): show())
	if get_node_or_null("HomePoints") != null:
		for i in $HomePoints.get_children():
			homepoints.append(i.global_position)
	patrol()

func patrol():
	if not homepoints.is_empty():
		while not PinRange:
			if Loader.InBattle:
				hide()
			else:
				show()
				$Collision.set_deferred("disabled", true)
				await go_to(homepoints.pick_random(), false)
			await Event.wait(randf_range(0,3))

func extended_process():
	if self.get_path in Loader.Defeated:
		hide()
		$CatchArea/CollisionShape2D.set_deferred("disabled", true)
		return
	if PinRange and tmr:
		Nav.target_position = Global.Player.position
		stopping = true
		if tmr.time_left != 0:
			$Collision.set_deferred("disabled", false)
			print(to_local(Nav.get_next_path_position()).normalized())
			BodyState = CHASE
			if Global.Player in $DirectionMarker/Finder.get_overlapping_bodies():
				Nav.set_target_position(Global.Player.position)
				if  tmr.time_left < 2:
					tmr.set_time_left(2)
			direction = to_local(Nav.get_next_path_position()).normalized()
		else:
			Loader.chased = false
			PinRange = false
			if not Loader.InBattle: Loader.battle_bars(0)
			speed = 20
			patrol()

func _on_finder_area_entered(area):
	if !Global.Player: return
	if not PinRange and not Loader.chased:
		PinRange = true
		await stop_going()
		Loader.chase_mode()
		speed = 40
		Loader.battle_bars(1)
		BodyState = IDLE
		$Bubble.play("Surprise")
		look_to(Global.get_direction(to_local(Global.Player.global_position)))
		await $Bubble.animation_finished
		BodyState = MOVE
		tmr = get_tree().create_timer(give_up_after)

func _on_catch_area_body_entered(body):
	if (body == Global.Player and (not lock) and (not Loader.InBattle) and
	(Global.Controllable or Global.Player.dashing) and (not Global.Player.attacking)):
		#print(Global.Player.attacking)
		Global.Player.winding_attack = false
		await Event.take_control(false, false, false)
		Global.Player.dashdir = Global.get_direction(Global.Player.to_local(global_position))
		Global.Player.get_node("Flame").energy = 0
		Global.Player.bump()
		begin_battle(2)

func begin_battle(advatage := 0):
	Loader.Attacker = self
	Global.Player.dramatic_attack_pause()
	await Loader.start_battle(Battle, advatage)
	global_position = DefaultPos

func attacked():
	#Global.jump_to(self, position+Global.get_direction()*12, 5, 0.5)
	if PinRange: begin_battle()
	else: begin_battle(1)

func _on_catch_area_area_entered(area: Area2D) -> void:
	if area.name == "Attack": attacked()
