extends Resource
class_name SequenceGraphNodeData

@export var id: StringName:
	set(x):
		id = x
		resource_name = x
@export var type: StringName
@export var position: Vector2
@export var data: Dictionary = {}

@export var next: SequenceGraphNodeData = null
@export var after_finished: SequenceGraphNodeData = null
@export var conditional: Array[SequenceGraphNodeData] = []

@export var inputs: Dictionary[StringName, SequenceGraphNodeData] = {}
@export var io_name_match: Dictionary[StringName, StringName] = {}
@export var outputs: Dictionary[StringName, Variant] = {}
