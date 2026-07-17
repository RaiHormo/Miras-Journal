@tool
extends EditorDock
class_name SequenceView

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


func insert(id: StringName) -> GraphNode:
	var dub := elements[id].duplicate()
	dub.set_meta(&"Type", dub.name)
	graph.add_child(dub)
	return dub


func apply_icons(node: Control):
	for i in node.get_children():
		if i.has_meta(&"Icon"):
			if i is Button:
				i.icon = EditorInterface.get_base_control().get_theme_icon(i.get_meta("Icon"), "EditorIcons")
		elif i.get_child_count() != 0:
			apply_icons(i)


func attach_node_ids(node: GraphNode = start_node, count: int = 0) -> void:
	if node in nodes.values():
		return

	nodes[count] = node
	node.name = str(count)
	print("attaching ", node.name)
	count += 1

	for connection in graph.connections:
		if connection["from_node"] == node.name:
			var target_node: GraphNode = graph.get_node(String(connection["to_node"])) as GraphNode
			attach_node_ids(target_node, count)


func open_from_path(path: String) -> void:
	if ResourceLoader.exists(path):
		open_file(ResourceLoader.load(path))


func open_file(file: SequenceGraph) -> void:
	clear()
	current_file = file
	file_name.text = file.resource_path.get_file()

	for i in file.nodes:
		var node := insert(i.type)
		node.position = i.position

	graph.connections = current_file.connections.duplicate(true)


func save() -> void:
	if current_file == null:
		return
	var resource_path := current_file.resource_path

	current_file = SequenceGraph.new()
	current_file.connections = graph.connections.duplicate(true)
	for node in graph.get_children():
		if node is GraphNode:
			var node_data = SequenceGraphNode.new()
			node_data.id = node.name
			node_data.type = node.get_meta(&"Type")
			node_data.position = node.position
			#node_data.data = node.data
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


func _graph_disconnection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	graph.disconnect_node(from_node, from_port, to_node, to_port)


func _on_insert_pressed(id: int) -> void:
	for i in elements.values():
		if i.get_meta("insert_id") == id:
			insert(i.name)


func _on_reload_button_pressed() -> void:
	var interface := EditorInterface
	interface.set_plugin_enabled("journal_sequence_editor", false)
	queue_free()
	interface.set_plugin_enabled("journal_sequence_editor", true)

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
