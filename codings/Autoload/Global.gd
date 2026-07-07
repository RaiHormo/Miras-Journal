extends Node

## Determines if the player should have control
## Prefer to use Event.give_control() and Event.take_control() instead of this
var Controllable: bool = true:
	set(x):
		Controllable = x

## Data for all party members (Outside of the party too)
var Members: Array[Actor]

## Current battle scene, null if not in battle
var Bt: Battle = null

## Current player node
var Player: Mira:
	get():
		if is_instance_valid(Player):
			return Player
		return null

## The current party data
var Party: PartyData

## Current room node
var Area: Room

## Active camera in the Area (Not battle camera)
var Camera: Camera2D:
	get:
		if not is_instance_valid(Area): 
			return null
		return Global.Area.cam

## The current settings
var Settings: Setting

## Complimentary abilities available
var Complimentaries: Array[String]

## Time info
var process_frame := 0
var start_time := 0.0
var first_start_time := 0.0
var play_time := 0.0
var save_time := 0.0

## Steam data
var using_steam := false
var steam_app_id := 4059970
var steam_user_id: int

## Account identifier for the player (Shown in the menu)
var player_name: String = "Local"

## For updating info like the party
signal check

#region System
func _ready() -> void:
	init_user()
	start_time = Time.get_unix_time_from_system()
	process_mode = Node.PROCESS_MODE_ALWAYS
	init_party(Party)
	init_settings()

	#print(Input.get_joy_name(0))
	Controller.rumble(0, 0.1, 0.1)
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_ON


func quit(save_first := true) -> void:
	if save_first:
		if get_tree().root.has_node("Options"):
			get_tree().root.get_node("Options").close()
		if get_tree().root.has_node("MainMenu"):
			get_tree().root.get_node("MainMenu").close()
		if (
			not Loader.in_battle and is_instance_valid(Player) and is_instance_valid(Area) and (
			Global.Controllable or get_tree().root.has_node("MainMenu") or get_tree().root.has_node("Options"))
		):
			Loader.icon_save()
			await Loader.save()
		elif is_instance_valid(Area):
			if not await Event.warning("The game cannot be saved right now.\nQuit the game anyways?", "QUIT", ["Canel", "Quit Game"]):
				return
		await Loader.transition(Direction.CENTER)
		if Engine.has_singleton("Steam") and using_steam:
			Steam.steamShutdown()
		Global.save_settings()
	get_tree().quit()


func normal_mode() -> void:
	Area.queue_free()
	get_tree().change_scene_to_file("res://scenes/Initializer.tscn")


func init_steam() -> void:
	if not Engine.has_singleton("Steam"):
		return
	var steam := Engine.get_singleton("Steam")
	OS.set_environment("SteamAppId", str(steam_app_id))
	OS.set_environment("SteamGameId", str(steam_app_id))
	var initialize_response: Dictionary = steam.steamInitEx(steam_app_id)
	print_rich("[color=orange]Did Steam initialize?: %s " % initialize_response)
	#Steam.inputInit()
	#Steam.enableDeviceCallbacks()
	#SteamInput.init()
	if initialize_response.get("status") == 0:
		print_rich("[color=orange]Running with Steam")
		using_steam = true
		steam_user_id = steam.getSteamID32(steam.getSteamID())
		player_name = steam.getPersonaName()
		print_rich("[color=orange]User: ", player_name, " ", steam_user_id)
	elif (
		initialize_response.get("status") == 1 and
		initialize_response.get("verbal") != "Could not determine Steam client install directory."
	):
		if not steam.isSubscribed():
			if steam_app_id == 4059970:
				print_rich("[color=orange]The user doesn't own the game, testing playtest")
				steam_app_id = 4063790
				init_steam()
				return
			elif steam_app_id == 4063790:
				print_rich("[color=orange]The user doesn't own playtest either, running locally")


func init_user() -> void:
	steam_user_id = 0
	init_steam()

	# If a user ID wasn't set by steam
	if steam_user_id == 0:
		if FileAccess.file_exists("user://last_user_id.txt"):
			steam_user_id = int(FileAccess.get_file_as_string("user://last_user_id.txt"))
			print_rich("[color=orange]Using last used user ID, ", steam_user_id)

	# Create a user folder if it doesn't exist
	if not DirAccess.dir_exists_absolute("user://" + str(steam_user_id)):
		print_rich("[color=orange]Creating user folder for ", steam_user_id)
		DirAccess.make_dir_absolute("user://" + str(steam_user_id))

	# If there's an ID now but, the previous one was 0, migrate the save data
	if FileAccess.file_exists("user://last_user_id.txt"):
		var last_id: int = int(FileAccess.get_file_as_string("user://last_user_id.txt"))
		if FileAccess.file_exists("user://" + str(steam_user_id)) and last_id == 0 and steam_user_id != 0:
			print_rich("[color=orange]Migrating from local to account")
			for i in DirAccess.get_files_at("user://0"):
				if not FileAccess.file_exists("user://" + str(steam_user_id) + "/" + i):
					DirAccess.copy_absolute("user://0/" + i, "user://" + str(steam_user_id) + "/" + i)

	# Write the current ID to a file
	var last_id_file: FileAccess = FileAccess.open("user://last_user_id.txt", FileAccess.WRITE)
	last_id_file.store_string(str(steam_user_id))

	# Move user:// to the new directory
	ProjectSettings.set("application/config/custom_user_dir_name", "miras-journal/" + str(steam_user_id))


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_WM_CLOSE_REQUEST:
			quit()
		NOTIFICATION_WM_ABOUT:
			OS.shell_open("https://raidev.eu/miras-journal")


func _physics_process(delta: float) -> void:
	process_frame += 1


static func alcine() -> String:
	return Query.find_member("Alcine").FirstName


func nodes_of_type(node: Node, className: String, result: Array) -> void:
	if !node: return
	if node.is_class(className):
		if node and (node is Light2D and node.shadow_enabled) and not "Editor" in node.name: result.push_back(node)
	for child in node.get_children():
		await nodes_of_type(child, className, result)
#endregion


#region Settings


func refresh() -> void:
	await Loader.save()
	Loader.load_game()
	print(Input.should_ignore_device(0x28de0, 0x11ff))


func fullscreen(tog: bool = !Settings.Fullscreen) -> void:
	if !Settings: await init_settings()
	if Engine.is_embedded_in_editor():
		Event.toast("Can't fullscreen while the window is embeded")
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
		#if OS.to_string() == "Linux":
			#get_window().size = Vector2i(1280,800)
			#await get_tree().create_timer(0.03).timeout
			#get_window().position = DisplayServer.screen_get_size(0)/2 - Vector2i(1280,800)/2
	await get_tree().create_timer(0.15).timeout
	get_window().grab_focus()
	save_settings()


func reset_settings() -> void:
	Settings = Setting.new()
	customize_default_settings()
	var error: Error = ResourceSaver.save(Settings, "user://Settings.res")
	if error != OK:
		printerr(error_string(error))
		#OS.alert("Cannot write to save data directory: "+error_string(error))


func customize_default_settings() -> void:
	if using_steam:
		var steam := Engine.get_singleton("Steam")
		if OS.get_environment("STEAMDECK") == "1" or steam.isSteamRunningOnSteamDeck():
			Settings.ControlSchemeEnum = 7
			Settings.ControlSchemeOverride = load("res://UI/Input/SteamDeck.tres")
			print_rich("[color=orange]Running on Steam Deck, setting control scheme")
		if steam.isSteamInBigPictureMode():
			fullscreen(true)
			print_rich("[color=orange]Running on Big Picture, enabling fullscreen")
	if OS.to_string() == "macOS":
		Settings.UpscaledRes = false


func init_settings() -> void:
	if not ResourceLoader.exists("user://Settings.res"):
		print_rich("[color=orange]No settings found, initializing...")
		reset_settings()
		await Event.wait()
	Settings = ResourceLoader.load("user://Settings.res")
	if not is_instance_valid(Settings):
		print_rich("[color=orange]Settings file is invalid, settings will be restored to default")
		reset_settings()
		await Event.wait()
		Settings = load("user://Settings.res")
	if not is_instance_valid(Settings):
		OS.alert("Something is wrong with the settings file or user folder")
	apply_settings()


func apply_settings() -> void:
	#const base_res := Vector2(1280, 800)
	if Settings.Fullscreen:
		fullscreen(true)
	if Settings.GlowEffect:
		World.environment.glow_enabled = true
	else: World.environment.glow_enabled = false
	if Settings.UpscaledRes:
		get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	else:
		get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	#else:
		#get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
		#get_window().content_scale_size = base_res * Settings.UpscaleFactor
		#get_window().content_scale_factor = Settings.UpscaleFactor
	AudioServer.set_bus_volume_db(0, Settings.MasterVolume)
	AudioServer.set_bus_volume_db(1, Settings.MusicVolume)
	AudioServer.set_bus_volume_db(2, Settings.EnvSFXVolume)
	AudioServer.set_bus_volume_db(3, Settings.BtSFXVolume)
	AudioServer.set_bus_volume_db(4, Settings.UIVolume)
	AudioServer.set_bus_volume_db(4, Settings.VoicesVolume)
	if Settings.VSync: DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	else: DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	if using_steam:
		Settings.PlayerName = player_name
	else: player_name = Settings.PlayerName
	Global.save_settings()

func get_playtime() -> int:
	play_time = save_time + Time.get_unix_time_from_system() - start_time
	return int(play_time)


func save_settings() -> void:
	ResourceSaver.save(Settings, "user://Settings.res")
	print_rich("[color=orange]Settings saved")
#endregion

#region Party Checks
func heal_party() -> void:
	for i in Members:
		i.full_heal()


func add_test_state(chara: Actor) -> void:
	for i in ResourceLoader.list_directory("res://database/States/"):
		var state: String = i.replace(".tres", "")
		var ab: Ability = load("res://database/Abilities/Debug/TestState.tres").duplicate()
		ab.name += state
		ab.InflictsState = state
		chara.Abilities.append(ab)


func reset_all_members() -> void:
	init_party(Party)
	for i in range(-1, Members.size() - 1):
		Members[i] = load("res://database/Party/" + Members[i].codename + ".tres").duplicate(true)
	Party.set_to_party(Party)

##Alias for find_member()


func init_party(party: PartyData) -> void:
	Members.clear()
	if !is_instance_valid(party): party = PartyData.new()
	for i in ResourceLoader.list_directory("res://database/Party"):
		var file: Resource = load("res://database/Party/" + i)
		if file is Actor:
			Members.append(file.duplicate())
	Party = PartyData.new()
	Party.set_to_party(party)


func unlock_all_abilities() -> void:
	for mem in Members:
		for ab in mem.LearnableAbilities:
			mem.Abilities.append(ab)


func give_every_ability() -> void:
	for i in ResourceLoader.list_directory("res://database/Abilities/"):
		var ab: Ability = load("res://database/Abilities/" + i).duplicate()
		Party.Leader.Abilities.append(ab)

func add_complimentary(ability: String) -> void:
	if ability not in Global.Complimentaries:
		Global.Complimentaries.append(ability)

func use_ability_overworld(ab: Ability, user: Actor) -> void:
	get_viewport().gui_release_focus()
	if Ability.TP.HEALING in ab.Types:
		await PartyUI.choose_member(ab, user)
#endregion
