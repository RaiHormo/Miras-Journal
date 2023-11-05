extends SubViewportContainer

@onready var screen = $Screen

func zoom(factor:float, time:float = 0.3):
	var t = create_tween()
	t.set_ease(Tween.EASE_IN_OUT)
	t.set_trans(Tween.TRANS_QUART)
	t.tween_property(self, "scale", Vector2(factor*4, factor*4), time)

func _process(delta):
	if Global.get_cam() != null and Global.get_cam().zoom != Vector2.ONE:
		scale = Global.get_cam().zoom
		Global.get_cam().zoom = Vector2.ONE
