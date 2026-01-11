extends LineEdit


func _gui_input(event: InputEvent) -> void:
	if event.is_action("ui_cancel"):
		get_viewport().set_input_as_handled()
