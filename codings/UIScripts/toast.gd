extends CanvasLayer


func _ready() -> void:
	$BoxContainer.modulate.a = 0
	var t := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	t.tween_property($BoxContainer, "scale", Vector2(1, 1), 0.2).from(Vector2(0.1, 0.8))
	t.parallel().tween_property($BoxContainer, "modulate:a", 1, 0.2)
	t.tween_await(get_tree().create_timer(3).timeout)
	t.tween_property($BoxContainer, "modulate:a", 0, 0.3)
	t.parallel().tween_property($BoxContainer, "scale", Vector2(0.3, 0.8), 0.2)
	t.tween_callback(queue_free)
