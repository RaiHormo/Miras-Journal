@icon("res://art/Icons/Editor/ladder.png")
class_name Ladder
extends Node2D

@export_group("Change index")
## Change the camera index when going up or down like stairs
@export_custom(PROPERTY_HINT_GROUP_ENABLE, "") var enable_stairs: bool = false
@export var down_index: CameraIndex
@export var up_index: CameraIndex

var active := false
var time: float = 8
var height: float = 0.5
var varience: float


func _physics_process(delta: float) -> void:
	if active:
		if varience == 0:
			var t := create_tween()
			t.tween_property(self, "varience", 1, 0.2)

		if varience == 1:
			var t := create_tween()
			t.tween_property(self, "varience", 0, 0.2)

		Global.Player.state = NPC.S.CUSTOM

		Global.Player.set_anim("Climb")

		if Input.is_action_pressed("ui_down"):
			Controller.rumble(0.2, 0, 0.1)
			Global.Player.direction = Vector2.DOWN * 1.5
		elif Input.is_action_pressed("ui_up"):
			Global.Player.direction = Vector2.UP * varience * 1.5

			if varience == 1:
				Controller.rumble(0.05, 0, 0.1)

			if varience == 0:
				Controller.rumble(0, 0.05, 0.1)
		else:
			Global.Player.direction = Vector2.ZERO
			Global.Player.sprite.pause()

		if Global.Player.position.y < $Start1.global_position.y and Global.Player.facing.is_vector(Vector2.UP):
			if enable_stairs:
				Global.Area.change_index(up_index)

			active = false
			Global.Player.set_anim("IdleUp")
			Global.Player.shadow(true)
			await Event.jump_to_global(Global.Player, $End1.global_position, time, height)
			Event.give_control()
			#Event.teleport_followers()

		if Global.Player.position.y > $Start2.global_position.y and Global.Player.facing.is_vector(Vector2.DOWN):
			if enable_stairs:
				Global.Area.change_index(down_index)

			active = false
			Global.Player.set_anim("IdleDown")
			Global.Player.look_to(Vector2.DOWN)
			Global.Player.shadow(true)
			await Event.jump_to_global(Global.Player, $End2.global_position, time, height)
			Event.give_control()
			#Event.teleport_followers()


func climb_down() -> void:
	#Global.Player.path.curve.clear_points()
	Global.Player.collision(false)
	await Event.take_control(true, true)
	await Event.jump_to_global(Global.Player, $Start1.global_position, time, height)
	Global.Player.shadow(false)
	active = true


func climb_up() -> void:
	#Global.Player.path.curve.clear_points()
	Global.Player.collision(false)
	await Event.take_control(true, true)
	await Event.jump_to_global(Global.Player, $Start2.global_position, time, height)
	Global.Player.shadow(false)
	active = true
