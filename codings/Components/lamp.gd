extends PointLight2D
@export var Light: bool = true
@export var flag: String = ""

func _ready() -> void:
	if flag != "": Light = Event.check_flag(flag)
	update()

func _on_interactable_action():
	Light = !Light
	if flag != "": Event.add_flag(flag, Light)
	update()

func update():
	var t = create_tween()
	if Light:
		t.tween_property(self, "energy", 1, 0.5)
		Light = true
	else:
		t.tween_property(self, "energy", 0, 0.1)
		Light = false
