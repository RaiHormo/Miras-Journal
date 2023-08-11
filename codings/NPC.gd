extends CharacterBody2D
class_name NPC

@export var speed = 75
@export var direction : Vector2 = Vector2.ZERO
@export var Facing: Vector2
var OverwritePrm = false
var RealVelocity = Vector2.ZERO

func process_move():
	if not OverwritePrm:
		var OldPosition = global_position
		velocity = direction * speed
		move_and_slide()
		update_anim_prm()
		RealVelocity = global_position - OldPosition
		if direction!=Vector2.ZERO:
			Facing = Global.get_direction(direction)

func update_anim_prm():
	if abs(RealVelocity.length())>2:
		$Sprite.play(str("Walk"+Global.get_dir_name(Facing)))
	else:
		$Sprite.play(str("Idle"+Global.get_dir_name(Facing)))

func move_dir(dir:Vector2, time:float=0.01):
	OverwritePrm = false
	direction = dir
	process_move()
#	await get_tree().create_timer(time).timeout
#	direction = Vector2.ZERO
