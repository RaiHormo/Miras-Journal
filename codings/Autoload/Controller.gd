extends Node

signal controller_changed


const SCHEMES: Dictionary[Variant, Variant] = {
	"None": "res://UI/Input/None.tres",
	"Keyboard": "res://UI/Input/Keyboard.tres",
	"Nintendo": "res://UI/Input/Nintendo.tres",
	"Generic": "res://UI/Input/Generic.tres",
	"Xbox": "res://UI/Input/Xbox.tres",
	"PlayStation": "res://UI/Input/PlayStation.tres",
	"PlayStationOld": "res://UI/Input/PlayStationOld.tres",
	"SteamDeck": "res://UI/Input/SteamDeck.tres",
}

var device: String = ""
var last_input := 0

var scheme_cache := {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	handle_remaps()


func get_scheme() -> ControlScheme:
	if !Global.Settings: return get_scheme_from_string("None")
	if not Global.Settings.ControlSchemeAuto:
		return Global.Settings.ControlSchemeOverride
	
	if device == "":
		device = Global.Settings.LastUsedDevice
	Global.Settings.LastUsedDevice = device
	
	return get_scheme_from_string(get_scheme_from_device())


func get_scheme_from_string(type: String) -> ControlScheme:
	if not scheme_cache.has(type):
		scheme_cache[type] = load(SCHEMES[type])
	return scheme_cache[type]


func get_scheme_from_device() -> String:
	if device == "Keyboard":
		return "Keyboard"
	if "Nintendo" in device or "Pro Controller" in device or "GameCube" in device:
		return "Nintendo"
	if "XInput" in device or "360" in device:
		return "Generic"
	if "Series" in device or "Xbox" in device or "XBox" in device:
		return "Xbox"
	if "PS4" in device or "DualShock 4" in device or "PS5" in device or "DualSense" in device:
		return "PlayStation"
	if "PS3" in device or "DualShock" in device or "PS2" in device or "Sony" in device or "PlayStation" in device:
		return "PlayStationOld"
	if "Steam" in device:
		return "SteamDeck"
	return "Generic"


func _input(event: InputEvent) -> void:
	if last_input == Global.ProcessFrame: return
	
	if event is InputEventMouseMotion:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		return
	
	if not event.is_pressed() and not (event is InputEventJoypadMotion and abs(event.axis_value) > 0.5):
		return
		
	var prev_dev := device
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	
	if event is InputEventKey:
		device = "Keyboard"
	elif event is InputEventJoypadButton or event is InputEventJoypadMotion:
		device = Input.get_joy_name(event.device)
	
	if prev_dev != device:
		if prev_dev != "":
			controller_changed.emit()
			Global.toast("Using " + device)
		handle_remaps()
	
	last_input = Global.ProcessFrame
	var is_fullscreen := get_window().mode == Window.MODE_FULLSCREEN
	if Global.Settings and is_fullscreen != Global.Settings.Fullscreen:
		Global.fullscreen(is_fullscreen)


func handle_remaps() -> void:
	var scheme := get_scheme()
	var use_alt := scheme.AltConfirm
	
	remap_action("ui_accept", "AltConfirm" if use_alt else "MainConfirm")
	remap_action("ui_cancel", "AltCancel" if use_alt else "MainCancel")


func remap_action(target_action: StringName, source_action: StringName) -> void:
	# Clean up joypad events from target action
	for event in InputMap.action_get_events(target_action):
		if event is InputEventJoypadButton or event is InputEventJoypadMotion:
			InputMap.action_erase_event(target_action, event)
	
	# Copy joypad events from source action
	for event in InputMap.action_get_events(source_action):
		if event is InputEventJoypadButton or event is InputEventJoypadMotion:
			InputMap.action_add_event(target_action, event)


func cancel() -> String:
	return "ui_cancel"


func confirm() -> String:
	return "ui_accept"


func rumble(strong: float, weak: float, duration: float, delay: float = 0) -> void:
	if Global.Settings and Global.Settings.ControllerVibration:
		if delay > 0: await Event.wait(delay, false)
		Input.start_joy_vibration(0, strong, weak, duration)


func _unhandled_input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("Fullscreen"):
		Global.fullscreen()
	if Input.is_action_just_pressed("Save"):
		Loader.save()
	if Input.is_action_just_pressed("Load"):
		Loader.load_game()
	if Input.is_action_just_pressed("SaveDir"):
		OS.shell_open(OS.get_user_data_dir())
	if Input.is_action_just_pressed("Refresh"):
		Global.refresh()
