extends Node
## This Autoload handles the movment of [NPC] nodes and provides useful functions for scripting cutscenes


##An [Array] of all [NPC] nodes in the current scene
var List: Dictionary[String, NPC]
var Objects: Dictionary[String, Node2D]
var Flags: Dictionary[StringName, int]
var Diary: Dictionary[int, PackedStringArray] = {
	2: ["boo"],
	5: ["boo", "bee"]
}
var Day: int:
	set(x):
		Day = x
		add_flag("day", x)
var Month: String = "November"
var TimeOfDay:= TOD.DARKHOUR:
	set(x):
		TimeOfDay = x
		add_flag("time", x)
var tutorial: String
var CutsceneHandler: Node = null
var allow_skipping:= true
var ToTime:= TOD.DARKHOUR
var ToDay: int
signal time_changed
signal next_day
@onready var sequences: Node = $Sequences


enum TOD {DARKHOUR = 0, MORNING = 1, DAYTIME = 2, AFTERNOON = 3, EVENING = 4, NIGHT = 5}

func _ready():
	process_mode = Node.PROCESS_MODE_PAUSABLE

##Character is added to the list of NPCS
func add_char(b:NPC):
	if List.has(b.ID) and is_instance_valid(List.get(b.ID)):
		push_warning("Duplicate npc spawned: ", b.ID)
	List.set(b.ID, b)

##Get the [NPC] node from a [String] ID
func npc(ID: String) -> NPC:
	return List.get(ID)

func obj(ID: String) -> Node2D:
	return Objects.get(ID)

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

func tween(object: Node, property: String, to: Variant, time = 0.3):
	var t = create_tween()
	t.set_ease(Tween.EASE_OUT)
	t.set_trans(Tween.TRANS_CUBIC)
	t.tween_property(object, NodePath(property), to, time)
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

var operators: Array[String] = ['+', '!', '||', '&&', '=', 'day:', 'time:', '>', '<', '>=', '<=']

## Check if a flag is equal to a given value.[br]
func check_flag(flag: StringName, value:= 1):
	flag = flag.replace(" ", "_")
	if flag in Flags:
		return Flags.get(flag) == value
	if value == 0: return true
	else: return false

## Evaluate an expression
## Additional syntax:[br]
## [code]flag + flag[/code] AND[br]
## [code]flag || flag[/code] OR[br]
## [code]flag = (Number)[/code] alternative to setting the value, useful for event triggers.[br]
## [code]day: (Number)[/code] Check if the current day is the given number.[br]
## [code]time: (Number)[/code] Check if the current time of day is the given number.[br]
func f(flag: StringName) -> bool:
	flag = flag.replace(" ", "_")
	if flag == "true": return true
	if flag == "false": return false
	if ":" in flag:
		return f(flag.replace(":", "="))
	if "+" in flag:
		var split = flag.split("+")
		for i in split:
			if not f(i): return false
		return true
	if "||" in flag:
		var split = flag.split("||")
		for i in split:
			if f(i): return true
		return false
	if flag.begins_with("!"): return not f(flag.replace("!", ""))
	if ">=" in flag:
		var split = flag.split(">=")
		return f(flag.replace(split[0]+">="+split[1], str(flag_int(split[0]) >= flag_int(split[1]))))
	if ">" in flag:
		var split = flag.split(">")
		return f(flag.replace(split[0]+">"+split[1], str(flag_int(split[0]) > flag_int(split[1]))))
	if "<=" in flag:
		var split = flag.split("<=")
		return f(flag.replace(split[0]+"<="+split[1], str(flag_int(split[0]) <= flag_int(split[1]))))
	if "<" in flag:
		var split = flag.split("<")
		return f(flag.replace(split[0]+"<"+split[1], str(flag_int(split[0]) < flag_int(split[1]))))
	if "=" in flag:
		var split = flag.split("=")
		return f(flag.replace(split[0]+"="+split[1], str(check_flag(split[0], flag_int(split[1])))))
	if Flags.has(flag) and Flags.get(flag) == 1: return true
	else: return false

## Set a flag with [code]do add_flag("Example", 1)[/code]. The second parameter is optional, and is 1 by default.
func add_flag(flag: StringName, value:= 1) -> bool:
	flag = flag.replace(" ", "_")
	if "=" in flag:
		var split = flag.split("=")
		return add_flag(str(split[0]), int(split[1]))
	if value == 0:
		remove_flag(flag)
		return 0
	Flags.set(flag, value)
	print("Set flag \"", flag, "\" to ", value)
	return value

func remove_flag(flag: StringName):
	if flag in Flags: Flags.erase(flag)
	print("Removed flag \"", flag, "\"")

func pop_tutorial(id: String):
	tutorial = id
	get_tree().root.add_child(preload("res://UI/Tutorials/TutorialPopup.tscn").instantiate())

func take_control(keep_ui:= false, keep_followers:= false, idle:= false):
	if not is_instance_valid(Global.Player):
		Global.Controllable = false
		return
	var pos = Global.Player.position
	print("Taking control")
	Global.Controllable = false
	await wait()
	if not is_instance_valid(Global.Player) or not is_instance_valid(Global.Area): return
	if Global.Player.dashing:
		await Global.Player.stop_dash(false)
		Global.Player.dashing = false
	Global.Player.speed = Global.Player.walk_speed
	Global.Player.dashdir = Vector2.ZERO
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
	if is_instance_valid(Global.Player):
		Global.Controllable = false
		Global.Player.position = pos
		Global.check_party.emit()

func give_control(camera_follow:= false, bring_followers:= true):
	if Global.Player == null:  return
	print("Giving control")
	if get_tree().root.has_node("Warning"):
		get_tree().root.get_node("Warning").queue_free()
	#if get_tree().root.has_node("MainMenu"):
		#get_tree().root.get_node("MainMenu").close()
	Global.Player.direction = Vector2.ZERO
	Global.Player.collision(true)
	PartyUI.UIvisible = true
	Global.Controllable = true
	Global.Player.local_controllable = true
	if camera_follow: Global.Player.camera_follow(true)
	get_tree().paused = false
	if bring_followers:
		for i in Global.Area.Followers:
			i.dont_follow = false
		#Event.teleport_followers()
	Global.Area.setup_params(true)
	Global.check_party.emit()

func flag_int(str: String) -> int:
	if str.is_valid_int(): return int(str)
	if Flags.has(str) and Flags.get(str) is int:
		return Flags.get(str)
	else: return 0

func flag_progress(stri: String, to:= 1):
	if to == 0: remove_flag(stri)
	else:
		Flags.set(stri, max(flag_int(stri), to))

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

## Sets up a time change. Run time_transition() to properly move time
func progress_by_time(amount: int):
	ToDay = get_day_progress_from_now(amount)
	ToTime = get_time_progress_from_now(amount)

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
	setup_time_changes(TimeOfDay, (ToDay-Day)*5+ToTime)
	TimeOfDay = tod
	time_changed.emit()

func teleport_followers():
	#for i in Global.Area.Followers:
		#i.jump_to_player()
	Global.Player.path.curve.clear_points()
	Global.Player.path.curve.add_point(Global.PlayerPos)
	Global.Player.path.curve.add_point(Global.PlayerPos)

func sequence(title: String):
	for i in sequences.get_children():
		if i.has_method(title):
			return i.call(title)
	OS.alert(title + " is not a valid event")

func sequence_exists(title: String) -> bool:
	for i in sequences.get_children():
		if i.has_method(title):
			return true
	return false

func spawn(id: String, pos: Vector2i, dir:= "D", z: int = Global.Area.get_z(), no_collision = true) -> NPC:
	var chara: NPC = (await Loader.load_res("res://rooms/components/NPC.tscn")).instantiate()
	var sprite_node:= AnimatedSprite2D.new()
	chara.SpawnOnCameraInd = false
	chara.add_child(sprite_node)
	sprite_node.name = "Sprite"
	sprite_node.use_parent_material = true
	var nam = id.split(":")
	var sprite = await get_ov_sprites(id)
	if sprite == null: return null
	sprite_node.sprite_frames = sprite
	if no_collision: chara.collision(false)
	chara.name = nam[0]
	chara.ID = nam[0]
	chara.position = pos
	chara.z_index = z
	if Global.Area.CurSubRoom == null:
		Global.Area.add_child.call_deferred(chara)
	else: 
		Global.Area.CurSubRoom.add_child.call_deferred(chara)
		chara.position -= Global.Area.CurSubRoom.position
	print("Spawned: ", chara.ID)
	if dir.length() > 1:
		chara.BodyState = NPC.CUSTOM
		chara.set_anim(dir)
	else:
		await chara.look_to(Query.get_dir_from_letter(dir))
	return chara

func no_player():
	Global.Controllable = false
	if is_instance_valid(Global.Player):
		Global.Player.queue_free()
		for i in Global.Area.Followers:
			i.queue_free()
			await get_tree().physics_frame
	PartyUI.hide_all()

func get_ov_sprites(id: String) -> SpriteFrames:
	var nam = id.split(":", false)
	match nam.size():
		1:
			nam.append(nam[0] + "OV")
		2:
			pass
		0, _:
			push_error("Invalid spawn id: " + id)
			return null
	return await Loader.load_res("res://art/OV/"+nam[0]+"/"+nam[1]+".tres")

func time_transition(location:= Global.Area.codename()):
	if get_tree().root.has_node("Textbox"):
		get_tree().root.get_node("Textbox")._on_close()
		#await Event.wait(0.3, false)
	await Event.take_control()
	await Loader.transition()
	Loader.ungray.emit()
	await Loader.flip_time(TimeOfDay, ToTime)
	if Day != ToDay:
		Day = ToDay
		Global.toast(Query.get_month_name(Query.get_month(Day))+" "+str(Day)+" cin16")
		Loader.Defeated.clear()
	set_time(ToTime)
	await start_time_events(location)

func zoom(val: float, maintain = false):
	Global.Camera.zoom = Vector2(val, val)
	if maintain: Global.Area.overwrite_zoom = val

func camera_move(to: Vector2, time: float = -1, ease:= Tween.EASE_IN_OUT, trans:= Tween.TRANS_QUAD):
	camera_unlock()
	if time > 0:
		Global.Camera.position_smoothing_enabled = false
		var t = create_tween().set_ease(ease).set_trans(trans).set_parallel()
		t.tween_property(Global.Camera, "position", to, time)
		await t.finished
		Global.Camera.position_smoothing_enabled = true
	elif time == 0: 
		Global.Camera.position_smoothing_enabled = false
		Global.Camera.position = to
		Global.Camera.position_smoothing_enabled = true
	else:
		Global.Camera.position = to

func camera_move_relative(to: Vector2, time: float = -1, ease:= Tween.EASE_IN_OUT, trans:= Tween.TRANS_QUAD):
	await camera_move(Global.Camera.position + to, time, ease, trans)

func camera_unlock():
	if is_instance_valid(Global.Player):
		Global.Player.camera_follow(false)

func start_time_events(location: String):
	var seq = Query.get_mmm(Query.get_month(Day)).to_lower()+str(Day)+"_"+Query.to_tod_text(TimeOfDay).to_lower()
	if sequence_exists(seq):
		print("Starting event: "+seq)
		await sequence(seq)
	else:
		match location:
			"Pyrson":
				if Global.Area.IsDungeon:
					await sequence("return_home_pyrson")
				else:
					await sequence("wake_home")
			"Dungeon":
				Global.passive("banter_misc", "rest_dungeon")
				give_control()
			_:
				give_control()
	Global.check_party.emit()
	Loader.detransition()

func condition(con: String):
	if $Conditions.has_method(con):
		var res = $Conditions.call(con)
		#print("Condition "+ con+" ", res)
		return res
	else: 
		push_error(con + " condition is not valid"); 
		return 0

func setup_time_changes(from: int, to: int):
	if f_past("eepy", 1):
		var eepy = flag_int("eepy")
		add_flag("eepy", eepy+to-from)
		if eepy >= 2 or TimeOfDay == TOD.MORNING: remove_flag("eepy")
		
