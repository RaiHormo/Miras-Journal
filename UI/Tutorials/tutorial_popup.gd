extends CanvasLayer

func _ready():
	if Global.device == "Touch": return
	call(Event.tutorial)


func pop_down():
	var t= create_tween()
	t.set_parallel()
	t.set_ease(Tween.EASE_OUT)
	t.set_trans(Tween.TRANS_QUART)
	t.tween_property($Border1, "position", Vector2(0, 622), 0.3).from(Vector2(-200, 622))
	t.tween_property($Border1, "modulate", Color.WHITE, 0.3).from(Color.TRANSPARENT)
	await t.finished

func dash():
	%Text.text = "[center]Hold [img]" + (Global.get_controller().Dash).resource_path + "[/img] to dash.[/center]"
	await pop_down()
	while not Input.is_action_pressed("Dash"):
		await Event.wait()
	await Event.wait(3)
	await close()
	%Text.text = "[center]By dashing you jump through obstacles.[/center]"
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

func party():
	%Text.text = "[center]Press [img]" + (Global.get_controller().Select).resource_path + "[/img] to check on your party.[/center]"
	await pop_down()
	while not Input.is_action_pressed("PartyMenu"):
		await Event.wait()
		if Global.Controllable == false: break
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

func aura1():
	await Event.wait(1, false)
	#$Fader.color = Color(0,0,0,0.5)
	Global.Bt.focus_cam(Global.Party.Leader)
	$Border2.show()
	$Border2.position = Vector2(290, 15)
	$Border2/Text.text = "This is the Aura meter."
	await await_input()
	$Border2/Text.text = Global.colorize("It will be drained whenever a Magic Ability is used.")
	await await_input()
	$Border2/Text.text = Global.colorize("One way to recover it is using Mira's guard ability, which will increase her Aura meter when hit.").replace("guard", "Guard")
	await await_input()
	Global.Bt.lock_turn = false
	queue_free()

func await_input():
	await Event.wait(0.5, false)
	while not Input.is_action_pressed("ui_accept"): await Event.wait()

func close():
	var t= create_tween()
	t.set_parallel()
	t.set_ease(Tween.EASE_OUT)
	t.set_trans(Tween.TRANS_QUART)
	t.tween_property($Border1, "position", Vector2(-200, 622), 0.3)
	t.tween_property($Border1, "modulate", Color.TRANSPARENT, 0.3)
	await t.finished
