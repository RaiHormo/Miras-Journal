extends Node2D
var active:= false
var time: float = 8
var height: float = 0.5
var varience: float

@export var enable_stairs:= false
@export_flags_2d_physics var LayersUp := 1
@export_flags_2d_physics var LayersDown := 1
@export var zUp := 0
@export var zDown := 0

func _physics_process(delta: float) -> void:
	if active:
		if varience == 0:
			var t = create_tween()
			t.tween_property(self, "varience", 1, 0.2)
		if varience == 1:
			var t = create_tween()
			t.tween_property(self, "varience", 0, 0.2)
		Global.Player.BodyState = NPC.CUSTOM
		Global.Player.set_anim("IdleUp")
		if Input.is_action_pressed("ui_down"):
			Global.rumble(0.2, 0, 0.1)
			Global.Player.direction = Vector2.DOWN *1.5
		elif Input.is_action_pressed("ui_up"):
			Global.Player.direction = Vector2.UP * varience * 1.5
			if varience == 1: Global.rumble(0.05, 0, 0.1)
			if varience == 0: Global.rumble(0, 0.05, 0.1)
		else: Global.Player.direction = Vector2.ZERO
		if Global.Player.position.y < $Start1.global_position.y and Global.Player.Facing == Vector2.UP:
			if enable_stairs:
				Global.Player.z_index = zUp
				Global.Player.collision_layer = LayersUp
				Global.Player.collision_mask = LayersUp
			active = false
			await Global.jump_to_global(Global.Player, $End1.global_position, time, height)
			Event.give_control()
			Event.teleport_followers()
		if Global.Player.position.y > $Start2.global_position.y and Global.Player.Facing == Vector2.DOWN:
			if enable_stairs:
				Global.Player.z_index = zDown
				Global.Player.collision_layer = LayersDown
				Global.Player.collision_mask = LayersDown
			active = false
			Global.Player.look_to(Vector2.DOWN)
			await Global.jump_to_global(Global.Player, $End2.global_position, time, height)
			Event.give_control()
			Event.teleport_followers()

func climb_down():
	Global.Player.collision(false)
	await Event.take_control(true)
	await Global.jump_to_global(Global.Player, $Start1.global_position, time, height)
	active = true

func climb_up():
	Global.Player.collision(false)
	await Event.take_control(true)
	await Global.jump_to_global(Global.Player, $Start2.global_position, time, height)
	active = true
