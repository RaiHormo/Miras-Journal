extends Area2D

@export var Dir: Vector2 = Vector2.UP
@export var ToSubarea: SubRoom = null

func _on_body_entered(body: Node2D) -> void:
	if body == Global.Player and Global.get_direction() == Dir and $"..".CurSubRoom == null:
		await Event.take_control(true, true)
		if ToSubarea != null: ToSubarea.transition()
		await Global.Player.go_to(global_position  + Vector2(0, -12), false, true, Vector2.UP, 2)
		Event.give_control(false)

func _on_body_exited(body: Node2D) -> void:
	if body == Global.Player and Global.get_direction(to_local(Global.Player.position)) == Dir*-1 and $"..".CurSubRoom == ToSubarea:
		await Event.take_control(true, true)
		if ToSubarea != null: ToSubarea.detransition()
		await Global.Player.go_to(global_position + Vector2(0, 12), false, true, Vector2.DOWN, 2)
		Event.give_control(false)
