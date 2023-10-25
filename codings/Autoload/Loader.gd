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
var chased = false
var Attacker: NPC
var CamZoom:Vector2 = Vector2(4,4)
var Defeated:Array[NodePath]
@onready var Preview = (await load_res("user://Autosave.tres")).Preview

func _ready():
	$Can.hide()
	Icon.global_position = Vector2(1181, 870)
	t = create_tween()
	t.tween_property(self, "position", position, 0)

func travel_to_coords(sc, pos:Vector2=Vector2.ZERO, camera_ind:int=0, trans=Global.get_dir_letter()):
	travel_to(sc, Global.Tilemap.map_to_local(pos), camera_ind, trans)

func travel_to(sc, pos:Vector2=Vector2.ZERO, camera_ind:int=0, trans=Global.get_dir_letter()):
	direc = trans
	if t.is_running(): await t.finished
	Event.List.clear()
	traveled_pos = pos
	Global.CameraInd = camera_ind
	scene = "res://scenes/Rooms/" + sc + ".tscn"
	if scene != "":
		ResourceLoader.load_threaded_request(scene)
	await transition(trans)
	status = ResourceLoader.load_threaded_get_status(scene, progress)
	if status == ResourceLoader.THREAD_LOAD_LOADED:
		await done()
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
		if status == ResourceLoader.THREAD_LOAD_LOADED:
			loading_thread = false
			thread_loaded.emit()

func transition(dir=Global.get_dir_letter()):
	if dir == "none": return
	Global.Controllable = false
	t.kill()
	t=create_tween()
	t.set_parallel(false)
	t.set_ease(Tween.EASE_IN)
	t.set_trans(Tween.TRANS_QUART)
	$Can.show()
	$Can.layer = 9
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
		t.tween_property($Can/Bars/Left, "global_position", Vector2(-200,-204), 0.3).from(Vector2(-1720,-204))
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
	get_tree().change_scene_to_packed(ResourceLoader.load_threaded_get(scene))
	await get_tree().create_timer(0.1).timeout
	if traveled_pos != Vector2.ZERO:
		Global.Player.global_position = traveled_pos
	get_tree().paused = false
	Global.Player.look_to(Global.get_direction())
	Global.Controllable = true
	await detransition()
	

func detransition():
	if direc == "none": return
	Global.get_cam().position_smoothing_enabled = false
	t.kill()
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
	if Icon.is_playing():
		Icon.play("Close")
	t.tween_property($Can/Icon, "global_position", Vector2(1181, 900), 0.3)
	await t.finished
	$Can.hide()
	$Can/Bars/Down.position = Vector2(-34, 1882)
	$Can/Bars/Up.position = Vector2(0,0)
	Global.get_cam().position_smoothing_enabled = true
	Global.ready_window()

func start_battle(stg):
	BattleResult = 0
	Global.Player.get_node("DirectionMarker/Finder/Shape").disabled = true
	PartyUI.UIvisible = false
	#Engine.time_scale = 0.1
	Global.Controllable = false
	print("Battle start!")
	get_tree().paused = true
	#get_node("/root/Area/TileMap/OvPlayer/Body/Camera2D").current = false
	if stg is String:
		Seq = await load_res("res://database/BattleSeq/"+ stg +".tres")
	elif stg is BattleSequence:
		Seq = stg
	else:
		OS.alert("THIS IS NOT A VALID BATTLE SEQUENCE", "YOU IDIOT")
		return
	CamZoom = Global.get_cam().zoom
	if Seq.Transition:
		battle_bars(4)
		await t.finished
	Global.get_cam().position_smoothing_enabled = false
	get_tree().get_root().add_child(preload("res://scenes/Battle.tscn").instantiate())
	#InBattle = true
	if Attacker!=null: Attacker.hide()
	Global.Player.get_parent().hide()
	
func end_battle():
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
		t.tween_property(Global.Bt.get_node("Cam"), "zoom", CamZoom, 0.5)
		t.tween_property(Global.Bt.get_node("Canvas/DottedBack"), "modulate", Color.TRANSPARENT, 0.5)
		t.tween_property(Global.Bt.get_node("Canvas/Callout"), "position", Vector2(1200, 50), 0.5)
		t.tween_property(Global.Bt.get_node("Canvas/Callout"), "modulate", Color.TRANSPARENT, 0.5)
		t.tween_property(Global.Bt.get_node("Background"), "modulate", Color.TRANSPARENT, 0.5)
		await t.finished
	InBattle= false
	if Global.Player == null: return
	Global.Player.get_parent().show()
	Global.Player.set_anim("Idle"+Global.get_dir_name())
	Global.Player.dashing = false
	if Global.Bt != null: Global.Bt.get_node("Act").hide()
	if BattleResult == 2:
		Event.warp_to(Seq.EscPosition)
	if Attacker!=null and BattleResult!= 1: Attacker.show()
	if BattleResult == 1 and Attacker!=null:
		Attacker.queue_free()
	battle_bars(0)
	PartyUI.UIvisible=true
	Global.Controllable = true
	get_tree().paused = false
	if Global.Player != null:
		await Event.wait(1)
		Global.Player.get_node("DirectionMarker/Finder/Shape").disabled = false
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

func battle_bars(x: int):
	if t != null:
		t.kill()
	$Can.layer = 2
	$Can.show()
	t=create_tween()
	t.set_parallel(true)
	t.set_ease(Tween.EASE_IN_OUT)
	t.set_trans(Tween.TRANS_CUBIC)
	match x:
		0:
			t.tween_property(Global.get_cam(), "zoom", CamZoom, 1)
			t.tween_property($Can/Bars/Down, "global_position", Vector2(-235,786), 0.5)
			t.tween_property($Can/Bars/Up, "global_position", Vector2(-156,-1096), 0.5)
			await t.finished
			$Can.hide()
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
			t.tween_property(Global.get_cam(), "zoom", CamZoom + Vector2(3,3), 0.5)
			t.tween_property($Can/Bars/Down, "global_position", Vector2(-235,133), 0.5)
			t.tween_property($Can/Bars/Up, "global_position", Vector2(-156,-400), 0.5)
			t.tween_property($Can/Bars/Up, "modulate", Color(1,1,1,1), 0.2)
			t.tween_property($Can/Bars/Down, "modulate", Color(1,1,1,1), 0.2)

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
	data.Defeated = Defeated
	data.Members = Global.Members.duplicate()
	for i in data.Members:
		data.Members[data.Members.find(i)] = i.duplicate()
	
	data.KeyInv = Item.KeyInv.duplicate()
	for i in data.KeyInv:
		data.KeyInv[data.KeyInv.find(i)] = i.duplicate()
	data.ConInv = Item.ConInv.duplicate()
	for i in data.ConInv:
		data.ConInv[data.ConInv.find(i)] = i.duplicate()
	var room=PackedScene.new()
	room.pack(get_tree().root.get_node_or_null("Area"))
	data.Room = room
	ResourceSaver.save(data, "user://"+filename+".tres")
	Preview = (await load_res("user://Autosave.tres")).Preview

func load_game(filename:String="Autosave"):
	transition("R")
	t = create_tween()
	t.tween_property(Icon, "global_position", Vector2(1181, 702), 0.2).from(Vector2(1181, 900))
	Icon.play("Load")
	await get_tree().create_timer(1).timeout
	var data:SaveFile = await load_res("user://"+filename+".tres")
	Global.StartTime = Time.get_unix_time_from_system()
	Global.SaveTime = data.PlayTime
	Defeated = data.Defeated
	Global.CameraInd = data.Camera  
	
	if data == null:
		OS.alert("This save file doen't exist", "WHERE FILE")
	if data.Room == null:
		OS.alert("There's no room set in this savefile", "WHERE TF ARE YOU")
	if get_tree().root.get_node_or_null("Area") != null:
		get_tree().root.get_node_or_null("Area").get_tree().change_scene_to_packed(data.Room)
	
	Item.KeyInv = data.KeyInv.duplicate()
	Item.ConInv = data.ConInv.duplicate()
	
	Global.Members = data.Members
	Global.Party.set_to(data.Party)
	
	await get_tree().create_timer(0.01).timeout
	Global.Player.global_position = data.Position
	Global.Controllable =true
	PartyUI._check_party()
	await Item.verify_inventory()
	detransition()

func load_res(path:String):
	loaded_resource = path
	ResourceLoader.load_threaded_request(path)
	loading_thread=true
	await thread_loaded
	return ResourceLoader.load_threaded_get(path)

func chase_mode():
	CamZoom = Global.get_cam().zoom
	chased = true

func white_fadeout(out_time:float=7, wait_time=2, in_time:float = 0.1):
	$Can.show()
	var fader = $Can/Bars/Left.duplicate()
	$Can/Bars.add_child(fader)
	fader.position = Vector2(50,900)
	fader.modulate = Color.TRANSPARENT
	var white = StyleBoxFlat.new()
	white.bg_color = Color.WHITE
	fader.add_theme_stylebox_override("panel", white)
	var tf = create_tween()
	tf.tween_property(fader, "modulate", Color.WHITE, in_time)
	await Event.wait(wait_time)
	tf = create_tween()
	tf.tween_property(fader, "modulate", Color.TRANSPARENT, out_time)
	await tf.finished
	fader.queue_free()
