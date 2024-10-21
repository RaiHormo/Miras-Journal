extends CanvasLayer
@onready var label: Label = $Label

func _ready() -> void:
	label.modulate = Color.TRANSPARENT
	var t = create_tween()
	t.set_parallel()
	t.set_ease(Tween.EASE_IN_OUT)
	t.set_trans(Tween.TRANS_QUART)
	t.tween_property(label, "modulate", Color.WHITE, 1)
	t.tween_property(label, "scale", Vector2.ONE, 1).from(Vector2(1.1, 1.1))
	await t.finished
	t = create_tween()
	t.tween_property(label, "scale", Vector2(0.9, 0.9), 5)
	await Event.wait(3)
	t = create_tween()
	t.tween_property(label, "modulate", Color.TRANSPARENT, 2)
	await t.finished
	queue_free()
