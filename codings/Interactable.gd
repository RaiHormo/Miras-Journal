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
const Textbox = DialogueManager.Textbox2
var CanInteract = false
var t:Tween


func _process(delta):
	if has_overlapping_areas() and Global.Controllable:
		CheckInput()
		#Appear
		if not $Button.visible:
			$Button.text = LabelText
			$Button.icon = Global.get_controller().ConfirmIcon
			t = create_tween()
			$Button.modulate = Color.TRANSPARENT
			$Arrow.modulate = Color.TRANSPARENT
			$Button.show()
			$Arrow.show()
			t.set_parallel(true)
			t.set_ease(Tween.EASE_OUT)
			t.set_trans(Tween.TRANS_BACK)
			t.tween_property($Button, "modulate", Color(1,1,1,1), 0.05)
			t.tween_property($Arrow, "modulate", Color(1,1,1,1), 0.1)
			t.tween_property($Button, "size", Vector2(Length,33), 0.1).from(Vector2(41, 33))
			t.tween_property($Button, "position", Vector2(-33-int((Length - 120)/10),-35), 0.1).from(Vector2(-19,-35))
			await get_tree().create_timer(0.1).timeout
			CanInteract = true
		
	elif $Button != null:
		#Disappear
		if $Button.visible:
			t = create_tween()
			t.set_parallel(true)
			t.set_ease(Tween.EASE_IN)
			t.set_trans(Tween.TRANS_LINEAR)
			t.tween_property($Button, "modulate", Color(0,0,0,0), 0.1)
			t.tween_property($Arrow, "modulate", Color(0,0,0,0), 0.1)
			t.tween_property($Button, "size", Vector2(41,33), 0.1)
			t.tween_property($Button, "position", Vector2(-19,-35), 0.1)
			await get_tree().create_timer(0.2).timeout
			$Button.hide()
			$Arrow.hide()
			CanInteract = false
		
func CheckInput():
	#Clicked
	if Input.is_action_just_pressed("ui_accept") and CanInteract:
		_on_button_pressed()

func _on_button_pressed():
	t = create_tween()
	t.set_parallel(true)
	t.set_ease(Tween.EASE_IN)
	t.set_trans(Tween.TRANS_LINEAR)
	t.tween_property($Button, "scale", Vector2(0.311,0.311), 0.1).from(Vector2(0.269,0.269))
	await t.finished
	match ActionType:
		"toggle":
			Global.confirm_sound()
			emit_signal("action")
		"text":
			Global.Controllable = false
			DialogueManager.textbox(file, title)
			await DialogueManager.dialogue_ended
			PartyUI.UIvisible = true
			Global.Controllable = true
		"item":
			if itemtype=="key":
				Item.add_key_item(item)
		"battle":
			Loader.start_battle(file)
		"global":
			Global.call(file)
	if hidesprite:
		get_parent().hide()
