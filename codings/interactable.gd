extends Area2D
class_name Interactable

signal action()
@export var LabelText : String = "Inspect"
@export var ActionType: String
@export var Length: int = 120
@export var file: String = ""
@export var title: String = ""
@export var item: String = ""
@export var hidesprite: bool = false
@export var itemtype: String = ""
@export var to_time: Event.TOD
@export var to_time_relative: int
@export var Collision: CollisionShape2D = null
@export var Height: int = 0
@export var bubble_always: bool
@onready var button:Button
@onready var arrow:TextureRect
@onready var pack := $Pack
@export var hide_on_flag: StringName
@export var add_flag: bool = false
@export var hide_parent: bool = false
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
	await Global.area_initialized
	do_position()
	disappear()

func _process(delta: float) -> void:
	if Loader.InBattle or not is_instance_valid(Global.Player):
		pack.hide()
		return
	if Event.check_flag(hide_on_flag):
		if hide_parent: get_parent().queue_free()
		else: queue_free()
	if Global.Player.get_node_or_null("DirectionMarker/Finder") in get_overlapping_areas() and Global.Controllable:
		CheckInput()
		if not CanInteract: 
			await appear()
			CanInteract = true
	elif CanInteract: 
		await disappear()
		CanInteract = false

func appear():
	if not CanInteract and not animating:
		animating = true
		do_position()
		button.text = LabelText
		button.icon = Global.get_controller().ConfirmIcon
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

func disappear():
	if not animating:
		animating = true
		t = create_tween()
		t.set_parallel(true)
		t.set_ease(Tween.EASE_IN)
		t.set_trans(Tween.TRANS_LINEAR)
		if bubble_always:
			pack.show()
			t.tween_property(pack, "scale", Vector2(0.3, 0.3), 0.1)
			t.tween_property(button, "custom_minimum_size:x", 48, 0.1)
			t.tween_property(pack, "self_modulate", Color(1,1,1,0.2), 0.1)
			t.tween_property(button.get_node("Dots"), "self_modulate", Color.WHITE, 0.1)
			await get_tree().create_timer(0.2).timeout
		else:
			t.tween_property(pack, "self_modulate", Color(1,1,1,0), 0.1)
			t.tween_property(button, "custom_minimum_size:x", 48, 0.1)
			await get_tree().create_timer(0.1).timeout
			pack.hide()
		animating = false

func CheckInput() -> void:
	if Input.is_action_just_pressed("ui_accept") and CanInteract:
		_on_button_pressed()

func do_position():
	
	var dir = Global.get_direction(to_local(Global.Player.position + Vector2(0, Height - offset)))
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
	action.emit()
	if needs_bag and not Event.f("HasBag"): Global.toast("A bag is needed to store that."); return
	match ActionType:
		"toggle":
			Global.confirm_sound()
		"text":
			await Event.take_control()
			await Global.textbox(file, title)
			Event.give_control()
		"item":
			Item.add_item(item, itemtype)
		"battle":
			Loader.start_battle(file)
		"global":
			Global.call(file)
		"event":
			Global.confirm_sound()
			Event.call(file)
		"pass_time":
			PartyUI.confirm_time_passage(title, item, 
			to_time if to_time_relative == 0 else Event.get_time_progress_from_now(to_time_relative), file)
			Global.confirm_sound()
	if hidesprite:
		if add_flag: Event.f(hide_on_flag, true)
		if Collision: Collision.set_deferred("disabled", true)
		if hide_parent: get_parent().queue_free()
		else: queue_free()
