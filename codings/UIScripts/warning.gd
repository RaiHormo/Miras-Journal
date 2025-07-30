extends CanvasLayer
signal response
var value: bool = false

func _ready() -> void:
	hide()

func ask_for_confirm(text: String, label: String = "WARNING", awnser1: String = "No", awnser2: String = "Yes", color: Color = Color.hex(0xdc000eff)) -> bool:
	var t = create_tween().set_parallel().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	t.tween_property($Bg, "modulate", Color(1,1,1,0.5), 0.5).from(Color.TRANSPARENT)
	t.tween_property($Panel, "scale:y", 1, 0.3).from(0)
	show()
	$Panel/Options/No.text = awnser1
	$Panel/Options/Yes.text = awnser2
	$Panel/Label.text = text
	$Panel/Label2.text = label
	$Panel/Options/No.grab_focus()
	await response
	queue_free()
	return value

func _on_no_pressed() -> void:
	Global.confirm_sound()
	value = false
	response.emit()


func _on_yes_pressed() -> void:
	Global.confirm_sound()
	value = true
	response.emit()
