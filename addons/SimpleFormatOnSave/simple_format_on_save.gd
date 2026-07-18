@tool
extends EditorPlugin

var FORMAT_ACTION := "simple_format_on_save/format_code"
var format_key: InputEventKey
var formatter: Formatter


func _enter_tree():
	add_tool_menu_item("Format (Ctrl+Alt+L)", _on_format_code)

	if InputMap.has_action(FORMAT_ACTION):
		InputMap.erase_action(FORMAT_ACTION)

	InputMap.add_action(FORMAT_ACTION)
	format_key = InputEventKey.new()
	format_key.keycode = KEY_L
	format_key.ctrl_pressed = true
	format_key.alt_pressed = true
	InputMap.action_add_event(FORMAT_ACTION, format_key)
	resource_saved.connect(on_resource_saved)


func _exit_tree():
	remove_tool_menu_item("Format (Ctrl+Alt+L)")
	InputMap.erase_action(FORMAT_ACTION)
	resource_saved.disconnect(on_resource_saved)


# Return true if formatted code != original code
func _on_format_code() -> bool:
	var current_editor := EditorInterface.get_script_editor().get_current_editor()

	if not (current_editor and current_editor.is_class("ScriptTextEditor")):
		return false

	var text_edit = current_editor.get_base_editor()
	var code = text_edit.text

	if not formatter:
		formatter = Formatter.new()

	var formatted_code = formatter.format_code(code)

	if not formatted_code:
		return false

	if code.length() == formatted_code.length() and code == formatted_code:
		return false

	var scroll_horizontal = text_edit.scroll_horizontal
	var scroll_vertical = text_edit.scroll_vertical
	var caret_column = text_edit.get_caret_column(0)
	var caret_line = text_edit.get_caret_line(0)

	text_edit.text = formatted_code
	text_edit.set_caret_line(caret_line)
	text_edit.set_caret_column(caret_column)
	text_edit.scroll_horizontal = scroll_horizontal
	text_edit.scroll_vertical = scroll_vertical

	return true


func _shortcut_input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_pressed():
		if Input.is_action_pressed(FORMAT_ACTION):
			_on_format_code()


# CALLED WHEN A SCRIPT IS SAVED
func on_resource_saved(resource: Resource):
	if resource is Script:
		var script: Script = resource
		var current_script = get_editor_interface().get_script_editor().get_current_script()

		# Prevents other unsaved scripts from overwriting the active one
		if current_script == script:
			var is_modified: bool = _on_format_code()

			#if is_modified:
				#print_rich("[color=#636363]Auto formatted code[/color]")
