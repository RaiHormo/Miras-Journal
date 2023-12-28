extends NPC
class_name Mira
##The script that handles's Mira's movment

##The parent of the parent node should always be a Global.Tilemap
#@onready var Global.Tilemap:TileMap = Global.Tilemap
##Whether the dash is active
var dashing := false
var realvelocity : Vector2 = Vector2.ZERO
##When the player is supposed to be in a midair perspective
var midair := false
##true is there is a wall in front of the player
var undashable := false
##Direction of the dash
var dashdir: Vector2 = Vector2.ZERO
##Use flame to light up the enviroment
@export var can_dash = true
const dash_speed := 200


func _ready() -> void:
	ID = "P"
	speed = 75
	Event.add_char(self)
	Item.pickup.connect(_on_pickup)
	await Event.wait()
	if Global.Tilemap == null:
		OS.alert("THIS IS THE PLAYER SCENE", "WRONG SCENE IDIOT")
		Loader.travel_to("Debug")
		queue_free()
		return
	Global.check_party.connect(_check_party)
	Loader.InBattle = false
	Global.Player = self
	Global.Follower[0] = self
	var cam :Camera2D = Global.get_cam()
	if cam !=null:
		for i in Global.Area.get_children():
			if "Camera" in i.name: i.enabled = false
		$Camera2D.remote_path = cam.get_path()
		cam.enabled = true
	set_anim(str("Idle"+Global.get_dir_name(Global.get_direction())))
	$Attack/CollisionShape2D.disabled = true
	$Attack/AttackPreview/CollisionShape2D.disabled = true


func extended_process() -> void:
	if Global.Controllable:
		#update_anim_prm()
		BodyState = CONTROLLED
		call_deferred("_check_party")
		check_flame()
	if midair:
		pass
	if direction != Vector2.ZERO: Global.PlayerDir = direction

func control_process():
	if Global.Tilemap != null: coords = Global.Tilemap.local_to_map(global_position)
#	if Global.device == "Keyboard" or is_zero_approx(Input.get_joy_axis(-1,JOY_AXIS_LEFT_X)):
	direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down", 0.4)
#	else:
#		direction = (Input.get_vector("MoveLeft", "MoveRight", "MoveUp", "MoveDown")*2).limit_length()
	undashable = false
	if is_on_wall():
		if round(get_wall_normal())*-1 == Global.get_direction(direction):
			undashable = true
	if Global.Controllable:
		if "Dash" in %Base.animation and not dashing:
			#print(1)
			stop_dash()
		if Input.is_action_pressed("Dash") and Global.get_direction(direction)!= dashdir*Vector2(-1,-1) and direction!=Vector2.ZERO and can_dash:
			if not dashing:
				if undashable:
#					Global.Controllable = false
					reset_speed()
					#position = round(position)
					set_anim("Deny"+Global.get_dir_name(Global.PlayerDir))
					await %Base.animation_finished
					set_anim("Idle"+Global.get_dir_name(Global.PlayerDir))
					return
				else:
					dashdir = Global.get_direction(direction)
					dashing = true
					Global.Controllable=false
					speed = dash_speed
					BodyState = CUSTOM
					reset_speed()
					set_anim("Dash"+Global.get_dir_name(direction)+"Start")
					while %Base.is_playing() and %Base.animation == "Dash"+Global.get_dir_name(dashdir)+"Start":
						velocity = dashdir * speed
						if is_on_wall(): Global.Controllable=true; set_anim("Idle"+Global.get_dir_name()); return
						await Event.wait()
					#Global.jump_to_global(self, global_position+Global.get_direction(direction)*20, 3, 0)
					if BodyState == CUSTOM:
						Global.Controllable=true
			elif Global.get_direction(direction) != dashdir:
				#print(2)
				stop_dash()
		elif dashing:
			#print(3)
			stop_dash()
		if direction != Vector2.ZERO:
			Global.PlayerDir = direction
			Global.PlayerPos = global_position
		if direction != Vector2.ZERO:
			$DirectionMarker.global_position=global_position +direction*10
		if dashing:
			velocity = ((dashdir+direction).normalized() * speed)
		else:
			velocity = direction * speed
		var old_position = global_position
		if direction.length()>0.1:
			move_and_slide()
			realvelocity = get_real_velocity()
		else:
			realvelocity = (global_position - old_position)/ get_physics_process_delta_time()
			position = round(position)
		if Input.is_action_just_pressed("DebugF"):
			Global.toast("Collision set to " + str($CollisionShape2D.disabled))
			$CollisionShape2D.disabled = Global.toggle($CollisionShape2D.disabled)
		#check_for_jumps()
		if Input.is_action_just_pressed("DebugD"):
			#print(Global.Tilemap)
			#print(Global.Tilemap.local_to_map(global_position))
			for i in Global.Tilemap.get_layers_count():
				if Global.Tilemap.get_cell_tile_data(i, coords) != null:
					check_terrain(Global.Tilemap.get_cell_tile_data(i, coords).get_custom_data("TerrainType"))
		if Input.is_action_just_pressed("OVAttack"):
			attack()


func update_anim_prm() -> void:
	if Footsteps: handle_step_sounds(%Base)
	if BodyState == CUSTOM: return
	if BodyState == CONTROLLED:
		if abs(realvelocity.length())>10 and Global.Controllable:
			move_frames+=1
			if dashing:
				reset_speed()
				set_anim("Dash"+Global.get_dir_name(dashdir)+"Loop")
			else:
				speed = 75
				set_anim(str("Walk"+Global.get_dir_name()))
				%Base.speed_scale=(realvelocity.length()/70)
				%Base/Bag.speed_scale=(realvelocity.length()/70)
				%Base/Bag/Axe.speed_scale=(realvelocity.length()/70)
		elif Global.Controllable and ("Walk" in %Base.animation or ("Dash" in %Base.animation and dashdir == Vector2.ZERO)):
			move_frames=0
			set_anim(str("Idle"+Global.get_dir_name()))
		if direction.length()>realvelocity.length() and dashing:
					move_frames = 0
					#print(4)
					stop_dash()
	else:
		if get_real_velocity().length() >30:
			BodyState = MOVE
			if dashing:
				set_anim("Dash"+Global.get_dir_name(dashdir)+"Stop")
			else:
				set_anim(str("Walk"+Global.get_dir_name(Facing)))
		else:
			BodyState = IDLE
			if realvelocity == Vector2.ZERO:
				position = round(position)
			set_anim(str("Idle"+Global.get_dir_name(Facing)))

func look_to(dir:Vector2) -> void:
	set_anim("Idle"+Global.get_dir_name(dir))

##Item pickup animation
func _on_pickup() -> void:
	Global.Controllable = false
	reset_speed()
	if Global.get_direction() == Vector2.LEFT: set_anim("PickUpLeft")
	else: set_anim("PickUpRight")
	await %Base.animation_looped
	Global.Controllable = true
	set_anim(str("Idle"+Global.get_dir_name(Global.get_direction(Global.PlayerDir))))

func _check_party() -> void:
	if Event.check_flag(&"FlameActive"):
		%Base.sprite_frames = preload("res://art/OV/Mira/MiraOVFlame.tres")
	elif Global.Party.Leader != null:
		%Base.sprite_frames =  Global.Party.Leader.OV
	if Item.check_item("LightweightAxe", "Key"):
		%Base/Bag/Axe.show()
	else:
		%Base/Bag/Axe.hide()

##Sets the animation for all sprite layers
func set_anim(anim:String = "Idle"+Global.get_dir_name()) -> void:
	if anim not in %Base.sprite_frames.get_animation_names(): return
	%Base.play(anim)
	if anim in %Base/Bag.sprite_frames.get_animation_names() and Item.HasBag:
		%Base/Bag.show()
		%Base/Bag.play(anim)
	else: %Base/Bag.hide()
	if anim in %Base/Flame.sprite_frames.get_animation_names() and Event.check_flag(&"FlameActive"):
		%Base/Flame.show()
		%Base/Flame.play(anim)
	else: %Base/Flame.hide()
	if %Base.is_playing(): await %Base.animation_finished

func activate_flame(animate:=true) -> void:
	Event.add_flag(&"FlameActive")
	_check_party()
	await Event.wait()
	check_flame()
	if animate:
		set_anim("FlameActive")
		await Event.wait(0.75)
		set_anim("IdleRight")
	%Base/Flame.show()

func check_flame() -> void:
	if Event.check_flag(&"FlameActive"):
		if $Flame.energy == 0:
			activate_flame(false)
			while $Flame.energy < 1.5:
				$Flame.energy += 0.03
				await Event.wait()
			$Flame.energy = 1.5
			$Flame.flicker = true
	else:
		$Flame.flicker = false
		$Flame.energy = 0

##For opening the menu
func bag_anim() -> void:
	set_anim("OpenBag")
	await %Base.animation_looped
	set_anim("BagIdle")

##If the player dashes into a gap she will jump
func check_for_jumps() -> void:
	if dashing and check_terrain("Gap"):
		if Global.get_direction(Global.Tilemap.get_cell_tile_data(1, Global.Tilemap.local_to_map(global_position)).get_custom_data("JumpDistance")) == Global.get_direction(realvelocity):
			reset_speed()
			set_anim("Dash"+Global.get_dir_name(direction)+"Loop")
			midair = true
			Global.Controllable = false
			$CollisionShape2D.disabled = true
			z_index+=2
			var jump = Global.Tilemap.get_cell_tile_data(1, Global.Tilemap.local_to_map(global_position)).get_custom_data("JumpDistance")
			#print(jump, "  ", coords)
			Global.jump_to_global(self, Global.Tilemap.map_to_local(coords) + jump*24, 5, 0.5)
			await Global.anim_done
			Global.Controllable = true
			z_index-=2
			$CollisionShape2D.disabled = false
			midair=false

##Handles the animation when the dash is stopped, either doing the slide or hit one depending on the wall in front of her
func stop_dash() -> void:
	if BodyState!=CONTROLLED or "Stop" in %Base.animation or "Hit" in %Base.animation or midair: return
	dashing = false
	speed = 75
	#print(realvelocity)
	reset_speed()
	var slide = true
	for i in Global.Tilemap.get_layers_count():
		if ((Global.Tilemap.get_cell_tile_data(i, coords+dashdir*2)!= null and Global.Tilemap.get_cell_tile_data(i, coords+dashdir*2).get_collision_polygons_count(0)>0) or
			Global.Tilemap.get_cell_tile_data(i, coords)!= null and Global.Tilemap.get_cell_tile_data(i, coords).get_collision_polygons_count(0)>0):
			slide = false
	if undashable and Global.get_direction()==dashdir and not check_terrain("Gap"):
		await bump()
	else:
		set_anim("Dash"+Global.get_dir_name(dashdir)+"Stop")
		Global.Controllable=false
		if Input.is_action_pressed("Dash") and Global.get_direction(direction) != dashdir and direction!=Vector2.ZERO:
			await get_tree().create_timer(0.1).timeout
		else:
			BodyState = CUSTOM
			speed = 75
			while %Base.is_playing() and %Base.animation == "Dash"+Global.get_dir_name(dashdir)+"Stop":
				velocity = dashdir * speed
				speed = max(0, speed - 2)
				await Event.wait()
		Global.Controllable=true
		BodyState = CONTROLLED
		speed = 75
		velocity = Vector2.ZERO
	dashdir = Vector2.ZERO
	if "Stop" in %Base.animation or "Hit" in %Base.animation:
		set_anim(str("Idle"+Global.get_dir_name()))

func reset_speed() -> void:
	%Base.speed_scale=1
	%Base/Bag.speed_scale=1
	%Base/Bag/Axe.speed_scale=1

func bump() -> void:
	Global.jump_to_global(self, global_position - dashdir*15, 15, 0.5)
	set_anim("Dash"+Global.get_dir_name(dashdir)+"Hit")
	Global.Controllable=false
	await %Base.animation_finished
	Global.Controllable=true

func camera_follow(follow := Global.toggle($Camera2D.update_position)) -> void:
	$Camera2D.update_position = follow

func attack():
	reset_speed()
	Global.Controllable = false
	$Attack/AttackPreview.collision_layer = collision_layer
	$Attack/AttackPreview/CollisionShape2D.disabled = false
	var checked := false
	await Event.wait()
	check_before_attack()
	$Attack.rotation = Global.get_direction().angle()
	await set_anim("Attack"+Global.get_dir_name()+"Windup")
	while Input.is_action_pressed("OVAttack") or not checked:
		direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down", 0.4)
		if direction != Vector2.ZERO: Global.PlayerDir = direction
		set_anim("Attack"+Global.get_dir_name()+"Windup")
		check_before_attack()
		checked = true
		await get_tree().physics_frame
	$Attack/CollisionShape2D.disabled = false
	var hits = false
	await get_tree().physics_frame
	await get_tree().physics_frame
	for i in $Attack.get_overlapping_bodies():
		print(i)
		if not (i is NPC or i is Follower or i is Mira):
			hits = true
	#print("pt1: " + str(hits))
	for i in $Attack.get_overlapping_bodies():
		print(i)
		if (i is NPC or i is Follower) and not i is Mira:
			hits = false
	#print("pt2: " + str(hits))
	var audio = preload("res://sound/SFX/Etc/Swing.ogg")
	var anim = "Attack" + Global.get_dir_name()
	if hits:
		anim = "Attack" + Global.get_dir_name() + "Hit"
		audio = preload("res://sound/SFX/Etc/AxeBlock.ogg")
	$Audio.stream = audio
	$Audio.play()
	await set_anim(anim)
	Global.Controllable = true
	if Input.is_action_pressed("OVAttack"): attack()
	else:
		set_anim()
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
		if %Base.animation == "Attack"+Global.get_dir_name():
			%Base.pause()
			#Loader.flash_attacker()
			return
		else: await Event.wait()
