extends CanvasGroup
@export_enum("No sampling", "Sample AnimatedSprite2D", "Sample Sprite2D") var SampleParent: int = 0
@onready var parent = get_parent()

func _ready():
	#get_node("/root/Area/TileSet").get_children()
	$Circle.modulate = Color.TRANSPARENT
	await Global.lights_loaded
	var dub = $Circle.duplicate()
	for light in Global.Lights:
			var dubs = ["V", "H", "D"]
			for i in dubs:
				dub.name = light.name+i
				add_child(dub.duplicate())
			get_node(light.name+"H").rotation_degrees = -90
			get_node(light.name+"D").flip_h = true
			get_node(light.name+"H").modulate = Color.TRANSPARENT
			get_node(light.name+"H").position.y += -2
			get_node(light.name+"V").modulate = light.color.inverted()
			get_node(light.name+"H").modulate = light.color.inverted()

func _physics_process(delta):
	if SampleParent == 1:
		for i in get_children():
			var anim = parent.animation
			var frame = parent.frame
			if "H" in i.name:
				if "Left" in anim: anim = anim.replace("Left", "Down")
				elif "Right" in anim: anim = anim.replace("Right", "Up")
				elif "Down" in anim: anim = anim.replace("Down", "Left")
				elif "Up" in anim: anim = anim.replace("Up", "Right")
			if frame >= parent.sprite_frames.get_frame_count(parent.animation) -1:
				frame = min(parent.sprite_frames.get_frame_count(anim)-1, parent.sprite_frames.get_frame_count(parent.animation)-1)
			if i.name != "Circle" and not "Pick" in anim: i.texture = parent.sprite_frames.get_frame_texture(anim, frame)
	for light in Global.Lights:
		if light != null:
			if get_node_or_null(light.name+"V") == null: return
			var dist = to_local(light.global_position)
			var h=1
			if dist.x < 0: h=-1
			var dir:Vector2 = dist - Vector2((light.get_height()*(light.scale.y)*h)/2 ,light.get_height()*(light.scale.y))
			var max_dist:float = light.texture_scale*100*light.get_energy()
			if light.get_energy() >= 1 and dist.length() < max_dist and light.scale.length() <8:
				var angle = remap(light.get_height(), 0, 100, 1.5, 0.3)
				get_node(light.name+"V").scale.y = angle
				get_node(light.name+"H").scale.y = angle
				get_node(light.name+"D").scale.y = angle
				var off = Vector2(0 ,angle)*-10*remap(light.get_height(), 0, 100, 1,0)
				get_node(light.name+"V").offset = off
				get_node(light.name+"H").offset = off
				get_node(light.name+"D").offset = off
				scale.x = remap(light.get_height(), 0, 100, 1, 1.3)
#				position.y = max(((angle * -abs(dir.normalized()))*-10).y, 10* -abs(dir.normalized().y))
#				position.x = ((angle * dir.normalized())*-2).x
				get_node(light.name+"V").skew = dir.angle() - PI/2
				get_node(light.name+"H").skew = dir.angle()
				#print(max(abs(dir.normalized().x),abs(dir.normalized().y)))
				if max(abs(dir.normalized().x),abs(dir.normalized().y)) < 0.9 and light.get_height()<80:
					get_node(light.name+"D").modulate = Color.BLACK
					get_node(light.name+"D").rotation = dir.angle() - PI/2
				else: get_node(light.name+"D").modulate = Color.TRANSPARENT
#				get_node(light.name+"V").modulate = Color.BLACK
#				get_node(light.name+"H").modulate = Color.BLACK
				if Global.get_direction(dir) == Vector2.DOWN or Global.get_direction(dir) == Vector2.UP or light.get_height()>80:
					get_node(light.name+"V").modulate = Color.BLACK
					get_node(light.name+"H").modulate = Color.TRANSPARENT
				else:
					get_node(light.name+"H").modulate = Color.BLACK
					get_node(light.name+"V").modulate = Color.TRANSPARENT
				#get_node(light.name+"V").scale.y = remap(dir.length(), 0, max_dist, 1, 3)
				self_modulate.a = remap(dist.length(), 0, max_dist, 0.8, 0)
				#get_node(light.name+"H").scale.y = remap(dir.length(), 0, max_dist, 1, 3)
			else:
				get_node(light.name+"V").modulate = Color.TRANSPARENT
				get_node(light.name+"H").modulate = Color.TRANSPARENT



