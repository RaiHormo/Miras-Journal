extends Area2D
@export var jump_dirs: Array[Vector2]
@export var jump_am := 1
@export var time := 5
@export var height := 0.5

func _on_entered(body: Node2D) -> void:
	if body == Global.Player and Global.Player.dashing and Global.Controllable:
		if jump_dirs.is_empty() or Global.Player.dashdir in jump_dirs:
			var prev_z = Global.Player.z_index
			Global.Player.z_index += 10
			Global.Controllable = false
			Global.Player.collision(false)
			var coord: Vector2 = Global.Player.global_position
			round(coord)
			coord += (jump_am*24) * Global.Player.dashdir
			await Global.jump_to(Global.Player, coord, time, height)
			Global.Player.collision(true)
			Global.Controllable = true
			Global.Player.z_index = prev_z
