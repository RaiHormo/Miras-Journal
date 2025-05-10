extends Area2D
class_name JumpPoint
@export var jump_dirs: Array[Vector2]
@export var jump_am:= 1
@export var jump_am_v:= 0
@export var time:= 5
@export var height:= 0.5
@export var DoubleJumpDir: Vector2
var busy: bool = false

func _ready() -> void:
	body_exited.connect(_on_body_exited)

func _physics_process(delta: float) -> void:
	if busy: return
	for body in get_overlapping_bodies():
		if body == Global.Player:
			if jump_dirs.is_empty():
				Global.toast("No jump dirs here, fix this!")
				return
			Global.Player.can_jump = true if Global.get_direction() in jump_dirs else false
			if Global.Player.dashing and Global.Controllable:
				if ((jump_dirs.is_empty() or Global.Player.dashdir in jump_dirs) and Global.Player.dashdir == Global.get_direction(to_local(Global.Player.position)*-1*jump_dirs[0])):
					busy = true
					var prev_z = Global.Player.z_index
					Global.Player.BodyState = NPC.NONE
					Global.Player.z_index += 10
					Global.Controllable = false
					Global.Player.collision(false)
					var coord: Vector2 = position - Global.Player.dashdir*24
					round(coord)
					coord += (jump_am*24) * Global.Player.dashdir + Vector2(0, jump_am_v*24)
					#coord /= 24
					coord = coord.round()
					#coord *= 24
					Global.Player.set_anim("Dash"+Global.get_dir_name(Global.Player.dashdir)+"Loop")
					Global.Player.used_sprite.frame = 0
					await Global.jump_to(Global.Player, coord, time, height)
					Global.Player.collision(true)
					Global.Controllable = true
					Global.Player.z_index = prev_z
					print("jump!")
					for i in Global.Area.Followers:
						i.position = Global.Player.position
					if DoubleJumpDir == Global.PlayerDir and not Input.is_action_pressed("Dash"):
						await Loader.transition()
						Global.Party.Leader.damage(randi_range(5, 25), true)
						Global.Player.position.x = global_position.x + jump_am * 12 * -Global.get_direction().x
						Global.check_party.emit()
						await Loader.detransition()
						Event.give_control()
					busy = false


func _on_body_exited(body: Node2D) -> void:
	if body == Global.Player:
		Global.Player.can_jump = false
