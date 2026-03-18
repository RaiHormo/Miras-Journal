@tool
extends EditorPlugin

var included_paths = ["res://"]
var excluded_paths = ["res://addons/"]
var is_enabled_prettify_editor_on_focus = true
var is_enabled_prettify_editor_on_line_change = false
var is_enabled_prettify_editor_on_save = true
var is_enabled_prettify_filesystem_on_save = false
var is_enabled_prettify_filesystem_every_second = false

var timer
var just_saved

var _last_modified = 0
var _last_line = 0

const SETTINGS_PATH = "pretty-gd/"
var Prettifier = preload("res://addons/pretty-gd/pretty.gd").new()


func _enter_tree() -> void:
	# Initialization of the plugin goes here.
	_migrate_settings()
	_on_settings_changed()
	EditorInterface.get_editor_settings().settings_changed.connect(_on_settings_changed)
	EditorInterface.get_script_editor().editor_script_changed.connect(_on_editor_script_changed)
	get_window().focus_entered.connect(_on_editor_script_changed)
	get_window().window_input.connect(_on_input)
	scene_saved.connect(_on_scene_saved)
	timer = Timer.new()
	get_tree().root.add_child(timer)
	timer.timeout.connect(_on_tick)
	timer.start()
	print("pretty.gd enabled 🎀")


func _exit_tree() -> void:
	# Clean-up of the plugin goes here.
	EditorInterface.get_editor_settings().settings_changed.disconnect(_on_settings_changed)
	EditorInterface.get_script_editor().editor_script_changed.disconnect(_on_editor_script_changed)
	get_window().focus_entered.disconnect(_on_editor_script_changed)
	get_window().window_input.disconnect(_on_input)
	scene_saved.disconnect(_on_scene_saved)
	if timer: timer.queue_free()
	print("pretty.gd disabled 💩")

	return
	var settings = EditorInterface.get_editor_settings()
	settings.erase(SETTINGS_PATH + "included_paths")
	settings.erase(SETTINGS_PATH + "excluded_paths")
	settings.erase(SETTINGS_PATH + "prettify_editor_on_focus")
	settings.erase(SETTINGS_PATH + "prettify_editor_on_line_change")
	settings.erase(SETTINGS_PATH + "prettify_editor_on_save")
	settings.erase(SETTINGS_PATH + "prettify_filesystem_on_save")
	settings.erase(SETTINGS_PATH + "prettify_filesystem_every_second")


func _migrate_settings():
	var default = {
		"included_paths": "\n".join(included_paths),
		"excluded_paths": "\n".join(excluded_paths),
		"prettify_editor_on_focus": is_enabled_prettify_editor_on_focus,
		"prettify_editor_on_line_change": is_enabled_prettify_editor_on_line_change,
		"prettify_editor_on_save": is_enabled_prettify_editor_on_save,
		"prettify_filesystem_on_save": is_enabled_prettify_filesystem_on_save,
		"prettify_filesystem_every_second": is_enabled_prettify_filesystem_every_second,
	}

	var settings = EditorInterface.get_editor_settings()
	settings.erase(SETTINGS_PATH + "pretty_editor_on_focus")
	settings.erase(SETTINGS_PATH + "pretty_editor_on_save")
	settings.erase(SETTINGS_PATH + "pretty_filesystem_on_save")

	for key in default:
		if not settings.has_setting(SETTINGS_PATH + key):
			settings.set_setting(SETTINGS_PATH + key, default[key])
		settings.set_initial_value(SETTINGS_PATH + key, default[key], false)

	settings.add_property_info({ name = SETTINGS_PATH + "included_paths", type = TYPE_STRING, hint = PROPERTY_HINT_MULTILINE_TEXT })
	settings.add_property_info({ name = SETTINGS_PATH + "excluded_paths", type = TYPE_STRING, hint = PROPERTY_HINT_MULTILINE_TEXT })


func _on_settings_changed():
	var settings = EditorInterface.get_editor_settings()

	included_paths = settings.get_setting(SETTINGS_PATH + "included_paths").split("\n", false)
	excluded_paths = settings.get_setting(SETTINGS_PATH + "excluded_paths").split("\n", false)
	is_enabled_prettify_editor_on_focus = settings.get_setting(SETTINGS_PATH + "prettify_editor_on_focus")
	is_enabled_prettify_editor_on_line_change = settings.get_setting(SETTINGS_PATH + "prettify_editor_on_line_change")
	is_enabled_prettify_editor_on_save = settings.get_setting(SETTINGS_PATH + "prettify_editor_on_save")
	is_enabled_prettify_filesystem_on_save = settings.get_setting(SETTINGS_PATH + "prettify_filesystem_on_save")
	is_enabled_prettify_filesystem_every_second = settings.get_setting(SETTINGS_PATH + "prettify_filesystem_every_second")

	Prettifier.tab_size = settings.get_setting("text_editor/behavior/indent/size")
	if settings.get_setting("text_editor/behavior/indent/type"):
		Prettifier.indent_str = " ".repeat(Prettifier.tab_size)
	else:
		Prettifier.indent_str = "\t"


func _on_editor_script_changed(script = null):
	if is_enabled_prettify_editor_on_focus:
		prettify_editor()


func _on_input(input: InputEvent):
	if not(input is InputEventKey or input is InputEventMouseButton): return
	if input.is_pressed(): return

	var editor = EditorInterface.get_script_editor().get_current_editor()
	if is_enabled_prettify_editor_on_line_change and editor:
		var ed = editor.get_base_editor()
		var line = ed.get_caret_line()
		if input.get_modifiers_mask() == 0:
			if _last_line > line:
				prettify_editor()
			if _last_line < line:
				prettify_editor(line)
		_last_line = line


func _on_scene_saved(path: String):
	just_saved = true


func _on_tick():
	if not just_saved:
		if is_enabled_prettify_filesystem_every_second:
			for included in included_paths:
				prettify_dir(included)
		return

	just_saved = false

	if is_enabled_prettify_editor_on_save and prettify_editor():
		EditorInterface.save_scene()
		var script = EditorInterface.get_script_editor().get_current_script()
		if not script: return false
		print("pretty.gd: ", script.resource_path, " 🎀")
	elif is_enabled_prettify_filesystem_on_save:
		for included in included_paths:
			prettify_dir(included)


func prettify_editor(until_line = INF):
	var script = EditorInterface.get_script_editor().get_current_script()
	if not script: return false
	if not is_valid_script(script.resource_path): return false
	var editor = EditorInterface.get_script_editor().get_current_editor()
	if not editor: return false

	var ed = editor.get_base_editor()
	var dirty = ed.text
	var pretty = Prettifier.prettify(dirty) + "\n"
	if not pretty: return false
	if not pretty.strip_edges(): return false
	if dirty.strip_edges() == pretty.strip_edges(): return false

	var lines = pretty.split("\n")
	for line_num in range(max(lines.size(), ed.get_line_count())):
		if line_num >= until_line: break
		if line_num < lines.size():
			while lines[line_num].strip_edges() and not ed.get_line(line_num).strip_edges():
				ed.remove_line_at(line_num)
				#ed.insert_line_at(ed.get_line_count() - 1, "#")
			if ed.get_line(line_num).strip_edges() and not lines[line_num].strip_edges():
				ed.insert_line_at(line_num, "#")
			while line_num >= ed.get_line_count():
				ed.insert_line_at(ed.get_line_count() - 1, "")
			if ed.get_line(line_num) != lines[line_num]:
				ed.set_line(line_num, lines[line_num])
		else:
			if ed.get_line(line_num):
				ed.set_line(line_num, "")
	return true


func prettify_dir(path = "res://", since = _last_modified):
	for excluded in excluded_paths:
		if path.begins_with(excluded): return false
	var files = DirAccess.get_files_at(path)
	for file in files:
		if not file.begins_with("."):
			prettify_file(path + file, since)
	var dirs = DirAccess.get_directories_at(path)
	for dir in dirs:
		if not dir.begins_with("."):
			prettify_dir(path + dir + "/", since)


func prettify_file(path, since = 0):
	if not is_valid_script(path): return false
	var modified = FileAccess.get_modified_time(path)
	if modified <= since: return

	var dirty = FileAccess.get_file_as_string(path)
	var pretty = Prettifier.prettify(dirty).strip_edges() + "\n"
	if not pretty: return false
	if not pretty.strip_edges(): return false
	if dirty == pretty:
		_last_modified = max(_last_modified, modified)
		return false

	var tmp = ".pretty" + str(randi()) + ".tmp"
	var file = FileAccess.open(path + tmp, FileAccess.WRITE)
	file.store_string(pretty)
	file.close()
	DirAccess.rename_absolute(path + tmp, path)
	if FileAccess.file_exists(path + tmp):
		DirAccess.remove_absolute(path)
		DirAccess.rename_absolute(path + tmp, path)

	print("pretty.gd: ", path, " 🎀")
	#if not _changed_scripts.has(path):
		#_changed_scripts.push_back(path)
	return true


func is_valid_script(path):
	if path.contains("/."): return false
	if not path.ends_with(".gd"): return false
	for excluded in excluded_paths:
		if path.begins_with(excluded): return false
	for included in included_paths:
		if path.begins_with(included): return true
	return false
