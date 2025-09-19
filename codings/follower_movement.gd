extends CharacterBody2D
class_name Follower

var speed = 60
var direction : Vector2
var oposite : Vector2
var RealVelocity: Vector2
var moving: bool
var target: Vector2
var player_jumped:= false

@export var member : int
@export var distance : int = 30
#@onready var nav_agent = $NavigationAgent2D as NavigationAgent2D
@export var dont_follow := false:
	set(x):
		dont_follow = x
@export var offset := 0
var path: Path2D
var follow: PathFollow2D

func _ready():
	hide()
	await Event.wait()
	oposite = (Global.get_direction() * Vector2(-1,-1)) * 150
	$AnimatedSprite2D.play("Idle"+Global.get_dir_name())
	velocity = oposite
	path = Global.Player.path
	follow = PathFollow2D.new()
	follow.name = name+"Path"
	path.add_child(follow)
	follow.cubic_interp = true
	await Event.wait(0.1)
	follow.progress = -distance
	position = follow.global_position

func _physics_process(_delta: float) -> void:
	if not is_instance_valid(Global.Player): return
	if dont_follow:
		direction = Vector2.ZERO
		moving = false
		animate()
		return
	if Global.Party.check_member(member) and not Loader.InBattle and is_instance_valid(follow):
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
		target = (follow.global_position + Global.PlayerDir.rotated(PI/2)*offset).floor()
		direction = to_local(target).normalized()
		if to_local(target).length() < 5: direction = Vector2.ZERO
		var path_dist = floor(path.curve.get_baked_length() - follow.progress)
		#if Loader.chased:
			#$CollisionShape2D.disabled = true
		if false:
			if player_dist > distance+80:
				jump_to_player()
				player_jumped = false
			elif player_dist < distance:
				player_jumped = false
		else:
			follow.progress = round(lerpf(follow.progress, max(float(path.curve.get_baked_length() -distance), 0), 0.5))
			if player_dist > 180:
				jump_to_player()
			if player_dist < 12 and Global.Controllable:
				animate()
				oposite = (Global.get_direction() * Vector2(-1,-1))
				velocity = oposite * 150
			#elif path_dist > distance:
				#$CollisionShape2D.disabled = true
		speed = max(50, Global.Player.speed*to_local(target).length()/20)
		velocity = speed * direction
		move_and_slide()
		if (global_position-oldposition).length() > 0.3:
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


func animate():
	if not Global.check_member(member): return
	if $AnimatedSprite2D.sprite_frames.resource_path != member_info().OV:
		$AnimatedSprite2D.sprite_frames = await member_info().get_OV()
	if $AnimatedSprite2D.animation != "default":
		if member_info().Shadow:
			$AnimatedSprite2D/Shadow.position.y = $AnimatedSprite2D.sprite_frames.get_frame_texture($AnimatedSprite2D.animation, 0).get_size().y - 32 - member_info().ShadowOffset
			#print($AnimatedSprite2D/Shadow.position.y)
			$AnimatedSprite2D/Shadow.show()
		else: $AnimatedSprite2D/Shadow.hide()
	if RealVelocity.x == RealVelocity.y:
		pass
	elif not moving:
		var dir = Global.get_direction(RealVelocity)
		position = round(position)
		if dir == Vector2.RIGHT:
			$AnimatedSprite2D.play("IdleRight")
		elif dir == Vector2.LEFT:
			$AnimatedSprite2D.play("IdleLeft")
		elif dir == Vector2.UP:
			$AnimatedSprite2D.play("IdleUp")
		elif dir == Vector2.DOWN:
			$AnimatedSprite2D.play("IdleDown")
	else:
		var dir = Global.get_direction(RealVelocity)
		if dir == Vector2.RIGHT:
			$AnimatedSprite2D.play("WalkRight")
		elif dir == Vector2.LEFT:
			$AnimatedSprite2D.play("WalkLeft")
		elif dir == Vector2.UP:
			$AnimatedSprite2D.play("WalkUp")
		elif dir == Vector2.DOWN:
			$AnimatedSprite2D.play("WalkDown")

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
		animate()

func member_info() -> Actor:
	return Global.Party.get_member(member)

func attacked():
	Global.jump_to(self, position-Vector2(Global.get_direction()*24), 5, 0.5)
