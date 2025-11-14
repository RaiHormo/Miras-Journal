extends Area2D
class_name Interactable

signal action()
@export var LabelText : String = "Inspect"
@export_enum("text", "toggle", "item", "battle", "event", "global", "pass_time", "veinet", "focus_cam", "social_link") var ActionType: String
@export var Length: int = 120
@export var file: String = ""
@export var title: String = ""
@export var item: String = ""
@export var hidesprite: bool = false
@export var hide_parent: bool = false
@export var free_on_hide: bool = false
@export var itemtype: String = ""
@export var to_time: Event.TOD
@export var to_time_relative: int
@export var Collision: CollisionShape2D = null
@export var Height: int = 0
@export var bubble_always: bool
@onready var button:Button
@onready var arrow:TextureRect
@onready var pack := $Pack
@export var return_control:= true
@export var event_condition:= ""
@export var show_on_flag: StringName
@export var hide_on_flag: StringName
@export var add_flag: bool = false
@export var offset := 5
@export var proper_pos:= Vector2.ZERO
@export var proper_face:= Vector2.ZERO
@export var needs_bag:= false
var CanInteract := false
var t:Tween
var animating:= false

func _ready() -> void:
	button = pack.get_node("Cnt/Button")
	arrow = pack.get_node("Arrow")
	check()
	await Global.area_initialized
	Global.check_party.connect(check)
	do_position()
	disappear()
	if ActionType == "vainet": vain_check()

func vain_check():
	if Event.f(get_parent().name):
		get_parent().get_node("Particle").emitting = false
		LabelText = "Enter"
		get_parent().get_node("Sprite").show()
	else:
		get_parent().get_node("Particle").emitting = true
		LabelText = "Open"
		get_parent().get_node("Sprite").hide()

func check() -> void:
	if bubble_always:
		if get_tree().root.has_node("Textbox"): disappear(true)
		else: bubble()
	if Loader.InBattle or not is_instance_valid(Global.Player):
		disappear(true)
		return
	if event_condition != "" and Event.condition(event_condition) == 0 :
		destroy()
	if not show_on_flag.is_empty() and not Event.check_flag(show_on_flag):
		destroy()
	if not hide_on_flag.is_empty() and Event.check_flag(hide_on_flag):
		destroy()
	#print(Global.Controllable, CanInteract)
	if not Global.Controllable and CanInteract:
		disappear()
		CanInteract = false
	elif Global.Controllable and Global.Player.get_node_or_null("DirectionMarker/Finder") in get_overlapping_areas() and not CanInteract:
		appear()
		CanInteract = true

func destroy():
	if hide_parent: 
		get_parent().hide()
		get_parent().scale = Vector2.ZERO
		if get_parent() is NPC: get_parent().collision(false)
		if free_on_hide: get_parent().queue_free()
	else:
		if free_on_hide: queue_free() 
		hide()
		scale = Vector2.ZERO

func appear():
	if not CanInteract and not animating:
		animating = true
		do_position()
		button.text = LabelText
		button.icon = Global.get_controller().ConfirmIcon
		z_index = 9
		t = create_tween()
		pack.self_modulate = Color.TRANSPARENT
		pack.show()
		button.show()
		arrow.show()
		t.set_parallel(true)
		t.set_ease(Tween.EASE_OUT)
		t.set_trans(Tween.TRANS_BACK)
		t.tween_property(pack, "scale", Vector2(0.4, 0.4), 0.1)
		t.tween_property(button.get_node("Dots"), "self_modulate", Color(1,1,1,0), 0.1)
		t.tween_property(pack, "self_modulate", Color.WHITE, 0.1).from(Color.TRANSPARENT)
		t.tween_property(button, "custom_minimum_size:x", Length, 0.15).from(48)
		await get_tree().create_timer(0.1).timeout
		animating = false
		if not is_instance_valid(Global.Player) or not Global.Player.get_node_or_null("DirectionMarker/Finder") in get_overlapping_areas():
			disappear()
			CanInteract = false

func disappear(also_hide_bubble:= false):
	if not animating:
		animating = true
		if bubble_always and not also_hide_bubble:
			await bubble()
		else:
			t = create_tween().set_parallel()
			t.set_ease(Tween.EASE_IN)
			t.set_trans(Tween.TRANS_LINEAR)
			t.tween_property(pack, "self_modulate", Color(1,1,1,0), 0.1)
			t.tween_property(button, "custom_minimum_size:x", 48, 0.1)
			await get_tree().create_timer(0.1).timeout
			pack.hide()
		z_index = 0
		animating = false

func bubble():
	pack.show()
	t = create_tween().set_parallel()
	t.set_ease(Tween.EASE_IN)
	t.set_trans(Tween.TRANS_LINEAR)
	t.tween_property(pack, "scale", Vector2(0.3, 0.3), 0.1)
	t.tween_property(button, "custom_minimum_size:x", 48, 0.1)
	t.tween_property(pack, "self_modulate", Color(1,1,1,0.2), 0.1)
	t.tween_property(button.get_node("Dots"), "self_modulate", Color.WHITE, 0.1)
	await get_tree().create_timer(0.2).timeout

func _input(event: InputEvent) -> void:
	if is_instance_valid(Global.Player) and Global.Controllable and Global.Player.get_node_or_null("DirectionMarker/Finder") in get_overlapping_areas() and not get_tree().root.has_node("Textbox"):
		if Input.is_action_just_pressed("ui_accept") and CanInteract:
			_on_button_pressed()

func do_position():
	if Loader.InBattle or not is_instance_valid(Global.Player):
		pack.hide()
		return
	var dir = Query.get_direction(to_local(Global.Player.position + Vector2(0, Height - offset)))
	if dir == Vector2.UP and bubble_always: dir = Vector2.DOWN
	match dir:
		Vector2.UP:
			$Pack/Cnt.alignment = BoxContainer.ALIGNMENT_CENTER
			$Pack/Cnt.position.x = -180
			$Pack.position.y = 28 - Height
			$Pack.position.x = 0
			$Pack/Arrow.flip_h = true
			$Pack/Arrow.position.y = -42
		Vector2.DOWN:
			$Pack/Cnt.alignment = BoxContainer.ALIGNMENT_CENTER
			$Pack/Cnt.position.x = -180
			$Pack.position.x = 0
			$Pack.position.y = -10 - Height
			$Pack/Arrow.flip_h = false
			$Pack/Arrow.position.y = -6
		Vector2.LEFT:
			$Pack/Cnt.alignment = BoxContainer.ALIGNMENT_BEGIN
			$Pack/Cnt.position.x = -24
			$Pack.position.x = 0
			$Pack.position.y = -10 - Height
			$Pack/Arrow.flip_h = false
			$Pack/Arrow.position.y = -6
		Vector2.RIGHT:
			$Pack/Cnt.alignment = BoxContainer.ALIGNMENT_END
			$Pack/Cnt.position.x = -342
			$Pack.position.x = 0
			$Pack/Arrow.position.y = -6
			$Pack.position.y = -10 - Height
			$Pack/Arrow.flip_h = false

func _on_button_pressed() -> void:
	Global.Controllable = false
	Global.Player.direction = Vector2.ZERO
	t = create_tween()
	t.set_parallel(true)
	t.set_ease(Tween.EASE_IN)
	t.set_trans(Tween.TRANS_LINEAR)
	t.tween_property(pack, "scale", Vector2(0.4,0.4), 0.1).from(Vector2(0.36,0.36))
	await t.finished
	if proper_pos != Vector2.ZERO:
		await Event.take_control()
		Global.Player.collision(false)
		await Global.Player.go_to(proper_pos, false, true, proper_face)
	if needs_bag and not Event.f("HasBag"): Global.toast("A bag is needed to store that."); return
	if get_tree().root.has_node("MainMenu"):
		get_tree().root.get_node("MainMenu").close()
	if not (to_time == 0 and to_time_relative == 0):
		Event.ToTime = to_time if to_time_relative == 0 else Event.get_time_progress_from_now(to_time_relative)
	match ActionType:
		"toggle":
			Global.confirm_sound()
		"text":
			await Event.take_control(false, false, true)
			disappear(true)
			await Global.textbox(file, title)
		"item":
			Item.add_item(item, itemtype)
		"battle":
			Loader.start_battle(file)
		"global":
			Global.call(file)
		"event":
			Global.confirm_sound()
			Event.sequence(file)
		"pass_time":
			if await PartyUI.confirm_time_passage(title, item):
				Global.confirm_sound()
				Event.sequence(file)
		"veinet":
			if Event.f(get_parent().name):
				Global.veinet_map(get_parent().name.replace("VP", ""))
				Loader.save()
			else:
				Event.f(get_parent().name, true)
				vain_check()
				disappear()
				await Event.wait(0.3)
				CanInteract = false
				appear()
		"focus_cam":
			Event.take_control()
			Global.Player.camera_follow(false)
			Global.get_cam().position = Vector2(file.to_int(), title.to_int())
			await Event.wait(1)
			if add_flag: Event.f(hide_on_flag, true)
			Global.check_party.emit()
			await Event.wait(3, false)
			Global.Player.camera_follow(true)
		"social_link":
			await Event.take_control(false)
			var rank = Event.condition(event_condition)
			if rank == 0:
				Global.toast("Something went wrong with the event condition")
			disappear(true)
			await Global.textbox(file, "rank"+str(rank)+"_prepare")
	if add_flag: 
		if hide_on_flag != "":
			Event.f(hide_on_flag, true)
		else: Event.f(name, true)
	if return_control:
		Event.give_control(false)
	if hidesprite:
		if Collision: Collision.set_deferred("disabled", true)
		if hide_parent: get_parent().queue_free()
		else: queue_free()
	action.emit()
	check()

func _on_area_entered(area: Area2D) -> void:
	if Loader.InBattle or not Global.Controllable or not is_instance_valid(Global.Player):
		pack.hide()
		return
	if area == Global.Player.get_node_or_null("DirectionMarker/Finder"):
		if not CanInteract:
			await appear()
			CanInteract = true

func _on_area_exited(area: Area2D) -> void:
	if not is_instance_valid(Global.Player): return
	if area == Global.Player.get_node_or_null("DirectionMarker/Finder"):
		await disappear()
		CanInteract = false
