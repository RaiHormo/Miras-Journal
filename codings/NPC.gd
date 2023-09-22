extends CharacterBody2D
class_name NPC
##An extension of [CharacterBody2D] designed for this game. Provides basic movment and interaction.

enum {IDLE, MOVE, INTERACTING, CONTROLLED, CHASE}

##Speed of movment
@export var speed = 75
##Used to control the direction of the next movment
@export var direction : Vector2 = Vector2.ZERO
##Used to determine what directions the animations face
@export var Facing: Vector2
##0: Idle, Not moving[br]
##1: Moving, usually when called by the [method go_to] function[br]
##2: Interacting, doing something other than walking or talking, usuallly with a special animation[br]
##3: Controlled, excludive to [Mira]
var BodyState = IDLE
var RealVelocity = Vector2.ZERO
##Coordinates on the [TileMap]
var coords:Vector2 = Vector2.ZERO
##The [String] used to refer to this node through [codeblock]Event.npc(ID)[/codeblock]
@export var ID: String
@export var DefaultPos = Vector2.ZERO
@export var Nav:NavigationAgent2D
@export var SpawnOnCameraInd = false
@export var CameraIndex: int
var stopping=false

func _ready():
	if SpawnOnCameraInd and CameraIndex != Global.CameraInd: queue_free()
	if self.get_path() in Loader.Defeated: queue_free()
	#motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	process_mode = Node.PROCESS_MODE_PAUSABLE
	DefaultPos = Global.Tilemap.local_to_map(global_position)
	Event.add_char(self)
	default()

func default():
#	while true:
#		await move_dir(Vector2(randf_range(-3,3), randf_range(-3,3)))
	pass

func extended_process():
	pass

func control_process():
	OS.alert("Only Mira can be set to 'Controlled'")
	BodyState=IDLE

func _physics_process(delta):
	if get_tree().paused:
		return
	extended_process()
	if self.get_path() in Loader.Defeated: queue_free()
	coords = Global.Tilemap.local_to_map(global_position)
	match BodyState:
		MOVE, CHASE:
			velocity = direction * speed
			move_and_slide()
		IDLE:
			direction = Vector2.ZERO
			velocity = direction
			move_and_slide()
		CONTROLLED:
			control_process()
	if direction != Vector2.ZERO:
		if get_node_or_null("DirectionMarker") != null:
			$DirectionMarker.global_position=global_position +direction*10
			$DirectionMarker.rotation = direction.angle()
		Facing = Global.get_direction(direction)
	update_anim_prm()

func update_anim_prm():
	#print(round(get_real_velocity().length()))
	if get_real_velocity().length() >5:
		#BodyState = MOVE
		$Sprite.play(str("Walk"+Global.get_dir_name(Facing)))
	else:
		#BodyState = IDLE
		position = round(position)
		$Sprite.play(str("Idle"+Global.get_dir_name(Facing)))

func move_dir(dir:Vector2, exact=true, autostop = true):
	await go_to(coords+(dir), exact, autostop)

func look_to(dir:Vector2):
	Facing=Global.get_direction(dir.normalized())
	print(dir, Facing)

func go_to(pos:Vector2,  exact=true, autostop = true):
	if Nav == null: return
	if self is Mira and Global.Controllable: return
	await stop_going()
	Nav.set_target_position(Global.Tilemap.map_to_local(pos))
	BodyState = MOVE
	#print("Target: ", Vector2(pos))
	while (not Nav.is_target_reached() and (not Global.Tilemap.local_to_map(global_position) == Vector2i(pos))) and BodyState == MOVE:
		direction = to_local(Nav.get_next_path_position()).normalized()
		await Event.wait()
		#print(not Global.Tilemap.local_to_map(global_position) == Vector2i(pos), not Nav.is_target_reached(), BodyState)
		if ((not Nav.is_target_reachable() or is_on_wall() or get_slide_collision_count()>0) and autostop) or stopping: 
			BodyState= IDLE
			return
	if Global.Tilemap.map_to_local(pos) != global_position and Global.Tilemap.local_to_map(global_position) == Vector2i(pos) and exact:
		#print("finished")
		var t = create_tween()
		t.tween_property(self, "global_position", Global.Tilemap.map_to_local(pos), Nav.distance_to_target()/speed)
		await t.finished
	if BodyState == MOVE: BodyState= IDLE
#	direction = Vector2.ZERO

func stop_going():
	stopping = true
	BodyState= IDLE
	await Event.wait()
	stopping = false

func defeat():
	Loader.Defeated.append(self.get_path())
	queue_free()

func _input(event):
	if Input.is_action_just_pressed("DebugR"):
		go_to(Global.Tilemap.local_to_map(get_global_mouse_position()))
		#Event.move_dir(Vector2.LEFT*5)

func set_direction_to(pos):
	Nav.set_target_position(Global.globalize(pos))
	direction = to_local(Nav.get_next_path_position()).normalized()

func wall_in_front():
	if is_on_wall() and Global.get_direction(get_wall_normal()) == Global.get_direction(): return true
	else: return false
