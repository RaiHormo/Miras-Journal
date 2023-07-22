extends Control
var stage
var rootIndex


func _ready():
	$Can/Base.play("Open")
	stage = "root"
	rootIndex=1

func _input(event):
	if stage=="root":
		if Input.is_action_just_pressed("ui_up"):
			if rootIndex == 0:
				Global.buzzer_sound()
			else:
				Global.cursor_sound()
				rootIndex -= 1
				move_menu()
		if Input.is_action_just_pressed("ui_down"):
			if rootIndex == 3:
				Global.buzzer_sound()
			else:
				Global.cursor_sound()
				rootIndex += 1
				move_menu()


func move_menu():
	if stage=="root":
		print(rootIndex)
		var button : Button = $Can/Rail.get_child(rootIndex).get_child(0)
		
