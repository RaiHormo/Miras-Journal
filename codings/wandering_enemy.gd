@tool
extends NPC

@export_tool_button("Add Homepoints and Sprites", "Add") var add_node_button: Callable = add_nodes
@export_tool_button("Apply positions", "CheckBox") var set_positions_button: Callable = set_positions
@export var BattleSeq: BattleSequence
@export var Defeated = false
@export var give_up_after := 3
@export var patrol_speed = 20
@export var chase_speed = 40
@onready var tmr: Timer = $Timer
var lock = false
var homepoints: Array[Vector2]
var PinRange = false
var CurHomepoint: Vector2 = Vector2.ZERO

func add_nodes():
	if get_node_or_null("HomePoints") == null:
		var homepoints = Node2D.new()
		homepoints.name = "HomePoints"
		add_child(homepoints)
		homepoints.owner = $".."
		var marker = Marker2D.new()
		marker.name = "1"
		homepoints.add_child(marker)
		marker.owner = $".."
	if get_node_or_null("Sprite") == null:
		var sprite: AnimatedSprite2D = AnimatedSprite2D.new()
		sprite.name = "Sprite"
		sprite.sprite_frames = preload("res://art/OV/Enemies/GenericEnemy.tres")
		add_child(sprite)
		sprite.owner = $".."
	var esc_marker: Marker2D =  get_node_or_null("EscapePosition")
	if esc_marker == null:
		esc_marker = Marker2D.new()
		esc_marker.name = "EscapePosition"
		add_child(esc_marker)
		esc_marker.owner = $".."
	var scn_marker: Marker2D = get_node_or_null("ScenePosition")
	if scn_marker == null:
		scn_marker = Marker2D.new()
		scn_marker.name = "ScenePosition"
		add_child(scn_marker)
		scn_marker.owner = $".."
	if BattleSeq != null:
		esc_marker.global_position = BattleSeq.EscPosition*24
		scn_marker.global_position = BattleSeq.ScenePosition
		scn_marker.gizmo_extents = 100

func set_positions():
	var scn_marker: Marker2D = get_node_or_null("ScenePosition")
	if scn_marker != null and BattleSeq != null:
		BattleSeq.ScenePosition = scn_marker.global_position
	var esc_marker: Marker2D = get_node_or_null("EscapePosition")
	if esc_marker != null and BattleSeq != null:
		BattleSeq.EscPosition = Vector2i(esc_marker.global_position/24)

func default():
	Nav = $Nav
	if ID == "": ID = name
	if ID in Loader.Defeated: queue_free()
	Loader.battle_start.connect(func(): hide())
	Loader.battle_end.connect(func(): show())
	if get_node_or_null("HomePoints") != null:
		for i in $HomePoints.get_children():
			homepoints.append(i.global_position)
	for i in Global.Area.Followers:
		add_collision_exception_with(i)
	patrol()

func patrol():
	stopping = false
	Loader.chased = false
	PinRange = false

func extended_process():
	if self.get_path in Loader.Defeated:
		hide()
		$CatchArea/CollisionShape2D.set_deferred("disabled", true)
		return
	if PinRange and tmr:
		stopping = true
		if tmr.time_left != 0:
			$Collision.set_deferred("disabled", false)
			BodyState = CHASE
			if Global.Player in $DirectionMarker/Finder.get_overlapping_bodies():
				Nav.set_target_position(Global.Player.position)
				if  tmr.time_left < 2 and Nav.is_target_reachable():
					tmr.start(2)
			if Global.get_direction(to_local(Nav.get_next_path_position())) != -Global.get_direction(direction):
				direction = to_local(Nav.get_next_path_position()).normalized()
		else:
			if not Loader.InBattle: Loader.battle_bars(0)
			patrol()
			if Loader.Attacker == self:
				Loader.Attacker = null
	else:
		if Loader.InBattle:
			hide()
		elif not homepoints.is_empty() and tmr.time_left == 0 and not stopping:
			if is_on_wall():
				Global.jump_to_global(self, CurHomepoint)
			if round(position/12) == round(CurHomepoint/12):
				tmr.start(randf_range(0,3))
				CurHomepoint = Vector2.ZERO
				BodyState = IDLE
			else:
				show()
				$Collision.set_deferred("disabled", true)
				speed = patrol_speed
				BodyState = MOVE
				if CurHomepoint == Vector2.ZERO:
					CurHomepoint = homepoints.pick_random()
				direction = to_local(CurHomepoint).normalized()


func _on_finder_body_entered(body):
	if body == Global.Player and not PinRange and not Loader.chased:
		Nav.set_target_position(Global.Player.position)
		if not Nav.is_target_reachable(): return
		stopping = true
		Loader.chase_mode()
		Loader.battle_bars(1)
		set_dir_marker(to_local(Global.Player.global_position))
		BodyState = IDLE
		direction = Vector2.ZERO
		$Bubble.play("Surprise")
		Loader.Attacker = self
		look_to(Global.get_direction(to_local(Global.Player.global_position)))
		await Event.wait(0.8)
		look_to(Global.get_direction(to_local(Global.Player.global_position)))
		speed = chase_speed
		set_dir_marker(to_local(Global.Player.global_position))
		await Event.wait()
		#if not Global.Player in $DirectionMarker/Finder.get_overlapping_bodies() or not Nav.is_target_reachable():
			#$Bubble.play("Ellipsis")
			#patrol()
		BodyState = MOVE
		tmr.start(give_up_after)
		PinRange = true

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
	await Loader.start_battle(BattleSeq, advatage)
	global_position = DefaultPos

func attacked():
	BodyState = NONE
	set_anim("Hit")
	var to_pos = position+Global.get_direction()*12
	Global.jump_to_global(self, to_pos, 25, 1)
	Global.Player.camera_follow(false)
	Global.Camera.position = to_pos
	Global.intro_effect(to_pos)
	if PinRange: begin_battle()
	else: begin_battle(1)

func _on_catch_area_area_entered(area: Area2D) -> void:
	if area.name == "Attack": attacked()
