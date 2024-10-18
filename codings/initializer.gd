extends Node

func _ready() -> void:
	$Splash.show()
	$TitleScreen.hide()
	glyph_update()
	PartyUI.disabled = true
	Global.controller_changed.connect(glyph_update)
	if FileAccess.file_exists("user://Autosave.tres"):
		await Loader.load_game("Autosave", false, false, false, false)
		$TitleScreen.show()
	else: Global.new_game()
	PartyUI.disabled = false
	PartyUI.visible = true

func _on_continue_pressed() -> void:
	dismiss_title()
	Event.give_control()
	get_tree().paused = false

func _on_options_pressed() -> void:
	Global.options()
	dismiss_title()

func dismiss_title():
	Global.confirm_sound()
	$Splash.hide()
	$TitleScreen.hide()
	Loader.detransition()
	queue_free()

func glyph_update():
	$TitleScreen/Continue.icon = Global.get_controller().ConfirmIcon
	$TitleScreen/Options.icon = Global.get_controller().Start
