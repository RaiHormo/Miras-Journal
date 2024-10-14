extends Area2D

@export var ToSubarea: SubRoom = null

func _on_body_entered(body: Node2D) -> void:
	if body == Global.Player and $"..".CurSubRoom == null:
		await Event.take_control(true, true)
		if ToSubarea != null: ToSubarea.transition()
		await Global.Player.go_to(global_position  + Vector2(0, -12), false, true, Vector2.UP, 4)
		print("a")
		Event.give_control(false)

func _on_body_exited(body: Node2D) -> void:
	if body == Global.Player and to_local(Global.Player.position).y > 0 and $"..".CurSubRoom == ToSubarea:
		await Event.take_control(true, true)
		if ToSubarea != null: ToSubarea.detransition()
		await Global.Player.go_to(global_position + Vector2(0, 12), false, true, Vector2.DOWN, 4)
		Event.give_control(false)
