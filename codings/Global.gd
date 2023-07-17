extends Node

var Controllable : bool = true
var Type
var Audio = AudioStreamPlayer.new()
var Sprite = Sprite2D.new()
func _ready():
	add_child(Audio)
	add_child(Sprite)
	Audio.volume_db = -5
static var Party = load("res://database/Party/CurrentParty.tres")
var hasPortrait = false
var portraitimg : Texture
var portrait_redraw = true
static var PlayerDir : Vector2
static var PlayerPos : Vector2
signal check_party

func get_controller():
	if "Nintendo" in Input.get_joy_name(0):
		return preload("res://UI/Input/Nintendo.tres")
	else:
		return preload("res://UI/Input/Keyboard.tres")
		
func cancel():
	if get_controller() == preload("res://UI/Input/Nintendo.tres"):
		return "AltCancel"
	else:
		return "ui_cancel"
		
func confirm():
	if get_controller().AltConfirm:
		return "AltConfirm"
	else:
		return "ui_accept"
		
func cursor_sound():
	Audio.stream = preload("res://sound/SFX/UI/cursor.wav")
	Audio.play()
func buzzer_sound():
	Audio.stream = preload("res://sound/SFX/UI/buzzer.ogg")
	Audio.play()
func confirm_sound():
	Audio.stream = preload("res://sound/SFX/UI/confirm.ogg")
	Audio.play()
func cancel_sound():
	Audio.stream = preload("res://sound/SFX/UI/Quit.ogg")
	Audio.play()
func item_sound():
	Audio.stream = preload("res://sound/SFX/UI/item.ogg")
	Audio.play()
func ui_sound(string:String):
	Audio.stream = load("res://sound/SFX/UI/"+string+".ogg")
	Audio.play()

func get_party():
	return preload("res://database/Party/CurrentParty.tres")
	
func check_member(n):
	return Party.check_member(n)
	#Sprite.texture = preload("res://art/Placeholder.png")

func get_member_name(n):
	if Party.check_member(0) and n==0:
		return Party.Leader.FirstName
	elif Party.check_member(1) and n==1:
		return Party.Member1.FirstName
	elif Party.check_member(2) and n==2:
		return Party.Member2.FirstName
	elif Party.check_member(3) and n==2:
		return Party.Member3.FirstName
	else:
		return "Null"

func number_of_party_members():
	var num= 1
	if check_member(1):
		num+=1
	if check_member(2):
		num+=1
	if check_member(3):
		num+=1
	return num

func is_in_party(n):
	if Party.Leader.FirstName == n:
		return true
	if Party.check_member(1):
		if Party.Member1.FirstName == n:
			return true
	if Party.check_member(2):
		if Party.Member2.FirstName == n:
			return true
	if Party.check_member(3):
		if Party.Member3.FirstName == n:
			return true
	else:
		return false

func portrait(img, redraw):
	portrait_redraw = redraw
	hasPortrait=true
	portraitimg = load("res://art/Portraits/" + img + ".png")

func portrait_clear():
	hasPortrait=false
	
#Match profile
func match_profile(named):
	if load("res://database/Text/Profiles/" + named + ".tres") == null:
		return preload("res://database/Text/Profiles/Default.tres")
	else:
		return load("res://database/Text/Profiles/" + named + ".tres")

func get_direction(v):
	if abs(v.x) > abs(v.y):
		if v.x >0:
			return Vector2.RIGHT
		else:
			return Vector2.LEFT
	else:
		if v.y >0:
			return Vector2.DOWN
		else:
			return Vector2.UP
	
func get_dir_letter(d):
	if get_direction(d) == Vector2.RIGHT:
		return "R"
	elif get_direction(d) == Vector2.LEFT:
		return "L"
	elif get_direction(d) == Vector2.UP:
		return "U"
	elif get_direction(d) == Vector2.DOWN:
		return "D"
