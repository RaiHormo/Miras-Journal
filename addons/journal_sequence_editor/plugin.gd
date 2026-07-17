@tool
extends EditorPlugin

const SEQUENCE_VIEW = preload("res://addons/journal_sequence_editor/sequence_panel.tscn")
var view_instance: SequenceView

func _enter_tree() -> void:
	view_instance = SEQUENCE_VIEW.instantiate()
	# Add the main panel to the editor's workspace
	EditorInterface.get_editor_main_screen().add_child(view_instance)
	_make_visible(false)

func _exit_tree() -> void:
	if view_instance:
		EditorInterface.get_editor_main_screen().remove_child(view_instance)
		view_instance.queue_free()

func _has_main_screen() -> bool:
	return true

func _make_visible(visible: bool) -> void:
	if view_instance:
		view_instance.visible = visible

func _get_plugin_name() -> String:
	return "Sequence"

func _get_plugin_icon() -> Texture2D:
	return EditorInterface.get_base_control().get_theme_icon("Animation", "EditorIcons")

func _handles(object: Object) -> bool:
	return object is SequenceGraph

func _edit(object: Object) -> void:
	EditorInterface.set_main_screen_editor("Sequence")
	view_instance.open(object)
