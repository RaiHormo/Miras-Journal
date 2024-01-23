extends CanvasLayer

func _ready() -> void:
	$BoxContainer/Toast.modulate.a = 0
	var t = create_tween()
	t.tween_property($BoxContainer/Toast, "modulate:a", 1, 0.3)
	await Event.wait(2, false)
	t= create_tween()
	t.tween_property($BoxContainer/Toast, "modulate:a", 0, 1)
	await t.finished
	queue_free()
