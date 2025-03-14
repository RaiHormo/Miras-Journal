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
	print(body.get_class())
	if body is NPC:
		var dir : Vector2 = to_local(body.position)
		go(dir)

func go(dir: Vector2):
	if Swap: dir *= -1
	if left_right_mode:
		dir.y = 0
		dir = Global.get_direction(dir)
		if dir == Vector2.RIGHT:
			go_up()
		elif dir == Vector2.LEFT:
			go_down()
	else:
		dir.x = 0
		dir = Global.get_direction(dir)
		if dir == Vector2.UP:
			go_up()
		elif dir == Vector2.DOWN:
			go_down()
	print("entered staircase ", name, " going ", dir)

func _on_body_exited(body: Node2D) -> void:
	if body is NPC:
		var dir : Vector2 = to_local(body.position)
		go(dir*-1)

func go_up():
	Global.Player.collision_layer = LayersUp
	Global.Player.collision_mask = LayersUp
	Global.Player.z_index = zUp

func go_down():
	Global.Player.collision_layer = LayersDown
	Global.Player.collision_mask = LayersDown
	Global.Player.z_index = zDown
