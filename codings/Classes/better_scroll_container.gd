extends ScrollContainer
class_name BetterScrollContainer
var t: Tween
var target = 0

#func _set(property: StringName, value: Variant) -> bool:
	#if value == get(property): return true
	#match property:
		#"scroll_horizontal":
			#scroll_to(value, &"h")
			#return true
		#"scroll_vertical":
			#scroll_to(value, &"v")
			#return true
	#return false

func _ready() -> void:
	get_viewport().gui_focus_changed.connect(scroll_to_focus)

func scroll_to_focus(foc: Control):
	if foc.get_parent() != get_child(0): 
		foc = foc.get_parent()
		if foc.get_parent() != get_child(0): return
	scroll_to(int(foc.position.y - size.y/2))

func scroll_to(to: int, axis: StringName = &"v"):
	if is_instance_valid(t): t.kill()
	to = max(0, to)
	t = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	var property = "scroll_vertical"
	if axis == &"h":
		property = "scroll_horizontal"
	t.tween_property(self, property, to, 0.3)

func scroll_by(amount: int, axis: StringName = &"v"):
	var property = "scroll_vertical"
	if axis == &"h":
		property = "scroll_horizontal"
	scroll_to(get(property)+amount)
