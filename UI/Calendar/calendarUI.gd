extends TextureRect
@export var HideOnDays: Array[int]
var time_pass_id: String

func _ready() -> void:
	Global.check_party.connect(_check_party)
	hide_prompt()

func _check_party():
	if Event.Day not in HideOnDays: show()
	else: hide()
	$Date/Day.text = str(Event.Day)
	$Date/Month.text = Global.get_mmm(Global.get_month(Event.Day))

func confirm_time_passage(title: String, description: String, to_time: int, action_id: String):
	time_pass_id = action_id
	show()
	Global.Controllable = false
	get_tree().paused = true
	PartyUI.darken()
	var t = create_tween()
	t.set_parallel()
	t.set_trans(Tween.TRANS_QUART)
	$Action.modulate = Color.TRANSPARENT
	t.tween_property($Action, "modulate:a", 1, 0.3)
	t.tween_property($Action, "position:x", -1750, 0.3).from(-1850)
	$Action/RichTextLabel.text = description
	$Action.text = title
	$Future/TimeOfDay.text = to_tod_text(to_time)
	$Future/TimeOfDay.icon = to_tod_icon(to_time)
	$Action.show()
	$Future.show()
	$Arrow.show()
	$Action/Nevermind.grab_focus()

func to_tod_text(x: int) -> String:
	match x:
		0: return "Morning"
		1: return "Mid-day"
		2: return "Afternoon"
		3: return "Evening"
		4: return "Night"
	return "Dark hour"

func to_tod_icon(x: int) -> Texture:
	return load("res://UI/Calendar/" + to_tod_text(x) + ".png")

func hide_prompt() -> void:
	$Action.hide()
	$Future.hide()
	$Arrow.hide()
	await PartyUI.darken(false)

func _on_nevermind_pressed() -> void:
	await hide_prompt()
	Global.Controllable = true
	get_tree().paused = false

func use_time() -> void:
	hide_prompt()
	await Loader.transition("")
	if Event.has_method(time_pass_id): Event.call(time_pass_id)
	else: OS.alert("Invalid event ID "+ time_pass_id)
