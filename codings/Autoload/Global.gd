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
var device: String = "Keyboard"
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
signal lights_loaded
signal check_party
signal anim_done
signal area_initialized
signal textbox_close
signal player_ready
signal controller_changed
const AppID = 480
var UsingSteam:= false
var SteamInputDevice

var ElementColor: Dictionary = {
	heat = Color.hex(0xff6b50ff), electric = Color.hex(0xfcde42ff), natural = Color.hex(0xd1ff3cff),
	wind = Color.hex(0x56d741ff), spiritual = Color.hex(0x52f8b5ff), cold = Color.hex(0x52f8b5ff),
	liquid = Color.hex(0x57a0f9ff), technical = Color.hex(0x7f17ffff), corruption = Color.hex(0xc333c3ff),
	physical = Color.hex(0xd3446dff),

	attack = Color.hex(0xdf3737ff), magic = Color.hex(0x5a68dfff), defence = Color.hex(0x40f178ff)}
#endregion

#region System
func _ready() -> void:
	StartTime=Time.get_unix_time_from_system()
	add_child(Audio)
	Audio.volume_db = -5
	process_mode = Node.PROCESS_MODE_ALWAYS
	init_party(Party)
	init_settings()
	init_steam()
	if is_instance_valid(Area): await nodes_of_type(Area, "Light2D", Lights)
	lights_loaded.emit()
	#print(Input.get_joy_name(0))
	#Input.start_joy_vibration(0, 1, 0, 0.1)
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_ON

func _init():
	OS.set_environment("SDL_GAMECONTROLLER_IGNORE_DEVICES", "0x28de/0x11ff")

func quit() -> void:
	if Loader.InBattle or not Global.Controllable or !Player or !Area: get_tree().quit()
	Loader.icon_save()
	await Loader.transition("")
	if get_node_or_null("/root/Options"):
		await get_node("/root/Options").close()
	if is_instance_valid(Player.get_node_or_null("MainMenu")):
		await Player.get_node("MainMenu").close()
	await Loader.save()
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
		if Steam.isSteamRunningOnSteamDeck() and Settings.ControlSchemeEnum == 0:
			Settings.ControlSchemeEnum = 7
			Settings.ControlSchemeOverride = load("res://UI/Input/SteamDeck.tres")
		print(Steam.getFriendPersonaName(Steam.getSteamID()))

func game_over():
	$"/root".add_child((await Loader.load_res("res://UI/GameOver/GameOver.tscn")).instantiate())

func _notification(what) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if Controllable: quit()
		else: get_tree().quit()

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
	if UsingSteam: 
		Steam.run_callbacks()
		Steam.runFrame()

func options(save_menu:= false):
	var control = Controllable
	#var init = get_tree().root.get_node_or_null("Initializer")
	#if init != null: init.queue_free()
	var opt = (await Loader.load_res("res://UI/Options/Options.tscn")).instantiate()
	Controllable = control
	get_tree().root.add_child(opt)
	if save_menu:
		opt.save_managment()

func title_screen():
	var init = (await Loader.load_res("res://codings/Initializer.tscn")).instantiate()
	get_tree().root.add_child(init)

func member_details(chara: Actor):
	if chara == null: return
	var dub = (await Loader.load_res("res://UI/MemberDetails/MemberDetails.tscn")).instantiate()
	get_tree().root.add_child(dub)
	await Event.wait()
	dub.draw_character(chara)

func next_day_ui():
	get_tree().root.add_child((await Loader.load_res("res://UI/Misc/DayChangeUi.tscn")).instantiate())

func veinet_map(cur: String):
	var Map = (await Loader.load_res("res://UI/Map/VeinetMap.tscn")).instantiate()
	get_tree().root.add_child(Map)
	Map.focus_place(cur)

func new_game() -> void:
	if get_node_or_null("/root/Textbox"): $"/root/Textbox"._on_close()
	init_party(Party)
	FirstStartTime = Time.get_unix_time_from_system()
	Event.Flags.clear()
	Event.add_flag("Started")
	Event.f("HasBag", false)
	PartyUI.hide_all()
	Event.f("DisableMenus", true)
	Event.f("HideDate", true)
	Item.KeyInv.clear()
	Item.ConInv.clear()
	Item.MatInv.clear()
	Item.add_item("Wallet", &"Key", false)
	Item.add_item("PenCase", &"Key", false)
	Item.add_item("FoldedPaper", &"Key", false)
	#Item.add_item("SmallPotion", &"Con", false)
	Loader.Defeated.clear()
	Party.reset_party()
	Loader.white_fadeout()
	reset_all_members()
	Event.TimeOfDay = Event.TOD.NIGHT
	Event.Day = 0
	Loader.travel_to("TempleWoods", Vector2.ZERO, 0, -1, "none", false)
	await Global.area_initialized
	await Event.take_control()
	Player.BodyState = NPC.CUSTOM
	Player.set_anim("OnFloor")
	Player.get_node("%Shadow").modulate = Color.TRANSPARENT
	Player._check_party()
	var t = create_tween()
	t.set_ease(Tween.EASE_OUT)
	t.set_trans(Tween.TRANS_QUART)
	PartyUI.UIvisible = false
	t.tween_property(get_cam(), "zoom", Vector2(6,6), 6).from(Vector2(2, 2))
	Loader.save()
	await t.finished
	t = create_tween()
	t.set_ease(Tween.EASE_OUT)
	t.set_trans(Tween.TRANS_QUART)
	t.set_parallel()
	t.tween_property(Area.get_node("GetUp"), "position", Vector2(100,512), 0.2).from(Vector2(120,512))
	t.tween_property(Area.get_node("GetUp"), "modulate", Color.WHITE, 0.2).from(Color.TRANSPARENT)
	t.tween_property(Area.get_node("GetUp"), "size", Vector2(120,33), 0.2).from(Vector2(41, 33))
	Area.get_node("GetUp").show()
	await Area.get_node("GetUp").pressed
	t = create_tween()
	t.set_ease(Tween.EASE_OUT)
	t.set_trans(Tween.TRANS_QUART)
	t.set_parallel()
	PartyUI.disabled = true
	t.tween_property(Area.get_node("GetUp"), "size", Vector2(41, 33), 0.1)
	t.tween_property(Area.get_node("GetUp"), "modulate", Color.TRANSPARENT, 0.1)
	t.tween_property(get_cam(), "zoom", Vector2(5,5), 5)
	t.tween_property(Player.get_node("%Shadow"), "modulate", Color.WHITE, 3).from(Color.TRANSPARENT).set_delay(3)
	await Player.set_anim("GetUp", true)
	Player.set_anim("IdleUp")
	Controllable = true
	Event.pop_tutorial("walk")

func nodes_of_type(node: Node, className : String, result : Array) -> void:
	if !node: return
	if node.is_class(className):
		if node and (node is Light2D and node.shadow_enabled) and not "Editor" in node.name: result.push_back(node)
	for child in node.get_children():
		await nodes_of_type(child, className, result)

#endregion

#region Controller

func get_controller() -> ControlScheme:
	if !Settings: return preload("res://UI/Input/Keyboard.tres")
	if not Settings.ControlSchemeAuto:
		return Settings.ControlSchemeOverride
	if device == "Keyboard":
		return preload("res://UI/Input/Keyboard.tres")
	elif device == "Touch":
		return preload("res://UI/Input/None.tres")
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
	elif "Steam Virtual Gamepad" in device:
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
	if event is InputEventScreenTouch or event is InputEventScreenDrag:
		device = "Touch"
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
	if prev_dev != device: 
		controller_changed.emit()
		toast("Swapped to "+ device)
	LastInput=ProcessFrame
	var is_fullscreen = get_window().mode == Window.MODE_FULLSCREEN
	if is_fullscreen != Settings.Fullscreen:
		fullscreen(is_fullscreen)
	#print(device)

func cancel() -> String:
	return "ui_cancel"

func confirm() -> String:
	return "ui_accept"

func _unhandled_input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("Fullscreen"):
		fullscreen()
	if Input.is_action_just_pressed("Save"):
		Loader.save()
	if Input.is_action_just_pressed("SaveManagment"):
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
	ResourceSaver.save(Settings, "user://Settings.tres")

func init_settings() -> void:
	if not ResourceLoader.exists("user://Settings.tres"):
		print("No settings found, initializing...")
		reset_settings()
		await Event.wait()
	Settings = load("user://Settings.tres")
	if !Settings:
		print("Settings file is invalid, settings will be restored to default")
		reset_settings()
		await Event.wait()
		Settings = load("user://Settings.tres")
	if !Settings: OS.alert("Something is wrong with the settings file or user folder")
	apply_settings()

func apply_settings():
	if Settings.Fullscreen:
		fullscreen(true)
	if Settings.GlowEffect:
		World.environment.glow_enabled = true
	else: World.environment.glow_enabled = false
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
	ResourceSaver.save(Settings, "user://Settings.tres")
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

func check_member(n:int) -> bool:
	return Party.check_member(n)

func get_member_name(n:int) -> String:
	if Party.check_member(0) and n==0:
		return Party.Leader.codename
	elif Party.check_member(1) and n==1:
		return Party.Member1.codename
	elif Party.check_member(2) and n==2:
		return Party.Member2.codename
	elif Party.check_member(3) and n==2:
		return Party.Member3.codename
	else:
		return "Null"

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

func find_member(Name: StringName) -> Actor:
	for i in Members:
		if i.codename == Name: return i
	#push_error("No party member with the name "+ Name + " was found")
	return null

##Alias for find_member()
func mem(Name: StringName) -> Actor:
	return find_member(Name)

func init_party(party:PartyData) -> void:
	Members.clear()
	if !is_instance_valid(party): party = PartyData.new()
	for i in DirAccess.get_files_at("res://database/Party"):
		var file = load("res://database/Party/"+ i)
		if file is Actor:
			Members.append(file.duplicate())
	Party = PartyData.new()
	Party.set_to(party)

func number_of_party_members() -> int:
	var num= 1
	if check_member(1):
		num+=1
	if check_member(2):
		num+=1
	if check_member(3):
		num+=1
	return num

func is_in_party(n:String) -> bool:
	if Party.Leader.codename == n:
		return true
	elif Party.check_member(1) and Party.Member1.codename == n:
		return true
	elif Party.check_member(2) and Party.Member2.codename == n:
		return true
	elif Party.check_member(3) and Party.Member3.codename == n:
		return true
	else:
		return false

func unlock_all_abilities():
	for mem in Members:
		for ab in mem.LearnableAbilities:
			mem.Abilities.append(ab)
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
	if get_node_or_null("/root/Textbox"):
		$"/root/Textbox"._on_close()
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
	var tost = (await Loader.load_res("res://UI/Misc/Toast.tscn")).instantiate()
	get_tree().root.add_child(tost)
	await Event.wait()
	if is_instance_valid(tost):
		tost.get_node("BoxContainer/Toast/Label").text = string

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

#region Quick Queries
func colorize(str: String) -> String:
	for i in ElementColor.keys():
		var elname: String = i
		#str = colorize_replace(elname, str, i)
		str = colorize_replace(elname.capitalize(), str, i)
		str = colorize_replace(state_element_verbing(elname), str, i)
		str = colorize_replace(state_element_verbs(elname), str, i)
		str = colorize_replace(state_element_verbed(elname), str, i)
		str = colorize_replace(state_element_verb(elname), str, i)
	return str

func colorize_replace(elname, str: String, i) -> String:
	if elname in str:
		var hex: String = "#%02X%02X%02X" % [ElementColor[i].r*255, ElementColor[i].g*255, ElementColor[i].b*255]
		var hex_out: String = "#%02X%02X%02X" % [ElementColor[i].r*100, ElementColor[i].g*100, ElementColor[i].b*100]
		return str.replacen(elname, "[outline_size=12][outline_color=" + hex_out + "][color=" + hex + "]" + elname + "[/color][/outline_color][/outline_size]")
	return str

func get_direction(v: Vector2 = PlayerDir, allow_zero = false) -> Vector2:
	if v == Vector2.ZERO and allow_zero: return Vector2.ZERO
	if abs(v.x) > abs(v.y):
		if v.x >0:
			return Vector2.RIGHT
		else:
			return Vector2.LEFT
	else:
		if v.y >0:
			return Vector2.DOWN
		else:
			return Vector2.UP

func get_cam() -> Camera2D:
	if !is_instance_valid(Area): return Camera2D.new()
	return Area.Cam

func str_length(str: String):
	return str.length()

func get_mmm(month: int) -> String:
	match month:
		1: return "Jan"
		2: return "Fed"
		3: return "Mar"
		4: return "Apr"
		5: return "May"
		6: return "Jun"
		7: return "Jul"
		8: return "Aug"
		9: return "Sep"
		10: return "Oct"
		11: return "Nov"
		12: return "Dec"
	return "???"

func get_month(day: int) -> int:
	if day>0 and day<=30: return 11
	if day<=0: return 10
	else: return 0

func get_dir_letter(d: Vector2 = PlayerDir) -> String:
	match  get_direction(d):
		Vector2.RIGHT:
			return "R"
		Vector2.LEFT:
			return "L"
		Vector2.UP:
			return "U"
		Vector2.DOWN:
			return "D"
		_: return "C"

func get_dir_from_letter(d: String) -> Vector2:
	match d:
		"R", "Right":
			return Vector2.RIGHT
		"L", "Left":
			return Vector2.LEFT
		"U", "Up":
			return Vector2.UP
		"D", "Down":
			return Vector2.DOWN
		_:
			return Vector2.ZERO


func tilemapize(pos: Vector2) -> Vector2:
	return Area.local_to_map(pos)

func globalize(coords :Vector2i) -> Vector2:
	return Area.map_to_local(coords)

func get_state(stat: StringName) -> State:
	return await Loader.load_res("res://database/States/" + stat + ".tres")

func get_dir_name(d: Vector2 = PlayerDir) -> String:
	if get_direction(d) == Vector2.RIGHT:
		return "Right"
	elif get_direction(d) == Vector2.LEFT:
		return "Left"
	elif get_direction(d) == Vector2.UP:
		return "Up"
	elif get_direction(d) == Vector2.DOWN:
		return "Down"
	else: return "Center"

func in_360(nm) -> int:
	return wrapi(nm, 0, 359)

func alcine() -> String:
	return find_member("Alcine").FirstName

func calc_num(ab: Ability = Bt.CurrentAbility, chara: Actor = null):
	var base: int
	match ab.Damage:
		Ability.D.NONE: base = 0
		Ability.D.WEAK: base = 12
		Ability.D.MEDIUM: base = 24
		Ability.D.HEAVY: base = 48
		Ability.D.SEVERE: base = 96
		Ability.D.CUSTOM: base = int(ab.Parameter)
		Ability.D.WEAPON: base = chara.WeaponPower if chara else Bt.CurrentChar.WeaponPower
	if ab.DmgVarience:
		base = int(base * randf_range(0.8, 1.2))
	return base

func state_element_verb(str: String) -> String:
	match str:
		"heat": return "burn"
		"wind": return "launch"
		"corruption": return "poison"
		"spiritual": return "confuse"
		"cold": return "freeze"
		"technical": return "deflect"
		"physical": return "bind"
		"liquid": return "soak"
		"natural": return "leech"
		"defence": return "guard"
		"attack": return "knock out"
		"magic": return "Aura break"
	return str

func state_element_verbs(str: String) -> String:
	match str:
		"heat": return "burns"
		"wind": return "launches"
		"corruption": return "poisons"
		"spiritual": return "confuses"
		"cold": return "freezes"
		"technical": return "deflects"
		"physical": return "binds"
		"liquid": return "soaks"
		"heat": return "burns"
		"natural": return "leeches"
		"defence": return "guards"
		"attack": return "knocks out"
		"magic": return "breaks their Aura"
	return str

func state_element_verbed(str: String) -> String:
	match str:
		"heat": return "burned"
		"wind": return "launched"
		"corruption": return "poisoned"
		"spiritual": return "confused"
		"cold": return "freezed"
		"technical": return "deflected"
		"physical": return "bound"
		"liquid": return "soaked"
		"heat": return "burned"
		"natural": return "leeched"
		"defence": return "guarded"
		"attack": return "knocked out"
		"magic": return "Aura broken"
	return str

func state_element_verbing(str: String) -> String:
	match str:
		"heat": return "burning"
		"wind": return "launching"
		"corruption": return "poisoning"
		"spiritual": return "confusing"
		"cold": return "freezing"
		"technical": return "deflecting"
		"physical": return "binding"
		"liquid": return "soaking"
		"heat": return "burning"
		"natural": return "leeching"
		"defence": return "guarding"
		"attack": return "knocking out"
		"magic": return "breaking their Aura"
	return str

func get_power_rating(power: int) -> String:
	if power < 6: return "Useless"
	if power < 12: return "Very weak"
	if power < 18: return "Weak"
	if power < 24: return "Servicable"
	if power < 30: return "Avrage"
	if power < 36: return "Fine"
	if power < 42: return "Kinda good"
	if power < 48: return "Pretty good"
	if power < 54: return "Sharp"
	if power < 60: return "Pretty strong"
	if power < 66: return "Excellent"
	if power < 72: return "Powerful"
	if power < 78: return "Very powerful"
	if power < 84: return "Formidable"
	if power < 90: return "Overpowered"
	if power < 96: return "Godly"
	return "Illegal"

func to_tod_text(x: Event.TOD) -> String:
	match x:
		Event.TOD.MORNING: return "Morning"
		Event.TOD.DAYTIME: return "Daytime"
		Event.TOD.AFTERNOON: return "Afternoon"
		Event.TOD.EVENING: return "Evening"
		Event.TOD.NIGHT: return "Night"
	return "Dark hour"

func to_tod_icon(x: Event.TOD) -> Texture:
	if ResourceLoader.exists("res://UI/Calendar/" + to_tod_text(x) + ".png"):
		return await Loader.load_res("res://UI/Calendar/" + to_tod_text(x) + ".png")
	else: return null

func range_360(n1, n2) -> Array:
	if n2 > 359:
		var range1 = range(n1, 359)
		var range2 = range(0, n2 - 359)
		range1.append_array(range2)
		return range1
	elif n1 < 0:
		var range1 = range(0, n2)
		var range2 = range(359 + n1, 359)
		range2.append_array(range1)
		return range2
	else: return range(n1, n2)

func make_array_unique(arr: Array):
	for i in range(-1, arr.size() - 1):
		arr[i] = arr[i].duplicate()

func get_affinity(attacker:Color) -> Affinity:
	var aff = Affinity.new()
	var pres = round(remap(attacker.s, 0, 1, 10, 75))
	var hue = round(remap(attacker.h, 0, 1, 0, 359))
	#print(in_360(hue-pres/4)," ", in_360(hue+pres/4))
	aff.hue = hue
	aff.color = attacker
	aff.oposing_hue = in_360(hue + 180)
	aff.oposing_range = range_360(aff.oposing_hue-pres/4, aff.oposing_hue+pres/4)
	aff.weak_range = range_360(aff.oposing_range[0]-1-pres, aff.oposing_range[0]+1)
	aff.resist_range = range_360(aff.oposing_range[-1]+1, aff.oposing_range[-1]+1+max(pres, 15))
	aff.near_range = range_360(hue-max(pres/3, 10), hue+max(pres/3, 10))
	return aff

func toggle(boo:bool) -> bool:
	return not boo

func _quad_bezier(ti : float, p0 : Vector2, p1 : Vector2, p2: Vector2, target : Node2D) -> void:
	var q0 = p0.lerp(p1, ti)
	var q1 = p1.lerp(p2, ti)
	var r = q0.lerp(q1, ti)

	if target.has_method("is_on_wall") and target.is_on_wall(): return
	else: target.position = r

func global_quad_bezier(ti : float, p0 : Vector2, p1 : Vector2, p2: Vector2, target : Node2D) -> void:
	var q0 = p0.lerp(p1, ti)
	var q1 = p1.lerp(p2, ti)
	var r = q0.lerp(q1, ti)

	target.global_position = r

#Finds an ability of a certain type
func find_abilities(Char: Actor, type:String, ignore_cost:= false, targets: Ability.T = Ability.T.ANY) -> Array[Ability]:
	#print("Chosing a ", type, " ability")
	var AblilityList:Array[Ability] = Char.Abilities.duplicate()
	AblilityList.push_front(Char.StandardAttack)
	var Choices:Array[Ability] = []
	for i in AblilityList:
		if (i.Type == type and (targets == Ability.T.ANY or i.Target == targets)):
			if ((i.AuraCost < Char.Aura or i.AuraCost == 0) and i.HPCost < Char.Health) or ignore_cost:
				Choices.push_front(i)
				print(i.name, " AP: ", i.AuraCost, " Targets: ", i.Target)
			else: print("Not enough resources")
	return Choices

func find_ability(Char: Actor, type:String, ignore_cost:= false, targets: Ability.T = Ability.T.ANY) -> Ability:
	return find_abilities(Char, type, ignore_cost, targets)[0]

func is_everyone_fully_healed() -> bool:
	for i in Party.array():
		if !is_instance_valid(i): continue
		if not i.is_fully_healed(): return false
	return true

func is_mem_healed(chara: Actor):
	if !is_instance_valid(chara): return true
	return chara.is_fully_healed()
#endregion

#region Quick Actions
func jump_to(character: Node, position: Vector2i, time: float = 5, height: float = 0.5) -> void:
	await jump_to_global(character, Area.to_global(position), time, height)

func jump_to_global(character: Node, position: Vector2, time: float = 5, height: float = 0.1) -> void:
	var t:Tween = create_tween()
	var start = character.global_position
	var jump_distance : float = start.distance_to(position)
	var jump_height : float = jump_distance * height #will need tweaking
	var midpoint = start.lerp(position, 0.5) + Vector2.UP * jump_height
	var jump_time = jump_distance * (time * 0.001) #will also need tweaking, this controls how fast the jump is
	t.tween_method(global_quad_bezier.bind(start, midpoint, position, character), 0.0, 1.0, jump_time)
	await t.finished
	anim_done.emit()

func heal_in_overworld(target:Actor, ab: Ability):
	print(ArbData0, " healed")
	var amount:= int(max(calc_num(ab), target.MaxHP*((calc_num(ab)*target.Magic)*0.02)))
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
