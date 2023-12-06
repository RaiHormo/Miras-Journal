extends TileMap
class_name Room

@export var Name: String = "???"
@export var SpawnPlayer = true
@export var SpawnPath: Node = self
@export var SpawnPos: Vector2 = Vector2(0,0)
@export var AutoLimits = false
@export var CameraLimits: Array[Vector4] = [Vector4(-10000000, -10000000, 10000000, 10000000)]
@export var CameraZooms: Array[float] = [1]
enum {LEFT=0, TOP=1, RIGHT=2, BOTTOM=3}
##[0]: left [1]: top [2]: right [3: bottom]
var bounds : Vector4
var Size:Vector2
var Cam = Camera2D.new()

func _ready():
	material = preload("res://scenes/Shaders/Pixelart.tres")
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(Cam)
	Cam.zoom = Vector2(CameraZooms[Global.CameraInd]*4, CameraZooms[Global.CameraInd]*4)
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
			SpawnPath.add_child(follower.duplicate())
		move_child(Player, 0)
#	View.zoom(CameraZooms[Global.CameraInd])
	Global.Area = self
	Global.Tilemap = self
	await Event.wait()
	if SpawnPlayer: Global.Player.global_position = map_to_local(SpawnPos)
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



