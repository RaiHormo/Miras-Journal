extends Node
var game_exists = false

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
	t.tween_property($TitleScreen/Splash, "modulate", Color.TRANSPARENT, 0.2).from(Color.WHITE).set_delay(0.3)
	t.tween_property($TitleScreen/Splash, "scale", Vector2(0.6, 0.6), 0.3).set_delay(0.3)
	$TitleScreen/Label.text += ProjectSettings.get_setting("application/config/version")
	PartyUI.disabled = false
	PartyUI.visible = true
	$TitleScreen/Error/Hint.text = "Hint: Should have been fine"
	$TitleScreen/Error.hide()
	if game_exists:
		focus()
	else: _on_continue_pressed()
	

func focus():
	$TitleScreen/Menu/Continue.grab_focus()
	get_window().grab_focus()

func _on_continue_pressed() -> void:
	if get_tree().root.has_node("Options"): return
	dismiss_title()
	if game_exists:
		if Input.is_action_pressed("ShoulderLeft"):
			you_can_now_play_as("Asteria")
		await Loader.load_game("Autosave")
		Event.give_control(false)
		get_tree().paused = false
	else:
		Event.sequence("new_game")

func _input(event: InputEvent) -> void:
	glyph_update()
	if Input.is_action_just_pressed("ui_up") or Input.is_action_just_pressed("ui_down") and get_viewport().gui_get_focus_owner().get_parent() == $TitleScreen/Menu:
		Global.cursor_sound() 

func _on_options_pressed() -> void:
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
	Global.warning("You can now play as [img height=64]res://art/Icons/Party/"+chara+".png[/img] "+chara+".", "CONGRATS", ["A"])


func _on_load_pressed() -> void:
	if get_tree().root.has_node("Options"): return
	Global.options(1)
