extends TextureRect
@export var HideOnDays: Array[int]
var time_pass_id: String
signal chosen_time_pass(awnser: bool)

func _ready() -> void:
	Global.check_party.connect(_check_party)
	hide_prompt()

func _check_party():
	if Event.f("HideDate") and not $Action.visible: 
		$Date/Day.add_theme_font_size_override("font_size", 150)
		$Date/Month.text = "Unknown"
		$Date/Day.text = "Date"
		hide()
	else: 
		show()
		$Date/Day.add_theme_font_size_override("font_size", 265) 
	$Container/TimeOfDay.text = Global.to_tod_text(Event.TimeOfDay)
	$Date/Day.text = str(wrapi(Event.Day, 1, 32))
	$Date/Month.text = Global.get_month_name(Global.get_month(Event.Day))
	$Container/TimeOfDay.icon = await Global.to_tod_icon(Event.TimeOfDay)
	

func confirm_time_passage(title: String, description: String, to_time: Event.TOD) -> bool:
	Global.check_party.emit()
	Event.f("DisableMenus", false)
	show()
	Global.Controllable = false
	get_tree().paused = true
	PartyUI.show_all()
	PartyUI.darken()
	var t = create_tween()
	t.set_parallel()
	t.set_trans(Tween.TRANS_QUART)
	$Action.modulate = Color.TRANSPARENT
	t.tween_property($Action, "modulate:a", 1, 0.3)
	t.tween_property($Action, "position:x", -1750, 0.3).from(-1850)
	$Action/RichTextLabel.text = description
	$Action.text = title
	$Future/TimeOfDay.text = Global.to_tod_text(to_time)
	$Future/TimeOfDay.icon = await Global.to_tod_icon(to_time)
	$Action.show()
	$Future.show()
	$Arrow.show()
	await t.finished
	Global.Controllable = false
	$Action/Nevermind.grab_focus()
	return await chosen_time_pass

func hide_prompt() -> void:
	$Action.hide()
	$Future.hide()
	$Arrow.hide()
	await PartyUI.darken(false)

func _on_nevermind_pressed() -> void:
	Global.cancel_sound()
	await hide_prompt()
	chosen_time_pass.emit(false)

func use_time() -> void:
	Global.confirm_sound()
	hide_prompt()
	chosen_time_pass.emit(true)

func _cursor() -> void:
	Global.cursor_sound()
