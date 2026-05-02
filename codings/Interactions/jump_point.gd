extends Area2D
class_name JumpPoint

## Directions where jumping is allowed in Vector2
@export var jump_dirs: Array[Vector2]
## Number of tiles to jump (24px)
@export var jump_am := 1
@export var jump_am_v := 0
## How long the jump takes
@export var time := 5
## Vertical leap height during the animation
@export var height := 0.5
## Base the target position on the player's current position, rather than a fixed tile
@export var RelativePositions: bool = false
@export_group("Change layering")
## If not -1, change the player's Z index
@export var to_z: int = -1
## If not 0, change the player's layers
@export_flags_2d_physics var to_layers := 0

@onready var target: TextureRect = $Target
@onready var timer: Timer = $Timer

var busy: bool = false
var waves: Array[TextureRect]


func _ready() -> void:
	body_exited.connect(_on_body_exited)
	if target != null:
		target.hide()


func _physics_process(delta: float) -> void:
	if busy: return
	for body in get_overlapping_bodies():
		if body == Global.Player:
			if jump_dirs.is_empty():
				Global.toast("No jump dirs here, fix this!")
				return

			# Add this object to the player's jump_points
			var player_face := Global.Player.Facing
			var player_side := Query.get_direction((to_local(body.position)))
			var can_jump := false
			for dir in jump_dirs:
				if player_face == dir and dir == -player_side:
					can_jump = true
			if can_jump:
				if not self in Global.Player.jump_points:
					Global.Player.jump_points.append(self)
			else:
				Global.Player.jump_points.erase(self)

			if Global.Player.dashing and Global.Controllable:
				if (
					Global.Player.dashdir in jump_dirs and
					Global.Player.dashdir == player_side * -1
				):
					busy = true

					# Fade the player's shadow
					Global.Player.shadow(false, remap(height, 0, 0.5, 1, 0))

					for i in waves:
						if is_instance_valid(i):
							wave_go_away(i)

					var prev_z := Global.Player.z_index
					Global.Player.BodyState = NPC.NONE
					Global.Player.z_index += 10
					Global.Controllable = false
					Global.Player.collision(false)

					var coord := get_target_coords()

					# Adjustment to make it look more right
					if player_face.y == 0:
						coord.y -= 8

					Global.Player.set_anim("Dash" + Query.get_dir_name(Global.Player.dashdir) + "Loop")
					Global.Player.sprite.frame = 0
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

					# Show shadow again
					Global.Player.shadow(true)

					prints("Jump!", name)

					for i in Global.Area.Followers:
						i.player_jumped = true
					busy = false
					Event.teleport_followers()

			if self in Global.Player.jump_points and is_instance_valid(timer):
				if timer.is_stopped():
					timer.start(1)
					timer.wait_time = 0.5
			else:
				timer.stop()


func get_target_coords(face := Global.Player.Facing) -> Vector2:
	var coord: Vector2
	if RelativePositions:
		coord = Global.Player.position + face * 24
	else:
		coord = position - face * 24

	coord += (jump_am * 24) * face + Vector2(0, jump_am_v * 24)
	coord = coord.round()
	print(coord)
	return coord


func _on_timer_timeout() -> void:
	if self in Global.Player.jump_points and Global.Controllable:
		var pos: Vector2 = to_local(get_target_coords())
		jump_target_effect(pos)


func jump_target_effect(pos: Vector2) -> void:
	var dub := target.duplicate()
	pos -= dub.get_combined_pivot_offset()
	dub.position = pos
	dub.show()
	add_child(dub)
	waves.append(dub)
	var splash_time := 1.4
	var t := create_tween().set_parallel().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	t.tween_property(dub, "scale", Vector2(0.4, 0.4) / scale, splash_time).from(Vector2(1, 1) / scale)
	t.tween_property(dub, "modulate:a", 0.4, splash_time * 0.5).from(0)
	t.tween_property(dub, "modulate:a", 0, splash_time * 0.5).set_delay(splash_time / 2)
	await t.finished
	if is_instance_valid(dub):
		dub.queue_free()


func _on_body_exited(body: Node2D) -> void:
	if body == Global.Player:
		Global.Player.jump_points.erase(self)
		timer.stop()


func wave_go_away(wave: TextureRect) -> void:
	if not is_instance_valid(wave): return
	var t := create_tween()
	t.tween_property(wave, "modulate:a", 0, 0.2)
	await t.finished
	if is_instance_valid(wave):
		wave.queue_free()
