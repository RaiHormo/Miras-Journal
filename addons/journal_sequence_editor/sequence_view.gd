@tool
extends EditorDock
class_name SequenceView

var plugin: EditorPlugin
var start_node: GraphNode
var nodes: Dictionary[int, GraphNode]
var current_file: SequenceGraph
var elements: Dictionary[StringName, GraphNode]

@onready var insert_button: MenuButton = %Insert
@onready var graph: GraphEdit = %GraphEdit
@onready var file_name: Label = %FileName
@onready var save_dialog: EditorFileDialog = %SaveDialog


func _ready() -> void:
	apply_icons(self)

	file_name.text = ""
	save_dialog.hide()
	%GraphElements.hide()
	for i in %GraphElements.get_children():
		elements.set(i.name, i)

	var insert_popup := insert_button.get_popup()
	insert_popup.id_pressed.connect(_on_insert_pressed)

	var count := 0
	insert_button.get_popup().clear(true)
	for i in elements.keys():
		var element := elements[i]
		insert_popup.add_item(element.title, count)
		element.set_meta("insert_id", count)
		count += 1

	graph.connection_request.connect(_graph_connection_request)
	graph.disconnection_request.connect(_graph_disconnection_request)


func insert(type: StringName) -> GraphNode:
	var dub := elements[type].duplicate()
	dub.set_meta(&"Type", type)
	dub.name += str(randi())
	graph.add_child(dub)

	# Determine the exact middle pixel of the GraphEdit container control
	var target_screen_center := graph.size / 2.0

	# Let GraphEdit translate screen pixels to zoomed canvas space automatically
	# This bypasses dividing by zoom variables that trigger the internal C++ error
	var clean_canvas_pos := (target_screen_center + graph.scroll_offset)

	if graph.zoom > 0.0:
		clean_canvas_pos /= graph.zoom

	dub.position_offset = clean_canvas_pos - (dub.size / 2.0)

	return dub


func apply_icons(node: Control):
	for i in node.get_children():
		if i.has_meta(&"Icon"):
			if i is Button:
				i.icon = EditorInterface.get_base_control().get_theme_icon(i.get_meta("Icon"), "EditorIcons")
		elif i.get_child_count() != 0:
			apply_icons(i)


func open_from_path(path: String) -> void:
	if ResourceLoader.exists(path):
		open_file(ResourceLoader.load(path))


func open_file(file: SequenceGraph) -> void:
	clear()
	current_file = file
	file_name.text = file.resource_path.get_file()

	for i in file.nodes:
		var node := insert(i.type)
		node.name = i.id
		node.position_offset = i.position

	for conn in current_file.connections:
		graph.connect_node(
			conn["from_node"],
			conn["from_port"],
			conn["to_node"],
			conn["to_port"]
		)

	if plugin:
		plugin.queue_save_layout()


func save() -> void:
	var resource_path := current_file.resource_path

	current_file.connections = graph.connections.duplicate(true)
	current_file.nodes.clear()
	for node in graph.get_children():
		if node is GraphNode:
			var node_data = SequenceGraphNode.new()
			node_data.id = node.name

			# Fallback to the title or a default string if the Type metadata is missing/empty
			var saved_type: String = node.get_meta(&"Type", "")

			if saved_type.is_empty():
				saved_type = String(node.title)

			node_data.type = saved_type

			node_data.position = node.position_offset
			current_file.nodes.append(node_data)

	current_file.resource_path = resource_path

	if ResourceSaver.save(current_file) == OK:
		print("Saved sequence to ", resource_path)
	else:
		printerr("Error saving ", resource_path)


func new_file(path: String) -> void:
	if ResourceLoader.exists(path):
		pass

	clear()
	current_file = SequenceGraph.new()
	current_file.resource_path = path
	print("Creating new file")

	start_node = insert("StartSingle")
	insert("EndTurn")
	save()


func clear() -> void:
	nodes.clear()
	graph.clear_connections()
	for i in graph.get_children().duplicate():
		if i is GraphNode:
			i.queue_free()


func _graph_connection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	graph.connect_node(from_node, from_port, to_node, to_port)
	save()
	if plugin:
		plugin.queue_save_layout()


func _graph_disconnection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	graph.disconnect_node(from_node, from_port, to_node, to_port)
	save()
	if plugin:
		plugin.queue_save_layout()


func _on_insert_pressed(id: int) -> void:
	for i in elements.values():
		if i.get_meta("insert_id") == id:
			insert(i.name)
			save()


func _on_reload_button_pressed() -> void:
	var interface := EditorInterface
	interface.set_plugin_enabled("journal_sequence_editor", false)
	queue_free()
	interface.set_plugin_enabled("journal_sequence_editor", true)
	plugin._make_visible(true)

	print("Sequence plugin reloaded")


func _on_open_pressed() -> void:
	EditorInterface.popup_quick_open(open_from_path, [&"SequenceGraph"])


func _on_new_pressed() -> void:
	save_dialog.popup_file_dialog()


func _on_save_dialog_confirmed() -> void:
	new_file(save_dialog.current_path)


func _on_graph_edit_delete_nodes_request(nodes_to_delete: Array[StringName]) -> void:
	# 1. Disconnect any lines attached to the nodes being deleted
	for connection in graph.connections:
		if connection["from_node"] in nodes_to_delete or connection["to_node"] in nodes_to_delete:
			graph.disconnect_node(connection["from_node"], connection["from_port"], connection["to_node"], connection["to_port"])

	# 2. Free the nodes from memory
	for node_name in nodes_to_delete:
		var node := graph.get_node(String(node_name))
		node.queue_free()

	# 3. Update your save file
	save()
