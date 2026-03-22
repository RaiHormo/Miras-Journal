extends Node2D
class_name Room

@export var Name: String = "???"
@export var IsDungeon := true
@export var SpawnPlayer = true
@export var SpawnPath: Node = self
##In tilemap coords
@export var SpawnPos: Vector2 = Vector2(0, 0)
@export var SpawnZ: Array[int] = [1]
@export_flags_2d_physics var SpawnLayers := 1
##[x]: left [y]: top [z]: right [w]: bottom
@export var CameraLimits: Array[Vector4] = [Vector4(-10000000, -10000000, 10000000, 10000000)]
@export var CameraZooms: Array[float] = [1]
var overwrite_zoom: float = 0
var Stairs: Array[Stair]
enum { LEFT = 0, TOP = 1, RIGHT = 2, BOTTOM = 3 }
##[0]: left [1]: top [2]: right [3]: bottom
var Size: Vector2
var Cam = Camera2D.new()
var Followers: Array[CharacterBody2D] = []
var Layers: Array[TileMapLayer]
var CurSubRoom: SubRoom = null
@export var FlameInInd: Array[int]
@export var BattlebackPosition: Vector2


func _ready():
	if position != Vector2.ZERO: push_warning(name, " is not at position 0,0")
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
	if CameraLimits[Global.CameraInd] == Vector4.ZERO:
		Cam.limit_left = -10000000
		Cam.limit_right = 10000000
		Cam.limit_top = -10000000
		Cam.limit_bottom = 10000000
	else:
		Cam.limit_left = (CameraLimits[Global.CameraInd])[LEFT]
		Cam.limit_right = (CameraLimits[Global.CameraInd])[RIGHT]
		Cam.limit_top = (CameraLimits[Global.CameraInd])[TOP]
		Cam.limit_bottom = (CameraLimits[Global.CameraInd])[BOTTOM]
	if SpawnPlayer:
		var Player = preload("uid://sql6r7jv7fjq").instantiate()
		SpawnPath.add_child(Player)
		var dist = 30
		for i in range(1, 4):
			var follower = preload("uid://da22xhcxygcjl").instantiate()
			follower.name = "Follower" + str(i)
			follower.member = i
			follower.distance = dist
			Followers.append(follower)
			SpawnPath.add_child(follower)
			#match i:
				#1: follower.offset = 6
				#2: follower.offset = -6
				#3: follower.offset = 0
			dist += round(30 + dist / 4)
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
		if -Global.CameraInd in FlameInInd or (Global.CameraInd == 0 and -99 in FlameInInd):
			Event.remove_flag("FlameActive")
		Global.Player.collision(true)
	default()
	if Global.Controllable:
		PartyUI.UIvisible = true
		for i in Global.Area.Followers:
			i.dont_follow = false
	name = codename()
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
		zoom = Vector2(CameraZooms[Global.CameraInd] * 4, CameraZooms[Global.CameraInd] * 4)
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


func get_z() -> int:
	if is_instance_valid(Global.Player): return Global.Player.z_index
	else: return SpawnZ[Global.CameraInd] if Global.CameraInd < SpawnZ.size() else 0


func map_to_local(vec: Vector2i) -> Vector2:
	return Layers[0].map_to_local(vec)


func local_to_map(vec: Vector2) -> Vector2i:
	return Layers[0].local_to_map(vec)

var t


func fade():
	if is_instance_valid(t): t.kill()
	t = create_tween()
	t.tween_property($SubRoomBg, "modulate", Color.WHITE, 0.3)
	for i in Layers:
		i.collision_enabled = false
	await t.finished
	for i in Layers:
		i.hide()


func unfade():
	if is_instance_valid(t): t.kill()
	t = create_tween()
	for i in Layers:
		i.collision_enabled = true
		i.show()
	t.tween_property($SubRoomBg, "modulate", Color.TRANSPARENT, 0.3)


func _physics_process(delta: float) -> void:
	if has_node("SubRoomBg") and CurSubRoom != null:
		$SubRoomBg.position = Cam.position


func go_to_subroom(subroom: String, fast = false) -> Vector2:
	for i in get_children():
		if not is_instance_valid(i): continue
		if i is SubRoom and i.name == subroom:
			await i.transition(0)
			return i.cam_pos
		elif i is TransferZone and i.name == "Transfer" + subroom:
			return i.position - (i.Direction * i.scale) * 80
		elif i is Marker2D and i.name == "Mark" + subroom:
			return i.position
	return Vector2.ZERO


func get_layers() -> Array[TileMapLayer]:
	return Layers if CurSubRoom == null else CurSubRoom.Layers


func get_tile(pos: Vector2, layer: int = 1):
	var tilemap = get_layers()[layer]
	tilemap.get_cell_tile_data(pos)


func get_terrain(coords: Vector2i) -> String:
	var layers: Array[TileMapLayer] = get_layers().duplicate()
	layers.reverse()
	for i in layers:
		var data = i.get_cell_tile_data(coords)
		if is_instance_valid(data) and data.has_custom_data("TerrainType"):
			var terrain: String = data.get_custom_data("TerrainType")
			#print(i, terrain, terrain)
			if not terrain.is_empty():
				return terrain
	return "Generic"


func codename() -> String:
	return Name.to_pascal_case()
