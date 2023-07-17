extends Control
@export var scene:String
var status
var progress = []
var loading = false
@export var direc : String
@onready var t: Tween = get_tree().create_tween()
var Seq :BattleSequence= preload("res://database/BattleSeq/DebugDummy.tres")
var InBattle = false

func _ready():
	$Can/Icon.hide()
	$Can/Down.hide()
	$Can/Up.hide()
	$Can/Left.hide()
	$Can/Right.hide()
	$Can/Icon.position = Vector2(1181, 702)

func travel_to(sc, trans):
	scene = "res://scenes/Rooms/" + sc + ".tscn"
	if scene != "":
		ResourceLoader.load_threaded_request(scene)
	transition(trans)
	await get_tree().create_timer(0.3).timeout
	status = ResourceLoader.load_threaded_get_status(scene, progress)
	if status == ResourceLoader.THREAD_LOAD_LOADED:
		done()
	else:
		$Can/Icon.show()
		$Anim.play("default")
		loading = true
	
	
func _process(delta):
	if loading == true:
		status = ResourceLoader.load_threaded_get_status(scene, progress)
		if status == ResourceLoader.THREAD_LOAD_LOADED:
			loading = false
			done()
		if status == ResourceLoader.THREAD_LOAD_FAILED or status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			OS.alert("THE SCENE FAILED TO LOAD, AND IT YOUR DAMN FAULT! DID YOU MOVE FILES AROUND OR SOMETHING?!", "OH FUCK")
			loading = false

func transition(dir):
	t.kill()
	Global.Controllable = false
	t=create_tween()
	t.set_parallel(false)
	t.set_ease(Tween.EASE_IN)
	t.set_trans(Tween.TRANS_QUART)
	$Can.layer = 9
	direc = dir
	t.tween_property($Can/Icon, "position", Vector2(1181, 702), 0.2).from(Vector2(1181, 900))
	if dir == "U":
		$Can/Down.show()
		t.parallel()
		t.tween_property($Can/Down, "position", Vector2(-235,-126), 0.3).from(Vector2(-235,786))
	elif dir == "D":
		$Can/Up.show()
		t.parallel()
		t.tween_property($Can/Up, "position", Vector2(-156,-126), 0.3).from(Vector2(-156,-1096))
	elif dir == "R":
		$Can/Left.show()
		t.parallel()
		t.tween_property($Can/Left, "position", Vector2(-200,-204), 0.3).from(Vector2(-1720,-204))
	elif dir == "L":
		$Can/Right.show()
		t.parallel()
		t.tween_property($Can/Right, "position", Vector2(-200,-177), 0.3).from(Vector2(1394,-177))
	else:
		t.set_parallel(true)
		$Can/Right.show()
		$Can/Left.show()
		$Can/Up.show()
		$Can/Down.show()
		t.tween_property($Can/Down, "position", Vector2(-235,-126), 0.3).from(Vector2(-235,786))
		t.tween_property($Can/Up, "position", Vector2(-156,-126), 0.3).from(Vector2(-156,-1096))
		t.tween_property($Can/Left, "position", Vector2(-200,-204), 0.3).from(Vector2(-1720,-204))
		t.tween_property($Can/Right, "position", Vector2(-200,-177), 0.3).from(Vector2(1394,-177))

func done():
	get_tree().change_scene_to_file(scene)
	await get_tree().create_timer(0.2).timeout
	t=create_tween()
	t.set_parallel(false)
	t.set_ease(Tween.EASE_IN)
	t.set_trans(Tween.TRANS_QUART)
	$Can/Up.modulate = Color.WHITE
	$Can/Down.modulate = Color.WHITE
	if direc == "U":
		t.tween_property($Can/Down, "position", Vector2(-235,-1096), 0.3)
	elif direc == "D":
		t.tween_property($Can/Up, "position", Vector2(-156,786), 0.3)
	elif direc == "R":
		t.tween_property($Can/Left, "position", Vector2(2000,-204), 0.3)
	elif direc == "L":
		t.tween_property($Can/Right, "position", Vector2(-2000,-177), 0.3)
	$Anim.play("exit")
	t.tween_property($Can/Icon, "position", Vector2(1181, 900), 0.3)
	await t.finished
	$Can/Icon.hide()
	$Can/Down.hide()
	$Can/Up.hide()
	$Can/Left.hide()
	$Can/Right.hide()
	Global.Controllable = true
	get_tree().paused = false

func StartBattle(stg):
	PartyUI.UIvisible = false
	#Engine.time_scale = 0.1
	Global.Controllable = false
	print("Battle start!")
	get_tree().paused = true
	#get_node("/root/Area/TileMap/OvPlayer/Body/Camera2D").current = false
	Seq = load("res://database/BattleSeq/"+ stg +".tres")
	if Seq.Transition:
		battle_bars(4)
		await t.finished
	get_tree().get_root().add_child(preload("res://scenes/Battle.tscn").instantiate())
	InBattle = true

func battle_bars(x: int):
	$Can.layer = 0
	$Can/Down.show()
	$Can/Up.show()
	t.kill()
	t=create_tween()
	t.set_parallel(true)
	t.set_ease(Tween.EASE_IN_OUT)
	t.set_trans(Tween.TRANS_QUART)
	match x:
		0:
			t.tween_property($Can/Down, "position", Vector2(-235,786), 0.5)
			t.tween_property($Can/Up, "position", Vector2(-156,-1096), 0.5)
			await t.finished
			$Can/Down.hide()
			$Can/Up.hide()
		1:
			t.tween_property($Can/Down, "position", Vector2(-235,700), 0.5)
			t.tween_property($Can/Up, "position", Vector2(-156,-1000), 0.5)
			t.tween_property($Can/Up, "modulate", Color(1,1,1,0.5), 1)
			t.tween_property($Can/Down, "modulate", Color(1,1,1,0.5), 1)
		2:
			t.tween_property($Can/Down, "position", Vector2(-235,600), 0.5)
			t.tween_property($Can/Up, "position", Vector2(-156,-900), 0.5)
			t.tween_property($Can/Up, "modulate", Color(1,1,1,0.7), 1)
			t.tween_property($Can/Down, "modulate", Color(1,1,1,0.7), 1)
		3:
			t.tween_property($Can/Down, "position", Vector2(-235,550), 0.5)
			t.tween_property($Can/Up, "position", Vector2(-156,-850), 0.5)
			t.tween_property($Can/Up, "modulate", Color(1,1,1,0.7), 1)
			t.tween_property($Can/Down, "modulate", Color(1,1,1,0.7), 1)
		4:
			t.tween_property($Can/Down, "position", Vector2(-235,133), 0.5)
			t.tween_property($Can/Up, "position", Vector2(-156,-400), 0.5)
			t.tween_property($Can/Up, "modulate", Color(1,1,1,1), 0.5)
			t.tween_property($Can/Down, "modulate", Color(1,1,1,1), 0.5)
			
func end_battle():
	if Seq.Transition:
		Loader.battle_bars(4)
		await get_tree().create_timer(0.5).timeout
	InBattle= false
	get_tree().paused = false
	Global.Controllable = true
	battle_bars(0)
