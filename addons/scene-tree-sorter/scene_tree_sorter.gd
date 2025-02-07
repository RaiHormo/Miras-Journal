@tool
extends EditorPlugin


const PLUGIN_NAME := "Sort Scene Tree";

var scene: Node


func _enter_tree() -> void:
	add_tool_menu_item(PLUGIN_NAME, _do_work)


func _exit_tree() -> void:
	remove_tool_menu_item(PLUGIN_NAME)


func _do_work() -> void:
	scene = get_editor_interface().get_edited_scene_root()

	assert(scene)
	_sort_children(scene)
	get_editor_interface().save_scene()

	scene = null


func _sort_children(parent: Node):
	var children := parent.get_children()

	var splited_array := _split_array_by_type_truncated(children)
	children = []

	for array in splited_array:
		array.sort_custom(_sort_by_class_name)
		array.sort_custom(_sort_by_name)
		array.sort_custom(_priority_sort)
		children.append_array(array)

	for i in children.size():
		var child: Node = children[i]

		if (String(child.name)[0] != "_"
			and (
				(not parent is Container)
				or (not child is Control)
			)
		):
			parent.move_child(child, i)

		if (child.scene_file_path == ""
			and child.get_child_count() > 0
		):
			_sort_children(child)


func _priority_sort(a: Node, b: Node) -> bool:
	if a is TileMapLayer and not b is TileMapLayer:
		return true
	elif "Light" in a.name or "Cover" in a.name and b is not TileMapLayer: return true
	else: return a.name.to_lower() < b.name.to_lower()


func _sort_by_name(a: Node, b: Node) -> bool:
	return a.name.to_lower() < b.name.to_lower()


func _sort_by_class_name(a: Node, b: Node) -> bool:
	return a.get_class() < b.get_class()


func _sort_by_class_name_truncated(a: Node, b: Node) -> bool:
	return _truncate_class(a) < _truncate_class(b)

func _truncate_class(a: Node) -> String:
	return (
			"Control" if a is Control
			else "Node2D" if a is Node2D
			else "Node3D" if a is Node3D
			else a.get_class()
	)


func _split_array_by_type_truncated(array: Array) -> Array[Array]:
	array.sort_custom(_sort_by_class_name_truncated)

	var final_array: Array[Array]
	var index: int = 0

	for i in array.size():
		if i == array.size() - 1:
			break

		var node_current: Node = array[i]
		var node_next: Node = array[i + 1]

		if _sort_by_class_name_truncated(node_current, node_next):
			final_array.append(array.slice(index, i + 1))
			index = i + 1

	final_array.append(array.slice(index, array.size()))

	return final_array
