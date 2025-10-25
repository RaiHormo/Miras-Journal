extends CanvasLayer

func _ready() -> void:
	Loader.InBattle = false
	if is_instance_valid(Global.Bt):
		Global.Bt.queue_free()
	if is_instance_valid(Global.Area):
		Global.Area.queue_free()
	PartyUI.disabled = true
	get_viewport().gui_focus_changed.connect(focus)
	$Options/Retry.grab_focus()

func retry() -> void:
	Loader.load_game()
	queue_free()

func _load() -> void:
	Global.options(1)
	queue_free()

func _quit() -> void:
	Global.quit()

func focus(control):
	Global.cursor_sound()
