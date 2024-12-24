extends Node2D
var active:= false
var time: float = 8
var height: float = 0.5
var varience: float

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
			Global.Player.direction = Vector2.DOWN
		elif Input.is_action_pressed("ui_up"):
			Global.Player.direction = Vector2.UP * varience
		else: Global.Player.direction = Vector2.ZERO
		if Global.Player.position.y < $Start1.global_position.y:
			active = false
			await Global.jump_to_global(Global.Player, $End1.global_position, time, height)
			Event.give_control()
			Event.teleport_followers()
		if Global.Player.position.y > $Start2.global_position.y:
			active = false
			Global.Player.look_to(Vector2.DOWN)
			await Global.jump_to_global(Global.Player, $End2.global_position, time, height)
			Event.give_control()
			Event.teleport_followers()

func climb_down():
	await Event.take_control(true)
	Global.Player.collision(false)
	await Global.jump_to_global(Global.Player, $Start1.global_position, time, height)
	active = true

func climb_up():
	await Event.take_control(true)
	Global.Player.collision(false)
	await Global.jump_to_global(Global.Player, $Start2.global_position, time, height)
	active = true
