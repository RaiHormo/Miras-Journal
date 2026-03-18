extends CanvasLayer

func _ready() -> void:
	$BoxContainer.modulate.a = 0
	var t = create_tween()
	t.set_parallel()
	t.set_ease(Tween.EASE_OUT)
	t.set_trans(Tween.TRANS_BACK)
	t.tween_property($BoxContainer, "scale", Vector2(1, 1), 0.2).from(Vector2(0.1, 0.8))
	t.tween_property($BoxContainer, "modulate:a", 1, 0.2)
	await Event.wait(3, false)
	t= create_tween()
	t.set_parallel()
	t.set_ease(Tween.EASE_IN)
	t.set_trans(Tween.TRANS_BACK)
	t.tween_property($BoxContainer, "modulate:a", 0, 0.5)
	t.tween_property($BoxContainer, "scale", Vector2(0.3, 0.8), 0.2).set_delay(0.3)
	await t.finished
	queue_free()
