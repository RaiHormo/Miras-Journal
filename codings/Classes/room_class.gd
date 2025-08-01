extends Node2D
class_name Room

@export var Name: String = "???"
@export var IsDungeon:= true
@export var SpawnPlayer = true
@export var SpawnPath: Node = self
##In tilemap coords
@export var SpawnPos: Vector2 = Vector2(0,0)
@export var SpawnZ: Array[int] = [1]
@export_flags_2d_physics var SpawnLayers := 1
@export var AutoLimits = false
##[x]: left [y]: top [z]: right [w]: bottom
@export var CameraLimits: Array[Vector4] = [Vector4(-10000000, -10000000, 10000000, 10000000)]
@export var CameraZooms: Array[float] = [1]
var overwrite_zoom: float = 0
var Stairs: Array[Stair]
enum {LEFT=0, TOP=1, RIGHT=2, BOTTOM=3}
##[0]: left [1]: top [2]: right [3]: bottom
var bounds : Vector4
var Size:Vector2
var Cam = Camera2D.new()
var Followers: Array[CharacterBody2D] = []
var Layers: Array[TileMapLayer]
var CurSubRoom: SubRoom = null
@export var FlameInInd: Array[int]

func _ready():
	material = preload("res://codings/Shaders/Pixelart.tres")
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	Cam.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	Cam.process_callback = Camera2D.CAMERA2D_PROCESS_IDLE
	Cam.position_smoothing_speed = 6
	add_child(Cam)
	setup_params()

	if get_node_or_null("SubRoomBg"): $SubRoomBg.modulate = Color.TRANSPARENT
	for i in get_children():
		if i is TileMapLayer:
			Layers.append(i)
	if AutoLimits:
		Cam.limit_left = bounds[LEFT]
		Cam.limit_right = bounds[RIGHT]
		Cam.limit_top = bounds[TOP]
		Cam.limit_bottom = bounds[BOTTOM]
	else:
		Cam.limit_left = (CameraLimits[Global.CameraInd])[LEFT]
		Cam.limit_right = (CameraLimits[Global.CameraInd])[RIGHT]
		Cam.limit_top = (CameraLimits[Global.CameraInd])[TOP]
		Cam.limit_bottom = (CameraLimits[Global.CameraInd])[BOTTOM]
	if SpawnPlayer:
		var Player = preload("res://codings/Mira.tscn").instantiate()
		SpawnPath.add_child(Player)
		var dist = 30
		for i in range(1,4):
			var follower = preload("res://codings/Follower.tscn").instantiate()
			follower.name = "Follower" + str(i)
			follower.member = i
			follower.distance = dist
			Followers.append(follower)
			SpawnPath.add_child(follower)
			match i:
				1: follower.offset = 24
				2: follower.offset = -24
				3: follower.offset = 0
			dist += 25
		move_child(Player, 0)
	Global.Area = self
	await Global.player_ready
	Global.check_party.emit()
	if SpawnPlayer:
		Global.Player.global_position = map_to_local(SpawnPos)
		handle_z()
		Global.Player.collision_layer = SpawnLayers
		Global.Player.collision_mask = SpawnLayers
	await Event.wait()
	if is_instance_valid(Global.Player):
		if Global.CameraInd in FlameInInd:
			if not Event.f("FlameActive"): Global.Player.activate_flame()
		if -Global.CameraInd in FlameInInd:
			Event.remove_flag("FlameActive")
		Global.Player.collision(true)
	default()
	if Global.Controllable:
		PartyUI.UIvisible = true
		for i in Global.Area.Followers:
			i.dont_follow = false
	Global.area_initialized.emit()

func setup_params(tween_zoom = false):
	Cam.limit_smoothed = true
	Cam.position_smoothing_enabled = true
	Cam.position_smoothing_speed = 10
	Cam.process_mode = Node.PROCESS_MODE_ALWAYS
	var zoom = Vector2(4, 4)
	if overwrite_zoom > 0:
		zoom = Vector2(overwrite_zoom, overwrite_zoom)
	if overwrite_zoom == 0 and Global.CameraInd < CameraZooms.size() and CurSubRoom == null:
		zoom = Vector2(CameraZooms[Global.CameraInd]*4, CameraZooms[Global.CameraInd]*4)
	elif CurSubRoom is SubRoom:
		zoom = Vector2(CurSubRoom.cam_zoom, CurSubRoom.cam_zoom)
	if tween_zoom:
		var t = create_tween()
		t.set_ease(Tween.EASE_OUT)
		t.set_trans(Tween.TRANS_QUART)
		t.tween_property(Cam, "zoom", zoom, 0.3)
	else:
		Cam.zoom = zoom

func default():
	pass

func handle_z(z := -1):
	if z == -1: z = SpawnZ[Global.CameraInd] if Global.CameraInd < SpawnZ.size() else 0
	Global.Player.z_index = z
	for i in get_children():
		if i is Stair and i not in Stairs:
			Stairs.append(i)
	for i in Stairs:
		if i.zUp == Global.Player.z_index:
			i.go_up()
		if i.zDown == Global.Player.z_index:
			i.go_down()

func map_to_local(vec: Vector2i) -> Vector2:
	return Layers[0].map_to_local(vec)

func local_to_map(vec: Vector2) -> Vector2i:
	return Layers[0].local_to_map(vec)

func fade():
	var t = create_tween()
	t.tween_property($SubRoomBg, "modulate", Color.WHITE, 0.3)
	for i in Layers:
		i.collision_enabled = false
	await t.finished
	for i in Layers:
		i.hide()

func unfade():
	var t = create_tween()
	for i in Layers:
		i.collision_enabled = true
		i.show()
	t.tween_property($SubRoomBg, "modulate", Color.TRANSPARENT, 0.3)

func _physics_process(delta: float) -> void:
	if get_node_or_null("SubRoomBg") and CurSubRoom != null:
		$SubRoomBg.position = Cam.position
	#if is_instance_valid(Global.Player) and Global.Controllable and (
		#Global.Player.position.x < CameraLimits[Global.CameraInd].x -64 or
		#Global.Player.position.x > CameraLimits[Global.CameraInd].z +64 or
		#Global.Player.position.y < CameraLimits[Global.CameraInd].y -64 or
		#Global.Player.position.y > CameraLimits[Global.CameraInd].w +64
	#):
		#Global.toast("What are you doing there?")
		#Global.CameraInd = 0
		#Global.Player.position = map_to_local(SpawnPos)
		#Global.refresh()

func go_to_subroom(subroom: String):
	for i in get_children(): 
		if is_instance_valid(i) and i.name == subroom and i is SubRoom:
			await i.transition()
