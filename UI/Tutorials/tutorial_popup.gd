extends CanvasLayer

func _ready():
	if Global.device == "Touch": return
	call(Event.tutorial)

func pop_down():
	var t= create_tween()
	t.set_parallel()
	t.set_ease(Tween.EASE_OUT)
	t.set_trans(Tween.TRANS_QUART)
	t.tween_property($Border1, "position", Vector2(-33, 622), 0.3).from(Vector2(-200, 622))
	t.tween_property($Border1, "modulate", Color.WHITE, 0.3).from(Color.TRANSPARENT)
	await t.finished

func dash():
	%Text.text = "[center]Hold [img]" + (Global.get_controller().Dash).resource_path + "[/img] to dash.[/center]"
	await pop_down()
	while not Input.is_action_pressed("Dash"):
		await Event.wait()
	await Event.wait(3)
	await close()
	%Text.text = "[center]Dashing allows you to jump through obstacles with enough momentum.[/center]"
	await pop_down()
	await Event.wait(6)
	await close()
	queue_free()

func ov_attack():
	%Text.text = "[center]Press [img]" + (Global.get_controller().OVAttack).resource_path + "[/img] to to swing the axe.[/center]"
	await pop_down()
	while not Input.is_action_pressed("OVAttack"):
		await Event.wait()
	await Event.wait(3)
	await close()
	queue_free()

func walk():
	if Global.device == "Keyboard":
		%Text.text = "[center]Use the arrow keys to walk.[/center]"
	else: %Text.text = "[center]Use the left stick or D-Pad to walk.[/center]"
	await pop_down()
	await Event.wait(4)
	await close()
	queue_free()

func close():
	var t= create_tween()
	t.set_parallel()
	t.set_ease(Tween.EASE_OUT)
	t.set_trans(Tween.TRANS_QUART)
	t.tween_property($Border1, "position", Vector2(-200, 622), 0.3)
	t.tween_property($Border1, "modulate", Color.TRANSPARENT, 0.3)
	await t.finished
