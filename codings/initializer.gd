extends Node
var game_exists = false

func _ready() -> void:
	$TitleScreen.hide()
	glyph_update()
	Event.Flags.append("DisableMenus")
	Global.controller_changed.connect(glyph_update)
	if FileAccess.file_exists("user://Autosave.tres"):
		game_exists = true
		Event.take_control()
	else:
		game_exists = false
		$TitleScreen/Continue.text = "New game"
		Loader.transition("")
	$TitleScreen.show()
	var t = create_tween()
	t.tween_property($TitleScreen/Splash, "modulate", Color.TRANSPARENT, 0.3).from(Color.WHITE).set_delay(0.1)
	$TitleScreen/Label.text += ProjectSettings.get_setting("application/config/version")
	PartyUI.disabled = false
	PartyUI.visible = true

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
