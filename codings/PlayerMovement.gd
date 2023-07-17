extends CharacterBody2D
class_name Mira

@onready var animation_tree : AnimationTree = $AnimationTree
signal nearest_changed


var nearestactionable = null
var speed = 75  # speed in pixels/sec
static var direction : Vector2 = Vector2.ZERO
var realvelocity : Vector2 = Vector2.ZERO

func _ready():
	animation_tree.active = true
	Item.pickup.connect(_on_pickup)
	Global.check_party.connect(_check_party)
	Loader.InBattle = false

func _process(delta):
	update_anim_prm()
	_check_party()

func _physics_process(delta):
	if Global.Controllable:
		direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
		if direction != Vector2.ZERO:
			Global.PlayerDir = direction
			Global.PlayerPos = global_position
		if direction != Vector2.ZERO:
			$DirectionMarker.global_position=global_position +direction*10
		velocity = direction * speed
		var old_position = position
		if direction.x > 0.1 or direction.x < -0.1  or direction.y > 0.1 or direction.y < -0.1:
			move_and_slide()
		realvelocity = (position - old_position) / delta
	
	#var vec : Vector2 = 
	#print(vec)


func update_anim_prm():
	if realvelocity.x > 2 or realvelocity.x < -2  or realvelocity.y > 2 or realvelocity.y < -2 and Global.Controllable:
		
		
		animation_tree["parameters/conditions/playerNotMoving"] = false
		animation_tree["parameters/conditions/playerIsMoving"] = true
		$AnimationTree.set("parameters/BlendTree/TimeScale/scale", realvelocity.length()/50)
		animation_tree["parameters/Idle/blend_position"] = direction
		animation_tree["parameters/BlendTree/BlendSpace2D/blend_position"] = direction
		

	else:
		animation_tree["parameters/conditions/playerNotMoving"] = true
		animation_tree["parameters/conditions/playerIsMoving"] = false

#func check_interactable():
#	var areas: Array[Area2D] = $DirectionMarker/Finder.get_overlapping_areas()
#	var shortestdist: float=INF
#	var secondshortest: Interactable = null
#	for area in areas:
#		var distance :float = area.global_position.distance_to(global_position)
#		if distance < shortestdist:
#			shortestdist = distance
#			secondshortest = area
#	if secondshortest != nearestactionable or not is_instance_valid(secondshortest):
#		nearestactionable = secondshortest
#		emit_signal("nearest_changed",nearestactionable)

func _on_pickup():
	var temp = $Base/Bag.visible
	$Base/Bag.visible = false
	Global.Controllable = false
	$AnimationTree["parameters/Pickup/blend_position"] = Global.PlayerDir.x
	$AnimationTree["parameters/conditions/pickup"] = true
	await $AnimationTree.animation_finished
	Global.Controllable = true
	$Base/Bag.visible = temp
	$AnimationTree["parameters/conditions/pickup"] = false

func _check_party():

	if Item.check_key("LightweightAxe"):
		$Base/Bag/Axe.show()
	else:
		$Base/Bag/Axe.hide()
