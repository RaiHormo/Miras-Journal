extends Area2D
@export var jump_dirs: Array[Vector2]
@export var jump_am:= 1
@export var time:= 5
@export var height:= 0.5
@export var DoubleJumpDir: Vector2

func _on_entered(body: Node2D) -> void:
	if body == Global.Player and Global.Player.dashing and Global.Controllable:
		if ((jump_dirs.is_empty() or Global.Player.dashdir in jump_dirs) and Global.Player.dashdir == Global.get_direction(to_local(Global.Player.position)*-1)):
			var prev_z = Global.Player.z_index
			Global.Player.BodyState = NPC.NONE
			Global.Player.z_index += 10
			Global.Controllable = false
			Global.Player.collision(false)
			var coord: Vector2 = Global.Player.global_position
			round(coord)
			coord += (jump_am*24) * Global.Player.dashdir
			Global.Player.used_sprite.frame = 0
			await Global.jump_to(Global.Player, coord, time, height)
			Global.Player.collision(true)
			Global.Controllable = true
			Global.Player.z_index = prev_z
			if DoubleJumpDir == Global.PlayerDir and not Input.is_action_pressed("Dash"):
				await Loader.transition()
				Global.Party.Leader.damage(randi_range(5, 25), true)
				Global.Player.position.x = global_position.x + jump_am * 12 * -Global.get_direction().x
				Global.check_party.emit()
				await Loader.detransition()
				Event.give_control()
