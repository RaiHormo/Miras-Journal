extends TextureRect
@export var HideOnDays: Array[int]
var time_pass_id: String

func _ready() -> void:
	Global.check_party.connect(_check_party)
	hide_prompt()

func _check_party():
	if Event.Day not in HideOnDays: show()
	else: hide()
	$Container/TimeOfDay.text = to_tod_text(Event.TimeOfDay)
	$Container/TimeOfDay.icon = to_tod_icon(Event.TimeOfDay)
	$Date/Day.text = str(Event.Day)
	$Date/Month.text = Global.get_mmm(Global.get_month(Event.Day))

func confirm_time_passage(title: String, description: String, to_time: Event.TOD, action_id: String):
	Global.check_party.emit()
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

func to_tod_text(x: Event.TOD) -> String:
	match x:
		Event.TOD.MORNING: return "Morning"
		Event.TOD.DAYTIME: return "Daytime"
		Event.TOD.AFTERNOON: return "Afternoon"
		Event.TOD.EVENING: return "Evening"
		Event.TOD.NIGHT: return "Night"
	return "Dark hour"

func to_tod_icon(x: Event.TOD) -> Texture:
	if FileAccess.file_exists("res://UI/Calendar/" + to_tod_text(x) + ".png"):
		return load("res://UI/Calendar/" + to_tod_text(x) + ".png")
	else: return null

func hide_prompt() -> void:
	$Action.hide()
	$Future.hide()
	$Arrow.hide()
	await PartyUI.darken(false)

func _on_nevermind_pressed() -> void:
	Global.cancel_sound()
	await hide_prompt()
	Global.Controllable = true
	get_tree().paused = false

func use_time() -> void:
	Global.confirm_sound()
	hide_prompt()
	await Loader.transition("")
	if Event.has_method(time_pass_id): Event.call(time_pass_id)
	else: OS.alert("Invalid event ID "+ time_pass_id)

func _cursor() -> void:
	Global.cursor_sound()
