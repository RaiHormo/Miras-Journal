extends Node
## This Autoload handles the movment of [NPC] nodes and provides useful functions for scripting cutscenes


##An [Array] of all [NPC] nodes in the current scene
var List: Array[NPC]
var Flags: Array[StringName]
var Day: int
var Month: String = "November"
var TimeOfDay:= TOD.DARKHOUR
var tutorial: String
var CutsceneHandler: Node = null
var allow_skipping:= true

enum TOD {DARKHOUR = -1, MORNING = 0, MIDDAY = 1, AFTERNOON = 2, EVENING = 3, NIGHT = 4}

func _ready():
	process_mode = Node.PROCESS_MODE_PAUSABLE

##Character is added to the list of NPCS
func add_char(b:NPC):
	for i in List:
		if ! i:
			#List.remove_at
			continue
		if i.ID == b.ID:
			List[List.find(i)] = b
			return
	List.append(b)

##Get the [NPC] node from a [String] ID
func npc(ID: String) -> NPC:
	for i in List:
		if !i:
			#List.erase(i)
			continue
		if i.ID == ID:
			return i
	return NPC.new()

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
func wait(time:float=0, pausable:= true) -> void:
	if time != 0:
		await get_tree().create_timer(time, !pausable).timeout
	else:
		await get_tree().physics_frame

##Tween an [NPC] to the specified coords (ignores all collision)
func twean_to(pos:Vector2, time:float=1, chara:String="P"):
	var t = create_tween()
	t.set_ease(Tween.EASE_OUT)
	t.set_trans(Tween.TRANS_CUBIC)
	t.tween_property(npc(chara), "global_position", Global.Area.map_to_local(pos), time)
	await t.finished

##Instantly move an [NPC] to the specified coords (ignores all collision)
func warp_to(pos:Vector2, chara:String="P"):
	npc(chara).global_position = Global.Area.map_to_local(pos)

##Used for jump calculations
func _quad_bezier(ti : float, p0 : Vector2, p1 : Vector2, p2: Vector2, target : Node2D) -> void:
	var q0 = p0.lerp(p1, ti)
	var q1 = p1.lerp(p2, ti)
	var r = q0.lerp(q1, ti)

	target.global_position = r

##Make an [NPC] jump to specified coords. The height and time is relative, but keep the numbers low
func jump_to(pos:Vector2, time:float, chara:String = "P", height: float =0.1):
	var t:Tween = create_tween()
	var position = Global.Area.map_to_local(pos)
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

func f(flag:StringName, state = null) -> bool:
	if state is bool:
		if state: add_flag(flag)
		else: remove_flag(flag)
	if state is int:
		return f_past(flag, state)
	return check_flag(flag)

func pop_tutorial(id: String):
	tutorial = id
	get_tree().root.add_child(preload("res://UI/Tutorials/TutorialPopup.tscn").instantiate())

func take_control(keep_ui:= false, keep_followers:= false, idle:= true):
	if !Global.Player or !Global.Area: return
	Global.Controllable = false
	await wait()
	if Global.Player.dashing:
		await Global.Player.stop_dash()
		Global.Player.dashing = false
	Global.Player.winding_attack = false
	if idle:
		Global.Player.BodyState = NPC.IDLE
		Global.Player.direction = Vector2.ZERO
		Global.Player.set_anim()

	PartyUI.UIvisible = keep_ui
	Global.Controllable = false
	if not keep_followers:
		for i in Global.Area.Followers:
			i.dont_follow = true
	await wait()


func give_control():
	if Global.Player == null:  return
	Global.Player.direction = Vector2.ZERO
	Global.Player.collision(true)
	PartyUI.UIvisible = true
	Global.Controllable = true
	Global.Player.camera_follow(true)
	get_tree().paused = false
	for i in Global.Area.Followers:
		i.dont_follow = false

func flag_int(str: String, max_num:= 9) -> int:
	for i in range(0, max_num):
		if check_flag(str + str(i)): return i
	return 0

func flag_progress(str: String, to:= 1):
	var num:= flag_int(str)
	if num == 0: add_flag(str+str(to))
	elif num < to:
		remove_flag(str+str(num))
		add_flag(str+str(to))

func f_past(str: String, has_passed:= 9) -> bool:
	if flag_int(str) >= has_passed:
		return true
	else: return false

func skip_cutscene():
	if CutsceneHandler and CutsceneHandler.has_method(&"skip"):
		await Loader.transition("")
		CutsceneHandler.skip()
		await Event.wait()
		var dub = CutsceneHandler.duplicate()
		CutsceneHandler.free()
		if Global.Area: Global.Area.add_child(dub)
		await Event.wait()
		dub.skip()
		Loader.detransition()
		CutsceneHandler = dub

func bubble(anim: String, npc: String):
	npc(npc).bubble(anim)
##########################################################

#region Sequences
func bag_seq():
	Global.Player.BodyState = NPC.CUSTOM
	Global.Player.direction = Vector2.ZERO
	await Global.Player.set_anim("BagGet", true)
	Global.Player.set_anim("IdleRight")
	Global.item_sound()
	Item.get_animation(preload("res://art/Icons/Items.tres"), "Flimsy bag", false)
	f(&"HasBag", true)
	give_control()
	Global.Player._check_party()

func axe_seq():
	Item.add_item("LightweightAxe", &"Key")
	pop_tutorial("ov_attack")

func TWflame():
	await Event.take_control()
	Global.Player.set_anim("IdleRight")
	await Global.textbox("temple_woods_random", "getting_dark")
	await Global.Player.activate_flame()
	await Event.wait(0.5)
	await Global.textbox("temple_woods_random", "that_should_do_it")
	Event.give_control()
	Event.add_flag("TWflame")

func rest_amberelm():
	take_control()
	await Loader.save()
	Global.check_party.emit()
	Loader.detransition()
	var cut = Global.Area.get_node("RestAmberelm")
	cut.show()
	get_tree().paused = false
	Global.Area.Followers[0].hide()
	cut.get_node("Mira").BodyState = NPC.NONE
	cut.get_node("Alcine").BodyState = NPC.NONE
	cut.get_node("Mira").set_anim("SitDown")
	cut.get_node("Alcine").set_anim("IdleDown")
	Global.Player.hide()
	Global.Player.camera_follow(false)
	Global.get_cam().zoom = Vector2(6,6)
	Global.get_cam().position = Vector2(85,360)
	await Event.wait(1)
	await Global.textbox("amberelm_txt", "rest_amberelm", true)
	await Loader.transition("")
	await Event.wait(1)
	Global.heal_party()
	Event.TimeOfDay = TOD.AFTERNOON
	Global.heal_party()
	await Loader.detransition()
	await Global.textbox("amberelm_txt", "wake_amberelm", true)
	await Loader.transition("R")
	Global.get_cam().zoom = Vector2(4,4)
	cut.hide()
	Global.Player.show()
	Loader.detransition()
	give_control()
	f("RestAmberelm", true)
	Loader.save()
#endregion
