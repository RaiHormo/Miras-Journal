extends Node

func _ready() -> void:
	PartyUI.disabled = true
	if not OS.is_debug_build() or Global.ProcessFrame != 0:
		if FileAccess.file_exists("user://Autosave.tres"):
			await Global.textbox("testbush", "welcome_back")
		else:
			print("No save detected, starting new game")
			await Global.textbox("testbush", "prototype_message")
			Global.new_game()
	else:
		print("Debug mode initialized, traveling to the debug room")
		await Loader.travel_to("Debug", Vector2.ZERO, 0, -1, "")
		PartyUI.disabled = false
		PartyUI.visible = true

