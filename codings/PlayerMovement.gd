extends NPC
class_name Mira

signal nearest_changed
@onready var tilemap:TileMap =get_node_or_null(get_path_to(get_parent().get_parent()))
var dashing = false
var nearestactionable = null
var realvelocity : Vector2 = Vector2.ZERO
var move_frames =0
var midair = false
var undashable = false
var dashdir:Vector2= Vector2.ZERO

func _ready():
	ID = "P"
	speed = 75
	Event.add_char(self)
	#animation_tree.active = true
	#speed = 75
	Item.pickup.connect(_on_pickup)
	Global.Tilemap = tilemap
	if tilemap == null:
		OS.alert("THIS IS THE PLAYER SCENE", "WRONG SCENE IDIOT")
		Loader.travel_to("Debug")
		return
	Global.check_party.connect(_check_party)
	Loader.InBattle = false
	Global.Player = self
	var cam :Camera2D = get_tree().root.get_node_or_null("Area/Camera"+str(Global.CameraInd))
	if cam !=null:
		for i in get_tree().root.get_node("Area").get_children(): 
			if "Camera" in i.name: i.enabled = false
		$Camera2D.remote_path = cam.get_path()
		cam.enabled = true

func _process(delta):
	if Global.Controllable:
		update_anim_prm()
	_check_party()

func _physics_process(delta):
	coords = tilemap.local_to_map(global_position)
	if OverwritePrm:
		direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	else:
		process_move()
	undashable = false
	if not dashing:
		dashdir = Global.get_direction(Global.PlayerDir)
	for i in tilemap.get_layers_count():
		if ((tilemap.get_cell_tile_data(i, coords+dashdir)!= null and tilemap.get_cell_tile_data(i, coords+dashdir).get_collision_polygons_count(0)>0) or 
			tilemap.get_cell_tile_data(i, coords)!= null and tilemap.get_cell_tile_data(i, coords).get_collision_polygons_count(0)>0):
			undashable=true
	#print(dashdir)
	if Global.Controllable:
		OverwritePrm=true
		if abs(realvelocity.length())>25 and Input.is_action_pressed("Dash") and Global.get_direction(direction)!= dashdir*Vector2(-1,-1) and direction!=Vector2.ZERO:
			if not dashing:
				if undashable:
					Global.Controllable = false
					reset_speed()
					set_anim("Deny"+Global.get_dir_name(Global.PlayerDir))
					await $Base.animation_finished
					set_anim("Idle"+Global.get_dir_name(Global.PlayerDir))
					while Global.get_direction(direction)==Global.get_direction(Global.PlayerDir) and Input.is_action_pressed("Dash"):
						await get_tree().create_timer(0.01).timeout
					Global.Controllable = true
				else:
					dashdir = Global.get_direction(direction)
					dashing = true
					Global.Controllable=false
					Global.jump_to(self, position+Global.get_direction(direction)*20, 3, 0)
					set_anim("Dash"+Global.get_dir_name(direction)+"Start")
					await Global.anim_done
					speed = 175
					Global.Controllable=true
			elif Global.get_direction(realvelocity) != dashdir:
				stop_dash()
				pass
		elif dashing:
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
		var old_position = position
		if direction.x > 0.1 or direction.x < -0.1  or direction.y > 0.1 or direction.y < -0.1:
			move_and_slide()
		realvelocity = (position - old_position) / delta
		if Input.is_action_just_pressed("DebugF"):
			$CollisionShape2D.disabled = Global.toggle($CollisionShape2D.disabled)
		check_for_jumps()
		if Input.is_action_just_pressed("DebugD"):
			#print(tilemap)
			#print(tilemap.local_to_map(global_position))
			for i in tilemap.get_layers_count():
				if tilemap.get_cell_tile_data(i, coords) != null:
					check_terrain(tilemap.get_cell_tile_data(i, coords).get_custom_data("TerrainType"))
	elif dashing and not Input.is_action_pressed("Dash"):
		stop_dash()


func update_anim_prm():
	if abs(realvelocity.length())>2 and Global.Controllable:
		move_frames+=1
		if dashing:
			reset_speed()
			set_anim("Dash"+Global.get_dir_name(dashdir)+"Loop")
		else:
			set_anim(str("Walk"+Global.get_dir_name(Global.get_direction(Global.PlayerDir))))
			$Base.speed_scale=(realvelocity.length()/75)
			$Base/Bag.speed_scale=(realvelocity.length()/75)
			$Base/Bag/Axe.speed_scale=(realvelocity.length()/75)
	else:
		if Global.Controllable:
			move_frames=0
			set_anim(str("Idle"+Global.get_dir_name(Global.get_direction(Global.PlayerDir))))
	if direction.length()>realvelocity.length() and dashing:
				move_frames = 0
				stop_dash()


func _on_pickup():
	Global.Controllable = false
	reset_speed()
	set_anim(str("PickUp"+Global.get_dir_name(Global.get_direction(Vector2(Global.PlayerDir.x, 0)))))
	await $Base.animation_looped
	Global.Controllable = true
	set_anim(str("Idle"+Global.get_dir_name(Global.get_direction(Global.PlayerDir))))

func _check_party():
	if Item.check_key("LightweightAxe"):
		$Base/Bag/Axe.show()
	else:
		$Base/Bag/Axe.hide()
		

func set_anim(anim:String):
	$Base.play(anim)
	$Base/Bag.play(anim)
	#$Base/Bag/Axe.play(anim)

func bag_anim():
	set_anim("OpenBag")
	await $Base.animation_looped
	set_anim("BagIdle")


func check_terrain(terrain:String):
	print(terrain)
	
func check_for_jumps():
	if dashing and tilemap.get_cell_tile_data(1, tilemap.local_to_map(global_position)) != null:
			if tilemap.get_cell_tile_data(1, tilemap.local_to_map(global_position)).get_custom_data("TerrainType") == "Gap":
				if Global.get_direction(tilemap.get_cell_tile_data(1, tilemap.local_to_map(global_position)).get_custom_data("JumpDistance")) == Global.get_direction(realvelocity):
					reset_speed()
					set_anim("Dash"+Global.get_dir_name(direction)+"Loop")
					midair = true
					Global.Controllable = false
					z_index+=2
					var jump = tilemap.get_cell_tile_data(1, tilemap.local_to_map(global_position)).get_custom_data("JumpDistance")
					#print(jump, "  ", coords)
					Global.jump_to(self, tilemap.map_to_local(coords) + Vector2(tilemap.map_to_local(jump).x, 0), 5, 0.5)
					await Global.anim_done
					Global.Controllable = true
					z_index-=2
					midair=false

func stop_dash():
	if midair:
		return
	dashing = false
	speed = 75
	reset_speed()
	if undashable and Global.get_direction(direction)==dashdir:
		Global.jump_to(self, position-dashdir*15, 20, 0.5)
		set_anim("Dash"+Global.get_dir_name(dashdir)+"Hit")
		Global.Controllable=false
		await $Base.animation_finished
		Global.Controllable=true
	else:
		#print(Global.PlayerDir)
		if not undashable:
			Global.jump_to(self, position+dashdir*15, 10, 0)
		set_anim("Dash"+Global.get_dir_name(dashdir)+"Stop")
		Global.Controllable=false
		if Input.is_action_pressed("Dash") and Global.get_direction(direction) != dashdir and direction!=Vector2.ZERO:
			await get_tree().create_timer(0.1).timeout
		else: await $Base.animation_finished
		Global.Controllable=true
	dashdir = Vector2.ZERO

func reset_speed():
	$Base.speed_scale=1
	$Base/Bag.speed_scale=1
	$Base/Bag/Axe.speed_scale=1
	
