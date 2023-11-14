extends CharacterBody2D
class_name NPC
##An extension of [CharacterBody2D] designed for this game. Provides basic movment and interaction.

enum {IDLE, MOVE, INTERACTING, CONTROLLED, CHASE, CUSTOM}

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
var BodyState := IDLE
var RealVelocity := Vector2.ZERO
##Coordinates on the [TileMap]
var coords:Vector2 = Vector2.ZERO
##The [String] used to refer to this node through [codeblock]Event.npc(ID)[/codeblock]
@export var ID: String
var DefaultPos := Vector2.ZERO
@export var Nav:NavigationAgent2D
@export var SpawnOnCameraInd := false
@export var CameraIndex: int
var stopping:=false
@export var Footsteps := true
var LastStepFrame := -1
##How many frames the character has been moving
var move_frames := 0

func _ready() -> void:
	if SpawnOnCameraInd and CameraIndex != Global.CameraInd: queue_free()
	if ID in Loader.Defeated: queue_free()
	#motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	await Event.wait()
	if Nav == null: Nav = get_node_or_null("Nav")
	process_mode = Node.PROCESS_MODE_PAUSABLE
	DefaultPos = global_position
	Event.add_char(self)
	default()

func default() -> void:
#	while true:
#		await move_dir(Vector2(randf_range(-3,3), randf_range(-3,3)))
	pass

func extended_process() -> void:
	pass

func control_process() -> void:
	OS.alert("Only Mira can be set to 'Controlled'")
	BodyState=IDLE

func _physics_process(delta) -> void:
	if get_tree().paused:
		return
	extended_process()
	if self.get_path() in Loader.Defeated: queue_free()
	if Global.Tilemap != null: coords = Global.Tilemap.local_to_map(global_position)
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
		CUSTOM:
			move_and_slide()
	if direction != Vector2.ZERO:
		if get_node_or_null("DirectionMarker") != null:
			$DirectionMarker.global_position=global_position +direction*10
			$DirectionMarker.rotation = direction.angle()
		Facing = Global.get_direction(direction)
	update_anim_prm()

func update_anim_prm() -> void:
	#print(round(get_real_velocity().length()))
	if BodyState == CUSTOM:return
	if get_real_velocity().length() >5:
		#BodyState = MOVE
		$Sprite.play(str("Walk"+Global.get_dir_name(Facing)))
	else:
		#BodyState = IDLE
		position = round(position)
		$Sprite.play(str("Idle"+Global.get_dir_name(Facing)))
	if Footsteps: handle_step_sounds($Sprite)

func handle_step_sounds(sprite: AnimatedSprite2D) -> void:
	if "Idle" in sprite.animation: LastStepFrame = -1
	if get_node_or_null("StdrFootsteps") == null: return
	if (("Walk" in sprite.animation and (
		sprite.frame == 0 or sprite.frame == 2)) or (
			"Dash" in sprite.animation and (
				sprite.frame == 0 or sprite.frame == 4))) and sprite.frame != LastStepFrame and move_frames>10:
		LastStepFrame = sprite.frame
		var rand
		if sprite.frame == 0: rand = str(randi_range(1,3))
		else: rand = str(randi_range(4,6))
		if $StdrFootsteps.get_node_or_null(get_terrain() + str(rand)) == null: return
		$StdrFootsteps.get_node(get_terrain() + str(rand)).play()


func check_terrain(terrain:String, layer:=1) -> bool:
	if get_tile(layer) != null:
		if get_tile(layer).get_custom_data("TerrainType") == terrain:
			return true
	return false

func get_terrain() -> String:
	if get_tile(1) != null and get_tile(1).get_custom_data("TerrainType") != "":
		return get_tile(1).get_custom_data("TerrainType")
	elif get_tile(0) != null and get_tile(0).get_custom_data("TerrainType") != "":
		return get_tile(0).get_custom_data("TerrainType")
	else: return "Generic"

func get_tile(layer:int):
	return Global.Tilemap.get_cell_tile_data(layer, Global.Tilemap.local_to_map(global_position))

func move_dir(dir:Vector2, exact=true, autostop = true) -> void:
	await go_to(coords+(dir), exact, autostop)

func look_to(dir:Vector2):
	BodyState = IDLE
	Facing=Global.get_direction(dir.normalized())
	print(dir, Facing)

func go_to(pos:Vector2,  exact=true, autostop = true) -> void:
	if Nav == null: return
	if self is Mira and Global.Controllable: return
	#await stop_going()
	Nav.set_target_position(Global.Tilemap.map_to_local(pos))
	BodyState = MOVE
	#print("Target: ", Vector2(pos))
	while (not Nav.is_target_reached() and (not Global.Tilemap.local_to_map(global_position) == Vector2i(pos))) and BodyState == MOVE:
		direction = to_local(Nav.get_next_path_position()).normalized()
		await Event.wait()
		#print(not Global.Tilemap.local_to_map(global_position) == Vector2i(pos), not Nav.is_target_reached(), BodyState)
		if Nav == null or ((not Nav.is_target_reachable() or is_on_wall() or get_slide_collision_count()>0) and autostop) or stopping:
			BodyState= IDLE
			return
	if Global.Tilemap.map_to_local(pos) != global_position and Global.Tilemap.local_to_map(global_position) == Vector2i(pos) and exact:
		#print("finished")
		var t = create_tween()
		t.tween_property(self, "global_position", Global.Tilemap.map_to_local(pos), Nav.distance_to_target()/speed)
		await t.finished
	BodyState= IDLE
	direction = Vector2.ZERO
	await Event.wait()

func stop_going() -> void:
	stopping = true
	BodyState= IDLE
	await Event.wait()
	stopping = false

func defeat() -> void:
	Loader.Defeated.append(ID)
	queue_free()

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("DebugR"):
		go_to(Global.Tilemap.local_to_map(get_global_mouse_position()))
		#Event.move_dir(Vector2.LEFT*5)

func set_direction_to(pos:Vector2i) -> void:
	var prev = Nav.target_position
	Nav.set_target_position(Global.globalize(pos))
	direction = to_local(Nav.get_next_path_position()).normalized()

func wall_in_front() -> bool:
	if is_on_wall() and Global.get_direction(get_wall_normal()) == Global.get_direction(): return true
	else: return false

func bubble(stri:String) -> void:
	$Bubble.play(stri)
	await $Bubble.animation_finished
