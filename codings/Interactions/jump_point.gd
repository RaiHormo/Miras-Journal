extends Area2D
class_name JumpPoint
@export var jump_dirs: Array[Vector2]
@export var jump_am:= 1
@export var jump_am_v:= 0
@export var time:= 5
@export var height:= 0.5
@export var RelativePositions: bool = false
@export var to_z: int = -1
@export_flags_2d_physics var to_layers := 0
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
			Global.Player.can_jump = true if Query.get_direction() in jump_dirs else false
			if Global.Player.dashing and Global.Controllable:
				if ((jump_dirs.is_empty() or Global.Player.dashdir in jump_dirs) and Global.Player.dashdir == Query.get_direction(to_local(Global.Player.position)*-1*jump_dirs[0])):
					busy = true
					#Global.Player.cant_bump = true
					var t = create_tween()
					t.tween_property(Global.Player.get_node("Shadow"), "modulate:a", remap(height, 0, 0.5, 1, 0), 0.1)
					var prev_z = Global.Player.z_index
					Global.Player.BodyState = NPC.NONE
					Global.Player.z_index += 10
					Global.Controllable = false
					Global.Player.collision(false)
					var coord: Vector2
					if RelativePositions:
						coord = Global.Player.position + Global.Player.dashdir*24
					else:
						coord = position - Global.Player.dashdir*24
					round(coord)
					coord += (jump_am*24) * Global.Player.dashdir + Vector2(0, jump_am_v*24)
					#coord /= 24
					coord = coord.round()
					#coord *= 24
					Global.Player.set_anim("Dash"+Query.get_dir_name(Global.Player.dashdir)+"Loop")
					Global.Player.used_sprite.frame = 0
					await Global.jump_to(Global.Player, coord, time, height)
					Global.Player.collision(true)
					Global.Controllable = true
					if to_z == -1:
						Global.Player.z_index = prev_z
					else: 
						Global.Player.z_index = to_z
						Global.Player.collision_layer = to_layers
						Global.Player.collision_mask = to_layers
					Global.Player.move_frames = 0
					t = create_tween()
					t.tween_property(Global.Player.get_node("Shadow"), "modulate", Color.WHITE, 0.2)
					print("jump!")
					for i in Global.Area.Followers:
						i.player_jumped = true
					busy = false
					Event.teleport_followers()


func _on_body_exited(body: Node2D) -> void:
	if body == Global.Player:
		Global.Player.can_jump = false
