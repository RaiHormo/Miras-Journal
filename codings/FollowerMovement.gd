extends CharacterBody2D
class_name Follower

var speed = 60
var direction : Vector2
var oposite : Vector2
var realvelocity: Vector2
var moving: bool

@export var member : int
@export var distance : int
@onready var nav_agent := $NavigationAgent2D as NavigationAgent2D

func _ready():
	Global.Follower[member] = self
	await Event.wait()
	distance = 20*member
	oposite = (Global.get_direction() * Vector2(-1,-1)) * 150
	$AnimatedSprite2D.play("Idle"+Global.get_dir_name())
	velocity = oposite
	move_and_slide()

func _physics_process(_delta: float) -> void:
	if Global.Player==null: return
	if Global.Party.check_member(member):
		show()
		z_index = Global.Player.z_index
		collision_layer = Global.Player.collision_layer
		collision_mask = Global.Player.collision_mask
		var oldposition=global_position
		#print(nav_agent.distance_to_target()," ", distance)
		if Loader.chased:
			$CollisionShape2D.disabled = true
		if nav_agent.distance_to_target() > 150:
				global_position = Global.Player.global_position
		if round(nav_agent.distance_to_target()) > distance:
			$CollisionShape2D.disabled = false
			direction = to_local(nav_agent.get_next_path_position()).normalized()
			if nav_agent.is_target_reachable():
				move_and_slide()
			velocity = speed * direction
			speed = max(30, Global.Player.realvelocity.length())
			if Loader.chased:
				$CollisionShape2D.disabled = true
			else:
				$CollisionShape2D.disabled = false
		elif nav_agent.distance_to_target() < 20:
			add_collision_exception_with(Global.Player)
			animate()
			oposite = (Global.get_direction() * Vector2(-1,-1)) * 150
			velocity = oposite
			realvelocity = Global.Player.direction
			move_and_slide()
		#if realvelocity == Vector2.ZERO:
			#position = round(position)
		#print((global_position-oldposition).length())
		if (global_position-oldposition).length() > 0.5:
			moving =true
			realvelocity=global_position-oldposition
		else:
			moving =false

		makepath()


	else:
		hide()
		$CollisionShape2D.disabled = true

func makepath() -> void:
	nav_agent.set_target_position(Global.Player.global_position)


func animate():
	if $AnimatedSprite2D.sprite_frames != member_info().OV:
		$AnimatedSprite2D.sprite_frames = member_info().OV
	if realvelocity.x == realvelocity.y:
		pass
	elif not moving:
		var dir = Global.get_direction(realvelocity)
		if dir == Vector2.RIGHT:
			$AnimatedSprite2D.play("IdleRight")
		elif dir == Vector2.LEFT:
			$AnimatedSprite2D.play("IdleLeft")
		elif dir == Vector2.UP:
			$AnimatedSprite2D.play("IdleUp")
		elif dir == Vector2.DOWN:
			$AnimatedSprite2D.play("IdleDown")
	else:
		var dir = Global.get_direction(realvelocity)
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
