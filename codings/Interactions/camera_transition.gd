extends Area2D

@export var ToSubarea: SubRoom = null

func _on_body_entered(body: Node2D) -> void:
	if body == Global.Player and Global.Area.CurSubRoom == null:
		if ToSubarea != null: ToSubarea.transition()
		await Event.take_control(true, true)
		await Global.Player.go_to(global_position  + Vector2(0, -12), false, true, Vector2.UP, 24)
		Event.give_control(false)

func _on_body_exited(body: Node2D) -> void:
	if body == Global.Player and to_local(Global.Player.position).y > 0 and Global.Area.CurSubRoom == ToSubarea:
		await Event.take_control(true, true)
		if ToSubarea != null: ToSubarea.detransition()
		await Global.Player.go_to(global_position + Vector2(0, 12), false, true, Vector2.DOWN, 12)
		Event.give_control(false)
		if to_local(Global.Player.position).y < 0 or Global.Player in get_overlapping_bodies() or $"../SubRoomBg".modulate == Color.WHITE:
			Global.Player.position.y = global_position.y + 24
			Global.refresh()
