extends Node

signal controller_changed

var device: String = ""
var AltConfirm: bool
var last_input := 0


func get_scheme() -> ControlScheme:
	if !Global.Settings: return preload("res://UI/Input/None.tres")
	if not Global.Settings.ControlSchemeAuto:
		return Global.Settings.ControlSchemeOverride
	if device == "":
		device = Global.Settings.LastUsedDevice
	Global.Settings.LastUsedDevice = device
	if device == "Keyboard":
		return preload("res://UI/Input/Keyboard.tres")
	#elif device == "Touch":
		#return preload("res://UI/Input/None.tres")
	elif "Nintendo" in device or "Pro Controller" in device or "GameCube" in device:
		return preload("res://UI/Input/Nintendo.tres")
	elif "XInput" in device or "360" in device:
		return preload("res://UI/Input/Generic.tres")
	elif "Series" in device or "Xbox" in device or "XBox" in device:
		return preload("res://UI/Input/Xbox.tres")
	elif "PS4" in device or "DualShock 4" in device or "PS5" in device or "DualSense" in device:
		return preload("res://UI/Input/PlayStation.tres")
	elif "PS3" in device or "DualShock" in device or "PS2" in device or "Sony" in device or "PlayStation" in device:
		return preload("res://UI/Input/PlayStationOld.tres")
	elif "Steam" in device:
		return preload("res://UI/Input/SteamDeck.tres")
	else:
		return preload("res://UI/Input/Generic.tres")


func _input(event: InputEvent) -> void:
	if last_input == Global.ProcessFrame: return
	var prev_dev := device
	if event is InputEventJoypadMotion and event.axis_value < 0.5: return
	if event is InputEventMouseMotion:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		return
	#if event is InputEventScreenTouch or event is InputEventScreenDrag:
		#device = "Touch"
	if not event.is_pressed(): return
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	if event is InputEventKey:
		device = "Keyboard"
	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		device = Input.get_joy_name(event.device)
		AltConfirm = get_scheme().AltConfirm
		if get_scheme().AltConfirm:
			InputMap.action_erase_event("ui_accept", InputMap.action_get_events("MainConfirm")[1])
			InputMap.action_add_event("ui_accept", InputMap.action_get_events("AltConfirm")[1])
			InputMap.action_erase_event("ui_cancel", InputMap.action_get_events("MainCancel")[1])
			InputMap.action_add_event("ui_cancel", InputMap.action_get_events("AltCancel")[1])
		else:
			InputMap.action_erase_event("ui_accept", InputMap.action_get_events("AltConfirm")[1])
			InputMap.action_add_event("ui_accept", InputMap.action_get_events("MainConfirm")[1])
			InputMap.action_erase_event("ui_cancel", InputMap.action_get_events("AltCancel")[1])
			InputMap.action_add_event("ui_cancel", InputMap.action_get_events("MainCancel")[1])
	#if "Steam" in device:
		#OS.set_environment("SDL_GAMECONTROLLER_IGNORE_DEVICES", "28de:11ff")
		#var steam_controllers = Steam.getConnectedControllers()
	if prev_dev != device and prev_dev != "":
		controller_changed.emit()
		Global.toast("Using " + device)
	last_input = Global.ProcessFrame
	var is_fullscreen := get_window().mode == Window.MODE_FULLSCREEN
	if is_fullscreen != Global.Settings.Fullscreen:
		Global.fullscreen(is_fullscreen)
	#print(device)


func cancel() -> String:
	return "ui_cancel"


func confirm() -> String:
	return "ui_accept"


func rumble(strong: float, weak: float, duration: float, delay: float = 0) -> void:
	if Global.Settings.ControllerVibration:
		if delay != 0: await Event.wait(delay, false)
		Input.start_joy_vibration(0, strong, weak, duration)
		await Event.wait(duration, false)
		Input.stop_joy_vibration(0)


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
