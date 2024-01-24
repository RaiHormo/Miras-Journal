#region Variables
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
var Player := Mira.new()
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

var ElementColor: Dictionary = {
	heat = Color.hex(0xff6b50ff), electric = Color.hex(0xfcde42ff), natural = Color.hex(0xd1ff3cff),
	wind = Color.hex(0x56d741ff), spiritual = Color.hex(0x52f8b5ff), cold = Color.hex(0x52f8b5ff),
	liquid = Color.hex(0x57a0f9ff), technical = Color.hex(0x7f17ffff), corruption = Color.hex(0xc34dc3ffff),
	physical = Color.hex(0xd3446dff)}
#endregion

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
	await Loader.transition("")
	if get_node_or_null("/root/Options") != null:
		await get_node("/root/Options").close()
	if Player.get_node_or_null("MainMenu") != null:
		await Player.get_node("MainMenu").close()
	await Loader.save()
	get_tree().quit()

func normal_mode():
	Area.queue_free()
	get_tree().change_scene_to_file("res://scenes/Initializer.tscn")

func game_over():
	$"/root".add_child(preload("res://UI/GameOver/GameOver.tscn").instantiate())

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

func options():
	get_tree().root.add_child(preload("res://UI/Options/Options.tscn").instantiate())

func new_game() -> void:
	if get_node_or_null("/root/Textbox") != null: $"/root/Textbox"._on_close()
	init_party(PartyData.new())
	Event.Flags.clear()
	Event.add_flag("Started")
	Event.Day = 10
	Item.HasBag = false
	Item.KeyInv.clear()
	Item.ConInv.clear()
	Item.MatInv.clear()
	Item.add_item("PenCase", &"Key", false)
	Item.add_item("FoldedPaper", &"Key", false)
	Item.add_item("Wallet", &"Key", false)
	Party.reset_party()
	Loader.white_fadeout()
	Loader.travel_to("TempleWoods", Vector2.ZERO, 0, -1, "none")
	await Event.wait(1)
	reset_all_members()
	Controllable = false
	Player.set_anim("OnFloor")
	Player.get_node("%Base/Shadow").modulate = Color.TRANSPARENT
	Player._check_party()
	var t = create_tween()
	t.set_ease(Tween.EASE_OUT)
	t.set_trans(Tween.TRANS_QUART)
	PartyUI.UIvisible = false
	t.tween_property(get_cam(), "zoom", Vector2(6,6), 10).from(Vector2(4,4))
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
	PartyUI.disabled = true
	t.tween_property(Tilemap.get_node("GetUp"), "size", Vector2(41, 33), 0.1)
	t.tween_property(Tilemap.get_node("GetUp"), "modulate", Color.TRANSPARENT, 0.1)
	t.tween_property(get_cam(), "zoom", Vector2(5,5), 5)
	t.tween_property(Player.get_node("%Base/Shadow"), "modulate", Color.WHITE, 3).from(Color.TRANSPARENT).set_delay(3)
	await Player.set_anim("GetUp", true)
	Player.set_anim("IdleUp")
	Controllable = true
	Event.pop_tutorial("walk")
	Loader.save()

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
	if Party.Leader.codename == "Mira" and not Party.check_member(1):
		return preload("res://art/Previews/1.png")
	if Party.Leader.codename == "Mira" and Party.Member1.codename == "Alcine":
		return preload("res://art/Previews/2.png")
	return preload("res://art/Previews/1.png")

func reset_settings() -> void:
	ResourceSaver.save(Setting.new(), "user://Settings.tres")

func init_settings() -> void:
	if not ResourceLoader.exists("user://Settings.tres"):
		print("No settings found, initializing...")
		reset_settings()
		await get_tree().create_timer(0.5).timeout
	Settings = load("user://Settings.tres")
	if Settings.Fullscreen:
		fullscreen()
	AudioServer.set_bus_volume_db(0, Settings.MasterVolume)

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

func reset_all_members() -> void:
	for i in range(-1, Members.size() - 1):
		Members[i] = load("res://database/Party/"+ Members[i].codename +".tres")

func find_member(Name: StringName) -> Actor:
	for i in Members:
		if i.codename == Name: return i
	return Party.Leader

func init_party(party:PartyData) -> void:
	Members.clear()
	for i in DirAccess.get_files_at("res://database/Party"):
		var file = load("res://database/Party/"+ i)
		if file is Actor:
			Members.push_front(file.duplicate())
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

#endregion

#region Textbox Managment

## Show the custom balloon
func textbox(file: String, title: String = "0", extra_game_states: Array = []) -> void:
	if get_node_or_null("/root/Textbox") != null: $"/root/Textbox".free(); await Event.wait()
	var balloon: Node = Textbox2.instantiate()
	get_tree().root.add_child(balloon)
	if balloon == null: return
	balloon.start(await Loader.load_res("res://database/Text/" + file + ".dialogue"), title, extra_game_states)
	await textbox_close

func passive(file: String, title: String = "0", extra_game_states: Array = []) -> void:
	if get_node_or_null("/root/Textbox") != null:
		$"/root/Textbox"._on_close()
		await textbox_close
		await Event.wait(0.1)
		passive(file, title, extra_game_states)
		return
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

func toast(string: String) -> void:
	if get_node_or_null("/root/Toast") != null:
		$/root/Toast.free()
		await Event.wait()
	var tost = preload("res://UI/Misc/Toast.tscn").instantiate()
	get_tree().root.add_child(tost)
	await Event.wait()
	if tost != null:
		tost.get_node("BoxContainer/Toast/Label").text = string


#Match profile
func match_profile(named:String) -> TextProfile:
	if not ResourceLoader.exists("res://database/Text/Profiles/" + named + ".tres"):
		return preload("res://database/Text/Profiles/Default.tres")
	else:
		return await Loader.load_res("res://database/Text/Profiles/" + named + ".tres")

#endregion

#region Quick Queries
func colorize(str: String) -> String:
	for i in ElementColor.keys():
		var elname: String = i
		elname = elname.to_pascal_case()
		if elname in str:
			var hex: String = "#%02X%02X%02X" % [ElementColor[i].r*255, ElementColor[i].g*255, ElementColor[i].b*255]
			var hex_out: String = "#%02X%02X%02X" % [ElementColor[i].r*100, ElementColor[i].g*100, ElementColor[i].b*100]
			str = str.replace(elname, "[outline_size=12][outline_color=" + hex_out + "][color=" + hex + "]" + elname + "[/color][/outline_color][/outline_size]")
	return str

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
#endregion

#region Quick Tweens
func jump_to(character:Node, position:Vector2, time:float=5, height: float =0.5) -> void:
	var t:Tween = create_tween()
	var start = character.position
	var jump_distance : float = start.distance_to(position)
	var jump_height : float = jump_distance * height #will need tweaking
	var midpoint = start.lerp(position, 0.5) + Vector2.UP * jump_height
	var jump_time = jump_distance * (time * 0.001) #will also need tweaking, this controls how fast the jump is
	t.tween_method(_quad_bezier.bind(start, midpoint, position, character), 0.0, 1.0, jump_time)
	await t.finished
	anim_done.emit()

func jump_to_global(character:Node, position:Vector2, time:float, height: float =0.1) -> void:
	var t:Tween = create_tween()
	var start = character.global_position
	var jump_distance : float = start.distance_to(position)
	var jump_height : float = jump_distance * height #will need tweaking
	var midpoint = start.lerp(position, 0.5) + Vector2.UP * jump_height
	var jump_time = jump_distance * (time * 0.001) #will also need tweaking, this controls how fast the jump is
	t.tween_method(global_quad_bezier.bind(start, midpoint, position, character), 0.0, 1.0, jump_time)
	await t.finished
	anim_done.emit()

#endregion

