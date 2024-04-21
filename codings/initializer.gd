extends Node

func _ready() -> void:
	PartyUI.disabled = true
	if FileAccess.file_exists("user://Autosave.tres"):
		await Loader.load_game("Autosave", false, false, false)
	else: Global.new_game()
	PartyUI.disabled = false
	PartyUI.visible = true
