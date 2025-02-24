extends Control

const SaveVersion = 4

@export var scene: Array[String] = []
var status
var progress = []
var loading = false
var loading_thread = false
var load_failed = false
@export var direc : String
@onready var t: Tween
var Seq: BattleSequence = preload("res://database/BattleSeq/DebugDummy.tres")
var InBattle = false
signal thread_loaded
var loaded_resource
var traveled_pos
@onready var Icon = $Can/Icon
var BattleResult=0
var chased = false
var Attacker: Node2D
var CamZoom:Vector2 = Vector2(4,4)
var Defeated:Array
var Preview
var BtAdvantage = 0
var data: SaveFile
var SaveFiles: Array[SaveFile]
signal battle_start
signal battle_end
signal ungray

func _ready():
	$Can.hide()
	Icon.global_position = Vector2(1181, 870)
	t = create_tween()
	t.tween_property(self, "position", position, 0)
	validate_save("user://Autosave.tres")

func save(filename:String="Autosave", showicon=true):
	if !Global.Player or !Global.Area:
		OS.alert("Cannot save right now")
		return
	print("Saving to user://"+filename+".tres")
	if showicon:
		icon_save()
	data = SaveFile.new()
	data.Name = filename
	data.Datetime = Time.get_datetime_dict_from_system()
	data.Party = Global.Party.get_strarr()
	data.StartTime = Global.StartTime
	data.Z = (Global.Player.z_index if !get_tree().root.get_node_or_null("MainMenu")
		else $"/root/MainMenu".z)
	data.SavedTime = Time.get_unix_time_from_system()
	data.PlayTime = Global.get_playtime()
	data.Position = Global.Player.global_position
	data.Camera = Global.CameraInd
	data.Defeated = Defeated.duplicate()
	data.Members = Global.Members.duplicate()
	Global.make_array_unique(data.Members)
	data.version = SaveVersion
	data.Flags = Event.Flags.duplicate()
	for i in data.Members:
		data.Members[data.Members.find(i)] = i.duplicate()

	data.Inventory = Item.combined_inv()
	for i in data.Inventory:
		data.Inventory[data.Inventory.find(i)] = i.duplicate()

	data.RoomPath = Global.Area.scene_file_path
	if Global.Area.CurSubRoom != null: data.RoomPath += ";" + Global.Area.CurSubRoom.name
	data.RoomName = Global.Area.Name
	data.Day = Event.Day
	data.TimeOfDay = Event.TimeOfDay
	ResourceSaver.save(data, "user://"+filename+".tres")
	Preview = (data.preview())

func load_game(filename:String="Autosave", sound:= true, predefined:= false, close_first:= true, transition_after_done = true):
	if sound: Global.ui_sound("Load")
	if filename=="File0": filename = "Autosave"
	var filepath = "res://database/IncludedSaves/"+filename+".tres" if predefined else "user://"+filename+".tres"
	if not FileAccess.file_exists(filepath): await save()
	print("Loading " + filepath)
	if is_instance_valid(Global.Bt): Global.Bt.free()
	t = create_tween()
	t.tween_property(Icon, "global_position", Vector2(1181, 702), 0.2).from(Vector2(1181, 900))
	Icon.play("Load")
	if close_first: await transition("")
	else: transition("")
	if not validate_save(filepath):
		OS.alert("Save data is corrupt")
		get_tree().quit()
		return
	data = await load_res(filepath)
	Global.StartTime = Time.get_unix_time_from_system()
	Global.SaveTime = data.PlayTime
	Defeated = data.Defeated.duplicate()
	Global.CameraInd = data.Camera
	PartyUI.UIvisible = true
	PartyUI.disabled = false
	Event.Flags = data.Flags.duplicate()
	print("Flags loaded: ", Event.Flags)
	Event.Day = data.Day
	Event.TimeOfDay = data.TimeOfDay as Event.TOD
	print("Date ID loaded: ", Event.Day)
	get_tree().paused = true
	if !data:
		OS.alert("This save file doen't exist", "WHERE FILE")
	if !data.RoomPath:
		OS.alert("There's no room set in this savefile", "WHERE TF ARE YOU")
	for i in get_tree().root.get_children():
		if i is Room: i.queue_free()
	var sc_split = data.RoomPath.split(";")
	get_tree().root.add_child((await load_res(sc_split[0])).instantiate())

	Item.load_inventories(data)

	var temp_members = data.Members.duplicate()
	if temp_members < Global.Members:
		Global.toast("WARNING: This save file was created in an older version.")
		for j in Global.Members:
			var exists = false
			for i in temp_members:
				if i.codename == j.codename: exists = true
			if not exists: temp_members.append(j)
	Global.Members = temp_members
	Global.make_array_unique(Global.Members)
	Global.Party.set_to_strarr(data.Party)
	print("Current party: ", data.Party)
	for i in Global.Members: i.reset_static_info()

	await Global.area_initialized
	if sc_split.size() > 1: Global.Area.go_to_subroom(sc_split[1])
	Global.Player.global_position = data.Position
	PartyUI._check_party()
	Global.Area.handle_z(data.Z)
	print("Loading room ", data.RoomName, " in camera ID ", data.Camera, " and Z index ", data.Z)
	await Item.verify_inventory()
	if $/root.get_node_or_null("MainMenu"):
		$/root.get_node("MainMenu").queue_free()
	if $/root.get_node_or_null("Options"):
		$/root.get_node("Options").queue_free()
	PartyUI.shrink.emit()
	if transition_after_done:
		await detransition()
		Event.give_control()
	else:
		await Event.take_control()
		dismiss_load_icon()
	print("File loaded!\n-------------------------")

func load_res(path: String) -> Resource:
	load_failed = false
	var frame := Global.ProcessFrame
	if not Global.Settings.HighResTextures:
		if ResourceLoader.exists(path.replace(".png", "_low.png")):
			path = path.replace(".png", "_low.png")
	loaded_resource = path
	if ResourceLoader.exists(path):
		ResourceLoader.load_threaded_request(path)
	else: push_error("Resource "+ path+ " not found")
	loading_thread = true
	await thread_loaded
	if Global.ProcessFrame - frame > 1:
		print("Loaded resource ", path, " in ", Global.ProcessFrame - frame, " frames")
	#if load_failed: return null
	return ResourceLoader.load_threaded_get(path)

func travel_to_coords(sc, pos:Vector2=Vector2.ZERO, camera_ind:int=0, z:= -1, trans=Global.get_dir_letter()):
	travel_to(sc, Global.Area.map_to_local(pos), camera_ind, z, trans)

func travel_to(sc: String, pos: Vector2=Vector2.ZERO, camera_ind: int=0, z := -1, trans=Global.get_dir_letter()):
	direc = trans
	print("Traveling to room \"", sc, "\" in camera ID ", camera_ind, " and Z index ", z)
	if t.is_running(): await t.finished
	Event.List.clear()
	traveled_pos = pos
	Global.CameraInd = camera_ind
	scene.assign((sc.split(";").duplicate()))
	sc = scene[0]
	scene[0] = "res://rooms/" + sc + ".tscn"
	if scene[0] != "":
		ResourceLoader.load_threaded_request(scene[0])
	await transition(trans)
	status = ResourceLoader.load_threaded_get_status(scene[0], progress)
	await Event.wait()
	if status == ResourceLoader.THREAD_LOAD_LOADED:
		await done()
		if z >= 0: Global.Area.handle_z(z)
	else:
		Icon.play("Load")
		loading = true

func _process(delta):
	if loading == true and !scene.is_empty():
		status = ResourceLoader.load_threaded_get_status(scene[0], progress)
		error_handle(status)
		if status == ResourceLoader.THREAD_LOAD_LOADED:
			loading = false
			done()
	if loading_thread == true:
		status = ResourceLoader.load_threaded_get_status(loaded_resource)
		error_handle(status)
		if status == ResourceLoader.THREAD_LOAD_LOADED or load_failed:
			loading_thread = false
			thread_loaded.emit()

func transition(dir=Global.get_dir_letter()):
	if dir == "none": return
	Global.Controllable = false
	if get_node_or_null("/root/Textbox"): $"/root/Textbox"._on_close()
	t.kill()
	t=create_tween()
	t.set_parallel(false)
	t.set_ease(Tween.EASE_IN)
	t.set_trans(Tween.TRANS_QUART)
	direc = dir
	if Icon.is_playing():
		t.tween_property(Icon, "global_position", Vector2(1181, 702), 0.2).from(Vector2(1181, 900))
	$Can.show()
	$Can.layer = 9
	$Can/Bars.modulate = Color.WHITE
	if dir == "U":
		t.parallel()
		t.tween_property($Can/Bars/Down, "global_position", Vector2(-235,-126), 0.3).from(Vector2(-235,786))
	elif dir == "D":
		t.parallel()
		t.tween_property($Can/Bars/Up, "global_position", Vector2(-156,-126), 0.3).from(Vector2(-156,-1096))
	elif dir == "R":
		t.parallel()
		t.tween_property($Can/Bars/Left, "global_position", Vector2(0,-204), 0.3).from(Vector2(-1720,-204))
	elif dir == "L":
		t.parallel()
		t.tween_property($Can/Bars/Right, "global_position", Vector2(-200,-177), 0.3).from(Vector2(1394,-177))
	else:
		t.set_parallel(true)
		t.tween_property($Can/Bars/Down, "global_position", Vector2(-235,-126), 0.3).from(Vector2(-235,786))
		t.tween_property($Can/Bars/Up, "global_position", Vector2(-156,-126), 0.3).from(Vector2(-156,-1096))
		t.tween_property($Can/Bars/Left, "global_position", Vector2(-200,-204), 0.3).from(Vector2(-1720,-204))
		t.tween_property($Can/Bars/Right, "global_position", Vector2(-200,-177), 0.3).from(Vector2(1394,-177))
	await t.finished

func done():
	chased = false
	if Global.Area: Global.Area.queue_free()
	$/root.add_child(ResourceLoader.load_threaded_get(scene[0]).instantiate())
	await get_tree().create_timer(0.1).timeout
	Global.Lights.clear()
	await Global.nodes_of_type(Global.Area, "Light2D", Global.Lights)
	Global.lights_loaded.emit()
	if traveled_pos != Vector2.ZERO:
		Global.Player.global_position = traveled_pos
	get_tree().paused = false
	if is_instance_valid(Global.Player): Global.Player.look_to(Global.get_direction())
	if scene.size() > 1:
		await Global.Area.go_to_subroom(scene[1])
	await detransition()
	Event.give_control(false)

func detransition():
	if direc == "none": return
	Global.get_cam().position_smoothing_enabled = false
	t.kill()
	t=create_tween()
	t.set_parallel(false)
	t.set_ease(Tween.EASE_IN)
	t.set_trans(Tween.TRANS_QUART)
	$Can/Bars.self_modulate = Color.WHITE
	if direc == "U":
		t.tween_property($Can/Bars/Down, "global_position", Vector2(-235,-1096), 0.3)
	elif direc == "D":
		t.tween_property($Can/Bars/Up, "global_position", Vector2(-156,786), 0.3)
	elif direc == "R":
		t.tween_property($Can/Bars/Left, "global_position", Vector2(2000,-204), 0.3)
	elif direc == "L":
		t.tween_property($Can/Bars/Right, "global_position", Vector2(-2000,-177), 0.3)
	else:
		t.set_parallel(true)
		t.tween_property($Can/Bars/Down, "global_position", Vector2(-235,786), 0.4).from(Vector2(-235,-126))
		t.tween_property($Can/Bars/Up, "global_position", Vector2(-156,-1096), 0.4).from(Vector2(-156,-126))
		t.tween_property($Can/Bars/Left, "global_position", Vector2(-1720,-204), 0.4).from(Vector2(-200,-204))
		t.tween_property($Can/Bars/Right, "global_position", Vector2(1394,-177), 0.4).from(Vector2(-200,-177))
	dismiss_load_icon()
	await t.finished
	$Can/Bars/Down.position = Vector2(-34, 1882)
	$Can/Bars/Up.position = Vector2(0,0)
	Global.get_cam().position_smoothing_enabled = true
	Global.ready_window()
	#$Can.hide()

func dismiss_load_icon():
	if Icon.is_playing():
		Icon.play("Close")
	t = create_tween()
	t.tween_property($Can/Icon, "global_position", Vector2(1181, 900), 0.3)

##Starts the specified battle. Advantage: 0 for Neutual, 1 for Player, 2 for enemy
func start_battle(stg, advantage := 0):
	if get_node_or_null("/root/Battle") or InBattle: return
	if stg is String:
		Seq = await load_res("res://database/BattleSeq/"+ stg +".tres")
	elif stg is BattleSequence:
		Seq = stg
	else:
		Global.toast("The battle sequence isn't set here, you probably should fix this.")
		await Event.wait(0.3)
		Event.give_control()
		PartyUI.show_all()
		return
	Loader.InBattle = true
	BattleResult = 0
	PartyUI.UIvisible = false
	BtAdvantage = advantage
	#Engine.time_scale = 0.1
	PartyUI.hide_all()
	Global.Controllable = false
	print("Battle start!")
	get_tree().paused = true
	CamZoom = Global.get_cam().zoom
	if Seq.Transition:
		if is_instance_valid(Attacker):
			battle_bars(2, 0.8, Tween.EASE_OUT)
			t = create_tween()
			t.set_trans(Tween.TRANS_QUART)
			t.set_ease(Tween.EASE_OUT)
			t.set_parallel()
			t.tween_property(Global.get_cam(), "zoom", Vector2(1,1), 0.8).as_relative()
			if advantage == 1: t.tween_property(Global.get_cam(), "global_position", Attacker.global_position, 0.4)
			await t.finished
		await battle_bars(4, 0.5, Tween.EASE_IN)
	#Engine.time_scale = 1
	if is_instance_valid(Global.Player):
		Global.Player.hide()
		Global.Player.get_node("DirectionMarker/Finder/Shape").set_deferred("disabled", true)
		Global.Player.camera_follow(false)
	Global.get_cam().position_smoothing_enabled = false
	get_tree().get_root().add_child(preload("res://codings/Battle.tscn").instantiate())
	if is_instance_valid(Attacker): Attacker.hide()
	for i in Global.Area.Followers:
		if is_instance_valid(i) and is_instance_valid(Global.Player):
			i.hide()
			i.global_position = Global.Player.position
	#InBattle = true

func end_battle():
	PartyUI._on_shrink()
	if Seq.Detransition or BattleResult!= 1:
		Loader.battle_bars(4)
		await get_tree().create_timer(0.5).timeout
		if is_instance_valid(Global.Bt): Global.Bt.queue_free()
	else:
		t=create_tween()
		t.set_ease(Tween.EASE_OUT)
		t.set_trans(Tween.TRANS_QUART)
		t.set_parallel()
		#Engine.time_scale = 0.1
		Global.Area.setup_params(true)
		for i in Global.Bt.TurnOrder:
			t.tween_property(i.node.get_node("Glow"), "energy", 0, 0.3)
		Global.Bt.get_node("Background").material = null
		t.tween_property(Global.Bt.get_node("Background"), "modulate", Color.TRANSPARENT, 0.5)
		hide_victory_stuff()
	InBattle = false
	Global.get_cam().position_smoothing_enabled = true
	battle_end.emit()

	if not is_instance_valid(Global.Player): return
	for i in Global.Area.Followers:
		if i and Global.check_member(i.member): i.show()
	Global.Player.set_anim("IdleRight")
	Global.Player.dashing = false
	if is_instance_valid(Global.Bt): Global.Bt.get_node("Act").hide()

	if BattleResult == 2:
		Global.Player.position = Global.globalize(Seq.EscPosition)

	if is_instance_valid(Attacker) and BattleResult != 1: Attacker.show()
	if Seq.DeleteAttacker and BattleResult == 1 and Attacker:
		Attacker.defeat()

	Global.Controllable = false
	battle_bars(0)
	if is_instance_valid(Global.Player):
		Global.Player.show()
		Global.Player.get_node("DirectionMarker/Finder/Shape").set_deferred("disabled", false)
		if Event.f(&"FlameActive"): await Global.Player.activate_flame()
	PartyUI.UIvisible=true
	Event.give_control(true)
	PartyUI._on_shrink()

func icon_save():
	t=create_tween()
	t.set_ease(Tween.EASE_OUT)
	t.set_trans(Tween.TRANS_QUART)
	$Can.show()
	t.tween_property(Icon, "global_position", Vector2(1181, 702), 0.2)
	#.from(Vector2(1181, 900))
	Icon.play("Save")
	await Icon.animation_finished
	t=create_tween()
	t.set_ease(Tween.EASE_IN)
	t.set_trans(Tween.TRANS_QUART)
	t.tween_property($Can/Icon, "global_position", Vector2(1181, 900), 0.3)
	await t.finished
	#$Can.hide()

func icon_load():
	t=create_tween()
	t.set_ease(Tween.EASE_OUT)
	t.set_trans(Tween.TRANS_QUART)
	$Can.show()
	t.tween_property(Icon, "global_position", Vector2(1181, 702), 0.2)
	#.from(Vector2(1181, 900))
	Icon.play("Load")
	await ungray
	Icon.play("Close")
	t=create_tween()
	t.set_ease(Tween.EASE_IN)
	t.set_trans(Tween.TRANS_QUART)
	t.tween_property($Can/Icon, "global_position", Vector2(1181, 900), 0.3)
	await t.finished
	$Can.hide()

func hide_victory_stuff():
	t = create_tween()
	t.set_ease(Tween.EASE_OUT)
	t.set_trans(Tween.TRANS_QUART)
	t.set_parallel()
	for i in Global.Bt.get_node("Canvas").get_children():
		if i.name != "DottedBack":
			t.tween_property(i, "position:x", i.position.x + 500, 0.3)
			t.tween_property(i, "modulate", Color.TRANSPARENT, 0.3)
	t.tween_property(Global.Bt.get_node("Canvas/DottedBack"), "modulate", Color(0.188,0.188,0.188,0), 0.5)

func battle_bars(x: int, time: float = 0.5, ease := Tween.EASE_IN_OUT):
	if is_instance_valid(t):
		t.kill()
	$Can.layer = 1
	$Can.show()
	t=create_tween()
	t.set_parallel(true)
	t.set_ease(ease)
	t.set_trans(Tween.TRANS_QUART)
	match x:
		0:
			#t.tween_property(Global.get_cam(), "zoom", CamZoom, 1)
			t.tween_property($Can/Bars/Down, "global_position", Vector2(-235,786), time)
			t.tween_property($Can/Bars/Up, "global_position", Vector2(-156,-1096), time)
		1:
			t.tween_property($Can/Bars/Down, "global_position", Vector2(-235,700), time)
			t.tween_property($Can/Bars/Up, "global_position", Vector2(-156,-1000), time)
			t.tween_property($Can/Bars, "self_modulate", Color(1,1,1,0.5), time)
		2:
			t.tween_property($Can/Bars/Down, "global_position", Vector2(-235,600), time)
			t.tween_property($Can/Bars/Up, "global_position", Vector2(-156,-900), time)
			t.tween_property($Can/Bars, "self_modulate", Color(1,1,1,0.7), time)
		3:
			t.tween_property($Can/Bars/Down, "global_position", Vector2(-235,550), time)
			t.tween_property($Can/Bars/Up, "global_position", Vector2(-156,-850), time)
			#t.tween_property($Can/Bars, "self_modulate", Color(1,1,1,0.7), time*2)
		4:
			#t.tween_property(Global.get_cam(), "zoom", CamZoom + Vector2(3,3), time)
			t.tween_property($Can/Bars/Down, "global_position", Vector2(-235,133), time)
			t.tween_property($Can/Bars/Up, "global_position", Vector2(-156,-400), time)
			t.tween_property($Can/Bars, "self_modulate", Color(1,1,1,1), time/2)
	$Can/Bars/Left.global_position = Vector2(-1720,-204)
	$Can/Bars/Right.global_position = Vector2(1394,-177)
	t.tween_property($Can/Icon, "global_position", Vector2(1181, 900), 0.3)
	await t.finished

func error_handle(res):
	if res == ResourceLoader.THREAD_LOAD_FAILED:
		OS.alert("Some resource just failed to load. \nEither the dev made a mistake or there's a corrupt/outdated save file.
\n
If you've played this game in an older version, you may have to delete the old save files.\n
If this has nothing to do with save data, please report this error to the developer, and include logs.\n
To find the directory where save files and logs are located, launch the game and press F1.
" ,"THE RESOURCE FAILED TO LOAD!")
		load_failed = true
	if res == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
		OS.alert("THE RESOURCE "+loaded_resource+" DOESN'T EXIST YOU IDIOT!")
		load_failed = true

func chase_mode():
	CamZoom = Global.get_cam().zoom
	chased = true

func white_fadeout(out_time:float = 7, wait_time:float = 2, in_time:float = 0.1, opacity: float = 1):
	$Can.show()
	var fader:ColorRect = $Can/Bars/Left.duplicate()
	$Can.add_child(fader)
	fader.position = Vector2(-134,-189)
	fader.modulate = Color.TRANSPARENT
	fader.color = Color.WHITE
	var tf = create_tween()
	tf.tween_property(fader, "modulate", Color(1,1,1,opacity), in_time)
	await tf.finished
	await Event.wait(wait_time, false)
	$Can.show()
	tf = create_tween()
	tf.tween_property(fader, "modulate", Color.TRANSPARENT, out_time)
	await tf.finished
	fader.queue_free()

func gray_out(amount := 0.8, in_time := 0.3, out_time := 0.3):
	$Can.show()
	$Can.layer = 9
	var fader = $Can/Bars/Left.duplicate()
	$Can.add_child(fader)
	fader.position = Vector2(-134,-189)
	fader.modulate = Color.TRANSPARENT
	fader.color = Color.BLACK
	var tf = create_tween()
	tf.tween_property(fader, "modulate", Color(0,0,0,amount), in_time)
	await ungray
	tf = create_tween()
	tf.tween_property(fader, "modulate", Color.TRANSPARENT, out_time)
	await tf.finished
	fader.queue_free()

func validate_save(save: String) -> bool:
	if FileAccess.file_exists("user://Autosave.tres"):
		var file = load(save)
		if is_instance_valid(file):
			if file.version == SaveVersion:
				Preview = file.preview()
				return true
			else:
				OS.alert("This save file is from an incompatible version", "Can't read file")
				return false
		else:
			OS.alert("This save file is corrupt or from an incompatible version", "Can't read file")
			#DirAccess.remove_absolute("user://Autosave.tres")
			return false
	else: return false

func flash_attacker():
	if not is_instance_valid(Attacker): return
	t = create_tween()
	t.tween_property(Attacker.get_node("Flash"), "energy", 10, 0.1)
	t.tween_property(Attacker.get_node("Flash"), "energy", 0, 1)
