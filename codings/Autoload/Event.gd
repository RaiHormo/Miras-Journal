extends Node
## This Autoload handles the movment of [NPC] nodes and provides useful functions for scripting cutscenes


##An [Array] of all [NPC] nodes in the current scene
var List: Array[NPC]
var Flags: Array[StringName]
var Day: int
var Month: String = "November"

func _ready():
	process_mode = Node.PROCESS_MODE_PAUSABLE

##Character is added to the list of NPCS
func add_char(b:NPC):
	for i in List:
		if i==null:
			#List.remove_at
			continue
		if i.ID == b.ID:
			List[List.find(i)] = b
			return
	List.append(b)

##Get the [NPC] node from a [String] ID
func npc(ID: String):
	if List.is_empty(): return NPC.new()
	for i in List:
		if i==null:
			#List.erase(i)
			continue
		if i.ID == ID:
			return i

##Move an [NPC] relative to their current coords
func move_dir(dir:Vector2=Global.get_direction(), chara:String="P"):
	await npc(chara).move_dir(dir)

##Move an [NPC] to the specified coords
func move_to(pos:Vector2=Global.get_direction(), chara:String="P"):
	await npc(chara).go_to(pos)

##Wait a specified amount of time or one frame by default
## short for:
## [codeblock]
##await get_tree().create_timer(time).timeout
##[/codeblock]
func wait(time:float=0.01) -> void:
	await get_tree().create_timer(time).timeout

##Tween an [NPC] to the specified coords (ignores all collision)
func twean_to(pos:Vector2, time:float=1, chara:String="P"):
	var t = create_tween()
	t.set_ease(Tween.EASE_OUT)
	t.set_trans(Tween.TRANS_CUBIC)
	t.tween_property(npc(chara), "global_position", Global.Tilemap.map_to_local(pos), time)
	await t.finished

##Instantly move an [NPC] to the specified coords (ignores all collision)
func warp_to(pos:Vector2, chara:String="P"):
	npc(chara).global_position = Global.Tilemap.map_to_local(pos)

##Used for jump calculations
func _quad_bezier(ti : float, p0 : Vector2, p1 : Vector2, p2: Vector2, target : Node2D) -> void:
	var q0 = p0.lerp(p1, ti)
	var q1 = p1.lerp(p2, ti)
	var r = q0.lerp(q1, ti)

	target.global_position = r

##Make an [NPC] jump to specified coords. The height and time is relative, but keep the numbers low
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

func check_flag(flag: StringName):
	if flag in Flags: return true
	else: return false

func add_flag(flag: StringName):
	if flag not in Flags: Flags.append(flag)

func remove_flag(flag: StringName):
	if flag in Flags: Flags.erase(flag)

func take_bag():
	Global.item_sound()
	Item.HasBag = true
	Global.Player._check_party()
