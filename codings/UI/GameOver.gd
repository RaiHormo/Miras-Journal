extends CanvasLayer

func _ready() -> void:
	Loader.InBattle = false
	Global.Bt.queue_free()
	Global.Area.queue_free()
	get_viewport().gui_focus_changed.connect(focus)
	$Options/Retry.grab_focus()

func retry() -> void:
	Loader.load_game()
	queue_free()

func _load() -> void:
	Global.options()
	queue_free()

func _quit() -> void:
	Global.quit()

func focus(control):
	Global.cursor_sound()

func _on_button_pressed() -> void:
	print("jidi")
