extends Area2D
class_name Interactable

signal action()
@export var LabelText : String = "Inspect"
@export var ActionType: String
@export var Length: int = 120
@export var file: String
@export var title: String
@export var item: String
@export var hidesprite: bool = false
@export var itemtype: String
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


func _ready() -> void:
	$Pack.hide()
	$Pack.position.y -= Height
	if Event.f(hide_on_flag):
		if hide_parent: get_parent().queue_free()
		else: queue_free()

func _process(delta: float) -> void:
	if pack == null:
		pack = $Pack.duplicate()
	if Global.Player != null and Global.Player.get_node_or_null("DirectionMarker/Finder") in get_overlapping_areas() and Global.Controllable:
		CheckInput()
		#Appear
		if not pack.visible:
			#$/root.add_child(pack)
			button = pack.get_node("Button")
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
			t.tween_property(button, "size", Vector2(Length,33), 0.1).from(Vector2(41, 33))
			t.tween_property(button, "position", Vector2(-44-int((Length - 120)/10),-47), 0.1).from(Vector2(-5,-47))
			await get_tree().create_timer(0.1).timeout
			CanInteract = true

	elif button != null:
		#Disappear
		if button.visible:
			t = create_tween()
			t.set_parallel(true)
			t.set_ease(Tween.EASE_IN)
			t.set_trans(Tween.TRANS_LINEAR)
			t.tween_property(button, "modulate", Color(0,0,0,0), 0.1)
			t.tween_property(arrow, "modulate", Color(0,0,0,0), 0.1)
			t.tween_property(button, "size", Vector2(41,33), 0.1)
			t.tween_property(button, "position", Vector2(-5,-47), 0.1)
			await get_tree().create_timer(0.2).timeout
			#if pack in get_tree().root.get_children(): pack.queue_free()
			pack.hide()
			CanInteract = false

func CheckInput() -> void:
	#print($Pack.global_position)
	#Clicked
	if Input.is_action_just_pressed("ui_accept") and CanInteract:
		_on_button_pressed()

func _on_button_pressed() -> void:
	t = create_tween()
	t.set_parallel(true)
	t.set_ease(Tween.EASE_IN)
	t.set_trans(Tween.TRANS_LINEAR)
	t.tween_property(pack, "scale", Vector2(0.4,0.4), 0.1).from(Vector2(0.36,0.36))
	await t.finished
	action.emit()
	match ActionType:
		"toggle":
			Global.confirm_sound()
		"text":
			await Event.take_control()
			await Global.textbox(file, title)
			PartyUI.UIvisible = true
			Global.Controllable = true
		"item":
			if not Item.HasBag: Global.toast("A bag is needed to store that."); return
			Item.add_item(item, itemtype)
		"battle":
			Loader.start_battle(file)
		"global":
			Global.call(file)
		"event":
			Event.call(file)
	if hidesprite:
		if add_flag: Event.f(hide_on_flag, true)
		if Collision != null: Collision.disabled = true
		if hide_parent: get_parent().queue_free()
		else: queue_free()
