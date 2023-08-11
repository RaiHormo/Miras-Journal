extends NPC

#func _ready():
#	speed = 10

func _physics_process(delta):
	move_dir(Vector2.RIGHT, 1)
	process_move()
