extends Control

const SaveVersion = 6

@export var scene: Array[String] = []
var status
var progress = []
var loading = false
var loading_thread = false
var load_failed = false
@export var direc : String
@onready var t: Tween
var Seq: BattleSequence
var InBattle = false
signal thread_loaded
var loaded_resource
var traveled_pos
@onready var Icon = $Can/Icon
var BattleResult = 0
var chased = false
var Attacker: Node2D
var CamZoom:Vector2 = Vector2(4,4)
var Defeated:Array
var Preview: Texture
var BtAdvantage = 0
var data: SaveFile
var SaveFiles: Array[SaveFile]
signal battle_start
signal battle_end
signal ungray
var prevent_battles:= false

var BAR_DOWN_POS: Vector2
var BAR_UP_POS: Vector2
var BAR_LEFT_POS: Vector2
var BAR_RIGHT_POS: Vector2

func _ready():
	$Can.hide()
	Icon.global_position = Vector2(1181, 870)
	t = create_tween()
	t.tween_property(self, "position", position, 0)
	validate_save("user://Autosave.tres")
	BAR_DOWN_POS = $Can/Bars/Down.position
	BAR_UP_POS = $Can/Bars/Up.position
	BAR_LEFT_POS = $Can/Bars/Left.position
	BAR_RIGHT_POS = $Can/Bars/Right.position

func save(filename:String="Autosave", showicon=true):
	if !Global.Player or !Global.Area:
		OS.alert("Cannot save right now")
		return
	print("Saving to user://"+filename+".tres")
	if showicon:
		icon_save()
	Global.save_settings()
	data = SaveFile.new()
	data.Name = filename
	data.Datetime = Time.get_datetime_dict_from_system()
	data.Party = Global.Party.get_strarr()
	data.StartTime = Global.FirstStartTime
	data.Z = (Global.Player.z_index if !get_tree().root.get_node_or_null("MainMenu")
		else $"/root/MainMenu".z)
	data.SavedTime = Time.get_unix_time_from_system()
	data.PlayTime = Global.get_playtime()
	data.Position = Global.Player.global_position
	data.Camera = Global.CameraInd
	data.Defeated = Defeated.duplicate()
	for mem in Global.Members:
		data.Members.append(mem.save_to_dict())
	#data.Members = Global.Members.duplicate()
	#Global.make_array_unique(data.Members)
	data.version = SaveVersion
	data.Flags = Event.Flags.duplicate()
	#for i in data.Members:
		#data.Members[data.Members.find(i)] = i.duplicate()
	data.Inventory = Item.save_to_strings()
	#for i in data.Inventory:
		#data.Inventory[data.Inventory.find(i)] = i.duplicate()

	data.RoomPath = Global.Area.scene_file_path
	if Global.Area.CurSubRoom != null: data.RoomPath += ";" + Global.Area.CurSubRoom.name
	data.RoomName = Global.Area.Name
	data.Day = Event.Day
	data.TimeOfDay = Event.TimeOfDay
	ResourceSaver.save(data, "user://"+filename+".tres")
	Preview = (await data.preview())

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
	await transition("")
	if get_tree().root.has_node("Initializer"):
		get_tree().root.get_node("Initializer").queue_free()
	if not validate_save(filepath):
		Loader.detransition()
		return
	prevent_battles = true
	Global.textbox_kill()
	chased = false
	data = await load_res(filepath)
	Global.StartTime = Time.get_unix_time_from_system()
	Global.FirstStartTime = data.StartTime
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
	
	var temp_members: Array[Actor]
	for mem_dict in data.Members:
		var mem: Actor = (await Loader.load_res("res://database/Party/"+mem_dict.get("codename")+".tres")).duplicate()
		await mem.load_from_dict(mem_dict)
		temp_members.append(mem)
	if temp_members < Global.Members:
		Global.toast("WARNING: This save file was created in an older version.")
		for j in Global.Members:
			var exists = false
			for i in temp_members:
				if i.codename == j.codename: exists = true
			if not exists: temp_members.append(j)
	PartyUI.LevelupChain.clear()
	Global.Members = temp_members
	
	print("Current party: ", data.Party)
	Global.Party.set_to_strarr(data.Party)
	for mem in Global.Members: 
		mem.reset_static_info()
		mem.Health = min(mem.Health, mem.MaxHP)
		mem.Aura = min(mem.Aura, mem.MaxAura)
	
	if !data:
		OS.alert("This save file doen't exist", "WHERE FILE")
	if !data.RoomPath:
		OS.alert("There's no room set in this savefile", "WHERE TF ARE YOU")
	travel_to(data.RoomPath, data.Position, data.Camera, data.Z, "")
	await Global.area_initialized
	Item.load_inventory(data.Inventory)
	PartyUI._check_party()
	print("Loading room ", data.RoomName, " in camera ID ", data.Camera, " and Z index ", data.Z)
	await Item.verify_inventory()
	if $/root.get_node_or_null("MainMenu"):
		$/root.get_node("MainMenu").queue_free()
	if $/root.get_node_or_null("Options"):
		$/root.get_node("Options").queue_free()
	PartyUI.shrink.emit()
	await Global.Player.look_to(Vector2.DOWN)
	if transition_after_done:
		await detransition()
		Event.give_control()
	else:
		await Event.take_control()
		dismiss_load_icon()
	Preview = (await data.preview())
	print("File loaded!\n-------------------------")
	await Event.wait()
	if (chased or Loader.InBattle) and is_instance_valid(Attacker):
		print("Too close to an enemy, auto escape")
		Global.Player.position = Attacker.BattleSeq.EscPosition *24
		Global.refresh()
	#await Event.wait(1)
	prevent_battles = false

func load_res(path: String) -> Resource:
	load_failed = false
	var frame := Global.ProcessFrame
	if not Global.Settings.HighResTextures:
		if ResourceLoader.exists(path.replace(".png", "_low.png")):
			path = path.replace(".png", "_low.png")
	loaded_resource = path
	if ResourceLoader.exists(path):
		ResourceLoader.call_deferred(&"load_threaded_request", path, "", true)
	else: push_error("Resource "+ path+ " not found")
	loading_thread = true
	await thread_loaded
	if Global.ProcessFrame - frame > 1:
		print("Loaded resource ", path, " in ", Global.ProcessFrame - frame, " frames")
	#if load_failed: return null
	return ResourceLoader.load_threaded_get(path)

func travel_to_coords(sc, pos:Vector2=Vector2.ZERO, camera_ind:int=0, z:= -1, trans=Global.get_dir_letter()):
	travel_to(sc, Global.Area.map_to_local(pos), camera_ind, z, trans)

func travel_to(sc: String, pos: Vector2=Vector2.ZERO, camera_ind: int=0, z := -1, trans = Global.get_dir_letter(), controllable:= true):
	direc = trans
	##Pass Z < -1 for a shortcut to controllable
	if z < -1: controllable = false
	print("Traveling to room \"", sc, "\" in camera ID ", camera_ind, " and Z index ", z)
	if t.is_running(): await t.finished
	PartyUI.hide_all()
	Event.List.clear()
	traveled_pos = pos
	Global.CameraInd = camera_ind
	scene.assign((sc.split(";").duplicate()))
	sc = scene[0]
	if not ".tscn" in sc:
		scene[0] = "res://rooms/" + sc + ".tscn"
	if scene[0] != "":
		ResourceLoader.load_threaded_request(scene[0])
	await transition(trans)
	get_tree().paused = true
	status = ResourceLoader.load_threaded_get_status(scene[0], progress)
	await Event.wait()
	if status == ResourceLoader.THREAD_LOAD_LOADED:
		await done(controllable)
	else:
		Icon.play("Load")
		loading = true
		await thread_loaded
		if status == ResourceLoader.THREAD_LOAD_LOADED:
			await done(controllable)
	if z >= 0: Global.Area.handle_z(z)

func _process(delta):
	if loading == true and !scene.is_empty():
		status = ResourceLoader.load_threaded_get_status(scene[0], progress)
		error_handle(status)
		if status == ResourceLoader.THREAD_LOAD_LOADED:
			loading = false
			thread_loaded.emit()
	if loading_thread == true:
		status = ResourceLoader.load_threaded_get_status(loaded_resource)
		error_handle(status)
		if status == ResourceLoader.THREAD_LOAD_LOADED or load_failed:
			loading_thread = false
			thread_loaded.emit()

func transition(dir=Global.get_dir_letter()):
	if dir == "none": return
	#Engine.time_scale = 0.1
	Global.Controllable = false
	direc = dir
	$Can.show()
	$Can.layer = 9
	$Can/Bars.modulate = Color.WHITE
	t.kill()
	if not is_in_transition():
		t = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUART).set_parallel()
		if Icon.is_playing():
			t.tween_property(Icon, "global_position", Vector2(1181, 702), 0.2).from(Vector2(1181, 900))
		match dir:
			"U":
				t.tween_property($Can/Bars/Down, "position", Vector2(-200,-200), 0.3)
			"D":
				t.tween_property($Can/Bars/Up, "position", Vector2(-200,-200), 0.3)
			"R":
				t.tween_property($Can/Bars/Left, "position", Vector2(-200,-200), 0.3)
			"L":
				t.tween_property($Can/Bars/Right, "position", Vector2(-200,-200), 0.3)
			_:
				t.tween_property($Can/Bars/Down, "position", Vector2(-200,-126), 0.3)
				t.tween_property($Can/Bars/Up, "position", Vector2(-200,-200), 0.3)
				t.tween_property($Can/Bars/Left, "position", Vector2(-200,-200), 0.3)
				t.tween_property($Can/Bars/Right, "position", Vector2(-200,-200), 0.3)
		await t.finished
	else: pass
	match dir:
		"U":
			$Can/Bars/Up.position = Vector2(-200,-200)
			$Can/Bars/Down.position = BAR_DOWN_POS
		"D":
			$Can/Bars/Down.position = Vector2(-200,-200)
			$Can/Bars/Up.position = BAR_UP_POS
		"R":
			$Can/Bars/Right.position = Vector2(-200,-200)
			$Can/Bars/Left.position = BAR_LEFT_POS
		"L":
			$Can/Bars/Left.position = Vector2(-200,-200)
			$Can/Bars/Right.position = BAR_RIGHT_POS
		_:
			$Can/Bars/Up.position = Vector2(-200,-200)
			$Can/Bars/Down.position = Vector2(-200,-200)
			$Can/Bars/Right.position = Vector2(-200,-200)
			$Can/Bars/Left.position = Vector2(-200,-200)
	await Event.wait()

func done(controllable:= false):
	chased = false
	var look_dir = Global.get_direction()
	if Global.Area: Global.Area.queue_free()
	if get_tree().root.has_node("MainMenu"): 
		get_tree().root.get_node("MainMenu").queue_free()
	var area = ResourceLoader.load_threaded_get(scene[0]).instantiate()
	$/root.add_child(area)
	await Global.area_initialized
	Global.Lights.clear()
	await Global.nodes_of_type(Global.Area, "Light2D", Global.Lights)
	Global.get_cam().position_smoothing_enabled = false
	Global.lights_loaded.emit()
	if traveled_pos != Vector2.ZERO:
		Global.Player.collision(false)
		Global.Player.global_position = traveled_pos
	for i in Global.Area.Followers:
		i.position = traveled_pos
	get_tree().paused = false
	if controllable:
		await Global.Player.look_to(look_dir)
	if scene.size() > 1:
		await Global.Area.go_to_subroom(scene[1])
	if direc != "wait": detransition()
	Global.get_cam().position_smoothing_enabled = true
	if controllable: 
		Event.give_control(false)
		await Event.wait(0.3, false)
		if Global.Controllable:
			PartyUI.show_all()

func detransition(dir = "direc"):
	if dir == "none": return
	#Engine.time_scale = 0.1
	if Global.Camera != null:
		Global.get_cam().position_smoothing_enabled = false
	t.kill()
	t = create_tween()
	t.set_parallel()
	t.set_ease(Tween.EASE_IN)
	t.set_trans(Tween.TRANS_QUART)
	$Can/Bars.self_modulate = Color.WHITE
	t.tween_property($Can/Bars/Down, "position", BAR_DOWN_POS, 0.4)#.from(Vector2(-235,-126))
	t.tween_property($Can/Bars/Up, "position", BAR_UP_POS, 0.4)#.from(Vector2(-156,-126))
	t.tween_property($Can/Bars/Left, "position", BAR_LEFT_POS, 0.4)#.from(Vector2(-200,-204))
	t.tween_property($Can/Bars/Right, "position", BAR_RIGHT_POS, 0.4)#.from(Vector2(-200,-177))
	dismiss_load_icon()
	await Event.wait(0.4, false)
	if Global.Camera != null:
		Global.get_cam().position_smoothing_enabled = true
	#Global.ready_window()

func restore_bars(dir: String = ""):
	$Can/Bars/Down.global_position = BAR_DOWN_POS
	$Can/Bars/Up.global_position = BAR_UP_POS
	$Can/Bars/Left.global_position = BAR_LEFT_POS
	$Can/Bars/Right.global_position = BAR_RIGHT_POS

func is_in_transition():
	return not (
		$Can/Bars/Down.global_position == BAR_DOWN_POS and
		$Can/Bars/Up.global_position == BAR_UP_POS and
		$Can/Bars/Left.global_position == BAR_LEFT_POS and
		$Can/Bars/Right.global_position == BAR_RIGHT_POS
	)

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
	if prevent_battles: return
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
			t.tween_property(Global.get_cam(), "zoom", Vector2(1,1), 0.3).as_relative()
			t.tween_property(Global.get_cam(), "zoom", Vector2(2,2), 1).as_relative()
			#if advantage == 1: t.tween_property(Global.get_cam(), "global_position", Attacker.global_position, 0.4)
			await Event.wait(0.8, false)
		var tr = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
		tr.tween_property(Global.get_cam(), "zoom", Vector2(8,8), 0.5)
		await battle_bars(4, 0.5, Tween.EASE_IN)
	#Engine.time_scale = 1
	var battle = (await load_res("res://codings/Battle.tscn")).instantiate()
	if is_instance_valid(Global.Player):
		Global.Player.hide()
		#if Global.Player.is_on_wall():
		Global.Player.position = Seq.ScenePosition
		Global.Player.get_node("DirectionMarker/Finder/Shape").set_deferred("disabled", true)
		Global.Player.camera_follow(false)
	Global.get_cam().position_smoothing_enabled = false
	get_tree().get_root().add_child(battle)
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
	if Seq.ReturnControl:
		PartyUI.UIvisible=true
		Event.give_control(true)
	PartyUI._on_shrink()

func icon_save():
	if Icon.is_playing(): return
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
			t.tween_property($Can/Bars/Down, "global_position", BAR_DOWN_POS, time)
			t.tween_property($Can/Bars/Up, "global_position", BAR_UP_POS, time)
		1:
			t.tween_property($Can/Bars/Down, "global_position", Vector2(-235,700), time)
			t.tween_property($Can/Bars/Up, "global_position", Vector2(-156,-1050), time)
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
	t.tween_property($Can/Icon, "global_position", Vector2(1181, 900), 0.3)
	await t.finished

func error_handle(res):
	if res == ResourceLoader.THREAD_LOAD_FAILED:
		Global.toast("A resource failed to load! \nPress F1 to check the logs.")
		load_failed = true
		loading_thread = false
	#if res == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
		#OS.alert("THE RESOURCE "+loaded_resource+" DOESN'T EXIST YOU IDIOT!")
		#load_failed = true
		#loading_thread = false

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

func gray_out(amount := 0.8, in_time := 0.3, out_time := 0.3, color: Color = Color.BLACK):
	$Can.show()
	$Can.layer = 9
	var fader = $Can/Bars/Left.duplicate()
	$Can.add_child(fader)
	fader.position = Vector2(-134,-189)
	fader.modulate = Color.TRANSPARENT
	fader.color = color
	var tf = create_tween()
	tf.tween_property(fader, "modulate:a", amount, in_time)
	await ungray
	tf = create_tween()
	tf.tween_property(fader, "modulate:a", 0, out_time)
	await tf.finished
	fader.queue_free()

func validate_save(save: String) -> bool:
	if FileAccess.file_exists(save):
		var file = load(save)
		if is_instance_valid(file):
			if file.version == SaveVersion:
				return true
			else:
				Global.warning("Sorry but the stored save data is from an incompatible version, and cannot be used.\nYou might have to start a new game...", "ERROR", ["Okay fine"])
				Global.options(1)
				return false
		else:
			Global.warning("The stored save data could not be loaded. You might have to start a new game.", "ERROR", ["Okay"])
			Global.options(1)
			return false
	else: return false

func flash_attacker():
	if not is_instance_valid(Attacker): return
	t = create_tween()
	t.tween_property(Attacker.get_node("Flash"), "energy", 10, 0.1)
	t.tween_property(Attacker.get_node("Flash"), "energy", 0, 1)

func flip_time(from: Event.TOD, to: Event.TOD):
	var tod = $Can/TimeOfDay
	tod.modulate = Color.TRANSPARENT
	tod.scale = Vector2(0.6, 0.6)
	tod.text = Global.to_tod_text(from)
	tod.icon = await  Global.to_tod_icon(from)
	tod.show()
	t = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC).set_parallel()
	t.tween_property(tod, "scale", Vector2(1, 1), 0.3)
	t.tween_property(tod, "modulate", Color.WHITE, 0.3)
	get_tree().paused = false
	await t.finished
	await Event.wait(0.3, false)
	t = create_tween()
	t.tween_property(tod, "scale:x", 0, 0.1)
	await t.finished
	tod.text = Global.to_tod_text(to)
	tod.icon = await Global.to_tod_icon(to)
	t = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	t.tween_property(tod, "scale:x", 1, 0.3)
	await Event.wait(0.6, false)
	t = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC).set_parallel()
	t.tween_property(tod, "scale", Vector2(0.6, 0.6), 0.3)
	t.tween_property(tod, "modulate", Color.TRANSPARENT, 0.3)
	await t.finished
	tod.hide()

func lower_layer():
	$Can.layer = 3
