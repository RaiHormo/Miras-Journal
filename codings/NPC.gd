extends CharacterBody2D
class_name NPC

@export var speed = 75
@export var direction : Vector2 = Vector2.ZERO
@export var Facing: Vector2
var OverwritePrm = false
var RealVelocity = Vector2.ZERO
var coords:Vector2 = Vector2.ZERO
@export var ID: String
@export var DefaultPos = Vector2.ZERO
var stopping=false

func _ready():
	if self.get_path() in Loader.Defeated: queue_free()
	process_mode = Node.PROCESS_MODE_PAUSABLE
	DefaultPos = Global.Tilemap.local_to_map(global_position)
	Event.add_char(self)
	default()

func default():
	pass

func process_move():
	if self.get_path() in Loader.Defeated: queue_free()
	coords = Global.Tilemap.local_to_map(global_position)
	if not OverwritePrm and speed != null:
		#print(direction)
		var OldPosition = global_position
		velocity = direction * speed
		move_and_slide()
		update_anim_prm()
		RealVelocity = global_position - OldPosition
		if direction != Vector2.ZERO:
			$DirectionMarker.global_position=global_position +direction*10
			$DirectionMarker.rotation = direction.angle()
			Facing = Global.get_direction(direction)

func update_anim_prm():
	if RealVelocity.normalized().length()*10 > 10 :
		return
	if abs(RealVelocity.length())>2:
		$Sprite.play(str("Walk"+Global.get_dir_name(Facing)))
	else:
		$Sprite.play(str("Idle"+Global.get_dir_name(Facing)))

func move_dir(dir:Vector2):
	if get_tree().paused:
		return
	OverwritePrm = false
	direction = dir
	process_move()

func move_to(pos:Vector2):
	if get_tree().paused:
		return
	$Nav.set_target_position(Global.Tilemap.map_to_local(pos))
	direction = to_local($Nav.get_next_path_position()).normalized()
	process_move()

func go_to(pos:Vector2):
	OverwritePrm = false
	#print(Global.Tilemap.map_to_local(pos))
	$Nav.set_target_position(Global.Tilemap.map_to_local(pos))
	while not $Nav.is_target_reached():
		direction = to_local($Nav.get_next_path_position()).normalized()
		process_move()
		await Event.wait()
		if round(RealVelocity.length()*10)== 0 or stopping or get_tree().paused:
			return

func stop_going():
	stopping = true
	await Event.wait(1)
	stopping = false

func defeat():
	Loader.Defeated.append(self.get_path())
	queue_free()
