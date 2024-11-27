extends CharacterBody2D
class_name Follower

var speed = 60
var direction : Vector2
var oposite : Vector2
var RealVelocity: Vector2
var moving: bool

@export var member : int
@export var distance : int = 30
@onready var nav_agent := $NavigationAgent2D as NavigationAgent2D
@export var dont_follow := false

func _ready():
	Global.Follower[member] = self
	await Event.wait()
	oposite = (Global.get_direction() * Vector2(-1,-1)) * 150
	$AnimatedSprite2D.play("Idle"+Global.get_dir_name())
	velocity = oposite
	move_and_slide()

func _physics_process(_delta: float) -> void:
	if not is_instance_valid(Global.Player): return
	if dont_follow:
		direction = Vector2.ZERO
		moving = false
		animate()
		return
	if Global.Party.check_member(member) and not Loader.InBattle:
		show()
		z_index = Global.Player.z_index
		collision_layer = Global.Player.collision_layer
		collision_mask = Global.Player.collision_mask
		var oldposition=global_position
		#print(nav_agent.distance_to_target()," ", distance)
		if Loader.chased:
			$CollisionShape2D.disabled = true
		if to_local(Global.Player.position).length() > 150:
				global_position = Global.Player.global_position
		if to_local(Global.Player.position).length() > distance:
			#$CollisionShape2D.disabled = false
			if nav_agent.is_target_reachable():
				direction = to_local(nav_agent.get_next_path_position()).normalized()
				$CollisionShape2D.disabled = false
			else: 
				direction = to_local(Global.Player.global_position).normalized()
				$CollisionShape2D.disabled = true
			move_and_slide()
			velocity = speed * direction
			speed = max(30, Global.Player.RealVelocity.length())
			if Loader.chased:
				$CollisionShape2D.disabled = true
		elif to_local(Global.Player.position).length() < 18 and Global.Controllable:
			add_collision_exception_with(Global.Player)
			animate()
			oposite = (Global.get_direction() * Vector2(-1,-1)) * 150
			velocity = oposite
			RealVelocity = Global.Player.direction
			move_and_slide()
		if (global_position-oldposition).length() > 0.3:
			moving =true
			RealVelocity=global_position-oldposition
		else:
			moving =false
		makepath()
	else:
		hide()
		$CollisionShape2D.disabled = true

func makepath() -> void:
	nav_agent.set_target_position(Global.Player.global_position)


func animate():
	if not Global.check_member(member): return
	if $AnimatedSprite2D.sprite_frames != member_info().OV:
		$AnimatedSprite2D.sprite_frames = member_info().OV
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


func _on_timer_timeout():
	if Global.Party.check_member(member):
		animate()

func member_info() -> Actor:
	return Global.Party.get_member(member)

func attacked():
	Global.jump_to(self, position-Vector2(Global.get_direction()*24), 5, 0.5)
