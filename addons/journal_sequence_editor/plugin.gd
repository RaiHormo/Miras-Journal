@tool
extends EditorPlugin

const SEQUENCE_VIEW = preload("res://addons/journal_sequence_editor/sequence_panel.tscn")
var view_instance: SequenceView

func _enter_tree() -> void:
	view_instance = SEQUENCE_VIEW.instantiate()
	view_instance.plugin = self
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

func _get_window_layout(configuration: ConfigFile) -> void:
	if view_instance and view_instance.current_file:
		var last_path := view_instance.current_file.resource_path
		configuration.set_value("JournalSequenceEditor", "last_opened_file", last_path)


func _set_window_layout(configuration: ConfigFile) -> void:
	if configuration.has_section_key("JournalSequenceEditor", "last_opened_file"):
		var last_path: String = configuration.get_value("SequenceEditor", "last_opened_file")
		if ResourceLoader.exists(last_path):
			view_instance.open_from_path(last_path)
