extends CharacterBody2D

var speed = 60
var direction : Vector2
var oposite : Vector2
var realvelocity: Vector2
var moving: bool

@export var member : int
@export var player : Node2D
@export var party : PartyData
@export var distance : int
@onready var nav_agent := $NavigationAgent2D as NavigationAgent2D

func _ready():
	oposite = (Global.get_direction() * Vector2(-1,-1)) * 150
	$AnimatedSprite2D.play("Idle"+Global.get_dir_name())
	velocity = oposite
	move_and_slide()

func _physics_process(_delta: float) -> void:
	if player==null:
		OS.alert("WRONG SCENE IDIOT, THIS IS THE FOLLOWER SCENE!", "YOU STUPID")
		get_tree().change_scene_to_file("res://scenes/Rooms/Debug.tscn")
	if party.check_member(member):
		show()
		var oldposition=global_position
		#speed = nav_agent.distance_to_target() * 4 - distance
		#print(speed)
		#print(nav_agent.distance_to_target())
		if Loader.chased or not Global.Controllable:
			$CollisionShape2D.disabled = true
		if nav_agent.distance_to_target() > 150:
				global_position = player.global_position
		if nav_agent.distance_to_target() > distance:
			$CollisionShape2D.disabled = false
			direction = to_local(nav_agent.get_next_path_position()).normalized()
			#print(direction)
			#if (player.realvelocity.x  * direction.x >= 0 and player.realvelocity.y * direction.y >= 0) or player.realvelocity != Vector2.ZERO:
			if nav_agent.is_target_reachable():
				move_and_slide()
			velocity = speed * direction
			speed = max(30, player.realvelocity.length())
			if Loader.chased:
				$CollisionShape2D.disabled = true
			else: 
				$CollisionShape2D.disabled = false
		elif nav_agent.distance_to_target() < 20:
			if player.direction != Vector2.ZERO:
				#speed = 80
				animate()
				#print(oposite)
				oposite = (Global.get_direction() * Vector2(-1,-1)) * 150
			velocity = oposite
			realvelocity = player.direction
			$CollisionShape2D.disabled = true
			move_and_slide()
		if global_position.x-oldposition.x != 0 and global_position.y-oldposition.y != 0:
			realvelocity=global_position-oldposition
			moving =true
		else:
			moving =false
		
		makepath()
		
		
	else:
		hide()
		$CollisionShape2D.disabled = true

func makepath() -> void:
	nav_agent.set_target_position(player.global_position)
	

func animate():
	if $AnimatedSprite2D.sprite_frames != member_info().OV:
		$AnimatedSprite2D.sprite_frames = member_info().OV
	if realvelocity.x == realvelocity.y:
		pass
	elif not moving:
		position = round(position)
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
	if party.check_member(member):
		animate()
	
func member_info():
	if member == 1:
		return party.Member1
	
