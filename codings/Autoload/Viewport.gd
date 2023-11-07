extends SubViewportContainer
@onready var Resolution = $Screen.size
@onready var Screen = $Screen
@onready var WindowScale: float = (DisplayServer.window_get_size() / Resolution).x
@onready var real_cam_pos:Vector2 = $Camera.global_position
var cam_pos = Vector2.ZERO

func zoom(factor:float, time:float = 0.3):
	var t = create_tween()
	t.set_ease(Tween.EASE_IN_OUT)
	t.set_trans(Tween.TRANS_QUART)
	t.tween_property($Camera, "zoom", Vector2(factor*4, factor*4), time)

func _process(delta):
	if Global.get_cam() != null and Global.get_cam().zoom != Vector2.ONE:
		pass
		#scale = Global.get_cam().zoom
		#Global.get_cam().zoom = Vector2.ONE
	if Global.Player != null: $Camera.position = Global.Player.position + Global.Area.Size/2
#	real_cam_pos = lerp(real_cam_pos, cam_pos, delta*5)
#	var subpixel_pos = real_cam_pos - real_cam_pos
#	material.set_shader_parameter("cam_offset", subpixel_pos)
#	$Camera.global_position = cam_pos.round()
	if Global.Area != null:
		$Screen.size = Global.Area.Size
		#Global.Area.global_position = Global.Area.Size/2

func change_scene(path: String):
	clear()
	add_scene(path)

func clear():
	for i in $Screen.get_children():
		i.queue_free()

func add_scene(scene):
	if scene is String:
		$Screen.add_child((await Loader.load_res(scene)).instantiate())
	elif scene is PackedScene:
		$Screen.add_child(scene.instantiate())
