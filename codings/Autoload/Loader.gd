extends Control

const SaveVersion = 4

@export var scene:String
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
	if Global.Player == null or Global.Area == null:
		OS.alert("Cannot save right now")
		return
	print("Saving to user://"+filename+".tres")
	if showicon:
		icon_save()
	var data:SaveFile = SaveFile.new()
	data.Name = filename
	data.Datetime = Time.get_datetime_dict_from_system()
	data.Party = Global.Party.get_strarr()
	data.StartTime = Global.StartTime
	data.Z = (Global.Player.z_index if get_node_or_null("/root/MainMenu") == null
		else $"/root/MainMenu".z)
	data.SavedTime = Time.get_unix_time_from_system()
	data.PlayTime = Global.get_playtime()
	data.Position = Global.Player.global_position
	data.Preview = Global.get_preview()
	data.Camera = Global.CameraInd
	data.Defeated = Defeated
	data.Members = Global.Members.duplicate()
	Global.make_array_unique(data.Members)
	data.version = SaveVersion
	data.Flags = Event.Flags
	for i in data.Members:
		data.Members[data.Members.find(i)] = i.duplicate()

	data.KeyInv = Item.KeyInv.duplicate()
	for i in data.KeyInv:
		data.KeyInv[data.KeyInv.find(i)] = i.duplicate()
	data.ConInv = Item.ConInv.duplicate()
	for i in data.ConInv:
		data.ConInv[data.ConInv.find(i)] = i.duplicate()
	data.MatInv = Item.MatInv.duplicate()
	for i in data.MatInv:
		data.MatInv[data.MatInv.find(i)] = i.duplicate()
	data.BtiInv = Item.BtiInv.duplicate()
	for i in data.BtiInv:
		data.BtiInv[data.BtiInv.find(i)] = i.duplicate()
	data.Room = Global.Area.scene_file_path
	data.RoomName = Global.Area.Name
	data.Day = Event.Day
	ResourceSaver.save(data, "user://"+filename+".tres")
	Preview = (data.Preview)

func load_game(filename:String="Autosave", sound:= true):
	if sound: Global.ui_sound("Load")
	if filename=="File0": filename = "Autosave"
	if not FileAccess.file_exists("user://"+filename+".tres"): await save()
	print("Loading user://"+filename+".tres")
	transition("")
	t = create_tween()
	t.tween_property(Icon, "global_position", Vector2(1181, 702), 0.2).from(Vector2(1181, 900))
	Icon.play("Load")
	await get_tree().create_timer(1).timeout
	if not validate_save("user://"+filename+".tres"):
		OS.alert("Save data is corrupt")
		OS.set_restart_on_exit(true)
		get_tree().quit()
		return
	var data:SaveFile = await load_res("user://"+filename+".tres")
	Global.StartTime = Time.get_unix_time_from_system()
	Global.SaveTime = data.PlayTime
	Defeated = data.Defeated
	Global.CameraInd = data.Camera
	PartyUI.UIvisible = true
	PartyUI.disabled = false
	Event.Flags = data.Flags
	get_tree().paused = true
	if data == null:
		OS.alert("This save file doen't exist", "WHERE FILE")
	if data.Room == null:
		OS.alert("There's no room set in this savefile", "WHERE TF ARE YOU")
	for i in $/root.get_children():
		if i is TileMap: i.queue_free()
	get_tree().root.add_child((await load_res(data.Room)).instantiate())

	Item.KeyInv = data.KeyInv.duplicate()
	Item.ConInv = data.ConInv.duplicate()
	Item.MatInv = data.MatInv.duplicate()
	Item.BtiInv = data.BtiInv.duplicate()

	Global.Members = data.Members.duplicate()
	Global.make_array_unique(Global.Members)
	Global.Party.set_to_strarr(data.Party)

	await Global.area_initialized
	Global.Player.global_position = data.Position
	Global.Controllable =true
	PartyUI._check_party()
	Global.Area.handle_z(data.Z)
	await Item.verify_inventory()
	if $/root.get_node_or_null("MainMenu") != null:
		$/root.get_node("MainMenu").queue_free()
	if $/root.get_node_or_null("Options") != null:
		$/root.get_node("Options").queue_free()
	await detransition()
	Global.Controllable = true
	get_tree().paused = false

func load_res(path:String):
	load_failed = false
	loaded_resource = path
	ResourceLoader.load_threaded_request(path)
	loading_thread=true
	await thread_loaded
	if load_failed: return null
	return ResourceLoader.load_threaded_get(path)

func travel_to_coords(sc, pos:Vector2=Vector2.ZERO, camera_ind:int=0, z:= -1, trans=Global.get_dir_letter()):
	travel_to(sc, Global.Tilemap.map_to_local(pos), camera_ind, z, trans)

func travel_to(sc, pos:Vector2=Vector2.ZERO, camera_ind:int=0, z := -1, trans=Global.get_dir_letter()):
	direc = trans
	if t.is_running(): await t.finished
	Event.List.clear()
	traveled_pos = pos
	Global.CameraInd = camera_ind
	scene = "res://rooms/" + sc + ".tscn"
	if scene != "":
		ResourceLoader.load_threaded_request(scene)
	await transition(trans)
	status = ResourceLoader.load_threaded_get_status(scene, progress)
	await Event.wait()
	if status == ResourceLoader.THREAD_LOAD_LOADED:
		await done()
		if z >= 0: Global.Area.handle_z(z)
	else:
		Icon.play("Load")
		loading = true

func _process(delta):
	if loading == true:
		status = ResourceLoader.load_threaded_get_status(scene, progress)
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
	if get_node_or_null("/root/Textbox") != null: $"/root/Textbox"._on_close()
	t.kill()
	t=create_tween()
	t.set_parallel(false)
	t.set_ease(Tween.EASE_IN)
	t.set_trans(Tween.TRANS_QUART)
	$Can.show()
	$Can.layer = 9
	$Can/Bars.modulate = Color.WHITE
	direc = dir
	if Icon.is_playing():
		t.tween_property(Icon, "global_position", Vector2(1181, 702), 0.2).from(Vector2(1181, 900))
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
	if Global.Area != null: Global.Area.queue_free()
	#get_tree().change_scene_to_packed(ResourceLoader.load_threaded_get(scene))
	$/root.add_child(ResourceLoader.load_threaded_get(scene).instantiate())
	await get_tree().create_timer(0.1).timeout
	Global.Lights.clear()
	await Global.nodes_of_type(Global.Area, "Light2D", Global.Lights)
	Global.lights_loaded.emit()
	if traveled_pos != Vector2.ZERO:
		Global.Player.global_position = traveled_pos
	get_tree().paused = false
	if Global.Player != null: Global.Player.look_to(Global.get_direction())
	Event.give_control()
	await detransition()

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
		t.tween_property($Can/Bars/Down, "global_position", Vector2(-235,786), 0.5).from(Vector2(-235,-126))
		t.tween_property($Can/Bars/Up, "global_position", Vector2(-156,-1096), 0.5).from(Vector2(-156,-126))
		t.tween_property($Can/Bars/Left, "global_position", Vector2(-1720,-204), 0.5).from(Vector2(-200,-204))
		t.tween_property($Can/Bars/Right, "global_position", Vector2(1394,-177), 0.5).from(Vector2(-200,-177))
	if Icon.is_playing():
		Icon.play("Close")
	t.tween_property($Can/Icon, "global_position", Vector2(1181, 900), 0.3)
	await t.finished
	$Can/Bars/Down.position = Vector2(-34, 1882)
	$Can/Bars/Up.position = Vector2(0,0)
	Global.get_cam().position_smoothing_enabled = true
	Global.ready_window()

##Starts the specified battle. Advantage: 0 for Neutual, 1 for Player, 2 for enemy
func start_battle(stg, advantage := 0):
	if get_node_or_null("/root/Battle") != null: return
	BattleResult = 0
	Global.Player.get_node("DirectionMarker/Finder/Shape").set_deferred("disabled", true)
	PartyUI.UIvisible = false
	BtAdvantage = advantage
	#Engine.time_scale = 0.1
	Global.Controllable = false
	print("Battle start!")
	get_tree().paused = true
	if stg is String:
		Seq = await load_res("res://database/BattleSeq/"+ stg +".tres")
	elif stg is BattleSequence:
		Seq = stg
	else:
		OS.alert("THIS IS NOT A VALID BATTLE SEQUENCE", "YOU IDIOT")
		return
	CamZoom = Global.get_cam().zoom
	if Seq.Transition:
		if Attacker != null:
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
	if Global.Player!= null: Global.Player.hide()
	Global.get_cam().position_smoothing_enabled = false
	get_tree().get_root().add_child(preload("res://codings/Battle.tscn").instantiate())
	if Attacker != null: Attacker.hide()
	for i in Global.Follower:
		if i != null: i.hide()
	#InBattle = true

func end_battle():
	Global.get_cam().zoom = CamZoom
	PartyUI._on_shrink()
	if Seq.Detransition or BattleResult!= 1:
		Loader.battle_bars(4)
		await get_tree().create_timer(0.5).timeout
		if Global.Bt != null: Global.Bt.queue_free()
	else:
		t=create_tween()
		t.set_ease(Tween.EASE_OUT)
		t.set_trans(Tween.TRANS_QUART)
		t.set_parallel()
		t.tween_property(Global.Bt.get_node("Cam"), "global_position", Global.get_cam().global_position, 0.5)
		t.tween_property(Global.Bt.get_node("Cam"), "zoom", CamZoom, 0.5 )
		t.tween_property(Global.Bt.get_node("Canvas/DottedBack"), "modulate", Color(0.188,0.188,0.188,0), 0.5)
		for i in Global.Bt.TurnOrder:
			t.tween_property(i.node.get_node("Glow"), "energy", 0, 0.3)
		for i in Global.Bt.get_node("Canvas").get_children():
			if i.name != "DottedBack":
				t.tween_property(i, "position:x", i.position.x + 500, 0.5)
				t.tween_property(i, "modulate", Color.TRANSPARENT, 0.5)
		t.tween_property(Global.Bt.get_node("Background"), "modulate", Color.TRANSPARENT, 0.5)
		await t.finished
	InBattle= false
	battle_end.emit()
	if Global.Player == null: return
	for i in Global.Follower:
		if i != null: i.show()
	Global.Player.set_anim("IdleRight")
	Global.Player.dashing = false
	if Global.Bt != null: Global.Bt.get_node("Act").hide()
	if BattleResult == 2:
		Global.Player.position = Global.globalize(Seq.EscPosition)
	if Attacker!=null and BattleResult!= 1: Attacker.show()
	if Seq.DeleteAttacker and BattleResult == 1 and Attacker!=null:
		Attacker.defeat()
	Global.Controllable = false
	battle_bars(0)
	get_tree().paused = false
	if Global.Player != null:
		Global.Player.show()
		Global.Player.get_node("DirectionMarker/Finder/Shape").set_deferred("disabled", false)
		await Event.wait(0.1)
		if Event.f(&"FlameActive"): await Global.Player.activate_flame()
	PartyUI.UIvisible=true
	Global.Controllable = true
	#Global.get_cam().position_smoothing_enabled = true

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
	$Can.hide()

func battle_bars(x: int, time: float = 0.5, ease := Tween.EASE_IN_OUT):
	if t != null:
		t.kill()
	$Can.layer = 2
	$Can.show()
	t=create_tween()
	t.set_parallel(true)
	t.set_ease(ease)
	t.set_trans(Tween.TRANS_QUART)
	match x:
		0:
			t.tween_property(Global.get_cam(), "zoom", CamZoom, 1)
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
			t.tween_property(Global.get_cam(), "zoom", CamZoom + Vector2(3,3), time)
			t.tween_property($Can/Bars/Down, "global_position", Vector2(-235,133), time)
			t.tween_property($Can/Bars/Up, "global_position", Vector2(-156,-400), time)
			t.tween_property($Can/Bars, "self_modulate", Color(1,1,1,1), time/2)
	$Can/Bars/Left.global_position = Vector2(-1720,-204)
	$Can/Bars/Right.global_position = Vector2(1394,-177)
	t.tween_property($Can/Icon, "global_position", Vector2(1181, 900), 0.3)
	await t.finished
	#if x == 0: $Can.hide()

func error_handle(res):
	if res == ResourceLoader.THREAD_LOAD_FAILED:
		OS.alert("Either the dev made a mistake, there's an outdated save file or
you were save editing.
\nIf you were save editing, please delete or restore the file.\n
If you've played this game in an older version, you may have to delete the old save files.\n
If this has nothing to do with save data, please report this error to the developer.\n
On Windows save files are located under \"%APPDATA%\\miras-journal\"
and on Linux under \"~/.local/share/miras-journal\"
" ,"THE RESOURCE FAILED TO LOAD!")
		load_failed = true
	if res == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
		OS.alert("THE RESOURCE DOESN'T EXIST YOU IDIOT!")
		load_failed = true


func chase_mode():
	CamZoom = Global.get_cam().zoom
	chased = true

func white_fadeout(out_time:float = 7, wait_time:float = 2, in_time:float = 0.1):
	$Can.show()
	var fader:ColorRect = $Can/Bars/Left.duplicate()
	$Can.add_child(fader)
	fader.position = Vector2(-134,-189)
	fader.modulate = Color.TRANSPARENT
	fader.color = Color.WHITE
	var tf = create_tween()
	tf.tween_property(fader, "modulate", Color.WHITE, in_time)
	await tf.finished
	await Event.wait(wait_time, false)
	$Can.show()
	tf = create_tween()
	tf.tween_property(fader, "modulate", Color.TRANSPARENT, out_time)
	await tf.finished
	fader.queue_free()

func gray_out(amount := 0.8, in_time := 0.3, out_time := 0.3):
	$Can.show()
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
		if file != null and file.version == SaveVersion:
			Preview = file.Preview
			return true
		else:
			OS.alert("This save file is corrupt or from an incompatible version and will now be deleted", "Can't read file")
			DirAccess.remove_absolute("user://Autosave.tres")
			return false
	else: return false

func flash_attacker():
	if Attacker == null: return
	t = create_tween()
	t.tween_property(Attacker.get_node("Flash"), "energy", 10, 0.1)
	t.tween_property(Attacker.get_node("Flash"), "energy", 0, 1)
