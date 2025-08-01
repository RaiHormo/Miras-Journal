extends NPC
class_name Mira
##The script that handles's Mira's movment

##The parent of the parent node should always be a Global.Area
#@onready var Global.Area:TileMap = Global.Area
##Whether the dash is active
var dashing := false
var winding_attack := false
##When the player is supposed to be in a midair perspective
var midair := false
##true is there is a wall in front of the player
var undashable := false
##Direction of the dash
var dashdir: Vector2 = Vector2.ZERO
##Use flame to light up the enviroment
@export var can_dash = true
const dash_speed := 200
const walk_speed := 100
var first_frame := true
@onready var flame: PointLight2D = $Flame
var attacking := false
@onready var used_sprite: AnimatedSprite2D = %Base
var is_clone: bool = false
var can_jump:= false
var cant_bump:= false

func _ready() -> void:
	collision(false)
	ID = "P"
	Event.add_char(self)
	Item.pickup.connect(_on_pickup)
	await Event.wait()
	if Global.Area == null:
		OS.alert("THIS IS THE PLAYER SCENE", "WRONG SCENE IDIOT")
		Loader.travel_to("Debug")
		queue_free()
		return
	Loader.InBattle = false
	if not is_clone:
		Global.Player = self
		var cam: Camera2D = Global.get_cam()
		if cam != null:
			for i in Global.Area.get_children():
				if "Camera" in i.name: i.enabled = false
			$Camera2D.remote_path = cam.get_path()
			cam.enabled = true
	set_anim("Idle"+str(Global.get_dir_name(Global.get_direction())))
	$Attack/CollisionShape2D.disabled = true
	$Attack/AttackPreview/CollisionShape2D.disabled = true
	Global.player_ready.emit()

#func _process(delta: float) -> void:
	#Steam.run_callbacks()
	#Steam.runFrame()

func extended_process() -> void:
	if Global.Controllable:
		BodyState = CONTROLLED
		check_flame()
	else:
		first_frame = true
		if BodyState == CONTROLLED:
			BodyState = CUSTOM

func control_process():
	if first_frame:
		if Engine.time_scale > 1: Engine.time_scale = 1
		$Attack/CollisionShape2D.set_deferred("disabled", true)
		first_frame = false
		reset_speed()
	if Global.Area: coords = Global.Area.local_to_map(global_position)
	direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down", 0.1)
	if abs(direction.x) < 0.1: direction.y += direction.x; direction.x = 0
	if abs(direction.y) < 0.1: direction.x += direction.y; direction.y = 0
	undashable = false
	if is_on_wall():
		if round(get_wall_normal())*-1 == Global.get_direction(direction):
			if can_jump and Input.is_action_pressed("Dash"):
				position -= direction *6
			else:
				undashable = true
	if Global.Controllable:
		if "Dash" in %Base.animation and not dashing:
			stop_dash()
		if Input.is_action_pressed("Dash") and Global.get_direction(
			direction)!= dashdir*Vector2(-1,-1) and direction!=Vector2.ZERO and can_dash:
			if dashing:
				if dashdir.y == 0:
					direction.y /= 1.2
				if dashdir.x == 0:
					direction.x /= 1.2
				speed = min(speed * 1.005, 350)
			if not dashing:
				if undashable:
					reset_speed()
					await set_anim("Deny"+Global.get_dir_name(Global.PlayerDir), true)
					set_anim()
					return
				else:
					dashdir = Global.get_direction(direction)
					dashing = true
					Global.Controllable=false
					BodyState = CUSTOM
					direction = dashdir
					reset_speed()
					if BodyState == CUSTOM:
						Global.Controllable=true
					if speed < dash_speed:
						speed = dash_speed
			elif Global.get_direction(direction.normalized()) != dashdir:
				stop_dash()
		elif dashing:
			stop_dash()
		if direction != Vector2.ZERO:
			Global.PlayerDir = direction
			Global.PlayerPos = global_position
		if dashing:
			velocity = ((dashdir+direction).normalized() * speed)
		else:
			velocity = direction * speed
		if RealVelocity != Vector2.ZERO:
			if RealVelocity.x == 0: position.x = roundf(position.x)
			if RealVelocity.y == 0: position.y = roundf(position.y)
		var old_position = global_position
		if direction.length()>0.1:
			move_and_slide()
		if Input.is_action_just_pressed("OVAttack") and Global.Controllable:
			attack()

	if Global.Settings.DebugMode:
		if Input.is_action_just_pressed("DebugF"):
			Global.toast("Collision set to " + str($CollisionShape2D.disabled))
			$CollisionShape2D.disabled = Global.toggle($CollisionShape2D.disabled)

func update_anim_prm() -> void:
	if get_node_or_null("%Base") == null: return
	if Footsteps: handle_step_sounds(used_sprite)
	if BodyState == CUSTOM: return
	if Facing == Vector2.ZERO: return
	if BodyState == CONTROLLED:
		if (abs(RealVelocity.length())>1 and Global.Controllable):
			if dashing:
				reset_speed()
				set_anim("Dash"+Global.get_dir_name(dashdir)+"Loop")
			else:
				speed = min(walk_speed, speed)
				set_anim(str("Walk"+Global.get_dir_name(Facing)))
				for i in $Sprite.get_children():
					i.speed_scale = min(max((RealVelocity.length() * get_physics_process_delta_time()), 0.3), 1)
			if move_frames < 0: move_frames = 0
			move_frames+=1
		elif Global.Controllable and ("Walk" in used_sprite.animation or
		("Dash" in used_sprite.animation and dashdir == Vector2.ZERO)):
			move_frames = 0
			reset_speed()
			set_anim(str("Idle"+Global.get_dir_name(Facing)))
		else:
			move_frames -= 1
		if direction.length()>RealVelocity.length() and dashing and not can_jump:
			stop_dash()
	else:
		if RealVelocity.length() > 1:
			if dashing:
				set_anim("Dash"+Global.get_dir_name(dashdir)+"Stop")
			else:
				set_anim(str("Walk"+Global.get_dir_name(Facing)))
		else:
			if RealVelocity == Vector2.ZERO:
				position = round(position)
			set_anim(str("Idle"+Global.get_dir_name(Facing)))

##Item pickup animation
func _on_pickup() -> void:
	await Event.take_control()
	if Global.get_direction() == Vector2.LEFT: await set_anim("PickUpLeft", true)
	else: await set_anim("PickUpRight", true)
	Event.give_control()
	set_anim()

func _check_party() -> void:
	if get_node_or_null("%Base") == null: return
	elif Global.Party.Leader:
		%Base.sprite_frames =  Global.Party.Leader.OV

##Sets the animation for all sprite layers
func set_anim(anim:String = "Idle"+Global.get_dir_name(), wait = false, overwrite_bodystate = false) -> void:
	#print(anim)
	if get_node_or_null("%Base") == null: return
	if not Global.Controllable: reset_speed()
	if overwrite_bodystate: BodyState = CUSTOM
	if Event.f(&"FlameActive") and anim in %Flame.sprite_frames.get_animation_names():
		used_sprite = %Flame
	elif Event.f(&"HasBag") and anim in %Bag.sprite_frames.get_animation_names():
		used_sprite = %Bag
	elif anim in %Base.sprite_frames.get_animation_names():
		used_sprite = %Base
	else:
		if wait: await Event.wait()
		return
	hide_other_sprites()
	#print(used_sprite.name, " ", anim)
	used_sprite.play(anim)
	if wait:
		while used_sprite.is_playing() and used_sprite.animation == anim:
			await get_tree().physics_frame

func hide_other_sprites():
	for i in $Sprite.get_children():
		if i == used_sprite: i.show()
		elif i == %Flame and Event.f(&"FlameActive") and used_sprite != %Flame:
			flame_out_of_the_way()
		else: i.hide()

func flame_out_of_the_way():
	if "Flame" not in %Flame.animation:
		%Flame.show()
		%Flame.play("FlameGo")
		await %Flame.animation_finished
		if "Flame" in %Flame.animation: %Flame.play("FlameFloat")
	#elif "Stop" in anim:
		#%Flame.play_backwards("FlameGo")

func activate_flame(animate:=true) -> void:
	Event.add_flag(&"FlameActive")
	await Event.wait()
	check_flame(true)
	if animate:
		Global.Controllable = false
		BodyState = NONE
		await set_anim("FlameActive", true)
		set_anim("IdleRight")

func check_flame(force:= false) -> void:
	if not Global.Controllable and not force: return
	if Event.check_flag(&"FlameActive"):
		if get_node_or_null("Flame") == null: return
		if flame.energy == 0:
			flame.flicker = true
			if not force: activate_flame(false)
			while flame.energy < 1.5:
				flame.energy += 0.03
				await Event.wait()
			flame.energy = 1.5
			flame.flicker = true
	elif get_node_or_null("Flame") and flame.energy != 0:
		reset_sprite()
		flame.flicker = false
		flame.energy = 0

func reset_sprite():
	%Base.sprite_frames = Global.Party.Leader.OV

##For opening the menu
func bag_anim() -> void:
	BodyState = NONE
	if get_node_or_null("%Base") == null: return
	await set_anim("BagOpen", true)
	set_anim("BagIdle")

##Handles the animation when the dash is stopped, either doing the slide or hit one depending on the wall in front of her
func stop_dash(slide = true) -> void:
	if (BodyState!=CONTROLLED or "Stop" in used_sprite.animation or "Hit" in
	used_sprite.animation or midair or not dashing): return
	dashing = false
	#print(RealVelocity)
	reset_speed()
	#for i in Global.Area.Layers.size():
		#if ((Global.Area.Layers[i].get_cell_tile_data(coords+dashdir*2)!= null and Global.Area.Layers[i].get_cell_tile_data(coords+dashdir*2).get_collision_polygons_count(0)>0) or
			#Global.Area.Layers[i].get_cell_tile_data(coords)!= null and Global.Area.Layers[i].get_cell_tile_data(coords).get_collision_polygons_count(0)>0):
			#slide = false
	if (undashable and Global.get_direction() == dashdir) and move_frames > 5:
		speed = walk_speed
		await bump()
	else:
		set_anim("Dash"+Global.get_dir_name(dashdir)+"Stop")
		Global.Controllable=false
		if Input.is_action_pressed("Dash") and Global.get_direction(direction) != dashdir and direction != Vector2.ZERO and not Global.get_direction(direction, true) == -dashdir:
			await get_tree().create_timer(0.1).timeout
		else:
			speed = walk_speed
			if slide:
				while used_sprite.is_playing() and "Stop" in used_sprite.animation:
					if direction == Vector2.ZERO: 
						direction = dashdir * 0.3
						speed = max(0, speed - 2)
					velocity = dashdir * speed
					speed = max(0, speed - 2)
					await Event.wait()
		Global.Controllable = true
		Global.check_party.emit()
		BodyState = CONTROLLED
		velocity = Vector2.ZERO
	dashdir = Vector2.ZERO
	move_frames = 0
	if "Stop" in used_sprite.animation or "Hit" in used_sprite.animation:
		set_anim(str("Idle"+Global.get_dir_name()))

func reset_speed() -> void:
	if get_node_or_null("%Base") == null: return
	for i in $Sprite.get_children():
		i.speed_scale=1

func bump(dir: Vector2 = Vector2.ZERO) -> void:
	if cant_bump: return
	winding_attack = false
	direction = Vector2.ZERO
	if dir == Vector2.ZERO: dir = dashdir
	Global.jump_to_global(self, global_position - dir*15, 15, 0.5)
	set_anim("Dash"+Global.get_dir_name(dashdir)+"Hit")
	var mem = Global.Controllable
	Global.Controllable = false
	if used_sprite.is_playing(): await used_sprite.animation_finished
	Global.Controllable = mem

func camera_follow(follow = !$Camera2D.update_position) -> void:
	$Camera2D.update_position = follow

func attack():
	if not Item.check_item("LightweightAxe", "Key"):
		Global.buzzer_sound()
		return
	if dashing: await stop_dash()
	reset_speed()
	speed = 40
	Global.Controllable = false
	$Attack/AttackPreview.collision_layer = collision_layer
	$Attack/AttackPreview.collision_mask = collision_mask
	$Attack/AttackPreview/CollisionShape2D.disabled = false
	var checked := false
	attacking = true
	await Event.wait()
	check_before_attack()
	$Attack.rotation = Global.get_direction().angle()
	await set_anim("Attack"+Global.get_dir_name()+"Windup", true)
	winding_attack = true
	while Input.is_action_pressed("OVAttack") or not checked:
		direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down", 0.4)
		if direction != Vector2.ZERO: Global.PlayerDir = direction
		set_anim("Attack"+Global.get_dir_name()+"Windup")
		check_before_attack()
		if not winding_attack: 
			attacking = false
			BodyState = IDLE
			set_anim()
			$Attack/AttackPreview/CollisionShape2D.disabled = false
			$Attack/CollisionShape2D.disabled = false
			speed = walk_speed
			return
		checked = true
		await get_tree().physics_frame
	winding_attack = false
	$Attack/CollisionShape2D.disabled = false
	var hits = false
	BodyState = CUSTOM
	direction = Vector2.ZERO
	await get_tree().physics_frame
	for i in $Attack/AttackPreview.get_overlapping_bodies():
		#print(i)
		if not (i is NPC or i is Follower or i is Mira):
			hits = true
	#print("pt1: " + str(hits))
	for i in $Attack.get_overlapping_bodies():
		#print(i)
		if (i is NPC or i is Follower) and not i is Mira:
			hits = false
	#print("pt2: " + str(hits))
	var audio = preload("res://sound/SFX/Swing.ogg")
	var anim = "Attack" + Global.get_dir_name()
	if hits:
		anim = "Attack" + Global.get_dir_name() + "Hit"
		audio = preload("res://sound/SFX/AxeBlock.ogg")
	$Audio.stream = audio
	$Audio.play()
	await set_anim(anim, true)
	Global.Controllable = true
	if Input.is_action_pressed("OVAttack"): attack()
	else:
		attacking = false
		set_anim()
		speed = walk_speed
		$Attack/CollisionShape2D.disabled = true
		$Attack/AttackPreview/CollisionShape2D.disabled = true

func check_before_attack():
	%Base.frame = 1
	$Attack.rotation = Global.get_direction().angle()
	for i in $Attack/AttackPreview.get_overlapping_bodies():
		if i is NPC or i is Follower:
			i.attacked()

func dramatic_attack_pause():
	while not Global.Controllable:
		Global.Controllable = false
		BodyState = CUSTOM
		#print(attacking)
		if attacking:
			set_anim("Attack" + Global.get_dir_name())
			pause_anim()
			var timer = get_tree().create_timer(3)
			while timer.time_left > 0:
				used_sprite = %Base
				hide_other_sprites()
				%Base.animation = "Attack" + Global.get_dir_name()
				%Base.frame = 1
				await Event.wait()
			set_anim()
		else:
			set_anim("Dash" + Global.get_dir_name() + "Hit")
			pause_anim()
		await Event.wait()

func _on_open_menu_pressed() -> void:
	if Global.Controllable:
		PartyUI.main_menu()

func remove_light(node:Node2D = $Sprite):
	for i in node.get_children():
		i.light_mask = 0
		remove_light(i)

func pause_anim(node:Node2D = $Sprite):
	for i in node.get_children():
		if i is AnimatedSprite2D:
			i.pause()
			pause_anim(i)

func flip_sprites(node: Node2D) -> void:
	for i in node.get_children():
		if i is Sprite2D: i.flip_h = true
		if i.get_child_count() != 0: flip_sprites(i)

#func _input(event: InputEvent) -> void:
	#if Input.is_key_pressed(KEY_W):
		#set_anim("IdleUp")
		#direction = Vector2.UP
	#if Input.is_key_pressed(KEY_D):
		#set_anim("IdleRight")
		#direction = Vector2.RIGHT
	#if Input.is_key_pressed(KEY_A):
		#set_anim("IdleLeft")
		#direction = Vector2.LEFT
	#if Input.is_key_pressed(KEY_S):
		#set_anim("IdleDown")
		#direction = Vector2.DOWN
