@tool
extends EditorDock
class_name SequenceView

const battle_animations: PackedStringArray = [
	"Idle",
	"Attack1", "Attack2",
	"Ability", "AbilityLoop",
	"Cast", "Throw", "Drink", "Eat",
	"Item", "ItemLoop",
	"Hit", "KnockOut",
	"Victory", "VictoryLoop",
	"Entrance",
	"Command",

	"FlameSpark", "Bleed", "FirstBattle"
]

var plugin: EditorPlugin
var start_node: GraphNode
var nodes: Dictionary[int, GraphNode]
var current_file: SequenceGraph
var elements: Dictionary[StringName, GraphNode]

@onready var insert_button: MenuButton = %Insert
@onready var graph: GraphEdit = %GraphEdit
@onready var file_name: Label = %FileName
@onready var save_dialog: EditorFileDialog = %SaveDialog
@onready var header_actions: HBoxContainer = %HeaderActions


func _ready() -> void:
	apply_properties(self)

	file_name.text = ""
	save_dialog.hide()
	%GraphElements.hide()

	var insert_popup := insert_button.get_popup()
	var count := 0
	insert_popup.clear(true)
	insert_popup.id_pressed.connect(_on_insert_pressed)
	insert_popup.search_bar_enabled = true

	for category in %GraphElements.get_children():
		if category is Control:
			var submenu := PopupMenu.new()
			insert_popup.add_submenu_node_item(category.name, submenu)
			insert_popup.search_bar_enabled = true
			submenu.id_pressed.connect(_on_insert_pressed)
			var icon = EditorInterface.get_base_control().get_theme_icon(category.get_meta(&"CategoryIcon"), "EditorIcons")
			insert_popup.set_item_icon(insert_popup.get_item_count() - 1, icon)

			for element in category.get_children():
				if element is GraphNode:
					elements.set(element.name, element)

					submenu.add_item(element.title, count)
					element.set_meta("insert_id", count)
					count += 1

	graph.connection_request.connect(_graph_connection_request)
	graph.disconnection_request.connect(_graph_disconnection_request)
	graph.popup_request.connect(_on_graph_popup_request)

	header_actions.visible = current_file != null


func insert(type: StringName, position := Vector2.ZERO) -> GraphNode:
	var dub := elements[type].duplicate()
	dub.set_meta(&"Type", type)
	dub.name += str(randi())
	graph.add_child(dub)

	if position == Vector2.ZERO:
		# Determine the exact middle pixel of the GraphEdit container control
		var target_screen_center := graph.size / 2.0

		# Let GraphEdit translate screen pixels to zoomed canvas space automatically
		# This bypasses dividing by zoom variables that trigger the internal C++ error
		var clean_canvas_pos := (target_screen_center + graph.scroll_offset)

		if graph.zoom > 0.0:
			clean_canvas_pos /= graph.zoom

		dub.position_offset = clean_canvas_pos - (dub.size / 2.0)
	else:
		dub.position_offset = position

	return dub


func apply_properties(node: Node):
	for i in node.get_children():
		# Attach icons
		if i.has_meta(&"Icon"):
			if i is Button:
				i.icon = EditorInterface.get_base_control().get_theme_icon(i.get_meta("Icon"), "EditorIcons")

		# Setup AnimationSelector controls
		elif i.name == "AnimationSelect" and i is OptionButton:

			for anim in battle_animations:
				i.add_item(anim)

				# Setup ActorSelector controls
		elif i.name == "ActorSelect" and i is Button:
			i.pressed.connect(_actor_select.bind(i))

		# Recursion
		elif i.get_child_count() != 0:
			apply_properties(i)


func open_from_path(path: String) -> void:
	if ResourceLoader.exists(path):
		open_file(ResourceLoader.load(path))


func open_file(file: SequenceGraph) -> void:
	save()
	clear()
	header_actions.visible = true
	current_file = file
	file_name.text = file.resource_path.get_file().replace(".tres", "")

	for i in file.nodes:
		var node := insert(i.type, i.position)
		node.name = i.id

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
	if not current_file: return
	var resource_path := current_file.resource_path

	current_file.connections = graph.connections.duplicate(true)
	current_file.nodes.clear()
	for node in graph.get_children():
		if node is GraphNode:
			var node_data = SequenceGraphNodeData.new()
			node_data.id = node.name

			# Fallback to the title or a default string if the Type metadata is missing/empty
			var saved_type: String = node.get_meta(&"Type", "")

			if saved_type.is_empty():
				saved_type = String(node.title)

			node_data.type = saved_type
			node_data.data = pack_node_data(node)

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
	header_actions.visible = true
	save()


func clear() -> void:
	nodes.clear()
	graph.clear_connections()
	for i in graph.get_children().duplicate():
		if i is GraphNode:
			i.free()


func pack_node_data(node: GraphNode) -> Dictionary:
	var node_data := {}

	for child in node.get_children():
		if not child is HBoxContainer:
			continue

		var container := child as HBoxContainer
		var param_name := container.name

		# Check if this parameter is optional and disabled
		if container.has_node("Enable"):
			var enable_box := container.get_node("Enable") as CheckButton

			if enable_box and not enable_box.button_pressed:
				continue # Skip this data entry entirely

		# Parse values based on what fields exist inside the container
		if container.has_node("CheckButton"):
			node_data[param_name] = container.get_node("CheckButton").button_pressed
		elif container.has_node("LineEdit"):
			node_data[param_name] = container.get_node("LineEdit").text
		elif container.has_node("SpinBox"):
			node_data[param_name] = container.get_node("SpinBox").value
		elif container.has_node("X") and container.has_node("Y"):
			var x: float = container.get_node("X").value
			var y: float = container.get_node("Y").value
			node_data[param_name] = Vector2(x, y)
		else:
			for i in container.get_children():
				if i.name.ends_with("Select"):
					node_data[param_name] = i.text

	return node_data


func unpack_node_data(node: GraphNode, node_data: Dictionary) -> void:
	for child in node.get_children():
		if not child is HBoxContainer:
			continue

		var container := child as HBoxContainer
		var param_name := container.name

		# Handle optional parameter initialization
		var has_data := node_data.has(param_name)

		if container.has_node("Enable"):
			container.get_node("Enable").button_pressed = has_data

		# If the file doesn't have data for this parameter, leave it default/disabled
		if not has_data:
			continue

		var val = node_data[param_name]

		if container.has_node("CheckButton") and val is bool:
			container.get_node("CheckButton").button_pressed = val
		elif container.has_node("LineEdit") and val is String:
			container.get_node("LineEdit").text = val
		elif container.has_node("SpinBox") and (val is int or val is float):
			container.get_node("SpinBox").value = val
		elif container.has_node("X") and container.has_node("Y") and val is Vector2:
			container.get_node("X").value = val.x
			container.get_node("Y").value = val.y
		else:
			for i in container.get_children():
				if i.name.ends_with("Select"):
					i.text = val


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
			var mouse_pos := get_local_mouse_position()
			var pos := mouse_pos if mouse_pos.y > 0 else Vector2.ZERO
			insert(i.name, pos)
			save()


func _on_reload_button_pressed() -> void:
	plugin = null
	(func():
		var interface := EditorInterface
		interface.set_plugin_enabled("journal_sequence_editor", false)
		interface.set_plugin_enabled("journal_sequence_editor", true)
		print("Sequence plugin reloaded")
		if current_file != null:
			EditorInterface.edit_resource(current_file)
	).call_deferred()


func _on_open_pressed() -> void:
	EditorInterface.popup_quick_open(open_from_path, [&"SequenceGraph"])


func _on_new_pressed() -> void:
	save_dialog.popup_file_dialog()


func _on_save_dialog_confirmed() -> void:
	new_file(save_dialog.current_path)


func _on_graph_edit_delete_nodes_request(nodes_to_delete: Array[StringName]) -> void:
	# Disconnect any lines attached to the nodes being deleted
	for connection in graph.connections:
		if connection["from_node"] in nodes_to_delete or connection["to_node"] in nodes_to_delete:
			graph.disconnect_node(connection["from_node"], connection["from_port"], connection["to_node"], connection["to_port"])

	# Free the nodes from memory
	for node_name in nodes_to_delete:
		var node := graph.get_node(String(node_name))
		node.free()

	# Update your save file
	save()


func _actor_select(btn: Button) -> void:
	var popup: AcceptDialog = %ActorSelect
	popup.popup()
	await popup.confirmed
	btn.text = popup.get_node("List/CurrentChar").button_group.get_pressed_button().text

	if btn.text == "SpecifyID":
		btn.text = popup.get_node("List/SpecifyID/ID").text


func _exit_tree() -> void:
	save()


func _on_graph_popup_request(at_position: Vector2) -> void:
	if current_file == null: return
	var insert_popup := insert_button.get_popup()

	# Position the popup at the current global mouse cursor position
	insert_popup.position = DisplayServer.mouse_get_position()

	# Show the context menu
	insert_popup.popup()
