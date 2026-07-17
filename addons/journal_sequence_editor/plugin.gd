@tool
extends EditorPlugin

const SEQUENCE_VIEW = preload("res://addons/journal_sequence_editor/sequence_panel.tscn")
var view_instance: SequenceView

func _enter_tree() -> void:
	view_instance = SEQUENCE_VIEW.instantiate()
	view_instance.dock_icon = EditorInterface.get_base_control().get_theme_icon("PlayStart", "EditorIcons")
	add_dock(view_instance)
	_make_visible(false)

func _exit_tree() -> void:
	if view_instance:
		remove_dock(view_instance)
		view_instance.queue_free()

func _has_main_screen() -> bool:
	return true

func _make_visible(visible: bool) -> void:
	if view_instance:
		view_instance.visible = visible

func _handles(object: Object) -> bool:
	return object is SequenceGraph

func _edit(object: Object) -> void:
	view_instance.open()
	view_instance.open_file(object)
