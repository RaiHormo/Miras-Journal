extends Node
var List: Array[NPC]

func _ready():
	process_mode = Node.PROCESS_MODE_PAUSABLE

func add_char(b:NPC):
	for i in List:
		if i.ID == b.ID:
			List[List.find(i)] = b
			return
	List.append(b)

func npc(ID: String):
	for i in List:
		if i.ID == ID:
			return i

func walk(dir:Vector2=Global.get_direction(), time:float=60, chara:String="P"):
	for i in time:
		if not npc(chara) == null:
			npc(chara).move_dir(dir)
		await wait()
	if not npc(chara) == null:
		npc(chara).direction = Vector2.ZERO

func wait(time=0.005):
	await get_tree().create_timer(time).timeout

func twean_to(pos:Vector2, time:float=1, chara:String="P"):
	var t = create_tween()
	t.set_ease(Tween.EASE_OUT)
	t.set_trans(Tween.TRANS_CUBIC)
	t.tween_property(npc(chara), "global_position", Global.Tilemap.map_to_local(pos), time)
	await t.finished


func _quad_bezier(ti : float, p0 : Vector2, p1 : Vector2, p2: Vector2, target : Node2D) -> void:
	var q0 = p0.lerp(p1, ti)
	var q1 = p1.lerp(p2, ti)
	var r = q0.lerp(q1, ti)
	
	target.global_position = r

func jump_to(pos:Vector2, time:float, chara:String = "P", height: float =0.1):
	var t:Tween = create_tween()
	var position = Global.Tilemap.map_to_local(pos)
	var start = npc(chara).global_position
	var jump_distance : float = start.distance_to(position)
	var jump_height : float = jump_distance * height #will need tweaking
	var midpoint = start.lerp(position, 0.5) + Vector2.UP * jump_height
	var jump_time = jump_distance * (time * 0.001) #will also need tweaking, this controls how fast the jump is
	t.tween_method(Global._quad_bezier.bind(start, midpoint, position, npc(chara)), 0.0, 1.0, jump_time)
	await t.finished