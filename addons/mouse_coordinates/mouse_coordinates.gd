@tool
extends EditorPlugin

const BREAK_PERIOD := 500

var config: Object

var int_component: CenterContainer
var save_component: CenterContainer
var local_component: CenterContainer
var position_component: Label

var root_node: Node
var selection: EditorSelection

var _pos := Vector2(0.0, 0.0)
var _is_integer := false
var _is_save := false
var _is_local := false
var _local_pos := Vector2(0.0, 0.0)
var _last_move_time := 0.0
var _last_display_flag := true
var cur_pos: Vector2i = Vector2.ZERO

func _enter_tree():
	config = preload("res://addons/mouse_coordinates/config.gd").new()

	int_component = preload("res://addons/mouse_coordinates/button/int.tscn").instantiate()
	save_component = preload("res://addons/mouse_coordinates/button/save.tscn").instantiate()
	local_component = preload("res://addons/mouse_coordinates/button/local.tscn").instantiate()
	position_component = preload("res://addons/mouse_coordinates/position.tscn").instantiate()

	add_control_to_container(CONTAINER_CANVAS_EDITOR_MENU, int_component)
	add_control_to_container(CONTAINER_CANVAS_EDITOR_MENU, save_component)
	add_control_to_container(CONTAINER_CANVAS_EDITOR_MENU, local_component)
	add_control_to_container(CONTAINER_CANVAS_EDITOR_MENU, position_component)

	root_node = get_editor_interface().get_edited_scene_root()
	scene_changed.connect(func(_new_root_node: Node): root_node = get_editor_interface().get_edited_scene_root())

	selection = get_editor_interface().get_selection()
	#selection.selection_changed.connect(_on_selection_changed)

	int_component.find_child("Int").toggled.connect(_on_int_toggled)
	save_component.find_child("Save").toggled.connect(_on_save_toggled)
	local_component.find_child("Local").toggled.connect(_on_local_toggled)

	_is_integer = config.get_val("Int") or false
	_is_save = config.get_val("Save") or false
	_is_local = config.get_val("Local") or false

	int_component.find_child("Int").button_pressed = _is_integer
	save_component.find_child("Save").button_pressed = _is_save
	local_component.find_child("Local").button_pressed = _is_local

	_update_local_pos()
	_update_position_component()


func _exit_tree():
	remove_control_from_container(CONTAINER_CANVAS_EDITOR_MENU, int_component)
	remove_control_from_container(CONTAINER_CANVAS_EDITOR_MENU, save_component)
	remove_control_from_container(CONTAINER_CANVAS_EDITOR_MENU, local_component)
	remove_control_from_container(CONTAINER_CANVAS_EDITOR_MENU, position_component)

	int_component.queue_free()
	save_component.queue_free()
	local_component.queue_free()
	position_component.queue_free()


func _process(_delta) -> void:
	if _is_save and not _last_display_flag and Time.get_ticks_msec() - _last_move_time >= BREAK_PERIOD:
		_update_position_component()
		_last_display_flag = true


func _input(event: InputEvent):
	if not is_instance_valid(root_node) or not root_node.has_method("get_global_mouse_position"):
		return

	_pos = root_node.get_global_mouse_position()

	if not _is_save:
		_update_position_component()

	_last_move_time = Time.get_ticks_msec()
	_last_display_flag = false


func _on_int_toggled(status: bool) -> void:
	_is_integer = status

	_update_position_component()

	config.set_val("Int", status)


func _on_save_toggled(status: bool) -> void:
	_is_save = status

	config.set_val("Save", status)


func _on_local_toggled(status: bool) -> void:
	_is_local = status

	_update_position_component()

	config.set_val("Local", status)


func _on_selection_changed() -> void:
	_update_local_pos()

	_update_position_component()


func _update_local_pos() -> void:
	var selected = selection.get_selected_nodes()

	if selected.size() > 0:
		_local_pos = selected[0].position


func _update_position_component() -> void:
	var calculated_pos := (_pos - _local_pos) if _is_local else _pos

	if _is_integer:
		position_component.text = str(Vector2i(int(calculated_pos.x), int(calculated_pos.y)))
	else:
		position_component.text = str(calculated_pos)
	cur_pos = Vector2i(calculated_pos)

func _shortcut_input(event: InputEvent) -> void:
	if Input.is_key_pressed(KEY_C) and Input.is_key_pressed(KEY_SHIFT) and cur_pos != Vector2i.ZERO:
		DisplayServer.clipboard_set(str(cur_pos))
