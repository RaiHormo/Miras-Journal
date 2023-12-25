extends CanvasLayer

func _ready():
	call(Event.tutorial)

func pop_down():
	var t= create_tween()
	t.set_parallel()
	t.tween_property($Border1, "position", Vector2(-33, 622), 0.3).from(Vector2(-200, 622))
	t.tween_property($Border1, "modulate", Color.WHITE, 0.3).from(Color.TRANSPARENT)

func dash():
	%Text.text = "Hold " + str(Global.get_controller().Dash) + " to dash."
	pop_down()
