extends Area2D

@export var LeftSubarea: SubRoom = null
@export var RightSubarea: SubRoom = null

func _on_body_entered(body: Node2D) -> void:
	if body == Global.Player:
		match Global.Area.CurSubRoom:
			LeftSubarea:
				await Event.take_control(true, true)
				if RightSubarea != null: RightSubarea.transition()
				LeftSubarea.fade_out()
				await Global.Player.go_to(Vector2(global_position.x +12, Global.Player.position.y), false, true, Vector2.RIGHT, 4)
				Event.give_control(false)
				if to_local(Global.Player.position).x < 0 or Global.Player in get_overlapping_bodies():
					Global.Player.position.x = global_position.x + 24
			RightSubarea:
				await Event.take_control(true, true)
				if LeftSubarea != null: LeftSubarea.transition()
				RightSubarea.fade_out()
				await Global.Player.go_to(Vector2(global_position.x -12, Global.Player.position.y), false, true, Vector2.LEFT, 4)
				Event.give_control(false)
				if to_local(Global.Player.position).x > 0 or Global.Player in get_overlapping_bodies():
					Global.Player.position.x = global_position.x - 24
