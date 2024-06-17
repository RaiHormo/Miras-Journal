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
@export var Collision: CollisionShape2D = null
@export var Height: int = 0
var CanInteract := false
var t:Tween
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

func _ready() -> void:
	$Pack.hide()

func _process(delta: float) -> void:
	if Loader.InBattle:
		pack.hide()
		return
	if Event.check_flag(hide_on_flag):
		if hide_parent: get_parent().queue_free()
		else: queue_free()
	if pack == null:
		pack = $Pack.duplicate()
	if Global.Player and Global.Player.get_node_or_null("DirectionMarker/Finder") in get_overlapping_areas() and Global.Controllable:
		CheckInput()
		#Appear
		if not pack.visible:
			do_position()
			#$/root.add_child(pack)
			button = pack.get_node("Cnt/Button")
			arrow = pack.get_node("Arrow")
			#pack.position = $Pack.global_position
			pack.show()
			button.text = LabelText
			button.icon = Global.get_controller().ConfirmIcon
			t = create_tween()
			button.modulate = Color.TRANSPARENT
			arrow.modulate = Color.TRANSPARENT
			button.show()
			arrow.show()
			t.set_parallel(true)
			t.set_ease(Tween.EASE_OUT)
			t.set_trans(Tween.TRANS_BACK)
			t.tween_property(button, "modulate", Color(1,1,1,1), 0.05)
			t.tween_property(arrow, "modulate", Color(1,1,1,1), 0.1)
			t.tween_property(button, "custom_minimum_size:x", Length, 0.15).from(48)
			await get_tree().create_timer(0.1).timeout
			CanInteract = true
	elif button:
		#Disappear
		if button.visible:
			t = create_tween()
			t.set_parallel(true)
			t.set_ease(Tween.EASE_IN)
			t.set_trans(Tween.TRANS_LINEAR)
			t.tween_property(button, "modulate", Color(0,0,0,0), 0.2)
			t.tween_property(arrow, "modulate", Color(0,0,0,0), 0.1)
			t.tween_property(button, "custom_minimum_size:x", 48, 0.2)
			await get_tree().create_timer(0.2).timeout
			#if pack in get_tree().root.get_children(): pack.queue_free()
			pack.hide()
			CanInteract = false

func CheckInput() -> void:
	#print($Pack.global_position)
	#Clicked
	if Input.is_action_just_pressed("ui_accept") and CanInteract:
		_on_button_pressed()

func do_position():
	match Global.get_direction(to_local(Global.Player.position + Vector2(0, Height - offset))):
		Vector2.UP:
			$Pack/Cnt.alignment = BoxContainer.ALIGNMENT_CENTER
			$Pack/Cnt.position.x = -166
			$Pack.position.y = 17 - Height
			$Pack.position.x = -15
			$Pack/Arrow.flip_h = true
			$Pack/Arrow.position.y = -42
		Vector2.DOWN:
			$Pack/Cnt.alignment = BoxContainer.ALIGNMENT_CENTER
			$Pack/Cnt.position.x = -166
			$Pack.position.x = -15
			$Pack.position.y = -17 - Height
			$Pack/Arrow.flip_h = false
			$Pack/Arrow.position.y = -6
		Vector2.LEFT:
			$Pack/Cnt.alignment = BoxContainer.ALIGNMENT_BEGIN
			$Pack/Cnt.position.x = 0
			$Pack.position.x = -15
			$Pack.position.y = -17 - Height
			$Pack/Arrow.flip_h = false
			$Pack/Arrow.position.y = -6
		Vector2.RIGHT:
			$Pack/Cnt.alignment = BoxContainer.ALIGNMENT_END
			$Pack/Cnt.position.x = -330
			$Pack.position.x = -15
			$Pack/Arrow.position.y = -6
			$Pack.position.y = -17 - Height
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
			Event.call(file)
		"pass_time":
			PartyUI.confirm_time_passage(title, item, to_time, file)
	if hidesprite:
		if add_flag: Event.f(hide_on_flag, true)
		if Collision: Collision.set_deferred("disabled", true)
		if hide_parent: get_parent().queue_free()
		else: queue_free()
