extends Area2D
@export var angle: float = 0.75


func _physics_process(delta: float) -> void:
	for body in get_overlapping_bodies():
		if body is NPC:
			if body.facing.is_horizontal():
				if body.direction.x < 0:
					body.position.y += angle
				elif body.direction.x > 0:
					body.position.y -= angle
