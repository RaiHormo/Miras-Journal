extends CanvasLayer

@export var DiaryEntries: Dictionary[StringName, String]
var stage: String

func _ready() -> void:
	$Close.icon = Global.get_controller().CancelIcon
	$Select.icon = Global.get_controller().ConfirmIcon
	load_entries()
	diary_load_day_list()
	root()

func root():
	stage = "root"
	$Pages.hide()
	$Journal.show()
	$Journal.position = Vector2(600, 0)
	$JournalBack.hide()
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
	$JournalBack.show()
	$Pages.show()
	$List.show()
	$Select.hide()
	var t = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART).set_parallel()
	t.tween_property($Close, "position:x", 320, 0.5).set_ease(Tween.EASE_OUT)
	t.tween_property($List, "position:x", 0, 0.5).from(-300)
	if get_tree().root.get_node_or_null("MainMenu") != null:
		t.tween_property(get_tree().root.get_node("MainMenu"), "offset:x", -165, 0.5)
		t.tween_property(Global.Camera, "offset:x", 150, 0.5)
	$List/List.get_children()[-1].grab_focus()

func add_test_entries():
	Event.Diary = {
	2: ["boo"],
	5: ["boo", "bee"]
}

func diary_load_day_list():
	if Event.Diary.is_empty(): add_test_entries()
	for i in Event.Diary:
		var dub =  $List/List/Listing0.duplicate()
		dub.name = str(i)
		dub.text = Query.get_mmm(Query.get_month(i)) + " " + str(i)
		$List/List.add_child(dub)
		dub.show()
	$List/List/Listing0.queue_free()

func diary_focus(day: int):
	%TextL.text = ""
	%TextR.text = ""
	var page = 0
	var text: String = Query.get_month_name(Query.get_month(day)) + " " + Query.get_date_day(day) + "\n\n"
	for i in Event.Diary[day]:
		var prev_text = text
		text += DiaryEntries.get(i)
		text += "\n~~~~~~\n"
		%TextL.text = text
		await Event.wait()
		if %TextL.get_line_count() > 20 or page == 1:
			%TextL.text = prev_text
			%TextR.text += DiaryEntries.get(i)

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

func load_entries():
	var file =  FileAccess.open("res://database/Text/Journal/Diary.json", FileAccess.READ)
	var json: Array = JSON.parse_string(file.get_as_text())
	for i in json:
		DiaryEntries.set(i[0], i[1])
	print(DiaryEntries)
	file.close()


func diary_focus_button() -> void:
	var foc = get_viewport().gui_get_focus_owner()
	diary_focus(int(foc.name))
