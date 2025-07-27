extends Control

var here: String
var foc: Control = null
var inited:= false

func _ready() -> void:
	await Event.take_control()
	await Loader.save()
	get_viewport().gui_focus_changed.connect(focus_change)
	Global.get_cam().limit_bottom = 999999
	Global.get_cam().limit_right = 999999
	Global.get_cam().limit_left = -999999
	Global.get_cam().limit_top = -999999
	for i in $Container/Scroller/LocationList.get_children():
		#if i is Button: i.pressed.connect(location_selected)
		if not Event.f("VP"+i.name):
			if i is Button: i.hide()
	$Container/Scroller/LocationList/Gate.show()
	var label: Label
	for i in $Container/Scroller/LocationList.get_children():
		if i is Label:
			label = i
			i.hide()
		if i is Button and i.visible: label.show()
	await Event.wait(0.3, false)
	if foc is Button: foc.grab_focus()

func focus_place(place: String = here):
	if not inited:
		here = place
		Global.Player.camera_follow(false)
		Global.get_cam().position_smoothing_enabled = false
		position = Global.get_cam().global_position - (size/2)
		$Container.global_position.x = 1300
		var t = create_tween()
		t.set_ease(Tween.EASE_OUT)
		t.set_trans(Tween.TRANS_QUINT)
		t.set_parallel()
		show()
		t.tween_property(self, "modulate", Color.WHITE, 0.5).from(Color.TRANSPARENT)
		t.tween_property(Global.get_cam(), "zoom", Vector2.ONE, 0.5)
		t.tween_property(Global.get_cam(), "position", position + (size/2), 0.5)
		t.tween_property($Container, "position:x", 898, 0.3).set_delay(0.3)
		inited = true
	else: Global.cursor_sound()
	foc = $Container/Scroller/LocationList.get_node(place)
	foc.show()
	foc.grab_focus()
	if $Map.get_node_or_null(place) != null and place != here:
		$Marker.global_position = $Map.get_node(place).global_position
		$Marker.show()
	else: $Marker.hide()
	if $Map.get_node_or_null(here) != null:
		$Here.global_position = $Map.get_node(here).global_position
	for i in $Container/Scroller/LocationList.get_children():
		if i is Button and i.name == here: i.icon = preload("res://UI/Map/here.png")

func focus_change(node: Control):
	if not inited: return
	foc = node
	for i in $Container/Scroller/LocationList.get_children():
		if i is Button: i.icon = preload("res://UI/MenuTextures/dot.png")
	if node.get_parent() == $Container/Scroller/LocationList:
		focus_place(node.name)
		node.icon = preload("res://UI/Map/marker.png")
	for i in $Container/Scroller/LocationList.get_children():
		if i is Button and i.name == here: i.icon = preload("res://UI/Map/here.png")

func location_selected():
	if not inited: return
	inited = false

	var progress_time = false
	var prev_foc = foc
	if foc.get_meta("IsDungeon", true) != Global.Area.IsDungeon:
		var message: String
		if Global.Area.IsDungeon:
			message = "Exit the dungeon and rest at home."
		else:
			message = "Head into a dungeon. Time will pass when returning."
		if not await PartyUI.confirm_time_passage("Travel", message, Event.get_time_progress_from_now(2)):
			inited = true
			foc =  prev_foc
			PartyUI.hide_all()
			focus_place(here)
			return
		elif Global.Area.IsDungeon:
			Event.ToTime = Event.get_time_progress_from_now(2)
			progress_time = true
			Event.add_flag("eepy1")
	foc =  prev_foc
	Global.confirm_sound()
	Event.remove_flag("FlameActive")
	var map_point = $Map.get_node_or_null(str(foc.name))
	if map_point == null: OS.alert("You forgot to add the map point idiot"); return
	var t = create_tween()
	t.set_parallel()
	t.tween_property(Global.get_cam(), "zoom", Vector2(4, 4), 0.3)
	t.tween_property(Global.get_cam(), "position", map_point.global_position, 0.3)
	await Loader.transition("")
	if progress_time:
		await Event.time_transition()
	Loader.travel_to(foc.get_meta("Room"), Vector2.ZERO, foc.get_meta("CamID"), -1, "")
	await Global.area_initialized
	var VP = Global.Area.get_node_or_null("VP"+foc.name)
	if VP == null: OS.alert("No such vain point exists"); return
	Global.Player.global_position = VP.global_position + Vector2(0, 24)
	queue_free()

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		focus_place(here)
	if Input.is_action_just_pressed(&"ui_accept") and foc != null:
		location_selected()
