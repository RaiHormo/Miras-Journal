extends NPC
class_name Follower

var oposite : Vector2
var moving: bool
var target: Vector2
var dir: Vector2
var player_jumped:= false

@export var member : int
@export var distance : int = 30
#@onready var nav_agent = $NavigationAgent2D as NavigationAgent2D
@export var dont_follow := false:
	set(x):
		dont_follow = x
		if dont_follow and BodyState == CONTROLLED: BodyState = IDLE
		elif not dont_follow: BodyState = CONTROLLED
@export var offset := 0
var path: Path2D
var follow: PathFollow2D

func default():
	hide()
	await Event.wait()
	oposite = (Query.get_direction() * Vector2(-1,-1)) * 150
	set_anim("Idle"+Query.get_dir_name())
	velocity = oposite
	path = Global.Player.path
	follow = PathFollow2D.new()
	follow.name = name+"Path"
	path.add_child(follow)
	follow.cubic_interp = true
	await Event.wait(0.1)
	follow.progress = -distance
	position = follow.global_position
	BodyState = CONTROLLED

func default_id() -> String:
	return "F"+str(member)

func control_process() -> void:
	if not is_instance_valid(Global.Player): return
	move_and_slide()
	if dont_follow:
		direction = Vector2.ZERO
		moving = false
		#animate()
		BodyState = IDLE
		return
	if Global.Party.check_member(member) and not Loader.InBattle and is_instance_valid(follow):
		if sprite.sprite_frames.resource_path != member_info().OV:
			sprite.sprite_frames = await member_info().get_OV()
		add_collision_exception_with(Global.Player)
		for i in Global.Area.Followers:
			add_collision_exception_with(i)
		show()
		z_index = Global.Player.z_index
		collision_layer = Global.Player.collision_layer
		collision_mask = Global.Player.collision_mask
		$Glow.color = member_info().MainColor
		$Glow.energy = member_info().GlowDef/2
		var oldposition=global_position
		var player_dist = to_local(Global.Player.position).length()
		target = round((follow.global_position + Global.PlayerDir.rotated(PI/2)*offset))
		direction = to_local(target).normalized()
		if to_local(target).length() < 6: direction = Vector2.ZERO
		var path_dist = floor(path.curve.get_baked_length() - follow.progress)
		#if Loader.chased:
			#$CollisionShape2D.disabled = true
		if false:
			if player_dist > distance+80:
				jump_to_player()
				player_jumped = false
			elif player_dist < distance and Global.Player.move_frames/10 > distance:
				player_jumped = false
		else:
			follow.progress = round(lerpf(follow.progress, max(float(path.curve.get_baked_length() -distance), 0), 0.5))
			if player_dist > 180:
				jump_to_player()
			if player_dist < 12 and Global.Controllable:
				update_anim_prm()
				oposite = (Query.get_direction() * Vector2(-1,-1))
				velocity = oposite * 150
			#elif path_dist > distance:
				#$CollisionShape2D.disabled = true
		speed = max(50, Global.Player.speed*(to_local(target).length()/40))
		if floor(player_dist/5) < floor(distance/5):
			speed /= 2
		velocity = speed * direction
		if (global_position-oldposition).length() > 0.1:
			moving = true
			RealVelocity=global_position-oldposition
		else:
			moving =false
	else:
		hide()
		#$CollisionShape2D.disabled = true

#func makepath() -> void:
	#target = Global.Player.position + (Global.PlayerDir.rotated(PI/2)*offset)
	#nav_agent.set_target_position(target)
	#if not nav_agent.is_target_reachable():
		#nav_agent.set_target_position(Global.Player.position)


#func update_anim_prm() -> void:
	#if not Query.check_member(member): return
	#if sprite.sprite_frames.resource_path != member_info().OV:
		#sprite.sprite_frames = await member_info().get_OV()
	#if sprite.animation != "default":
		#if member_info().Shadow:
			#sprite.get_node("Shadow").position.y = sprite.sprite_frames.get_frame_texture(sprite.animation, 0).get_size().y - 32 - member_info().ShadowOffset
			##print(sprite/Shadow.position.y)
			#sprite.get_node("Shadow").show()
		#else: sprite.get_node("Shadow").hide()
	#if RealVelocity.x == RealVelocity.y:
		#pass
	#elif not moving:
		#if Global.Player.move_frames < randi_range(-100, -2000):
			#dir = Query.get_direction(to_local(Global.Player.position))
		#if RealVelocity.length() == 0:
			#position = round(position)
		#if dir == Vector2.RIGHT:
			#sprite.play("IdleRight")
		#elif dir == Vector2.LEFT:
			#sprite.play("IdleLeft")
		#elif dir == Vector2.UP:
			#sprite.play("IdleUp")
		#elif dir == Vector2.DOWN:
			#sprite.play("IdleDown")
	#else:
		#dir = Query.get_direction(RealVelocity)
		#if dir == Vector2.RIGHT:
			#sprite.play("WalkRight")
		#elif dir == Vector2.LEFT:
			#sprite.play("WalkLeft")
		#elif dir == Vector2.UP:
			#sprite.play("WalkUp")
		#elif dir == Vector2.DOWN:
			#sprite.play("WalkDown")

func jump_to_player(speed = 2):
	if not is_instance_valid(Global.Player): return
	if Global.Player.dashing: return
	var prev_pos = position
	var new_pos = Global.Player.position
	#new_pos.x += offset
	#if member == 3: new_pos.y -= 24
	#if speed > 0:
		#await Global.jump_to_global(self, new_pos, speed, 0.3)
	position = new_pos

func _on_timer_timeout():
	if Global.Party.check_member(member):
		update_anim_prm()

func member_info() -> Actor:
	return Global.Party.get_member(member)

func attacked():
	Global.jump_to(self, position-Vector2(Query.get_direction()*24), 5, 0.5)
