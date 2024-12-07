extends Area2D
class_name Stair

@export_flags_2d_physics var LayersUp := 1
@export_flags_2d_physics var LayersDown := 1
@export var zUp := 0
@export var zDown := 0
@export var Swap := false
@export var left_right_mode := false

#func _ready() -> void:
	#body_entered.connect(_on_body_entered)
	#body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	print(body.name)
	if body is NPC:
		var dir : Vector2 = to_local(body.global_position)
		if left_right_mode: dir.y = 0 
		else: dir.x = 0
		dir = Global.get_direction(dir)
		if Swap: dir *= -1
		print(body.name, " entered staircase ", name, " going ", dir)
		if left_right_mode:
			if dir == Vector2.RIGHT:
				go_up()
			elif dir == Vector2.LEFT:
				go_down()
		else:
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
