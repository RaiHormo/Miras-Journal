extends LineEdit


func _gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		if event is InputEventKey:
			if Input.is_key_pressed(KEY_SHIFT):
				text += "X"
			else:
				text += "x"
		caret_column = 9999
	if event.is_action_pressed("ui_accept") and event is not InputEventKey:
		text_submitted.emit(text)
