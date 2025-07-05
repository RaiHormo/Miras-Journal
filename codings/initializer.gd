extends Node
var game_exists = false

func _ready() -> void:
	#$TitleScreen.hide()
	$TitleScreen/Error.show()
	$TitleScreen/Error/Hint.text = "Hint: Ready"
	print("Game Started!")
	glyph_update()
	$TitleScreen/Error/Hint.text = "Hint: Glyph"
	Event.Flags.append("DisableMenus")
	#Global.controller_changed.connect(glyph_update)
	if FileAccess.file_exists("user://Autosave.tres"):
		game_exists = true
	else:
		game_exists = false
		$TitleScreen/Continue.text = "New game"
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

func _on_continue_pressed() -> void:
	if get_tree().root.has_node("Options"): return
	dismiss_title()
	if game_exists:
		await Loader.load_game("Autosave")
		Event.give_control(false)
		get_tree().paused = false
	else:
		Global.new_game()

func _on_options_pressed() -> void:
	if get_tree().root.has_node("Options"): return
	Global.options()
	#dismiss_title()

func dismiss_title():
	$TitleScreen.hide()
	#Loader.detransition()
	queue_free()

func glyph_update():
	$TitleScreen/Continue.icon = Global.get_controller().ConfirmIcon
	$TitleScreen/Options.icon = Global.get_controller().Start
