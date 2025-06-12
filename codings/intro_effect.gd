extends CanvasLayer

var pos_ref: Vector2

func animate():
	$Sprite.position =  pos_ref
	$Sprite.play("Hit")
	#var t = create_tween().set_ease(Tween.EASE_OUT)
	#t.tween_property($Sprite, "rotation_degrees", 15, 1).from(0)
	await Event.wait(3)
	queue_free()
