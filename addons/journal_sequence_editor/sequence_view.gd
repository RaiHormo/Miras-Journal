@tool
extends Control
class_name SequenceView

@onready var insert: MenuButton = %Insert
@onready var graph: GraphEdit = %GraphEdit
@onready var start_node: GraphNode = $HSplitContainer/VBoxContainer2/GraphEdit/Start
var nodes: Dictionary[int, GraphNode]
var current_file: SequenceGraph

var elements: Dictionary[int, GraphNode]

func _ready() -> void:
	
	apply_icons(self)
	
	var count := 0
	%GraphElements.hide()
	for i in %GraphElements.get_children():
		elements.set(count, i)
		count += 1
	
	var insert_popup := insert.get_popup()

	for i in elements.keys():
		var element := elements[i]
		insert_popup.add_item(element.title, i)
		insert_popup.id_pressed.connect(_on_insert_pressed)
		
	graph.connection_request.connect(_graph_connection_request)
	graph.disconnection_request.connect(_graph_disconnection_request)

func _graph_connection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	graph.connect_node(from_node, from_port, to_node, to_port)

func _graph_disconnection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	graph.disconnect_node(from_node, from_port, to_node, to_port)

func _on_insert_pressed(id: int):
	var dub := elements[id].duplicate()
	dub.set_meta(&"Type", dub.name)
	graph.add_child(dub)

func apply_icons(node: Control):
	for i in node.get_children():
		if i.has_meta(&"Icon"):
			if i is Button: 
				i.icon = EditorInterface.get_base_control().get_theme_icon(i.get_meta("Icon"), "EditorIcons")
		elif i.get_child_count() != 0:
			apply_icons(i)

func _on_reload_button_pressed() -> void:
	var interface := EditorInterface
	interface.set_plugin_enabled("journal_sequence_editor", false)
	interface.set_plugin_enabled("journal_sequence_editor", true)
	
	interface.set_main_screen_editor("Sequence")
	
	print("Sequence plugin reloaded")


func _on_open_pressed() -> void:
	EditorInterface.popup_quick_open(open, [&"SequenceGraph"])

func attach_node_ids(node: GraphNode = start_node, count: int = 0) -> void:
	if node in nodes.values():
		return
	
	nodes[count] = node
	count += 1
	node.name = str(count)
	
	for connection in graph.connections:
		if connection["from_node"] == node.name:
			var target_node: GraphNode = get_node(String(connection["to_node"])) as GraphNode
			attach_node_ids(target_node, count)

func open(file: SequenceGraph) -> void:
	current_file = file

func save() -> void:
	nodes.clear()
	attach_node_ids()
