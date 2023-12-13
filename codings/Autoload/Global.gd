extends Node

var Controllable : bool = true
var Audio := AudioStreamPlayer.new()
var Sprite := Sprite2D.new()
var Party: PartyData = PartyData.new()
var HasPortrait := false
var PortraitIMG: Texture
var PortraitRedraw := true
var PlayerDir := Vector2.DOWN
var PlayerPos: Vector2
var device: String = "Keyboard"
var ProcessFrame := 0
var LastInput=0
var AltConfirm: bool
var StartTime := 0.0
var PlayTime := 0.0
var SaveTime := 0.0
var Player: CharacterBody2D
var Follower: Array[CharacterBody2D] = [null, null, null, null]
var Settings:Setting
var Bt: Battle = null
var CameraInd := 0
var Tilemap: TileMap
var Members: Array[Actor]
var Lights: Array[Light2D] = []
var Area: Room
var Textbox2 = preload("res://codings/UI/Textbox2.tscn")
var Passive = preload("res://codings/UI/Passive.tscn")
signal lights_loaded
signal check_party
signal anim_done
signal area_initialized
signal textbox_close

#region System
func _ready() -> void:
	StartTime=Time.get_unix_time_from_system()
	add_child(Audio)
	add_child(Sprite)
	Audio.volume_db = -5
	process_mode = Node.PROCESS_MODE_ALWAYS
	init_party(load("res://database/Party/CurrentParty.tres"))
	await ready_window()
	init_settings()
	if Tilemap != null: await nodes_of_type(Tilemap, "Light2D", Lights)
	lights_loaded.emit()

func quit() -> void:
	if Loader.InBattle or Player == null or Area == null: get_tree().quit()
	Loader.icon_save()
	await Loader.transition("L")
	if get_node_or_null("/root/Options") != null:
		await get_node("/root/Options").close()
	if Player.get_node_or_null("MainMenu") != null:
		await Player.get_node("MainMenu").close()
	await Loader.save()
	get_tree().quit()

func _notification(what) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if Controllable: quit()
		else: get_tree().quit()

##Focus the window, used as a workaround to a wayland problem
func ready_window() -> void:
	if not OS.get_name() == "Linux":
		Event.wait(0.5)
		return
	for i in 180:
		await Event.wait()
		get_window().grab_focus()
	while LastInput == 0:
		await Event.wait()
		get_window().grab_focus()

func _physics_process(delta: float) -> void:
	ProcessFrame+=1

func new_game() -> void:
	init_party(PartyData.new())
	Event.Flags.clear()
	Event.add_flag("Started")
	Event.Day = 10
	Item.HasBag = false
	Item.KeyInv.clear()
	Item.ConInv.clear()
	Item.MatInv.clear()
	Party.reset_party()
	Loader.white_fadeout()
	Loader.travel_to("TempleWoods", Vector2.ZERO, 0, "none")
	await Event.wait(1)
	Controllable = false
	Global.Player.get_node("Base").play("OnFloor")
	Global.Player.get_node("Base/Shadow").hide()
	Global.Player._check_party()
	Global.Player.flame_active = false
	var t = create_tween()
	t.set_ease(Tween.EASE_OUT)
	t.set_trans(Tween.TRANS_QUART)
	PartyUI.UIvisible = false
	t.tween_property(Global.get_cam(), "zoom", Vector2(6,6), 10).from(Vector2(4,4))
	await t.finished
	t = create_tween()
	t.set_ease(Tween.EASE_OUT)
	t.set_trans(Tween.TRANS_QUART)
	t.set_parallel()
	t.tween_property(Tilemap.get_node("GetUp"), "position", Vector2(100,512), 0.2).from(Vector2(120,512))
	t.tween_property(Tilemap.get_node("GetUp"), "modulate", Color.WHITE, 0.2).from(Color.TRANSPARENT)
	t.tween_property(Tilemap.get_node("GetUp"), "size", Vector2(120,33), 0.2).from(Vector2(41, 33))
	Tilemap.get_node("GetUp").show()
	await Tilemap.get_node("GetUp").pressed
	t = create_tween()
	t.set_ease(Tween.EASE_OUT)
	t.set_trans(Tween.TRANS_QUART)
	t.set_parallel()
	t.tween_property(Tilemap.get_node("GetUp"), "size", Vector2(41, 33), 0.1)
	t.tween_property(Tilemap.get_node("GetUp"), "modulate", Color.TRANSPARENT, 0.1)
	t.tween_property(Global.get_cam(), "zoom", Vector2(5,5), 5)
	Global.Player.set_anim("GetUp")
	await Global.Player.get_node("Base").animation_finished
	Global.Player.set_anim("IdleUp")
	Global.Player.get_node("Base/Shadow").show()
	Global.Controllable = true

func nodes_of_type(node: Node, className : String, result : Array) -> void:
	if node == null: return
	if node.is_class(className):
		if node != null and (node is Light2D and node.shadow_enabled) and not "Editor" in node.name: result.push_back(node)
	for child in node.get_children():
		await nodes_of_type(child, className, result)

#endregion

#region Controller

func get_controller() -> ControlScheme:
	if Settings == null: return preload("res://UI/Input/Keyboard.tres")
	if not Settings.ControlSchemeAuto:
		return Settings.ControlSchemeOverride
	if device == "Keyboard":
		return preload("res://UI/Input/Keyboard.tres")
	if "Nintendo" in device or "Pro Controller" in device or  "GameCube" in device:
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
	if not event.is_pressed(): return
	if LastInput==ProcessFrame: return
	if event is InputEventMouseMotion: return
	if event is InputEventJoypadMotion  and event.axis_value < 0.5: return
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
	LastInput=ProcessFrame
	Engine.set_physics_ticks_per_second(int(DisplayServer.screen_get_refresh_rate()))
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

#endregion

#region Settings

func fullscreen() -> void:
	if Settings == null: await init_settings()
	if get_window().mode != 3:
			get_window().mode = Window.MODE_FULLSCREEN
			await get_tree().create_timer(0.1).timeout
			get_window().grab_focus()
			Settings.Fullscreen = true
	else:
		get_window().mode = Window.MODE_WINDOWED
		if OS.get_name() == "Linux":
			get_window().size = Vector2i(1280,800)
			await get_tree().create_timer(0.03).timeout
			get_window().position = DisplayServer.screen_get_size(0)/2 - Vector2i(1280,800)/2
			await get_tree().create_timer(0.15).timeout
			get_window().grab_focus()
		Settings.Fullscreen = false
	save_settings()

func get_preview() -> Texture:
	if Party.Leader.FirstName == "Mira" and not Party.check_member(1):
		return preload("res://art/Previews/1.png")
	if Party.Leader.FirstName == "Mira" and Party.Member1.FirstName == "Alcine":
		return preload("res://art/Previews/2.png")
	return preload("res://art/Previews/1.png")

func reset_settings() -> void:
	ResourceSaver.save(Setting.new(), "user://Settings.tres")

func init_settings() -> void:
	if not ResourceLoader.exists("user://Settings.tres"):
		reset_settings()
		await get_tree().create_timer(0.5).timeout
	Settings = preload("user://Settings.tres")
	if Settings.Fullscreen:
		fullscreen()
	AudioServer.set_bus_volume_db(0, Global.Settings.MasterVolume)

func get_playtime() -> int:
	PlayTime = SaveTime + Time.get_unix_time_from_system() - StartTime
	return int(PlayTime)

func save_settings() -> void:
	ResourceSaver.save(Settings, "user://Settings.tres")
#endregion

#region UI Sounds

func cursor_sound() -> void:
	Audio.stream = preload("res://sound/SFX/UI/cursor.wav")
	Audio.play()
func buzzer_sound() -> void:
	Audio.stream = preload("res://sound/SFX/UI/buzzer.ogg")
	Audio.play()
func confirm_sound() -> void:
	Audio.stream = preload("res://sound/SFX/UI/confirm.ogg")
	Audio.play()
func cancel_sound() -> void:
	Audio.stream = preload("res://sound/SFX/UI/Quit.ogg")
	Audio.play()
func item_sound() -> void:
	Audio.stream = preload("res://sound/SFX/UI/item.ogg")
	Audio.play()
func ui_sound(string:String) -> void:
	Audio.stream = await Loader.load_res("res://sound/SFX/UI/"+string+".ogg")
	Audio.play()

#endregion

#region Party Checks
func get_party() -> PartyData:
	return preload("res://database/Party/CurrentParty.tres")

func check_member(n:int) -> bool:
	return Party.check_member(n)
	#Sprite.texture = preload("res://art/Placeholder.png")

func get_member_name(n:int) -> String:
	if Party.check_member(0) and n==0:
		return Party.Leader.FirstName
	elif Party.check_member(1) and n==1:
		return Party.Member1.FirstName
	elif Party.check_member(2) and n==2:
		return Party.Member2.FirstName
	elif Party.check_member(3) and n==2:
		return Party.Member3.FirstName
	else:
		return "Null"

func find_member(Name: String) -> Actor:
	for i in Members:
		if i.FirstName == Name: return i
	return Party.Leader

func init_party(party:PartyData) -> void:
	Members.clear()
	for i in DirAccess.get_files_at("res://database/Party"):
		var file = load("res://database/Party/"+ i)
		if file is Actor:
			Members.push_front(file)
	#Party = PartyData.new()
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
	if Party.Leader.FirstName == n:
		return true
	elif Party.check_member(1) and Party.Member1.FirstName == n:
		return true
	elif Party.check_member(2) and Party.Member2.FirstName == n:
		return true
	elif Party.check_member(3) and Party.Member3.FirstName == n:
		return true
	else:
		return false

#endregion

#region Textbox Managment

## Show the custom balloon
func textbox(file: String, title: String = "0", extra_game_states: Array = []) -> void:
#	Loader.load_thread("res://database/Text/" + file + ".dialogue")
#	await Loader.thread_loaded
	var balloon: Node = Textbox2.instantiate()
	get_tree().root.add_child(balloon)
	balloon.start(await Loader.load_res("res://database/Text/" + file + ".dialogue"), title, extra_game_states)
	await textbox_close

func passive(file: String, title: String = "0", extra_game_states: Array = []) -> void:
#	Loader.load_thread("res://database/Text/" + file + ".dialogue")
#	await Loader.thread_loaded
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

func next_box(profile:String) -> void:
	$/root.get_node("Textbox").next_box = profile

func toast(string: String) -> void:
	if get_node_or_null("/root/Toast") != null:
		$/root/Toast.queue_free()
		await Event.wait()
	get_tree().root.add_child(preload("res://UI/Misc/Toast.tscn").instantiate())
	await Event.wait()
	$"/root/Toast/BoxContainer/Toast/Label".text = string


#Match profile
func match_profile(named:String) -> TextProfile:
	if not ResourceLoader.exists("res://database/Text/Profiles/" + named + ".tres"):
		return preload("res://database/Text/Profiles/Default.tres")
	else:
		return await Loader.load_res("res://database/Text/Profiles/" + named + ".tres")

#endregion

#region Quick Queries
func get_direction(v: Vector2 = PlayerDir) -> Vector2:
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
	return Area.Cam
	#return Area.get_node("Camera"+str(CameraInd))

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
	else: return 0

func get_dir_letter(d: Vector2 = PlayerDir) -> String:
	if get_direction(d) == Vector2.RIGHT:
		return "R"
	elif get_direction(d) == Vector2.LEFT:
		return "L"
	elif get_direction(d) == Vector2.UP:
		return "U"
	elif get_direction(d) == Vector2.DOWN:
		return "D"
	else: return "C"

func tilemapize(pos: Vector2) -> void:
	return Tilemap.local_to_map(pos)

func globalize(coords :Vector2i) -> Vector2:
	return Tilemap.map_to_local(coords)

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
	var n = int(nm)
	if n > 359: return n - 359
	elif n < 0: return 359 + n
	else: return n

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
	if boo: return false
	else: return true

func _quad_bezier(ti : float, p0 : Vector2, p1 : Vector2, p2: Vector2, target : Node2D) -> void:
	var q0 = p0.lerp(p1, ti)
	var q1 = p1.lerp(p2, ti)
	var r = q0.lerp(q1, ti)

	target.position = r

func global_quad_bezier(ti : float, p0 : Vector2, p1 : Vector2, p2: Vector2, target : Node2D) -> void:
	var q0 = p0.lerp(p1, ti)
	var q1 = p1.lerp(p2, ti)
	var r = q0.lerp(q1, ti)

	target.global_position = r

#endregion

#region Quick Tweens
func jump_to(character:Node, position:Vector2, time:float, height: float =0.1) -> void:
	var t:Tween = create_tween()
	var start = character.position
	var jump_distance : float = start.distance_to(position)
	var jump_height : float = jump_distance * height #will need tweaking
	var midpoint = start.lerp(position, 0.5) + Vector2.UP * jump_height
	var jump_time = jump_distance * (time * 0.001) #will also need tweaking, this controls how fast the jump is
	t.tween_method(Global._quad_bezier.bind(start, midpoint, position, character), 0.0, 1.0, jump_time)
	await t.finished
	anim_done.emit()

func jump_to_global(character:Node, position:Vector2, time:float, height: float =0.1) -> void:
	var t:Tween = create_tween()
	var start = character.global_position
	var jump_distance : float = start.distance_to(position)
	var jump_height : float = jump_distance * height #will need tweaking
	var midpoint = start.lerp(position, 0.5) + Vector2.UP * jump_height
	var jump_time = jump_distance * (time * 0.001) #will also need tweaking, this controls how fast the jump is
	t.tween_method(Global.global_quad_bezier.bind(start, midpoint, position, character), 0.0, 1.0, jump_time)
	await t.finished
	anim_done.emit()

#endregion

