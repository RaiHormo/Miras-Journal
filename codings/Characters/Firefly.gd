extends Marker2D
var moving= false
var direction:Vector2
var t:Tween

func _process(delta):
	if not moving:
		moving = true
		direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
		var d = Global.get_direction()*50
		if Global.Player != null: global_position = Global.Player.global_position + Vector2(randf_range(-180 , 180), randf_range(-150, 150)) +d
		t= create_tween()
		t.set_ease(randi_range(0,3))
		t.set_trans(Tween.TRANS_QUART)
		var s = randf_range(0.1, 0.7)
		scale = Vector2(s,s)
		var time = randf_range(3, 20)
		move(time)
		var n = randf_range(0.3, 1.5)
		t.tween_property($Light, "energy", n, time/2)
		t.tween_property($Light, "energy", 0, time/2)

		await t.finished
		moving = false

func move(time):
	var tn= create_tween()
	tn.set_ease(randi_range(0,3))
	tn.set_trans(Tween.TRANS_QUART)
	tn.set_parallel()
	tn.tween_property(self, "position", direction*100, time).as_relative()


#func _on_notif_screen_exited():
#	t.kill()
#	moving = false
