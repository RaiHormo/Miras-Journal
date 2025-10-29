#region Variables
extends Node
var Controllable : bool = true:
	set(x):
		Controllable = x
var Audio := AudioStreamPlayer.new()
var Party: PartyData
var Members: Array[Actor]
var Bt: Battle = null
var PortraitIMG: Texture
var Player: Mira
var PlayerDir: Vector2:
	get:
		if is_instance_valid(Player):
			return Player.Facing
		else: return Vector2.RIGHT
var PlayerPos: Vector2
var Area: Room
var Camera: Camera2D:
	get:
		return get_cam()
var CameraInd:= 0
var Settings: Setting
var Lights: Array[Light2D] = []
var device: String = ""
var ProcessFrame := 0
var LastInput:= 0
var AltConfirm: bool
var StartTime:= 0.0
var FirstStartTime:= 0.0
var PlayTime:= 0.0
var SaveTime:= 0.0
var HasPortrait := false
var textbox_open:= false
var PortraitRedraw := true
var ArbData0 = null
var Complimentaries: Array[String]
signal lights_loaded
signal check_party
signal anim_done
signal area_initialized
signal textbox_close
signal player_ready
signal controller_changed
const AppID = 4059970
var UsingSteam:= false
var SteamInputDevice
var UserID: int
#endregion

#region System
func _init():
	init_user()
	#OS.set_environment("SDL_GAMECONTROLLER_IGNORE_DEVICES", "0x28de/0x11ff")

func _ready() -> void:
	StartTime=Time.get_unix_time_from_system()
	add_child(Audio)
	Audio.volume_db = -5
	process_mode = Node.PROCESS_MODE_ALWAYS
	init_party(Party)
	init_settings()
	
	if is_instance_valid(Area): await nodes_of_type(Area, "Light2D", Lights)
	lights_loaded.emit()
	#print(Input.get_joy_name(0))
	rumble(0, 0.5, 0.1)
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_ON


func quit() -> void:
	if get_tree().root.has_node("Options"):
		get_tree().root.get_node("Options").close()
	if get_tree().root.has_node("MainMenu"):
		get_tree().root.get_node("MainMenu").close()
	if not Loader.InBattle and is_instance_valid(Player) and is_instance_valid(Area) and (
		Global.Controllable or get_tree().root.has_node("MainMenu") or get_tree().root.has_node("Options")): 
		Loader.icon_save()
		await Loader.save()
	elif is_instance_valid(Area):
		if not await warning("The game cannot be saved right now.\nQuit the game anyways?", "QUIT", ["Canel", "Quit Game"]):
			return
	await Loader.transition("")
	get_tree().quit()

func normal_mode():
	Area.queue_free()
	get_tree().change_scene_to_file("res://scenes/Initializer.tscn")

func init_steam():
	OS.set_environment("SteamAppId", str(AppID))
	OS.set_environment("SteamGameId", str(AppID))
	var initialize_response: Dictionary = Steam.steamInitEx(AppID)
	print("Did Steam initialize?: %s " % initialize_response)
	#Steam.inputInit()
	#Steam.enableDeviceCallbacks()
	#SteamInput.init()
	if initialize_response.get("status") == 0:
		print("Running with Steam")
		UsingSteam = true
		UserID = Steam.getSteamID32(Steam.getSteamID())
		print("User: ", Steam.getPersonaName(), " ", UserID)
		#if Steam.isSteamRunningOnSteamDeck() and Settings.ControlSchemeEnum == 0:
			#Settings.ControlSchemeEnum = 7
			#Settings.ControlSchemeOverride = load("res://UI/Input/SteamDeck.tres")
		#print(Steam.getFriendPersonaName(Steam.getSteamID()))

func init_user():
	UserID = 0
	init_steam()
	if UserID == 0:
		if FileAccess.file_exists("user://last_user_id.txt"):
			UserID = int(FileAccess.get_file_as_string("user://last_user_id.txt"))
			print("Using last used user ID, ", UserID)
	var last_id_write = FileAccess.open("user://last_user_id.txt", FileAccess.WRITE)
	last_id_write.store_string(str(UserID))
	if not DirAccess.dir_exists_absolute("user://"+str(UserID)):
		DirAccess.make_dir_absolute("user://"+str(UserID))
	ProjectSettings.set("application/config/custom_user_dir_name", "miras-journal/"+str(UserID))

func game_over():
	$"/root".add_child((await Loader.load_res("res://UI/GameOver/GameOver.tscn")).instantiate())

func _notification(what) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		quit()

##Focus the window, used as a workaround to a wayland problem
func ready_window() -> void:
	if not OS.get_name() == "Linux":
		await Event.wait(0.5)
		return

func _process(delta: float) -> void:
	ProcessFrame+=1
	if ProcessFrame % 100:
		#if Settings.FPS == 0:
			#Engine.set_physics_ticks_per_second(int(DisplayServer.screen_get_refresh_rate()))
		#else:
			#Engine.set_physics_ticks_per_second(Settings.FPS)
		Engine.max_fps = Settings.FPS
	#if UsingSteam: 
		#Steam.run_callbacks()
		#Steam.runFrame()

func options(submenu = 0):
	if get_tree().root.has_node("Options"): return
	var control = Controllable
	#var init = get_tree().root.get_node_or_null("Initializer")
	#if init != null: init.queue_free()
	var opt = (await Loader.load_res("res://UI/Options/Options.tscn")).instantiate()
	Controllable = control
	match submenu:
		1:
			opt.set_no_main()
			opt.save_managment()
		3:
			opt.set_no_main()
			opt.manual()
	get_tree().root.add_child(opt)

func title_screen():
	var init = (await Loader.load_res("res://codings/Initializer.tscn")).instantiate()
	get_tree().root.add_child(init)

func member_details(chara: Actor, menu:= 0):
	if chara == null: return
	var dub = (await Loader.load_res("res://UI/MemberDetails/MemberDetails.tscn")).instantiate()
	get_tree().root.add_child(dub)
	#await Event.wait()
	dub.draw_character(chara, menu)

func complimentary_ui(chara: Actor):
	if chara == null: return
	var dub = (await Loader.load_res("res://UI/Complimentary/ComplimentaryUI.tscn")).instantiate()
	get_tree().root.add_child(dub)
	await Event.wait()
	dub.draw_character(chara)

func next_day_ui():
	get_tree().root.add_child((await Loader.load_res("res://UI/Misc/DayChangeUi.tscn")).instantiate())

func veinet_map(cur: String):
	var Map = (await Loader.load_res("res://UI/Map/VeinetMap.tscn")).instantiate()
	get_tree().root.add_child(Map)
	Map.focus_place(cur)

static func alcine() -> String:
	return Query.find_member("Alcine").FirstName

func nodes_of_type(node: Node, className : String, result : Array) -> void:
	if !node: return
	if node.is_class(className):
		if node and (node is Light2D and node.shadow_enabled) and not "Editor" in node.name: result.push_back(node)
	for child in node.get_children():
		await nodes_of_type(child, className, result)

func intro_effect(ref: Node):
	#if get_tree().root.has_node("IntroEffect"): return
	var node = (await Loader.load_res("res://codings/IntroEffect.tscn")).instantiate()
	get_tree().root.add_child(node)
	node.ref = ref
	node.animate()

#endregion

#region Controller

func get_controller() -> ControlScheme:
	if !Settings: return preload("res://UI/Input/None.tres")
	if not Settings.ControlSchemeAuto:
		return Settings.ControlSchemeOverride
	if device == "":
		device = Settings.LastUsedDevice
	Settings.LastUsedDevice = device
	if device == "Keyboard":
		return preload("res://UI/Input/Keyboard.tres")
	#elif device == "Touch":
		#return preload("res://UI/Input/None.tres")
	elif "Nintendo" in device or "Pro Controller" in device or  "GameCube" in device:
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
	if LastInput==ProcessFrame: return
	var prev_dev = device
	if event is InputEventJoypadMotion  and event.axis_value < 0.5: return
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
		AltConfirm = get_controller().AltConfirm
		if get_controller().AltConfirm:
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
		toast("Using "+ device)
	LastInput=ProcessFrame
	var is_fullscreen = get_window().mode == Window.MODE_FULLSCREEN
	if is_fullscreen != Settings.Fullscreen:
		fullscreen(is_fullscreen)
	#print(device)

func cancel() -> String:
	return "ui_cancel"

func confirm() -> String:
	return "ui_accept"

func rumble(strong: float, weak: float, duration: float, delay: float = 0):
	if Settings.ControllerVibration:
		if delay != 0: await Event.wait(delay, false)
		Input.start_joy_vibration(0, strong, weak, duration)
		await Event.wait(duration, false)
		Input.stop_joy_vibration(0)

func _unhandled_input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("Fullscreen"):
		fullscreen()
	if Input.is_action_just_pressed("Save"):
		Loader.save()
	if Input.is_action_just_pressed("Load"):
		Loader.load_game()
	if Input.is_action_just_pressed("SaveDir"):
		OS.shell_open(OS.get_user_data_dir())
	if Input.is_action_just_pressed("Refresh"):
		refresh()
#endregion

#region Settings

func refresh():
	await Loader.save()
	Loader.load_game()
	print(Input.should_ignore_device(0x28de, 0x11ff))

func fullscreen(tog: bool = !Settings.Fullscreen) -> void:
	if !Settings: await init_settings()
	if Engine.is_embedded_in_editor():
		toast("Can't fullscreen while the window is embeded")
		Settings.Fullscreen = false
		return
	if tog:
		Settings.Fullscreen = true
		get_window().mode = Window.MODE_FULLSCREEN
		await get_tree().create_timer(0.1).timeout
		get_window().grab_focus()
	else:
		Settings.Fullscreen = false
		get_window().mode = Window.MODE_WINDOWED
		#if OS.get_name() == "Linux":
			#get_window().size = Vector2i(1280,800)
			#await get_tree().create_timer(0.03).timeout
			#get_window().position = DisplayServer.screen_get_size(0)/2 - Vector2i(1280,800)/2
	await get_tree().create_timer(0.15).timeout
	get_window().grab_focus()
	save_settings()

func reset_settings() -> void:
	Settings = Setting.new()
	ResourceSaver.save(Settings, "user://Settings.res")
	if OS.get_environment("STEAMDECK") == "1":
		Settings.ControlSchemeAuto = false
		Settings.ControlSchemeEnum = 7

func init_settings() -> void:
	if not ResourceLoader.exists("user://Settings.res"):
		print("No settings found, initializing...")
		reset_settings()
		await Event.wait()
	Settings = ResourceLoader.load("user://Settings.res")
	if not is_instance_valid(Settings):
		print("Settings file is invalid, settings will be restored to default")
		reset_settings()
		await Event.wait()
		Settings = load("user://Settings.res")
	if not is_instance_valid(Settings):
		OS.alert("Something is wrong with the settings file or user folder")
	apply_settings()

func apply_settings():
	if Settings.Fullscreen:
		fullscreen(true)
	if Settings.GlowEffect:
		World.environment.glow_enabled = true
	else: World.environment.glow_enabled = false
	if Settings.UpscaledRes:
		get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	else:
		get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	AudioServer.set_bus_volume_db(0, Settings.MasterVolume)
	AudioServer.set_bus_volume_db(1, Settings.MusicVolume)
	AudioServer.set_bus_volume_db(2, Settings.EnvSFXVolume)
	AudioServer.set_bus_volume_db(3, Settings.BtSFXVolume)
	AudioServer.set_bus_volume_db(4, Settings.UIVolume)
	AudioServer.set_bus_volume_db(4, Settings.VoicesVolume)
	if Settings.VSync: DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	else: DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)

func get_playtime() -> int:
	PlayTime = SaveTime + Time.get_unix_time_from_system() - StartTime
	return int(PlayTime)

func save_settings() -> void:
	ResourceSaver.save(Settings, "user://Settings.res")
#endregion

#region UI Sounds
func cursor_sound(dont_force:= false) -> void:
	if not (dont_force and Audio.playing):
		Audio.stream = preload("res://sound/SFX/cursor.wav")
		Audio.play()
func buzzer_sound() -> void:
	Audio.stream = preload("res://sound/SFX/buzzer.ogg")
	Audio.play()
func confirm_sound() -> void:
	Audio.stream = preload("res://sound/SFX/confirm.ogg")
	Audio.play()
func cancel_sound() -> void:
	Audio.stream = preload("res://sound/SFX/Quit.ogg")
	Audio.play()
func item_sound() -> void:
	Audio.stream = preload("res://sound/SFX/item.ogg")
	Audio.play()
func ui_sound(string:String) -> void:
	Audio.stream = await Loader.load_res("res://sound/SFX/"+string+".ogg")
	Audio.play()
#endregion

#region Party Checks
func get_party() -> PartyData:
	return Global.Party

func heal_party() -> void:
	for i in Members:
		i.full_heal()

func add_test_state(chara: Actor):
	for i in DirAccess.get_files_at("res://database/States/"):
		var state: String = i.replace(".tres", "")
		var ab: Ability = load("res://database/Abilities/Debug/TestState.tres").duplicate()
		ab.name += state
		ab.InflictsState = state
		chara.Abilities.append(ab)

func reset_all_members() -> void:
	init_party(Party)
	for i in range(-1, Members.size() - 1):
		Members[i] = load("res://database/Party/"+ Members[i].codename +".tres").duplicate(true)
	Party.set_to(Party)

##Alias for find_member()

func add_complimentary(ability: String):
	if ability not in Global.Complimentaries:
		Global.Complimentaries.append(ability)

func init_party(party:PartyData) -> void:
	Members.clear()
	if !is_instance_valid(party): party = PartyData.new()
	for i in DirAccess.get_files_at("res://database/Party"):
		var file = load("res://database/Party/"+ i)
		if file is Actor:
			Members.append(file.duplicate())
	Party = PartyData.new()
	Party.set_to(party)

func unlock_all_abilities():
	for mem in Members:
		for ab in mem.LearnableAbilities:
			mem.Abilities.append(ab)

func give_every_ability():
	for i in DirAccess.get_files_at("res://database/Abilities/"):
		var ab: Ability = load("res://database/Abilities/"+i).duplicate()
		Party.Leader.Abilities.append(ab)
#endregion

#region Textbox Managment

func textbox(file: String, title: String = "0", fade_bg:= false, extra_game_states: Array = []) -> void:
	textbox_kill()
	textbox_open = true
	for i in get_tree().root.get_children():
		if i is Textbox: i.queue_free()
	var Textbox2 = await Loader.load_res("res://UI/Textbox/Textbox2.tscn")
	var balloon: Node = Textbox2.instantiate()
	var text = await Loader.load_res("res://database/Text/" + file + ".dialogue")
	get_tree().root.add_child(balloon)
	if is_instance_valid(balloon): balloon.start(text, title, extra_game_states)
	if fade_bg: fade_txt_background()
	await textbox_close
	textbox_open = false

func textbox_kill():
	if get_node_or_null("/root/Textbox"): $"/root/Textbox".free(); await Event.wait()

func passive(file: String, title: String = "0", extra_game_states: Array = []) -> void:
	if get_node_or_null("/root/Passive"):
		$"/root/Passive"._on_close()
		await textbox_close
		await Event.wait(0.1)
		passive(file, title, extra_game_states)
		return
	var Passive = await Loader.load_res("res://UI/Textbox/Passive.tscn")
	var balloon: Node = Passive.instantiate()
	get_tree().root.add_child(balloon)
	balloon.start(await Loader.load_res("res://database/Text/" + file + ".dialogue"), title, extra_game_states)
	await textbox_close

func portrait(img:String, redraw:=true) -> void:
	PortraitRedraw = redraw
	HasPortrait=true
	PortraitIMG = await Loader.load_res("res://art/Portraits/" + img + ".png")

func portrait_clear() -> void:
	HasPortrait=false

func fade_txt_background(alpha := 0.8):
	var t = create_tween()
	t.tween_property(get_tree().root.get_node("Textbox/Fader"), "color", Color(0, 0, 0, alpha), 0.5)

func next_box(profile:String) -> void:
	$/root.get_node("Textbox").next_box = profile

func picture(img: String):
	$/root/Textbox.picture = await Loader.load_res("res://art/Pictures/" + img + ".png")

func picture_clear():
	$/root/Textbox.picture = null

func toast(string: String) -> void:
	if get_node_or_null("/root/Toast"):
		$/root/Toast.free()
		await Event.wait()
	print("Toast: "+ string)
	var tost = (preload("res://UI/Misc/Toast.tscn")).instantiate()
	get_tree().root.add_child(tost)
	await Event.wait()
	if is_instance_valid(tost):
		tost.get_node("BoxContainer/Toast/Label").text = string

func warning(text: String, label: String = "WARNING", awnser: Array[String] = ["No", "Yes"], color: Color = Color.hex(0xdc000eff)) -> int:
	if get_node_or_null("/root/Warning"):
		$/root/Warning.free()
		await Event.wait()
	await Event.wait()
	print("Warn: "+ text)
	var tost = (preload("res://UI/Misc/Warning.tscn")).instantiate()
	get_tree().root.add_child(tost)
	await Event.wait()
	if is_instance_valid(tost):
		return await tost.ask_for_confirm(text, label, awnser, color)
	else: return false

func location_name(string: String) -> void:
	if get_node_or_null("/root/LocationName"):
		$/root/LocationName.free()
		await Event.wait()
	var tost = (await Loader.load_res("res://UI/Misc/LocationName.tscn")).instantiate()
	get_tree().root.add_child(tost)
	await Event.wait()
	if is_instance_valid(tost):
		tost.get_node("Label").text = string

#Match profile
func match_profile(named:String) -> TextProfile:
	if not ResourceLoader.exists("res://database/Text/Profiles/" + named + "Box.tres"):
		return preload("res://database/Text/Profiles/DefaultBox.tres")
	else:
		return await Loader.load_res("res://database/Text/Profiles/" + named + "Box.tres")

#endregion

func toggle(boo:bool) -> bool:
	return not boo

#region Quick Actions
func jump_to(character: Node, position: Vector2i, time: float = 5, height: float = 0.5) -> void:
	await jump_to_global(character, Area.to_global(position), time, height)

func jump_to_global(character: Node, position: Vector2, time: float = 5, height: float = 0.1, rumble = true) -> void:
	if character == Player and rumble:
		Global.rumble(0, abs(height)/3, 0.06)
	var t:Tween = create_tween()
	var start = character.global_position
	var jump_distance : float = start.distance_to(position)
	var jump_height : float = jump_distance * height #will need tweaking
	var midpoint = start.lerp(position, 0.5) + Vector2.UP * jump_height
	var jump_time = jump_distance * (time * 0.001) #will also need tweaking, this controls how fast the jump is
	t.tween_method(Query.global_quad_bezier.bind(start, midpoint, position, character), 0.0, 1.0, jump_time)
	await t.finished
	if character == Player and rumble:
		Global.rumble(0, abs(height)/2, 0.06)
	anim_done.emit()

func get_cam() -> Camera2D:
	if !is_instance_valid(Area): return null
	return Global.Area.Cam

func heal_in_overworld(target:Actor, ab: Ability):
	print(ArbData0, " healed")
	var amount:= int(max(Query.calc_num(ab), target.MaxHP*((Query.calc_num(ab)*target.Magic)*0.02)))
	target.add_health(amount)
	check_party.emit()

func screen_shake(amount:float = 15, times:float = 7, ShakeDuration:float = 0.2):
	var t = create_tween()
	t.set_ease(Tween.EASE_OUT)
	t.set_trans(Tween.TRANS_QUART)
	var dur = ShakeDuration/times
	var am  = amount
	for i in range(0, times):
		am = am - (amount/times)
		t.tween_property(Camera, "offset",
		Vector2(randi_range(-am,am), randi_range(-am,am)), dur).as_relative()
		t.tween_property(Camera, "offset", Vector2.ZERO, dur)
	await t.finished

func node_shake(node: Node, amount:= 10, repeat:= randi_range(4,8), time = 0.04):
	if not is_instance_valid(node): return
	ArbData0 = amount
	var tw = create_tween()
	tw.set_ease(Tween.EASE_OUT)
	tw.set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(self, "ArbData0", 0, (repeat*time)*4)
	for i in repeat:
		amount = ArbData0
		var t = create_tween()
		t.tween_property(node, "position:x", amount, time).as_relative()
		t.tween_property(node, "position:x", -amount*2, time*2).as_relative()
		t.tween_property(node, "position:x", amount, time).as_relative()
		await t.finished
#endregion
