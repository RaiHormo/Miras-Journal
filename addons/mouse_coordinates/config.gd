extends Node


var _config = ConfigFile.new()

var _path := "res://addons/mouse_coordinates/config.cfg"

var _section = "IniConfig"


func _init() -> void:
	_create_config()


func set_val(key: String, value: bool) -> void:
	_config.set_value(_section, key, value)

	var err = _config.save(_path)
	if err != OK:
		print("Fail to save config: ", err)


func get_val(key) -> bool:
	var err = _config.load(_path)
	if err != OK:
		assert("Fail to load file")

	return _config.get_value(_section, key)


func _create_config() -> void:
	var exist = FileAccess.file_exists(_path)

	if not exist:
		set_val("Int", false)
		set_val("Save", false)
		set_val("Local", false)
