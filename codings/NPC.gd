extends CharacterBody2D
class_name NPC

@export var speed = 75
@export var direction : Vector2 = Vector2.ZERO
@export var Facing: Vector2
var OverwritePrm = false
var RealVelocity = Vector2.ZERO
@export var ID: String

func _ready():
	Event.add_char(self)
	default()

func default():
	pass

func process_move():
	if not OverwritePrm:
		#print(direction)
		var OldPosition = global_position
		velocity = direction * speed
		move_and_slide()
		update_anim_prm()
		RealVelocity = global_position - OldPosition
		if direction != Vector2.ZERO:
			$DirectionMarker.global_position=global_position +direction*10
			$DirectionMarker.rotation = direction.angle()
		if direction!=Vector2.ZERO:
			Facing = Global.get_direction(direction)

func update_anim_prm():
	if abs(RealVelocity.length())>2:
		$Sprite.play(str("Walk"+Global.get_dir_name(Facing)))
	else:
		$Sprite.play(str("Idle"+Global.get_dir_name(Facing)))

func move_dir(dir:Vector2):
	OverwritePrm = false
	direction = dir
	process_move()

func go_to(pos:Vector2):
	$Nav




