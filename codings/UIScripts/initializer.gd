extends Node
var game_exists = false
var inactive := false
var focused := 0


func _ready() -> void:
	#$TitleScreen.hide()
	$TitleScreen/Error.show()
	$TitleScreen/Error/Hint.text = "Hint: Ready"
	print("Game Started!")
	glyph_update()
	$TitleScreen/Error/Hint.text = "Hint: Glyph"
	Event.add_flag("DisableMenus")
	#Global.controller_changed.connect(glyph_update)
	if FileAccess.file_exists("user://Autosave.tres"):
		game_exists = true
	else:
		game_exists = false
		$TitleScreen/Menu/Continue.text = "New game"
	$TitleScreen/Error/Hint.text = "Hint: File check"
	$TitleScreen.show()
	$TitleScreen/Splash.show()
	var t = create_tween().set_ease(Tween.EASE_IN).set_parallel().set_trans(Tween.TRANS_CUBIC)
	t.tween_property($TitleScreen/Splash, "modulate", Color.TRANSPARENT, 0.3).from(Color.WHITE).set_delay(0.3)
	#t.tween_property($TitleScreen/Splash, "scale", Vector2(0.6, 0.6), 0.3).set_delay(0.3)
	$TitleScreen/Label.text += ProjectSettings.get_setting("application/config/version")
	PartyUI.disabled = false
	PartyUI.visible = true
	$TitleScreen/Error/Hint.text = "Hint: Should have been fine"
	$TitleScreen/Error.hide()
	get_viewport().get_window().grab_focus()
	if game_exists:
		focus()
	else: _on_continue_pressed()


func focus():
	$TitleScreen/Menu.get_child(focused).grab_focus()
	get_window().grab_focus()


func _on_continue_pressed() -> void:
	if inactive: return
	inactive = true
	if get_tree().root.has_node("Options"): return
	if Input.is_action_pressed("LeftTrigger"):
		you_can_now_play_as("Asteria")
	await Loader.load_game("Autosave")
	dismiss_title()
	Event.give_control(false)
	get_tree().paused = false


func _input(event: InputEvent) -> void:
	glyph_update()
	if Input.is_action_just_pressed("ui_up") or Input.is_action_just_pressed("ui_down") and get_viewport().gui_get_focus_owner().get_parent() == $TitleScreen/Menu:
		Global.cursor_sound()
		await get_tree().physics_frame
		focused = get_viewport().gui_get_focus_owner().get_index()


func _on_options_pressed() -> void:
	if inactive: return
	if get_tree().root.has_node("Options"): return
	Global.options()
	#dismiss_title()


func dismiss_title():
	$TitleScreen.hide()
	#Loader.detransition()
	queue_free()


func glyph_update():
	#$TitleScreen/Continue.icon = Global.get_controller().ConfirmIcon
	$TitleScreen/Options.icon = Global.get_controller().Start


func you_can_now_play_as(chara: String):
	var data: SaveFile = load("user://Autosave.tres")
	if chara in data.Party:
		data.Party[data.Party.find(chara)] = "Mira"
	data.Party[0] = chara
	for i in data.Members:
		if i.get("codename") == chara: i.set("Controllable", true)
	ResourceSaver.save(data, "user://Autosave.tres")
	Global.warning("You can now play as [img height=64]res://art/Icons/Party/" + chara + ".png[/img] " + chara + ".", "CONGRATS", ["A"])


func _on_load_pressed() -> void:
	if inactive: return
	if get_tree().root.has_node("Options"): return
	Global.options(1)


func _on_new_pressed() -> void:
	Global.confirm_sound()
	if not game_exists or await Global.warning("Start a new game? Any Autosave data will be overwritten, so make sure to save it into a new file if you want to keep it.", "NEW GAME", ["Cancel", "Start New Game"]):
		dismiss_title()
		Event.sequence("new_game")
	else:
		focus()
