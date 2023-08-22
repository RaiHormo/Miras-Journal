extends Node
var List: Array[NPC]

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
		await get_tree().create_timer(0.005).timeout
	if not npc(chara) == null:
		npc(chara).direction = Vector2.ZERO
