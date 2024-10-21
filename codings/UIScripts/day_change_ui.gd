extends CanvasLayer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	await Event.wait(0.5, false)
	Loader.detransition()
	$DayCurrent.text = str(Event.Day)
	$Buttons/NextDay.grab_focus()

func _on_next_day_pressed() -> void:
	Global.confirm_sound()
	$Buttons.hide()
	Event.Day += 1
	Event.TimeOfDay = Event.TOD.MORNING
	$DayCurrent.text = str(Event.Day)
	Global.check_party.emit()
	await Event.wait(2, false)
	Event.next_day.emit()
	queue_free()

func _on_options_pressed() -> void:
	Global.confirm_sound()
	Global.options()

func _on_quit_pressed() -> void:
	Global.confirm_sound()
	Global.quit()

func _cursor() -> void:
	Global.cursor_sound()
