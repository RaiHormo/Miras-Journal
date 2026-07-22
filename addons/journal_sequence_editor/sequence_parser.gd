class_name SequenceGraphParser
extends RefCounted


func parse(node_data: SequenceGraphNodeData) -> void:
	if not node_data:
		return

	# Fire 'next' asynchronously 
	if node_data.next:
		parse(node_data.next)

	# Handle inputs
	for input_key in node_data.inputs.keys():
		var input_node := node_data.inputs[input_key]
		var output_key := node_data.io_name_match[input_key]

		if input_node.outputs.has(output_key):
			node_data.data[input_key] = input_node.outputs[output_key]

	# Execute this node's logic
	await _execute_node(node_data)

	# Fire 'after_finished' once this node completes
	if node_data.after_finished:
		await parse(node_data.after_finished)


func _execute_node(node: SequenceGraphNodeData) -> void:
	pass


func execute_conditional(node_data: SequenceGraphNodeData, index: int) -> void:
	if index >= 0 and index < node_data.conditional.size() and node_data.conditional[index]:
		await parse(node_data.conditional[index])
