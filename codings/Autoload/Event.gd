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
var ToTime:= TOD.DARKHOUR
signal time_changed
signal next_day
@onready var seq: Node = $Sequences


enum TOD {DARKHOUR = 0, MORNING = 1, DAYTIME = 2, AFTERNOON = 3, EVENING = 4, NIGHT = 5}

func _ready():
	process_mode = Node.PROCESS_MODE_PAUSABLE

##Character is added to the list of NPCS
func add_char(b:NPC):
	for i in List:
		if !is_instance_valid(i):
			#List.remove_at
			continue
		if i.ID == b.ID:
			List[List.find(i)] = b
			return
	List.append(b)

##Get the [NPC] node from a [String] ID
func npc(ID: String) -> NPC:
	for i in List:
		if !is_instance_valid(i):
			#List.erase(i)
			continue
		if i.ID == ID:
			return i
	return null

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
	if "day:" in flag:
		if int(flag.replace("day:", "")) == Day: return true
		else: return false
	if "time:" in flag:
		if int(flag.replace("time:", "")) == TimeOfDay: return true
		else: return false
	if flag in Flags: return true
	else: return false

func add_flag(flag: StringName):
	if flag not in Flags: Flags.append(flag)
	print("Added flag \"", flag, "\"")

func remove_flag(flag: StringName):
	if flag in Flags: Flags.erase(flag)
	print("Removed flag \"", flag, "\"")

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

func take_control(keep_ui:= false, keep_followers:= false, idle:= false):
	Global.Controllable = false
	await wait()
	if not is_instance_valid(Global.Player) or not is_instance_valid(Global.Area): return
	if Global.Player.dashing:
		await Global.Player.stop_dash()
		Global.Player.dashing = false
	Global.Player.winding_attack = false
	Global.Player.direction = Vector2.ZERO
	if idle:
		Global.Player.BodyState = NPC.IDLE
		Global.Player.set_anim()

	PartyUI.UIvisible = keep_ui
	Global.Controllable = false
	if not keep_followers:
		for i in Global.Area.Followers:
			i.dont_follow = true
	await wait()
	Global.check_party.emit()

func give_control(camera_follow:= false):
	if Global.Player == null:  return
	Global.Player.direction = Vector2.ZERO
	Global.Player.collision(true)
	PartyUI.UIvisible = true
	Global.Controllable = true
	if camera_follow: Global.Player.camera_follow(true)
	get_tree().paused = false
	for i in Global.Area.Followers:
		i.dont_follow = false
	Global.check_party.emit()

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
#FIXME
func skip_cutscene():
	if is_instance_valid(CutsceneHandler) and CutsceneHandler.has_method(&"skip"):
		await Loader.transition("")
		CutsceneHandler.skip()
		await Event.wait()
		var dub = CutsceneHandler.duplicate()
		CutsceneHandler.free()
		if is_instance_valid(Global.Area): Global.Area.add_child(dub)
		await Event.wait()
		dub.skip()
		Loader.detransition()
		CutsceneHandler = dub

func bubble(anim: String, npc: String):
	npc(npc).bubble(anim)

func progress_by_time(amount: int):
	Day = get_day_progress_from_now(amount)
	TimeOfDay = get_time_progress_from_now(amount)
	Global.check_party.emit()

func get_time_progress_from_now(amount: int):
	var toad = TimeOfDay as int
	toad += amount
	toad = wrapi(toad, 1, 6)
	return toad as TOD

func get_day_progress_from_now(amount: int):
	var toad = TimeOfDay as int
	print(toad)
	toad += amount
	if toad > 5:
		return Day + 1
	else: return Day

func set_time(tod: TOD):
	if tod < TimeOfDay:
		Global.next_day_ui()
	TimeOfDay = tod
	time_changed.emit()

func teleport_followers():
	for i in Global.Area.Followers:
		i.position = Global.Player.position

func sequence(title: String):
	if seq.has_method(title):
		seq.call(title)
	else:
		OS.alert(title + " is not a valid event")

func sequence_exists(title: String) -> bool:
	return seq.has_method(title)

func spawn(id: String, pos: Vector2i, dir:= "D") -> NPC:
	var chara: NPC = (await Loader.load_res("res://rooms/components/NPC.tscn")).instantiate()
	var nam = id.split(":", false)
	match nam.size():
		1:
			nam.append(nam[0] + "OV")
		2:
			pass
		0, _:
			push_error("Invalid spawn id: " + id)
			return null
	var sprite_node:= AnimatedSprite2D.new()
	chara.add_child(sprite_node)
	sprite_node.name = "Sprite"
	sprite_node.use_parent_material = true
	var sprite = await Loader.load_res("res://art/OV/"+nam[0]+"/"+nam[1]+".tres")
	if sprite == null: return null
	sprite_node.sprite_frames = sprite
	Global.Area.add_child(chara)
	chara.name = nam[0]
	chara.position = pos
	chara.look_to(Global.get_dir_from_letter(dir))
	return chara

func no_player():
	Global.Controllable = false
	if is_instance_valid(Global.Player):
		Global.Player.queue_free()
	PartyUI.hide_all()

func time_transition():
	await Event.take_control()
	await Loader.transition()
	await Loader.flip_time(TimeOfDay, ToTime)
	set_time(ToTime)
	start_time_events()

func zoom(val: float):
	Global.Camera.zoom = Vector2(val, val)

func start_time_events():
	var seq = Global.get_mmm(Global.get_month(Day)).to_lower()+str(TimeOfDay)+"_"+Global.to_tod_text(TimeOfDay).to_lower()
	print(seq)
	if sequence_exists(seq):
		sequence(seq)
