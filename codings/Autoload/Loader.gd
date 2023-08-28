extends Control
@export var scene:String
var status
var progress = []
var loading = false
var loading_thread = false
@export var direc : String
@onready var t: Tween
var Seq :BattleSequence= preload("res://database/BattleSeq/DebugDummy.tres")
var InBattle = false
signal thread_loaded
var loaded_resource
var traveled_pos
@onready var Icon = $Can/Icon
var BattleResult=0

func _ready():
	Icon.hide()
	$Can/Bars/Down.hide()
	$Can/Bars/Up.hide()
	$Can/Bars/Left.hide()
	$Can/Bars/Right.hide()
	Icon.global_position = Vector2(1181, 702)

func travel_to(sc, pos:Vector2=Vector2.ZERO, camera_ind:int=0, trans=Global.get_dir_letter()):
	Event.List.clear()
	traveled_pos = pos
	Global.CameraInd = camera_ind
	scene = "res://scenes/Rooms/" + sc + ".tscn"
	if scene != "":
		ResourceLoader.load_threaded_request(scene)
	transition(trans)
	await get_tree().create_timer(0.3).timeout
	status = ResourceLoader.load_threaded_get_status(scene, progress)
	if status == ResourceLoader.THREAD_LOAD_LOADED:
		done()
	else:
		Icon.show()
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
		if status == ResourceLoader.THREAD_LOAD_LOADED:
			loading_thread = false
			thread_loaded.emit()

func transition(dir=Global.get_dir_letter()):
	Global.Controllable = false
	t=create_tween()
	t.set_parallel(false)
	t.set_ease(Tween.EASE_IN)
	t.set_trans(Tween.TRANS_QUART)
	$Can.layer = 9
	direc = dir
	t.tween_property(Icon, "global_position", Vector2(1181, 702), 0.2).from(Vector2(1181, 900))
	if dir == "U":
		$Can/Bars/Down.show()
		t.parallel()
		t.tween_property($Can/Bars/Down, "global_position", Vector2(-235,-126), 0.3).from(Vector2(-235,786))
	elif dir == "D":
		$Can/Bars/Up.show()
		t.parallel()
		t.tween_property($Can/Bars/Up, "global_position", Vector2(-156,-126), 0.3).from(Vector2(-156,-1096))
	elif dir == "R":
		$Can/Bars/Left.show()
		t.parallel()
		t.tween_property($Can/Bars/Left, "global_position", Vector2(-200,-204), 0.3).from(Vector2(-1720,-204))
	elif dir == "L":
		$Can/Bars/Right.show()
		t.parallel()
		t.tween_property($Can/Bars/Right, "global_position", Vector2(-200,-177), 0.3).from(Vector2(1394,-177))
	else:
		t.set_parallel(true)
		$Can/Bars/Right.show()
		$Can/Bars/Left.show()
		$Can/Bars/Up.show()
		$Can/Bars/Down.show()
		t.tween_property($Can/Bars/Down, "global_position", Vector2(-235,-126), 0.3).from(Vector2(-235,786))
		t.tween_property($Can/Bars/Up, "global_position", Vector2(-156,-126), 0.3).from(Vector2(-156,-1096))
		t.tween_property($Can/Bars/Left, "global_position", Vector2(-200,-204), 0.3).from(Vector2(-1720,-204))
		t.tween_property($Can/Bars/Right, "global_position", Vector2(-200,-177), 0.3).from(Vector2(1394,-177))

func done():
	get_tree().change_scene_to_packed(ResourceLoader.load_threaded_get(scene))
	await get_tree().create_timer(0.1).timeout
	detransition()
	if traveled_pos != Vector2.ZERO:
		Global.Player.global_position = traveled_pos
	Global.Controllable = true
	get_tree().paused = false

func detransition():
	Global.get_cam().position_smoothing_enabled = false
	t=create_tween()
	t.set_parallel(false)
	t.set_ease(Tween.EASE_IN)
	t.set_trans(Tween.TRANS_QUART)
	$Can/Bars/Up.modulate = Color.WHITE
	$Can/Bars/Down.modulate = Color.WHITE
	if direc == "U":
		t.tween_property($Can/Bars/Down, "global_position", Vector2(-235,-1096), 0.3)
	elif direc == "D":
		t.tween_property($Can/Bars/Up, "global_position", Vector2(-156,786), 0.3)
	elif direc == "R":
		t.tween_property($Can/Bars/Left, "global_position", Vector2(2000,-204), 0.3)
	elif direc == "L":
		t.tween_property($Can/Bars/Right, "global_position", Vector2(-2000,-177), 0.3)
	Icon.play("Close")
	t.tween_property($Can/Icon, "global_position", Vector2(1181, 900), 0.3)
	await t.finished
	$Can/Icon.hide()
	$Can/Bars/Down.hide()
	$Can/Bars/Up.hide()
	$Can/Bars/Left.hide()
	$Can/Bars/Right.hide()
	Global.get_cam().position_smoothing_enabled = true

func StartBattle(stg):
	BattleResult = 0
	PartyUI.UIvisible = false
	#Engine.time_scale = 0.1
	Global.Controllable = false
	print("Battle start!")
	get_tree().paused = true
	#get_node("/root/Area/TileMap/OvPlayer/Body/Camera2D").current = false
	Seq = await load_res("res://database/BattleSeq/"+ stg +".tres")
	if Seq.Transition:
		battle_bars(4)
		await t.finished
	get_tree().get_root().add_child(preload("res://scenes/Battle.tscn").instantiate())
	#InBattle = true

func icon_save():
	t=create_tween()
	t.set_ease(Tween.EASE_OUT)
	t.set_trans(Tween.TRANS_QUART)
	Icon.show()
	t.tween_property(Icon, "global_position", Vector2(1181, 702), 0.2).from(Vector2(1181, 900))
	Icon.play("Save")
	await Icon.animation_finished
	t=create_tween()
	t.set_ease(Tween.EASE_IN)
	t.set_trans(Tween.TRANS_QUART)
	t.tween_property($Can/Icon, "global_position", Vector2(1181, 900), 0.3)
	await t.finished
	Icon.hide()

func battle_bars(x: int):
	$Can.layer = 0
	$Can/Bars/Down.show()
	$Can/Bars/Up.show()
	t=create_tween()
	t.set_parallel(true)
	t.set_ease(Tween.EASE_IN_OUT)
	t.set_trans(Tween.TRANS_QUART)
	match x:
		0:
			t.tween_property($Can/Bars/Down, "global_position", Vector2(-235,786), 0.5)
			t.tween_property($Can/Bars/Up, "global_position", Vector2(-156,-1096), 0.5)
			await t.finished
			$Can/Bars/Down.hide()
			$Can/Bars/Up.hide()
		1:
			t.tween_property($Can/Bars/Down, "global_position", Vector2(-235,700), 0.5)
			t.tween_property($Can/Bars/Up, "global_position", Vector2(-156,-1000), 0.5)
			t.tween_property($Can/Bars/Up, "modulate", Color(1,1,1,0.5), 1)
			t.tween_property($Can/Bars/Down, "modulate", Color(1,1,1,0.5), 1)
		2:
			t.tween_property($Can/Bars/Down, "global_position", Vector2(-235,600), 0.5)
			t.tween_property($Can/Bars/Up, "global_position", Vector2(-156,-900), 0.5)
			t.tween_property($Can/Bars/Up, "modulate", Color(1,1,1,0.7), 1)
			t.tween_property($Can/Bars/Down, "modulate", Color(1,1,1,0.7), 1)
		3:
			t.tween_property($Can/Bars/Down, "global_position", Vector2(-235,550), 0.5)
			t.tween_property($Can/Bars/Up, "global_position", Vector2(-156,-850), 0.5)
			t.tween_property($Can/Bars/Up, "modulate", Color(1,1,1,0.7), 1)
			t.tween_property($Can/Bars/Down, "modulate", Color(1,1,1,0.7), 1)
		4:
			t.tween_property($Can/Bars/Down, "global_position", Vector2(-235,133), 0.5)
			t.tween_property($Can/Bars/Up, "global_position", Vector2(-156,-400), 0.5)
			t.tween_property($Can/Bars/Up, "modulate", Color(1,1,1,1), 0.2)
			t.tween_property($Can/Bars/Down, "modulate", Color(1,1,1,1), 0.2)
			
func end_battle():
	if Seq.Transition:
		Loader.battle_bars(4)
		await get_tree().create_timer(0.5).timeout
	InBattle= false
	get_tree().paused = false
	battle_bars(0)
	PartyUI.UIvisible=true
	if BattleResult == 0:
		await Event.twean_to(Seq.EscPosition)
	Global.Controllable = true


func error_handle(res):
	if res == ResourceLoader.THREAD_LOAD_FAILED:
		OS.alert("THE RESOURCE FAILED TO LOAD, AND IT YOUR DAMN FAULT!", "OH FUCK")
	if res == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
		OS.alert("THE RESOURCE DOESN'T EXIST YOU IDIOT!", "OH FUCK")

func save(filename:String="Autosave", showicon=true):
	if showicon:
		icon_save()
	var data:SaveFile =SaveFile.new()
	data.Datetime = Time.get_datetime_dict_from_system()
	data.Party = PartyData.new()
	data.Party.set_to(Global.Party)
	data.Party.make_unique()
	data.StartTime = Global.StartTime
	data.PlayTime = Global.PlayTime
	data.Position = Global.Player.global_position
	data.Preview = Global.get_preview()
	data.Camera = Global.CameraInd
	var members: Array[Actor] = []
	for i in DirAccess.get_files_at("res://database/Party"):
		var file = await load_res("res://database/Party/"+ i)
		if file is Actor:
			members.push_front(file.duplicate())
	data.Members = members
	
	var key: Array[ItemData] = []
	for file in DirAccess.get_files_at("res://database/Items/KeyItems"):
		if ".tres" in file:
			var item:ItemData =(await load_res("res://database/Items/KeyItems/"+ file)).duplicate()
			item.filename = file
			key.push_front(item)
	data.KeyItems = key
	data.KeyInv = Item.KeyInv.duplicate()
	
	var con: Array[ItemData] = []
	for file in DirAccess.get_files_at("res://database/Items/Consumables"):
		if ".tres" in file:
			var item:ItemData = (await load_res("res://database/Items/Consumables/"+ file)).duplicate()
			item.filename = file
			con.push_front(item)
	data.Consumables = con
	data.ConInv = Item.ConInv.duplicate()
	var room=PackedScene.new()
	room.pack(get_tree().root.get_node_or_null("Area"))
	data.Room = room
	
	ResourceSaver.save(data, "user://"+filename+".tres")

func load_game(filename:String="Autosave"):
	transition("R")
	await get_tree().create_timer(1).timeout
	var data:SaveFile = await load_res("user://"+filename+".tres")
	Global.StartTime = Time.get_unix_time_from_system()
	Global.SaveTime = data.PlayTime
	
	if data == null:
		OS.alert("This save file doen't exist", "WHERE FILE")
	if data.Room == null:
		OS.alert("There's no room set in this savefile", "WHERE TF ARE YOU")
	if get_tree().root.get_node_or_null("Area") != null:
		get_tree().root.get_node_or_null("Area").get_tree().change_scene_to_packed(data.Room)
	detransition()
	
	for i in data.Members:
		var member:Actor = await load_res("res://database/Party/"+i.FirstName+".tres") 
		member.Health = i.Health
		member.Aura = i.Aura
		member.Abilities = i.Abilities
	Global.Party.set_to(data.Party)
	await get_tree().create_timer(0.01).timeout
	Global.Player.global_position = data.Position
	Global.CameraInd = data.Camera
	Global.Controllable =true

func load_res(path:String):
	loaded_resource = path
	ResourceLoader.load_threaded_request(path)
	loading_thread=true
	await thread_loaded
	return ResourceLoader.load_threaded_get(path)
