extends CanvasLayer

func _ready():
	if Global.device == "Touch": return
	call(Event.tutorial)
	$Border2.hide()
	$Border2/Control/Next.icon = Global.get_controller().ConfirmIcon

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
	%Text.text = "[center]Jump over obstacles by dashing through them.[/center]"
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
	Loader.save()
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

func ability():
	await Event.wait(0.1, false)
	Global.Bt.focus_cam(Global.Party.Leader)
	$Border2.show()
	$Border2/Control/Arrow.hide()
	$Border2.position = Vector2(50, 201)
	$Border2/Control/Next.hide()
	$Border2/Text.text = "Press [img]" + (Global.get_controller().AbilityIcon).resource_path + "[/img] to use a magic Ability."
	await Global.Bt.get_node("BattleUI").ability
	queue_free()

func aura1():
	await Event.wait(0.5, false)
	$Border2.show()
	$Border2.position = Vector2(290, 15)
	$Border2/Text.text = Global.colorize("This is the AP meter.")
	await await_next()
	$Border2/Text.text = Global.colorize("It represents how much power Mira currently has.")
	await await_next()
	$Border2/Text.text = Global.colorize("This meter will be drained whenever a magic Ability is used.")
	await await_next()
	Global.Bt.lock_turn = false
	queue_free()

func aura2():
	await Event.wait(1, false)
	Global.Bt.focus_cam(Global.Party.Leader)
	$Border2.show()
	$Border2/Control/Arrow.hide()
	$Border2.position = Vector2(612, 201)
	$Border2/Text.text = "Looks like the enemy is preparing to attack again."
	await await_next()
	$Border2/Control/Arrow.show()
	$Border2.position = Vector2(290, 15)
	$Border2/Text.text = "Mira's AP is also pretty low right now."
	await await_next()
	$Border2/Control/Arrow.hide()
	$Border2.position = Vector2(104, 279)
	$Border2/Text.text = Global.colorize("Using her Aura Guard ability, Mira will take less damage, while increasing her AP when hit.").replace("guard", "Guard")
	await await_next()
	Global.Bt.lock_turn = false
	queue_free()

func aura3():
	await Event.wait(1, false)
	Global.Bt.focus_cam(Global.Party.Leader)
	$Border2.show()
	$Border2/Control/Arrow.hide()
	$Border2/Control/Arrow.hide()
	$Border2.position = Vector2(104, 279)
	$Border2/Text.text = "Using weapon attacks will also give some AP."
	await await_next()
	$Border2/Text.text = "So go on and finish off this enemy!"
	await await_next()
	Global.Bt.lock_turn = false
	queue_free()

func await_input(input:= "DialogNext"):
	while Input.is_action_pressed(input): await Event.wait()
	while not Input.is_action_pressed(input): await Event.wait()
	Global.confirm_sound()

func await_next():
	print("boing")
	await $Border2/Control/Next.pressed
	print("boing2")
	Global.confirm_sound()

func close():
	var t= create_tween()
	t.set_parallel()
	t.set_ease(Tween.EASE_OUT)
	t.set_trans(Tween.TRANS_QUART)
	t.tween_property($Border1, "position", Vector2(-200, 622), 0.3)
	t.tween_property($Border1, "modulate", Color.TRANSPARENT, 0.3)
	await t.finished
