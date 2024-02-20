extends Area2D
class_name Stair

@export_flags_2d_physics var LayersUp := 1
@export_flags_2d_physics var LayersDown := 1
@export var zUp := 0
@export var zDown := 0
@export var Swap := false

func _on_body_entered(body: Node2D) -> void:
	#print(body)
	if body.name == "Finder":
		var dir : Vector2 = to_local(Global.Player.global_position)
		dir.x = 0
		dir = Global.get_direction(dir)
		if Swap: dir *= -1
		if dir == Vector2.UP:
			go_up()
		elif dir == Vector2.DOWN:
			go_down()

func _on_body_exited(body: Node2D) -> void:
	if body.name == "Finder": _on_body_entered(body)

func go_up():
	Global.Player.collision_layer = LayersUp
	Global.Player.collision_mask = LayersUp
	Global.Player.z_index = zUp

func go_down():
	Global.Player.collision_layer = LayersDown
	Global.Player.collision_mask = LayersDown
	Global.Player.z_index = zDown
