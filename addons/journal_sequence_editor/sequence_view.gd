@tool
extends EditorDock
class_name SequenceView

const slot_names: Dictionary[int, String] = {
	0: "Call",
	1: "String",
	2: "Vector2",
	3: "Number",
	4: "Actor"
}

const slot_colors: Dictionary[int, Color] = {
	0: Color.WHITE,
	1: Color("6d4affff"),
	2: Color("be4d00ff"),
	3: Color("009e13"),
	4: Color("d70058"),
}

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
@onready var node_context_menu: PopupMenu = $SequenceView/NodeContextMenu


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
	graph.popup_request.connect(_open_context_menu)

	header_actions.visible = current_file != null


func insert(type: StringName, pos := Vector2.ZERO) -> GraphNode:
	var dub := elements[type].duplicate()
	dub.set_meta(&"Type", type)
	dub.name += str(randi())
	graph.add_child(dub)

	if pos == Vector2.ZERO:
		var target_screen_center := graph.size / 2.0
		var clean_canvas_pos := (target_screen_center + graph.scroll_offset)

		if graph.zoom > 0.0:
			clean_canvas_pos /= graph.zoom

		dub.position_offset = clean_canvas_pos - (dub.size / 2.0)
	else:
		dub.position_offset = pos

	dub.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			dub.selected = true
			_open_context_menu()
			dub.accept_event()
	)

	create_slots(dub)

	return dub


func apply_properties(node: Node):
	for i in node.get_children():
		# Attach icons
		if i.has_meta(&"Icon"):
			if i is Button:
				i.icon = EditorInterface.get_base_control().get_theme_icon(i.get_meta("Icon"), "EditorIcons")

		# Recursion
		elif i.get_child_count() != 0:
			apply_properties(i)


func create_slots(node: Node, graph_node: GraphNode = node if node is GraphNode else null) -> void:
	for i in node.get_children():
		if i.name == &"Radio" and i is VBoxContainer:
			var group := ButtonGroup.new()
			var stack: Array[Node] = [i]

			while not stack.is_empty():
				var curr := stack.pop_back()

				if curr is CheckBox:
					curr.button_group = group

				stack.append_array(curr.get_children())

		if i is Button and i.name.ends_with("Select"):
			var type := i.name.replace("Select", "")

			var slot: int = slot_names.find_key(type)

			if not slot:
				printerr("Unspecified slot type for ", i.name)
				return

			var container := i.get_parent() as HBoxContainer

			if container:
				if graph_node:
					var idx := container.get_index()
					graph_node.set_slot(
						idx,
						true,
						slot,
						slot_colors.get(slot),
						graph_node.is_slot_enabled_right(idx),
						graph_node.get_slot_type_right(idx),
						graph_node.get_slot_color_right(idx)
					)

					if elements.has(type):
						i.pressed.connect(func():
							var new_node := insert(type, graph_node.position_offset - Vector2(graph_node.size.x * 1.2, 0))

							# Calculate the true left port index by counting enabled left slots above it
							var port_idx := 0

							for c_idx in range(idx):
								if graph_node.is_slot_enabled_left(c_idx):
									port_idx += 1

							_graph_connection_request(new_node.name, 0, graph_node.name, port_idx)
						)

		# Recursion
		elif i.get_child_count() != 0:
			create_slots(i, graph_node)


func open_from_path(path: String) -> void:
	if ResourceLoader.exists(path):
		open_file(ResourceLoader.load(path))


func open_file(file: SequenceGraph) -> void:
	if file == null: return

	save()
	clear()
	header_actions.visible = true
	current_file = file
	file_name.text = file.resource_name

	for i in file.nodes:
		var node := insert(i.type, i.position)
		node.name = i.id
		unpack_node_data(node, i.data)

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
	current_file.resource_name = resource_path.get_file().replace(".tres", "")

	current_file.connections = graph.connections.duplicate(true)
	current_file.nodes.clear()

	var node_map: Dictionary[StringName, GraphNode] = {}
	var data_map: Dictionary[StringName, SequenceGraphNodeData] = {}

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

			node_map[node.name] = node
			data_map[node.name] = node_data

	for conn in current_file.connections:
		var from_id: StringName = conn["from_node"]
		var to_id: StringName = conn["to_node"]
		var from_port: int = conn["from_port"]
		var to_port: int = conn["to_port"]

		if not data_map.has(from_id) or not data_map.has(to_id):
			continue

		var from_node := node_map[from_id]
		var to_node := node_map[to_id]
		var from_data := data_map[from_id]
		var to_data := data_map[to_id]

		var right_port_idx := 0

		for slot_idx in from_node.get_child_count():
			if from_node.is_slot_enabled_right(slot_idx):
				if right_port_idx == from_port:
					var child_name := String(from_node.get_child(slot_idx).name)

					if from_node.get_slot_type_right(slot_idx) == 0:
						if child_name == "Next":
							from_data.next = to_data
						elif child_name == "AfterFinished":
							from_data.after_finished = to_data
						elif child_name.begins_with("Condition"):
							var idx := child_name.trim_prefix("Condition").to_int()

							while from_data.conditional.size() <= idx:
								from_data.conditional.append(null)

							from_data.conditional[idx] = to_data
					else:
						var left_port_idx := 0

						for to_slot_idx in to_node.get_child_count():
							if to_node.is_slot_enabled_left(to_slot_idx):
								if left_port_idx == to_port:
									var input_param := StringName(to_node.get_child(to_slot_idx).name)
									var output_param := StringName(child_name)

									to_data.inputs[input_param] = from_data
									to_data.io_name_match[input_param] = output_param
									break

								left_port_idx += 1

					break

				right_port_idx += 1

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
		if child.name == &"Radio" and child is VBoxContainer:
			var stack: Array[Node] = [child]

			while not stack.is_empty():
				var curr := stack.pop_back()

				if curr is CheckBox and curr.button_pressed:
					var val := String(curr.name)
					var parent: Node = curr.get_parent()

					if parent is HBoxContainer:
						for sibling in parent.get_children():
							if sibling != curr:
								if sibling is LineEdit or sibling is Button:
									val += sibling.text
								elif sibling is SpinBox:
									val += str(sibling.value)

					node_data[&"Radio"] = val
					break

				stack.append_array(curr.get_children())

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
		if child.name == &"Radio" and child is VBoxContainer:
			if node_data.has(&"Radio"):
				var val = node_data[&"Radio"]

				if val is String:
					var stack: Array[Node] = [child]
					var checkboxes: Array[CheckBox] = []

					while not stack.is_empty():
						var curr := stack.pop_back()

						if curr is CheckBox:
							checkboxes.append(curr)

						stack.append_array(curr.get_children())

					for cb in checkboxes:
						var cb_name := String(cb.name)

						if val == cb_name:
							cb.button_pressed = true
							break
						elif val.begins_with(cb_name):
							var remainder: String = val.substr(cb_name.length())
							var parent := cb.get_parent()

							if parent is HBoxContainer:
								var has_control := false

								for sibling in parent.get_children():
									if sibling != cb:
										if sibling is OptionButton:
											for idx in range(sibling.item_count):
												if sibling.get_item_text(idx) == remainder:
													sibling.selected = idx
													break

											has_control = true
										elif sibling is LineEdit:
											sibling.text = remainder
											has_control = true
										elif sibling is Button:
											sibling.text = remainder
											has_control = true
										elif sibling is SpinBox:
											sibling.value = remainder.to_float()
											has_control = true

								if has_control:
									cb.button_pressed = true
									break

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


func _exit_tree() -> void:
	save()


func _open_context_menu(pos: Vector2i = Vector2i.ZERO):
	insert_button.get_popup().reparent(node_context_menu)
	node_context_menu.add_submenu_node_item("Insert", insert_button.get_popup(), 0)
	node_context_menu.popup()
	node_context_menu.position = get_global_mouse_position()

	node_context_menu.set_item_icon(0, get_theme_icon(&"Duplicate", &"EditorIcons"))
	node_context_menu.set_item_icon(1, get_theme_icon(&"Unlinked", &"EditorIcons"))
	node_context_menu.set_item_icon(2, get_theme_icon(&"Remove", &"EditorIcons"))
	node_context_menu.set_item_icon(3, get_theme_icon(&"ToolAddNode", &"EditorIcons"))


func _on_node_context_menu_id_pressed(id: int) -> void:
	match id:
		1: # Duplicate
			duplicate_nodes(get_selected_nodes())

		2: # Disconnect Slots
			disconnect_slots(get_selected_node_names())

		3: # Delete
			_on_graph_edit_delete_nodes_request(get_selected_node_names())


func disconnect_slots(selected_names: Array[StringName]) -> void:

	if selected_names.is_empty():
		return

	# Make a duplicate of graph.connections to safely iterate through while disconnecting
	var connections_to_check := graph.connections.duplicate(true)

	for conn in connections_to_check:
		var from_node: StringName = conn["from_node"]
		var to_node: StringName = conn["to_node"]

		if from_node in selected_names or to_node in selected_names:
			var from_port: int = conn["from_port"]
			var to_port: int = conn["to_port"]
			graph.disconnect_node(from_node, from_port, to_node, to_port)


func duplicate_nodes(node_array: Array[GraphNode]) -> void:
	for i in node_array:
		var dup := i.duplicate()
		graph.add_child(dup)
		dup.position_offset += Vector2(50, 50)
		i.selected = false


func get_selected_nodes() -> Array[GraphNode]:
	var selected_nodes: Array[GraphNode] = []

	for child in graph.get_children():
		if child is GraphNode and child.selected:
			selected_nodes.append(child)

	return selected_nodes


func get_selected_node_names() -> Array[StringName]:
	var selected_nodes: Array[StringName] = []

	for child in graph.get_children():
		if child is GraphNode and child.selected:
			selected_nodes.append(child.name)

	return selected_nodes


func _on_node_context_menu_popup_hide() -> void:
	insert_button.get_popup().reparent(insert_button)
	node_context_menu.remove_item(3)
