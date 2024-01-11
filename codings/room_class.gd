extends TileMap
class_name Room

@export var Name: String = "???"
@export var SpawnPlayer = true
@export var SpawnPath: Node = self
##In tilemap coords
@export var SpawnPos: Vector2 = Vector2(0,0)
@export var SpawnZ: Array[int] = [1]
@export_flags_2d_physics var SpawnLayers := 1
@export var AutoLimits = false
##[x]: left [y]: top [z]: right [w]: bottom]
@export var CameraLimits: Array[Vector4] = [Vector4(-10000000, -10000000, 10000000, 10000000)]
@export var CameraZooms: Array[float] = [1]
@export var Stairs: Array[Stair]
enum {LEFT=0, TOP=1, RIGHT=2, BOTTOM=3}
##[0]: left [1]: top [2]: right [3: bottom]
var bounds : Vector4
var Size:Vector2
var Cam = Camera2D.new()
var Followers: Array[Follower] = []


func _ready():
	#print(SpawnLayers)
	material = preload("res://scenes/Shaders/Pixelart.tres")
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(Cam)
	Cam.zoom = Vector2(CameraZooms[Global.CameraInd]*4, CameraZooms[Global.CameraInd]*4)
	Cam.limit_smoothed = true
	Cam.position_smoothing_enabled = true
	Cam.process_mode = Node.PROCESS_MODE_ALWAYS
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
	calculate_bounds()
	#global_position=Size/2
	if SpawnPlayer:
		var Player = preload("res://scenes/Characters/Mira.tscn").instantiate()
		SpawnPath.add_child(Player)
		for i in range(1,4):
			var follower = preload("res://scenes/Characters/Follower.tscn").instantiate()
			follower.name = "Follower" + str(i)
			follower.member = i
			Followers.append(follower)
			SpawnPath.add_child(follower)
		move_child(Player, 0)
#	View.zoom(CameraZooms[Global.CameraInd])
	Global.Area = self
	Global.Tilemap = self
	await Event.wait()
	if SpawnPlayer:
		Global.Player.global_position = map_to_local(SpawnPos)
		handle_z()
		Global.Player.collision_layer = SpawnLayers
		Global.Player.collision_mask = SpawnLayers
	Global.area_initialized.emit()

func calculate_bounds():
	for pos in get_used_cells(0):
		if pos.x < bounds[LEFT]:
			bounds[LEFT] = int(pos.x) - 1
		elif pos.x > bounds[RIGHT]:
			bounds[RIGHT] = int(pos.x) + 1
		if pos.y < bounds[TOP]:
			bounds[TOP] = int(pos.y) - 1
		elif pos.y > bounds[BOTTOM]:
			bounds[BOTTOM] = int(pos.y) + 1
	bounds *= 24
	Size = Vector2(abs(bounds[LEFT])+bounds[RIGHT], abs(bounds[TOP])+bounds[BOTTOM])

func handle_z(z := SpawnZ[Global.CameraInd]):
	Global.Player.z_index = z
	for i in get_children():
		if i is Stair and i not in Stairs:
			Stairs.append(i)
	for i in Stairs:
		if i.zUp == Global.Player.z_index:
			i.go_up()
		if i.zDown == Global.Player.z_index:
			i.go_down()

