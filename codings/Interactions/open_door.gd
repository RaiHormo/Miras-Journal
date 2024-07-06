extends Area2D

@export var Dir: Vector2
@export var ToSubarea: SubRoom = null

func _on_body_entered(body: Node2D) -> void:
	if body == Global.Player and Global.get_direction() == Dir:
		if ToSubarea != null:
			ToSubarea.transition()

func _on_body_exited(body: Node2D) -> void:
	if body == Global.Player and Global.get_direction(to_local(Global.Player.position)) == Dir*-1:
		ToSubarea.detransition()
