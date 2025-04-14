extends CharacterBody2D
class_name NPC
##An extension of [CharacterBody2D] designed for this game. Provides basic movment and interaction.

enum {IDLE, MOVE, INTERACTING, CONTROLLED, CHASE, CUSTOM, NONE}

##Speed of movment
@export var speed = 80
##Used to control the direction of the next movment
@export var direction : Vector2 = Vector2.ZERO
##Used to determine what directions the animations face
@export var Facing: Vector2 = Vector2.DOWN
##0: Idle, Not moving[br]
##1: Moving, usually when called by the [method go_to] function[br]
##2: Interacting, doing something other than walking or talking, usuallly with a special animation[br]
##3: Controlled, excludive to [Mira]
##5: Custom
var BodyState:= IDLE:
	set(x):
		BodyState = x
		print(ID+"'s body state set to ", x)
		if BodyState == CUSTOM or BodyState == NONE and self is Mira:
			Global.Controllable = false
		if BodyState == MOVE:
			pass
@export var DefaultState:= 0
var RealVelocity:= Vector2.ZERO
var PrevPosition:= Vector2.ZERO
##Coordinates on the [TileMap]
var coords:Vector2 = Vector2.ZERO
##The [String] used to refer to this node through [codeblock]Event.npc(ID)[/codeblock]
@export var ID: String
var DefaultPos := Vector2.ZERO
@export var Nav:NavigationAgent2D
@export var SpawnOnCameraInd := false
@export var CameraIndex: int
var stopping:= false
@export var Footsteps:= true
var LastStepFrame:= -1
##How many frames the character has been moving
var move_frames:= 0
@export var Shadow: Node2D

func _ready() -> void:
	if Engine.is_editor_hint(): return
	if ID == "": ID = name
	if SpawnOnCameraInd and CameraIndex != Global.CameraInd: queue_free()
	if ID in Loader.Defeated: queue_free()
	#motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	await Event.wait()
	if Nav == null: Nav = get_node_or_null("Nav")
	process_mode = Node.PROCESS_MODE_PAUSABLE
	DefaultPos = global_position
	Event.add_char(self)
	BodyState = DefaultState
	default()

func default() -> void:
	pass

func extended_process() -> void:
	pass

func control_process() -> void:
	OS.alert("Only Mira can be set to 'Controlled'")
	BodyState = IDLE

func _physics_process(delta) -> void:
	if Engine.is_editor_hint(): return
	if get_tree().paused or Loader.InBattle:
		return
	extended_process()
	if self.get_path() in Loader.Defeated: queue_free()
	if Global.Area: coords = Global.Area.local_to_map(global_position)
	RealVelocity = (PrevPosition - position) / get_physics_process_delta_time()
	PrevPosition = position
	match BodyState:
		MOVE, CHASE:
			velocity = direction * speed
			move_and_collide(velocity*delta)
		IDLE:
			direction = Vector2.ZERO
			position = round(position)
			move_and_collide(direction)
		CONTROLLED:
			control_process()
		CUSTOM:
			velocity = direction * speed
			move_and_collide(velocity*delta)
		NONE: return
	if direction.length() > 0.2:
		if get_node_or_null("DirectionMarker"):
			set_dir_marker(direction)
		if direction.length() > 0.05: Facing = Global.get_direction(direction)
	update_anim_prm()

func set_dir_marker(vec: Vector2 = direction):
	vec = vec.normalized()
	$DirectionMarker.global_position=global_position + vec * 10
	$DirectionMarker.rotation = direction.angle()

func update_anim_prm() -> void:
	if $Sprite.sprite_frames == null: return
	if BodyState == CUSTOM: return
	if RealVelocity.length() > 0.3:
		#BodyState = MOVE
		if str("Walk"+Global.get_dir_name(Facing)) in $Sprite.sprite_frames.get_animation_names():
			$Sprite.play(str("Walk"+Global.get_dir_name(Facing)))
	else:
		#BodyState = IDLE
		if str("Idle"+Global.get_dir_name(Facing)) in $Sprite.sprite_frames.get_animation_names():
			$Sprite.play(str("Idle"+Global.get_dir_name(Facing)))
	if Footsteps: handle_step_sounds($Sprite)

func handle_step_sounds(sprite: AnimatedSprite2D) -> void:
	if "Generic" in get_terrain(): return
	if "Idle" in sprite.animation: LastStepFrame = -1
	if not get_node_or_null("StdrFootsteps"): return
	if "Start" in sprite.animation:
		$StdrFootsteps.get_node(get_terrain() + str(randi_range(1,3))).play()
	if (("Walk" in sprite.animation and (
		sprite.frame == 0 or sprite.frame == 2)) or (
			"Dash" in sprite.animation and (
				sprite.frame == 0 or sprite.frame == 4))) and sprite.frame != LastStepFrame and move_frames>10:
		LastStepFrame = sprite.frame
		var rand
		if sprite.frame == 0: rand = str(randi_range(1,3))
		else: rand = str(randi_range(4,6))
		if $StdrFootsteps.get_node_or_null(get_terrain() + str(rand)) == null:
			return
		#print(get_terrain())
		$StdrFootsteps.get_node(get_terrain() + str(rand)).play()

func check_terrain(terrain:String, layer:=1) -> bool:
	if get_tile(layer):
		if get_tile(layer).get_custom_data("TerrainType") == terrain:
			return true
	return false

func get_terrain() -> String:
	var layers: Array[TileMapLayer] = Global.Area.Layers.duplicate()
	layers.reverse()
	var j = layers.size() -1
	for i in layers:
		j -= 1
		if get_tile(j) and get_tile(j).get_custom_data("TerrainType") != "":
			return get_tile(j).get_custom_data("TerrainType")
	return "Generic"

func get_tile(layer:int):
	return Global.Area.Layers[layer].get_cell_tile_data(Global.Area.local_to_map(global_position))

func move_dir(dir: Vector2, use_coords = true, autostop = true) -> void:
	if use_coords: await go_to(coords + dir, use_coords, autostop)
	else: await go_to(position + dir, use_coords, autostop)

func look_to(dir):
	if dir is String: dir = Global.get_dir_from_letter(dir)
	BodyState = MOVE
	Facing = dir
	direction = dir
	await Event.wait()
	BodyState = IDLE
	await Event.wait()

func pathfind_to(pos:Vector2,  exact=true, autostop = true, look_dir: Vector2 = Vector2.ZERO) -> void:
	if Nav == null: return
	if self is Mira and Global.Controllable: await Event.take_control()
	#await stop_going()
	Nav.set_target_position(Global.Area.map_to_local(pos))
	BodyState = MOVE
	#print("Target: ", Vector2(pos))
	while (not Nav.is_target_reached() and (not Global.Area.local_to_map(global_position) == Vector2i(pos))) and BodyState == MOVE:
		await Event.wait()
		direction = to_local(Nav.get_next_path_position()).normalized()
		#print(not Global.Area.local_to_map(global_position) == Vector2i(pos), not Nav.is_target_reached(), BodyState)
		if Nav == null or ((not Nav.is_target_reachable() or is_on_wall() or get_slide_collision_count()>0) and autostop) or stopping:
			BodyState = IDLE
			return
	if Global.Area.map_to_local(pos) != global_position and Global.Area.local_to_map(global_position) == Vector2i(pos) and exact:
		#print("finished")
		var t = create_tween()
		t.tween_property(self, "global_position", Global.Area.map_to_local(pos), Nav.distance_to_target()/speed)
		await t.finished
	BodyState = IDLE
	position = Vector2i(position)
	direction = Vector2.ZERO
	await Event.wait()
	if look_dir != Vector2.ZERO:
		await look_to(look_dir)

##Move towards a specific position until arriving.
##if use_coords is true it will use TileMap coordinates instead of a global position.
##If autostop is true, it will stop when hitting a wall.
##look_dir is the direction the NPC will face after reaching the destination.
##accuracy detarmines how close to the destination the NPC should get.
func go_to(pos:Vector2, use_coords = true, autostop = true, look_dir: Vector2 = Vector2.ZERO, accuracy: int = 5) -> void:
	if self is Mira and Global.Controllable: return
	await stop_going()
	BodyState = MOVE
	if use_coords: pos = Global.Area.map_to_local(pos)
	while round(global_position / accuracy) != round(pos / accuracy):
		direction = to_local(pos).normalized()
		await Event.wait()
		if (autostop and is_on_wall()) or stopping: break
	direction = Vector2.ZERO
	BodyState = IDLE
	if look_dir != Vector2.ZERO: look_to(look_dir)
	await Event.wait()

func set_anim(anim: String):
	$Sprite.play(anim)

func stop_going() -> void:
	stopping = true
	await Event.wait()
	stopping = false

func defeat() -> void:
	Loader.Defeated.append(ID)
	queue_free()

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("DebugR"):
		go_to(get_global_mouse_position(), false)

func wall_in_front() -> bool:
	if is_on_wall() and Global.get_direction(get_wall_normal()) == Global.get_direction(): return true
	else: return false

func bubble(stri:String) -> void:
	$Bubble.play(stri)
	await $Bubble.animation_finished

func shade(opacity: float = 0.8) -> void:
	var t = create_tween()
	t.tween_property($Sprite, "modulate", Color(opacity, opacity, opacity, 1), 0.3)

func unshade() -> void:
	var t = create_tween()
	t.tween_property($Sprite, "modulate", Color.WHITE, 0.3)

func collision(tog: bool = $CollisionShape2D.disabled):
	$CollisionShape2D.set_deferred("disabled", not tog)

func attacked():
	pass

func chain_moves(moves: Array[Vector2]):
	for i in moves:
		await move_dir(i)
