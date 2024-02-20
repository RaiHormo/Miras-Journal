extends Area2D

func _on_body_entered(body: Node2D) -> void:
	if body is NPC: body.shade()

func _on_body_exited(body: Node2D) -> void:
	if body is NPC: body.unshade()
