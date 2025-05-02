extends CanvasLayer

var stage: String

func _ready() -> void:
	$Close.icon = Global.get_controller().CancelIcon
	$Select.icon = Global.get_controller().ConfirmIcon
	root()

func root():
	stage = "root"
	$Pages.hide()
	$Journal.show()
	$Journal.position = Vector2(600, 0)
	$RootMenu.show()
	$List.hide()
	$RootMenu/Diary.grab_focus()
	var t = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART).set_parallel()
	t.tween_property($Close, "position:x", 200, 0.3)
	t.tween_property($Journal, "position", Vector2(600, 0), 1).from(Vector2(600, 2000))
	t.tween_property($RootMenu, "modulate", Color.WHITE, 0.6).from(Color.TRANSPARENT)
	t.tween_property($RootMenu, "position:x", 254, 0.6).from(400)
	$Select.show()
	if get_tree().root.get_node_or_null("MainMenu") != null:
		t.tween_property(get_tree().root.get_node("MainMenu"), "offset:x", 0, 0.5)
		t.tween_property(Global.Camera, "offset:x", 100, 0.5)

func diary() -> void:
	stage = "diary"
	$Journal.hide()
	$RootMenu.hide()
	$Pages.show()
	$List.show()
	$Select.hide()
	var t = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART).set_parallel()
	t.tween_property($Close, "position:x", 320, 0.5).set_ease(Tween.EASE_OUT)
	t.tween_property($List, "position:x", 0, 0.5).from(-300)
	if get_tree().root.get_node_or_null("MainMenu") != null:
		t.tween_property(get_tree().root.get_node("MainMenu"), "offset:x", -165, 0.5)
		t.tween_property(Global.Camera, "offset:x", 150, 0.5)

func close():
	if get_tree().root.get_node_or_null("MainMenu") != null:
		get_tree().root.get_node_or_null("MainMenu")._root()
	queue_free()

func _on_back_pressed() -> void:
	Global.cancel_sound()
	match stage:
		"root":
			close()
		"diary":
			root()

func _input(event: InputEvent) -> void:
	$Close.icon = Global.get_controller().CancelIcon
	$Select.icon = Global.get_controller().ConfirmIcon
