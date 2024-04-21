extends CanvasLayer

func _ready():
	if Global.device == "Touch": return
	call(Event.tutorial)
	$Border2.hide()

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
	await Event.wait(2)
	while not Input.is_action_pressed("MainMenu"):
		await Event.wait()
		if Global.Controllable == false: break
	await close()
	queue_free()

func bag():
	%Text.text = "[center]Press [img]" + (Global.get_controller().Menu).resource_path + "[/img] to check your bag.[/center]"
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
	await Event.wait(0.5, false)
	$Border2.show()
	$Border2.position = Vector2(290, 15)
	$Border2/Text.text = Global.colorize("This is the Aura meter.")
	await await_input()
	$Border2/Text.text = Global.colorize("It represents how much power Mira currently has.")
	await await_input()
	$Border2/Text.text = Global.colorize("The Aura meter will be drained whenever a Magic Ability is used.")
	await await_input()
	Global.Bt.lock_turn = false
	queue_free()

func aura2():
	await Event.wait(1, false)
	Global.Bt.focus_cam(Global.Party.Leader)
	$Border2.show()
	$Border2/Control/Arrow.hide()
	$Border2.position = Vector2(612, 201)
	$Border2/Text.text = "Looks like the enemy is preparing to attack again."
	await await_input()
	$Border2/Control/Arrow.show()
	$Border2.position = Vector2(290, 15)
	$Border2/Text.text = "Mira's Aura meter is also pretty low right now."
	await await_input()
	$Border2/Control/Arrow.hide()
	$Border2.position = Vector2(104, 279)
	$Border2/Text.text = Global.colorize("Using her guard ability, Mira will take less damage, while powering up her Aura when hit.").replace("guard", "Guard")
	await await_input()
	Global.Bt.lock_turn = false
	queue_free()

func aura3():
	await Event.wait(1, false)
	Global.Bt.focus_cam(Global.Party.Leader)
	$Border2.show()
	$Border2/Control/Arrow.hide()
	$Border2/Control/Arrow.hide()
	$Border2.position = Vector2(104, 279)
	$Border2/Text.text = "Using weapon attacks will also power up the Aura slightly."
	await await_input()
	$Border2/Text.text = "So go on and finish off this enemy!"
	await await_input()
	Global.Bt.lock_turn = false
	queue_free()


func await_input():
	await Event.wait(0.5, false)
	while not Input.is_action_pressed("ui_accept"): await Event.wait()
	Global.confirm_sound()

func close():
	var t= create_tween()
	t.set_parallel()
	t.set_ease(Tween.EASE_OUT)
	t.set_trans(Tween.TRANS_QUART)
	t.tween_property($Border1, "position", Vector2(-200, 622), 0.3)
	t.tween_property($Border1, "modulate", Color.TRANSPARENT, 0.3)
	await t.finished
